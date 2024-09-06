import 'package:flutter/material.dart';
import 'package:Kodegiri/screens/splash_screen.dart';

void main() {
  runApp(const WebLauncherApp());
}

class WebLauncherApp extends StatelessWidget {
  const WebLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kodegiri',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}
