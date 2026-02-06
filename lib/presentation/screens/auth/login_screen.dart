import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../services/auth_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/notification_scheduler_service.dart';

/// Login screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();

      // Show loading message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Signing in...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Wait a moment for auth state to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Refresh auth provider to ensure state is updated
      ref.invalidate(currentUserStreamProvider);

      // Initialize notification scheduler
      try {
        final scheduler = NotificationSchedulerService();
        await scheduler.initialize();
      } catch (e) {
        // Don't fail login if notification initialization fails
        print('Error initializing notifications: $e');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Login successful!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Navigate to home after a brief delay
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Login failed: ${e.toString().replaceAll('Exception: ', '')}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Use theme background
      /* appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/onboarding'),
        ),
      ), */
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveConfig.padding(all: 24),
            child: Center(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome Back',
                      style: ResponsiveConfig.textStyle(
                        size: 28,
                        weight: FontWeight.bold,
                        color: Theme.of(context).textTheme.displaySmall?.color,
                      ),
                    ),
                    ResponsiveConfig.heightBox(8),
                    Text(
                      'Sign in to continue',
                      style: ResponsiveConfig.textStyle(
                        size: 16,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    ResponsiveConfig.heightBox(32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validators.email,
                    ),
                    ResponsiveConfig.heightBox(16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    ResponsiveConfig.heightBox(8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Navigate to forgot password
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    ResponsiveConfig.heightBox(24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: ResponsiveConfig.padding(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                ResponsiveConfig.widthBox(12),
                                const Text('Signing in...'),
                              ],
                            )
                          : const Text('Sign In'),
                    ),
                    ResponsiveConfig.heightBox(24),
                    _buildSocialAuth(context),
                    ResponsiveConfig.heightBox(16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/signup'),
                          child: const Text('Sign Up'),
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

  Widget _buildSocialAuth(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: ResponsiveConfig.textStyle(
                    size: 14, color: AppTheme.mediumGray),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        ResponsiveConfig.heightBox(20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(
              icon: FontAwesomeIcons.google,
              onTap: () => _handleSocialSignIn(
                  ref.read(authServiceProvider).signInWithGoogle),
            ),
            ResponsiveConfig.widthBox(20),
            _socialButton(
              icon: FontAwesomeIcons.apple,
              onTap: () => _handleSocialSignIn(
                  ref.read(authServiceProvider).signInWithApple),
              isApple: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialButton(
      {required IconData icon,
      required VoidCallback onTap,
      bool isApple = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkGray.withOpacity(0.3) : Colors.white,
          border: Border.all(color: AppTheme.mediumGray.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FaIcon(
          icon,
          size: 28,
          color: isApple
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? Colors.white : AppTheme.primaryPink),
        ),
      ),
    );
  }

  Future<void> _handleSocialSignIn(
      Future<dynamic> Function() signInMethod) async {
    setState(() => _isLoading = true);
    try {
      await signInMethod();

      // Wait for auth state to propagate
      await Future.delayed(const Duration(milliseconds: 500));

      // Force provider refresh to update auth state
      ref.invalidate(currentUserStreamProvider);

      // Initialize notification scheduler
      try {
        final scheduler = NotificationSchedulerService();
        await scheduler.initialize();
      } catch (e) {
        print('Error initializing notifications: $e');
      }

      // Navigate to home
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
