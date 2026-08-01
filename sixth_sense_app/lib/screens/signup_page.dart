import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:sixth_sense_app/screens/home.dart';
import 'package:sixth_sense_app/services/appwrite_service.dart';
import '../services/auth_service.dart';
import '../theme/auth_theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Creates the only profile row for this account, keyed by its auth ID.
  Future<void> _createUserRow(String userId) async {
    await AppwriteService.tablesDB.createRow(
      databaseId: AppwriteService.databaseId,
      tableId: AppwriteService.userTableId,
      rowId: userId,
      data: {
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
      },
      // Without this, if the table has document security enabled, the row
      // is created with no read/update/delete permission for the very
      // user it belongs to — later listRows() queries return 0 rows even
      // though the row exists. This is almost certainly why profile data
      // wasn't loading on the dashboard.
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await AuthService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      try {
        await _createUserRow(user.$id);
      } on AppwriteException catch (e) {
        // Show the exact Appwrite error while debugging. Common causes:
        // 401/authorization -> collection missing "create" permission for
        // role:users (this is a COLLECTION-level setting, separate from
        // the per-document permissions passed above); 404 -> wrong
        // databaseId/tableId; 400 -> a required attribute is missing or
        // has the wrong type for your table's schema.
        // ignore: avoid_print
        print('Profile row creation failed for ${user.$id}: ${e.code} ${e.message}');
        if (!mounted) return;
        setState(() {
          _error = 'Profile row failed: [${e.code}] ${e.message}';
          _loading = false;
        });
        // Still proceed to Home — AuthService/session is valid; the
        // dashboard's own retry flow can recreate/reload the row.
        // Do not open Home without its required profile row.
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => Home()),
        (route) => false,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AuthColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AuthColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AuthColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign up to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: AuthColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    label: 'Name',
                    hint: 'Your full name',
                    controller: _nameController,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Password',
                    hint: 'At least 8 characters',
                    controller: _passwordController,
                    obscure: _obscure,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 8) return 'Must be at least 8 characters';
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AuthColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    controller: _confirmController,
                    obscure: _obscureConfirm,
                    validator: (v) {
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AuthColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AuthColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AuthColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  AuthPrimaryButton(
                    label: 'Sign Up',
                    loading: _loading,
                    onPressed: _handleSignUp,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: AuthColors.textSecondary, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: AuthColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
