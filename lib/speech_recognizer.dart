import 'package:flutter/rendering.dart';
import 'package:speech_recognizer/lib.dart';

class SpeechRecognizer {
  VoidCallback? _listener;

  Future<void> startTranscription({
    Locale? locale,
    required ResultCallback<String> onUpdate,
    ResultCallback<dynamic>? onError,
    VoidCallback? onStarted,
    VoidCallback? onCompleted,
    Duration duration = const Duration(seconds: 5),
  }) async {
    if (_listener != null) return;

    final updates = SpeechRecognizerPlatform.instance.transcriptionUpdate;

    _listener ??= () {
      final update = updates.value;

      if (update == null) return;

      if (update.isTranscript) {
        onUpdate(update.message);
      }

      if (update.isError) {
        onError?.call(update.data);
      }

      if (update.isStartState == true) {
        onStarted?.call();
        return;
      }

      if (update.isCompletedState == true) {
        onCompleted?.call();

        updates.removeListener(_listener!);
        _listener = null;
      }
    };

    updates.addListener(_listener!);

    SpeechRecognizerPlatform.instance.startTranscription(
      locale: locale,
      duration: duration,
    );
  }

  Future<void> stopTranscription() async {
    await SpeechRecognizerPlatform.instance.stopTranscription();
    SpeechRecognizerPlatform.instance.transcriptionUpdate.removeListener(
      _listener!,
    );
    _listener = null;
  }
}
