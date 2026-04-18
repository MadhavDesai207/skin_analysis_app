import 'package:flutter/material.dart';

import 'package:skin_ai_app/src/screens/get_started_screen.dart';

class SkinSenseApp extends StatelessWidget {
  const SkinSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Sense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB65F35),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F1EA),
        useMaterial3: true,
      ),
      home: const GetStartedScreen(),
    );
  }
}
