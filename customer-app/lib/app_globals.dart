import 'package:flutter/material.dart';

/// App-wide messenger key so services (e.g. order alerts) can surface a
/// SnackBar from anywhere, without needing a BuildContext.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
