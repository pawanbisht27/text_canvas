import 'package:flutter/material.dart';
import 'screens/editor_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Text Canvas',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const EditorScreen(),
    );
  }
}