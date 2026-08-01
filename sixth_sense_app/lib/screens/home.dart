import 'package:flutter/material.dart';
import 'package:sixth_sense_app/screens/login_page.dart';
import 'package:sixth_sense_app/services/auth_service.dart';
import 'package:sixth_sense_app/theme/auth_theme.dart';

class Home extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home>{
  
  
  @override
  Widget build(BuildContext context) {

    Future<void> _logout(BuildContext context) async {
  await AuthService.logout();
  if (!context.mounted) return;
  Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => LoginPage(),
  ));
}

   return  Scaffold(
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