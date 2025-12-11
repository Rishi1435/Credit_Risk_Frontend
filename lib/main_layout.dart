import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
import 'screens/form_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    LoanApplicationScreen(),
  ];

  // Colors matching Form/Dashboard exactly
  final Color bgBlack = const Color(0xFF121212);
  final Color cardGrey = const Color(0xFF1E1E1E);
  final Color neonGreen = const Color(0xFF00E676);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildWebLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: bgBlack,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        // Remove visible top border for cleaner look
        decoration: BoxDecoration(
          color: cardGrey,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: NavigationBar(
          backgroundColor: cardGrey,
          indicatorColor: neonGreen.withValues(alpha: 0.2),
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          height: 65,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.grid_view, color: Colors.grey),
              selectedIcon: Icon(Icons.grid_view_rounded, color: neonGreen),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
              selectedIcon: Icon(Icons.add_circle, color: neonGreen),
              label: 'New Risk Check',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: bgBlack,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: cardGrey,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            extended: true,
            minExtendedWidth: 200,
            selectedIconTheme: IconThemeData(color: neonGreen),
            unselectedIconTheme: const IconThemeData(color: Colors.grey),
            selectedLabelTextStyle: GoogleFonts.inter(
                color: neonGreen, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: GoogleFonts.inter(color: Colors.grey),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hub, color: neonGreen, size: 28),
                  const SizedBox(width: 10),
                  Text("CREDITFLOW", 
                    style: GoogleFonts.inter(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2
                    )
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.grid_view),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                label: Text('New Assessment'),
              ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1, color: Colors.white.withValues(alpha: 0.05)),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}