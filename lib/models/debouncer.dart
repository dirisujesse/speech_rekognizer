import 'package:flutter/foundation.dart';
import 'dart:async';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer(this.delay);

  void abort() {
    if (_timer == null) return;
    if (!_timer!.isActive) return;
    _timer!.cancel();
  }

  bool get isActive => _timer?.isActive ?? false;

  run(VoidCallback action) {
    if (_timer != null) {
      abort();
      _timer = Timer(delay, action);
    } else {
      _timer = Timer(delay, action);
    }
  }
}
