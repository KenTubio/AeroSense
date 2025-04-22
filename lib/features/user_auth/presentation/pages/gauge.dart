import 'package:flutter/material.dart';
import 'dart:math';

class GaugeWidget extends StatelessWidget {
  const GaugeWidget({super.key, required this.needleValue});

  final double needleValue;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 300,
        child: CustomPaint(
          painter: GaugePainter(needleValue: needleValue),
        ),
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double needleValue;

  GaugePainter({required this.needleValue});

  @override
  void paint(Canvas canvas, Size size) {
    List<Map<String, dynamic>> segments = [
      {'label': 'Good', 'color': Colors.green, 'min': 0, 'max': 50},
      {'label': 'Moderate', 'color': Colors.yellow, 'min': 51, 'max': 100},
      {
        'label': 'Unhealthy for Sensitive Groups',
        'color': Colors.orange,
        'min': 101,
        'max': 150
      },
      {'label': 'Unhealthy', 'color': Colors.red, 'min': 151, 'max': 200},
      {
        'label': 'Very Unhealthy',
        'color': Colors.purple,
        'min': 201,
        'max': 300
      },
      {'label': 'Hazardous', 'color': Colors.brown, 'min': 301, 'max': 500},
    ];

    double totalSegments = segments.length.toDouble();
    double anglePerSegment = pi / totalSegments;

    for (int i = 0; i < segments.length; i++) {
      final Paint segmentPaint = Paint()
        ..color = segments[i]['color']
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height),
          radius: size.width / 2,
        ),
        pi + (anglePerSegment * i),
        anglePerSegment,
        true,
        segmentPaint,
      );

      double labelAngle = pi + (anglePerSegment * i) + anglePerSegment / 2;
      double labelX = (size.width / 2) + (size.width / 2.3) * cos(labelAngle);
      double labelY = size.height + 3 + (size.width / 2.18) * sin(labelAngle);

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: '${segments[i]['min']} - ${segments[i]['max']}',
          style: const TextStyle(
              color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      labelPainter.layout();
      labelPainter.paint(
          canvas,
          Offset(labelX - labelPainter.width / 2,
              labelY - labelPainter.height / 2));
    }

    double clampedNeedleValue = needleValue.clamp(0, 500);

    int segmentIndex = segments.indexWhere((segment) =>
        clampedNeedleValue >= segment['min'] &&
        clampedNeedleValue <= segment['max']);

    double needleNormalized = 0.0;

    if (segmentIndex != -1) {
      double segmentMin = segments[segmentIndex]['min'].toDouble();
      double segmentMax = segments[segmentIndex]['max'].toDouble();
      double segmentRange = segmentMax - segmentMin;

      needleNormalized = (clampedNeedleValue - segmentMin) / segmentRange;
    }

    double needleAngle =
        pi + (needleNormalized + segmentIndex) * anglePerSegment;

    double needleLength = size.width / 2 - 40;

    double needleX = (size.width / 2) + needleLength * cos(needleAngle);
    double needleY = size.height + needleLength * sin(needleAngle) - 10;

    final Paint needlePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawLine(
      Offset(size.width / 2, size.height),
      Offset(needleX, needleY),
      needlePaint,
    );

    const double arrowSize = 10;
    Path arrowPath = Path();
    arrowPath.moveTo(needleX, needleY);
    arrowPath.lineTo(needleX - arrowSize * cos(needleAngle - pi / 6),
        needleY - arrowSize * sin(needleAngle - pi / 6)); // Left arrow tip
    arrowPath.lineTo(needleX - arrowSize * cos(needleAngle + pi / 6),
        needleY - arrowSize * sin(needleAngle + pi / 6)); // Right arrow tip
    arrowPath.close();

    canvas.drawPath(arrowPath, needlePaint);

    final Paint basePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    const double needleBaseRadius = 10;
    canvas.drawCircle(
      Offset(size.width / 2, size.height),
      needleBaseRadius,
      basePaint,
    );

    final TextPainter valuePainter = TextPainter(
      text: TextSpan(
        text: clampedNeedleValue.toStringAsFixed(2), // Clamp the value here
        style: const TextStyle(
            color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    valuePainter.layout();
    valuePainter.paint(
      canvas,
      Offset(size.width / 2 - valuePainter.width / 2, size.height + 20),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
