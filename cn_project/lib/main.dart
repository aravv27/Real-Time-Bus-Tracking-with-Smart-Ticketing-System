import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class UserData {
  static final UserData _instance = UserData._internal();

  factory UserData() => _instance;
  late String _username;
  late String _phoneNumber;

  UserData._internal();

  String get username => _username;
  String get phoneNumber => _phoneNumber;

  void updateUsername(String username) {
    _username = username;
  }

  void updatePhoneNumber(String phoneNumber) {
    _phoneNumber = phoneNumber;
  }
}

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
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _login() async {
    final String apiUrl = 'http://192.168.1.8:500/login';
    final Map<String, dynamic> loginData = {
      'username': usernameController.text,
      'password': passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );

      if (response.statusCode == 200) {
        final userProfileResponse = await http.get(Uri.parse(
            'http://192.168.1.8:500/user-profile/${usernameController.text}'));
        if (userProfileResponse.statusCode == 200) {
          final userProfile = jsonDecode(userProfileResponse.body);
          // Update username and phone number in the singleton class
          UserData().updateUsername(userProfile['username']);
          UserData().updatePhoneNumber(userProfile['phone_number']);
          // Assuming the login is successful
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MapScreen()),
          );
        }
      } else {
        // Handle login failure
        _showErrorDialog('Login failed. Please check your credentials.');
      }
    } catch (e) {
      _showErrorDialog('Error during login: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistrationScreen()),
    );
  }

  @override
Widget build(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;
  return Scaffold(
    appBar: AppBar(
      title: Text('Get Tickets in Your FingerTips!'),
      centerTitle: true,
    ),
    body: Stack(
      children: [
        // Background Image with Blur Effect
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/bus.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Adjust the blur intensity as needed
            child: Container(
              color: Colors.black.withOpacity(0.1), // Optional color overlay
            ),
          ),
        ),
        // Card with Unblurred Image
        Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Container(
              width: screenWidth * 0.9,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/bus.jpg"),
                  fit: BoxFit.cover,
                  //opacity: 0.2,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Login',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 300,
                      child: TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'UserName',
                          labelStyle: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          prefixIcon: Icon(
                            Icons.email,
                            color: Colors.white,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 300,
                      child: TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Colors.white,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        obscureText: true,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _login,
                      child: Text('Login'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shadowColor: Colors.blueAccent,
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateToRegister,
                      child: Text(
                        'New User? Register here',
                        style: TextStyle(color: Colors.yellow.shade100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  Future<void> _register() async {
    final String apiUrl = 'http://192.168.1.8:500/registration';
    final Map<String, dynamic> registrationData = {
      'username': usernameController.text,
      'password': passwordController.text,
      'phone_number': phoneNumberController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(registrationData),
      );

      if (response.statusCode == 201) {
        // Registration successful, navigate back to login
        Navigator.pop(context);
      } else {
        // Handle registration failure
        _showErrorDialog('Registration failed. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error during registration: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;
  return Scaffold(
    appBar: AppBar(
      title: Text('Experience Wonder by Registering'),
      centerTitle: true,
    ),
    body: Stack(
      children: [
        // Background Image with Blur Effect
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/login_card.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Adjust the blur intensity
            child: Container(
              color: Colors.black.withOpacity(0.1), // Optional color overlay
            ),
          ),
        ),
        // Card with Unblurred Image
        Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Container(
              width: screenWidth * 0.9, // Use a percentage of screen width
              padding: EdgeInsets.all(20),
              // Background image for the card
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/login_card.jpg"),
                  fit: BoxFit.cover,
                  //opacity: 0.2,
                ),
                borderRadius: BorderRadius.circular(10), // Match the card's border radius
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 400,
                      child: TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'UserName',
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          prefixIcon: Icon(Icons.email, color: Colors.white),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 400,
                      child: TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          prefixIcon: Icon(Icons.lock, color: Colors.white),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        obscureText: true,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 400,
                      child: TextField(
                        controller: phoneNumberController,
                        decoration: InputDecoration(
                          labelText: 'PhoneNumber',
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          prefixIcon: Icon(Icons.phone, color: Colors.white),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (usernameController.text.isNotEmpty &&
                            passwordController.text.isNotEmpty &&
                            phoneNumberController.text.isNotEmpty) {
                          _register();
                        } else {
                          _showErrorDialog('Please fill in all fields.');
                        }
                      },
                      child: Text('Register'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shadowColor: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _tickets = [];

  Future<void> _fetchTickets() async {
    final String apiUrl =
        'http://192.168.1.8:500/user-tickets/${UserData()._phoneNumber}';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('jsonData: $jsonData');
        if (jsonData is List) {
          setState(() {
            _tickets = jsonData
                .map((ticket) => ticket as Map<String, dynamic>)
                .toList();
          });
        } else {
          setState(() {
            _tickets = [jsonData as Map<String, dynamic>];
          });
        }
        print('_tickets: $_tickets');
      } else {
        throw Exception('Failed to load tickets');
      }
    } catch (e) {
      print('Error fetching tickets: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/user_background.jpg"),
                fit: BoxFit.cover,
                //opacity: 0.1
                )
                ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  child: ListTile(
                    title: Text(
                      'Username: ${UserData()._username}',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    subtitle: Text(
                      'Phone Number: ${UserData()._phoneNumber}',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: _tickets.isEmpty
                    ? Center(child: Text('No tickets purchased'))
                    : ListView.builder(
                        itemCount: _tickets.length,
                        itemBuilder: (context, index) {
                          return Column(children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 400,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 7,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(16),
                                child: ListTile(
                                  title: Text(
                                      'Start Location: ${_tickets[index]['origin']}\nStop Location: ${_tickets[index]['destination']}'),
                                  subtitle: Text(
                                      'Tickets: ${_tickets[index]['ticketCount']}'),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                          ]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
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
  final String apiUrl =
      'http://192.168.1.8:500/bus-locations'; // Your Flask backend URL
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
    _timer = Timer.periodic(
        Duration(minutes: 5), (Timer t) => _fetchAllBusLocations());
  }

  Future<void> _fetchAllBusLocations() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _busData = data.cast<Map<String, dynamic>>();
          _busMarkers = _busData.map((bus) {
            double latitude =
                double.tryParse(bus['latitude'].toString()) ?? 0.0;
            double longitude =
                double.tryParse(bus['longitude'].toString()) ?? 0.0;

            return Marker(
              point: LatLng(latitude, longitude),
              child: Container(
                child:
                    Icon(Icons.directions_bus, color: Colors.blue, size: 40.0),
              ),
            );
          }).toList();
          _origins = _busData
              .map((bus) => bus['originName'].toString())
              .toSet()
              .toList();
          _destinations = _busData
              .map((bus) => bus['destinationName'].toString())
              .toSet()
              .toList();

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
          (b) =>
              LatLng(double.tryParse(b['latitude'].toString()) ?? 0.0,
                  double.tryParse(b['longitude'].toString()) ?? 0.0) ==
              marker.point,
        );
        //if (bus == null) return false;

        bool matchesOrigin =
            _selectedOrigin == null || bus['originName'] == _selectedOrigin;
        bool matchesDestination = _selectedDestination == null ||
            bus['destinationName'] == _selectedDestination;

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
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      title: Text('Real-time Bus Tracking'),
      centerTitle: true,
    ),
    body: Stack(
      children: [
        // Map layer
        FlutterMap(
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
              markers: _filteredBusMarkers,
            ),
          ],
        ),
        // Dropdown overlays
        Positioned(
          top: 20,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Origin Dropdown Card
              Expanded(
                child: Card(
                  elevation: 4,
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    child: DropdownButton<String>(
                      value: _selectedOrigin,
                      hint: Text('Select Origin'),
                      isExpanded: true,
                      items: _origins.map((String origin) {
                        return DropdownMenuItem<String>(
                          value: origin,
                          child: Text(origin),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedOrigin = newValue;
                          _fetchFilteredBusLocations();
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16), // Space between the cards
              // Destination Dropdown Card
              Expanded(
                child: Card(
                  elevation: 4,
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    child: DropdownButton<String>(
                      value: _selectedDestination,
                      hint: Text('Select Destination'),
                      isExpanded: true,
                      items: _destinations.map((String destination) {
                        return DropdownMenuItem<String>(
                          value: destination,
                          child: Text(destination),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedDestination = newValue;
                          _fetchFilteredBusLocations();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    drawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.purple),
            child: Text("Navigation"),
          ),
          ListTile(
            title: const Text("Profile"),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
            },
          ),
          ListTile(
            title: const Text("Book tickets"),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => TicketBookingScreen(
                origins: _origins,
                destinations: _destinations,
              )));
            },
          ),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton(
      child: const Icon(Icons.directions_bus),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => YourBusScreen(
            busData: _busData,
            origins: _origins,
            destinations: _destinations,
          )),
        );
      },
    ),
  );
}}

class YourBusScreen extends StatefulWidget {
  final List<String> origins;
  final List<String> destinations;
  final List<Map<String, dynamic>> busData;

  YourBusScreen(
      {required this.origins,
      required this.destinations,
      required this.busData});

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
        bool matchesOrigin =
            selectedOrigin == null || bus['originName'] == selectedOrigin;
        bool matchesDestination = selectedDestination == null ||
            bus['destinationName'] == selectedDestination;
        return matchesOrigin && matchesDestination;
      }).toList();
    });
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Bus'),
      ),
      body: Stack(
        children: [
          // Map layer (You can replace this with your FlutterMap if needed)
          Container(
            color: Colors.blueGrey[100], // Placeholder for the map background
            // Replace with FlutterMap widget if using a map
          ),
          // Dropdown overlays
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Origin Dropdown Card
                Expanded(
                  child: Card(
                    elevation: 4,
                    color: Colors.white.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      child: DropdownButton<String>(
                        value: selectedOrigin,
                        hint: Text("Select Origin"),
                        isExpanded: true,
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
                    ),
                  ),
                ),
                SizedBox(width: 16), // Space between the cards
                // Destination Dropdown Card
                Expanded(
                  child: Card(
                    elevation: 4,
                    color: Colors.white.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      child: DropdownButton<String>(
                        value: selectedDestination,
                        hint: Text("Select Destination"),
                        isExpanded: true,
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
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List of filtered buses
          Positioned(
            top: 100, // Adjust as needed based on dropdown height
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: filteredBuses.map((bus) {
                  DateTime dateTime =
                      DateTime.parse(bus['originAimedDepartureTime']);

                  String formattedDate =
                      DateFormat('yyyy-MM-dd').format(dateTime);
                  String formattedTime = DateFormat('HH:mm').format(dateTime);
                  return Card(
                    child: ListTile(
                      title: Text("Vehicle Ref: ${bus['vehicleRef']}"),
                      subtitle: Text(
                          "Origin : ${bus['originName']}\nDestination : ${bus['destinationName']}\nLine Ref: ${bus['lineRef']}\nDeparture Date: ${formattedDate}  Departure Time: ${formattedTime}"),
                    ),
                  );
                }).toList(),
              ),
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

  Future<void> _bookTicket() async {
    final String apiUrl = 'http://192.168.1.8:500/book-ticket';
    final Map<String, dynamic> ticketData = {
      'origin': selectedStartLocation,
      'destination': selectedStopLocation,
      'ticketCount': ticketCount,
      'bookingTime': DateTime.now().toIso8601String(),
      'phone_number': UserData()._phoneNumber
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ticketData),
      );

      if (response.statusCode == 201) {
        print('Ticket booked successfully!');
      } else {
        print('Failed to book ticket: ${response.body}');
      }
    } catch (e) {
      print('Error booking ticket: $e');
    }
  }

 
    @override
  Widget build(BuildContext context) {
    // Get device screen dimensions
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Book Tickets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Prevent overflow
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Start Location Dropdown
                      DropdownButton<String>(
                        value: selectedStartLocation,
                        hint: Text("Select Start Location"),
                        isExpanded: true,
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
                      SizedBox(height: 16), // Space between dropdowns
                      // Stop Location Dropdown
                      DropdownButton<String>(
                        value: selectedStopLocation,
                        hint: Text("Select Stop Location"),
                        isExpanded: true,
                        items: widget.destinations.map((String location) {
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
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20), // Space between card and ticket count
              Container(
                width: screenWidth * 0.9, // Limit width to 90% of screen
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Number of Tickets",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      ticketCount = int.tryParse(value) ?? 1;
                    });
                  },
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (selectedStartLocation != null && selectedStopLocation != null) {
                    _bookTicket();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          startLocation: selectedStartLocation!,
                          stopLocation: selectedStopLocation!,
                          ticketCount: ticketCount,
                        ),
                      ),
                    );
                  } else {
                    // Show error if locations are not selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select both locations.")),
                    );
                  }
                },
                child: Text("Proceed to Payment"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class PaymentScreen extends StatelessWidget {
  final String startLocation;
  final String stopLocation;
  final int ticketCount;

  PaymentScreen(
      {required this.startLocation,
      required this.stopLocation,
      required this.ticketCount});
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
      MaterialPageRoute(
          builder: (context) => QRCodeScreen(
                startLocation: startLocation,
                stopLocation: stopLocation,
                ticketCount: ticketCount,
              )),
    );
  }
}

class QRCodeScreen extends StatefulWidget {
  final String startLocation;
  final String stopLocation;
  final int ticketCount;

  QRCodeScreen(
      {required this.startLocation,
      required this.stopLocation,
      required this.ticketCount});

  @override
  _QRCodeScreenState createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  String phoneNumber = "";

  @override
  Widget build(BuildContext context) {
    // Construct ticket details to be embedded in the QR code
    String qrData =
        "Ticket Info: Start - ${widget.startLocation}, Stop - ${widget.stopLocation}, Tickets: ${widget.ticketCount}";

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
              data: qrData, // Set QR code data to the ticket details
              version: QrVersions.auto,
              size: 200.0,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (phoneNumber.isNotEmpty) {
                  // Simulate sending QR code via SMS
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'QR Code with ticket details sent to $phoneNumber'),
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
