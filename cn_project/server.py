from flask import Flask, jsonify
import requests
import xml.etree.ElementTree as ET
import threading
import time
from flask_cors import CORS

app = Flask(__name__)
CORS(app)


#app = Flask(__name__)

# Define a global variable to store bus locations
bus_locations = []

# Function to fetch and update bus locations
def fetch_bus_locations():
    global bus_locations
    url = 'https://data.bus-data.dft.gov.uk/api/v1/datafeed/?api_key=7c5d0af81183db272285451c9cc7e832f38c1107&boundingBox=-2.93,53.374,-3.085,53.453'
    while True:
        response = requests.get(url)
        if response.status_code == 200:
            root = ET.fromstring(response.text)
            new_locations = []

            # Namespace for XML parsing
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
            # for vehicle_location in root.findall('.//{' + namespace + '}VehicleLocation'):
            #     longitude = vehicle_location.find('{'+namespace+'}Longitude')
            #     latitude = vehicle_location.find('{'+namespace+'}Latitude')
            #     origin_name = vehicle_location.find('{'+namespace+'}OriginName')  # Update to correct XML path
            #     destination_name = vehicle_location.find('{'+namespace+'}DestinationName')  # Update to correct XML path
                
            #     if longitude is not None and latitude is not None:
            #         new_locations.append({
            #             'longitude': longitude.text,
            #             'latitude': latitude.text,
            #             'originName': origin_name.text if origin_name is not None else 'Unknown',
            #             'destinationName': destination_name.text if destination_name is not None else 'Unknown'
            #         })
                #print(new_locations)
            
            bus_locations = new_locations
            #print(f"bus location updated:{bus_locations}")

        time.sleep(300)  # Sleep for 5 minutes

# Route to get bus locations
@app.route('/bus-locations', methods=['GET'])
def get_bus_locations():
    return jsonify(bus_locations)

if __name__ == '__main__':
    # Start the background thread to fetch bus locations
    thread = threading.Thread(target=fetch_bus_locations)
    thread.daemon = True
    thread.start()

    app.run(debug=True)
