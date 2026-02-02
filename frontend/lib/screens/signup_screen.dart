import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}
class _SignupScreenState extends State<SignupScreen> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  final _name = TextEditingController();
  bool loading = false;
  String? error;

  void _signup() async {
    setState(() { loading = true; error = null; });
    final user = await AuthService.signup(_u.text.trim(), _p.text, _name.text.trim());
    setState(() { loading = false; });
    if (user != null) {
      Navigator.pop(context); // back to login (or push to home)
    } else {
      setState(() { error = "Signup failed (username may be taken)"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: "Display name")),
            TextField(controller: _u, decoration: const InputDecoration(labelText: "Username")),
            TextField(controller: _p, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            if (error != null) Padding(padding: const EdgeInsets.only(top:8.0), child: Text(error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: loading ? null : _signup, child: loading ? const CircularProgressIndicator() : const Text("Create account")),
          ],
        ),
      ),
    );
  }
}
