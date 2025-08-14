import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:speech_recognizer/lib.dart';

abstract class SpeechRecognizerPlatform extends PlatformInterface {
  /// Constructs a SpeechRecognizerPlatform.
  SpeechRecognizerPlatform() : super(token: _token);

  static final Object _token = Object();

  static SpeechRecognizerPlatform _instance = MethodChannelSpeechRecognizer();

  ValueNotifier<TranscriptionResponse?> transcriptionUpdate =
      ValueNotifier(null);

  /// The default instance of [SpeechRecognizerPlatform] to use.
  ///
  /// Defaults to [MethodChannelSpeechRecognizer].
  static SpeechRecognizerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SpeechRecognizerPlatform] when
  /// they register themselves.
  static set instance(SpeechRecognizerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<TranscriptionResponse?> startTranscription({
    Locale? locale,
    Duration duration = const Duration(seconds: 5),
  }) {
    throw UnimplementedError(
      'startTranscription(locale: $locale) has not been implemented.',
    );
  }

  Future<void> stopTranscription() {
    throw UnimplementedError('stopTranscription() has not been implemented.');
  }
}
