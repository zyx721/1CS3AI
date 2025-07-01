import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/drive.dart';
import '../payment/payment_selection_dialog.dart';
import '../new/compaign_list.dart';

// --- Transaction History Screen ---
class TransactionHistoryScreen extends StatelessWidget {
  final String userId;

  const TransactionHistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.greenAccent),
              ),
            );
          }

          final transactions = snapshot.data!.docs;

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppColors.textMuted.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet.',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: AppColors.textMuted,
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
                elevation: 0,
                color: AppColors.cardBg,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: type == 'add_funds'
                              ? AppColors.greenAccent.withOpacity(0.1)
                              : AppColors.textMuted.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          type == 'add_funds'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: type == 'add_funds'
                              ? AppColors.greenAccent
                              : AppColors.textMuted,
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
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (paymentMethod.isNotEmpty)
                              Text(
                                'via $paymentMethod',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
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
                                color: AppColors.textMuted.withOpacity(0.5),
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
                                  : AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          StatusPill(
                            status[0].toUpperCase() + status.substring(1),
                            isSuccess: status == 'success',
                            isTablet: MediaQuery.of(context).size.width > 600,
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

// --- Status Pill Widget ---
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

// --- Profile Screen ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  // --- Controllers & State ---
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;
  final GoogleDriveService _driveService = GoogleDriveService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isUploading = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Additional controllers for agent dialog
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _servicesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditingAgentInfo = false;
  bool _isAgentInfoLoading = false;

  // --- Lifecycle ---
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
    _businessNameController.dispose();
    _domainController.dispose();
    _servicesController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --- UI Builders ---
  Widget _buildWalletBalanceCard(String title, String count, {VoidCallback? onTap, bool isTablet = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
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
                color: AppColors.textMuted,
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
                color: AppColors.greenAccent,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required IconData icon,
    bool isPrimary = true,
  }) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;
    return SizedBox(
      width: double.infinity,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: isTablet ? 18 : 16, color: AppColors.bgDark),
              label: Text(text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenAccent,
                foregroundColor: AppColors.bgDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 14 : 12),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: isTablet ? 16 : 14),
              ).copyWith(
                overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(MaterialState.hovered)) return AppColors.greenAccent.withOpacity(0.8);
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
              icon: Icon(icon, size: isTablet ? 18 : 16, color: AppColors.textMuted),
              label: Text(text),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                side: const BorderSide(color: AppColors.borderColor),
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

  // --- Profile Actions ---
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
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.greenAccent.withOpacity(0.18), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle, color: AppColors.greenAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add Funds',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Amount (DZD)',
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.attach_money, color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.greenAccent, width: 2),
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
                            foregroundColor: AppColors.textMuted,
                            side: const BorderSide(color: AppColors.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                            backgroundColor: Colors.transparent,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
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
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.payment, color: AppColors.bgDark),
                          label: Text("Continue"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.greenAccent,
                            foregroundColor: AppColors.bgDark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                            elevation: 0,
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

  // --- Fetch agent info from backend ---
  Future<void> _fetchAgentInfo() async {
    setState(() => _isAgentInfoLoading = true);
    try {
      final res = await http.get(Uri.parse('http://10.48.173.163:8000/agent-info'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _businessNameController.text = data['business_name'] ?? '';
        _domainController.text = data['domain'] ?? '';
        _locationController.text = data['location'] ?? '';
        _servicesController.text = data['services'] ?? '';
        _descriptionController.text = data['description'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch agent info: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isAgentInfoLoading = false);
    }
  }

  // --- Update agent info on backend ---
  Future<bool> _updateAgentInfo() async {
    setState(() => _isAgentInfoLoading = true);
    try {
      final res = await http.post(
        Uri.parse('http://10.48.173.163:8000/agent-info'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'business_name': _businessNameController.text,
          'domain': _domainController.text,
          'location': _locationController.text,
          'services': _servicesController.text,
          'description': _descriptionController.text,
        }),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Agent info updated!'), backgroundColor: Colors.green),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update agent info'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isAgentInfoLoading = false);
    }
    return false;
  }

  // --- Show Edit Agent Dialog with fetch ---
  void _showEditAgentDialog() async {
    await _fetchAgentInfo();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Material(
              color: Colors.transparent,
              child: _AgentEditDialog(
                businessNameController: _businessNameController,
                domainController: _domainController,
                locationController: _locationController,
                servicesController: _servicesController,
                descriptionController: _descriptionController,
                isLoading: _isAgentInfoLoading,
                onSave: () async {
                  if (_businessNameController.text.trim().isEmpty ||
                      _domainController.text.trim().isEmpty ||
                      _locationController.text.trim().isEmpty ||
                      _servicesController.text.trim().isEmpty ||
                      _descriptionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('All fields are required'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  setStateDialog(() => _isAgentInfoLoading = true);
                  final success = await _updateAgentInfo();
                  setStateDialog(() => _isAgentInfoLoading = false);
                  if (success && mounted) Navigator.of(ctx).pop();
                },
                onCancel: () {
                  Navigator.of(ctx).pop();
                },
              ),
            );
          },
        );
      },
    );
  }

  void _saveAndCloseSidebar() {
    if (_formKey.currentState?.validate() ?? false) {
      // Save logic here
      Navigator.of(context).pop();
    }
  }

  void _hideEditAgentForm() {
    setState(() {
      _isEditingAgentInfo = false;
    });
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(color: AppColors.textLight),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.18),
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted.withOpacity(0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.greenAccent),
            ),
          ),
          validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildSettingsOptions() {
    return Column(
      key: const ValueKey('options'),
      children: [
        _SidebarOptionButton(
          icon: FontAwesomeIcons.solidUser,
          label: "Edit Agent Information",
          onPressed: _showEditAgentDialog,
        ),
        _SidebarOptionButton(
          icon: FontAwesomeIcons.key,
          label: "Change Password",
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (ctx) => const _ChangePasswordDialog(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        key: const ValueKey('form'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextFormField(controller: _businessNameController, label: "Business Name"),
            _buildTextFormField(controller: _domainController, label: "Industry / Niche"),
            _buildTextFormField(controller: _locationController, label: "Target Location(s)", hint: "e.g. United States, France"),
            _buildTextFormField(controller: _servicesController, label: "Products / Services", maxLines: 2),
            _buildTextFormField(controller: _descriptionController, label: "Company Description", maxLines: 3),
            const SizedBox(height: 20),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveAndCloseSidebar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenAccent,
                      foregroundColor: AppColors.bgDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                    child: const Text("Save"),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _hideEditAgentForm,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSidebar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth < 400 ? screenWidth * 0.9 : 400.0;
    
    return Drawer(
      width: sidebarWidth,
      backgroundColor: AppColors.cardBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Settings",
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isEditingAgentInfo ? _buildSettingsForm() : _buildSettingsOptions(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Build ---
  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;
    final double padding = isTablet ? 32.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        title: Text(
          "Profile",
          style: GoogleFonts.inter(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [ 
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

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  // --- Profile Header Card ---
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
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
                                  radius: isTablet ? 54 : 44,
                                  backgroundColor: AppColors.bgDark,
                                  backgroundImage: userData['photoURL'] != null && userData['photoURL'].toString().isNotEmpty
                                      ? NetworkImage(userData['photoURL'])
                                      : null,
                                  child: userData['photoURL'] == null || userData['photoURL'].toString().isEmpty
                                      ? Icon(Icons.person, size: isTablet ? 54 : 44, color: AppColors.textMuted)
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _isUploading ? null : _updateProfilePicture,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.greenAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.bgDark, width: 2),
                                    ),
                                    child: _isUploading
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.bgDark),
                                            ),
                                          )
                                        : Icon(Icons.camera_alt, color: AppColors.bgDark, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            userData['displayName'] ?? user?.displayName ?? 'No Name',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: isTablet ? 22 : 18,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            userData['email'] ?? user?.email ?? '',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 15 : 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // --- Wallet Balance & Actions ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildWalletBalanceCard(
                          "Wallet Balance",
                          "${walletBalance.toStringAsFixed(2)} DZD",
                          onTap: _showTransactionHistory,
                          isTablet: isTablet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildWalletBalanceCard(
                          "Add Funds",
                          "+",
                          onTap: _showAddFundsDialog,
                          isTablet: isTablet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // --- Actions ---
     
                  // --- Settings Sidebar Button ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.settings, color: AppColors.textMuted),
                      label: Text("Settings"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: AppColors.borderColor),
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 14 : 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: isTablet ? 16 : 14),
                      ),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      endDrawer: _buildSettingsSidebar(),
    );
  }
}

// --- Sidebar Option Button Widget ---
class _SidebarOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SidebarOptionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: OutlinedButton.icon(
        icon: Icon(icon, color: AppColors.textMuted, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

// --- Agent Edit Dialog Widget ---
class _AgentEditDialog extends StatelessWidget {
  final TextEditingController businessNameController;
  final TextEditingController domainController;
  final TextEditingController locationController;
  final TextEditingController servicesController;
  final TextEditingController descriptionController;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isLoading;

  const _AgentEditDialog({
    required this.businessNameController,
    required this.domainController,
    required this.locationController,
    required this.servicesController,
    required this.descriptionController,
    required this.onSave,
    required this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isLoading,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, color: AppColors.greenAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Edit Agent Information',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onCancel,
                        icon: Icon(Icons.close, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: businessNameController,
                    style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Business Name',
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.greenAccent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: domainController,
                    style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Industry / Niche',
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.greenAccent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: locationController,
                    style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Target Location(s)',
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      hintText: "e.g. United States, France",
                      hintStyle: GoogleFonts.inter(color: AppColors.textMuted.withOpacity(0.5)),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.greenAccent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: servicesController,
                    maxLines: 2,
                    style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Products / Services',
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.greenAccent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Company Description',
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.greenAccent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textMuted,
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
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : onSave,
                          icon: Icon(Icons.save, color: AppColors.bgDark),
                          label: isLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.bgDark),
                                  ),
                                )
                              : Text("Save"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.greenAccent,
                            foregroundColor: AppColors.bgDark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.08),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Change Password Dialog Widget (styled like change.dart) ---
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({Key? key}) : super(key: key);

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isEmailPasswordProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((element) => element.providerId == 'password');
  }

  Widget _buildAuthMethodMessage() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final providers = user.providerData.map((e) => e.providerId).toList();
    String authMethod = 'Unknown';

    if (providers.contains('google.com')) {
      authMethod = 'Google';
    } else if (providers.contains('facebook.com')) {
      authMethod = 'Facebook';
    } else if (providers.contains('apple.com')) {
      authMethod = 'Apple';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBg.withOpacity(0.98),
            AppColors.bgDark.withOpacity(0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenAccent.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.greenAccent,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Signed in with $authMethod',
            style: GoogleFonts.inter(
              fontSize: 18,
              color: AppColors.greenAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please visit $authMethod settings to manage your password.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'No user found';

      if (!_isEmailPasswordProvider()) {
        throw 'This feature is only available for email/password accounts';
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password updated successfully'),
            backgroundColor: Colors.green[600],
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 30, 139, 57), // Purple 500
              Color.fromARGB(255, 19, 240, 89), // Purple 700
            ],
          ),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: _isEmailPasswordProvider()
                  ? Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Change Password",
                                      style: TextStyle(
                                        color: Colors.purple[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, color: Colors.purple[700]),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _currentPasswordController,
                                decoration: InputDecoration(
                                  labelText: "Current Password",
                                  labelStyle: TextStyle(color: Colors.purple[700]),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.purple[700]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.purple[200]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showCurrentPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.purple[700],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showCurrentPassword = !_showCurrentPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_showCurrentPassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Current password required";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _newPasswordController,
                                decoration: InputDecoration(
                                  labelText: "New Password",
                                  labelStyle: TextStyle(color: Colors.purple[700]),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.purple[700]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.purple[200]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showNewPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.purple[700],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showNewPassword = !_showNewPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_showNewPassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "New password required";
                                  }
                                  if (value.length < 6) {
                                    return "Password must be at least 6 characters";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText: "Confirm New Password",
                                  labelStyle: TextStyle(color: const Color.fromARGB(255, 31, 162, 92)),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: const Color.fromARGB(255, 31, 162, 61)!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: const Color.fromARGB(255, 147, 216, 180)!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color.fromARGB(255, 31, 162, 94),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showConfirmPassword = !_showConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_showConfirmPassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please confirm new password";
                                  }
                                  if (value != _newPasswordController.text) {
                                    return "Passwords do not match";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 31, 162, 68),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        "Change Password",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _buildAuthMethodMessage(),
            ),
          ),
        ),
      ),
    );
  }
}