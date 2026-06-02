import 'package:flutter/material.dart';

void main() {
  runApp(const KrishiDrishtiApp());
}

class KrishiDrishtiApp extends StatelessWidget {
  const KrishiDrishtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krishi Drishti',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Krishi Drishti'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.satellite_alt, size: 80, color: Color(0xFF2E7D32)),
            SizedBox(height: 20),
            Text(
              'Krishi Drishti',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Satellite Vision for Smart Farming',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),
            Text(
              'This is a starter project.\n'
              'You can embed the web version here\n'
              'or build a native Flutter UI.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
