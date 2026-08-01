import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'auth_theme.dart';
import 'login_page.dart';

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
          return const HomeScreen();
        }
        return LoginPage(homeBuilder: (_) => const HomeScreen());
      },
    );
  }
}

/// Placeholder home screen — replace with your actual app screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(homeBuilder: (_) => const HomeScreen()),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      appBar: AppBar(
        backgroundColor: AuthColors.background,
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(color: AuthColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AuthColors.textPrimary),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "You're logged in.",
          style: TextStyle(fontSize: 16, color: AuthColors.textSecondary),
        ),
      ),
    );
  }
}