import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';

class AIScanningScreen extends StatefulWidget {
  const AIScanningScreen({super.key});

  @override
  State<AIScanningScreen> createState() => _AIScanningScreenState();
}

class _AIScanningScreenState extends State<AIScanningScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> companies = [
    {"name": "Tech Innovators Inc.", "logo": "assets/logo1.png", "relevance": 3},
    {"name": "Global Solutions Ltd.", "logo": "assets/logo2.png", "relevance": 4},
    {"name": "Future Dynamics Corp.", "logo": "assets/logo3.png", "relevance": 2},
    {"name": "Digital Ventures LLC", "logo": "assets/logo4.png", "relevance": 5},
    {"name": "Smart Systems Co.", "logo": "assets/logo5.png", "relevance": 3},
  ];

  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  final List<bool> _visible = [];
  bool _scanningComplete = false;
  int _currentProgress = 0;

  @override
  void initState() {
    super.initState();
    _visible.addAll(List.filled(companies.length, false));
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );

    _startScanningSequence();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startScanningSequence() async {
    // Start fade in animation
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Start pulsing animation
    _pulseController.repeat(reverse: true);
    
    // Start progress animation
    _progressController.forward();
    
    // Listen to progress changes
    _progressController.addListener(() {
      final newProgress = (_progressAnimation.value * 100).round();
      if (newProgress != _currentProgress) {
        setState(() => _currentProgress = newProgress);
      }
      
      // Start revealing companies at different progress points with staggered timing
      if (_progressAnimation.value >= 0.25 && !_visible[0]) {
        _revealCompany(0);
      } else if (_progressAnimation.value >= 0.4 && companies.length > 1 && !_visible[1]) {
        _revealCompany(1);
      } else if (_progressAnimation.value >= 0.6 && companies.length > 2 && !_visible[2]) {
        _revealCompany(2);
      } else if (_progressAnimation.value >= 0.8 && companies.length > 3 && !_visible[3]) {
        _revealCompany(3);
      } else if (_progressAnimation.value >= 0.95 && companies.length > 4 && !_visible[4]) {
        _revealCompany(4);
      }
    });

    // Complete scanning when animation finishes
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _scanningComplete = true);
        _pulseController.stop();
      }
    });
  }

  void _revealCompany(int index) async {
    if (index < _visible.length) {
      await Future.delayed(Duration(milliseconds: index * 200));
      if (mounted) {
        setState(() => _visible[index] = true);
      }
    }
  }

  String get _scanningStatus {
    if (_scanningComplete) return "Analysis Complete";
    if (_currentProgress < 25) return "Initializing Neural Networks...";
    if (_currentProgress < 50) return "Scanning Market Intelligence...";
    if (_currentProgress < 75) return "Processing Business Patterns...";
    if (_currentProgress < 95) return "Validating Opportunities...";
    return "Finalizing Results...";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.white.withOpacity(0.9),
        ),
        centerTitle: true,
        title: Text(
          "AI Business Scanner",
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 120, 24, 32),
                children: [
                  // Scanning Header
                  _buildScanningHeader(),
                  const SizedBox(height: 40),
                  
                  // AI Animation
                  _buildAIAnimation(),
                  const SizedBox(height: 40),
                  
                  // Companies Section
                  _buildCompaniesSection(),
                  const SizedBox(height: 40),
                  
                  // Metrics Section (now includes Continue button)
                  _buildMetricsSection(),
                  const SizedBox(height: 32),
                ],
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

  Widget _buildScanningHeader() {
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
                  // color: (_scanningComplete ? Colors.teal : Colors.cyan).withOpacity(0.2),
                  color: (_scanningComplete
                          ? const Color(0xFF34D399)
                          : const Color(0xFF10B981))
                      .withOpacity(0.18), // emerald glassy
                ),
                child: Icon(
                  _scanningComplete ? Icons.check_circle_outline : Icons.auto_awesome,
                  // color: _scanningComplete ? Colors.teal : Colors.cyan,
                  color: _scanningComplete
                      ? const Color(0xFF34D399)
                      : const Color(0xFF10B981), // emerald
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Neural Analysis",
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
            _scanningStatus,
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
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _scanningComplete 
                        // ? Colors.teal.withOpacity(0.8)
                        // : Colors.cyan.withOpacity(0.8),
                        ? const Color(0xFF34D399).withOpacity(0.8)
                        : const Color(0xFF10B981).withOpacity(0.8), // emerald
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Text(
                "$_currentProgress%",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnimation() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scanningComplete ? 1.0 : _pulseAnimation.value,
            child: Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    // (_scanningComplete ? Colors.teal : Colors.cyan).withOpacity(0.1),
                    (_scanningComplete
                        ? const Color(0xFF34D399)
                        : const Color(0xFF10B981))
                        .withOpacity(0.13), // emerald glassy
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  // color: (_scanningComplete ? Colors.teal : Colors.cyan).withOpacity(0.3),
                  color: (_scanningComplete
                      ? const Color(0xFF34D399)
                      : const Color(0xFF10B981)).withOpacity(0.25), // emerald
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(80),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SizedBox(
                        height: 100,
                        child: Lottie.asset(
                          'assets/animation/ai_scan.json',
                          repeat: !_scanningComplete,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompaniesSection() {
    final visibleCompanies = companies.asMap().entries
        .where((entry) => entry.key < _visible.length && _visible[entry.key])
        .toList();

    if (visibleCompanies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.business_center_outlined,
                color: Colors.white.withOpacity(0.8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Discovered Prospects",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  // color: Colors.cyan.withOpacity(0.2),
                  color: const Color(0xFF34D399).withOpacity(0.18), // emerald glassy
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${visibleCompanies.length} found",
                  style: TextStyle(
                    // color: Colors.cyan.withOpacity(0.9),
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
        ...visibleCompanies.map((entry) {
          final index = entry.key;
          final company = entry.value;
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 800 + (index * 100)),
            tween: Tween(begin: 0.0, end: _visible[index] ? 1.0 : 0.0),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: _buildCompanyCard(
                    company["name"],
                    company["logo"],
                    company["relevance"],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCompanyCard(String name, String logo, int relevance) {
    return _buildGlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      opacity: 0.06,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                logo,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.domain,
                    color: Colors.white.withOpacity(0.6),
                    size: 24,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < relevance ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber.withOpacity(0.8),
                        size: 14,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      "$relevance.0 relevance",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withOpacity(0.4),
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    if (!_scanningComplete) return const SizedBox.shrink();

    final totalScans = 1247;
    final leadsFound = companies.length;
    final avgRelevance = companies.fold(0, (sum, company) => sum + (company["relevance"] as int)) / companies.length;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
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
                        Icons.analytics_outlined,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Analysis Metrics",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildMetricCard("Total Scans", totalScans.toString())),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricCard("Prospects", leadsFound.toString())),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMetricCard(
                  "Quality Score",
                  "${avgRelevance.toStringAsFixed(1)}/5.0",
                  isFullWidth: true,
                ),
                const SizedBox(height: 24),
                // Continue button fades in with metrics
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
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
                  Navigator.of(context).pushNamed('/matches');
                },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Continue",
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, {bool isFullWidth = false}) {
    return _buildGlassContainer(
      padding: const EdgeInsets.all(20),
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 20,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}