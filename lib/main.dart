import 'package:flutter_localizations/flutter_localizations.dart';
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
      localizationsDelegates: const [
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
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
                  content: '今日は朝から雨が降っていたので、家でゆっくり過ごしました。',
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
              '起床時間: ${DateFormat('HH:mm').format(DateTime.parse(datetime))}',
            ),
            SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
