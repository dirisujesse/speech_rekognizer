import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:speech_recognizer/speech_recognizer_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // MethodChannelSpeechRecognizer platform = MethodChannelSpeechRecognizer();
  const MethodChannel channel = MethodChannel('speech_recognizer');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect('42', '42');
  });
}
