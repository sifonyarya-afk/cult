import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class GenderPage extends StatelessWidget {
  const GenderPage({super.key, this.onDone});

  final VoidCallback? onDone;

  Future<void> _pick(BuildContext context, ClientGender gender) async {
    await ClinicScope.of(context).setGender(gender);
    onDone?.call();
    if (onDone == null && context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(gender);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('CULT', style: cultHeadline(42).copyWith(letterSpacing: 6), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              const Center(child: SizedBox(width: 36, height: 2, child: ColoredBox(color: Cult.gold))),
              const SizedBox(height: 28),
              Text('Для кого протокол?', style: cultHeadline(30), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'Подберём женский или мужской каталог. Сменить можно в профиле.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Cult.muted, height: 1.4),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: _GenderChoice(
                  title: 'Женщина',
                  note: 'Эстетика · инъекции · уходы',
                  image: 'sculpt',
                  accent: Cult.gold,
                  onTap: () => _pick(context, ClientGender.woman),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _GenderChoice(
                  title: 'Мужчина',
                  note: 'Мужские уходы · протоколы',
                  image: 'tone',
                  accent: Cult.sand,
                  onTap: () => _pick(context, ClientGender.man),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'EXCLUSIVE CLINICAL SANCTUARY',
                textAlign: TextAlign.center,
                style: TextStyle(color: Cult.muted.withValues(alpha: 0.7), letterSpacing: 2.2, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderChoice extends StatelessWidget {
  const _GenderChoice({
    required this.title,
    required this.note,
    required this.image,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String note;
  final String image;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Cult.line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: ColoredBox(
                  color: accent.withValues(alpha: 0.25),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        photo[image] ?? photo['logo']!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(color: accent.withValues(alpha: 0.35)),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(width: 6, color: accent),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: cultHeadline(28)),
                      const SizedBox(height: 6),
                      Text(note, style: const TextStyle(color: Cult.muted, height: 1.35)),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          Text(
                            'ВЫБРАТЬ',
                            style: TextStyle(color: Cult.secondary, letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 16, color: Cult.secondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
