import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/agent_voice.dart';
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
  try {
    // Prefer a short timeout: a broken SharedPreferences channel otherwise
    // leaves a blank white screen before runApp.
    await store.load().timeout(const Duration(seconds: 8));
  } catch (_) {
    // MissingPluginException / channel hang — continue with empty local state.
  }
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
  Timer? _splashTimer;

  void _finishSplash() {
    _splashTimer?.cancel();
    _splashTimer = null;
    if (_ready || !mounted) return;
    setState(() => _ready = true);
  }

  @override
  void initState() {
    super.initState();
    if (widget.splash == Duration.zero) {
      _ready = true;
      return;
    }
    _splashTimer = Timer(widget.splash, _finishSplash);
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (!_ready) {
      child = SplashScreen(
        key: const ValueKey('splash'),
        duration: widget.splash,
        onSkip: _finishSplash,
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
  const SplashScreen({
    super.key,
    required this.duration,
    this.onSkip,
  });

  final Duration duration;
  final VoidCallback? onSkip;

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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          cultTapFeedback();
          widget.onSkip?.call();
        },
        child: AnimatedBuilder(
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
                                  SizedBox(height: 18),
                                  Text(
                                    'Нажмите, чтобы продолжить',
                                    style: TextStyle(
                                      color: Cult.muted,
                                      fontSize: 12,
                                    ),
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
  final _homeScroll = ScrollController();

  void _openShop() => setState(() {
    _shopTab = 2;
    _index = 3; // Магазин (Агент — центр, index 2)
  });

  static const _tabHome = 0;
  static const _tabServices = 1;
  static const _tabAgent = 2;
  static const _tabShop = 3;
  static const _tabProfile = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_synced) return;
    _synced = true;
    final store = ClinicScope.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => store.syncClinic());
  }

  @override
  void dispose() {
    _homeScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ClinicScope.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Scaffold(
          appBar: _index == _tabAgent
              ? null
              : AppBar(
                  leading: IconButton(
                    tooltip: 'Меню',
                    onPressed: () {
                      cultTapFeedback();
                      _menu(context);
                    },
                    icon: Badge(
                      isLabelVisible: store.hasUnreadChat,
                      smallSize: 8,
                      backgroundColor: Cult.gold,
                      child: const Icon(Icons.menu),
                    ),
                  ),
                  title: GestureDetector(
                    onTap: () {
                      cultTapFeedback();
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      setState(() => _index = _tabHome);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!_homeScroll.hasClients) return;
                        _homeScroll.animateTo(
                          0,
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        );
                      });
                    },
                    child: const Text('CULT'),
                  ),
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
                    if (_index == _tabShop || store.cartCount > 0)
                      IconButton(
                        tooltip: store.cartCount > 0
                            ? 'Корзина, ${store.cartCount}'
                            : 'Корзина',
                        onPressed: () {
                          cultTapFeedback();
                          pushPage(context, const CartPage());
                        },
                        icon: Badge(
                          isLabelVisible: store.cartCount > 0,
                          label: Text('${store.cartCount}'),
                          child: Semantics(
                            label: store.cartCount > 0
                                ? 'Корзина, ${store.cartCount} позиц.'
                                : 'Корзина',
                            child: const Icon(Icons.shopping_bag_outlined),
                          ),
                        ),
                      ),
                  ],
                ),
          extendBody: true,
          body: IndexedStack(
            index: _index,
            children: [
              HomePage(onShop: _openShop, scrollController: _homeScroll),
              const ServicesPage(),
              // Leave room for the floating dock above the mic controls.
              Padding(
                padding: const EdgeInsets.only(bottom: 96),
                child: AgentVoicePage(active: _index == _tabAgent),
              ),
              ShopPage(key: ValueKey(_shopTab), initialTab: _shopTab),
              const CabinetPage(),
            ],
          ),
          bottomNavigationBar: _CultDockBar(
            index: _index,
            agentSelected: _index == _tabAgent,
            onSelect: _selectTab,
          ),
        ),
      ),
    );
  }

  void _selectTab(int value) {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    if (value == _index) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (value == _tabHome && _homeScroll.hasClients) {
        _homeScroll.animateTo(
          0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    setState(() => _index = value);
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
            const SizedBox(height: 4),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Cult.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
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
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Магазин'),
              subtitle: const Text('Биохакинг и уход'),
              onTap: () {
                cultTapFeedback();
                Navigator.pop(sheetContext);
                setState(() => _index = _tabShop);
              },
            ),
            ListTile(
              leading: Badge(
                isLabelVisible: store.hasUnreadChat,
                smallSize: 8,
                backgroundColor: Cult.gold,
                child: const Icon(Icons.chat_bubble_outline),
              ),
              title: const Text('Чат'),
              subtitle: const Text('Администратор и врач'),
              onTap: () => _go(sheetContext, const ChatPage()),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Мои записи'),
              onTap: () => _go(sheetContext, const VisitsPage()),
            ),
            ListTile(
              leading: const Icon(Icons.biotech_outlined),
              title: const Text('Мои анализы'),
              onTap: () => _go(sheetContext, const AnalysesPage()),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Избранное'),
              onTap: () => _go(sheetContext, const FavoritesPage()),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Мои заказы'),
              onTap: () => _go(sheetContext, const OrdersPage()),
            ),
            ListTile(
              leading: const Icon(Icons.loyalty_outlined),
              title: const Text('Лояльность'),
              onTap: () => _go(sheetContext, const LoyaltyPage()),
            ),
            ListTile(
              leading: const Icon(Icons.medical_information_outlined),
              title: const Text('Аптечка'),
              subtitle: const Text('Рекомендации врача'),
              onTap: () => _go(sheetContext, const PharmacyPage()),
            ),
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
              onTap: () {
                cultTapFeedback();
                Navigator.pop(sheetContext);
                if (store.signedIn) {
                  setState(() => _index = _tabProfile);
                } else {
                  pushPage(context, const AuthPage(allowSkip: false));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext sheetContext, Widget page) {
    cultTapFeedback();
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

/// Floating pill dock with center champagne Agent button (notched gap).
class _CultDockBar extends StatelessWidget {
  const _CultDockBar({
    required this.index,
    required this.agentSelected,
    required this.onSelect,
  });

  final int index;
  final bool agentSelected;
  final ValueChanged<int> onSelect;

  static const _tabHome = 0;
  static const _tabServices = 1;
  static const _tabAgent = 2;
  static const _tabShop = 3;
  static const _tabProfile = 4;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: SizedBox(
          height: 84,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 66,
                    child: Row(
                      children: [
                        Expanded(
                          child: _DockItem(
                            tooltip: 'Главная',
                            selected: index == _tabHome,
                            icon: Icons.home_outlined,
                            selectedIcon: Icons.home,
                            onTap: () => onSelect(_tabHome),
                          ),
                        ),
                        Expanded(
                          child: _DockItem(
                            tooltip: 'Услуги',
                            selected: index == _tabServices,
                            icon: Icons.spa_outlined,
                            selectedIcon: Icons.spa,
                            onTap: () => onSelect(_tabServices),
                          ),
                        ),
                        const SizedBox(width: 72),
                        Expanded(
                          child: _DockItem(
                            tooltip: 'Магазин',
                            selected: index == _tabShop,
                            icon: Icons.shopping_bag_outlined,
                            selectedIcon: Icons.shopping_bag,
                            onTap: () => onSelect(_tabShop),
                          ),
                        ),
                        Expanded(
                          child: _DockItem(
                            tooltip: 'Профиль',
                            selected: index == _tabProfile,
                            icon: Icons.person_outline,
                            selectedIcon: Icons.person,
                            onTap: () => onSelect(_tabProfile),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: Semantics(
                  button: true,
                  selected: agentSelected,
                  label: 'Агент',
                  child: Tooltip(
                    message: 'Агент',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onSelect(
                          agentSelected ? _tabHome : _tabAgent,
                        ),
                        child: SizedBox(
                          width: 68,
                          height: 68,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE8D4B8)
                                          .withValues(alpha: 0.45),
                                      blurRadius: agentSelected ? 16 : 10,
                                    ),
                                  ],
                                  gradient: const RadialGradient(
                                    center: Alignment(-0.35, -0.4),
                                    radius: 1.05,
                                    colors: [
                                      Color(0xFFFFFEFA),
                                      Color(0xFFF4E8D8),
                                      Color(0xFFD8C0A4),
                                      Color(0xFFB89878),
                                    ],
                                    stops: [0, 0.35, 0.72, 1],
                                  ),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              // Specular glint
                              Positioned(
                                top: 16,
                                left: 18,
                                child: Container(
                                  width: 18,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.85),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (agentSelected)
                                Icon(
                                  Icons.close_rounded,
                                  color: const Color(0xFF1B1408)
                                      .withValues(alpha: 0.55),
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.tooltip,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  final String tooltip;
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 66,
          child: Icon(
            selected ? selectedIcon : icon,
            size: 26,
            color: selected ? Cult.primary : Cult.muted,
          ),
        ),
      ),
    );
  }
}
