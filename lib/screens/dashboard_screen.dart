import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/dashboard_service.dart';
import 'result_screen.dart'; // Import ResultScreen to allow navigation

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

  // --- PALETTE ---
  final Color bgBlack = const Color(0xFF121212);
  final Color cardGrey = const Color(0xFF1E1E1E);
  final Color neonGreen = const Color(0xFF00E676);
  final Color neonRed = const Color(0xFFFF5252);
  final Color textWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    _controller.reset();
    final data = await _service.fetchDashboardData();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
      _controller.forward();
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
          IconButton(
            icon: Icon(Icons.refresh, color: neonGreen),
            tooltip: 'Reload Data',
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
          const SizedBox(width: 8),
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
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
                  _buildAnimatedSection(
                      1, "Risk Intelligence", Icons.analytics),
                  const SizedBox(height: 15),
                  LayoutBuilder(builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 800;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildChartCard(
                            "Education vs Default",
                            "Portfolio distribution by Education",
                            AspectRatio(
                              aspectRatio: isWide ? 1.5 : 1.3,
                              child: _buildBarChart(),
                            ),
                            legends: [
                              _buildLegendItem(neonGreen, "Graduate"),
                              _buildLegendItem(neonRed, "University"),
                              _buildLegendItem(Colors.orange, "High School"),
                              _buildLegendItem(Colors.blue, "Others"),
                            ],
                          ),
                        ),
                        if (isWide) const SizedBox(width: 20),
                        if (!isWide) const SizedBox(height: 20),
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: _buildChartCard(
                            "Utilization Density",
                            "Spending patterns of Safe vs Risky users",
                            AspectRatio(
                              aspectRatio: isWide ? 1.5 : 1.3,
                              child: _buildLineChart(),
                            ),
                            legends: [
                              _buildLegendItem(neonGreen, "Safe Users"),
                              _buildLegendItem(neonRed, "Risky Users"),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 30),
                  LayoutBuilder(builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 800;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: isWide ? 350 : double.infinity,
                          margin: EdgeInsets.only(bottom: isWide ? 0 : 20),
                          child: _buildChartCard(
                            "Payment Status",
                            "Current active portfolio health",
                            AspectRatio(
                                aspectRatio: 1.2, child: _buildPieChart()),
                            legends: [
                              _buildLegendItem(neonGreen, "Paid On-Time"),
                              _buildLegendItem(
                                  Colors.blueAccent, "Active"),
                              _buildLegendItem(neonRed, "Delinquent"),
                            ],
                          ),
                        ),
                        if (isWide) const SizedBox(width: 20),
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

  // --- WIDGET BUILDERS ---

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

  List<Widget> _buildKpiList() {
    final kpi = _data?['kpi'] ?? {};
    double exposure = (kpi['exposure'] ?? 0).toDouble();
    double riskScore = (kpi['risk_score'] ?? 0).toDouble();
    double avgLimit = (kpi['avg_limit'] ?? 0).toDouble();
    double delinquency = (kpi['delinquency'] ?? 0).toDouble();

    return [
      _buildKpiCard(
        "Exposure",
        _formatLargeNumber(exposure),
        "Total",
        Icons.account_balance_wallet,
        false,
      ),
      _buildKpiCard(
        "Risk Score",
        "${riskScore.toStringAsFixed(1)}%",
        riskScore > 15 ? "High" : "Low",
        Icons.warning,
        riskScore > 15,
      ),
      _buildKpiCard(
        "Avg Limit",
        _formatLargeNumber(avgLimit),
        "Per User",
        Icons.credit_card,
        false,
      ),
      _buildKpiCard(
        "Delinquency",
        "${delinquency.toStringAsFixed(1)}%",
        "Late Pays",
        Icons.trending_down,
        true,
      ),
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

  Widget _buildChartCard(String title, String subtitle, Widget chart,
      {List<Widget>? legends}) {
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
          if (legends != null) ...[
            const SizedBox(height: 20),
            Divider(color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 15,
              runSpacing: 10,
              children: legends,
            )
          ]
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 11),
        ),
      ],
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
          if (feed.isEmpty)
             const Text("No recent data", style: TextStyle(color: Colors.grey)),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: feed.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.white.withValues(alpha: 0.05)),
            itemBuilder: (context, index) {
              final item = feed[index];
              bool isHighRisk = item['risk'] == 'High';
              
              // --- INTERACTIVITY: CLICK TO VIEW RESULT ---
              return InkWell(
                onTap: () {
                  // 1. Get the raw MongoDB data we stored in the service
                  final raw = item['raw'] ?? {};
                  
                  // 2. Map flat MongoDB structure to ResultScreen structure
                  final resultData = {
                    'risk_assessment': raw['risk_prediction'] ?? "Default",
                    'confidence_score': (raw['confidence_score'] ?? 0.0),
                    'input_received': {
                      'demographics': {
                        'LIMIT_BAL': raw['LIMIT_BAL']
                      },
                      'financials': {
                        'BILL_AMT1': raw['BILL_AMT1'],
                        'PAY_AMT1': raw['PAY_AMT1'],
                      }
                    }
                  };
                  
                  // 3. Navigate
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => ResultScreen(data: resultData)
                    )
                  );
                },
                child: ListTile(
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
                ),
              );
            },
          )
        ],
      ),
    );
  }

  // --- CHARTS IMPLEMENTATION ---

  Widget _buildBarChart() {
    final demos = _data?['demographics'] as List<dynamic>? ?? [];

    double getValue(String label) {
      final item = demos.firstWhere((e) => e['label'] == label, orElse: () => {'value': 0});
      return (item['value'] as int).toDouble();
    }

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
            touchTooltipData:
                BarTouchTooltipData(getTooltipColor: (_) => cardGrey)),
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
                return SideTitleWidget(
                    meta: meta, child: Text(text, style: style));
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1)),
        barGroups: [
          _makeBarGroup(0, getValue("Grad"), neonGreen),
          _makeBarGroup(1, getValue("Uni"), neonRed),
          _makeBarGroup(2, getValue("HS"), Colors.orange),
          _makeBarGroup(3, getValue("Other"), Colors.blue),
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
            show: true, toY: 100, color: Colors.black.withValues(alpha: 0.2)),
      )
    ]);
  }

  Widget _buildLineChart() {
    final util = _data?['utilization'] ?? {};
    final List<dynamic> safeList = util['safe'] ?? [];
    final List<dynamic> riskyList = util['risky'] ?? [];

    List<FlSpot> toSpots(List<dynamic> list) {
      return list.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), (e.value.toDouble() * 10));
      }).toList();
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: toSpots(riskyList).isEmpty 
              ? [const FlSpot(0, 0)] 
              : toSpots(riskyList),
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
          LineChartBarData(
            spots: toSpots(safeList).isEmpty 
              ? [const FlSpot(0, 0)] 
              : toSpots(safeList),
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
    final kpi = _data?['kpi'] ?? {};
    double delinquency = (kpi['delinquency'] ?? 0).toDouble();
    double riskScore = (kpi['risk_score'] ?? 0).toDouble();
    
    double goodPortion = 100 - (delinquency + riskScore);
    if(goodPortion < 0) goodPortion = 0;

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        startDegreeOffset: 180,
        sections: [
          PieChartSectionData(
            color: neonGreen,
            value: goodPortion,
            title: '${goodPortion.toInt()}%',
            radius: 20,
            titleStyle: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 10, color: textWhite),
          ),
          PieChartSectionData(
            color: Colors.blueAccent,
            value: riskScore,
            title: '${riskScore.toInt()}%',
            radius: 20,
            titleStyle: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 10, color: textWhite),
          ),
          PieChartSectionData(
            color: neonRed,
            value: delinquency,
            title: '${delinquency.toInt()}%',
            radius: 25,
            titleStyle: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 10, color: textWhite),
          ),
        ],
      ),
    );
  }

  String _formatLargeNumber(double num) {
    if (num >= 1000000000) {
      return "\$${(num / 1000000000).toStringAsFixed(2)}B";
    }
    if (num >= 1000000) {
      return "\$${(num / 1000000).toStringAsFixed(2)}M";
    }
    if (num >= 1000) {
      return "\$${(num / 1000).toStringAsFixed(0)}K";
    }
    return "\$${num.toInt()}";
  }
}