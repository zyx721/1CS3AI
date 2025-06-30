import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';

// --- Color Palette from CSS Variables ---
class AppColors {
  static const Color bgDark = Color(0xFF131414);
  static const Color cardBg = Color(0xFF1D1D1F);
  static const Color textLight = Color(0xFFF5F4F0);
  static const Color textMuted = Color(0xFF8A8A8E);
  static const Color greenAccent = Color(0xFF79B266);
  static const Color borderColor = Color.fromRGBO(245, 244, 240, 0.1);
  static const Color topGlow1 = Color(0xFF2E402B);
}

// --- Main Dashboard Page Widget ---
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // State for settings sidebar
  bool _isEditingAgentInfo = false;
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _domainController = TextEditingController();
  final _locationController = TextEditingController();
  final _servicesController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _businessNameController.dispose();
    _domainController.dispose();
    _locationController.dispose();
    _servicesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Methods for Settings Persistence (like localStorage) ---
  Future<void> _loadAgentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final infoJson = prefs.getString('agentInfo');
    if (infoJson != null) {
      final info = jsonDecode(infoJson);
      _businessNameController.text = info['business_name'] ?? '';
      _domainController.text = info['domain'] ?? '';
      final location = info['location'];
      if(location is List){
        _locationController.text = location.join(', ');
      } else {
        _locationController.text = location ?? '';
      }
      _servicesController.text = info['services'] ?? '';
      _descriptionController.text = info['description'] ?? '';
    }
  }

  Future<void> _saveAgentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final info = {
      'business_name': _businessNameController.text,
      'domain': _domainController.text,
      'location': _locationController.text.split(',').map((s) => s.trim()).toList(),
      'services': _servicesController.text,
      'description': _descriptionController.text,
    };
    await prefs.setString('agentInfo', jsonEncode(info));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: AppColors.greenAccent,
        ),
      );
    }
  }

  void _showEditAgentForm() async {
    await _loadAgentInfo();
    setState(() {
      _isEditingAgentInfo = true;
    });
  }

  void _hideEditAgentForm() {
    setState(() {
      _isEditingAgentInfo = false;
    });
  }

  void _saveAndCloseSidebar() {
    _saveAgentInfo();
    _hideEditAgentForm();
    Navigator.of(context).pop(); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final padding = isTablet ? 32.0 : 16.0;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgDark,
      endDrawer: _buildSettingsSidebar(),
      body: Stack(
        children: [
          // --- Top Radial Glow Effect ---
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -1.5),
                radius: 1.0,
                colors: [AppColors.topGlow1, Colors.transparent],
                stops: [0.0, 0.7],
              ),
            ),
          ),
          // --- Main Scrollable Content ---
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isTablet),
                  SizedBox(height: isTablet ? 32 : 20),
                  _buildStatsGrid(isTablet),
                  const SizedBox(height: 20),
                  _buildPerformanceChartCard(isTablet),
                  const SizedBox(height: 20),
                  _buildResultsTableCard(isTablet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Builder Methods ---

  Widget _buildHeader(bool isTablet) {
    if (isTablet) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildHeaderContent()),
          _buildSettingsButton(),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildHeaderContent()),
              _buildSettingsButton(),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Agent Dashboard",
          style: GoogleFonts.inter(
            fontSize: 24, 
            fontWeight: FontWeight.w600, 
            color: AppColors.textLight
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Welcome back! Here's a summary of your activities.",
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildSettingsButton() {
    return ElevatedButton.icon(
      onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
      icon: const FaIcon(FontAwesomeIcons.gear, size: 14),
      label: const Text("Settings"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.hovered)) return AppColors.greenAccent.withOpacity(0.8);
          return null;
        }),
        foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
           if (states.contains(MaterialState.hovered)) return AppColors.bgDark;
           return AppColors.textLight;
        })
      ),
    );
  }

  Widget _buildStatsGrid(bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid: 2 columns on mobile, up to 4 on larger screens
        final crossAxisCount = isTablet 
            ? (constraints.maxWidth / 240).floor().clamp(2, 4)
            : 2;
        
        return GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isTablet ? 20 : 12,
            mainAxisSpacing: isTablet ? 20 : 12,
            childAspectRatio: isTablet ? 1.5 : 1.3,
          ),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            _buildStatCard("Total Calls Made", "1,284", isTablet),
            _buildStatCard("Calls This Week", "76", isTablet),
            _buildStatCard("Success Rate", "21%", isHighlighted: true, isTablet),
            _buildStatCard("New Leads Found", "18", isTablet),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, bool isTablet, {bool isHighlighted = false}) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label, 
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14 : 12, 
              color: AppColors.textMuted
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 32 : 28,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? AppColors.greenAccent : AppColors.textLight,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChartCard(bool isTablet) {
    return _DashCard(
      title: "Performance Over Time (Last 30 Days)",
      isTablet: isTablet,
      child: Column(
        children: [
          _buildChartLegend(isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          SizedBox(
            height: isTablet ? 300 : 250,
            child: _ProfessionalLineChart(isTablet: isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(bool isTablet) {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        _legendItem(AppColors.greenAccent, "New Leads", isTablet),
        _legendItem(AppColors.textMuted, "Successful Calls", isTablet),
      ],
    );
  }

  Widget _legendItem(Color color, String text, bool isTablet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 14 : 12, 
            color: AppColors.textMuted
          ),
        ),
      ],
    );
  }

  Widget _buildResultsTableCard(bool isTablet) {
    return _DashCard(
      title: "Lead Search Results",
      isTablet: isTablet,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - (isTablet ? 80 : 48),
          ),
          child: DataTable(
            columnSpacing: isTablet ? 16 : 12,
            horizontalMargin: 0,
            headingRowHeight: isTablet ? 48 : 44,
            dataRowMinHeight: isTablet ? 52 : 48,
            dataRowMaxHeight: isTablet ? 60 : 56,
            headingTextStyle: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: isTablet ? 12 : 11,
              letterSpacing: 0.5,
            ),
            dataTextStyle: GoogleFonts.inter(
              color: AppColors.textLight, 
              fontSize: isTablet ? 14 : 13
            ),
            columns: const [
              DataColumn(label: Text("BUSINESS NAME")),
              DataColumn(label: Text("CONTACT")),
              DataColumn(label: Text("STATUS")),
            ],
            rows: [
              DataRow(cells: [
                const DataCell(Text("Sunrise Bakery")),
                const DataCell(Text("555-123-4567")),
                DataCell(_StatusPill("Interested", isSuccess: true, isTablet: isTablet)),
              ]),
              DataRow(cells: [
                const DataCell(Text("Quantum Tech")),
                const DataCell(Text("555-987-6543")),
                DataCell(_StatusPill("Contacted", isTablet: isTablet)),
              ]),
              DataRow(cells: [
                const DataCell(Text("Green Leaf Cafe")),
                const DataCell(Text("555-222-3333")),
                DataCell(_StatusPill("Not Contacted", isTablet: isTablet)),
              ]),
            ],
          ),
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
  
  Widget _buildSettingsOptions() {
    return Column(
      key: const ValueKey('options'),
      children: [
        _SidebarOptionButton(
          icon: FontAwesomeIcons.solidUser,
          label: "Edit Agent Information",
          onPressed: _showEditAgentForm,
        ),
        _SidebarOptionButton(
          icon: FontAwesomeIcons.key,
          label: "Change Password",
          onPressed: () {},
        ),
        _SidebarOptionButton(
          icon: FontAwesomeIcons.solidBell,
          label: "Notification Preferences",
          onPressed: () {},
        ),
        _SidebarOptionButton(
          icon: FontAwesomeIcons.fileExport,
          label: "Export Data",
          onPressed: () {},
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
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

// --- Reusable Component Widgets ---

class _DashCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isTablet;
  const _DashCard({required this.title, required this.child, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 18 : 16, 
              fontWeight: FontWeight.w500, 
              color: AppColors.textLight
            ),
          ),
          SizedBox(height: isTablet ? 24 : 16),
          child,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final bool isSuccess;
  final bool isTablet;
  const _StatusPill(this.text, {this.isSuccess = false, required this.isTablet});

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

class _SidebarOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _SidebarOptionButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.black.withOpacity(0.12),
          foregroundColor: AppColors.textLight,
          alignment: Alignment.centerLeft,
          minimumSize: const Size(double.infinity, 50),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.borderColor),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
        ).copyWith(
            overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
              if (states.contains(MaterialState.hovered)) return AppColors.greenAccent.withOpacity(0.8);
              return null;
            }),
            foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
               if (states.contains(MaterialState.hovered)) return AppColors.bgDark;
               return AppColors.textLight;
            })
        ),
      ),
    );
  }
}

// --- Chart Widget ---
class _ProfessionalLineChart extends StatefulWidget {
  final bool isTablet;
  
  const _ProfessionalLineChart({required this.isTablet});

  @override
  State<_ProfessionalLineChart> createState() => _ProfessionalLineChartState();
}

class _ProfessionalLineChartState extends State<_ProfessionalLineChart> {
  late List<FlSpot> leadsData;
  late List<FlSpot> successData;

  @override
  void initState() {
    super.initState();
    // Generate random data similar to the JS example
    final random = Random();
    final tempLeads = List.generate(30, (i) => random.nextDouble() * 20 + 10);
    leadsData = List.generate(30, (i) => FlSpot(i.toDouble(), tempLeads[i]));
    successData = List.generate(30, (i) => FlSpot(i.toDouble(), max(0, tempLeads[i] * (random.nextDouble() * 0.4 + 0.1) - random.nextDouble() * 5)));
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        // Interaction and Tooltip
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(color: AppColors.textLight.withOpacity(0.5), strokeWidth: 1),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: barData.color!,
                      strokeWidth: 0,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF2A2E2A).withOpacity(0.9),
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final bar = touchedSpot.bar;
                final label = bar.barWidth == 2 ? 'New Leads' : 'Successful Calls';
                return LineTooltipItem(
                  '$label: ${touchedSpot.y.toStringAsFixed(0)}',
                  GoogleFonts.inter(
                    color: bar.color,
                    fontWeight: FontWeight.bold,
                    fontSize: widget.isTablet ? 12 : 11,
                  ),
                );
              }).toList();
            },
          ),
        ),

        // Grid and Axis Styling
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: AppColors.borderColor,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: widget.isTablet ? 6 : 10, // Fewer labels on mobile
              getTitlesWidget: (value, meta) {
                final date = DateTime.now().subtract(Duration(days: 29 - value.toInt()));
                const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                String text = '${monthNames[date.month-1]} ${date.day}';
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    text, 
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted, 
                      fontSize: widget.isTablet ? 12 : 10
                    )
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  meta.formattedValue,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted, 
                    fontSize: widget.isTablet ? 12 : 10
                  ),
                ),
              ),
              reservedSize: widget.isTablet ? 40 : 35,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),

        // Line Data
        lineBarsData: [
          // New Leads Line
          LineChartBarData(
            spots: leadsData,
            isCurved: true,
            color: AppColors.greenAccent,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.greenAccent.withOpacity(0.25),
                  AppColors.greenAccent.withOpacity(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Successful Calls Line
          LineChartBarData(
            spots: successData,
            isCurved: true,
            color: AppColors.textMuted,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5], // Dashed line effect
          ),
        ],
      ),
    );
  }
}