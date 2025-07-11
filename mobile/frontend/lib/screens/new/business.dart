import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessDetailScreen extends StatefulWidget {
  final Map<String, dynamic> business;

  const BusinessDetailScreen({
    super.key,
    required this.business,
  });

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _showContent = false;
  bool _isFavorite = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart));

    _startAnimations();
    _initUserAndFavorite();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _showContent = true);
    }
  }

  Future<void> _initUserAndFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _userId = user?.uid ?? "guest";
    });
    await _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    if (_userId == null) return;
    final favDoc = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(_userId)
        .collection('items')
        .doc(_favKey(widget.business))
        .get();
    setState(() {
      _isFavorite = favDoc.exists;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_userId == null) return;
    final favRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(_userId)
        .collection('items')
        .doc(_favKey(widget.business));
    if (_isFavorite) {
      await favRef.delete();
    } else {
      await favRef.set(widget.business);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  String _favKey(Map<String, dynamic> business) {
    return (business["website"] ?? business["name"] ?? "").toString().replaceAll(RegExp(r'[^\w]'), '_');
  }

  // --- WEBSITE SHORTENING ---
  String _shortWebsite(String url) {
    if (url.isEmpty) return "";
    try {
      Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url.length > 22 ? url.substring(0, 20) + "..." : url;
    }
  }

  Future<void> _launchWebsite(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

  Color _getMatchColor(int match) {
    if (match >= 90) return const Color(0xFF34D399);
    if (match >= 80) return const Color(0xFF10B981);
    if (match >= 70) return const Color(0xFFF59E0B);
    return const Color(0xFFF97316);
  }

  @override
  Widget build(BuildContext context) {
    final matchScore = (widget.business["match"] ?? 80) as int;
    final matchColor = _getMatchColor(matchScore);
    final scoreOutOf5 = (matchScore / 20).clamp(0, 5).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.white.withOpacity(0.9),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white.withOpacity(0.9),
            ),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? "Remove from Favorites" : "Add to Favorites",
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
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
          ),
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroSection(matchColor, scoreOutOf5),
                        const SizedBox(height: 24),
                        _buildAboutSection(),
                        const SizedBox(height: 24),
                        _buildContactInfo(),
                        const SizedBox(height: 24),
                        // Show extra info if available
                        if ((widget.business["prospects"] ?? 0) > 0)
                          _buildGlassContainer(
                            child: Row(
                              children: [
                                Icon(Icons.people, color: Colors.white.withOpacity(0.8)),
                                const SizedBox(width: 8),
                                Text(
                                  "Prospects: ${widget.business["prospects"]}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(Color matchColor, String scoreOutOf5) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: _showContent ? 1.0 : 0.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: _buildGlassContainer(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  // Company Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: matchColor.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        widget.business["logo"] ?? "",
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.domain,
                            color: Colors.white.withOpacity(0.6),
                            size: 48,
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Company Name
                  Text(
                    widget.business["name"] ?? "",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Sector Badge
                  if (widget.business["sector"] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: matchColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: matchColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.business["sector"],
                        style: TextStyle(
                          color: matchColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Match Score
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: matchColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: matchColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          scoreOutOf5,
                          style: TextStyle(
                            color: matchColor,
                            fontSize: 36,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Text(
                          "Match Score",
                          style: TextStyle(
                            color: matchColor.withOpacity(0.8),
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  
  Widget _buildAboutSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1600),
      tween: Tween(begin: 0.0, end: _showContent ? 1.0 : 0.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: _buildGlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "About Company",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.business["description"] ?? "No description available.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.6,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Website
                  if ((widget.business["website"] ?? "").isNotEmpty)
                    GestureDetector(
                      onTap: () => _launchWebsite(widget.business["website"]),
                      child: Row(
                        children: [
                          Icon(
                            Icons.language_outlined,
                            color: Colors.white.withOpacity(0.5),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _shortWebsite(widget.business["website"]),
                            style: TextStyle(
                              color: const Color(0xFF34D399),
                              fontSize: 14,
                              letterSpacing: 0.3,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactInfo() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween(begin: 0.0, end: _showContent ? 1.0 : 0.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: _buildGlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Contact Information",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Location
                  if ((widget.business["location"] ?? "").isNotEmpty)
                    _buildContactItem(Icons.location_on_outlined, widget.business["location"]),
                  // Phone
                  if ((widget.business["phone"] ?? "").isNotEmpty)
                    _buildContactItem(Icons.phone_outlined, widget.business["phone"]),
                  // Email
                  if ((widget.business["email"] ?? "").isNotEmpty)
                    _buildContactItem(Icons.email_outlined, widget.business["email"]),
                  // Sector
                  if ((widget.business["sector"] ?? "").isNotEmpty)
                    _buildContactItem(Icons.business_outlined, widget.business["sector"]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchFactor(String factor, double percentage, Color matchColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              factor,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              "${(percentage * 100).toInt()}%",
              style: TextStyle(
                color: matchColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(matchColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.5),
          size: 16,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryButton(IconData icon, String label, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: _buildGlassContainer(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          icon: Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 18,
          ),
          label: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}