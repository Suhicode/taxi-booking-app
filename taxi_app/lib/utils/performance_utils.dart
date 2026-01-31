import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class Throttler {
  final Duration duration;
  Timer? _timer;
  
  Throttler({this.duration = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    if (_timer?.isActive ?? false) return;
    
    _timer = Timer(duration, () {
      action();
      _timer = null;
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}

class Debouncer {
  final Duration duration;
  Timer? _timer;
  
  Debouncer({this.duration = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

// For expensive computations in isolates
Future<R> computeInBackground<Q, R>(
  FutureOr<R> Function(Q) function, 
  Q message,
) async {
  return await compute(
    (message) async => await function(message as Q),
    message,
  );
}
