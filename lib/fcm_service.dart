import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'courier_state.dart';

class FCMService extends ChangeNotifier {
  FCMService(this._messaging);

  final FirebaseMessaging _messaging;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _started = false;
  bool _disposed = false;
  bool _checkingDevice = false;
  String? _token;
  AuthorizationStatus? _permission;
  String? _deviceError;
  String? _listenerError;
  int _tokenRevision = 0;
  CourierState _state = const CourierState();

  CourierState get state => _state;
  String? get token => _token;
  AuthorizationStatus? get permission => _permission;
  String? get deviceError => _deviceError;
  String? get listenerError => _listenerError;
  bool get checkingDevice => _checkingDevice;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _subscriptions.addAll([
      FirebaseMessaging.onMessage.listen(
        (message) => _handle(message, MessagePath.foreground),
        onError: _handleStreamError,
      ),
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _handle(message, MessagePath.backgroundTap),
        onError: _handleStreamError,
      ),
      _messaging.onTokenRefresh.listen((token) {
        _tokenRevision++;
        _token = token;
        _publish();
      }, onError: _handleStreamError),
    ]);
    unawaited(_readInitialMessage());
    unawaited(refreshDevice());
  }

  Future<void> _readInitialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();
      if (message != null) _handle(message, MessagePath.coldStartTap);
    } catch (error) {
      debugPrint('Cloud Courier initial message: $error');
      _listenerError = 'Could not check whether a notification opened the app.';
      _publish();
    }
  }

  Future<void> refreshDevice({bool requestPermission = false}) async {
    if (_checkingDevice || _disposed) return;
    _checkingDevice = true;
    _deviceError = null;
    _publish();

    try {
      final settings = requestPermission
          ? await _messaging.requestPermission()
          : await _messaging.getNotificationSettings();
      _permission = settings.authorizationStatus;
      final revision = _tokenRevision;
      final token = await _messaging.getToken();
      if (revision == _tokenRevision) _token = token;
      if (_token == null)
        _deviceError = 'No token yet. Check Google Play services and refresh.';
    } catch (error) {
      debugPrint('Cloud Courier device registration: $error');
      _deviceError = 'Device check failed. Verify Firebase setup and connectivity, then refresh.';
    } finally {
      _checkingDevice = false;
      _publish();
    }
  }

  void _handle(RemoteMessage message, MessagePath path) {
    if (_disposed) return;
    _state = _state.receive(
      data: message.data,
      path: path,
      messageId: message.messageId,
      notificationTitle: message.notification?.title,
      notificationBody: message.notification?.body,
    );
    debugPrint('Cloud Courier ${path.label}: ${message.messageId}');
    _publish();
  }

  void _handleStreamError(Object error) {
    debugPrint('Cloud Courier message stream: $error');
    _listenerError = 'A Firebase messaging listener reported an error.';
    _publish();
  }

  void _publish() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
