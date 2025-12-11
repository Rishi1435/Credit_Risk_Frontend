// services/dashboard_service.dart
// import 'dart:convert'; // Uncomment when using real API
// import 'package:http/http.dart' as http; // Uncomment when using real API

class DashboardService {
  // TODO: Create a route in your Node.js backend: /api/dashboard-stats
  final String apiUrl = "https://credit-risk-system-ry83.onrender.com/api/dashboard-stats";

  Future<Map<String, dynamic>> fetchDashboardData() async {
    // SIMULATED DATA
    // In the future: final response = await http.get(Uri.parse(apiUrl));
    
    await Future.delayed(const Duration(seconds: 1)); 

    return {
      "kpi": {
        "exposure": 1540000000, 
        "risk_score": 22.1,
        "avg_limit": 167000,
        "delinquency": 14.5
      },
      "demographics": [
        {"label": "Grad", "value": 12}, 
        {"label": "Uni", "value": 45},  
        {"label": "HS", "value": 38},   
        {"label": "Other", "value": 5},
      ],
      "utilization": {
        "safe": [0.1, 0.2, 0.15, 0.05, 0.02],
        "risky": [0.05, 0.1, 0.2, 0.45, 0.2], 
      },
      "live_feed": [
        {"id": "USER_9921", "risk": "High", "prob": 92.4, "time": "2 min ago"},
        {"id": "USER_8812", "risk": "High", "prob": 88.1, "time": "5 min ago"},
        {"id": "USER_7734", "risk": "Med", "prob": 65.0, "time": "12 min ago"},
        {"id": "USER_1209", "risk": "High", "prob": 99.1, "time": "15 min ago"},
      ]
    };
  }
}