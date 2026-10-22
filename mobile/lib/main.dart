import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/auth_page.dart';
import 'pages/browse.dart';
import 'pages/cabinet.dart';
import 'pages/gender_page.dart';
import 'pages/home.dart';
import 'pages/info.dart';
import 'pages/shop.dart';
import 'pages/talk.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = ClinicStore();
  await store.load();
  runApp(CultApp(store: store));
}

class CultApp extends StatelessWidget {
  const CultApp({super.key, required this.store, this.splash = const Duration(milliseconds: 2600)});

  final ClinicStore store;
  final Duration splash;

  @override
  Widget build(BuildContext context) {
    return ClinicScope(
      store: store,
      child: MaterialApp(
        title: 'CULT Clinic',
        debugShowCheckedModeBanner: false,
        theme: cultTheme(),
        locale: const Locale('ru'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ru')],
        home: Boot(splash: splash),
      ),
    );
  }
}

class Boot extends StatefulWidget {
  const Boot({super.key, required this.splash});

  final Duration splash;

  @override
  State<Boot> createState() => _BootState();
}

class _BootState extends State<Boot> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.splash == Duration.zero) {
      _ready = true;
      return;
    }
    Future<void>.delayed(widget.splash, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Cult.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CULT', style: TextStyle(fontFamily: 'serif', fontSize: 56, letterSpacing: 6)),
              SizedBox(height: 12),
              SizedBox(width: 48, height: 2, child: ColoredBox(color: Cult.gold)),
              SizedBox(height: 12),
              Text('CLINIC', style: TextStyle(letterSpacing: 4, color: Cult.muted)),
              SizedBox(height: 8),
              Text('Сочи', style: TextStyle(color: Cult.muted)),
            ],
          ),
        ),
      );
    }
    final store = ClinicScope.of(context);
    if (!store.hasGender) {
      return GenderPage(
        onDone: () {
          if (mounted) setState(() {});
        },
      );
    }
    return const Shell();
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  var _index = 0;
  var _shopTab = 0;
  var _synced = false;

  void _openShop() => setState(() {
        _shopTab = 2;
        _index = 2;
      });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_synced) return;
    _synced = true;
    final store = ClinicScope.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => store.syncClinic());
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    final pages = [
      HomePage(onShop: _openShop),
      const ServicesPage(),
      ShopPage(key: ValueKey(_shopTab), initialTab: _shopTab),
      const ChatPage(),
      const CabinetPage(),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Scaffold(
      appBar: AppBar(
        title: const Text('CULT'),
        actions: [
          IconButton(
            tooltip: 'Корзина',
            onPressed: () => pushPage(context, const CartPage()),
            icon: Badge(isLabelVisible: store.cartCount > 0, label: Text('${store.cartCount}'), child: const Icon(Icons.shopping_bag_outlined)),
          ),
          IconButton(tooltip: 'Меню', onPressed: () => _menu(context), icon: const Icon(Icons.menu)),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.spa_outlined), label: 'Услуги'),
          NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Магазин'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Чат'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Кабинет'),
        ],
      ),
        ),
      ),
    );
  }

  void _menu(BuildContext context) {
    final store = ClinicScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), child: Text('Меню', style: cultHeadline(28))),
            const _MenuLabel('Клиника'),
            ListTile(title: const Text('Запись'), subtitle: const Text('Услуга, врач, время'), onTap: () => _go(sheetContext, const BookingPage())),
            ListTile(title: const Text('Прайс'), subtitle: const Text('Цены филиала'), onTap: () => _go(sheetContext, const PricesPage())),
            ListTile(title: const Text('Врачи'), onTap: () => _go(sheetContext, const DoctorsPage())),
            ListTile(title: const Text('Оборудование'), onTap: () => _go(sheetContext, const EquipmentPage())),
            const _MenuLabel('Журнал'),
            ListTile(title: const Text('Кейсы'), onTap: () => _go(sheetContext, const CasesPage())),
            ListTile(title: const Text('Блог'), onTap: () => _go(sheetContext, const BlogPage())),
            ListTile(title: const Text('О клинике'), onTap: () => _go(sheetContext, const AboutPage())),
            const _MenuLabel('Ещё'),
            ListTile(title: const Text('Трансфер'), onTap: () => _go(sheetContext, const TransferPage())),
            ListTile(title: const Text('Сертификаты'), onTap: () => _go(sheetContext, const CertificatesPage())),
            ListTile(
              title: Text(store.signedIn ? 'Профиль' : 'Войти по телефону'),
              subtitle: Text(store.signedIn ? store.profilePhone : 'Сохраним вас в филиале'),
              onTap: () => _go(sheetContext, store.signedIn ? const SettingsPage() : const AuthPage(allowSkip: false)),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext sheetContext, Widget page) {
    Navigator.pop(sheetContext);
    pushPage(context, page);
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(text.toUpperCase(), style: const TextStyle(color: Cult.muted, fontSize: 12, letterSpacing: 1.2)),
    );
  }
}
