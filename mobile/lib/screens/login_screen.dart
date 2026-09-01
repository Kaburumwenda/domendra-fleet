import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

/// Login screen — mirrors the web `login.vue`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'manager@acme.com');
  final _passwordController = TextEditingController(text: 'Manager@12345');
  bool _obscurePassword = true;
  bool _loading = false;
  String? _serverError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemo(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _serverError = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.login(_emailController.text, _passwordController.text);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      setState(() {
        _serverError = _parseError(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseError(dynamic e) {
    final str = e.toString();
    // Dio wraps responses — try to extract the `detail` field
    if (str.contains('detail')) {
      final match = RegExp(r"'detail':\s*'([^']+)'").firstMatch(str);
      if (match != null) return match.group(1)!;
    }
    if (str.contains('401') || str.contains('Invalid')) return 'Invalid email or password';
    if (str.contains('Connection') || str.contains('Socket')) {
      return 'Cannot connect to server. Make sure the backend is running on ${AppConfig.apiBase}.';
    }
    return 'Login failed. Please check your credentials.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DomendraTheme.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // ── Logo ────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: DomendraTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                AppConfig.appName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: DomendraTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DomendraTheme.onSurface,
                ),
              ),
              const Text(
                'Sign in to your fleet management dashboard',
                style: TextStyle(
                  fontSize: 14,
                  color: DomendraTheme.onSurfaceMuted,
                ),
              ),

              const SizedBox(height: 36),

              // ── Server error ────────────────────────────
              if (_serverError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DomendraTheme.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DomendraTheme.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: DomendraTheme.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _serverError!,
                          style: const TextStyle(color: DomendraTheme.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Form ────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined, size: 22, color: DomendraTheme.onSurfaceMuted),
                        labelText: 'Email',
                        hintText: 'you@company.com',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v)) return 'Enter a valid email';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, size: 22, color: DomendraTheme.onSurfaceMuted),
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: DomendraTheme.onSurfaceMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),

                    const SizedBox(height: 28),

                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleLogin,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── Demo credentials ─────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DomendraTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DomendraTheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.key, size: 16, color: DomendraTheme.onSurfaceMuted),
                        const SizedBox(width: 6),
                        const Text(
                          'Demo credentials',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DomendraTheme.onSurfaceMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _DemoCard(
                      label: 'Tenant Manager',
                      email: 'manager@acme.com',
                      onTap: () => _fillDemo('manager@acme.com', 'Manager@12345'),
                    ),
                    const SizedBox(height: 8),
                    _DemoCard(
                      label: 'Super Admin',
                      email: 'admin@domendra.com',
                      onTap: () => _fillDemo('admin@domendra.com', 'SuperAdmin@12345'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap any card to auto-fill',
                      style: TextStyle(fontSize: 11, color: DomendraTheme.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
class _DemoCard extends StatelessWidget {
  final String label;
  final String email;
  final VoidCallback onTap;

  const _DemoCard({required this.label, required this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DomendraTheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DomendraTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DomendraTheme.primary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                email,
                style: const TextStyle(fontSize: 13, color: DomendraTheme.onSurface, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
