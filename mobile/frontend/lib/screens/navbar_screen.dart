import 'package:flutter/material.dart';
import 'package:frontend/screens/map_screen.dart';
import 'Chat_screen/chat_screen.dart';
import 'Profile_screen/profile_screen.dart';
import 'new/new_lead_step1.dart';
import 'dart:ui';
import 'new/compaign_list.dart';

class NavBarScreen extends StatefulWidget {
  const NavBarScreen({Key? key}) : super(key: key);

  @override
  _NavBarScreenState createState() => _NavBarScreenState();
}

class _NavBarScreenState extends State<NavBarScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  final List<Widget> _pages = [
    // const EnhancedMapScreen(),
    // const ChatScreen(),
    const CampaignsPage(), // Assuming this is the campaign list screen
    const ProfileScreen(),
    const NewLeadStep1(), // Assuming this is a new lead creation screen
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    bool isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _animationController.reset();
        _animationController.forward();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : 1.0,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isSelected ? _pulseAnimation.value : 1.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        padding: const EdgeInsets.all(8), // smaller icon padding
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.22),
                                    Colors.white.withOpacity(0.09),
                                    const Color(0xFF10B981).withOpacity(0.12), // emerald green
                                    Colors.blue.withOpacity(0.12),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.08),
                                    Colors.white.withOpacity(0.03),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(14), // smaller radius
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withOpacity(0.22)
                                : Colors.white.withOpacity(0.08),
                            width: 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.18), // emerald green
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 3),
                                  ),
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.07),
                                    blurRadius: 7,
                                    spreadRadius: 0.5,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Icon(
                          icon,
                          color: isSelected 
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 22, // smaller icon
                        ),
                      ),
                      const SizedBox(height: 3), // less space
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white
                              : Colors.grey.shade500,
                          fontSize: isSelected ? 12 : 11, // smaller font
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          letterSpacing: 0.4,
                        ),
                        child: Text(label),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12), // smaller margin
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18), // smaller radius
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // less padding
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.18),
                    Colors.white.withOpacity(0.08),
                    const Color(0xFF10B981).withOpacity(0.05), // emerald green accent
                    Colors.blue.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    spreadRadius: 0,
                    offset: const Offset(0, 7),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.08),
                    blurRadius: 0,
                    spreadRadius: 0,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [    
                  _buildNavItem(Icons.list_rounded, 0, 'Campaigns'),
                  _buildNavItem(Icons.person_rounded, 1, 'Profile'),
                  _buildNavItem(Icons.add_circle_outline_rounded, 2, 'New Lead'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}