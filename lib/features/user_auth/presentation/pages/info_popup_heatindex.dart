import 'package:flutter/material.dart';

class InfoPopup extends StatelessWidget {
  const InfoPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Heat Index',
        style: TextStyle(
          fontFamily: 'handjet',
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The Heat Index provides a measure of perceived temperature based on humidity and actual temperature. It is an important indicator of how hot it feels to the human body.',
            style: TextStyle(
              fontFamily: 'handjet',
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Warning Levels based on Heat Index:',
            style: TextStyle(
              fontFamily: 'handjet',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),

          // Low Risk
          Container(
            color: Colors.blue[300],
            padding: const EdgeInsets.all(5),
            child: const Text(
              '1. **Low Risk (Below 27°C):** Normal conditions, no risk of heat-related illness.',
              style: TextStyle(
                fontFamily: 'handjet',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),

// Moderate Risk
          Container(
            color: Colors.green[300],
            padding: const EdgeInsets.all(5),
            child: const Text(
              '2. **Moderate Risk (27°C - 32°C):** Caution is advised for sensitive individuals. Stay hydrated.',
              style: TextStyle(
                fontFamily: 'handjet',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),

// High Risk
          Container(
            color: Colors.yellow[300],
            padding: const EdgeInsets.all(5),
            child: const Text(
              '3. **High Risk (32°C - 40°C):** Take precautions. Prolonged exposure may lead to heat-related illness.',
              style: TextStyle(
                fontFamily: 'handjet',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),

// Very High Risk
          Container(
            color: Colors.orange[300],
            padding: const EdgeInsets.all(5),
            child: const Text(
              '4. **Very High Risk (40°C - 54°C):** Extreme precautions needed to avoid heat-related illnesses.',
              style: TextStyle(
                fontFamily: 'handjet',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),

// Extreme Risk
          Container(
            color: Colors.red[300],
            padding: const EdgeInsets.all(5),
            child: const Text(
              '5. **Extreme Risk (Above 54°C):** High risk of heatstroke and other severe health issues. Avoid outdoor activities.',
              style: TextStyle(
                fontFamily: 'handjet',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Text(
            'Source: National Weather Service, Heat Index Guidelines.',
            style: TextStyle(
              fontFamily: 'handjet',
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(color: Colors.green),
          ),
        ),
      ],
    );
  }
}
