import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:speech_recognizer/speech_recognizer.dart';

void main() {
  runApp(const MyApp(key: Key("speech_example")));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SpeechRecognizer _speechRecognitionService;
  final ValueNotifier<String> _transcribedText = ValueNotifier('');
  final ValueNotifier<bool> _isListening = ValueNotifier(false);

  @override
  void initState() {
    _speechRecognitionService = SpeechRecognizer();
    super.initState();
  }

  void _toggleListening() {
    if (_isListening.value) {
      _speechRecognitionService.stopTranscription();
      _isListening.value = false;
      return;
    }

    _speechRecognitionService.startTranscription(
      locale: Locale.fromSubtags(languageCode: "en", countryCode: "US"),
      onStarted: () => _isListening.value = true,
      onCompleted: () => _isListening.value = false,
      onUpdate: (text) {
        log(text);
        _transcribedText.value = text;
      },
      onError: (error) {
        log('Speech recognition error: $error');
        _isListening.value = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ListenableBuilder(
        listenable: Listenable.merge([_transcribedText, _isListening]),
        builder: (context, child) {
          return Scaffold(
            key: ValueKey((_transcribedText.value, _isListening.value)),
            appBar: AppBar(title: Text('Speech to Text (Kotlin/Swift)')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 30,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${_isListening.value ? 'Listening' : 'Not Listening'}',
                      style: TextStyle(color: Colors.red[600], fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Transcripts',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    Text(
                      _transcribedText.value,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              key: ValueKey(_isListening.value),
              onPressed: _toggleListening,
              tooltip: 'Listen',
              child: Icon(
                _isListening.value ? Icons.hearing_outlined : Icons.mic,
              ),
            ),
          );
        },
      ),
    );
  }
}
