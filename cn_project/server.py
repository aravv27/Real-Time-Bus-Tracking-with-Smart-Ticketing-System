from flask import Flask, jsonify, request
import requests
import xml.etree.ElementTree as ET
import threading
import time
from flask_cors import CORS
from pymongo.mongo_client import MongoClient
from pymongo.server_api import ServerApi
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
CORS(app)

TEXTLOCAL_API_KEY = 'NDY2NjRiNTY0MTZhNGY1NzQyNTU2ODU1N2EzODM5NmU='
TEXTLOCAL_SENDER = 'Ticket4U'  # Replace with your sender name

def send_sms(phone_number, message):
    url = "https://api.textlocal.in/send/"
    data = {
        'apikey': TEXTLOCAL_API_KEY,
        'numbers': phone_number,
        'message': message,
        'sender': TEXTLOCAL_SENDER,
    }
    
    response = requests.post(url, data=data)
    return response.json()


bus_locations = []


def fetch_bus_locations():
    global bus_locations
    url = 'https://data.bus-data.dft.gov.uk/api/v1/datafeed/?api_key=7c5d0af81183db272285451c9cc7e832f38c1107&boundingBox=-2.93,53.374,-3.085,53.453'
    while True:
        response = requests.get(url)
        if response.status_code == 200:
            root = ET.fromstring(response.text)
            new_locations = []
            
            namespace = 'http://www.siri.org.uk/siri'

            for monitored_vehicle_journey in root.findall('.//{' + namespace + '}MonitoredVehicleJourney'):
                origin_name = monitored_vehicle_journey.find('{'+namespace+'}OriginName')
                destination_name = monitored_vehicle_journey.find('{'+namespace+'}DestinationName')
                vehicle_location = monitored_vehicle_journey.find('{'+namespace+'}VehicleLocation')
                vehicle_ref = monitored_vehicle_journey.find('{'+namespace+'}VehicleRef')
                origin_aimed_departure_time = monitored_vehicle_journey.find('{'+namespace+'}OriginAimedDepartureTime')
                line_ref = monitored_vehicle_journey.find('{'+namespace+'}LineRef')
                
                longitude = vehicle_location.find('{'+namespace+'}Longitude') if vehicle_location is not None else None
                latitude = vehicle_location.find('{'+namespace+'}Latitude') if vehicle_location is not None else None

                if longitude is not None and latitude is not None:
                    new_locations.append({
                        'longitude': longitude.text,
                        'latitude': latitude.text,
                        'originName': origin_name.text if origin_name is not None else 'Unknown',
                        'destinationName': destination_name.text if destination_name is not None else 'Unknown',
                        'vehicleRef': vehicle_ref.text if vehicle_ref is not None else 'Unknown',
                        'originAimedDepartureTime': origin_aimed_departure_time.text if origin_aimed_departure_time is not None else 'Unknown',
                        'lineRef': line_ref.text if line_ref is not None else 'Unknown',
                    })

            bus_locations = new_locations


        time.sleep(300)  


@app.route('/bus-locations', methods=['GET'])
def get_bus_locations():
    return jsonify(bus_locations)

uri = "mongodb+srv://2005aravin:Poity123@smartticketingsystem.lwjo5.mongodb.net/?retryWrites=true&w=majority&appName=smartTicketingSystem"
client = MongoClient(uri, server_api=ServerApi('1'))
db = client['smart_ticketing_system']
ticket_collection = db['tickets_new']
user_collection = db['users']

@app.route('/book-ticket', methods=['POST'])
def book_ticket():
    data = request.json  
    try:
        ticket = {
            'origin': data['origin'],
            'destination': data['destination'],
            'ticketCount': data['ticketCount'],
            'bookingTime': data.get('bookingTime'),
            'phone_number': data.get('phone_number')
        }
        
        ticket_collection.insert_one(ticket)
        return jsonify({'message': 'Ticket booked successfully!'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/user-tickets/<phone_number>', methods=['GET'])
def get_user_tickets(phone_number):
    try:
        tickets = ticket_collection.find({'phone_number': phone_number})
        tickets_list = []
        for ticket in tickets:
            ticket.pop('_id', None)
            tickets_list.append(ticket)
        return jsonify((tickets_list)), 200
    except Exception as e:
        print(f"Error retrieving user profile: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')

    # Find user in the database
    user = user_collection.find_one({'username': username})
    if user and check_password_hash(user['password'], password):  # Assume password is stored as hashed
        return jsonify({'message': 'Login successful!'}), 200
    else:
        return jsonify({'error': 'Invalid credentials'}), 401

# Updated registration route
@app.route('/registration', methods=['POST'])
def register():
    data = request.json
    username = data['username']
    password = generate_password_hash(data['password'])  # Hash the password
    phone_number = data.get('phone_number')  # Get the phone number from the request

    # Ensure the username and phone number are unique (you may want to add more checks)
    if user_collection.find_one({'username': username}):
        return jsonify({'error': 'Username already exists'}), 400
    
    if user_collection.find_one({'phone_number': phone_number}):
        return jsonify({'error': 'Phone number already registered'}), 400

    new_user = {
        'username': username,
        'password': password,
        'phone_number': phone_number  # Save the phone number
    }

    user_collection.insert_one(new_user)
    return jsonify({'message': 'User registered successfully!'}), 201

@app.route('/user-profile/<username>', methods=['GET'])
def get_user_profile(username):
    try:
        user = user_collection.find_one({'username': username})
        if user:
            user.pop('_id', None)
            # Remove sensitive information like password
            user.pop('password', None)
            return jsonify(user), 200
        else:
            return jsonify({'error': 'User  not found'}), 404
    except Exception as e:
        print(f"Error retrieving user profile: {str(e)}")
        #logging.error(f"Error retrieving user profile: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    
    thread = threading.Thread(target=fetch_bus_locations)
    thread.daemon = True
    thread.start()

    app.run(host='0.0.0.0',port=500,debug=True)
