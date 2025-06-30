import 'package:flutter/material.dart';
import 'dart:ui';

class CampaignsPage extends StatefulWidget {
  const CampaignsPage({super.key});

  @override
  State<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends State<CampaignsPage>
    with TickerProviderStateMixin {
  bool isGrid = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final campaigns = [
    {
      'status': 'Active',
      'name': 'AI Marketing Campaign',
      'target': 'Marketing Managers',
      'color': const Color(0xFF34D399),
      'progress': 0.75,
      'leads': 48,
      'responses': 23,
    },
    {
      'status': 'Paused',
      'name': 'Sales Automation Campaign',
      'target': 'Sales Directors',
      'color': const Color(0xFFF59E0B),
      'progress': 0.45,
      'leads': 32,
      'responses': 12,
    },
    {
      'status': 'Completed',
      'name': 'HR Tech Outreach',
      'target': 'HR Professionals',
      'color': const Color(0xFF8B5CF6),
      'progress': 1.0,
      'leads': 65,
      'responses': 41,
    },
    {
      'status': 'Active',
      'name': 'Product Innovation Drive',
      'target': 'Product Owners',
      'color': const Color(0xFFEF4444),
      'progress': 0.30,
      'leads': 19,
      'responses': 8,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _startAnimations();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Campaigns',
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontWeight: FontWeight.w300,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Container(
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
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 120),
                    
                    // Header with stats
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    
                    // Toggle buttons
                    _buildToggleSection(),
                    const SizedBox(height: 24),
                    
                    // Campaigns list
                    Expanded(
                      child: isGrid ? _buildGridView() : _buildListView(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
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

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _buildGlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Campaigns',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '2',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.white.withOpacity(0.15),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Total Leads',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${campaigns.fold(0, (sum, campaign) => sum + (campaign['leads'] as int))}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.white.withOpacity(0.15),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Responses',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${campaigns.fold(0, (sum, campaign) => sum + (campaign['responses'] as int))}',
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _buildGlassContainer(
        padding: const EdgeInsets.all(8),
        opacity: 0.05,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => isGrid = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: !isGrid 
                        ? const Color(0xFF34D399).withOpacity(0.2)
                        : Colors.transparent,
                    border: !isGrid
                        ? Border.all(
                            color: const Color(0xFF34D399).withOpacity(0.4),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.view_list_rounded,
                        color: !isGrid 
                            ? const Color(0xFF34D399)
                            : Colors.white.withOpacity(0.6),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'List',
                        style: TextStyle(
                          color: !isGrid 
                              ? const Color(0xFF34D399)
                              : Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => isGrid = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isGrid 
                        ? const Color(0xFF34D399).withOpacity(0.2)
                        : Colors.transparent,
                    border: isGrid
                        ? Border.all(
                            color: const Color(0xFF34D399).withOpacity(0.4),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        color: isGrid 
                            ? const Color(0xFF34D399)
                            : Colors.white.withOpacity(0.6),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Grid',
                        style: TextStyle(
                          color: isGrid 
                              ? const Color(0xFF34D399)
                              : Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 80), // increased bottom padding
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: CampaignCard(
                  campaign: campaigns[index],
                  isGrid: false,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 80), // match ListView bottom padding
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: CampaignCard(
                  campaign: campaigns[index],
                  isGrid: true,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final bool isGrid;

  const CampaignCard({
    super.key,
    required this.campaign,
    required this.isGrid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
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
            child: isGrid ? _buildGridCard() : _buildListCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Status indicator and icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: RadialGradient(
                colors: [
                  (campaign['color'] as Color).withOpacity(0.3),
                  (campaign['color'] as Color).withOpacity(0.8),
                ],
              ),
              border: Border.all(
                color: (campaign['color'] as Color).withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Icon(
              _getStatusIcon(campaign['status'] as String),
              color: campaign['color'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Campaign details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        campaign['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _buildStatusChip(campaign['status'] as String),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Target: ${campaign['target']}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${((campaign['progress'] as double) * 100).toInt()}%',
                          style: TextStyle(
                            color: campaign['color'] as Color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: campaign['progress'] as double,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        campaign['color'] as Color,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Stats
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: Colors.white.withOpacity(0.6),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${campaign['leads']} leads',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white.withOpacity(0.6),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${campaign['responses']} responses',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: RadialGradient(
                    colors: [
                      (campaign['color'] as Color).withOpacity(0.3),
                      (campaign['color'] as Color).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Icon(
                  _getStatusIcon(campaign['status'] as String),
                  color: campaign['color'] as Color,
                  size: 20,
                ),
              ),
              const Spacer(),
              _buildStatusChip(campaign['status'] as String),
            ],
          ),
          const SizedBox(height: 16),
          
          // Campaign name
          Text(
            campaign['name'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          
          // Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${((campaign['progress'] as double) * 100).toInt()}%',
                    style: TextStyle(
                      color: campaign['color'] as Color,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: campaign['progress'] as double,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  campaign['color'] as Color,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${campaign['leads']}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'leads',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${campaign['responses']}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'responses',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor = getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Active':
        return Icons.play_arrow_rounded;
      case 'Paused':
        return Icons.pause_rounded;
      case 'Completed':
        return Icons.check_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF34D399);
      case 'Paused':
        return const Color(0xFFF59E0B);
      case 'Completed':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.white;
    }
  }
}