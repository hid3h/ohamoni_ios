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
  List<DateTime> _wakeupDatetimes = [];

  @override
  void initState() {
    super.initState();
    _loadWakeUpTimes();
  }

  void _loadWakeUpTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final wakeUpTimes = prefs.getStringList('wakeUpTimes') ?? [];
    setState(() {
      _wakeupDatetimes = wakeUpTimes.map((timeString) {
        return DateFormat('yyyy-MM-dd HH:mm').parse(timeString);
      }).toList();
    });
  }

  void _saveWakeUpTimeToPrefs(String formattedTime) async {
    final prefs = await SharedPreferences.getInstance();
    final wakeUpTimes = prefs.getStringList('wakeUpTimes') ?? [];
    wakeUpTimes.insert(0, formattedTime);
    await prefs.setStringList('wakeUpTimes', wakeUpTimes);
  }

  void _recordWakeUpTime(DateTime wakeupDateTime) {
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(wakeupDateTime);
    _saveWakeUpTimeToPrefs(formattedTime);
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

  List<DateTime> get _getWakeUpDateTimes {
    final List<String> temp = [];
    final List<DateTime> ret = [];
    for (final wakeUpDateTime in _wakeupDatetimes) {
      final date = wakeUpDateTime.toString().split(' ')[0];
      if (!temp.contains(date)) {
        temp.add(date);
        ret.add(wakeUpDateTime);
      }
    }
    debugPrint('ret: $ret');
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('起床時間記録'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                final wakeUpDateTimes = _getWakeUpDateTimes;
                return ListView.builder(
                  itemCount: wakeUpDateTimes.length,
                  itemBuilder: (context, index) {
                    final dateTime = wakeUpDateTimes[index];
                    return BlogEntry(
                      datetime: DateFormat('yyyy-MM-dd HH:mm').format(dateTime),
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
        child: Icon(Icons.add),
      ),
    );
  }
}

class BlogEntry extends StatelessWidget {
  final String datetime;

  const BlogEntry({
    super.key,
    required this.datetime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MM月dd日 (E)').format(DateTime.parse(datetime)),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '起床時間: ${DateFormat('HH:mm').format(DateTime.parse(datetime))}',
            ),
          ],
        ),
      ),
    );
  }
}
