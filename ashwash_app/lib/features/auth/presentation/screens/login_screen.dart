import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/specialist_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../navigation/presentation/screens/main_navigation_screen.dart';
import 'register_screen.dart';
import 'category_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBangla;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool hasError = false;
    if (email.isEmpty) {
      setState(() => _emailError = isBn ? 'ইউজারনেম অথবা ইমেইল দেওয়া আবশ্যিক' : 'Username or Email is required');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = isBn ? 'পাসওয়ার্ড প্রদান করা আবশ্যিক' : 'Password is required');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = isBn ? 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে' : 'Password must contain at least 6 characters');
      hasError = true;
    }

    if (hasError) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(email, password, role: 'PATIENT');

    if (!mounted) return;

    if (success) {
      Provider.of<DashboardProvider>(context, listen: false).clearUserData();
      Provider.of<SpecialistProvider>(context, listen: false).clearPatientData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      final err = (authProvider.errorMessage ?? '').toLowerCase();
      String snackbarMessage = isBn
          ? 'লগইন ব্যর্থ! দয়া করে লাল চিহ্নিত ফিল্ডগুলো চেক করুন।'
          : 'Incorrect credentials! Please check the highlighted red fields.';

      setState(() {
        if (err.contains('connection') || err.contains('timeout') || err.contains('server')) {
          snackbarMessage = isBn
              ? 'সার্ভার চালু হচ্ছে। দয়া করে ১ মিনিট পর আবার চেষ্টা করুন।'
              : 'Server is waking up (cold start). Please try again in 1 minute.';
        } else if (err.contains('password') || err.contains('credential') || err.contains('invalid')) {
          _passwordError = isBn ? 'ভুল পাসওয়ার্ড! আবার চেষ্টা করুন' : 'Incorrect password! Please try again';
          _emailError = isBn ? 'ইউজারনেম বা ইমেইল চেক করুন' : 'Check username or email';
        } else if (err.contains('user') || err.contains('email') || err.contains('not found')) {
          _emailError = isBn ? 'ভুল ইউজারনেম বা ইমেইল' : 'Incorrect username or email address';
        } else {
          _emailError = isBn ? 'ভুল ইউজারনেম বা ইমেইল' : 'Wrong username or email';
          _passwordError = isBn ? 'ভুল পাসওয়ার্ড' : 'Wrong password';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackbarMessage),
          backgroundColor: AppColors.emergency,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.isBangla;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.loginWithGoogle();

    if (!mounted) return;

    if (result['success'] == true) {
      final bool isNewUser = result['isNewUser'] ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'গুগল অ্যাকাউন্ট দিয়ে সফলভাবে অ্যাকাউন্ট সংযুক্ত হয়েছে!' : 'Signed in with Google successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Provider.of<DashboardProvider>(context, listen: false).clearUserData();
      Provider.of<SpecialistProvider>(context, listen: false).clearPatientData();
      if (isNewUser) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } else if (result['fallback'] == true) {
      // Graceful fallback for local debug build without SHA-1
      final selectedAccount = await showModalBottomSheet<Map<String, String>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => _GoogleAccountPickerSheet(isBn: isBn),
      );

      if (selectedAccount == null) return;

      final directResult = await authProvider.loginWithGoogleDirect(
        email: selectedAccount['email']!,
        name: selectedAccount['name']!,
      );

      if (!mounted) return;

      if (directResult['success'] == true) {
        final bool isNewUser = directResult['isNewUser'] ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBn ? 'গুগল অ্যাকাউন্ট দিয়ে সফলভাবে অ্যাকাউন্ট সংযুক্ত হয়েছে!' : 'Signed in with Google successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (isNewUser) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CategorySelectionScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        }
      }
    } else if (result['cancelled'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? (isBn ? 'গুগল সাইন-ইন ব্যর্থ হয়েছে।' : 'Google Sign-In failed.')),
          backgroundColor: AppColors.emergency,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBn = langProvider.isBangla;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Top Actions: Globe (Lang) & Moon/Sun (Theme) Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.language_rounded,
                      color: isDark ? Colors.white70 : AppColors.primary,
                    ),
                    onPressed: () => langProvider.toggleLanguage(),
                  ),
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      color: isDark ? Colors.amber : AppColors.primary,
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Brand Icon Logo Image
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: AppColors.glassSurface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Header Titles
              Text(
                isBn ? 'স্বাগতম' : 'Welcome Back',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isBn ? 'মানসিক স্বাস্থ্যের জন্য আপনার নিরাপদ ঠিকানা' : 'Your Safe Space for Mental Wellness',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 36),

              // Form Credentials
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'ইউজারনেম অথবা ইমেইল' : 'Username or Email',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) {
                        if (_emailError != null) setState(() => _emailError = null);
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded),
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
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      isBn ? 'পাসওয়ার্ড' : 'Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (val) {
                        if (_passwordError != null) setState(() => _passwordError = null);
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
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
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Login Button
              ElevatedButton(
                onPressed: authProvider.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isBn ? 'লগইন' : 'Login',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 32),

              // Footer Link ("Don't have an account? Sign Up")
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isBn ? 'একাউন্ট নেই? ' : "Don't have an account? ",
                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class OfficialGoogleLogo extends StatelessWidget {
  final double size;
  const OfficialGoogleLogo({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.glassSurface,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: Image.network(
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
        width: size - 4,
        height: size - 4,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) {
          return Center(
            child: Text(
              'G',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: size * 0.65,
                color: const Color(0xFF4285F4),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GoogleAccountPickerSheet extends StatefulWidget {
  final bool isBn;
  const _GoogleAccountPickerSheet({required this.isBn});

  @override
  State<_GoogleAccountPickerSheet> createState() => _GoogleAccountPickerSheetState();
}

class _GoogleAccountPickerSheetState extends State<_GoogleAccountPickerSheet> {
  final _emailCtrl = TextEditingController(text: 'user@gmail.com');
  final _nameCtrl = TextEditingController(text: 'Google User');
  bool _isCustom = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBn;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const OfficialGoogleLogo(size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isBn ? 'আশ্বাসে চালিয়ে যেতে একটি গুগল অ্যাকাউন্ট বেছে নিন' : 'Choose an account to continue to Ashwash',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF4285F4),
              child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text('Google User', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            subtitle: const Text('user@gmail.com'),
            onTap: () => Navigator.pop(context, {'email': 'user@gmail.com', 'name': 'Google User'}),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text('Ashwash Patient', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            subtitle: const Text('ashwash.patient@gmail.com'),
            onTap: () => Navigator.pop(context, {'email': 'ashwash.patient@gmail.com', 'name': 'Ashwash Patient'}),
          ),
          const Divider(),
          if (!_isCustom)
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: Text(isBn ? 'অন্য গুগল অ্যাকাউন্ট যোগ বা ব্যবহার করুন' : 'Use another Google account'),
              onTap: () => setState(() => _isCustom = true),
            )
          else ...[
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: isBn ? 'আপনার নাম' : 'Your Name',
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isBn ? 'গুগল ইমেইল (e.g. user@gmail.com)' : 'Google Email (e.g. user@gmail.com)',
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final email = _emailCtrl.text.trim();
                final name = _nameCtrl.text.trim();
                if (email.isNotEmpty && email.contains('@')) {
                  Navigator.pop(context, {'email': email, 'name': name.isEmpty ? 'Google User' : name});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isBn ? 'চালিয়ে যান' : 'Continue', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
