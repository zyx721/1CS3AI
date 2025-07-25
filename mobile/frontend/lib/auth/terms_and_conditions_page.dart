import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  _TermsAndConditionsPageState createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms and Conditions',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF505050), // dark gray
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(255, 255, 255, 1),
              Color.fromARGB(65, 120, 120, 120),   // light gray
              Color.fromARGB(120, 120, 120, 120),  // medium gray
              Color.fromARGB(255, 80, 80, 80),     // dark gray
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            'Terms and Conditions',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF505050), // dark gray
                            ),
                          ),
                          Divider(
                            color: Colors.grey.shade400,
                            thickness: 2,
                            height: 32,
                          ),
                          Text(
                            '1. Introduction\n'
                            'These terms and conditions outline the rules and regulations for the use of the HANINI app.\n\n'
                            '2. Acceptance of Terms\n'
                            'By accessing this app, we assume you accept these terms and conditions.\n\n'
                            '3. Privacy Policy\n'
                            'Your privacy is important to us, and we are committed to protecting your personal data.\n\n'
                            '4. Changes to Terms\n'
                            'We may update the terms and conditions periodically. Please review them regularly.\n\n'
                            '5. Limitation of Liability\n'
                            'In no event shall we be liable for any damages or losses.\n\n'
                            '6. Governing Law\n'
                            'These terms shall be governed by the laws of [Your Country].\n\n'
                            'Please read all terms carefully before proceeding to the app.',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              height: 1.6,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}