import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import 'category_selection_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'you@example.com');
  final _passwordController = TextEditingController(text: '12345678');
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  void _handleLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final langProvider = Provider.of<AppLanguageProvider>(context, listen: false);
    final isBn = langProvider.isBangla;

    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    bool hasError = false;
    if (email.isEmpty) {
      setState(() => _emailError = isBn ? 'ইউজারনেম অথবা ইমেইল দেওয়া আবশ্যিক' : 'Email is required');
      hasError = true;
    }

    if (pass.isEmpty) {
      setState(() => _passwordError = isBn ? 'পাসওয়ার্ড প্রদান করা আবশ্যিক' : 'Password is required');
      hasError = true;
    } else if (pass.length < 6) {
      setState(() => _passwordError = isBn ? 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে' : 'Password must be at least 6 characters');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(email, pass);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
      );
    } else if (mounted) {
      setState(() {
        _emailError = isBn ? 'ইউজারনেম বা ইমেইল সঠিক নয়' : 'Incorrect email or username';
        _passwordError = isBn ? 'পাসওয়ার্ডটি ভুল হয়েছে' : 'Incorrect password';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBn
                ? 'লগইন তথ্য ভুল দেওয়া হয়েছে! চিহ্নিত লাল ফিল্ডগুলো চেক করুন।'
                : 'Incorrect credentials! Please check highlighted red fields.',
          ),
          backgroundColor: AppColors.emergency,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final langProvider = Provider.of<AppLanguageProvider>(context, listen: false);
    final isBn = langProvider.isBangla;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBn ? 'গুগল অ্যাকাউন্ট দিয়ে সফলভাবে লগইন হয়েছে!' : 'Logged in with Google successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
    );
  }

  Future<void> _handleFacebookLogin() async {
    final langProvider = Provider.of<AppLanguageProvider>(context, listen: false);
    final isBn = langProvider.isBangla;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isBn ? 'ফেসবুক অ্যাকাউন্ট দিয়ে সফলভাবে লগইন হয়েছে!' : 'Logged in with Facebook successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<AppLanguageProvider>(context);
    final themeProvider = Provider.of<AppThemeProvider>(context);
    final isBn = langProvider.isBangla;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.language_rounded, color: AppColors.primary),
                    onPressed: () => langProvider.toggleLanguage(),
                  ),
                  IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      themeProvider.toggleTheme(!themeProvider.isDarkMode);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Official Ashwash Logo
              Image.asset(
                'assets/images/logo.png',
                width: 130,
                height: 130,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),

              Text(
                isBn ? 'স্বাগতম' : 'Welcome Back',
                style: AppTypography.heading1(context),
              ),
              const SizedBox(height: 8),
              Text(
                isBn ? 'মানসিক সুস্থতায় আপনার নিরাপদ স্থান' : 'Your Safe Space for Mental Wellness',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 36),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (val) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
                decoration: InputDecoration(
                  labelText: isBn ? 'ইমেইল' : 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: _emailError,
                  errorStyle: const TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.emergency, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.emergency, width: 1.5),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                onChanged: (val) {
                  if (_passwordError != null) setState(() => _passwordError = null);
                },
                decoration: InputDecoration(
                  labelText: isBn ? 'পাসওয়ার্ড' : 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  errorText: _passwordError,
                  errorStyle: const TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.emergency, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.emergency, width: 1.5),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isBn ? 'লগইন' : 'Login',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      isBn ? 'অথবা চালু রাখুন' : 'Or continue with',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 20),

              // Social Logins
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _handleGoogleLogin(),
                      icon: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.asset(
                            'assets/images/google_g_logo.jpg',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 24),
                          ),
                        ),
                      ),
                      label: const Text('Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _handleFacebookLogin(),
                      icon: const Icon(Icons.facebook, color: Colors.blue, size: 22),
                      label: const Text('Facebook', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isBn ? 'একাউন্ট নেই? ' : "Don't have an account? ",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      isBn ? 'সাইন আপ' : 'Sign Up',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
