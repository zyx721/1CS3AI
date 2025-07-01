import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http; // <-- Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// === THEME & CONSTANTS ===
class AppTheme {
  static const Color bgDark = Color(0xFF0A0B0C);
  static const Color cardBg = Color(0xFF1A1B1C);
  static const Color textLight = Color(0xFFF5F4F0);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color gradientStart = Color(0xFF2E402B);
  static const Color gradientEnd = Color(0xFF79B266);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color borderColor = Color.fromRGBO(245, 244, 240, 0.15);
  static const double borderRadius = 12.0;
  
  // Enhanced gradient colors for background
  static const Color bgGradient1 = Color.fromRGBO(46, 64, 43, 0.6);
  static const Color bgGradient2 = Color.fromRGBO(90, 124, 80, 0.5);
  static const Color bgGradient3 = Color.fromRGBO(121, 178, 102, 0.4);
}

class AppConstants {
  static const int totalFormSteps = 2;
  static const Duration animationDuration = Duration(milliseconds: 400);
  static const Duration backgroundAnimationDuration = Duration(seconds: 120);
}

// === MAIN SCREEN ===
class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> 
    with TickerProviderStateMixin {
  
  // Animation Controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _pulseAnimationController;
  late PageController _pageController;

  // State Variables
  int _currentPage = 0;
  bool _isSubmitting = false;
  String? _submitError;
  bool _submitSuccess = false;
  
  // Form Controllers & Keys
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(), 
    GlobalKey<FormState>()
  ];
  
  final _businessNameController = TextEditingController();
  final _servicesController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedIndustry;
  List<String> _selectedCountries = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _pageController = PageController();
    
    // Enhanced background animation
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: AppConstants.backgroundAnimationDuration,
    )..repeat(reverse: true);
    
    // Pulse animation for enhanced gradient effect
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _pulseAnimationController.dispose();
    _pageController.dispose();
    _businessNameController.dispose();
    _servicesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // === NAVIGATION METHODS ===
  void _nextPage() {
    if (_currentPage < AppConstants.totalFormSteps && 
        !_formKeys[_currentPage].currentState!.validate()) {
      return;
    }

    if (_currentPage < AppConstants.totalFormSteps) {
      _pageController.nextPage(
        duration: AppConstants.animationDuration,
        curve: Curves.easeInOut,
      );
    }

    if (_currentPage == AppConstants.totalFormSteps - 1) {
      _collectAndSubmitData();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: AppConstants.animationDuration,
      curve: Curves.easeInOut,
    );
  }

  void _collectAndSubmitData() async {
    final businessInfo = {
      'business_name': _businessNameController.text,
      'domain': _selectedIndustry,
      // Convert list to comma-separated string for backend compatibility
      'location': _selectedCountries.isNotEmpty ? _selectedCountries.join(', ') : 'Global',
      'services': _servicesController.text,
      'description': _descriptionController.text,
    };

    setState(() {
      _isSubmitting = true;
      _submitError = null;
      _submitSuccess = false;
    });

    try {
      // Use the correct endpoint and fix the URL
      final response = await http.post(
        Uri.parse('http://192.168.100.5:8000/agent-info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(businessInfo),
      );
      if (response.statusCode == 200) {
        // Set isFirst to false after successful setup
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'isFirst': false});
        }
        setState(() {
          _submitSuccess = true;
        });
        // Navigate to navbar after setup
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/navbar');
        }
        // Optionally, go to the next page (completion step)
        // _pageController.nextPage(
        //   duration: AppConstants.animationDuration,
        //   curve: Curves.easeInOut,
        // );
      } else {
        setState(() {
          _submitError = 'Failed to submit: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _submitError = 'Error: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildEnhancedAnimatedBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Stack(
                  children: [
                    _buildWizardContainer(),
                    if (_isSubmitting)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.4),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.gradientEnd,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === BACKGROUND WIDGETS ===
  Widget _buildEnhancedAnimatedBackground() {
    return Stack(
      children: [
        // Base gradient layer
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                AppTheme.bgGradient1,
                Colors.transparent,
              ],
            ),
          ),
        ),
        
        // Animated gradient layers with enhanced green emphasis
        AnimatedBuilder(
          animation: _backgroundAnimationController,
          builder: (context, child) {
            final value = _backgroundAnimationController.value;
            return Transform.scale(
              scale: 1.0 + (value * 0.4),
              child: Transform.translate(
                offset: Offset(
                  math.sin(value * 2 * math.pi) * 80,
                  math.cos(value * 2 * math.pi) * 60,
                ),
                child: Transform.rotate(
                  angle: value * (math.pi / 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.6, 0.3),
                        radius: 1.4,
                        colors: [
                          AppTheme.bgGradient2,
                          AppTheme.bgGradient3,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 0.8],
                      ),
                    ),
                  ),
                ),
              ),);
          },
        ),
        
        // Pulsing gradient overlay for extra emphasis
        AnimatedBuilder(
          animation: _pulseAnimationController,
          builder: (context, child) {
            final pulseValue = _pulseAnimationController.value;
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.7),
                  radius: 1.2 + (pulseValue * 0.5),
                  colors: [
                    AppTheme.gradientEnd.withOpacity(0.3 * (1 - pulseValue)),
                    AppTheme.accentGreen.withOpacity(0.2 * (1 - pulseValue)),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            );
          },
        ),
        
        // Floating orbs for additional visual interest
        ...List.generate(3, (index) => _buildFloatingOrb(index)),
      ],
    );
  }

  Widget _buildFloatingOrb(int index) {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        final offset = (index + 1) * 0.3;
        final value = (_backgroundAnimationController.value + offset) % 1.0;
        
        return Positioned(
          left: 50 + (index * 100) + (math.sin(value * 2 * math.pi) * 40),
          top: 100 + (index * 150) + (math.cos(value * 2 * math.pi) * 30),
          child: Container(
            width: 60 + (index * 20),
            height: 60 + (index * 20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.gradientEnd.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // === WIZARD CONTAINER ===
  Widget _buildWizardContainer() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBg.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.gradientEnd.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gradientEnd.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWizardHeader(),
                _buildWizardBody(),
                if (_currentPage < AppConstants.totalFormSteps) 
                  _buildWizardNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWizardHeader() {
    final progress = _currentPage >= AppConstants.totalFormSteps
        ? 1.0
        : (_currentPage / (AppConstants.totalFormSteps - 1));

    return Container(
      padding: const EdgeInsets.fromLTRB(40, 30, 40, 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.gradientStart.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppTheme.textLight,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Chilbot AI',
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _buildProgressIndicator(progress),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(double progress) {
    // If on first step, use green background, else use default
    final isFirstStep = progress == 0.0;
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: isFirstStep
            ? AppTheme.gradientEnd.withOpacity(0.25)
            : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: progress),
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.gradientEnd,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWizardBody() {
    return SizedBox(
      height: 480,
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) => setState(() => _currentPage = page),
        children: [
          FormStep(
            key: const ValueKey('step1'),
            formKey: _formKeys[0],
            title: "Let's Configure Your Agent",
            subtitle: "This information helps your AI agent understand your business to find the most relevant leads.",
            child: _buildStep1Content(),
          ),
          FormStep(
            key: const ValueKey('step2'),
            formKey: _formKeys[1],
            title: 'Tell Us More',
            subtitle: 'Describe your offerings. The more detail you provide, the smarter your agent will be.',
            child: _buildStep2Content(),
          ),
          _buildCompletionStep(),
        ],
      ),
    );
  }

  // === FORM STEP CONTENT ===
  Widget _buildStep1Content() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _businessNameController,
          label: 'Business Name',
          hint: 'e.g., Your Company LLC',
          validator: (val) => val?.isEmpty == true ? 'Business name is required' : null,
        ),
        const SizedBox(height: 25),
        IndustryDropdownField(
          value: _selectedIndustry,
          onChanged: (value) => setState(() => _selectedIndustry = value),
        ),
        const SizedBox(height: 25),
        // Wrap in a scrollable to ensure visibility when keyboard is up
        LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 0,
                maxHeight: MediaQuery.of(context).size.height * 0.25,
              ),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: CountryMultiSelectField(
                  selectedCountries: _selectedCountries,
                  onSelectionChanged: (countries) => setState(() => _selectedCountries = countries),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep2Content() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _servicesController,
          label: 'Products / Services Offered',
          hint: 'List your key products or services, separated by commas...',
          maxLines: 4,
          validator: (val) => val?.isEmpty == true ? 'Services are required' : null,
        ),
        const SizedBox(height: 25),
        CustomTextFormField(
          controller: _descriptionController,
          label: 'Company Description',
          hint: 'Describe your company in a few sentences. This is crucial for generating relevant outreach messages.',
          maxLines: 5,
          validator: (val) => val?.isEmpty == true ? 'Description is required' : null,
        ),
      ],
    );
  }

  Widget _buildCompletionStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SuccessCheckmark(),
          const SizedBox(height: 30),
          Text(
            _submitSuccess ? 'Setup Complete!' : 'Setup Failed',
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _submitSuccess
                ? 'Your Chilbot AI agent is configured and ready. Let\'s find some leads.'
                : (_submitError ?? 'An error occurred. Please try again.'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 30),
          EnhancedElevatedButton(
            onPressed: _submitSuccess
                ? () => print("Navigate to Dashboard")
                : () {
                    // Retry submission
                    _collectAndSubmitData();
                  },
            icon: _submitSuccess ? Icons.bar_chart_rounded : Icons.refresh,
            label: _submitSuccess ? 'Go to Dashboard' : 'Retry',
          ),
        ],
      ),
    );
  }

  Widget _buildWizardNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderColor.withOpacity(0.5)),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppTheme.gradientStart.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            EnhancedTextButton(
              onPressed: _previousPage,
              icon: Icons.arrow_back,
              label: 'Back',
              isSecondary: true,
            )
          else
            const SizedBox(),
          EnhancedElevatedButton(
            onPressed: _nextPage,
            icon: _currentPage == AppConstants.totalFormSteps - 1 
                ? Icons.check_rounded 
                : Icons.arrow_forward,
            label: _currentPage == AppConstants.totalFormSteps - 1 ? 'Finish' : 'Next',
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }
}

// === CUSTOM WIDGETS ===

class FormStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String title;
  final String subtitle;
  final Widget child;

  const FormStep({
    super.key,
    required this.formKey,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 30),
            child,
          ],
        ),
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppTheme.textLight),
          decoration: _getInputDecoration(hint),
          validator: validator,
        ),
      ],
    );
  }
}

class IndustryDropdownField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const IndustryDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const Map<String, List<String>> _industries = {
    "Technology": [
      "SaaS (Software as a Service)",
      "AI / Machine Learning",
      "FinTech",
      "EdTech",
      "IT Services & Consulting",
      "Web Development & Design",
    ],
    "E-commerce & Retail": [
      "E-commerce (General)",
      "Fashion & Apparel",
      "Home Goods & Decor",
      "Electronics",
      "Beauty & Cosmetics",
    ],
    "Professional Services": [
      "Marketing & Advertising Agency",
      "Business Consulting",
      "Real Estate",
      "Legal Services",
      "Accounting & Financial Services",
    ],
    "Other": ["Other (Please specify in description)"]
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Industry / Niche',
          style: TextStyle(
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: const Text(
            'Select your industry...',
            style: TextStyle(color: Color(0xFF666666)),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textMuted),
          decoration: _getInputDecoration(''),
          dropdownColor: AppTheme.cardBg,
          style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
          validator: (val) => val == null ? 'Please select an industry' : null,
          onChanged: onChanged,
          items: _buildDropdownItems(),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems() {
    return _industries.entries.expand((entry) {
      final category = entry.key;
      final items = entry.value;
      return [
        DropdownMenuItem<String>(
          enabled: false,
          child: Text(
            category,
            style: const TextStyle(
              color: AppTheme.gradientEnd,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(value),
            ),
          );
        }),
      ];
    }).toList();
  }
}

class CountryMultiSelectField extends StatelessWidget {
  final List<String> selectedCountries;
  final ValueChanged<List<String>> onSelectionChanged;

  const CountryMultiSelectField({
    super.key,
    required this.selectedCountries,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CountryMultiSelect(
      selectedCountries: selectedCountries,
      onSelectionChanged: onSelectionChanged,
    );
  }
}

class EnhancedElevatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final IconAlignment iconAlignment;

  const EnhancedElevatedButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.iconAlignment = IconAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gradientEnd.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: AppTheme.textLight),
        label: Text(
          label,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
        iconAlignment: iconAlignment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
        ),
      ),
    );
  }
}

class EnhancedTextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isSecondary;

  const EnhancedTextButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppTheme.textMuted),
      label: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
      ),
    );
  }
}

// === EXISTING WIDGETS (CountryMultiSelect, SuccessCheckmark, etc.) ===
// Note: I'll include the existing CountryMultiSelect and SuccessCheckmark widgets
// with minor enhancements for consistency

class CountryMultiSelect extends StatefulWidget {
  final List<String> selectedCountries;
  final Function(List<String>) onSelectionChanged;
  
  const CountryMultiSelect({
    super.key,
    required this.selectedCountries,
    required this.onSelectionChanged,
  });

  @override
  State<CountryMultiSelect> createState() => _CountryMultiSelectState();
}

class _CountryMultiSelectState extends State<CountryMultiSelect> {
  static const List<String> _allCountries = [
    "Global", "Afghanistan", "Albania", "Algeria", "Andorra", "Angola",
    "Antigua and Barbuda", "Argentina", "Armenia", "Australia", "Austria",
    "Azerbaijan", "Bahamas", "Bahrain", "Bangladesh", "Barbados", "Belarus",
    "Belgium", "Belize", "Benin", "Bhutan", "Bolivia", "Bosnia and Herzegovina",
    "Botswana", "Brazil", "Brunei", "Bulgaria", "Burkina Faso", "Burundi",
    "Cabo Verde", "Cambodia", "Cameroon", "Canada", "Central African Republic",
    "Chad", "Chile", "China", "Colombia", "Comoros", "Congo, Democratic Republic of the",
    "Congo, Republic of the", "Costa Rica", "Cote d'Ivoire", "Croatia", "Cuba",
    "Cyprus", "Czech Republic", "Denmark", "Djibouti", "Dominica",
    "Dominican Republic", "Ecuador", "Egypt", "El Salvador", "Equatorial Guinea",
    "Eritrea", "Estonia", "Eswatini", "Ethiopia", "Fiji", "Finland", "France",
    "Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Greece", "Grenada",
    "Guatemala", "Guinea", "Guinea-Bissau", "Guyana", "Haiti", "Honduras",
    "Hungary", "Iceland", "India", "Indonesia", "Iran", "Iraq", "Ireland",
    "Israel", "Italy", "Jamaica", "Japan", "Jordan", "Kazakhstan", "Kenya",
    "Kiribati", "Korea, North", "Korea, South", "Kosovo", "Kuwait", "Kyrgyzstan",
    "Laos", "Latvia", "Lebanon", "Lesotho", "Liberia", "Libya", "Liechtenstein",
    "Lithuania", "Luxembourg", "Madagascar", "Malawi", "Malaysia", "Maldives",
    "Mali", "Malta", "Marshall Islands", "Mauritania", "Mauritius", "Mexico",
    "Micronesia", "Moldova", "Monaco", "Mongolia", "Montenegro", "Morocco",
    "Mozambique", "Myanmar", "Namibia", "Nauru", "Nepal", "Netherlands",
    "New Zealand", "Nicaragua", "Niger", "Nigeria", "North Macedonia", "Norway",
    "Oman", "Pakistan", "Palau", "Palestine", "Panama", "Papua New Guinea",
    "Paraguay", "Peru", "Philippines", "Poland", "Portugal", "Qatar", "Romania",
    "Russia", "Rwanda", "Saint Kitts and Nevis", "Saint Lucia",
    "Saint Vincent and the Grenadines", "Samoa", "San Marino",
    "Sao Tome and Principe", "Saudi Arabia", "Senegal", "Serbia", "Seychelles",
    "Sierra Leone", "Singapore", "Slovakia", "Slovenia", "Solomon Islands",
    "Somalia", "South Africa", "South Sudan", "Spain", "Sri Lanka", "Sudan",
    "Suriname", "Sweden", "Switzerland", "Syria", "Taiwan", "Tajikistan",
    "Tanzania", "Thailand", "Timor-Leste", "Togo", "Tonga", "Trinidad and Tobago",
    "Tunisia", "Turkey", "Turkmenistan", "Tuvalu", "Uganda", "Ukraine",
    "United Arab Emirates", "United Kingdom", "United States", "Uruguay",
    "Uzbekistan", "Vanuatu", "Vatican City", "Venezuela", "Vietnam", "Yemen",
    "Zambia", "Zimbabwe"
  ];

  void _showCountryPickerModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius)),
      ),
      builder: (context) {
        String searchQuery = '';
        List<String> filteredCountries = _allCountries
            .where((c) =>
                c.toLowerCase().contains(searchQuery.toLowerCase()) &&
                !widget.selectedCountries.contains(c))
            .toList();
        final TextEditingController searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            filteredCountries = _allCountries
                .where((c) =>
                    c.toLowerCase().contains(searchQuery.toLowerCase()) &&
                    !widget.selectedCountries.contains(c))
                .toList();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: searchController,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textLight),
                    decoration: const InputDecoration(
                      hintText: 'Type to search...',
                      hintStyle: TextStyle(color: Color(0xFF666666)),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius)),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) => setModalState(() => searchQuery = val),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filteredCountries.isEmpty
                        ? const Center(
                            child: Text('No matches', style: TextStyle(color: AppTheme.textMuted)),
                          )
                        : ListView.builder(
                            itemCount: filteredCountries.length,
                            itemBuilder: (context, index) {
                              final country = filteredCountries[index];
                              return ListTile(
                                title: Text(country, style: const TextStyle(color: AppTheme.textLight)),
                                onTap: () {
                                  final updated = List<String>.from(widget.selectedCountries)..add(country);
                                  widget.onSelectionChanged(updated);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _removeCountry(String country) {
    final updated = List<String>.from(widget.selectedCountries)..remove(country);
    widget.onSelectionChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selectedCountries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.selectedCountries.map((country) => Padding(
                  padding: const EdgeInsets.only(right: 6.0, bottom: 2.0),
                  child: Chip(
                    label: Text(country, style: const TextStyle(color: AppTheme.bgDark, fontWeight: FontWeight.bold)),
                    backgroundColor: AppTheme.gradientEnd,
                    deleteIcon: const Icon(Icons.close, size: 16, color: AppTheme.bgDark),
                    onDeleted: () => _removeCountry(country),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )).toList(),
              ),
            ),
          ),
        const Text(
          'Target Location',
          style: TextStyle(
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCountryPickerModal(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Row(
              children: [
                const Icon(Icons.public, color: AppTheme.textMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.selectedCountries.isEmpty
                        ? 'Select countries...'
                        : 'Add more countries',
                    style: TextStyle(
                      color: widget.selectedCountries.isEmpty
                          ? const Color(0xFF666666)
                          : AppTheme.textLight,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Type and select one or more countries. Tap × to remove.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        )
      ],
    );
  }
}

// Add this helper function at the bottom or near your theme section
InputDecoration _getInputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFF666666)),
    filled: true,
    fillColor: Colors.black.withOpacity(0.2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      borderSide: const BorderSide(color: AppTheme.borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      borderSide: const BorderSide(color: AppTheme.borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      borderSide: const BorderSide(color: AppTheme.gradientEnd, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
  );
}

// Add the SuccessCheckmark and CheckmarkPainter widgets if missing:
class SuccessCheckmark extends StatefulWidget {
  const SuccessCheckmark({super.key});

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: CheckmarkPainter(progress: _animation.value),
          );
        },
      ),
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  CheckmarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Phase 1: Draw circle (0.0 -> 0.4)
    final circleProgress = (t / 0.4).clamp(0.0, 1.0);
    final circlePaint = Paint()
      ..color = AppTheme.gradientEnd
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * circleProgress,
      false,
      circlePaint,
    );

    // Phase 2: Fill circle (0.4 -> 0.7)
    final fillProgress = ((t - 0.4) / 0.3).clamp(0.0, 1.0);
    final fillPaint = Paint()..color = AppTheme.gradientEnd.withOpacity(fillProgress);
    canvas.drawCircle(center, radius, fillPaint);

    // Phase 3: Draw checkmark (0.7 -> 1.0)
    final checkProgress = ((t - 0.7) / 0.3).clamp(0.0, 1.0);
    final checkPaint = Paint()
      ..color = AppTheme.textLight
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;

    final path = Path();
    path.moveTo(size.width * 0.27, size.height * 0.52);
    path.lineTo(size.width * 0.45, size.height * 0.70);
    path.lineTo(size.width * 0.73, size.height * 0.38);

    final pathMetric = path.computeMetrics().first;
    final extractPath = pathMetric.extractPath(0.0, pathMetric.length * checkProgress);

    canvas.drawPath(extractPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}