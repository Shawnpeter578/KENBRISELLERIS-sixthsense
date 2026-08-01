import 'package:flutter/material.dart';
import 'package:sixth_sense_app/screens/home.dart';
import 'services/auth_service.dart';
import 'theme/auth_theme.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AuthColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AuthColors.primary,
          primary: AuthColors.primary,
          background: AuthColors.background,
        ),
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}

/// Checks for an existing Appwrite session on launch and routes
/// straight to home if logged in, otherwise to the login page.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AuthColors.primary),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return  Home();
        }
        return LoginPage();
      },
    );
  }
}

