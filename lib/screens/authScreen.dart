import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _isRegister = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AuthService auth) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isRegister) {
        await auth.registerWithEmail(
          _email.text.trim(),
          _password.text.trim(),
          _name.text.trim(),
        );
      } else {
        await auth.signInWithEmail(
          _email.text.trim(),
          _password.text.trim(),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email to reset password')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset email: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Welcome'),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary.withOpacity(0.10), cs.secondary.withOpacity(0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Animated blobs (no Hero, no ParentData errors)
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubicEmphasized,
              alignment: _isRegister ? Alignment.topRight : Alignment.topLeft,
              child: Transform.translate(
                offset: _isRegister ? const Offset(60, -80) : const Offset(-60, -80),
                child: _blob(220, cs.primary.withOpacity(0.18)),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubicEmphasized,
              alignment: _isRegister ? Alignment.bottomLeft : Alignment.bottomRight,
              child: Transform.translate(
                offset: _isRegister ? const Offset(-50, 70) : const Offset(60, 70),
                child: _blob(200, cs.secondary.withOpacity(0.16)),
              ),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
              child: Column(
                children: [
                  Text(
                    _isRegister ? 'Create your account' : 'Sign in to continue',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Glass card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: 560,
                        constraints: const BoxConstraints(maxWidth: 560),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.surface.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            // Toggle
                            _ModeToggle(
                              isRegister: _isRegister,
                              onChanged: (v) => setState(() => _isRegister = v),
                            ),
                            const SizedBox(height: 12),

                            // Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  if (_isRegister) ...[
                                    TextFormField(
                                      controller: _name,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Display name',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                      validator: (v) {
                                        if (!_isRegister) return null;
                                        if (v == null || v.trim().length < 2) {
                                          return 'Please enter at least 2 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  TextFormField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.username, AutofillHints.email],
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.alternate_email_rounded),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Email is required';
                                      if (!v.contains('@')) return 'Enter a valid email';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _password,
                                    obscureText: _obscure,
                                    textInputAction: _isRegister ? TextInputAction.next : TextInputAction.done,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                                      suffixIcon: IconButton(
                                        tooltip: _obscure ? 'Show password' : 'Hide password',
                                        icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                                        onPressed: () => setState(() => _obscure = !_obscure),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Password is required';
                                      if (v.length < 6) return 'At least 6 characters';
                                      return null;
                                    },
                                    onFieldSubmitted: (_) {
                                      if (!_isRegister) _handleSubmit(auth);
                                    },
                                  ),
                                  if (_isRegister) ...[
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _confirm,
                                      obscureText: _obscure,
                                      textInputAction: TextInputAction.done,
                                      decoration: const InputDecoration(
                                        labelText: 'Confirm password',
                                        prefixIcon: Icon(Icons.lock_reset_rounded),
                                      ),
                                      validator: (v) {
                                        if (!_isRegister) return null;
                                        if (v == null || v.isEmpty) return 'Please confirm password';
                                        if (v != _password.text) return 'Passwords do not match';
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _handleSubmit(auth),
                                    ),
                                  ],
                                  const SizedBox(height: 14),

                                  // Error
                                  if (_error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        _error!,
                                        style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
                                      ),
                                    ),

                                  // Primary button
                                  _PrimaryButton(
                                    label: _isRegister ? 'Create account' : 'Sign in',
                                    onPressed: _loading ? null : () => _handleSubmit(auth),
                                  ),
                                  const SizedBox(height: 12),

                                  // Links row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // TextButton(
                                      //   onPressed: _loading
                                      //       ? null
                                      //       : () => setState(() => _isRegister = !_isRegister),
                                      //   child: Text(
                                      //     _isRegister ? 'Have an account? Sign in' : 'New here? Create account',
                                      //   ),
                                      // ),
                                      if (!_isRegister)
                                        TextButton(
                                          onPressed: _loading ? null : _forgotPassword,
                                          child: const Text('Forgot password?'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isRegister;
  final ValueChanged<bool> onChanged;
  const _ModeToggle({required this.isRegister, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _seg(
            context,
            label: 'Sign in',
            selected: !isRegister,
            onTap: () => onChanged(false),
          ),
          _seg(
            context,
            label: 'Create account',
            selected: isRegister,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _seg(BuildContext context, {required String label, required bool selected, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          alignment: Alignment.center,
          child: const Text(
            'G',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        label: const Text('Continue with Google'),
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}