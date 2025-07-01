import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // <-- Add this import
import '../../services/drive.dart';
import '../follow_list_screen.dart';
import '../notification_screen/notification_screen.dart';
import '../payment/payment_selection_dialog.dart';
import '../new/compaign_list.dart'; // Import for DashboardPage and AppColors

// Importing necessary components from compaign_list.dart for consistent styling
// This assumes AppColors, _DashCard, _StatusPill, _SidebarOptionButton, _ProfessionalLineChart, _FavoriteBusinessCard
// and DashboardPage are all defined within your compaign_list.dart file.

// Transaction History Screen - Moved here for completeness, styled with AppColors
class TransactionHistoryScreen extends StatelessWidget {
  final String userId;

  const TransactionHistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark, // Compaign background
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: GoogleFonts.inter(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenAccent), // Compaign accent color
              ),
            );
          }

          final transactions = snapshot.data!.docs;

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppColors.textMuted.withOpacity(0.6)), // Muted icon
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet.',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: AppColors.textMuted, // Muted text
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index].data() as Map<String, dynamic>;
              final amount = transaction['amount']?.toDouble() ?? 0.0;
              final type = transaction['type'] ?? '';
              final timestamp = transaction['timestamp'] as Timestamp?;
              final paymentMethod = transaction['paymentMethod'] ?? '';
              final status = transaction['status'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0, // Flat design
                color: AppColors.cardBg, // Compaign card background
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: type == 'add_funds'
                              ? AppColors.greenAccent.withOpacity(0.1) // Subtle accent background
                              : AppColors.textMuted.withOpacity(0.1), // Muted background
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          type == 'add_funds'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: type == 'add_funds'
                              ? AppColors.greenAccent // Accent color for income
                              : AppColors.textMuted, // Muted color for outcome
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 18),
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
                                color: AppColors.textLight, // Light text for main info
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (paymentMethod.isNotEmpty)
                              Text(
                                'via $paymentMethod',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textMuted, // Muted text
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              timestamp != null
                                  ? DateTime.fromMillisecondsSinceEpoch(
                                          timestamp.millisecondsSinceEpoch)
                                      .toLocal()
                                      .toString()
                                  : '',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textMuted.withOpacity(0.5), // Even more muted for timestamp
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
                                  ? AppColors.greenAccent
                                  : AppColors.textLight, // Accent for income, light for outcome
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Use _StatusPill for consistency
                          StatusPill(
                            status[0].toUpperCase() + status.substring(1),
                            isSuccess: status == 'success',
                            isTablet: MediaQuery.of(context).size.width > 600, // Pass isTablet for responsive pill size
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
  // Removed _isEditingAbout and _aboutController as they were not fully implemented in original snippet.
  final TextEditingController _amountController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    _amountController.dispose();
    super.dispose();
  }

  // Adjusted to resemble _buildStatCard from DashboardPage
  Widget _buildWalletBalanceCard(String title, String count, {VoidCallback? onTap, bool isTablet = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg, // Compaign card background
          borderRadius: BorderRadius.circular(12),
          // Subtle shadow to match dashboard cards
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 14 : 12,
                color: AppColors.textMuted, // Muted text
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 32 : 28,
                fontWeight: FontWeight.w600,
                color: AppColors.greenAccent, // Highlight with accent color
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Re-designed button to match Compaign style
  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required IconData icon,
    bool isPrimary = true, // To distinguish between primary (filled) and secondary (outlined)
  }) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;
    return SizedBox(
      width: double.infinity,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: isTablet ? 18 : 16, color: AppColors.bgDark), // <-- Use Icon instead of FaIcon for Material icons
              label: Text(text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenAccent,
                foregroundColor: AppColors.bgDark, // Text color for primary button
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 14 : 12),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: isTablet ? 16 : 14),
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(MaterialState.hovered)) return AppColors.greenAccent.withOpacity(0.8); // Darker on hover
                  return null;
                }),
                foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                   if (states.contains(MaterialState.hovered)) return AppColors.bgDark;
                   return AppColors.bgDark;
                })
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: isTablet ? 18 : 16, color: AppColors.textMuted), // <-- Use Icon instead of FaIcon
              label: Text(text),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMuted, // Text color for secondary button
                side: const BorderSide(color: AppColors.borderColor), // Border color
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 14 : 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: isTablet ? 16 : 14),
              ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(MaterialState.hovered)) return AppColors.greenAccent.withOpacity(0.1);
                    return null;
                  }),
                  foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                     if (states.contains(MaterialState.hovered)) return AppColors.greenAccent;
                     return AppColors.textMuted;
                  })
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
              backgroundColor: Colors.redAccent, // Keep red for error
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
        backgroundColor: AppColors.cardBg, // Compaign dialog background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.add_circle, color: AppColors.greenAccent, size: 28), // Accent color for icon
                  const SizedBox(width: 12),
      
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppColors.textMuted), // Muted close icon
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 16), // Light text input
                decoration: InputDecoration(
                  labelText: 'Amount (DZD)',
                  labelStyle: GoogleFonts.inter(color: AppColors.textMuted), // Muted label
                  prefixIcon: Icon(Icons.attach_money, color: AppColors.textMuted), // Muted icon
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.18), // Dark input background
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor), // Compaign border
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor), // Compaign border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.greenAccent, width: 2), // Accent focused border
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted, // Muted text for cancel
                        side: const BorderSide(color: AppColors.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton( // Use the new action button for consistency
                      text: "Continue",
                      icon: Icons.payment,
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
                              backgroundColor: Colors.orange, // Warning color
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      isPrimary: true,
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
    final bool isTablet = MediaQuery.of(context).size.width > 600;
    final double padding = isTablet ? 32.0 : 20.0; // Consistent padding

    return Scaffold(
      backgroundColor: AppColors.bgDark, // Compaign background color
      appBar: AppBar(
        backgroundColor: AppColors.bgDark, // Compaign app bar background
        foregroundColor: AppColors.textLight, // Compaign text color for app bar
        elevation: 0,
        title: Text(
          "Profile",
          style: GoogleFonts.inter(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 24, // Larger title to match Dashboard header
          ),
        ),
        actions: [ 
          // Logout Button
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: IconButton(
              icon: Icon(Icons.logout, color: AppColors.textLight, size: 22),
              onPressed: handleLogout,
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<DocumentSnapshot>(
          stream: firestore.collection('users').doc(user?.uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenAccent),
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final walletBalance = (userData['wallet_balance'] as num?)?.toDouble() ?? 0.0;

            return SingleChildScrollView( // Changed from CustomScrollView for simplicity with new AppBar
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  // Profile Header Card (Compaign style)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg, // Compaign card background
                      borderRadius: BorderRadius.circular(18), // Larger radius for a softer look
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18), // Subtle shadow
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          // Avatar Section
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
                                  backgroundColor: Colors.black.withOpacity(0.10), // Darker placeholder
                                  backgroundImage: user?.photoURL != null
                                      ? NetworkImage(user!.photoURL!)
                                      : null,
                                  child: _isUploading
                                      ? CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenAccent),
                                        )
                                      : user?.photoURL == null
                                          ? Icon(Icons.person, size: 50, color: AppColors.textMuted) // Muted icon
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
                                      color: AppColors.greenAccent, // Accent color for camera button
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
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: AppColors.bgDark, // Dark icon for contrast
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Name
                          Text(
                            user?.displayName ?? 'User Name',
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight, // Light text
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),

                          // Email
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.12), // Subtle dark background
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user?.email ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textMuted, // Muted text
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Settings Button (Compaign style)
                  _buildActionButton(
                    text: "Settings",
                    icon: Icons.settings,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => FractionallySizedBox(
                          heightFactor: 0.95,
                          child: DashboardPage.buildSettingsSidebar(context),
                        ),
                      );
                    },
                    isPrimary: false, // Outlined style
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Add this widget if _StatusPill is not public in compaign_list.dart
class StatusPill extends StatelessWidget {
  final String text;
  final bool isSuccess;
  final bool isTablet;
  const StatusPill(this.text, {this.isSuccess = false, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSuccess ? AppColors.greenAccent.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: isTablet ? 12 : 11,
          fontWeight: FontWeight.w500,
          color: isSuccess ? AppColors.greenAccent : AppColors.textMuted,
        ),
      ),
    );
  }
}