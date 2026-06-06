import 'package:flutter/material.dart';

import '../services/firebase_service.dart';

class AppNavigation {
  static void goHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
      arguments: firebaseService.nickname ?? 'Guest',
    );
  }
}
