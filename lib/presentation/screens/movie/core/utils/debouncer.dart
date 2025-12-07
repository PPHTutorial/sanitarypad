import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debouncer utility for delaying function execution
class Debouncer {
  final Duration delay;
  Timer? _timer;
  
  Debouncer({this.delay = const Duration(milliseconds: 300)});
  
  /// Call the debounced action
  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
  
  /// Run action immediately and cancel any pending action
  void callImmediately(VoidCallback action) {
    _timer?.cancel();
    action();
  }
  
  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
  }
  
  /// Dispose the debouncer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
  
  /// Check if there's a pending action
  bool get isPending => _timer?.isActive ?? false;
}

/// Throttler utility for limiting function execution frequency
class Throttler {
  final Duration duration;
  Timer? _timer;
  bool _isExecuting = false;
  
  Throttler({this.duration = const Duration(milliseconds: 500)});
  
  /// Call the throttled action
  void call(VoidCallback action) {
    if (_isExecuting) return;
    
    _isExecuting = true;
    action();
    
    _timer = Timer(duration, () {
      _isExecuting = false;
    });
  }
  
  /// Dispose the throttler
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _isExecuting = false;
  }
  
  /// Check if currently throttled
  bool get isThrottled => _isExecuting;
}

