import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'widgets/phone_frame.dart';

void main() {
  runApp(const DhopaBariAdminApp());
}

class DhopaBariAdminApp extends StatelessWidget {
  const DhopaBariAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ধোপা বাড়ি — Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) => PhoneFrame(child: child!),
      home: const LoginScreen(),
    );
  }
}
