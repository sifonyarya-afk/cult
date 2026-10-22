import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class GenderPage extends StatefulWidget {
  const GenderPage({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  State<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage> {
  ClientGender? _selected;

  Future<void> _start() async {
    final gender = _selected;
    if (gender == null) return;
    HapticFeedback.mediumImpact();
    await ClinicScope.of(context).setGender(gender);
    widget.onDone?.call();
    if (widget.onDone == null && mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(gender);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cult.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/media/gender-bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Image.asset(
              photo['interior'] ?? photo['logo']!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFF2C2A28)),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x661B1C1C),
                  Color(0x991B1C1C),
                  Color(0xCC1B1C1C),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
              child: Column(
                children: [
                  Text(
                    'CULT',
                    style: cultHeadline(40).copyWith(
                      color: Colors.white,
                      letterSpacing: 10,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(color: Color(0x66000000), blurRadius: 12),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Ваш путь к совершенству\nначинается в CULT',
                        textAlign: TextAlign.center,
                        style: cultHeadline(28).copyWith(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                          shadows: const [
                            Shadow(color: Color(0x66000000), blurRadius: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    label: 'Выбор профиля услуг',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GenderCircle(
                          label: 'Мужчина',
                          icon: Icons.male,
                          selected: _selected == ClientGender.man,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selected = ClientGender.man);
                          },
                        ),
                        const SizedBox(width: 36),
                        _GenderCircle(
                          label: 'Женщина',
                          icon: Icons.female,
                          selected: _selected == ClientGender.woman,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selected = ClientGender.woman);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Cult.ink,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Cult.ink.withValues(
                          alpha: 0.55,
                        ),
                        disabledForegroundColor: Colors.white54,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          letterSpacing: 3.2,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: _selected == null ? null : _start,
                      child: const Text('НАЧАТЬ'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Персональная косметология для каждого',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                      fontFamily: 'serif',
                      fontSize: 15,
                      shadows: const [
                        Shadow(color: Color(0x55000000), blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderCircle extends StatelessWidget {
  const _GenderCircle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: selected ? 0.28 : 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: selected ? 0.85 : 0.35),
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              letterSpacing: 2.4,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
