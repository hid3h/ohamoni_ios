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
  Map<String, String> _wakeUpTimesByDate = {};

  @override
  void initState() {
    super.initState();
    _loadWakeUpTimes();
  }

  void _loadWakeUpTimes() async {
    debugPrint('Loading wake up times from prefs');
    final prefs = await SharedPreferences.getInstance();
    final wakeUpTimes = prefs.getStringList('wakeUpTimes') ?? [];
    debugPrint('Loaded wake up times: $wakeUpTimes');
    setState(() {
      _wakeUpTimesByDate = {};
      for (var time in wakeUpTimes) {
        final date = time.split(' ')[0];
        if (!_wakeUpTimesByDate.containsKey(date)) {
          _wakeUpTimesByDate[date] = time;
        }
      }
    });
    debugPrint('整理された起床時間: $_wakeUpTimesByDate');
  }

  void _saveWakeUpTimeToPrefs(String formattedTime) async {
    final prefs = await SharedPreferences.getInstance();
    final wakeUpTimes = prefs.getStringList('wakeUpTimes') ?? [];
    wakeUpTimes.insert(0, formattedTime);
    await prefs.setStringList('wakeUpTimes', wakeUpTimes);
    _loadWakeUpTimes();
  }

  void _recordWakeUpTime(DateTime wakeupDateTime) {
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(wakeupDateTime);
    _saveWakeUpTimeToPrefs(formattedTime);
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
            child: ListView.builder(
              itemCount: _wakeUpTimesByDate.length,
              itemBuilder: (context, index) {
                final entry = _wakeUpTimesByDate.entries.elementAt(index);
                return BlogEntry(
                  datetime: entry.value,
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
