import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'courier_app.dart';
import 'fcm_service.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Android runs this callback in a separate isolate. Only log the delivery.
  debugPrint('Cloud Courier onBackgroundMessage: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (error) {
    debugPrint('Cloud Courier Firebase startup failed: $error');
    runApp(
      const CourierApp(
        setupMessage:
            'Connect this Android app to your Firebase project, then '
            'rebuild it. Follow the steps in README.md.',
      ),
    );
    return;
  }

  runApp(CourierApp(service: FCMService(FirebaseMessaging.instance)));
}
