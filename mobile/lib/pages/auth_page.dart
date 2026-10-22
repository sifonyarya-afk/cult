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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    final store = ClinicScope.of(context);
    if (store.profileName.trim().isNotEmpty) _name.text = store.profileName;
    if (store.profilePhone.trim().isNotEmpty) {
      final digits = normalizePhone(store.profilePhone);
      _phone.text = digits.length >= 11 ? '+$digits' : store.profilePhone;
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
    });
    if (error == null) {
      widget.onDone?.call();
      if (widget.onDone == null && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.allowSkip && widget.onDone == null ? AppBar(title: const Text('Вход')) : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            Text('CULT', style: cultHeadline(40).copyWith(letterSpacing: 4), textAlign: TextAlign.center),
            const SizedBox(height: 18),
            CultCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('WELCOME BONUS', style: TextStyle(color: Cult.secondary, letterSpacing: 1.6, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Подарок новым клиентам', style: cultHeadline(26)),
                  const SizedBox(height: 8),
                  const Text(
                    'Войдите по телефону — сохраним вас в филиале Сочи и начислим 3 000 ₽ на бонусный счёт.',
                    style: TextStyle(color: Cult.muted, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Имя'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]'))],
                    decoration: const InputDecoration(labelText: 'Номер телефона', hintText: '+7 (___) ___-__-__', prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(labelText: 'Почта, по желанию'),
                    onSubmitted: (_) {
                      if (!_busy) _submit();
                    },
                  ),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8E8E6), borderRadius: BorderRadius.circular(12)),
                      child: Text(_error, style: const TextStyle(color: Cult.error)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  CultButton(
                    label: _busy ? 'Сохраняем' : 'Получить бонус',
                    onPressed: () {
                      if (!_busy) _submit();
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Нажимая кнопку, вы принимаете правила бонусной программы и обработку данных.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Cult.muted, fontSize: 11, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'EXCLUSIVE CLINICAL SANCTUARY',
              textAlign: TextAlign.center,
              style: TextStyle(color: Cult.muted.withValues(alpha: 0.7), letterSpacing: 2.2, fontSize: 10),
            ),
            if (widget.allowSkip)
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
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
    );
  }
}
