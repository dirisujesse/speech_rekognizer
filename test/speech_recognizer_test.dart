// import 'package:flutter_test/flutter_test.dart';
// import 'package:speech_recognizer/speech_recognizer.dart';
// import 'package:speech_recognizer/speech_recognizer_platform_interface.dart';
// import 'package:speech_recognizer/speech_recognizer_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockSpeechRecognizerPlatform
//     with MockPlatformInterfaceMixin
//     implements SpeechRecognizerPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final SpeechRecognizerPlatform initialPlatform = SpeechRecognizerPlatform.instance;

//   test('$MethodChannelSpeechRecognizer is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelSpeechRecognizer>());
//   });

//   test('getPlatformVersion', () async {
//     SpeechRecognizer speechRecognizerPlugin = SpeechRecognizer();
//     MockSpeechRecognizerPlatform fakePlatform = MockSpeechRecognizerPlatform();
//     SpeechRecognizerPlatform.instance = fakePlatform;

//     expect(42, '42');
//   });
// }
