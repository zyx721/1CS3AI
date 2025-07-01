import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BaridiPaymentScreen extends StatefulWidget {
  final double amount;
  final String orderNumber;
  final String purpose; // 'add_funds' or 'donation'
  final String? fundraiserId;
  final bool isAnonymous;

  const BaridiPaymentScreen({
    Key? key,
    required this.amount,
    required this.orderNumber,
    required this.purpose,
    this.fundraiserId,
    this.isAnonymous = false,
  }) : super(key: key);

  @override
  _BaridiPaymentScreenState createState() => _BaridiPaymentScreenState();
}

class _BaridiPaymentScreenState extends State<BaridiPaymentScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cvvController = TextEditingController();
  
  bool _isProcessing = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardNumberController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _cardHolderController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (widget.purpose == 'add_funds') {
        await _addFundsToProfile(currentUser);
      } else if (widget.purpose == 'donation') {
        await _saveDonationInfo(currentUser);
      }

      // Show success animation and navigate back
      await _showSuccessDialog();
      Navigator.of(context).pop(true);
      
    } catch (e) {
      print('Error processing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _addFundsToProfile(User currentUser) async {
    // Add funds to user's wallet/balance
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({
      'wallet_balance': FieldValue.increment(widget.amount),
    });

    // Create transaction record
    await FirebaseFirestore.instance
        .collection('transactions')
        .add({
      'userId': currentUser.uid,
      'type': 'add_funds',
      'amount': widget.amount,
      'paymentMethod': 'Baridi Mobile',
      'orderNumber': widget.orderNumber,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'completed',
    });
  }

  Future<void> _saveDonationInfo(User currentUser) async {
    if (widget.fundraiserId == null) {
      throw Exception('Fundraiser ID is required for donations');
    }

    // Create donation document
    final donationData = {
      'fundraiserId': widget.fundraiserId,
      'amount': widget.amount,
      'timestamp': FieldValue.serverTimestamp(),
      'donatorId': widget.isAnonymous ? 'anonymous' : currentUser.uid,
      'paymentMethod': 'Baridi Mobile',
      'orderNumber': widget.orderNumber,
      'status': 'completed',
    };

    // Add donation to donations collection
    await FirebaseFirestore.instance
        .collection('donations')
        .add(donationData);

    // Update fundraiser's total amount and donators count
    await FirebaseFirestore.instance
        .collection('fundraisers')
        .doc(widget.fundraiserId!)
        .update({
      'funding': FieldValue.increment(widget.amount),
      'donators': FieldValue.increment(1),
    });

    // Update user's donations list if not anonymous
    if (!widget.isAnonymous) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'donations': FieldValue.arrayUnion([widget.fundraiserId])
      });
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.purpose == 'add_funds'
                  ? 'Funds have been added to your wallet'
                  : 'Your donation has been processed',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Baridi Mobile Payment', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
        ),
        backgroundColor: const Color(0xFF181C23), // dark appbar
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF101215), // dark background
      body: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baridi Logo and Header
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/baridi_card.png',
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                Text(
                  'PAYMENT INFORMATION',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF3CB35),
                  ),
                ),
                Container(
                  height: 3,
                  width: 60,
                  color: Color(0xFFF3CB35),
                  margin: EdgeInsets.only(top: 4),
                ),
                
                SizedBox(height: 20),
                
                // Payment Details Card
                Card(
                  elevation: 8,
                  color: const Color(0xFF23262B).withOpacity(0.85), // dark glass effect
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Order Details Table
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFF3CB35)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Table(
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Color(0xFF23262B),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(7),
                                    topRight: Radius.circular(7),
                                  ),
                                ),
                                children: [
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        'ORDER NUMBER',
                                        style: TextStyle(
                                          color: Color(0xFFF3CB35),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        'TOTAL AMOUNT',
                                        style: TextStyle(
                                          color: Color(0xFFF3CB35),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        widget.orderNumber,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TableCell(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        '${widget.amount.toStringAsFixed(2)} DZD',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF3CB35),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Card Details Form
                        _buildTextField(
                          'Credit card number',
                          _cardNumberController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.credit_card,
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Month',
                                _monthController,
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.calendar_month,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                'Year',
                                _yearController,
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.calendar_today,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          'Card holder name',
                          _cardHolderController,
                          prefixIcon: Icons.person,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          'CVV',
                          _cvvController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.security,
                          obscureText: true,
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Submit Button
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF3CB35),
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Confirm Payment',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Security Notice
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFF3CB35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Color(0xFFF3CB35), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your payment information is secure and encrypted',
                          style: TextStyle(
                            color: Color(0xFFF3CB35),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Color(0xFFF3CB35)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFF3CB35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFF3CB35), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white24),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        
        // Additional validation for specific fields
        if (label == 'Credit card number' && value.length < 16) {
          return 'Please enter a valid card number';
        }
        if (label == 'Month' && (int.tryParse(value) == null || int.parse(value) < 1 || int.parse(value) > 12)) {
          return 'Please enter a valid month (1-12)';
        }
        if (label == 'Year' && (int.tryParse(value) == null || int.parse(value) < DateTime.now().year)) {
          return 'Please enter a valid year';
        }
        if (label == 'CVV' && value.length < 3) {
          return 'Please enter a valid CVV';
        }
        
        return null;
      },
    );
  }
}