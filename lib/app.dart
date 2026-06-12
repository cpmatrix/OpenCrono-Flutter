import 'package:flutter/material.dart';

import 'features/auth/pages/login_page.dart';
import 'shared/theme/app_theme.dart';

class OpenCronoApp extends StatelessWidget {
  const OpenCronoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenCrono',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const LoginPage(),
    );
  }
}
