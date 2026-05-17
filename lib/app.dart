// lib/app.dart

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/raid/presentation/pages/main_dashboard.dart';

class AetherApp extends StatelessWidget {
  const AetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Aether',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainDashboard(),
    );
  }
}
