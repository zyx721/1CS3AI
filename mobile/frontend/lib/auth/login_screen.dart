import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// --- CSS Variables ---
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // --- State Variables ---
  bool _isSignUp = false;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Animation Controllers ---
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // --- Controllers for inputs ---
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();

    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        print('User is signed in! Navigating...');
        _handleUserSignedIn(user);
      } else {
        print('User is currently signed out!');
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  // --- Device Token Functions ---
  Future<String?> generateDeviceToken() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission for notifications
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Notification permissions denied');
        return null;
      }

      // Get the device token
      final String? token = await messaging.getToken();

      if (token != null) {
        debugPrint('Device token generated: $token');
        return token;
      } else {
        debugPrint('Failed to generate device token');
        return null;
      }
    } catch (e) {
      debugPrint('Error generating device token: $e');
      return null;
    }
  }

  Future<void> saveDeviceTokenToFirestore(String userId) async {
    try {
      final String? token = await generateDeviceToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'deviceToken': token,
        });
        debugPrint('Device token saved to Firestore: $token');
      } else {
        debugPrint('Device token generation failed');
      }
    } catch (e) {
      debugPrint('Error saving device token to Firestore: $e');
    }
  }

  // --- Handle User Sign In Navigation ---
  Future<void> _handleUserSignedIn(User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Navigate based on user status
      if (mounted) {
        // If isFirst is true or missing, go to lead setup
        if (!userDoc.exists || userDoc.data()?['isFirst'] == true || userDoc.data()?['isFirst'] == null) {
          Navigator.pushReplacementNamed(context, '/lead');
        } else {
          // If isFirst is false, go to navbar
          Navigator.pushReplacementNamed(context, '/navbar');
        }
      }
    } catch (e) {
      debugPrint('Error handling user sign in: $e');
    }
  }

  // --- Toggle Form with Animation ---
  void _toggleForm() {
    setState(() {
      _isSignUp = !_isSignUp;
      if (_isSignUp) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    });
  }

  // --- UI Building ---
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
                    maxWidth: isDesktop ? 768 : 400,
                    minHeight: isDesktop ? 520 : 600,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildMainContainer(isDesktop),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContainer(bool isDesktop) {
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
          child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final screenWidth = MediaQuery.of(context).size.width.clamp(0.0, 768.0);
    return Stack(
      children: [
        // Sign Up Form
        SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: screenWidth / 2,
            child: _buildSignUpForm(isMobile: false),
          ),
        ),
        // Sign In Form
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeInOutCubic,
          )),
          child: Container(
            width: screenWidth / 2,
            child: _buildSignInForm(isMobile: false),
          ),
        ),
        // Overlay
        AnimatedPositioned(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          top: 0,
          bottom: 0,
          left: _isSignUp ? screenWidth / 2 : 0,
          width: screenWidth / 2,
          child: _buildOverlay(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: Offset(child.key == const ValueKey('signIn') ? -1.0 : 1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ));
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: _isSignUp
          ? _buildSignUpForm(isMobile: true, key: const ValueKey('signUp'))
          : _buildSignInForm(isMobile: true, key: const ValueKey('signIn')),
    );
  }

  Widget _buildSignInForm({required bool isMobile, Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Sign In', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 15),
          _buildSocialContainer(isSignUp: false),
          const SizedBox(height: 15),
          Text('or use your account', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight.withOpacity(0.7))),
          const SizedBox(height: 10),
          _buildTextField(controller: _signInEmailController, hint: 'Email', isEmail: true),
          _buildTextField(controller: _signInPasswordController, hint: 'Password', isPassword: true),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot-password');
              },
              child: Text('Forgot your password?', style: GoogleFonts.inter(color: AppColors.textLight.withOpacity(0.7))),
            ),
          ),
          const SizedBox(height: 10),
          _buildPrimaryButton(text: 'Sign In', onPressed: _handleEmailSignIn),
          if (isMobile) _buildMobileSwitcher(isSignUp: false),
        ],
      ),
    );
  }

  Widget _buildSignUpForm({required bool isMobile, Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Create Account', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 15),
          _buildSocialContainer(isSignUp: true),
          const SizedBox(height: 15),
          Text('or use your email for registration', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight.withOpacity(0.7))),
          const SizedBox(height: 10),
          _buildTextField(controller: _signUpNameController, hint: 'Name'),
          _buildTextField(controller: _signUpEmailController, hint: 'Email', isEmail: true),
          _buildTextField(controller: _signUpPasswordController, hint: 'Password', isPassword: true),
          const SizedBox(height: 20),
          _buildPrimaryButton(text: 'Sign Up', onPressed: _handleEmailSignUp),
          if (isMobile) _buildMobileSwitcher(isSignUp: true),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF1D221C), Color(0xFF3B5428)],
        ),
      ),
      child: Stack(
        children: [
          // "Welcome Back!" panel
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _isSignUp ? 1.0 : 0.0,
            child: _buildOverlayPanel(
              title: 'Welcome Back!',
              text: 'To keep connected with us please login with your personal info',
              buttonText: 'Sign In',
              onPressed: _toggleForm,
            ),
          ),
          // "Hello, Friend!" panel
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _isSignUp ? 0.0 : 1.0,
            child: _buildOverlayPanel(
              title: 'Hello, Friend!',
              text: 'Enter your personal details and start your journey with us',
              buttonText: 'Sign Up',
              onPressed: _toggleForm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayPanel({required String title, required String text, required String buttonText, required VoidCallback onPressed}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textLight)),
          const SizedBox(height: 20),
          Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: AppColors.textLight)),
          const SizedBox(height: 30),
          _buildGhostButton(text: buttonText, onPressed: onPressed),
        ],
      ),
    );
  }

  Widget _buildMobileSwitcher({required bool isSignUp}) {
    return Padding(
      padding: const EdgeInsets.only(top: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isSignUp ? 'Already have an account?' : "Don't have an account?",
            style: GoogleFonts.inter(color: AppColors.textLight.withOpacity(0.7)),
          ),
          TextButton(
            onPressed: _toggleForm,
            child: Text(
              isSignUp ? 'Sign In' : 'Sign Up',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }

  // --- Reusable Widgets ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
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
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1),
      ),
      onPressed: _isLoading ? null : onPressed,
      child: _isLoading 
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.bgDark, strokeWidth: 3)) 
          : Text(text.toUpperCase()),
    );
  }

  Widget _buildGhostButton({required String text, required VoidCallback onPressed}) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textLight,
        side: const BorderSide(color: AppColors.textLight, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 45),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1),
      ),
      onPressed: onPressed,
      child: Text(text.toUpperCase()),
    );
  }

  Widget _buildSocialContainer({required bool isSignUp}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: _isLoading ? null : () => _handleGoogleSignIn(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Center(
              child: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenAccent),
                      ),
                    )
                  // Use PNG asset instead of SVG
                  : Image.asset(
                      'assets/images/google_logo.png',
                      width: 20,
                      height: 20,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground() {
    return const Stack(
      children: [
        // Glowing Orbs
        Positioned(top: -100, left: -150, child: _GlowCircle(size: 400, color: AppColors.greenGlow1)),
        Positioned(bottom: -120, right: -180, child: _GlowCircle(size: 500, color: AppColors.greenGlow2)),
      ],
    );
  }

  // --- Authentication Logic ---
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

  // Email validation
  bool _isValidEmail(String email) {
    final emailPattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
    final emailRegex = RegExp(emailPattern);
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleEmailSignUp() async {
    if (_isLoading) return;
    
    final name = _signUpNameController.text.trim();
    final email = _signUpEmailController.text.trim();
    final password = _signUpPasswordController.text.trim();

    // Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorSnackBar('Invalid email format');
      return;
    }

    if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();
        
        // Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'createdAt': DateTime.now(),
          'isFirst': true,
          'isConnected': false,
          'isEmailVerified': false,
        });

        await saveDeviceTokenToFirestore(user.uid);

        // Sign out user until they verify email
        await _auth.signOut();
        
        _showSuccessSnackBar('Verification email sent! Please check your email.');
        
        // Clear form and switch to sign in
        _signUpNameController.clear();
        _signUpEmailController.clear();
        _signUpPasswordController.clear();
        _toggleForm();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Sign Up Error: ';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage += 'Email is already registered';
          break;
        case 'weak-password':
          errorMessage += 'Password is too weak';
          break;
        case 'invalid-email':
          errorMessage += 'Invalid email format';
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

  Future<void> _handleEmailSignIn() async {
    if (_isLoading) return;
    
    final email = _signInEmailController.text.trim();
    final password = _signInPasswordController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please enter both email and password');
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorSnackBar('Invalid email format');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        // Check if email is verified
        if (!user.emailVerified) {
          _showErrorSnackBar('Please verify your email before logging in');
          await _auth.signOut();
          return;
        }

        // Update user data
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'lastSignIn': DateTime.now(),
          'isConnected': true,
          'isEmailVerified': true,
        }, SetOptions(merge: true));

        await saveDeviceTokenToFirestore(user.uid);
        // Navigation is handled by authStateChanges listener
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Sign In Error: ';
      switch (e.code) {
        case 'user-not-found':
          errorMessage += 'No user found for that email';
          break;
        case 'wrong-password':
          errorMessage += 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage += 'Invalid email format';
          break;
        case 'user-disabled':
          errorMessage += 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage += 'Too many failed attempts. Try again later';
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

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          Map<String, dynamic> userData = {
            'uid': user.uid,
            'email': user.email ?? 'No Email',
            'lastSignIn': DateTime.now(),
            'isConnected': true,
            'isEmailVerified': true,
          };

          if (!userDoc.exists || userDoc.data()?['name'] == null) {
            userData['name'] = user.displayName ?? 'No Name';
          }

          if (!userDoc.exists ||
              userDoc.data()?['photoURL'] == null ||
              (userDoc.data()?['photoURL']?.isEmpty ?? true)) {
            userData['photoURL'] = user.photoURL ?? '';
          }

          if (!userDoc.exists) {
            userData['createdAt'] = DateTime.now();
            userData['isFirst'] = true;
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(userData, SetOptions(merge: true));

          await saveDeviceTokenToFirestore(user.uid);
          // Navigation is handled by authStateChanges listener
        }
      } else {
        _showErrorSnackBar('Google Sign-In was canceled');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _showErrorSnackBar('Account exists with different credentials');
      } else {
        _showErrorSnackBar('Google Sign-In Error: ${e.message}');
      }
    } catch (error) {
      _showErrorSnackBar('An unexpected error occurred during Google Sign-In.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Helper widget for the background glow effect
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