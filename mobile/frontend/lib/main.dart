import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // Required for BackdropFilter (ImageFiltered)

import 'auth/login_screen.dart';
import 'auth/forgot_password_screen.dart';
import 'screens/navbar_screen.dart';
import 'screens/fill_profile_screen.dart';
import 'screens/new/ai_scanning_screen.dart';
import 'auth/new_lead_step1.dart';
import 'screens/new/matches.dart';

// Landing Page Components (from your landing page code)
class AppColors {
  static const Color bgLight = Color(0xFFEBE6DC);
  static const Color bgDark = Color(0xFF131414);
  static const Color textDark = Color(0xFF131414);
  static const Color textLight = Color(0xFFF5F4F0);
  static const Color greenAccent = Color(0xFF79B266);
  static const Color greenDark = Color(0xFF2E402B);
  static const Color premiumTopRight = Color(0xFF3F5230);
  static const Color premiumBottomRight = Color(0xFFBEB881);
  static const Color premiumLeft = Color(0xFF1D221C);
  static const Color premiumMiddle = Color(0xFF3B5428);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<String> _determineInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final user = FirebaseAuth.instance.currentUser;

  // Show landing page on first launch
  if (isFirstLaunch) {
    return '/landing';
  }

  if (isLoggedIn && user != null) {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data()?['isFirst'] == false) {
        return '/navbar';
      } else {
        return '/lead';
      }
    } catch (e) {
      return '/navbar';
    }
  }
  return '/login';
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    print('Initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ncs',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<String>(
        future: _determineInitialRoute(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final route = snapshot.data ?? '/login';
          return _buildScreenForRoute(route);
        },
      ),
      routes: {
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/navbar': (context) => const NavBarScreen(),
        '/fill-profile': (context) => const FillProfileScreen(),
        '/ai_scanning': (context) => const AIScanningScreen(),
        '/lead': (context) => const AccountSetupScreen(),
        '/matches': (context) => const MatchesScreen(matches: []),
      },
    );
  }

  Widget _buildScreenForRoute(String route) {
    switch (route) {
      case '/landing':
        return const LandingScreen();
      case '/navbar':
        return const NavBarScreen();
      case '/fill-profile':
        return const FillProfileScreen();
      case '/lead':
        return const AccountSetupScreen();
      case '/matches':
        return const MatchesScreen(matches: []);
      default:
        return const LoginScreen();
    }
  }
}

// Landing Screen - Only shown on first app launch
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<void> _completeLanding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
    
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gemsell',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgDark,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: AppColors.textDark,
          displayColor: AppColors.textDark,
        ),
      ),
      home: LandingHomeScreen(onGetStarted: () => _completeLanding(context)),
    );
  }
}

class LandingHomeScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  
  const LandingHomeScreen({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No drawer here, so no sandwich button
      body: CustomScrollView(
        slivers: [
          const GlassyAppBar(),
          HeroSection(onGetStarted: onGetStarted),
          const ProductsSection(),
          const PricingSection(),
          const TestimonialsSection(),
          FinalCtaSection(onGetStarted: onGetStarted),
          const FooterSection(),
        ],
      ),
    );
  }
}

// Modified Hero Section with callback
class HeroSection extends StatelessWidget {
  final VoidCallback onGetStarted;
  
  const HeroSection({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppColors.bgDark,
          gradient: RadialGradient(
            center: Alignment(0.5, -0.3),
            radius: 0.8,
            colors: [Color(0x7F789D6E), AppColors.bgDark],
            stops: [0.0, 0.6],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                    height: 1.1,
                  ),
                  children: const [
                    TextSpan(text: 'Have a Service?'),
                    TextSpan(text: 'AI '),
                    TextSpan(
                      text: 'Finds & Closes',
                      style: TextStyle(
                          color: AppColors.greenAccent,
                          fontStyle: FontStyle.italic),
                    ),
                    TextSpan(text: '\nYour Deals'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textLight.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: const Text(
                  '⭐ 4.3/5 Rating / 3.5M+ Installs',
                  style: TextStyle(color: AppColors.textLight),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenAccent,
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  "Get Started",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modified Final CTA Section with callback
class FinalCtaSection extends StatelessWidget {
  final VoidCallback onGetStarted;
  
  const FinalCtaSection({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.bgLight,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
        child: Column(
          children: [
            const Text('Get started'),
            const SizedBox(height: 16),
            const Text(
              'Start your journey\nwith our app',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 40, fontWeight: FontWeight.w600, height: 1.2),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenAccent,
                foregroundColor: AppColors.textDark,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                "Get Started",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep all other components from the landing page (GlassyAppBar, ProductsSection, etc.)
class GlassyAppBar extends StatelessWidget {
  const GlassyAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0x4D131414),
      pinned: true,
      floating: true,
      elevation: 0,
      automaticallyImplyLeading: false, // No sandwich button
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo2.png',
            height: 32,
          ),
          const SizedBox(width: 12),
          Text(
            'Gemsell',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }
}

class ProductsSection extends StatelessWidget {
  const ProductsSection({super.key});

  static const List<Map<String, dynamic>> products = [
    {
      'icon': Icons.search,
      'title': 'Lead Finder',
      'subtitle': 'AI-powered search for high-potential customers who need your product most.',
      'number': '01'
    },
    {
      'icon': Icons.record_voice_over,
      'title': 'AI Advanced Voice',
      'subtitle': 'Natural, real-time streaming AI agent that interacts and negotiates with businesses—closing deals for you.',
      'number': '02'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.bgLight,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Our products', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              '2 tools — one platform',
              textAlign: TextAlign.left,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
            ...products.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: ProductCard(
                icon: product['icon'],
                title: product['title'],
                subtitle: product['subtitle'],
                number: product['number'],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String number;

  const ProductCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.greenAccent.withOpacity(0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: AppColors.greenDark, size: 32),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[ $number ]',
                  style: const TextStyle(
                    color: Colors.black38,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.black54,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PricingSection extends StatelessWidget {
  const PricingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.bgDark,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
        child: Column(
          children: [
            const Text('Pricing', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                  height: 1.2,
                ),
                children: const [
                  TextSpan(text: 'Choose your\n'),
                  TextSpan(
                    text: 'Plan',
                    style: TextStyle(color: AppColors.greenAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const PriceCard(isPremium: false),
            const SizedBox(height: 24),
            const PriceCard(isPremium: true),
          ],
        ),
      ),
    );
  }
}

class PriceCard extends StatelessWidget {
  final bool isPremium;
  const PriceCard({super.key, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final freeFeatures = [
      'Basic features included',
      'Standard support',
      'Limited usage',
    ];
    final premiumFeatures = [
      'All features unlocked',
      'Priority support',
      'Unlimited usage',
    ];

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: isPremium ? null : Border.all(color: const Color(0xFF282828)),
        gradient: isPremium
            ? const LinearGradient(
                colors: [AppColors.premiumLeft, AppColors.premiumMiddle],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              )
            : null,
        color: isPremium ? null : const Color(0xFF181818),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPremium)
            const Align(
              alignment: Alignment.topRight,
              child: Icon(Icons.diamond_outlined,
                  color: AppColors.premiumBottomRight, size: 40),
            ),
          Text(
            isPremium ? 'Premium' : 'Free',
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPremium ? '30-day money-back guarantee' : 'No credit card required',
            style: const TextStyle(
                color: Color(0xFFB4CC5B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: AppColors.textLight),
              children: [
                TextSpan(
                  text: isPremium ? '\$9.99' : '\$0',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w600),
                ),
                const TextSpan(
                  text: ' USD / per month',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor:
                  isPremium ? const Color(0xFFB3D0AB) : const Color(0xFF1F1F1F),
              foregroundColor:
                  isPremium ? AppColors.greenDark : AppColors.textLight,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: isPremium ? null : const BorderSide(color: Color(0xFF333333)),
            ),
            child: Text(
              isPremium ? 'Upgrade to premium' : 'Get started free',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPremium
                ? 'Get access to all premium features'
                : 'Perfect for getting started',
            style: const TextStyle(color: Color(0xFFBDBDBD), height: 1.5),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(color: Colors.white12),
          ),
          Text(
            isPremium ? 'Everything in Free, plus:' : "What's included:",
            style: const TextStyle(
                color: Color(0xFFE0E0E0), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          ...List.generate((isPremium ? premiumFeatures : freeFeatures).length,
              (index) {
            final features = isPremium ? premiumFeatures : freeFeatures;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Color(0xFFB4CC5B), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(features[index],
                        style: const TextStyle(color: Color(0xFFD0D0D0))),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.bgLight,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
        child: Column(
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark),
                children: const [
                  TextSpan(text: 'What users '),
                  TextSpan(
                    text: 'say',
                    style: TextStyle(
                        color: Color(0xFF5A7C50), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const TestimonialCard(
              text: "This app has completely transformed how I work. The features are intuitive and powerful.",
              author: 'Sarah Johnson',
              title: 'Product Manager',
              imageUrl: 'https://i.pravatar.cc/80?u=sarah',
            ),
            const SizedBox(height: 20),
            const TestimonialCard(
              text: "Amazing experience! The support team is responsive and the app keeps getting better.",
              author: 'Mike Chen',
              title: 'Developer',
              imageUrl: 'https://i.pravatar.cc/80?u=mike',
            ),
          ],
        ),
      ),
    );
  }
}

class TestimonialCard extends StatelessWidget {
  final String text, author, title, imageUrl;
  const TestimonialCard(
      {super.key,
      required this.text,
      required this.author,
      required this.title,
      required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"$text"', style: const TextStyle(height: 1.6)),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(imageUrl),
                radius: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(title, style: const TextStyle(color: Colors.black54)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.bgLight,
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Gemsell',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 30),
            const Text('Copyright © 2024, Your Company Inc.'),
            const SizedBox(height: 10),
            const Text('support@gemsell.com',
                style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bgDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.greenDark),
            child: Text(
              'Menu',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDrawerItem(context, 'Features'),
          _buildDrawerItem(context, 'Pricing'),
          _buildDrawerItem(context, 'About'),
          _buildDrawerItem(context, 'Contact'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textLight),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}

// Keep your existing MyHomePage class unchanged
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}