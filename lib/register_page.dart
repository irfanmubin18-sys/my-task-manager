import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _primary = Color(0xFF5B52E0);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool isLoading = false;
  bool obscurePass = true;
  bool obscureConfirm = true;

  Future<void> registerUser() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmController.text.trim().isEmpty) {
      _snack('Please fill in all fields', Colors.redAccent);
      return;
    }
    if (passwordController.text.trim() != confirmController.text.trim()) {
      _snack('Passwords do not match', Colors.redAccent);
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (mounted) {
        _snack('Account created! Please sign in.', Colors.green);
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Registration failed';
      if (e.code == 'weak-password') msg = 'Password too weak (min 6 characters)';
      else if (e.code == 'email-already-in-use') msg = 'Email already registered';
      else if (e.code == 'invalid-email') msg = 'Invalid email address';
      if (mounted) _snack(msg, Colors.redAccent);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1a1a1a), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                height: 72,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEAFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    size: 36, color: _primary),
              ),

              const Text('Create account',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a1a))),
              const SizedBox(height: 6),
              const Text('Join and start managing your tasks',
                  style: TextStyle(fontSize: 14, color: Color(0xFF888780))),
              const SizedBox(height: 32),

              _label('Email'),
              const SizedBox(height: 6),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _deco(hint: 'you@email.com', icon: Icons.email_outlined),
              ),
              const SizedBox(height: 16),

              _label('Password'),
              const SizedBox(height: 6),
              TextField(
                controller: passwordController,
                obscureText: obscurePass,
                decoration: _deco(
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  suffix: _eyeBtn(obscurePass, () => setState(() => obscurePass = !obscurePass)),
                ),
              ),
              const SizedBox(height: 16),

              _label('Confirm password'),
              const SizedBox(height: 6),
              TextField(
                controller: confirmController,
                obscureText: obscureConfirm,
                decoration: _deco(
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  suffix: _eyeBtn(obscureConfirm, () => setState(() => obscureConfirm = !obscureConfirm)),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Create account',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ',
                      style: TextStyle(color: Color(0xFF888780), fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Sign in',
                        style: TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF444441)));

  Widget _eyeBtn(bool obscure, VoidCallback onTap) => IconButton(
      icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 18, color: Colors.grey),
      onPressed: onTap);

  InputDecoration _deco({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB4B2A9), fontSize: 14),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF888780)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEDEAFF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEDEAFF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }
}