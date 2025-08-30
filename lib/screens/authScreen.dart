import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isRegister)
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Display name')),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : () async {
                setState(() { _loading = true; _error = null; });
                try {
                  if (_isRegister) {
                    await auth.registerWithEmail(_email.text.trim(), _password.text.trim(), _name.text.trim());
                  } else {
                    await auth.signInWithEmail(_email.text.trim(), _password.text.trim());
                  }
                } catch (e) {
                  setState(() { _error = '$e'; });
                } finally {
                  if (mounted) setState(() { _loading = false; });
                }
              },
              child: Text(_isRegister ? 'Create account' : 'Sign in'),
            ),
            TextButton(
              onPressed: () => setState(() { _isRegister = !_isRegister; }),
              child: Text(_isRegister ? 'Have an account? Sign in' : 'Create an account'),
            ),
            const Divider(),
            OutlinedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: _loading ? null : () async {
                setState(() { _loading = true; _error = null; });
                try {
                  await auth.signInWithGoogle();
                } catch (e) {
                  setState(() { _error = '$e'; });
                } finally {
                  if (mounted) setState(() { _loading = false; });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}