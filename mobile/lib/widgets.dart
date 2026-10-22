import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';
import 'store.dart';
import 'theme.dart';

class ClinicScope extends InheritedNotifier<ClinicStore> {
  const ClinicScope({super.key, required ClinicStore store, required super.child}) : super(notifier: store);

  static ClinicStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ClinicScope>();
    assert(scope != null, 'ClinicScope не найден');
    return scope!.notifier!;
  }
}

class CultImage extends StatelessWidget {
  const CultImage(this.name, {super.key, this.aspect = 4 / 5, this.radius = 0});

  final String name;
  final double aspect;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final child = AspectRatio(
      aspectRatio: aspect,
      child: Image.asset(
        photo[name] ?? photo['logo']!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(color: Cult.sand),
      ),
    );
    if (radius == 0) return child;
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}

class CultButton extends StatelessWidget {
  const CultButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Cult.ink,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        child: Text(label.toUpperCase()),
      ),
    );
  }
}

class CultSelect extends StatelessWidget {
  const CultSelect({super.key, required this.label, required this.value, required this.onTap, this.hint = 'Выбрать'});

  final String label;
  final String value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Cult.muted, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(empty ? hint : value, style: TextStyle(color: empty ? Cult.muted : Cult.ink, fontSize: 16)),
                    ],
                  ),
                ),
                const Icon(Icons.expand_more, color: Cult.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CultCard extends StatelessWidget {
  const CultCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: child,
    );
  }
}

Future<void> openExternal(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

void pushPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
