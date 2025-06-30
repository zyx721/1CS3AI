import 'package:flutter/material.dart';
import '../payment/baridi_payment_screen.dart';

class PaymentSelectionDialog extends StatefulWidget {
  final double amount;
  final String purpose; // 'add_funds' or 'donation'
  final String? fundraiserId; // Only for donations

  const PaymentSelectionDialog({
    Key? key,
    required this.amount,
    required this.purpose,
    this.fundraiserId,
  }) : super(key: key);

  @override
  _PaymentSelectionDialogState createState() => _PaymentSelectionDialogState();
}

class _PaymentSelectionDialogState extends State<PaymentSelectionDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          color: Color(0xFF336799),
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.purpose == 'add_funds' 
                                ? 'Add Funds' 
                                : 'Choose Payment Method',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF336799),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Amount display
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Color(0xFF336799).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF336799).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${widget.amount.toStringAsFixed(2)} DZD',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF336799),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    Text(
                      'Select your preferred payment method:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Payment options
                    _buildPaymentOption(
                      title: 'Baridi Mobile',
                      subtitle: 'Pay with Baridi Mobile',
                      iconWidget: Icon(Icons.phone_android, color: Color(0xFF336799), size: 24),
                      color: Color(0xFF336799),
                      onTap: () => _handleBaridiPayment(),
                    ),
                    
                    SizedBox(height: 12),
                    
                    _buildPaymentOption(
                      title: 'PayPal',
                      subtitle: 'Pay with PayPal account',
                      iconWidget: Icon(Icons.account_balance_wallet, color: Colors.blue[700], size: 24),
                      color: Colors.blue[700]!,
                      onTap: () => _handlePayPalPayment(),
                    ),
                    
                    SizedBox(height: 12),
                    
                    _buildPaymentOption(
                      title: 'Google Pay',
                      subtitle: 'Pay with Google Pay',
                      iconWidget: Image.asset(
                        'assets/images/google_logo.png',
                        height: 24,
                        width: 24,
                      ),
                      // Changed from green to gray
                      color: Colors.grey[600]!,
                      onTap: () => _handleGooglePayment(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required Widget iconWidget,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: iconWidget,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBaridiPayment() {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return BaridiPaymentScreen(
            amount: widget.amount,
            orderNumber: _generateOrderNumber(),
            purpose: widget.purpose,
            fundraiserId: widget.fundraiserId,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _handlePayPalPayment() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PayPal integration coming soon!'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  void _handleGooglePayment() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Google Pay integration coming soon!'),
        // Changed from green to gray
        backgroundColor: Colors.grey[600],
      ),
    );
  }

  String _generateOrderNumber() {
    return 'ORD${DateTime.now().millisecondsSinceEpoch}';
  }
}

// Function to show the payment dialog
Future<void> showPaymentDialog(BuildContext context, {
  required double amount,
  required String purpose,
  String? fundraiserId,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PaymentSelectionDialog(
      amount: amount,
      purpose: purpose,
      fundraiserId: fundraiserId,
    ),
  );
}