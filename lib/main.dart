import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'screens/home_screen.dart';
import 'services/storage.dart';

const STUDENT_NAME = 'Dương Hồng Phúc';
const STUDENT_ID = '2351060479';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const MainRouter(),
    );
  }
}

class MainRouter extends StatelessWidget {
  const MainRouter({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure intl default locale formatting is available
    Intl.defaultLocale = Intl.getCurrentLocale();
    return const HomeScreen(studentName: STUDENT_NAME, studentId: STUDENT_ID);
  }
}
