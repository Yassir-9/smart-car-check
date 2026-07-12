import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CarAiApp());
}

class CarAiApp extends StatelessWidget {
  const CarAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تشخيص السيارة الذكي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}
