import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Ticketing System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LatLng _center = LatLng(53.410782, -2.977840); // Example center
  List<Marker> _busMarkers = [];
  List<Marker> _filteredBusMarkers = [];
  final String apiUrl = 'http://127.0.0.1:5000/bus-locations'; // Your Flask backend URL
  List<String> _origins = [];
  List<String> _destinations = [];
  String? _selectedOrigin;
  String? _selectedDestination;
  List<Map<String, dynamic>> _busData = []; // To store raw bus data
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchAllBusLocations();
    _timer = Timer.periodic(Duration(minutes: 5), (Timer t) => _fetchAllBusLocations());
  }

  Future<void> _fetchAllBusLocations() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _busData = data.cast<Map<String, dynamic>>();
          _busMarkers = _busData.map((bus) {
            double latitude = double.tryParse(bus['latitude'].toString()) ?? 0.0;
            double longitude = double.tryParse(bus['longitude'].toString()) ?? 0.0;

            return Marker(
              point: LatLng(latitude, longitude),
              child: Container(
                child: Icon(Icons.directions_bus, color: Colors.blue, size: 40.0),
              ),
            );
          }).toList();
          _origins = _busData.map((bus) => bus['originName'].toString()).toSet().toList();
          _destinations = _busData.map((bus) => bus['destinationName'].toString()).toSet().toList();

          _fetchFilteredBusLocations(); // Initialize filtered markers
        });
      } else {
        throw Exception('Failed to load bus locations');
      }
    } catch (e) {
      print('Error fetching bus locations: $e');
    }
  }

  void _fetchFilteredBusLocations() {
    setState(() {
      _filteredBusMarkers = _busMarkers.where((marker) {
        final bus = _busData.firstWhere(
          (b) => LatLng(double.tryParse(b['latitude'].toString()) ?? 0.0, double.tryParse(b['longitude'].toString()) ?? 0.0) == marker.point,
          );
        if (bus == null) return false;

        bool matchesOrigin = _selectedOrigin == null || bus['originName'] == _selectedOrigin;
        bool matchesDestination = _selectedDestination == null || bus['destinationName'] == _selectedDestination;

        return matchesOrigin && matchesDestination;
      }).toList();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (BuildContext context){
          return IconButton(onPressed: () { Scaffold.of(context).openDrawer(); }, icon: const Icon(Icons.menu),tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,);
        },),
        title: Text('Real-time Bus Tracking'),
        centerTitle: true,
        actions: [
          // Dropdown for Origin
          DropdownButton<String>(
            value: _selectedOrigin,
            hint: Text('Select Origin'),
            items: _origins.isNotEmpty?_origins.map((String origin) {
              return DropdownMenuItem<String>(
                value: origin,
                child: Text(origin),
              );
            }).toList() : [DropdownMenuItem<String>(value: null, child: Text('No Destinations Available'))],
            onChanged: (newValue) {
              setState(() {
                _selectedOrigin = newValue;
                _fetchFilteredBusLocations(); // Update filtered markers
              });
            },
          ),
          // Dropdown for Destination
          DropdownButton<String>(
            value: _selectedDestination,
            hint: Text('Select Destination'),
            items: _destinations.isNotEmpty? _destinations.map((String destination) {
              return DropdownMenuItem<String>(
                value: destination,
                child: Text(destination),
              );
            }).toList() : [DropdownMenuItem<String>(value: null, child: Text('No Destinations Available'))],
            onChanged: (newValue) {
              setState(() {
                _selectedDestination = newValue;
                _fetchFilteredBusLocations(); // Update filtered markers
              });
            },
          ),
          SizedBox(width: 10),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _center,
          minZoom: 1.0,
          maxZoom: 34.0,
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: _filteredBusMarkers, // Use filtered markers
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Text("Navigation"),decoration: BoxDecoration(color: Colors.purple),),
            // ListTile(
            //   title: const Text(" Your bus"),
            //   onTap: () { Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => YourBusScreen(
            //           origins: _origins,
            //           destinations: _destinations,
            //           busData: _busData,
            //         ),
            //       ),
            //     );
            //   },
            // ),
            ListTile(
                title: const Text("Book tickets"),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TicketBookingScreen(origins: _origins,destinations: _destinations,)));

                },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(child: const Icon(Icons.directions_bus,), onPressed: () {Navigator.push(context,MaterialPageRoute(builder: (context) => YourBusScreen(busData: _busData,origins: _origins,destinations: _destinations,)),);},),
    );
  }
}
class YourBusScreen extends StatefulWidget {
  final List<String> origins;
  final List<String> destinations;
  final List<Map<String, dynamic>> busData;

  YourBusScreen({required this.origins, required this.destinations, required this.busData});

  @override
  _YourBusScreenState createState() => _YourBusScreenState();
}

class _YourBusScreenState extends State<YourBusScreen> {
  String? selectedOrigin;
  String? selectedDestination;
  List<Map<String, dynamic>> filteredBuses = [];

  void filterBuses() {
    setState(() {
      filteredBuses = widget.busData.where((bus) {
        bool matchesOrigin = selectedOrigin == null || bus['originName'] == selectedOrigin;
        bool matchesDestination = selectedDestination == null || bus['destinationName'] == selectedDestination;
        return matchesOrigin && matchesDestination;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // DateTime dateTime = DateTime.parse(widget.busData.['originAimedDepartureTime']);

    // // Extract the date and time separately
    // String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime); // Format: 2024-09-17
    // String formattedTime = DateFormat('HH:mm').format(dateTime);
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Bus'),
      ),
      body: Column(
        children: [
          // Container(
          //     padding: EdgeInsets.all(12.0),
          //     decoration: BoxDecoration(
          //     border: Border.all(color: Colors.blueAccent),
          //     borderRadius: BorderRadius.circular(8.0),
          //     ),),
          Row(
            children: [
              
              DropdownButton<String>(
                value: selectedOrigin,
                hint: Text("Select Origin"),
                // icon: Icon(Icons.arrow_drop_down, color: Colors.blue),
                // underline: Container(
                // height: 2,
                // color: Colors.blueAccent,
                // ),
                items: widget.origins.map((String origin) {
                  return DropdownMenuItem<String>(
                    value: origin,
                    child: Text(origin),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedOrigin = newValue;
                    filterBuses();
                  });
                },
              ),
              
              DropdownButton<String>(
                
                value: selectedDestination,
                hint: Text("Select Destination"),
                items: widget.destinations.map((String destination) {
                  return DropdownMenuItem<String>(
                    value: destination,
                    child: Text(destination),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedDestination = newValue;
                    filterBuses();
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: filteredBuses.map((bus) {
                DateTime dateTime = DateTime.parse(bus['originAimedDepartureTime']);

                // Extract the date and time separately
                String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime); // Format: 2024-09-17
                String formattedTime = DateFormat('HH:mm').format(dateTime);
                return Card(
                  child: ListTile(
                    title: Text("Vehicle Ref: ${bus['vehicleRef']}"),
                    subtitle: Text("Origin : ${bus['originName']}\nDestination : ${bus['destinationName']}\nLine Ref: ${bus['lineRef']}\nDeparture Date: ${formattedDate}  Departure Time: ${formattedTime}"),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class TicketBookingScreen extends StatefulWidget {
  final List<String> origins;
  final List<String> destinations;

  TicketBookingScreen({required this.origins, required this.destinations});
  @override
  _TicketBookingScreenState createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends State<TicketBookingScreen> {
  String? selectedStartLocation;
  String? selectedStopLocation;
  int ticketCount = 1;

  List<String> locationList = ['Thambaram', 'Irumbuliyr', 'Perungalathur', 'Vandalur Railway station', 'Vandalur'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Tickets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedStartLocation,
              hint: Text("Select Start Location"),
              items: widget.origins.map((String location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedStartLocation = newValue!;
                });
              },
            ),
            DropdownButton<String>(
              value: selectedStopLocation,
              hint: Text("Select Stop Location"),
              items: widget.origins.map((String location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedStopLocation = newValue!;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: "Number of Tickets"),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  ticketCount = int.parse(value);
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentScreen()),
                );
              },
              child: Text("Proceed to Payment"),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Options'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.credit_card),
              title: Text("Credit Card"),
              onTap: () {
                _onPaymentSuccess(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.mobile_friendly),
              title: Text("Mobile Payment"),
              onTap: () {
                _onPaymentSuccess(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.money),
              title: Text("Cash"),
              onTap: () {
                _onPaymentSuccess(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onPaymentSuccess(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRCodeScreen()),
    );
  }
}


class QRCodeScreen extends StatefulWidget {
  @override
  _QRCodeScreenState createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  String phoneNumber = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Ticket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: "Phone Number"),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                setState(() {
                  phoneNumber = value;
                });
              },
            ),
            SizedBox(height: 20),
            QrImageView(
              data: "Ticket Info: Bus Stop - Destination", // Example data
              version: QrVersions.auto,
              size: 200.0,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (phoneNumber.isNotEmpty) {
                  // Simulate sending QR code via SMS
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('QR Code sent to $phoneNumber'),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Printing QR Code...'),
                  ));
                }
              },
              child: Text("Send to Phone or Print"),
            ),
          ],
        ),
      ),
    );
  }
}
