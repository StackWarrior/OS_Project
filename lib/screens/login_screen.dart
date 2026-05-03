import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  Future<void> _submit() async {
    final isEn = context.read<AppState>().locale.languageCode == 'en';
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    
    try {
      await context.read<AppState>().loginEmail(
            email: _email.text.trim(),
            password: _password.text,
          );
      
      if (!mounted) return;
      // Navigate to Main Shell - Home Tab
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.mainShell,
        (r) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn ? 'Login failed: ${e.toString()}' : 'فشل تسجيل الدخول: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loginGoogle() async {
    final isEn = context.read<AppState>().locale.languageCode == 'en';
    setState(() => _busy = true);
    try {
      await context.read<AppState>().loginGoogle();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.mainShell,
        (r) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn ? 'Google Login failed: ${e.toString()}' : 'فشل تسجيل الدخول بجوجل: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final isEn = context.read<AppState>().locale.languageCode == 'en';
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? 'Please enter a valid email first' : 'يرجى إدخال بريد إلكتروني صحيح أولاً'),
        ),
      );
      return;
    }

    try {
      await context.read<AppState>().sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn 
              ? 'Password reset email sent to $email' 
              : 'تم إرسال رابط إعادة تعيين كلمة المرور إلى $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn ? 'Error: ${e.toString()}' : 'خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isEn = app.locale.languageCode == 'en';
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => app.toggleLanguage(),
            icon: const Icon(Icons.translate),
            tooltip: isEn ? 'Switch Language' : 'تغيير اللغة',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      isEn ? 'Welcome back' : 'مرحباً بعودتك',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEn ? 'Sign in to continue learning.' : 'سجل دخولك لمتابعة التعلم.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: isEn ? 'Email' : 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.mail_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return isEn ? 'Enter email' : 'أدخل البريد الإلكتروني';
                        }
                        if (!v.contains('@')) {
                          return isEn ? 'Enter a valid email' : 'أدخل بريد إلكتروني صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: isEn ? 'Password' : 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return isEn ? 'At least 6 characters' : '6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: isEn ? Alignment.centerRight : Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _busy ? null : _forgotPassword,
                        child: Text(isEn ? 'Forgot Password?' : 'نسيت كلمة المرور؟'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEn ? 'Sign in' : 'تسجيل الدخول'),
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(isEn ? 'New here?' : 'جديد هنا؟'),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.register);
                          },
                          child: Text(isEn ? 'Create account' : 'إنشاء حساب'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
