import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final DashboardService _service = DashboardService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  late AnimationController _controller;

  // --- PALETTE (MATCHING FORM SCREEN) ---
  final Color bgBlack = const Color(0xFF121212); // Deep Black
  final Color cardGrey = const Color(0xFF1E1E1E); // Dark Grey Cards
  final Color neonGreen = const Color(0xFF00E676); // Neon Green
  final Color neonRed = const Color(0xFFFF5252); // Neon Red (From Result Screen)
  final Color textWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    // Setup Animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.fetchDashboardData();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
      _controller.forward(); // Start animation after data loads
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: bgBlack,
        elevation: 0,
        title: Text("Risk Command",
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: textWhite)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              backgroundColor: neonGreen.withValues(alpha: 0.1),
              side: BorderSide(color: neonGreen.withValues(alpha: 0.3)),
              label: Text("LIVE SYSTEM",
                  style: GoogleFonts.inter(
                      color: neonGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 10)),
              padding: const EdgeInsets.all(0),
            ),
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: neonGreen))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedSection(
                      0, "Portfolio Pulse", Icons.bar_chart_rounded),
                  const SizedBox(height: 15),

                  // --- 1. RESPONSIVE KPI GRID ---
                  // Uses LayoutBuilder to decide between Horizontal Scroll (Mobile) or Grid (Web)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        // Web/Desktop: Grid View
                        return GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.6,
                          physics: const NeverScrollableScrollPhysics(),
                          children: _buildKpiList(),
                        );
                      } else {
                        // Mobile: Horizontal Scroll
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _buildKpiList()
                                .map((e) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 15.0),
                                      child: SizedBox(width: 200, child: e),
                                    ))
                                .toList(),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 30),

                  // --- 2. MAIN CHARTS ---
                  _buildAnimatedSection(1, "Risk Intelligence", Icons.analytics),
                  const SizedBox(height: 15),
                  LayoutBuilder(builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 800;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chart A
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildChartCard(
                            "Education vs Default",
                            "High School grads showing stress",
                            AspectRatio(
                              aspectRatio: isWide ? 1.5 : 1.3,
                              child: _buildBarChart(),
                            ),
                          ),
                        ),
                        if (isWide) const SizedBox(width: 20),
                        if (!isWide) const SizedBox(height: 20),
                        // Chart B
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildChartCard(
                            "Utilization Density",
                            "Red Zones = 80%+ Utilization",
                            AspectRatio(
                              aspectRatio: isWide ? 1.5 : 1.3,
                              child: _buildLineChart(),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 30),

                  // --- 3. BOTTOM SECTION (Donut + Live Feed) ---
                  LayoutBuilder(builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 800;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Donut Chart
                        Container(
                          width: isWide ? 350 : double.infinity,
                          margin: EdgeInsets.only(bottom: isWide ? 0 : 20),
                          child: _buildChartCard(
                            "Payment Status",
                            "Current active portfolio",
                            AspectRatio(
                                aspectRatio: 1.2, child: _buildPieChart()),
                          ),
                        ),
                        if (isWide) const SizedBox(width: 20),
                        // Live Feed
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildLiveFeedCard(),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  // --- 1. WIDGET BUILDERS: ANIMATIONS ---
  Widget _buildAnimatedSection(int index, String title, IconData icon) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _controller,
              curve: Interval(index * 0.2, 1.0, curve: Curves.easeOut))),
      child: FadeTransition(
        opacity: _controller,
        child: Row(
          children: [
            Icon(icon, color: neonGreen, size: 20),
            const SizedBox(width: 8),
            Text(title.toUpperCase(),
                style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  // --- 2. WIDGET BUILDERS: CARDS ---
  List<Widget> _buildKpiList() {
    return [
      _buildKpiCard("Exposure", "NT\$ 1.54B", "+2.4%",
          Icons.account_balance_wallet, false),
      _buildKpiCard("Risk Score", "22.1%", "+1.2%", Icons.warning, true),
      _buildKpiCard(
          "Avg Limit", "NT\$ 167k", "-0.5%", Icons.credit_card, false),
      _buildKpiCard(
          "Delinquency", "14.5%", "+0.8%", Icons.trending_down, true),
    ];
  }

  Widget _buildKpiCard(
      String title, String value, String delta, IconData icon, bool isBad) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.grey[500], size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isBad ? neonRed : neonGreen).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(delta,
                    style: GoogleFonts.inter(
                        color: isBad ? neonRed : neonGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.inter(
                  color: textWhite, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title,
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, String subtitle, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  color: textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtitle,
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 24),
          chart,
        ],
      ),
    );
  }

  Widget _buildLiveFeedCard() {
    List<dynamic> feed = _data?['live_feed'] ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Recent Activity",
                  style: GoogleFonts.inter(
                      color: textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Icon(Icons.history, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 15),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: feed.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.white.withValues(alpha: 0.05)),
            itemBuilder: (context, index) {
              final item = feed[index];
              bool isHighRisk = item['risk'] == 'High';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: isHighRisk
                      ? neonRed.withValues(alpha: 0.1)
                      : neonGreen.withValues(alpha: 0.1),
                  child: Icon(
                    isHighRisk ? Icons.priority_high : Icons.check,
                    color: isHighRisk ? neonRed : neonGreen,
                    size: 16,
                  ),
                ),
                title: Text(item['id'],
                    style: GoogleFonts.inter(
                        color: textWhite, fontWeight: FontWeight.w600)),
                subtitle: Text("Confidence: ${item['prob']}%",
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                trailing: Text(item['time'],
                    style: GoogleFonts.inter(
                        color: Colors.grey[600], fontSize: 11)),
              );
            },
          )
        ],
      ),
    );
  }

  // --- 3. CHARTS IMPLEMENTATION (Professional) ---

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(getTooltipColor: (_) => cardGrey)),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10);
                String text;
                switch (value.toInt()) {
                  case 0: text = 'Grad'; break;
                  case 1: text = 'Uni'; break;
                  case 2: text = 'HS'; break;
                  case 3: text = 'Oth'; break;
                  default: text = '';
                }
                return SideTitleWidget(meta: meta, child: Text(text, style: style));
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1)),
        barGroups: [
          _makeBarGroup(0, 12, neonGreen),
          _makeBarGroup(1, 45, neonRed),
          _makeBarGroup(2, 38, neonRed),
          _makeBarGroup(3, 5, Colors.blue),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        color: color,
        width: 16,
        borderRadius: BorderRadius.circular(4),
        backDrawRodData: BackgroundBarChartRodData(
            show: true, toY: 50, color: Colors.black.withValues(alpha: 0.2)),
      )
    ]);
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // RED LINE (Risky)
          LineChartBarData(
            spots: const [
              FlSpot(0, 1), FlSpot(2, 4), FlSpot(4, 8), FlSpot(6, 6), FlSpot(8, 9)
            ],
            isCurved: true,
            color: neonRed,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  neonRed.withValues(alpha: 0.3),
                  neonRed.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // GREEN LINE (Safe)
          LineChartBarData(
            spots: const [
              FlSpot(0, 5), FlSpot(2, 6), FlSpot(4, 3), FlSpot(6, 2), FlSpot(8, 1)
            ],
            isCurved: true,
            color: neonGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  neonGreen.withValues(alpha: 0.3),
                  neonGreen.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40, // Makes it a Donut
        startDegreeOffset: 180,
        sections: [
          PieChartSectionData(
            color: neonGreen,
            value: 40,
            title: '40%',
            radius: 20,
            titleStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10, color: textWhite),
          ),
          PieChartSectionData(
            color: Colors.blueAccent,
            value: 35,
            title: '35%',
            radius: 20,
            titleStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10, color: textWhite),
          ),
          PieChartSectionData(
            color: neonRed,
            value: 25,
            title: '25%',
            radius: 25, // Slightly pop out the bad one
            titleStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10, color: textWhite),
          ),
        ],
      ),
    );
  }
}