import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/drive.dart';
import '../follow_list_screen.dart';
import '../notification_screen/notification_screen.dart';
import '../payment/payment_selection_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;
  final GoogleDriveService _driveService = GoogleDriveService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isUploading = false;
  bool _isEditingAbout = false;
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Enhanced color scheme
  static const Color primaryGray = Color(0xFF424242);
  static const Color accentGray = Color(0xFF757575);
  static const Color lightGray = Color(0xFF9E9E9E);
  static const Color surfaceGray = Color(0xFFF5F5F5);
  static const Color cardGray = Color(0xFFFAFAFA);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _aboutController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Widget _buildStatItem(String title, String count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryGray,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: lightGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    required IconData icon,
    Color? backgroundColor,
    List<Color>? gradientColors,
    double? fontSize, // <-- add this
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradientColors != null 
          ? LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : backgroundColor == null 
            ? LinearGradient(
                colors: [accentGray, primaryGray],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? gradientColors?.first ?? accentGray).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: fontSize ?? 14, // <-- use fontSize if provided
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final file = File(image.path);
        final imageUrl = await _driveService.uploadFile(file);

        await FirebaseAuth.instance.currentUser?.updatePhotoURL(imageUrl);
        await firestore.collection('users').doc(user?.uid).update({
          'photoURL': imageUrl,
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile picture: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'isConnected': false,
          'lastSignIn': DateTime.now(),
        });
      }

      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      await prefs.setBool('isLoggedIn', false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Logout Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showAddFundsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Changed from green to gray
                  Icon(Icons.add_circle, color: accentGray, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Funds',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryGray,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (DZD)',
                  // Changed from green to gray
                  prefixIcon: Icon(Icons.attach_money, color: accentGray),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    // Changed from green to gray
                    borderSide: BorderSide(color: accentGray, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: GoogleFonts.inter(fontSize: 16),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: lightGray),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildGradientButton(
                      // Add space before "Continue" if missing
                      text: "Continue",
                      icon: Icons.payment,
                      // Changed from green to gray
                      gradientColors: [accentGray, primaryGray],
                      onPressed: () {
                        final amount = double.tryParse(_amountController.text);
                        if (amount != null && amount > 0) {
                          Navigator.of(context).pop();
                          showPaymentDialog(
                            context,
                            amount: amount,
                            purpose: 'add_funds',
                          );
                          _amountController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter a valid amount'),
                              // Changed from orange to gray
                              backgroundColor: accentGray,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      // Add this parameter to override the font size for "Continue"
                      // (You need to update _buildGradientButton to accept this parameter)
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionHistoryScreen(userId: user?.uid ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceGray,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 0, bottom: 16, right: 0, top: 0),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      "Profile",
                      style: GoogleFonts.inter(
                        color: primaryGray,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.notifications_outlined, color: primaryGray, size: 22),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NotificationScreen()),
                            );
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.logout, color: primaryGray, size: 22),
                          onPressed: handleLogout,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              centerTitle: false,
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: StreamBuilder<DocumentSnapshot>(
                stream: firestore.collection('users').doc(user?.uid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(accentGray),
                        ),
                      ),
                    );
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  final interests = (userData['interests'] as List<dynamic>?) ?? [];
                  final aboutMe = userData['aboutMe'] as String? ?? "Tell the world about yourself...";
                  final followers = (userData['followers'] as List<dynamic>?)?.length ?? 0;
                  final following = (userData['following'] as List<dynamic>?)?.length ?? 0;
                  final walletBalance = (userData['wallet_balance'] as num?)?.toDouble() ?? 0.0;

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Enhanced Profile Header Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              children: [
                                // Enhanced Avatar Section
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 65,
                                        backgroundColor: Colors.grey[200],
                                        backgroundImage: user?.photoURL != null 
                                          ? NetworkImage(user!.photoURL!) 
                                          : null,
                                        child: _isUploading 
                                          ? CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(accentGray),
                                            )
                                          : user?.photoURL == null 
                                            ? Icon(Icons.person, size: 50, color: lightGray)
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: _updateProfilePicture,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: primaryGray,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                
                                // Enhanced Name
                                Text(
                                  user?.displayName ?? 'User Name',
                                  style: GoogleFonts.inter(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGray,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                
                                // Email
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    user?.email ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: lightGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Enhanced Stats Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(
                                        "Followers", 
                                        followers.toString(),
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FollowListScreen(
                                              userId: user?.uid ?? '',
                                              isFollowers: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatItem(
                                        "Following", 
                                        following.toString(),
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FollowListScreen(
                                              userId: user?.uid ?? '',
                                              isFollowers: false,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Enhanced Wallet Card with More Features
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey[50]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        // Changed from green to gray
                                        color: accentGray.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.account_balance_wallet, color: accentGray, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Wallet Balance",
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: lightGray,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: _showTransactionHistory,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.history, size: 16, color: accentGray),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        "History",
                                                        style: GoogleFonts.inter(
                                                          fontSize: 12,
                                                          color: accentGray,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${walletBalance.toStringAsFixed(2)} DZD",
                                            style: GoogleFonts.inter(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: primaryGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildGradientButton(
                                        text: "Add Funds",
                                        icon: Icons.add,
                                        // Changed from green to gray
                                        gradientColors: [accentGray, primaryGray],
                                        onPressed: _showAddFundsDialog,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),    
                        // Enhanced About Me Section
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "About Me",
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryGray,
                                      ),
                                    ),
                                    if (!_isEditingAbout)
                                      GestureDetector(
                                        onTap: () => setState(() => _isEditingAbout = true),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.edit_outlined, color: accentGray, size: 18),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_isEditingAbout) ...[
                                  TextField(
                                    controller: _aboutController..text = aboutMe,
                                    decoration: InputDecoration(
                                      hintText: "Tell us about yourself...",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: accentGray, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    maxLines: 4,
                                    style: GoogleFonts.inter(fontSize: 15),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => setState(() => _isEditingAbout = false),
                                        child: Text("Cancel", style: GoogleFonts.inter(color: lightGray)),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildGradientButton(
                                        text: "Save",
                                        icon: Icons.check,
                                        onPressed: () async {
                                          await firestore.collection('users').doc(user?.uid).update({
                                            'aboutMe': _aboutController.text,
                                          });
                                          setState(() => _isEditingAbout = false);
                                        },
                                      ),
                                    ],
                                  ),
                                ] else
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cardGray,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Text(
                                      aboutMe,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: Colors.grey[700],
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40), // Bottom padding
                      ],
                    ),);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Transaction History Screen
class TransactionHistoryScreen extends StatelessWidget {
  final String userId;

  const TransactionHistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!.docs;

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index].data() as Map<String, dynamic>;
              final amount = transaction['amount']?.toDouble() ?? 0.0;
              final type = transaction['type'] ?? '';
              final timestamp = transaction['timestamp'] as Timestamp?;
              final paymentMethod = transaction['paymentMethod'] ?? '';
              final status = transaction['status'] ?? '';

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: type == 'add_funds'
                              ? Colors.green[50]
                              : Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          type == 'add_funds'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: type == 'add_funds'
                              ? Colors.green
                              : Colors.blue,
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type == 'add_funds'
                                  ? 'Funds Added'
                                  : 'Transfer',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              paymentMethod.isNotEmpty
                                  ? 'via $paymentMethod'
                                  : '',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              timestamp != null
                                  ? DateTime.fromMillisecondsSinceEpoch(
                                          timestamp.millisecondsSinceEpoch)
                                      .toLocal()
                                      .toString()
                                  : '',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            (type == 'add_funds' ? '+' : '-') +
                                '${amount.toStringAsFixed(2)} DZD',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: type == 'add_funds'
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'success'
                                  ? Colors.green[100]
                                  : status == 'pending'
                                      ? Colors.orange[100]
                                      : Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status[0].toUpperCase() +
                                  status.substring(1),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: status == 'success'
                                    ? Colors.green
                                    : status == 'pending'
                                        ? Colors.orange
                                        : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}