import 'package:flutter/material.dart';

class Cult {
  static const bg = Color(0xFFFBF9F8);
  static const ink = Color(0xFF1B1C1C);
  static const primary = Color(0xFF6E5B43);
  static const secondary = Color(0xFF775A19);
  static const gold = Color(0xFFFED488);
  static const sand = Color(0xFFD7BEA0);
  static const line = Color(0xFFD0C5B9);
  static const muted = Color(0xFF7F766C);
  static const error = Color(0xFFBA1A1A);
}

ThemeData cultTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Cult.bg,
    colorScheme: const ColorScheme.light(
      primary: Cult.primary,
      onPrimary: Colors.white,
      secondary: Cult.secondary,
      onSecondary: Colors.white,
      secondaryContainer: Cult.gold,
      surface: Cult.bg,
      error: Cult.error,
    ),
    dividerColor: Cult.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: Cult.bg,
      foregroundColor: Cult.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: 'serif', fontSize: 22, color: Cult.ink),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Cult.sand,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          color: states.contains(WidgetState.selected) ? Cult.primary : Cult.muted,
        ),
      ),
    ),
  );
  return base;
}

TextStyle cultHeadline(double size) => TextStyle(
      fontFamily: 'serif',
      fontSize: size,
      height: 1.15,
      fontWeight: FontWeight.w500,
      color: Cult.ink,
    );

String rub(int value) {
  final raw = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('\u00A0');
    buffer.write(raw[i]);
  }
  final sign = value < 0 ? '−' : '';
  return '$sign$buffer\u00A0₽';
}

String formatVisitDate(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) return iso;
  return '$day ${months[month - 1]}';
}
