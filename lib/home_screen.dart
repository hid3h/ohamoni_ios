import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _WakeUpTimerPageState();
}

class _WakeUpTimerPageState extends State<HomeScreen> {
  WakeUpDateTimeList _wakeUpDateTimes = WakeUpDateTimeList([]);

  @override
  void initState() {
    super.initState();
    _loadWakeUpTimes();
  }

  void _loadWakeUpTimes() async {
    final wakeUpDateTimes = await WakeUpDateTimeList.fetchWakeUpDateTime();
    setState(() {
      _wakeUpDateTimes = wakeUpDateTimes;
    });
  }

  void _recordWakeUpTime(DateTime wakeupDateTime) {
    WakeUpDateTimeList.recordWakeUpTime(wakeupDateTime);
    _loadWakeUpTimes();
  }

  void _showDateTimePicker(BuildContext context) async {
    final DateTime? pickedDateTime = await DatePicker.showDateTimePicker(
      context,
      currentTime: DateTime.now(),
      minTime: DateTime(2000),
      maxTime: DateTime.now(),
      locale: LocaleType.jp,
    );

    if (pickedDateTime != null) {
      _recordWakeUpTime(pickedDateTime);
    }
  }

  List<FlSpot> _getChartData() {
    final List<FlSpot> spots = [];
    final weekDates = _getWeekDates();
    debugPrint('週の日付: $weekDates');

    for (int i = 0; i < weekDates.length; i++) {
      final date = weekDates[i];
      final wakeUpDateTime = _wakeUpDateTimes.findSameDate(date);
      debugPrint('日付: $date, 起床時間: $wakeUpDateTime');
      if (wakeUpDateTime != null) {
        final spot = FlSpot(
            i.toDouble(), wakeUpDateTime.minutesSinceMidnight().toDouble());
        spots.add(spot);
      }
    }
    debugPrint('チャートデータ: $spots');
    return spots;
  }

  List<DateTime> _getWeekDates() {
    final now = DateTime.now();
    final lastSunday = now.weekday == DateTime.sunday
        ? now
        : now.subtract(Duration(days: now.weekday));

    return List.generate(7, (index) => lastSunday.add(Duration(days: index)));
  }

  (double, double) _getYAxisRange() {
    final spots = _getChartData();
    if (spots.isEmpty) {
      return (0, 1440); // 0:00から24:00までの範囲（分単位）
    }

    final minY = spots.map((spot) => spot.y).reduce((a, b) => min(a, b));
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => max(a, b));

    double lowerBound;
    if (minY <= 60) {
      lowerBound = 0; // 0:00 ~ 1:00 は0時に
    } else {
      lowerBound = (minY ~/ 60) * 60.0; // 1:01~24:00は60で割って切り捨ての時間に
    }

    double upperBound;
    if (maxY >= 1380) {
      // 23:00 以降
      upperBound = 1440; // 23:00~24:00は24時に
    } else {
      upperBound = ((maxY ~/ 60) + 1) * 60.0; // 0:00~22:59は60で割って切り上げの時間に
    }

    return (lowerBound, upperBound);
  }

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = Localizations.localeOf(context).toString();
    final (minY, maxY) = _getYAxisRange();
    debugPrint('Y軸の範囲: ($minY, $maxY)');
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          SizedBox(
            width: screenWidth * 0.95,
            height: screenWidth * 0.95 * 0.65,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: true,
                    horizontalInterval: 30, // 30分ごとにグリッド線を表示,
                    verticalInterval: 1,
                    // これがあるとgridの線をデザインできて点線じゃなくなるみたい
                    // getDrawingHorizontalLine: (value) {
                    //   return FlLine(
                    //     color: Colors.grey[300],
                    //     strokeWidth: 1,
                    //   );
                    // },
                    // getDrawingVerticalLine: (value) {
                    //   return FlLine(
                    //     color: Colors.grey[300],
                    //     strokeWidth: 1,
                    //   );
                    // },
                  ),
                  titlesData: FlTitlesData(
                    // x軸とy軸のタイトルを表示するのに必要
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 60, // 1時間ごとにタイトルを表示,
                        getTitlesWidget: (value, meta) {
                          int hours = (value ~/ 60).toInt();
                          return Text('$hours');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) {
                            return const SizedBox.shrink();
                          }
                          final weekDates = _getWeekDates();
                          final date = weekDates[value.toInt()];
                          Color textColor;
                          if (date.weekday == DateTime.sunday) {
                            textColor = Colors.red;
                          } else if (date.weekday == DateTime.saturday) {
                            textColor = Colors.blue;
                          } else {
                            textColor = Colors.black;
                          }
                          return Text(
                            '${date.day}',
                            style: TextStyle(
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                        // reservedSize: 30,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  // タッチ操作時の設定
                  lineTouchData:
                      const LineTouchData(handleBuiltInTouches: false),
                  maxX: 6,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getChartData(),
                      isCurved: false,
                      color: Colors.orange,
                      // dotData: FlDotData(
                      //   show: true,
                      //   getDotPainter: (spot, percent, barData, index) {
                      //     return FlDotCirclePainter(
                      //       radius: 6,
                      //       color: Colors.orange,
                      //       strokeWidth: 2,
                      //       strokeColor: Colors.white,
                      //     );
                      //   },
                      // ),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                final wakeUpDateTimeValues = _wakeUpDateTimes.values;
                return ListView.builder(
                  itemCount: wakeUpDateTimeValues.length,
                  itemBuilder: (context, index) {
                    final wakeUpDateTime = wakeUpDateTimeValues[index];
                    return Container(
                      margin: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.blue,
                            width: 3.0,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 1.0, 1.0, 1.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wakeUpDateTime.formattedDate(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '起床時間: ${wakeUpDateTime.formattedTime()}',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDateTimePicker(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class WakeUpDateTime {
  final DateTime _value;

  factory WakeUpDateTime.fromString(String wakeUpDateTimeString) {
    return WakeUpDateTime(
        DateFormat('yyyy-MM-dd HH:mm').parse(wakeUpDateTimeString));
  }

  WakeUpDateTime(this._value);

  formattedDate() {
    return DateFormat('yyyy年MM月dd日 (E)').format(_value);
  }

  formattedTime() {
    return DateFormat('HH:mm').format(_value);
  }

  compareTo(WakeUpDateTime other) {
    return _value.compareTo(other._value);
  }

  bool isSameDate(DateTime other) {
    return _value.year == other.year &&
        _value.month == other.month &&
        _value.day == other.day;
  }

  int minutesSinceMidnight() {
    return _value.hour * 60 + _value.minute;
  }
}

class WakeUpDateTimeList {
  final List<WakeUpDateTime> values;

  WakeUpDateTimeList(this.values);

  static recordWakeUpTime(DateTime wakeupDateTime) {
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(wakeupDateTime);
    _saveWakeUpTimeToPrefs(formattedTime);
  }

  static Future<WakeUpDateTimeList> fetchWakeUpDateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final wakeUpDateTimeStrings = prefs.getStringList('wakeUpTimes') ?? [];

    final List<String> temp = [];
    final List<WakeUpDateTime> ret = [];

    for (final wakeUpDateTimeString in wakeUpDateTimeStrings) {
      final date = wakeUpDateTimeString.split(' ')[0];
      if (!temp.contains(date)) {
        temp.add(date);
        ret.add(WakeUpDateTime.fromString(wakeUpDateTimeString));
      }
    }
    ret.sort((a, b) => b.compareTo(a));

    return WakeUpDateTimeList(ret);
  }

  static _saveWakeUpTimeToPrefs(String formattedTime) async {
    final prefs = await SharedPreferences.getInstance();
    final wakeUpTimes = prefs.getStringList('wakeUpTimes') ?? [];
    wakeUpTimes.insert(0, formattedTime);
    await prefs.setStringList('wakeUpTimes', wakeUpTimes);
  }

  WakeUpDateTime? findSameDate(DateTime date) {
    return values.firstWhereOrNull((wt) => wt.isSameDate(date));
  }
}
