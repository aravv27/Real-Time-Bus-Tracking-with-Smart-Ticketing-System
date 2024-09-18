import requests
import xml.etree.ElementTree as ET

url = 'https://data.bus-data.dft.gov.uk/api/v1/datafeed/?api_key=7c5d0af81183db272285451c9cc7e832f38c1107&boundingBox=-2.93,53.374,-3.085,53.453'
response = requests.get(url)

print("Response Status Code:", response.status_code)
print("Response Headers:", response.headers)
print(response.text)
# Check if the response is not empty
# if response.text:
#     try:
#         # Define the namespace
#         namespace = 'http://www.siri.org.uk/siri'
        
#         # Parse XML response
#         root = ET.fromstring(response.text)
        
#         # Iterate through VehicleLocation elements and extract Latitude and Longitude
#         for vehicle_location in root.findall('.//{' + namespace + '}VehicleLocation'):
#             longitude = vehicle_location.find('{'+namespace+'}Longitude')
#             latitude = vehicle_location.find('{'+namespace+'}Latitude')
            
#             if longitude is not None and latitude is not None:
#                 print(f"Longitude: {longitude.text}")
#                 print(f"Latitude: {latitude.text}")
#                 print("-" * 40)
#             else:
#                 print("Longitude or Latitude missing in the current entry.")
#     except ET.ParseError as e:
#         print("Failed to parse XML response.")
#         print(e)
# else:
#     print("Empty response received.")
