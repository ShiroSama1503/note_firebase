import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'config/supabase_config.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/storage.dart';

const studentName = 'Dương Hồng Phúc';
const studentId = '2351060479';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
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

    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        return FutureBuilder<void>(
          future: Storage.setCurrentUser(user?.uid),
          builder: (context, storageSnapshot) {
            if (storageSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (user == null) {
              return const AuthScreen();
            }

            return const HomeScreen(
              studentName: studentName,
              studentId: studentId,
            );
          },
        );
      },
    );
  }
}
