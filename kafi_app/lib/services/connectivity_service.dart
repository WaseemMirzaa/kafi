import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:kafi_app/utils/errors/error_handler.dart';

/// Network connectivity monitor per Technical Architecture §13.6
class ConnectivityService extends GetxService {
  final RxBool isOnline = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  final List<Function()> _reconnectCallbacks = [];

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _sub = Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    isOnline.value = !result.contains(ConnectivityResult.none);
  }

  void _handleConnectivityChange(List<ConnectivityResult> result) {
    final wasOffline = !isOnline.value;
    isOnline.value = !result.contains(ConnectivityResult.none);

    if (isOnline.value) {
      ErrorHandler.hideOfflineBanner();
      if (wasOffline) {
        _onReconnect();
      }
    } else {
      ErrorHandler.showOfflineBanner();
    }
  }

  void _onReconnect() {
    for (final callback in _reconnectCallbacks) {
      callback();
    }
  }

  void addReconnectCallback(Function() callback) {
    _reconnectCallbacks.add(callback);
  }

  void removeReconnectCallback(Function() callback) {
    _reconnectCallbacks.remove(callback);
  }

  @override
  void onClose() {
    _sub?.cancel();
    _reconnectCallbacks.clear();
    super.onClose();
  }
}

/// Action queue for offline retry per Technical Architecture §13.7
class ActionQueue {
  final List<QueuedAction> _queue = [];
  final ConnectivityService _connectivity;

  ActionQueue(this._connectivity) {
    _connectivity.addReconnectCallback(_flushIfOnline);
  }

  void enqueue(QueuedAction action) {
    _queue.add(action);
    _flushIfOnline();
  }

  void _flushIfOnline() {
    if (!_connectivity.isOnline.value) return;

    final pending = List<QueuedAction>.from(_queue);
    _queue.clear();

    for (final action in pending) {
      _executeWithRetry(action);
    }
  }

  Future<void> _executeWithRetry(QueuedAction action) async {
    try {
      await action.execute();
    } catch (e) {
      if (action.retryCount < action.maxRetries) {
        action.retryCount++;
        _queue.add(action);
      } else {
        action.onFailure?.call(e);
      }
    }
  }

  void dispose() {
    _connectivity.removeReconnectCallback(_flushIfOnline);
    _queue.clear();
  }
}

class QueuedAction {
  final Future<void> Function() execute;
  final Function(dynamic error)? onFailure;
  final int maxRetries;
  int retryCount = 0;

  QueuedAction({
    required this.execute,
    this.onFailure,
    this.maxRetries = 3,
  });
}
