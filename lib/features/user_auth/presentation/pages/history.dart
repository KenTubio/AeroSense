import 'package:aerosense_ph/features/user_auth/presentation/pages/aqa_provider.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/back_button_handler.dart';
import 'package:aerosense_ph/features/user_auth/presentation/pages/cautionpage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class DailyAverageChartScreen extends StatefulWidget {
  const DailyAverageChartScreen({super.key});

  @override
  _DailyAverageChartScreenState createState() =>
      _DailyAverageChartScreenState();
}

class _DailyAverageChartScreenState extends State<DailyAverageChartScreen> {
  List<ChartData> dailyAverages = [];
  List<ChartData> filteredData = [];
  bool isLoading = false; // Track loading state

  late Timer _timer;
  static const String authToken = 'Cc4I-8AMONW2CZwWkd-bZEz10otAcMOw';
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  final List<int> futureYears =
      List.generate(DateTime.now().year - 2021 + 1, (index) => 2021 + index);

  @override
  void initState() {
    super.initState();
    loadDataFromFirestore();

    _timer = Timer.periodic(
        const Duration(minutes: 1), (timer) => fetchAndStoreData());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> fetchAndStoreData() async {
    await fetchAndAddData();
    await loadDataFromFirestore();
  }

  Future<void> fetchAndAddData() async {
    try {
      final dailyAverage = await fetchDailyAverageGas();
      if (dailyAverage != null) {
        final now = DateTime.now().toLocal();
        final currentDate = DateTime(now.year, now.month, now.day);

        final collectionRef =
            FirebaseFirestore.instance.collection('daily_gas');
        final querySnapshot = await collectionRef
            .where('date', isEqualTo: Timestamp.fromDate(currentDate))
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          var doc = querySnapshot.docs.first;
          await doc.reference
              .update({'value': dailyAverage, 'time': Timestamp.now()});

          dailyAverages.removeWhere((data) =>
              data.date.year == currentDate.year &&
              data.date.month == currentDate.month &&
              data.date.day == currentDate.day);
          dailyAverages.add(ChartData(currentDate, dailyAverage));
        } else {
          await storeDataInFirestore(currentDate, dailyAverage);
          dailyAverages.add(ChartData(currentDate, dailyAverage));
        }

        dailyAverages.sort((a, b) => a.date.compareTo(b.date));
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void showClearHistoryDialog() {
    int tempSelectedMonth = DateTime.now().month;
    int tempSelectedYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text(
                "Clear History",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color.fromARGB(255, 18, 18, 19),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: tempSelectedMonth,
                    dropdownColor: const Color.fromARGB(255, 18, 18, 19),
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(_getMonthName(index)),
                      );
                    }),
                    onChanged: (value) {
                      setDialogState(() {
                        tempSelectedMonth = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<int>(
                    value: tempSelectedYear,
                    dropdownColor: const Color.fromARGB(255, 18, 18, 19),
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: futureYears.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text("$year"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        tempSelectedYear = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Show loading state
                    setDialogState(() {
                      isLoading = true;
                    });

                    // Perform the deletion
                    await clearHistory(tempSelectedMonth, tempSelectedYear);

                    // Hide loading state and close dialog
                    setDialogState(() {
                      isLoading = false;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text("Clear"),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> clearHistory(int month, int year) async {
    try {
      final collectionRef = FirebaseFirestore.instance.collection('daily_gas');

      // Query documents matching the specified month and year
      final querySnapshot = await collectionRef
          .where('date',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(DateTime(year, month, 1)))
          .where('date',
              isLessThan: Timestamp.fromDate(DateTime(year, month + 1, 1)))
          .get();

      // Delete all matching documents in parallel
      final deleteFutures =
          querySnapshot.docs.map((doc) => doc.reference.delete());
      await Future.wait(deleteFutures);

      // Reload data to reflect changes in the chart
      await loadDataFromFirestore();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "History cleared successfully.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error clearing history: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to clear history.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
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
      'date': Timestamp.fromDate(date), // Store as Timestamp
      'value': value,
    });
  }

  Future<void> loadDataFromFirestore() async {
    final collectionRef = FirebaseFirestore.instance.collection('daily_gas');
    final snapshot = await collectionRef.get();

    Map<String, ChartData> uniqueDataMap = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final dateField = data['date'];
      final valueField = data['value'];

      if (dateField is Timestamp && valueField != null) {
        final date = dateField.toDate();
        final dateString = '${date.year}-${date.month}-${date.day}';

        double value = valueField is String
            ? double.tryParse(valueField) ?? 0.0
            : valueField.toDouble();

        if (!uniqueDataMap.containsKey(dateString)) {
          uniqueDataMap[dateString] = ChartData(date, value);
        } else {
          uniqueDataMap[dateString] = ChartData(date, value);
        }
      } else {
        print('Document missing required fields: ${doc.id}');
      }
    }

    List<ChartData> uniqueData = uniqueDataMap.values.toList();

    // Sort the data by date
    uniqueData.sort((a, b) => a.date.compareTo(b.date));

    setState(() {
      dailyAverages = uniqueData;
      filterDataByMonthAndYear(selectedMonth, selectedYear);
    });
  }

  void filterDataByMonthAndYear(int month, int year) {
    filteredData = dailyAverages
        .where((data) => data.date.year == year && data.date.month == month)
        .toList();
    setState(() {});
  }

  String formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: () async {
        return await BackButtonHandler.handleBackButton(context);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromARGB(255, 18, 18, 19),
          title: const Center(
            child: Text(
              'Hourly Average AQA Chart',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'handjet',
                  letterSpacing: 2.0,
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: Container(
          color: const Color.fromARGB(255, 18, 18, 19),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Image.asset(
                                  'assets/img/mainlogo.png',
                                  width: 150,
                                  height: 85,
                                ),
                                content: const SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "AeroSense provides real-time air quality data every second, calculating hourly averages based on each second's data. This helps track pollutant fluctuations and make timely decisions to maintain a healthier indoor environment.",
                                        style: TextStyle(fontSize: 14),
                                        textAlign: TextAlign.justify,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "Hourly Average Air Quality Scale:",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "• Good (0-50): Air quality is considered satisfactory and air pollution poses little or no risk.\n\n"
                                        "• Moderate (51-100): Air quality is acceptable; however, there may be some minor health concerns for a very small group of sensitive individuals.\n\n"
                                        "• Sensitive Levels (101-150): Members of sensitive groups may experience health effects. The general public is less likely to be affected.\n\n"
                                        "• Unhealthy (151-200): Health alert; everyone may begin to experience health effects, and sensitive groups may experience more serious effects.\n\n"
                                        "• Harmful (201-300): Health warning of emergency conditions. The entire population is more likely to be affected.\n\n"
                                        "• Hazardous (301-500): Serious health effects or emergencies. The entire population may experience significant health effects.\n",
                                        style: TextStyle(fontSize: 14),
                                        textAlign: TextAlign.justify,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "The hourly average helps mitigate the effects of short-term pollution spikes and supports timely interventions such as issuing alerts and minimizing exposure for sensitive individuals.",
                                        style: TextStyle(fontSize: 14),
                                        textAlign: TextAlign.justify,
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("OK"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text(
                              _getMonthName(index),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedMonth = value;
                              filterDataByMonthAndYear(
                                  selectedMonth, selectedYear);
                            });
                          }
                        },
                        dropdownColor: const Color.fromARGB(255, 18, 18, 19),
                        iconEnabledColor: Colors.white,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      DropdownButton<int>(
                        value: selectedYear,
                        items: futureYears.map((year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(
                              "$year",
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedYear = value;
                              filterDataByMonthAndYear(
                                  selectedMonth, selectedYear);
                            });
                          }
                        },
                        dropdownColor: const Color.fromARGB(255, 18, 18, 19),
                        iconEnabledColor: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HazardousMonitorPage()),
                          );
                        },
                        child: const Icon(
                          Icons.warning_amber_outlined,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  showClearHistoryDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  "Clear History",
                  style: TextStyle(
                    fontFamily: 'handjet',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(
                        labelStyle: TextStyle(color: Colors.green),
                        majorGridLines: MajorGridLines(width: 0),
                        labelRotation: 45,
                        interval: 1,
                      ),
                      primaryYAxis: const NumericAxis(
                        title: AxisTitle(
                            text: 'Air Quality Analysis',
                            textStyle: TextStyle(color: Colors.white)),
                        minimum: 0,
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      series: <CartesianSeries>[
                        ColumnSeries<ChartData, String>(
                          dataSource: filteredData,
                          xValueMapper: (ChartData data, _) =>
                              formatDate(data.date),
                          yValueMapper: (ChartData data, _) => data.value,
                          name: 'AQA History',
                          color: Colors.green,
                        ),
                      ],
                      tooltipBehavior: TooltipBehavior(enable: true),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int index) {
    const monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return monthNames[index];
  }
}

class ChartData {
  final DateTime date;
  final double value;

  ChartData(this.date, this.value);
}
