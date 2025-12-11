import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  final String apiUrl = "https://credit-risk-system-ry83.onrender.com/api/get-all";

  Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> rawData = jsonDecode(response.body);
        return _processData(rawData);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching dashboard data: $e");
      return {}; 
    }
  }

  Map<String, dynamic> _processData(List<dynamic> data) {
    if (data.isEmpty) return {};

    double totalExposure = 0;
    double totalLimit = 0;
    int defaultCount = 0;
    int delinquencyCount = 0;
    
    Map<int, int> eduCounts = {1: 0, 2: 0, 3: 0, 4: 0};
    
    List<double> safeUtilization = [];
    List<double> riskyUtilization = [];
    List<Map<String, dynamic>> liveFeed = [];

    // Sort by timestamp (newest first)
    data.sort((a, b) {
      String tA = a['timestamp'] ?? DateTime.now().toString();
      String tB = b['timestamp'] ?? DateTime.now().toString();
      return DateTime.parse(tB).compareTo(DateTime.parse(tA));
    });

    for (var item in data) {
      // KPI Calcs
      double limit = (item['LIMIT_BAL'] ?? 0).toDouble();
      totalExposure += limit;
      totalLimit += limit;

      String prediction = item['risk_prediction'] ?? "No Default";
      bool isDefault = prediction == "Default";
      if (isDefault) defaultCount++;

      int pay1 = (item['PAY_1'] ?? 0);
      if (pay1 > 0) delinquencyCount++;

      // Demographics
      int edu = (item['EDUCATION'] ?? 4);
      if (eduCounts.containsKey(edu)) {
        eduCounts[edu] = eduCounts[edu]! + 1;
      } else {
        eduCounts[4] = eduCounts[4]! + 1;
      }

      // Utilization
      double util = (item['Utilization_Sept'] ?? 0).toDouble();
      if (isDefault) {
        riskyUtilization.add(util);
      } else {
        safeUtilization.add(util);
      }

      // Live Feed
      if (liveFeed.length < 20) {
        double prob = (item['confidence_score'] ?? 0.0) * 100;
        
        liveFeed.add({
          "id": "ID_${(item['_id'] ?? 'Unknown').substring(0, 6).toUpperCase()}",
          "risk": isDefault ? "High" : "Safe",
          "prob": prob.toStringAsFixed(1),
          "time": _calculateTimeAgo(item['timestamp']),
          "raw": item, // <--- IMPORTANT: Storing full data here for the click action
        });
      }
    }

    int totalCount = data.length;
    double avgLimit = totalCount > 0 ? totalLimit / totalCount : 0;
    double riskScore = totalCount > 0 ? (defaultCount / totalCount) * 100 : 0;
    double delinquencyRate = totalCount > 0 ? (delinquencyCount / totalCount) * 100 : 0;

    return {
      "kpi": {
        "exposure": totalExposure, 
        "risk_score": riskScore,
        "avg_limit": avgLimit,
        "delinquency": delinquencyRate
      },
      "demographics": [
        {"label": "Grad", "value": eduCounts[1]}, 
        {"label": "Uni", "value": eduCounts[2]},  
        {"label": "HS", "value": eduCounts[3]},   
        {"label": "Other", "value": eduCounts[4]},
      ],
      "utilization": {
        "safe": safeUtilization.take(20).toList(), 
        "risky": riskyUtilization.take(20).toList(), 
      },
      "live_feed": liveFeed
    };
  }

  String _calculateTimeAgo(String? timestamp) {
    if (timestamp == null) return "Just now";
    try {
      final DateTime eventTime = DateTime.parse(timestamp);
      final Duration diff = DateTime.now().difference(eventTime);

      if (diff.inDays > 0) return "${diff.inDays}d ago";
      if (diff.inHours > 0) return "${diff.inHours}h ago";
      if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
      return "Just now";
    } catch (e) {
      return "Unknown";
    }
  }
}