import 'dart:async';
import 'dart:developer' show log;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:speech_recognizer/lib.dart';

/// An implementation of [SpeechRecognizerPlatform] that uses method channels.
class MethodChannelSpeechRecognizer extends SpeechRecognizerPlatform {
  late Debouncer _debouncer = Debouncer(const Duration(seconds: 5));
  static const _channelName = "com.dirisujesse.speech_recognizer/methods";

  final _channel = MethodChannel(_channelName);
  bool _isTranscribing = false;

  MethodChannelSpeechRecognizer() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onSpeechResult':
        log('onSpeechResult: ${call.arguments}');
        transcriptionUpdate.value = TranscriptionResponse(
          message: call.arguments,
        );
        break;
      case 'onPartialSpeechResult':
        log('onPartialSpeechResult: ${call.arguments}');
        transcriptionUpdate.value = TranscriptionResponse(
          message: call.arguments,
        );

        break;
      case 'onSpeechError':
        log('onSpeechError: ${call.arguments}');
        transcriptionUpdate.value = TranscriptionResponse(
          data: call.arguments,
          type: TranscriptionResponseType.error,
          message: 'An error occurred during speech recognition.',
        );

        break;
      case 'onSpeechReady':
        log('onSpeechReady: ${call.arguments}');
        transcriptionUpdate.value = TranscriptionResponse(
          type: call.arguments == true
              ? TranscriptionResponseType.started
              : TranscriptionResponseType.completed,
          message: call.arguments,
        );

        break;
      default:
        log('Unknown method ${call.method}');
    }
  }

  @override
  Future<TranscriptionResponse?> startTranscription({
    Locale? locale,
    Duration duration = const Duration(seconds: 5),
  }) async {
    if (_isTranscribing) return null;
    try {
      _isTranscribing = true;

      _debouncer.abort();
      _debouncer = Debouncer(duration);
      _debouncer.run(() async {
        log('Starting transcription stop for locale: $locale');
        await stopTranscription();
      });

      transcriptionUpdate.value = TranscriptionResponse(
        type: TranscriptionResponseType.started,
        message: 'Started',
      );

      
      _channel.invokeMethod('startTranscription', {
        'locale': locale?.toString(),
      });
    } on PlatformException catch (e) {
      _isTranscribing = false;
      transcriptionUpdate.value = TranscriptionResponse(
        data: e,
        type: TranscriptionResponseType.error,
        message: 'An error occurred during speech recognition.',
      );
      return null;
    }
  }

  @override
  Future<void> stopTranscription() async {
    if (!_isTranscribing) return;

    try {
      _debouncer.abort();

      await _channel.invokeMethod('stopTranscription');

      _isTranscribing = false;
      transcriptionUpdate.value = TranscriptionResponse(
        type: TranscriptionResponseType.completed,
        message: 'Stopped',
      );
    } on PlatformException catch (e) {
      _isTranscribing = false;
      transcriptionUpdate.value = TranscriptionResponse(
        data: e,
        type: TranscriptionResponseType.error,
        message: 'An error occurred during speech recognition.',
      );
    }
  }
}
