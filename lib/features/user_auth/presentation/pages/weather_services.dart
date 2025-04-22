import 'dart:convert';
import 'package:aerosense_ph/features/user_auth/presentation/pages/back_button_handler.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '3573c2d59b01442489631411242610';
  final String baseUrl = 'http://api.weatherapi.com/v1';

  Future<Map<String, dynamic>> fetchWeather(String query) async {
    final url = '$baseUrl/current.json?key=$apiKey&q=$query&aqi=no';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (error) {
      throw Exception('Failed to load weather data: $error');
    }
  }
}

class WeatherSection extends StatefulWidget {
  const WeatherSection({Key? key}) : super(key: key);

  @override
  _WeatherSectionState createState() => _WeatherSectionState();
}

class _WeatherSectionState extends State<WeatherSection> {
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  // Default cities in the Philippines
  final List<String> defaultCities = [
    "Manila",
    "Cebu City",
    "Davao City",
    "Baguio",
    "Iloilo City",
    "Zamboanga City",
    "Bacolod",
    "Cagayan de Oro",
    "Tagaytay",
    "General Santos"
  ];
  List<Map<String, dynamic>> defaultCitiesWeather = [];

  @override
  void initState() {
    super.initState();
    fetchDefaultCitiesWeather();
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchDefaultCitiesWeather() async {
    setState(() {
      isLoading = true;
      defaultCitiesWeather = [];
    });

    WeatherService weatherService = WeatherService();

    try {
      for (String city in defaultCities) {
        final data = await weatherService.fetchWeather(city);
        defaultCitiesWeather.add(data);
      }
      setState(() {
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      showErrorDialog('Failed to load default cities. Error: $error');
    }
  }

  void searchCity() async {
    FocusScope.of(context).unfocus(); // Dismiss keyboard
    setState(() {
      isLoading = true;
    });

    WeatherService weatherService = WeatherService();
    try {
      final data = await weatherService.fetchWeather(_searchController.text);

      // Check if the country is the Philippines
      if (data['location']['country'] != 'Philippines') {
        setState(() {
          isLoading = false;
        });
        showErrorDialog('City is not from the Philippines.');
        return;
      }

      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      showErrorDialog('City not found. Please try again.');
    }
  }

  Future<void> fetchWeatherByLocation() async {
    FocusScope.of(context).unfocus(); // Dismiss keyboard
    setState(() {
      isLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showErrorDialog('Location permission denied.');
          setState(() {
            isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        showErrorDialog(
            'Location permission is permanently denied. Please enable it in the app settings.');
        setState(() {
          isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      WeatherService weatherService = WeatherService();
      final data = await weatherService.fetchWeather(
        '${position.latitude},${position.longitude}',
      );

      setState(() {
        weatherData = data;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      showErrorDialog('Failed to get location or weather data. Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Call the BackButtonHandler for handling back press
        return await BackButtonHandler.handleBackButton(context);
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 18, 18, 19),
        appBar: AppBar(
          title: const Text(
            'AeroSense Weather',
            style: TextStyle(
              fontFamily: 'Handjet',
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchDefaultCitiesWeather,
            ),
          ],
          backgroundColor: const Color.fromARGB(255, 18, 18, 19),
        ),
        body: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search City',
                        labelStyle:
                            TextStyle(color: Colors.white, fontSize: 13),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: searchCity,
                    child: Container(
                      height: 55,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Search',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'handjet',
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: fetchWeatherByLocation,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Current Location Weather',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'handjet',
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : weatherData != null
                        ? buildWeatherInfo(weatherData!)
                        : ListView.builder(
                            itemCount: defaultCitiesWeather.length,
                            itemBuilder: (context, index) {
                              return buildWeatherInfo(
                                  defaultCitiesWeather[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildWeatherInfo(Map<String, dynamic> data) {
    String condition = data['current']['condition']['text'];
    String iconUrl = data['current']['condition']['icon'];
    String cityName = data['location']['name'];
    String temperature = '${data['current']['temp_c']} °C';
    String humidity = '${data['current']['humidity']}%';
    String windSpeed = '${data['current']['wind_kph']} kph';
    String pressure = '${data['current']['pressure_mb']}';
    String cloudCoverage = '${data['current']['cloud']}';
    String feelsLike = '${data['current']['feelslike_c']}';

    return Center(
      // Wrap the Card in Center to make it take only as much space as needed
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        shadowColor: Colors.black.withOpacity(0.8),
        color: const Color.fromARGB(255, 55, 55, 56),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.network('http:$iconUrl', width: 50, height: 50),
                  const SizedBox(width: 10),
                  Text(
                    condition,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'City: $cityName',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              Text(
                'Temperature: $temperature',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              Text(
                'Humidity: $humidity',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              Text(
                'Wind Speed: $windSpeed',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 10),
              // Adding more weather information
              Text(
                'Pressure: $pressure hPa',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              Text(
                'Cloud Coverage: $cloudCoverage%',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              Text(
                'Feels Like: $feelsLike °C',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
