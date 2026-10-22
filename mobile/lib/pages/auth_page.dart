import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets.dart';
import '../yclients.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.onDone, this.allowSkip = true});

  final VoidCallback? onDone;
  final bool allowSkip;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController(text: '+7');
  final _email = TextEditingController();
  var _busy = false;
  var _error = '';
  var _filled = false;
  var _success = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    final store = ClinicScope.of(context);
    if (store.profileName.trim().isNotEmpty) _name.text = store.profileName;
    if (store.profilePhone.trim().isNotEmpty) {
      _phone.text = formatRuPhone(store.profilePhone);
    }
    if (store.profileEmail.trim().isNotEmpty) _email.text = store.profileEmail;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final store = ClinicScope.of(context);
    setState(() {
      _busy = true;
      _error = '';
    });
    final error = await store.registerWithPhone(
      name: _name.text,
      phone: _phone.text,
      email: _email.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error ?? '';
      _success = error == null;
    });
    if (error == null) {
      HapticFeedback.mediumImpact();
    }
  }

  void _finish() {
    widget.onDone?.call();
    if (widget.onDone == null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.allowSkip && widget.onDone == null && !_success
          ? AppBar(title: const Text('Вход'))
          : null,
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            children: [
            Text(
              'CULT',
              style: cultHeadline(40).copyWith(letterSpacing: 4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: _success
                  ? _SuccessCard(onContinue: _finish)
                  : _FormCard(
                      key: const ValueKey('form'),
                      name: _name,
                      phone: _phone,
                      email: _email,
                      busy: _busy,
                      error: _error,
                      onSubmit: _submit,
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              'EXCLUSIVE CLINICAL SANCTUARY',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Cult.muted.withValues(alpha: 0.7),
                letterSpacing: 2.2,
                fontSize: 10,
              ),
            ),
            if (widget.allowSkip && !_success)
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        cultTapFeedback();
                        if (widget.onDone != null) {
                          widget.onDone!();
                        } else if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop(false);
                        }
                      },
                child: const Text('Продолжить без входа'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.busy,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final bool busy;
  final String error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return CultCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'WELCOME BONUS',
            style: TextStyle(
              color: Cult.secondary,
              letterSpacing: 1.6,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text('Подарок для новых клиентов', style: cultHeadline(26)),
          const SizedBox(height: 8),
          const Text.rich(
            TextSpan(
              style: TextStyle(color: Cult.muted, height: 1.4),
              children: [
                TextSpan(
                  text: 'Зарегистрируйтесь по номеру телефона и получите ',
                ),
                TextSpan(
                  text: '3 000 ₽',
                  style: TextStyle(
                    color: Cult.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' на бонусный счёт.'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AutofillGroup(
            child: Column(
              children: [
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(labelText: 'Имя'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: const [CultPhoneInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Номер телефона',
                    hintText: '+7 (___) ___-__-__',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Почта, по желанию',
                  ),
                  onSubmitted: (_) {
                    if (!busy) onSubmit();
                  },
                ),
              ],
            ),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            CultErrorBanner(message: error),
          ],
          const SizedBox(height: 18),
          CultButton(
            label: busy ? 'Сохраняем' : 'Получить бонус',
            onPressed: busy ? null : onSubmit,
          ),
          const SizedBox(height: 10),
          const Text(
            'Нажимая кнопку, вы соглашаетесь с правилами бонусной программы и обработкой персональных данных.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Cult.muted, fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return CultCard(
      key: const ValueKey('success'),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF3EFEA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Cult.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 18),
          Text('Бонус начислен!', style: cultHeadline(26)),
          const SizedBox(height: 8),
          const Text(
            'Баланс пополнен на 3 000 ₽. Профиль сохранён в филиале CULT Сочи.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Cult.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          CultButton(label: 'Перейти в личный кабинет', onPressed: onContinue),
          TextButton(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(
                  text: 'Welcome-бонус CULT: 3 000 ₽ на балансе',
                ),
              );
              cultTapFeedback();
              showCultSnack(context, 'Бонус скопирован');
            },
            child: const Text('Скопировать про бонус'),
          ),
        ],
      ),
    );
  }
}
