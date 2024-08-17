import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final wakeUpDateTimes = await WakeUpDateTimeList.fetchWakeUpTime();
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

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = Localizations.localeOf(context).toString();
    return Scaffold(
      body: Column(
        children: [
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
}

class WakeUpDateTimeList {
  final List<WakeUpDateTime> values;

  WakeUpDateTimeList(this.values);

  static recordWakeUpTime(DateTime wakeupDateTime) {
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(wakeupDateTime);
    _saveWakeUpTimeToPrefs(formattedTime);
  }

  static Future<WakeUpDateTimeList> fetchWakeUpTime() async {
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
}
