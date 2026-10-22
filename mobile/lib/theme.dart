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
  const radius = 14.0;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: const BorderSide(color: Cult.line),
  );
  return ThemeData(
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
    splashColor: Cult.sand.withValues(alpha: 0.35),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Cult.ink, height: 1.35),
      bodyLarge: TextStyle(color: Cult.ink, height: 1.35),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Cult.bg,
      foregroundColor: Cult.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'serif',
        fontSize: 22,
        letterSpacing: 3,
        color: Cult.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: Cult.muted),
      hintStyle: const TextStyle(color: Cult.muted),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Cult.primary, width: 1.4),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Cult.bg,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: Cult.gold,
      side: const BorderSide(color: Cult.line),
      labelStyle: const TextStyle(color: Cult.ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      height: 68,
      indicatorColor: Cult.sand,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.selected)
              ? Cult.primary
              : Cult.muted,
        ),
      ),
    ),
  );
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
  final clean = iso.trim().split('T').first.split(' ').first;
  final parts = clean.split('-');
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
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2].split('.').first);
  if (year == null ||
      month == null ||
      day == null ||
      month < 1 ||
      month > 12) {
    return iso;
  }
  final visit = DateTime(year, month, day);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final delta = visit.difference(today).inDays;
  if (delta == 0) return 'сегодня';
  if (delta == 1) return 'завтра';
  if (delta == -1) return 'вчера';
  return '$day ${months[month - 1]}';
}

/// Relative countdown to a visit datetime, e.g. `через 3 ч`. Empty if past/invalid.
String formatVisitCountdown(String iso, String time) {
  final clean = iso.trim().split('T').first.split(' ').first;
  final dateParts = clean.split('-');
  if (dateParts.length != 3) return '';
  final year = int.tryParse(dateParts[0]);
  final month = int.tryParse(dateParts[1]);
  final day = int.tryParse(dateParts[2].split('.').first);
  final clock = time.trim().split(':');
  if (year == null ||
      month == null ||
      day == null ||
      clock.isEmpty ||
      month < 1 ||
      month > 12) {
    return '';
  }
  final hour = int.tryParse(clock[0]) ?? 0;
  final minute = clock.length > 1 ? (int.tryParse(clock[1]) ?? 0) : 0;
  final at = DateTime(year, month, day, hour, minute);
  final diff = at.difference(DateTime.now());
  if (diff.isNegative) return '';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes.clamp(1, 59);
    return 'через $m мин';
  }
  if (diff.inHours < 24) return 'через ${diff.inHours} ч';
  if (diff.inDays == 1) return 'завтра';
  return 'через ${diff.inDays} дн.';
}
