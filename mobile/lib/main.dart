import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  const CultApp({
    super.key,
    required this.store,
    this.splash = const Duration(milliseconds: 2800),
  });

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
    final Widget child;
    if (!_ready) {
      child = SplashScreen(
        key: const ValueKey('splash'),
        duration: widget.splash,
      );
    } else {
      final store = ClinicScope.of(context);
      if (!store.hasGender) {
        child = GenderPage(
          key: const ValueKey('gender'),
          onDone: () {
            if (mounted) setState(() {});
          },
        );
      } else {
        child = const Shell(key: ValueKey('shell'));
      }
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.duration});

  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
  );
  late final Animation<double> _rise = Tween<double>(begin: 18, end: 0).animate(
    CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ),
  );
  late final Animation<double> _line = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.25, 0.75, curve: Curves.easeInOut),
  );
  late final Animation<double> _sub = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(const Color(0xFFF3EFEA), Cult.bg, _fade.value)!,
                  Cult.bg,
                  Color.lerp(
                    Cult.bg,
                    Cult.sand.withValues(alpha: 0.35),
                    _sub.value,
                  )!,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.08 + (_sub.value * 0.08),
                    child: Image.asset(
                      'assets/media/bc16b5df11db.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                Center(
                  child: Opacity(
                    opacity: _fade.value,
                    child: Transform.translate(
                      offset: Offset(0, _rise.value),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CULT',
                            style: cultHeadline(56).copyWith(letterSpacing: 8),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: 56 * _line.value.clamp(0.05, 1),
                            height: 2,
                            child: const ColoredBox(color: Cult.gold),
                          ),
                          const SizedBox(height: 14),
                          Opacity(
                            opacity: _sub.value,
                            child: const Column(
                              children: [
                                Text(
                                  'CLINIC',
                                  style: TextStyle(
                                    letterSpacing: 5,
                                    color: Cult.muted,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Сочи',
                                  style: TextStyle(color: Cult.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Меню',
              onPressed: () => _menu(context),
              icon: const Icon(Icons.menu),
            ),
            title: const Text('CULT'),
            actions: [
              if (store.syncing)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Cult.primary,
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Настройки',
                onPressed: () => pushPage(context, const SettingsPage()),
                icon: const Icon(Icons.notifications_none),
              ),
              if (_index == 2 || store.cartCount > 0)
                IconButton(
                  tooltip: 'Корзина',
                  onPressed: () => pushPage(context, const CartPage()),
                  icon: Badge(
                    isLabelVisible: store.cartCount > 0,
                    label: Text('${store.cartCount}'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                ),
            ],
          ),
          body: IndexedStack(
            index: _index,
            children: [
              HomePage(onShop: _openShop),
              const ServicesPage(),
              ShopPage(key: ValueKey(_shopTab), initialTab: _shopTab),
              const ChatPage(),
              const CabinetPage(),
            ],
          ),
          floatingActionButton: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _index == 0
                ? FloatingActionButton(
                    key: const ValueKey('fab-book'),
                    heroTag: 'shell-book',
                    backgroundColor: Cult.ink,
                    foregroundColor: Colors.white,
                    tooltip: 'Запись',
                    onPressed: () => pushPage(context, const BookingPage()),
                    child: const Icon(Icons.add),
                  )
                : const SizedBox.shrink(key: ValueKey('fab-none')),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) {
              FocusManager.instance.primaryFocus?.unfocus();
              HapticFeedback.selectionClick();
              if (value == _index) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                return;
              }
              setState(() => _index = value);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Главная',
              ),
              NavigationDestination(
                icon: Icon(Icons.spa_outlined),
                selectedIcon: Icon(Icons.spa),
                label: 'Услуги',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag),
                label: 'Магазин',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Чат',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Профиль',
              ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text('Меню', style: cultHeadline(28)),
            ),
            const _MenuLabel('Клиника'),
            ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Запись'),
              subtitle: const Text('Услуга, врач, время'),
              onTap: () => _go(sheetContext, const BookingPage()),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Прайс'),
              subtitle: const Text('Цены филиала'),
              onTap: () => _go(sheetContext, const PricesPage()),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text('Врачи'),
              onTap: () => _go(sheetContext, const DoctorsPage()),
            ),
            ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: const Text('Аппаратная'),
              onTap: () =>
                  _go(sheetContext, const CategoryHubPage(slug: 'hardware')),
            ),
            ListTile(
              leading: const Icon(Icons.vaccines_outlined),
              title: const Text('Инъекции'),
              onTap: () =>
                  _go(sheetContext, const CategoryHubPage(slug: 'injections')),
            ),
            ListTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: const Text('Инфузии'),
              onTap: () =>
                  _go(sheetContext, const CategoryHubPage(slug: 'infusions')),
            ),
            ListTile(
              leading: const Icon(Icons.biotech_outlined),
              title: const Text('Наука'),
              onTap: () =>
                  _go(sheetContext, const CategoryHubPage(slug: 'science')),
            ),
            const _MenuLabel('Журнал'),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Кейсы'),
              onTap: () => _go(sheetContext, const CasesPage()),
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Блог'),
              onTap: () => _go(sheetContext, const BlogPage()),
            ),
            ListTile(
              leading: const Icon(Icons.apartment_outlined),
              title: const Text('О клинике'),
              onTap: () => _go(sheetContext, const AboutPage()),
            ),
            const _MenuLabel('Ещё'),
            ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: const Text('Трансфер'),
              onTap: () => _go(sheetContext, const TransferPage()),
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard_outlined),
              title: const Text('Сертификаты'),
              onTap: () => _go(sheetContext, const CertificatesPage()),
            ),
            ListTile(
              leading: Icon(
                store.signedIn ? Icons.person_outline : Icons.login,
              ),
              title: Text(store.signedIn ? 'Профиль' : 'Войти по телефону'),
              subtitle: Text(
                store.signedIn ? store.profilePhone : 'Сохраним вас в филиале',
              ),
              onTap: () => _go(
                sheetContext,
                store.signedIn
                    ? const SettingsPage()
                    : const AuthPage(allowSkip: false),
              ),
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
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Cult.muted,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
