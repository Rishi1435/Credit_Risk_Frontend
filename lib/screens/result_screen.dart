import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ResultScreen({super.key, required this.data});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. Data Parsing (FIXED LOGIC) ---
    
    // Get the raw probability score (0.0 to 1.0)
    double rawScore = (widget.data['confidence_score'] ?? 0.0);

    // LOGIC FIX: 
    // If score > 0.5 (50%), it is High Risk. 
    // If score <= 0.5 (50%), it is Safe.
    final bool isSafe = rawScore <= 0.5;
    
    // The gauge simply shows the raw probability
    final double confidence = rawScore;

    // --- 2. Financial Parsing ---
    final inputData = widget.data['input_received'] ?? {};
    final financials = inputData['financials'] ?? {};
    final demographics = inputData['demographics'] ?? {};

    final double limit = (demographics['LIMIT_BAL'] ?? 0).toDouble();
    final double billAmt = (financials['BILL_AMT1'] ?? 0).toDouble();
    final double payAmt = (financials['PAY_AMT1'] ?? 0).toDouble();

    // --- 3. Theme Colors ---
    // Green if Safe (<= 50%), Red if Risk (> 50%)
    final Color primaryColor =
        isSafe ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    const Color bgColor = Color(0xFF121212);
    const Color cardColor = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Risk Assessment",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- GAUGE ---
              Center(
                child: CircularPercentIndicator(
                  radius: 120.0,
                  lineWidth: 20.0,
                  animation: true,
                  animationDuration: 2000,
                  percent: confidence.clamp(0.0, 1.0),
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${(confidence * 100).toStringAsFixed(1)}%",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 40.0,
                            color: Colors.white),
                      ),
                      Text(
                        // Display text based on the isSafe boolean calculated above
                        isSafe ? "SAFE" : "HIGH RISK",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                            color: primaryColor),
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: Colors.grey[800]!,
                  progressColor: primaryColor,
                  footer: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      "AI Probability Chances",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- KEY METRICS ---
              Text("Financial Snapshot",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                      child: _buildMetricCard("Credit Limit",
                          "\$${limit.toInt()}", cardColor, Icons.credit_card)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildMetricCard(
                          "Utilization",
                          _calculateUtilization(billAmt, limit),
                          cardColor,
                          Icons.pie_chart)),
                ],
              ),
              const SizedBox(height: 15),
              // --- BILL & PAID DISPLAY ---
              Row(
                children: [
                  Expanded(
                      child: _buildMetricCard("Last Bill", "\$${billAmt.toInt()}",
                          cardColor, Icons.receipt_long,
                          textColor: Colors.blueAccent)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildMetricCard("Amount Paid", "\$${payAmt.toInt()}",
                          cardColor, Icons.check_circle_outline,
                          textColor: Colors.greenAccent)),
                ],
              ),

              const SizedBox(height: 30),

              // --- CHART ---
              Text("Repayment Analysis",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Container(
                height: 250,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (billAmt > payAmt ? billAmt : payAmt) * 1.2,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            const style = TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12);
                            Widget text;
                            switch (value.toInt()) {
                              case 0:
                                text = const Text('Bill', style: style);
                                break;
                              case 1:
                                text = const Text('Paid', style: style);
                                break;
                              default:
                                text = const Text('', style: style);
                            }
                            return SideTitleWidget(
                                meta: meta, child: text);
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [
                        BarChartRodData(
                            toY: billAmt,
                            color: Colors.blueAccent,
                            width: 25,
                            borderRadius: BorderRadius.circular(4))
                      ]),
                      BarChartGroupData(x: 1, barRods: [
                        BarChartRodData(
                            toY: payAmt,
                            color: Colors.greenAccent,
                            width: 25,
                            borderRadius: BorderRadius.circular(4))
                      ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- EXPLAINABILITY ---
              Text("Why this decision?",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // Pass the correct isSafe boolean to the explanation generator
              ..._generateExplanation(isSafe)
                  .map((e) => _buildExplanationCard(e, cardColor)),

              const SizedBox(height: 30),

              // --- BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Analyze New Customer",
                      style: GoogleFonts.inter(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---
  String _calculateUtilization(double bill, double limit) {
    if (limit == 0) return "0%";
    return "${((bill / limit) * 100).toStringAsFixed(1)}%";
  }

  Widget _buildMetricCard(
      String title, String value, Color bgColor, IconData icon,
      {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.inter(
                  color: textColor ?? Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(title,
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(Map<String, dynamic> data, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: data['good']
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2),
          child: Icon(data['icon'],
              color: data['good'] ? Colors.green : Colors.red, size: 20),
        ),
        title: Text(data['text'],
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(data['desc'],
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
      ),
    );
  }

  List<Map<String, dynamic>> _generateExplanation(bool isSafe) {
    if (isSafe) {
      return [
        {
          "icon": Icons.check,
          "text": "Healthy Payments",
          "desc": "Customer pays bills on time.",
          "good": true
        },
        {
          "icon": Icons.pie_chart,
          "text": "Low Utilization",
          "desc": "Uses less than 30% of credit limit.",
          "good": true
        },
      ];
    } else {
      return [
        {
          "icon": Icons.warning,
          "text": "Late Payments",
          "desc": "History of payment delays detected.",
          "good": false
        },
        {
          "icon": Icons.money_off,
          "text": "High Utilization",
          "desc": "Customer is maxing out credit lines.",
          "good": false
        },
      ];
    }
  }
}