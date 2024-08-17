import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WakeUpTimerPage(),
    );
  }
}

class WakeUpTimerPage extends StatefulWidget {
  const WakeUpTimerPage({super.key});

  @override
  State<WakeUpTimerPage> createState() => _WakeUpTimerPageState();
}

class _WakeUpTimerPageState extends State<WakeUpTimerPage> {
  List<String> _wakeUpTimes = [];
  DateTime _selectedTime = DateTime.now();
  bool _showTimePicker = false;

  @override
  void initState() {
    super.initState();
    _loadWakeUpTimes();
  }

  void _loadWakeUpTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wakeUpTimes = prefs.getStringList('wakeUpTimes') ?? [];
    });
  }

  void _saveWakeUpTimeToPrefs(String formattedTime) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wakeUpTimes.insert(0, formattedTime);
      prefs.setStringList('wakeUpTimes', _wakeUpTimes);
    });
  }

  void _saveWakeUpTime() {
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(_selectedTime);
    _saveWakeUpTimeToPrefs(formattedTime);
    _toggleTimePicker(); // タイムピッカーを閉じる
  }

  void _updateSelectedTime(DateTime time) {
    setState(() {
      _selectedTime = time;
    });
  }

  void _toggleTimePicker() {
    setState(() {
      _showTimePicker = !_showTimePicker;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('起床時間記録'),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _toggleTimePicker,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '起床時間: ${DateFormat('HH:mm').format(_selectedTime)}',
                      style: TextStyle(fontSize: 18),
                    ),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
          if (_showTimePicker)
            Container(
              height: 150,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _selectedTime,
                onDateTimeChanged: _updateSelectedTime,
                minuteInterval: 1,
                use24hFormat: true,
              ),
            ),
          ElevatedButton(
            onPressed: _saveWakeUpTime,
            child: Text('記録'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _wakeUpTimes.length,
              itemBuilder: (context, index) {
                return BlogEntry(
                  datetime: _wakeUpTimes[index],
                  content: '今日は朝から雨が降っていたので、家でゆっくり過ごしました。',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BlogEntry extends StatelessWidget {
  final String datetime;
  final String content;

  const BlogEntry({
    super.key,
    required this.datetime,
    required this.content,
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
              '記録時間: ${DateFormat('HH:mm').format(DateTime.parse(datetime))}',
            ),
            SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
