import 'package:flutter/material.dart';
import 'dart:ui';

class NewLeadStep1 extends StatefulWidget {
  const NewLeadStep1({super.key});

  @override
  State<NewLeadStep1> createState() => _NewLeadStep1State();
}

class _NewLeadStep1State extends State<NewLeadStep1>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  
  bool _hasUploadedDocs = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _startAnimations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _productController.dispose();
    _industryController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: Colors.white.withOpacity(0.9),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "New Lead",
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontWeight: FontWeight.w300,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 120, 24, 32),
                  children: [
                    // Progress Header
                    _buildProgressHeader(),
                    const SizedBox(height: 40),
                    
                    // Form Fields
                    _buildFormSection(),
                    const SizedBox(height: 32),
                    
                    // Documents Section
                    _buildDocumentsSection(),
                    const SizedBox(height: 40),
                    
                    // Create Lead Button
                    _buildCreateButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? opacity,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity ?? 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:Color(0xFF34D399).withOpacity(0.2),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF34D399),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Lead Information",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Step 1 of 3 - Basic Details",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 24),
          
          // Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.white.withOpacity(0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: 0.33,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF34D399).withOpacity(0.8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "33%",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildInputCard(
                  title: "Product/Service Name",
                  subtitle: "Enter the name of the product or service you offer",
                  controller: _productController,
                  icon: Icons.widgets_outlined,
                  assetPath: 'assets/images/p1.png',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 700),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildInputCard(
                  title: "Target Industries",
                  subtitle: "Specify the industries you are targeting",
                  controller: _industryController,
                  icon: Icons.group_outlined,
                  assetPath: 'assets/images/p2.png',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildInputCard(
                  title: "Value Proposition",
                  subtitle: "Describe the unique value your product or service offers",
                  controller: _valueController,
                  icon: Icons.lightbulb_outline,
                  assetPath: 'assets/images/p3.png',
                  isMultiline: true,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInputCard({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required IconData icon,
    required String assetPath,
    bool isMultiline = false,
  }) {
    return _buildGlassContainer(
      padding: EdgeInsets.zero,
      opacity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large image taking 70% of the card height
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  height: 180, // 70% of total card height
                  width: double.infinity,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white.withOpacity(0.1),
                        child: Icon(
                          icon,
                          color: Colors.white.withOpacity(0.6),
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Gradient overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Title and subtitle overlaid on image
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        shadows: const [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Input field in the remaining 30%
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: isMultiline ? 3 : 1,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: "Enter ${title.toLowerCase()}...",
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    icon,
                    color: Colors.white.withOpacity(0.5),
                    size: 18,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Supporting Documents",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      if (_hasUploadedDocs)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            // color: Colors.teal.withOpacity(0.2),
                            color: const Color(0xFF34D399).withOpacity(0.18), // emerald glassy
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Uploaded",
                            style: TextStyle(
                              // color: Colors.teal.withOpacity(0.9),
                              color: const Color(0xFF10B981).withOpacity(0.9), // emerald
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildGlassContainer(
                  opacity: 0.05,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() => _hasUploadedDocs = true);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              // color: Colors.cyan.withOpacity(0.3),
                              color: const Color(0xFF34D399).withOpacity(0.3), // emerald
                              width: 1,
                            ),
                            // color: Colors.cyan.withOpacity(0.05),
                            color: const Color(0xFF34D399).withOpacity(0.07), // emerald glassy
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                // color: Colors.cyan.withOpacity(0.8),
                                color: const Color(0xFF10B981).withOpacity(0.8), // emerald
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Upload Documents",
                                style: TextStyle(
                                  // color: Colors.cyan.withOpacity(0.9),
                                  color: const Color(0xFF10B981).withOpacity(0.9), // emerald
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "PDFs, presentations, brochures",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_hasUploadedDocs) ...[
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "View Extracted Data",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white.withOpacity(0.4),
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF43EA5B), // bright green
                    Color(0xFF1DB954), // spotify green
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF43EA5B).withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/ai_scanning');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  "Create Lead",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
        },
    );
  }
}