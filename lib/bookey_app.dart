import 'package:flutter/material.dart';

import 'package:bookey/bookey_shell.dart';
import 'package:bookey/constants.dart';

class BookeyApp extends StatelessWidget {
  const BookeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: frame,
      brightness: Brightness.light,
    ).copyWith(primary: frame, secondary: accentYellow, surface: panel);

    return MaterialApp(
      title: 'Bookey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const BookeyShell(),
    );
  }
}
