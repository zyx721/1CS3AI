import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- CSS Variables (matching login screen) ---
class AppColors {
  static const Color bgDark = Color(0xFF131414);
  static const Color textLight = Color(0xFFF5F4F0);
  static const Color greenAccent = Color(0xFF79B266);
  static const Color greenGlow1 = Color(0x66789D6E); // 0.4 opacity
  static const Color greenGlow2 = Color(0x666A905E); // 0.4 opacity
  static const Color borderLight = Color(0x33F5F4F0); // 0.2 opacity
  static const Color formBg = Color(0x4D191A1A); // 0.3 opacity
  static const Color inputBg = Color(0x33000000); // 0.2 opacity
  static const Color inputPlaceholder = Color(0x99F5F4F0); // 0.6 opacity
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  // --- Animation Controllers ---
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Email validation (matching login screen)
  bool _isValidEmail(String email) {
    final emailPattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
    final emailRegex = RegExp(emailPattern);
    return emailRegex.hasMatch(email);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _recoverPassword() async {
    if (_isLoading) return;
    
    final email = _emailController.text.trim();

    // Validation
    if (email.isEmpty) {
      _showErrorSnackBar('Please enter your email address');
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorSnackBar('Invalid email format');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final querySnapshot = await usersCollection.where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isEmpty) {
        _showErrorSnackBar('No user found with this email');
      } else {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        _showSuccessSnackBar('Password reset email sent! Please check your inbox.');
        
        // Clear the email field
        _emailController.clear();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Reset Password Error: ';
      switch (e.code) {
        case 'user-not-found':
          errorMessage += 'No user found for that email';
          break;
        case 'invalid-email':
          errorMessage += 'Invalid email format';
          break;
        case 'too-many-requests':
          errorMessage += 'Too many requests. Try again later';
          break;
        default:
          errorMessage += e.message ?? 'Unknown error';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 768;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 500 : 400,
                    minHeight: isDesktop ? 400 : 500,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildMainContainer(),
                  ),
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textLight,
                size: 20,
              ),
              splashRadius: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContainer() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.formBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: AppColors.greenAccent.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 40,
                    color: AppColors.greenAccent,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Title
                Text(
                  'Forgot Password?',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Subtitle
                Text(
                  'Don\'t worry! Enter your email address and we\'ll send you a password reset link.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textLight.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Email input
                _buildTextField(
                  controller: _emailController,
                  hint: 'Enter your email',
                  isEmail: true,
                ),
                const SizedBox(height: 30),
                
                // Reset button
                _buildPrimaryButton(
                  text: 'Send Reset Link',
                  onPressed: _recoverPassword,
                ),
                const SizedBox(height: 25),
                
                // Back to login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remember your password?',
                      style: GoogleFonts.inter(
                        color: AppColors.textLight.withOpacity(0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.greenAccent,
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isEmail = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.inputBg,
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.inputPlaceholder),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.greenAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
    );
  }

  Widget _buildPrimaryButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.greenAccent,
        foregroundColor: AppColors.bgDark,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 45),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
      onPressed: _isLoading ? null : onPressed,
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: AppColors.bgDark,
                strokeWidth: 3,
              ),
            )
          : Text(text.toUpperCase()),
    );
  }

  Widget _buildAnimatedBackground() {
    return const Stack(
      children: [
        // Glowing Orbs (matching login screen)
        Positioned(
          top: -100,
          left: -150,
          child: _GlowCircle(size: 400, color: AppColors.greenGlow1),
        ),
        Positioned(
          bottom: -120,
          right: -180,
          child: _GlowCircle(size: 500, color: AppColors.greenGlow2),
        ),
      ],
    );
  }
}

// Helper widget for the background glow effect (matching login screen)
class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}