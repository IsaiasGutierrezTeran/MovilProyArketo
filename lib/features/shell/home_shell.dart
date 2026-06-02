import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../ai/ai_design_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../projects/projects_screen.dart';
import '../sketch_2d/sketch_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  static const _tabs = [
    DashboardScreen(),
    ProjectsScreen(),
    AiDesignScreen(),
    SketchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(child: SafeArea(child: IndexedStack(index: _index, children: _tabs))),
      bottomNavigationBar: NavigationBar(
        backgroundColor: kSurface,
        indicatorColor: kPrimary.withValues(alpha: 0.18),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Proyectos'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Diseño IA'),
          NavigationDestination(icon: Icon(Icons.draw_outlined), selectedIcon: Icon(Icons.draw), label: 'Boceto'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
