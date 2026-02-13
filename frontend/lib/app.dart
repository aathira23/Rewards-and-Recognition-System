/// "The root widget of the application, configuring themes, localizations, and initial navigation."
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';

class RRApp extends StatelessWidget {
  const RRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rewards & Recognition',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // TODO: Implement Routing (using GoRouter or AutoRouter)
      home: const LoginPage(),
    );
  }
}
