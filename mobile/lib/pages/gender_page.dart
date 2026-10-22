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
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('CULT', style: cultHeadline(40).copyWith(letterSpacing: 4), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Для кого подбираем услуги?', style: cultHeadline(28), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'Каталог, прайс и запись покажут женские или мужские протоколы. Потом можно сменить в кабинете.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Cult.muted),
              ),
              const Spacer(),
              _GenderChoice(
                title: 'Женщина',
                note: 'Эстетика, инъекции и уходы',
                accent: Cult.gold,
                onTap: () => _pick(context, ClientGender.woman),
              ),
              const SizedBox(height: 14),
              _GenderChoice(
                title: 'Мужчина',
                note: 'Мужские уходы и протоколы',
                accent: Cult.sand,
                onTap: () => _pick(context, ClientGender.man),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderChoice extends StatelessWidget {
  const _GenderChoice({required this.title, required this.note, required this.accent, required this.onTap});

  final String title;
  final String note;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Cult.line),
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 56,
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: cultHeadline(26)),
                    const SizedBox(height: 4),
                    Text(note, style: const TextStyle(color: Cult.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Cult.muted),
            ],
          ),
        ),
      ),
    );
  }
}
