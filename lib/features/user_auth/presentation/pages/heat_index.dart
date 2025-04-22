import 'package:aerosense_ph/features/user_auth/presentation/pages/info_popup_heatindex.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // For decoding JSON
import 'package:http/http.dart' as http;
import 'dart:async'; // For using Timer
import 'dart:math';

class HeatIndex extends StatefulWidget {
  @override
  _HeatIndexState createState() => _HeatIndexState();
}

class _HeatIndexState extends State<HeatIndex>
    with SingleTickerProviderStateMixin {
  double? temperature;
  double? humidity;
  double? heatIndex;
  bool isLoading = false; // To track the loading state

  final String blynkToken = 'Cc4I-8AMONW2CZwWkd-bZEz10otAcMOw';
  Timer? _timer;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true); // Initializes and starts the animation
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchData(false); // Fetch data silently without showing loading animation
    });
    fetchData(false); // Initial fetch without showing loading animation
  }

  @override
  void dispose() {
    _controller.dispose(); // Disposes the animation controller
    _timer?.cancel(); // Cancels the timer
    super.dispose();
  }

  Future<void> fetchData(bool showLoading) async {
    if (showLoading) {
      setState(() {
        isLoading = true; // Show the loading indicator
      });
    }

    try {
      final temperatureResponse = await http.get(Uri.parse(
          'https://blynk.cloud/external/api/get?token=$blynkToken&V3'));
      final humidityResponse = await http.get(Uri.parse(
          'https://blynk.cloud/external/api/get?token=$blynkToken&V4'));

      if (temperatureResponse.statusCode == 200 &&
          humidityResponse.statusCode == 200) {
        setState(() {
          temperature = double.tryParse(temperatureResponse.body);
          humidity = double.tryParse(humidityResponse.body);

          if (temperature != null && humidity != null) {
            heatIndex = calculateHeatIndex(temperature!, humidity!);
          }
        });
      } else {
        throw Exception('Failed to fetch data from Blynk');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      if (showLoading) {
        setState(() {
          isLoading = false; // Hide the loading indicator
        });
      }
    }
  }

  double calculateHeatIndex(double temperature, double humidity) {
    double hi = -8.78469475556 +
        1.61139411 * temperature +
        2.33854883889 * humidity +
        -0.14611605 * temperature * humidity +
        -0.012308094 * temperature * temperature +
        -0.0164248277778 * humidity * humidity +
        0.002211732 * temperature * temperature * humidity +
        0.00072546 * temperature * humidity * humidity +
        -0.00000358 * temperature * temperature * humidity * humidity;

    return hi;
  }

  Color getHeatIndexColor(double heatIndex) {
    if (heatIndex >= 27 && heatIndex < 32) {
      return Colors.green;
    } else if (heatIndex >= 32 && heatIndex < 40) {
      return Colors.yellow;
    } else if (heatIndex >= 40 && heatIndex < 54) {
      return Colors.orange;
    } else if (heatIndex >= 54) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Indoor Heat Index',
          style: TextStyle(
            fontFamily: 'Handjet',
            fontSize: 28,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Sets the back button color to white
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const InfoPopup(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black,
                      Colors.blueGrey.withOpacity(_controller.value),
                      Colors.black,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  size: const Size(300, 300),
                  painter: HeatIndexGaugePainter(
                      heatIndex ?? 0, temperature ?? 0, humidity ?? 0),
                ),
                const SizedBox(height: 30),
                GlassmorphismCard(
                  temperature: temperature,
                  humidity: humidity,
                  heatIndex: heatIndex,
                  heatIndexColor: getHeatIndexColor(heatIndex ?? 0),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.cyan,
              child: isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              onPressed: () =>
                  fetchData(true), // Show loading animation on click
            ),
          ),
        ],
      ),
    );
  }
}

class HeatIndexGaugePainter extends CustomPainter {
  final double heatIndex;
  final double temperature;
  final double humidity;

  HeatIndexGaugePainter(this.heatIndex, this.temperature, this.humidity);

  @override
  void paint(Canvas canvas, Size size) {
    // Paint for filling the circle with the color of the heat index level
    final paint = Paint()
      ..color = getHeatIndexColor(heatIndex)
          .withOpacity(0.75) // Color based on heat index level
      ..style = PaintingStyle.fill; // Fill the circle with color

    // Adjust the circle size (e.g., 70% of the available width)
    final radius = size.width * 0.9 / 2; // 70% of the available width
    canvas.drawCircle(size.center(Offset.zero), radius, paint);

    // Paint for the shadow text (slightly offset) for heat index value
    final shadowTextPainter = TextPainter(
      text: TextSpan(
        text: '${heatIndex.toStringAsFixed(1)}°C', // Display heat index value
        style: TextStyle(
          fontFamily: 'Handjet', // Set the Handjet font
          color: Colors.black.withOpacity(0.6), // Dark shadow color
          fontSize: 40, // Font size
          fontWeight: FontWeight.bold, // Bold text
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: size.width);

    // Paint shadow text slightly offset
    shadowTextPainter.paint(
      canvas,
      Offset(size.width / 2 - shadowTextPainter.width / 2 + 2,
          size.height / 2 - shadowTextPainter.height / 2 + 2),
    );

    // Paint the actual heat index text on top of the shadow
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${heatIndex.toStringAsFixed(1)}°C', // Display heat index value
        style: TextStyle(
          fontFamily: 'Handjet', // Set the Handjet font
          color: Colors.white, // Text color
          fontSize: 40, // Font size
          fontWeight: FontWeight.bold, // Bold text
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: size.width);

    // Paint the actual heat index text on top of the shadow
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2,
          size.height / 2 - textPainter.height / 2),
    );

    // Now, paint the temperature and humidity below the heat index
    final tempAndHumidTextPainter = TextPainter(
      text: TextSpan(
        text:
            '🌡️${temperature.toStringAsFixed(1)}°C  ' // Space between temp and humidity
            '💧${humidity.toStringAsFixed(1)}%', // Humidity
        style: const TextStyle(
          fontFamily: 'Handjet', // Set the Handjet font
          color: Colors.white, // Text color
          fontSize: 18, // Font size for temperature and humidity
          fontWeight: FontWeight.normal, // Regular text weight
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: size.width);

    // Paint the temperature and humidity text below the heat index
    tempAndHumidTextPainter.paint(
      canvas,
      Offset(
          size.width / 2 - tempAndHumidTextPainter.width / 2,
          size.height / 2 +
              textPainter.height / 2 +
              10), // 10 is the space between the heat index and temp/humidity text
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  Color getHeatIndexColor(double heatIndex) {
    if (heatIndex >= 27 && heatIndex < 32) {
      return Colors.green;
    } else if (heatIndex >= 32 && heatIndex < 40) {
      return Colors.yellow;
    } else if (heatIndex >= 40 && heatIndex < 54) {
      return Colors.orange;
    } else if (heatIndex >= 54) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }
}

class GlassmorphismCard extends StatelessWidget {
  final double? temperature;
  final double? humidity;
  final double? heatIndex;
  final Color heatIndexColor;

  const GlassmorphismCard({
    required this.temperature,
    required this.humidity,
    required this.heatIndex,
    required this.heatIndexColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Center the specific warning part and justify the rest

          Text(
            getHeatIndexRecommendation(
                heatIndex ?? 0), // Get recommendation based on heat index
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.justify, // Justify the remaining text
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String getHeatIndexRecommendation(double heatIndex) {
    if (heatIndex < 27) {
      return 'Safe indoor heat index level.\n\n'
          '- Maintain hydration even at lower temperatures.\n'
          '- Perform regular maintenance of cooling devices.\n'
          '- Stay alert to changes in indoor temperature.\n'
          '- Avoid excessive indoor humidity.';
    } else if (heatIndex >= 27 && heatIndex < 32) {
      return 'Moderate: Take precautions.\n\n'
          '- Use fans or air circulators to maintain airflow.\n'
          '- Drink water to stay hydrated.\n'
          '- Avoid excessive physical activity indoors.\n'
          '- Close blinds or curtains to reduce indoor heat from the sun.';
    } else if (heatIndex >= 32 && heatIndex < 40) {
      return 'Yellow Warning: High indoor heat.\n\n'
          '- Open windows to allow airflow.\n'
          '- Use damp cloths or cooling devices to lower body temperature.\n'
          '- Regularly monitor indoor temperatures.\n'
          '- Avoid using heat-generating appliances.';
    } else if (heatIndex >= 40 && heatIndex < 54) {
      return 'Orange Warning: Very high indoor heat index.\n\n'
          '- Take regular breaks to rest and hydrate.\n'
          '- Monitor vulnerable individuals (children, elderly).\n'
          '- Limit physical activity and avoid outdoor exposure.\n'
          '- Use cooling gels or ice packs for quick relief.';
    } else {
      return 'Red Warning: Extreme indoor heat index!\n\n'
          '- Seek medical attention if you feel symptoms of heatstroke.\n'
          '- Move to an air-conditioned room immediately.\n'
          '- Avoid staying in poorly ventilated areas.\n'
          '- Continuously monitor indoor heat levels and ensure adequate cooling.';
    }
  }
}
