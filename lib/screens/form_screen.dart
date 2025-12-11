import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../config.dart';
import 'result_screen.dart';

class LoanApplicationScreen extends StatefulWidget {
  const LoanApplicationScreen({super.key});

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;

  // Controllers
  final _limitBalController = TextEditingController();
  final _ageController = TextEditingController();
  final _billAmtController = TextEditingController();
  final _payAmtController = TextEditingController();

  int? _sex = 2;
  int? _education = 2;
  int? _marriage = 1;
  double _pay1Status = 0;

  final Color _bgColor = const Color(0xFF121212);
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _accentColor = const Color(0xFF00E676);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fillDemoData({bool risky = false}) {
    setState(() {
      if (risky) {
        _limitBalController.text = "10000";
        _ageController.text = "24";
        _sex = 1;
        _education = 3;
        _marriage = 2;
        _pay1Status = 3;
        _billAmtController.text = "9500";
        _payAmtController.text = "0";
      } else {
        _limitBalController.text = "500000";
        _ageController.text = "35";
        _sex = 2;
        _education = 1;
        _marriage = 1;
        _pay1Status = -1;
        _billAmtController.text = "20000";
        _payAmtController.text = "20000";
      }
    });
  }

  Future<void> _analyzeRisk() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      double limit = double.parse(_limitBalController.text);
      double bill1 = double.parse(_billAmtController.text);
      double payAmt1 = double.parse(_payAmtController.text);
      int pay1 = _pay1Status.toInt();

      double utilization = limit > 0 ? (bill1 / limit) : 0;
      double payToBill = bill1 > 0 ? (payAmt1 / bill1) : 1.0;
      int lateCount = pay1 > 0 ? 1 : 0;
      int maxLateness = pay1 > 0 ? pay1 : 0;
      List<double> bills = [bill1, 0, 0, 0, 0, 0];
      double meanBill = bills.reduce((a, b) => a + b) / 6;
      double variance = bills
              .map((b) => (b - meanBill) * (b - meanBill))
              .reduce((a, b) => a + b) /
          6;
      double volatility = variance > 0 ? sqrt(variance) : 0;

      final Map<String, dynamic> payload = {
        "LIMIT_BAL": limit,
        "SEX": _sex,
        "EDUCATION": _education,
        "MARRIAGE": _marriage,
        "AGE": int.parse(_ageController.text),
        "PAY_1": pay1,
        "PAY_2": 0, "PAY_3": 0, "PAY_4": 0, "PAY_5": 0, "PAY_6": 0,
        "BILL_AMT1": bill1,
        "BILL_AMT2": 0.0, "BILL_AMT3": 0.0, "BILL_AMT4": 0.0, "BILL_AMT5": 0.0, "BILL_AMT6": 0.0,
        "PAY_AMT1": payAmt1,
        "PAY_AMT2": 0.0, "PAY_AMT3": 0.0, "PAY_AMT4": 0.0, "PAY_AMT5": 0.0, "PAY_AMT6": 0.0,
        "Utilization_Sept": utilization,
        "Pay_to_Bill_Sept": payToBill,
        "Late_Payment_Count": lateCount,
        "Max_Lateness": maxLateness,
        "Bill_Volatility": volatility,
      };

      // Call API
      final response = await http.post(
        Uri.parse(API_URL),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(payload),
      );

      debugPrint("Status: ${response.statusCode}");
      debugPrint("Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // --- CRITICAL FIX START ---
        // Manually inject the input data so ResultScreen can display it
        // (Since the backend is not echoing it back)
        responseData['input_received'] = {
          'demographics': {'LIMIT_BAL': limit},
          'financials': {'BILL_AMT1': bill1, 'PAY_AMT1': payAmt1}
        };
        // --- CRITICAL FIX END ---

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(data: responseData),
            ),
          );
        }
      } else {
        _showError("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Connection Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text("New Assessment",
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _bgColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high, color: Colors.blueAccent),
            onPressed: _showDemoDialog,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimatedSection(
                  0, "Customer Profile", Icons.person_outline),
              const SizedBox(height: 15),
              _buildAnimatedCard(1, [
                _buildDarkTextField(
                    "Credit Limit (\$)", _limitBalController, Icons.credit_card),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(
                      child: _buildDarkTextField(
                          "Age", _ageController, Icons.cake)),
                  const SizedBox(width: 15),
                  Expanded(
                      child: _buildDarkDropdown(
                          "Gender",
                          _sex,
                          {1: "Male", 2: "Female"},
                          (v) => setState(() => _sex = v))),
                ]),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(
                      child: _buildDarkDropdown(
                          "Education",
                          _education,
                          {1: "Grad", 2: "Uni", 3: "HS", 4: "Other"},
                          (v) => setState(() => _education = v))),
                  const SizedBox(width: 15),
                  Expanded(
                      child: _buildDarkDropdown(
                          "Marriage",
                          _marriage,
                          {1: "Married", 2: "Single", 3: "Other"},
                          (v) => setState(() => _marriage = v))),
                ]),
              ]),
              const SizedBox(height: 30),
              _buildAnimatedSection(2, "Repayment History", Icons.history),
              const SizedBox(height: 15),
              _buildAnimatedCard(3, [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Payment Delay (Months)",
                        style: GoogleFonts.inter(color: Colors.grey)),
                    Text(
                      _pay1Status <= 0
                          ? "Paid On Time"
                          : "${_pay1Status.toInt()} Months Late",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: _pay1Status > 0
                              ? Colors.redAccent
                              : _accentColor),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor:
                        _pay1Status > 0 ? Colors.redAccent : _accentColor,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.1),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _pay1Status,
                    min: -2,
                    max: 8,
                    divisions: 10,
                    onChanged: (v) => setState(() => _pay1Status = v),
                  ),
                ),
              ]),
              const SizedBox(height: 30),
              _buildAnimatedSection(
                  4, "Financials (Sept)", Icons.account_balance_wallet_outlined),
              const SizedBox(height: 15),
              _buildAnimatedCard(5, [
                _buildDarkTextField(
                    "Bill Amount", _billAmtController, Icons.receipt_long),
                const SizedBox(height: 15),
                _buildDarkTextField(
                    "Amount Paid", _payAmtController, Icons.payments_outlined),
              ]),
              const SizedBox(height: 40),
              SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
                )),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_accentColor, Colors.teal]),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                          color: _accentColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _analyzeRisk,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text("Analyze Risk Profile",
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildAnimatedSection(int index, String title, IconData icon) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: _animationController,
        child: Row(children: [
          Icon(icon, color: _accentColor, size: 20),
          const SizedBox(width: 10),
          Text(title,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildAnimatedCard(int index, List<Widget> children) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: _animationController,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildDarkTextField(
      String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _accentColor)),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDarkDropdown(String label, int? value, Map<int, String> items,
      Function(int?) onChanged) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      dropdownColor: const Color(0xFF2C2C2C),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
      items: items.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: onChanged,
    );
  }

  void _showDemoDialog() {
    showDialog(
        context: context,
        builder: (_) => Dialog(
              backgroundColor: _cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Select Persona",
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ListTile(
                      leading:
                          const Icon(Icons.check_circle, color: Colors.green),
                      title: const Text("Safe Customer",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        _fillDemoData(risky: false);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.warning, color: Colors.red),
                      title: const Text("Risky Customer",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        _fillDemoData(risky: true);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ));
  }
}