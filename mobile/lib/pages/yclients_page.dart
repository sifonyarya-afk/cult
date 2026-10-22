import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import '../yclients.dart';

class YClientsPage extends StatefulWidget {
  const YClientsPage({super.key});

  @override
  State<YClientsPage> createState() => _YClientsPageState();
}

class _YClientsPageState extends State<YClientsPage> {
  final _company = TextEditingController();
  final _chain = TextEditingController(text: '0');
  final _partner = TextEditingController();
  final _user = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _login = TextEditingController();
  final _password = TextEditingController();
  var _booted = false;
  var _busy = false;
  var _message = '';
  var _ok = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_booted) return;
    _booted = true;
    final store = ClinicScope.of(context);
    _company.text = store.companyId;
    _chain.text = store.chainId;
    _partner.text = store.partnerToken;
    _user.text = store.userToken;
    _phone.text = store.profilePhone;
    _email.text = store.profileEmail;
  }

  @override
  void dispose() {
    _company.dispose();
    _chain.dispose();
    _partner.dispose();
    _user.dispose();
    _phone.dispose();
    _email.dispose();
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final store = ClinicScope.of(context);
    setState(() {
      _busy = true;
      _message = '';
      _ok = false;
    });
    final error = await store.connectYclients(
      companyId: _company.text,
      chainId: _chain.text,
      partnerToken: _partner.text,
      userToken: _user.text,
      phone: _phone.text,
      email: _email.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _ok = error == null;
      _message = error ?? 'Филиал подключён. Услуг для записи: ${store.liveServices.length}.';
    });
  }

  Future<void> _authorize() async {
    final store = ClinicScope.of(context);
    final partner = _partner.text.trim();
    if (partner.isEmpty || _login.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() {
        _ok = false;
        _message = 'Нужны партнёрский токен, логин и пароль.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final token = await store.yclients.login(partner, _login.text.trim(), _password.text);
      _password.clear();
      if (!mounted) return;
      setState(() {
        _user.text = token;
        _busy = false;
        _ok = true;
        _message = 'Токен пользователя получен. Нажмите «Подключить», чтобы сохранить.';
      });
    } on YcException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _ok = false;
        _message = error.message;
      });
    }
  }

  Future<void> _disconnect() async {
    final store = ClinicScope.of(context);
    await store.disconnectYclients();
    if (!mounted) return;
    setState(() {
      _company.clear();
      _partner.clear();
      _user.clear();
      _chain.text = '0';
      _ok = true;
      _message = 'Филиал отключён. Запись снова сохраняется только в приложении.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('YClients')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Подключение филиала', style: cultHeadline(30)),
          const SizedBox(height: 8),
          const Text(
            'Нужно поле «Токен партнера»: Интеграции → Аккаунт разработчика → Настройки аккаунта → Данные аккаунта. User token из карточки приложения YClients не принимает. ID филиала уже указан. Ключ остаётся только на этом телефоне.',
          ),
          const SizedBox(height: 12),
          Text(store.yclientsReady ? 'Сейчас подключён филиал ${store.companyId}.' : 'Филиал не подключён.'),
          const SizedBox(height: 12),
          TextField(controller: _company, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ID филиала')),
          TextField(controller: _chain, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ID сети, 0 если филиал один')),
          TextField(controller: _partner, obscureText: true, decoration: const InputDecoration(labelText: 'Токен партнера')),
          TextField(controller: _user, obscureText: true, decoration: const InputDecoration(labelText: 'Токен пользователя, если есть')),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Телефон для записи и карты')),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Почта')),
          const SizedBox(height: 8),
          const Text('Токен пользователя нужен для отмены чужих записей и карты лояльности. Его можно получить логином сотрудника и сразу стереть пароль.'),
          TextField(controller: _login, decoration: const InputDecoration(labelText: 'Логин YClients')),
          TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль')),
          TextButton(onPressed: _busy ? null : _authorize, child: const Text('Получить токен пользователя')),
          if (_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_message, style: TextStyle(color: _ok ? Cult.primary : Cult.error)),
            ),
          CultButton(
            label: _busy ? 'Проверяем' : 'Подключить',
            onPressed: () {
              if (!_busy) _connect();
            },
          ),
          if (store.yclientsReady)
            TextButton(onPressed: _busy ? null : _disconnect, child: const Text('Отключить филиал', style: TextStyle(color: Cult.error))),
        ],
      ),
    );
  }
}
