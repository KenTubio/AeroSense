import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class DataTimerService {
  static const String authToken = 'Cc4I-8AMONW2CZwWkd-bZEz10otAcMOw';
  late Timer _timer;

  DataTimerService() {
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => fetchAndStoreData(),
    );
  }

  Future<void> fetchAndStoreData() async {
    final dailyAverage = await fetchDailyAverageGas();
    if (dailyAverage != null) {
      await storeDataInFirestore(DateTime.now(), dailyAverage);
    }
  }

  Future<double?> fetchDailyAverageGas() async {
    final url =
        Uri.parse('http://blynk.cloud/external/api/get?token=$authToken&V1');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return double.parse(response.body);
    } else {
      print('Failed to fetch daily average gas value: ${response.statusCode}');
      return null;
    }
  }

  Future<void> storeDataInFirestore(DateTime date, double value) async {
    final collectionRef = FirebaseFirestore.instance.collection('daily_gas');
    await collectionRef.add({
      'date': Timestamp.fromDate(date),
      'value': value,
    });
  }

  void dispose() {
    _timer.cancel();
  }
}
