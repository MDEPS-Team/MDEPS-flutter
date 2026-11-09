import 'package:flutter/material.dart';
import 'package:mdeps_flutter/iam/ui/login_screen.dart';

void main() {
  runApp(const VantagePmoApp());
}

class VantagePmoApp extends StatelessWidget {
  const VantagePmoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vantage PMO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A5F)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
