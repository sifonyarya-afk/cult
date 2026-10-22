import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';
import 'store.dart';
import 'theme.dart';

class ClinicScope extends InheritedNotifier<ClinicStore> {
  const ClinicScope({
    super.key,
    required ClinicStore store,
    required super.child,
  }) : super(notifier: store);

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
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Cult.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Cult.ink.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: onPressed,
        child: Text(label.toUpperCase()),
      ),
    );
  }
}

class CultSelect extends StatelessWidget {
  const CultSelect({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint = 'Выбрать',
  });

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
                      Text(
                        label,
                        style: const TextStyle(color: Cult.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        empty ? hint : value,
                        style: TextStyle(
                          color: empty ? Cult.muted : Cult.ink,
                          fontSize: 16,
                        ),
                      ),
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
  const CultCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

Future<void> openExternal(String url, {BuildContext? context}) async {
  final uri = Uri.parse(url);
  final ok =
      await canLaunchUrl(uri) &&
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context != null && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Не удалось открыть ссылку')));
  }
}

class CultLoading extends StatelessWidget {
  const CultLoading({super.key, this.label = 'Обновляем филиал…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const LinearProgressIndicator(
            color: Cult.primary,
            backgroundColor: Color(0xFFE8E0D6),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Cult.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

class CultErrorBanner extends StatelessWidget {
  const CultErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Повторить',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8E8E6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: Cult.error, height: 1.35),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 4),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Cult.primary,
                padding: EdgeInsets.zero,
              ),
              onPressed: onRetry,
              child: Text(retryLabel),
            ),
          ],
        ],
      ),
    );
  }
}

void pushPage(BuildContext context, Widget page) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, animation, _) => page,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class CultEmpty extends StatelessWidget {
  const CultEmpty({
    super.key,
    required this.title,
    this.note = '',
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String note;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return CultCard(
      child: Column(
        children: [
          Text(title, style: cultHeadline(22), textAlign: TextAlign.center),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Cult.muted, height: 1.4),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            CultButton(label: actionLabel!, onPressed: onAction!),
          ],
        ],
      ),
    );
  }
}

class CultSectionLabel extends StatelessWidget {
  const CultSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Cult.muted,
        letterSpacing: 1.5,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
