import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(BachataApp());
}

class BachataApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bachata Training App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
        ).copyWith(
          secondary: Colors.blueAccent,
        ),
        sliderTheme: SliderThemeData(
          thumbColor: Colors.blueAccent,
          activeTrackColor: Colors.blueAccent,
          inactiveTrackColor: Colors.grey,
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: BachataHomePage(),
    );
  }
}

class BachataHomePage extends StatefulWidget {
  @override
  _BachataHomePageState createState() => _BachataHomePageState();
}

class _BachataHomePageState extends State<BachataHomePage> {
  double _tactValue = 140; // Default BPM value (within dancing range)
  late FlutterSoundPlayer _player;
  Timer? _beatTimer;

  // Bachata exercises
  final List<String> exercises = [
    'Stand Figuren', 'Headrole', 'in die Knie/Rotation führen',
    'Offene Figuren', 'Fenster-Move', 'Verneigen-Move',
    'Cross-Body Lead | Rausdrehen', 'Half-Turn | Ausdrehen oder Half-Step + HüfteDrehen',
    'Cross-Body Lead | Hammerlock', 'Figur Salsamás 1',
    'Platztausch. Offene Haltung', 'Drehen. Hand auf Bauch.',
    'Halb-Drehung. Hände fallen lassen.',
    'Platztausch. Geschlossene Haltung', 'Halb-Drehung',
    'Basic.NachVorne.Half-Basic.FollowerTurn.LeaderTurn.FollowerTurn.',
    'Drehung links/rechts', 'Half-Basic', 'Step Tap', 'Vorwärts',
    'Diagonal Step', 'ÜberKreuz. Vorne/Hinten', 'Rock Step',
    'Box Step', 'Merengue Step', 'Diagonal Basic', 'Twist Spin', 'Trible Step'
  ];

  // Categories for each exercise
  Map<String, Map<String, bool>> exerciseCategories = {};

  @override
  void initState() {
    super.initState();
    _player = FlutterSoundPlayer();
    _player.openPlayer();
    _loadSavedData(); // Load saved checkbox values
    _startTact(); // Start the beat when the app starts
  }

  @override
  void dispose() {
    _beatTimer?.cancel();
    _player.closePlayer();
    super.dispose();
  }

  // Start the beat based on tact value (BPM)
  void _startTact() {
    _beatTimer?.cancel(); // Cancel any previous timer
    int interval = (60000 / _tactValue).round(); // Calculate interval in milliseconds

    _beatTimer = Timer.periodic(Duration(milliseconds: interval), (Timer timer) {
      _playBeat(); // Play the custom beep sound
    });
  }

  // Play a simple beep sound
  void _playBeat() async {
    Uint8List beepData = _generateBeep();
    await _player.startPlayer(fromDataBuffer: beepData, codec: Codec.pcm16WAV, numChannels: 1);
  }


// Generate a simple beep sound buffer as Uint8List
  Uint8List _generateBeep() {
    const int sampleRate = 44100;
    const double durationInSeconds = 0.05; // 50ms beep
    const double frequency = 440.0; // A4 note

    // List to store the sample data
    List<int> samples = List<int>.filled((sampleRate * durationInSeconds).toInt(), 0);

    for (int i = 0; i < samples.length; i++) {
      double t = i / sampleRate;
      samples[i] = (32767 * 0.5 * (1.0 - 2.0 * (t * frequency - (t * frequency).floor()))).toInt();
    }

    // Convert the List<int> to Uint8List
    Uint8List soundBytes = Uint8List.fromList(samples);
    return soundBytes;
  }


  // Save the checkbox values to local storage
  void _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> savedData = {};

    exerciseCategories.forEach((exercise, categories) {
      savedData[exercise] = jsonEncode(categories);
    });

    prefs.setString('exerciseData', jsonEncode(savedData));
  }

  // Load the saved checkbox values from local storage
  void _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDataString = prefs.getString('exerciseData');

    if (savedDataString != null) {
      Map<String, dynamic> savedData = jsonDecode(savedDataString);

      savedData.forEach((exercise, categoriesJson) {
        Map<String, dynamic> categories = jsonDecode(categoriesJson);
        exerciseCategories[exercise] = categories.map((category, value) => MapEntry(category, value as bool));
      });
    } else {
      // Initialize default values if there's no saved data
      exercises.forEach((exercise) {
        exerciseCategories[exercise] = {
          'Trained Today': false,
          'Easy': false,
          'Middle': false,
          'Hard': false,
          'Use More Often': false,
        };
      });
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bachata Training'),
        backgroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Slider for adjusting tact
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Adjust Tact (BPM): ${_tactValue.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.white),
                ),
                Slider(
                  value: _tactValue,
                  min: 120, // Lower end of normal Bachata BPM range
                  max: 200, // Higher end of normal Bachata BPM range
                  divisions: 80,
                  label: _tactValue.toString(),
                  onChanged: (double value) {
                    setState(() {
                      _tactValue = value;
                      _startTact(); // Restart tact with new BPM value
                    });
                  },
                ),
              ],
            ),
          ),

          // List of Exercises
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                String exercise = exercises[index];
                return ExpansionTile(
                  title: Text(
                    exercise,
                    style: TextStyle(color: Colors.white),
                  ),
                  children: exerciseCategories[exercise]!.keys.map((category) {
                    return CheckboxListTile(
                      title: Text(category, style: TextStyle(color: Colors.white70)),
                      value: exerciseCategories[exercise]![category],
                      onChanged: (bool? value) {
                        setState(() {
                          exerciseCategories[exercise]![category] = value!;
                          _saveData(); // Save the updated value
                        });
                      },
                      activeColor: Colors.blueAccent,
                      checkColor: Colors.white,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
