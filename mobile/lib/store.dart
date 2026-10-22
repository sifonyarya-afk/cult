import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'yclients.dart';

class CartItem {
  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.qty = 1,
  });

  final String id;
  final String name;
  final int price;
  int qty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'qty': qty,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as String,
    name: json['name'] as String,
    price: json['price'] as int,
    qty: json['qty'] as int,
  );
}

class Appointment {
  Appointment({
    required this.id,
    required this.service,
    required this.doctor,
    required this.date,
    required this.time,
    this.status = 'upcoming',
    this.recordId,
    this.recordHash,
  });

  final String id;
  final String service;
  final String doctor;
  final String date;
  final String time;
  String status;
  final int? recordId;
  final String? recordHash;

  Map<String, dynamic> toJson() => {
    'id': id,
    'service': service,
    'doctor': doctor,
    'date': date,
    'time': time,
    'status': status,
    'recordId': recordId,
    'recordHash': recordHash,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    service: json['service'] as String,
    doctor: json['doctor'] as String,
    date: json['date'] as String,
    time: json['time'] as String,
    status: json['status'] as String? ?? 'upcoming',
    recordId: json['recordId'] as int?,
    recordHash: json['recordHash'] as String?,
  );
}

class ShopOrder {
  ShopOrder({
    required this.id,
    required this.title,
    required this.total,
    required this.pay,
    required this.at,
  });

  final String id;
  final String title;
  final int total;
  final String pay;
  final String at;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'total': total,
    'pay': pay,
    'at': at,
  };

  factory ShopOrder.fromJson(Map<String, dynamic> json) => ShopOrder(
    id: json['id'] as String,
    title: json['title'] as String,
    total: json['total'] as int,
    pay: json['pay'] as String,
    at: json['at'] as String,
  );
}

class GiftCard {
  GiftCard({
    required this.id,
    required this.nominal,
    required this.design,
    required this.code,
  });

  final String id;
  final int nominal;
  final String design;
  final String code;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nominal': nominal,
    'design': design,
    'code': code,
  };

  factory GiftCard.fromJson(Map<String, dynamic> json) => GiftCard(
    id: json['id'] as String,
    nominal: json['nominal'] as int,
    design: json['design'] as String,
    code: json['code'] as String,
  );
}

class ChatMessage {
  ChatMessage({required this.id, required this.from, required this.text});

  final String id;
  final String from;
  final String text;

  Map<String, dynamic> toJson() => {'id': id, 'from': from, 'text': text};

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    from: json['from'] as String,
    text: json['text'] as String,
  );
}

class ClinicStore extends ChangeNotifier {
  ClinicStore();

  static const _key = 'cult-flutter';
  static const branchId = '988587';
  static const partnerKey = 'Vh91j85a5N2Ugbe78XJE';
  static const userKey = '45e37b62495cf77d877359a0c9d93751';

  List<CartItem> cart = [];
  List<Appointment> appointments = [];
  List<ShopOrder> orders = [];
  List<GiftCard> gifts = [];
  List<String> favorites = [];
  Map<String, List<ChatMessage>> threads = {};
  Map<String, String> chatRead = {};
  Map<String, bool> notices = {
    'visits': true,
    'analyses': true,
    'pharmacy': true,
    'offers': false,
  };
  int spent = 0;
  int welcomeBonus = 0;
  var welcomeGranted = false;
  String profileName = '';
  String profilePhone = '';
  String profileEmail = '';
  ClientGender? gender;
  int ycClientId = 0;
  String companyId = '';
  String chainId = '0';
  String partnerToken = '';
  String userToken = '';
  List<YcService> liveServices = [];
  List<YcStaff> liveStaff = [];
  List<YcCard> loyaltyCards = [];
  String liveError = '';
  String visitsError = '';
  var visitsLoading = false;
  var syncing = false;

  YClientsApi yclients = YClientsApi();

  int get balance {
    if (loyaltyCards.isNotEmpty) {
      return loyaltyCards.fold(0, (sum, card) => sum + card.balance) +
          welcomeBonus;
    }
    return max(0, 12450 + welcomeBonus - spent);
  }

  int? get companyIdInt => int.tryParse(companyId.trim());
  bool get yclientsReady =>
      companyIdInt != null &&
      partnerToken.trim().isNotEmpty &&
      userToken.trim().isNotEmpty;
  bool get signedIn =>
      ycClientId > 0 && normalizePhone(profilePhone).length >= 11;
  bool get hasGender => gender != null;
  String get displayName {
    final name = profileName.trim();
    if (name.isNotEmpty) return name;
    return signedIn ? 'Клиент CULT' : 'Гость';
  }

  int get cartCount => cart.fold(0, (sum, item) => sum + item.qty);
  int get cartTotal => cart.fold(0, (sum, item) => sum + item.price * item.qty);

  List<Appointment> get upcoming =>
      appointments.where((item) => item.status == 'upcoming').toList();
  List<Appointment> get past =>
      appointments.where((item) => item.status == 'past').toList();
  List<Appointment> get labHistory {
    return [
      for (final visit in [...upcoming, ...past])
        if (RegExp(
          r'анализ|днк|забор',
          caseSensitive: false,
        ).hasMatch(visit.service))
          visit,
    ];
  }

  List<Service> get catalogServices {
    final current = gender;
    if (current == null) return services;
    return [
      for (final item in services)
        if (item.audience.matches(current)) item,
    ];
  }

  List<YcService> get catalogLive {
    final current = gender;
    if (current == null) return liveServices;
    return [
      for (final item in liveServices)
        if (audienceFromText(item.title, item.category).matches(current)) item,
    ];
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _applyClinicDefaults();
      _seedThreads();
      notifyListeners();
      return;
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    cart = (json['cart'] as List<dynamic>? ?? [])
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();
    appointments = (json['appointments'] as List<dynamic>? ?? [])
        .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
        .where((item) => item.id != 'seed-visit')
        .toList();
    orders = (json['orders'] as List<dynamic>? ?? [])
        .map((item) => ShopOrder.fromJson(item as Map<String, dynamic>))
        .toList();
    gifts = (json['gifts'] as List<dynamic>? ?? [])
        .map((item) => GiftCard.fromJson(item as Map<String, dynamic>))
        .toList();
    favorites = (json['favorites'] as List<dynamic>? ?? []).cast<String>();
    spent = json['spent'] as int? ?? 0;
    welcomeBonus = json['welcomeBonus'] as int? ?? 0;
    welcomeGranted = json['welcomeGranted'] as bool? ?? welcomeBonus > 0;
    profileName = json['profileName'] as String? ?? '';
    profilePhone = json['profilePhone'] as String? ?? '';
    profileEmail = json['profileEmail'] as String? ?? '';
    gender = ClientGender.tryParse(json['gender'] as String?);
    ycClientId = json['ycClientId'] as int? ?? 0;
    companyId = json['companyId'] as String? ?? '';
    chainId = json['chainId'] as String? ?? '0';
    partnerToken = json['partnerToken'] as String? ?? '';
    userToken = json['userToken'] as String? ?? '';
    _applyClinicDefaults();
    final savedNotices = json['notices'] as Map<String, dynamic>?;
    if (savedNotices != null) {
      notices = savedNotices.map((key, value) => MapEntry(key, value as bool));
    }
    final savedThreads = json['threads'] as Map<String, dynamic>?;
    threads = {};
    if (savedThreads != null) {
      for (final entry in savedThreads.entries) {
        threads[entry.key] = (entry.value as List<dynamic>)
            .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
    final savedRead = json['chatRead'] as Map<String, dynamic>?;
    chatRead = savedRead == null
        ? {}
        : savedRead.map((key, value) => MapEntry(key, value.toString()));
    _seedThreads();
    notifyListeners();
  }

  static const _chatSeeds = {
    'admin': 'Здравствуйте. Помогу с записью, трансфером и сертификатом.',
    'bot': 'Я ассистент CULT. Спросите про услуги, часы или запись.',
    'specialist': 'Здравствуйте. Я на связи по уходу после процедур.',
  };

  void _seedThreads() {
    for (final entry in _chatSeeds.entries) {
      if (threads.containsKey(entry.key)) continue;
      final seed = ChatMessage(
        id: '${entry.key}-seed',
        from: 'them',
        text: entry.value,
      );
      threads[entry.key] = [seed];
      // Welcome seeds are not "new" replies — badge only for later messages.
      chatRead.putIfAbsent(entry.key, () => seed.id);
    }
  }

  void clearChat(String contactId) {
    final text =
        _chatSeeds[contactId] ?? 'Здравствуйте. Чем можем помочь?';
    final seed = ChatMessage(
      id: '$contactId-seed-${DateTime.now().microsecondsSinceEpoch}',
      from: 'them',
      text: text,
    );
    threads[contactId] = [seed];
    chatRead[contactId] = seed.id;
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'cart': cart.map((item) => item.toJson()).toList(),
      'appointments': appointments.map((item) => item.toJson()).toList(),
      'orders': orders.map((item) => item.toJson()).toList(),
      'gifts': gifts.map((item) => item.toJson()).toList(),
      'favorites': favorites,
      'spent': spent,
      'welcomeBonus': welcomeBonus,
      'welcomeGranted': welcomeGranted,
      'profileName': profileName,
      'profilePhone': profilePhone,
      'profileEmail': profileEmail,
      'gender': gender?.storage,
      'ycClientId': ycClientId,
      'companyId': companyId,
      'chainId': chainId,
      'partnerToken': partnerToken,
      'userToken': userToken,
      'notices': notices,
      'chatRead': chatRead,
      'threads': threads.map(
        (key, value) =>
            MapEntry(key, value.map((item) => item.toJson()).toList()),
      ),
    };
    await prefs.setString(_key, jsonEncode(payload));
    notifyListeners();
  }

  void addToCart(String id, String name, int price) {
    final found = cart.where((item) => item.id == id).firstOrNull;
    if (found == null) {
      cart.add(CartItem(id: id, name: name, price: price));
    } else {
      found.qty += 1;
    }
    _save();
  }

  void setQty(String id, int qty) {
    if (qty <= 0) {
      cart.removeWhere((item) => item.id == id);
    } else {
      cart.firstWhere((item) => item.id == id).qty = qty;
    }
    _save();
  }

  void clearCart() {
    if (cart.isEmpty) return;
    cart = [];
    _save();
  }

  void clearFavorites() {
    if (favorites.isEmpty) return;
    favorites = [];
    _save();
  }

  /// Adds every favorited catalog product to the cart. Returns count.
  int addFavoritesToCart() {
    var added = 0;
    for (final product in products) {
      if (!favorites.contains(product.id)) continue;
      addToCart(product.id, product.name, product.price);
      added++;
    }
    return added;
  }

  /// Adds catalog products whose names appear in an order title. Returns count.
  int reorderFromTitle(String title) {
    var added = 0;
    for (final product in products) {
      if (title.contains(product.name)) {
        addToCart(product.id, product.name, product.price);
        added++;
      }
    }
    return added;
  }

  bool isChatUnread(String contactId) {
    final thread = threads[contactId];
    if (thread == null || thread.isEmpty) return false;
    final last = thread.last;
    return last.from == 'them' && chatRead[contactId] != last.id;
  }

  bool get hasUnreadChat {
    for (final id in threads.keys) {
      if (isChatUnread(id)) return true;
    }
    return false;
  }

  void markChatRead(String contactId) {
    final thread = threads[contactId];
    if (thread == null || thread.isEmpty) return;
    final lastId = thread.last.id;
    if (chatRead[contactId] == lastId) return;
    chatRead[contactId] = lastId;
    _save();
  }

  void markAllChatsRead() {
    var changed = false;
    for (final entry in threads.entries) {
      if (entry.value.isEmpty) continue;
      final lastId = entry.value.last.id;
      if (chatRead[entry.key] == lastId) continue;
      chatRead[entry.key] = lastId;
      changed = true;
    }
    if (changed) _save();
  }

  void toggleFavorite(String id) {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    _save();
  }

  void bookVisit({
    required String service,
    required String doctor,
    required String date,
    required String time,
    int? recordId,
    String? recordHash,
  }) {
    appointments.insert(
      0,
      Appointment(
        id: recordId == null
            ? 'visit-${DateTime.now().microsecondsSinceEpoch}'
            : 'yc-$recordId',
        service: service,
        doctor: doctor,
        date: date,
        time: time,
        recordId: recordId,
        recordHash: recordHash,
      ),
    );
    _save();
  }

  Future<String?> cancelVisit(String id) async {
    final visit = appointments.where((item) => item.id == id).firstOrNull;
    if (visit == null || visit.status == 'cancelled') return null;
    final company = companyIdInt;
    if (yclientsReady && visit.recordId != null && company != null) {
      try {
        if ((visit.recordHash ?? '').isNotEmpty) {
          await yclients.cancel(
            partnerToken: partnerToken,
            userToken: userToken,
            recordId: visit.recordId!,
            recordHash: visit.recordHash!,
          );
        } else {
          await yclients.deleteRecord(
            partnerToken: partnerToken,
            userToken: userToken,
            companyId: company,
            recordId: visit.recordId!,
          );
        }
      } on YcException catch (error) {
        return error.message;
      }
    }
    visit.status = 'cancelled';
    await _save();
    await refreshVisits();
    return null;
  }

  void rememberContact({
    required String name,
    required String phone,
    String email = '',
  }) {
    if (name.trim().isNotEmpty) profileName = name.trim();
    profilePhone = phone.trim();
    if (email.trim().isNotEmpty) profileEmail = email.trim();
    _save();
  }

  Future<void> setGender(ClientGender value) async {
    gender = value;
    await _save();
    if (signedIn) {
      await _syncGenderToYclients();
    }
  }

  Future<String?> registerWithPhone({
    required String name,
    required String phone,
    String email = '',
  }) async {
    _applyClinicDefaults();
    final id = companyIdInt;
    if (id == null || partnerToken.isEmpty || userToken.isEmpty) {
      return 'Клиника временно недоступна. Попробуйте позже.';
    }
    final digits = normalizePhone(phone);
    final trimmed = name.trim();
    if (trimmed.length < 2) return 'Укажите имя.';
    if (digits.length < 11) return 'Укажите телефон в формате +7.';
    try {
      final client = await yclients.registerClient(
        partnerToken: partnerToken,
        userToken: userToken,
        companyId: id,
        name: trimmed,
        phone: digits,
        email: email,
        sexId: gender?.ycSexId ?? 0,
      );
      ycClientId = client.id;
      profileName = trimmed;
      profilePhone = digits;
      if (email.trim().isNotEmpty) {
        profileEmail = email.trim();
      } else if (client.email.isNotEmpty) {
        profileEmail = client.email;
      }
      if (!welcomeGranted) {
        welcomeBonus = 3000;
        welcomeGranted = true;
      }
      await _save();
      if (gender != null) await _syncGenderToYclients();
      await syncClinic();
      return null;
    } on YcException catch (error) {
      return error.message;
    }
  }

  Future<void> _syncGenderToYclients() async {
    final id = companyIdInt;
    final current = gender;
    if (id == null ||
        current == null ||
        ycClientId <= 0 ||
        partnerToken.isEmpty ||
        userToken.isEmpty)
      return;
    try {
      await yclients.updateClient(
        partnerToken: partnerToken,
        userToken: userToken,
        companyId: id,
        clientId: ycClientId,
        sexId: current.ycSexId,
        name: profileName,
      );
    } on YcException {
      // Пол остаётся в приложении, даже если филиал временно не принял правку.
    }
  }

  Future<void> signOut() async {
    ycClientId = 0;
    profileName = '';
    profilePhone = '';
    profileEmail = '';
    loyaltyCards = [];
    appointments = [];
    visitsError = '';
    await _save();
  }

  Future<void> syncClinic() async {
    if (syncing || !yclientsReady) return;
    syncing = true;
    notifyListeners();
    await Future.wait([
      refreshCatalog(),
      refreshStaff(),
      if (signedIn) refreshVisits(),
      if (signedIn) refreshLoyalty(),
    ]);
    syncing = false;
    notifyListeners();
  }

  Future<String?> refreshCatalog() async {
    final id = companyIdInt;
    if (id == null || partnerToken.isEmpty) return 'YClients не подключён.';
    try {
      liveServices = await _fetchLive(
        partner: partnerToken,
        user: userToken,
        companyId: id,
      );
      liveError = '';
      notifyListeners();
      return null;
    } on YcException catch (error) {
      liveError = error.message;
      notifyListeners();
      return error.message;
    }
  }

  Future<String?> refreshStaff() async {
    final id = companyIdInt;
    if (id == null || partnerToken.isEmpty) return 'YClients не подключён.';
    try {
      var list = await yclients.companyStaff(partnerToken, userToken, id);
      if (list.isEmpty) list = await yclients.staff(partnerToken, id);
      liveStaff = list;
      notifyListeners();
      return null;
    } on YcException catch (error) {
      return error.message;
    }
  }

  Future<String?> refreshVisits() async {
    final id = companyIdInt;
    if (!signedIn || id == null || partnerToken.isEmpty || userToken.isEmpty) {
      if (!signedIn) {
        appointments = [];
        visitsError = '';
        notifyListeners();
      }
      return null;
    }
    visitsLoading = true;
    visitsError = '';
    notifyListeners();
    try {
      final records = await yclients.clientRecords(
        partnerToken: partnerToken,
        userToken: userToken,
        companyId: id,
        clientId: ycClientId,
        phone: profilePhone,
      );
      appointments = [
        for (final record in records)
          Appointment(
            id: 'yc-${record.id}',
            service: record.service,
            doctor: record.doctor,
            date: record.date,
            time: record.time,
            status: record.status,
            recordId: record.id,
            recordHash: record.recordHash.isEmpty ? null : record.recordHash,
          ),
      ]..sort((a, b) => '${b.date}${b.time}'.compareTo('${a.date}${a.time}'));
      visitsLoading = false;
      await _save();
      return null;
    } on YcException catch (error) {
      visitsLoading = false;
      visitsError = error.message;
      notifyListeners();
      return error.message;
    }
  }

  void _applyClinicDefaults() {
    companyId = branchId;
    partnerToken = partnerKey;
    userToken = userKey;
    if (chainId.trim().isEmpty) chainId = '0';
  }

  Future<List<YcService>> _fetchLive({
    required String partner,
    required String user,
    required int companyId,
  }) async {
    Map<int, String> names = {};
    try {
      names = await yclients.categoryNames(partner, companyId);
    } on YcException {
      names = {};
    }
    var list = await yclients.services(partner, companyId);
    if (list.isEmpty && user.trim().isNotEmpty) {
      list = await yclients.companyServices(partner, user.trim(), companyId);
    }
    return [
      for (final item in list)
        item.withCategory(names[item.categoryId] ?? item.category),
    ];
  }

  Future<String?> refreshLoyalty() async {
    final id = companyIdInt;
    final phone = normalizePhone(profilePhone);
    final chain = int.tryParse(chainId) ?? 0;
    if (id == null ||
        partnerToken.isEmpty ||
        userToken.isEmpty ||
        phone.length < 11)
      return null;
    try {
      loyaltyCards = await yclients.loyaltyCards(
        partnerToken: partnerToken,
        userToken: userToken,
        phone: phone,
        companyId: id,
        chainId: chain,
      );
      notifyListeners();
      return null;
    } on YcException catch (error) {
      return error.message;
    }
  }

  bool spendBonus(int amount) {
    if (amount <= 0 || amount > balance) return false;
    spent += amount;
    _save();
    return true;
  }

  void placeOrder({
    required String title,
    required int total,
    required String pay,
  }) {
    final now = DateTime.now();
    orders.insert(
      0,
      ShopOrder(
        id: 'order-${now.microsecondsSinceEpoch}',
        title: title,
        total: total,
        pay: pay,
        at: '${now.day}.${now.month}.${now.year}',
      ),
    );
    cart = [];
    _save();
  }

  String buyGift(int nominal, String design) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final tail = List.generate(
      4,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    final code = 'CULT-${nominal ~/ 1000}-$tail';
    gifts.insert(
      0,
      GiftCard(
        id: 'gift-${DateTime.now().microsecondsSinceEpoch}',
        nominal: nominal,
        design: design,
        code: code,
      ),
    );
    _save();
    return code;
  }

  void sendMessage(String contactId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final list = threads.putIfAbsent(contactId, () => []);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    list.add(ChatMessage(id: 'me-$stamp', from: 'me', text: trimmed));
    list.add(
      ChatMessage(
        id: 'them-$stamp',
        from: 'them',
        text: _autoReply(contactId, trimmed),
      ),
    );
    _save();
  }

  String _autoReply(String contactId, String text) {
    final q = text.toLowerCase();
    if (contactId == 'bot') {
      if (q.contains('запис')) {
        return 'Откройте «Запись» в меню или нажмите «+» на главной — подберём услугу, врача и время.';
      }
      if (q.contains('доставк') ||
          q.contains('курьер') ||
          q.contains('магазин') ||
          q.contains('шоп')) {
        return 'Биохакинг-шоп — во вкладке «Магазин». Самовывоз на ресепшен или курьер при оформлении корзины.';
      }
      if (q.contains('массаж') || q.contains('лимфодрен')) {
        return 'Массаж и лимфодренаж — в меню «Услуги» и на записи. Подскажем протокол под вашу задачу на консультации.';
      }
      if (q.contains('лазер') || q.contains('ipl') || q.contains('пигмент')) {
        return 'Лазер и IPL — в разделе «Аппаратная». Перед курсом врач оценит фототип и зону.';
      }
      if (q.contains('пилинг') || q.contains('чистка')) {
        return 'Пилинги и уходы — в меню «Услуги». Подберём интенсивность под сезон и тип кожи.';
      }
      if (q.contains('абонемент') || q.contains('пакет') || q.contains('курс')) {
        return 'Курсы и пакеты обсуждаем на консультации. Часть протоколов выгоднее пакетом — спросите администратора.';
      }
      if (q.contains('эпиляц')) {
        return 'Лазерная эпиляция — в «Аппаратной». Курс и зону подберём на консультации с учётом фототипа.';
      }
      if (q.contains('перманент') || q.contains('татуаж') || q.contains('бров')) {
        return 'Перманентный макияж обсуждаем на очной консультации. Запись — через «+» или карточку специалиста.';
      }
      if (q.contains('мезотерап') || q.contains('биоревитал') || q.contains('плазмо')) {
        return 'Мезотерапия и биоревитализация — в меню «Инъекции». Перед курсом врач оценит показания.';
      }
      if (q.contains('контурн') || q.contains('липо') || q.contains('скульпт')) {
        return 'Контурная пластика и скульптурирование — в «Инъекциях». Объём и зоны согласуем на консультации.';
      }
      if (q.contains('ресепшен') ||
          q.contains('ресепшн') ||
          q.contains('администрац')) {
        return 'Ресепшен CULT Сочи — Черноморская, 6, ежедневно 9:00–21:00. Самовывоз шопа и вопросы по записи — там же.';
      }
      if (q.contains('час') ||
          q.contains('режим') ||
          q.contains('выходн') ||
          q.contains('воскрес') ||
          q.contains('суббот') ||
          q.contains('график работ') ||
          q.contains('часы работ')) {
        return 'CULT Сочи открыта ежедневно, включая выходные, с 9:00 до 21:00. Черноморская, 6.';
      }
      if (q.contains('добр') || q.contains('адрес') || q.contains('ехать')) {
        return 'Адрес: Сочи, Черноморская, 6. Нужен трансфер — закажите в профиле.';
      }
      if (q.contains('бонус')) {
        return 'Новым клиентам — 3 000 ₽ welcome-бонус. Баланс смотрите в профиле.';
      }
      if (q.contains('сертификат') || q.contains('подарок')) {
        return 'Сертификаты — в профиле → «Купить сертификат». Номинал и дизайн выбираете сами, код копируется в один тап.';
      }
      if (q.contains('трансфер') ||
          q.contains('такси') ||
          q.contains('машин')) {
        return 'VIP-трансфер заказывается в профиле. Укажите адрес — водитель напишет в чат администратора.';
      }
      if (q.contains('прайс') || q.contains('цен') || q.contains('стоим')) {
        return 'Актуальный прайс филиала — в меню «Прайс». Там же можно сразу записаться на услугу.';
      }
      if (q.contains('парков')) {
        return 'Гостевая парковка у входа на Черноморской, 6. Места для клиентов CULT — бесплатно на время визита.';
      }
      if (q.contains('анализ') || q.contains('лаборатор') || q.contains('кровь')) {
        return 'Анализы и протоколы — в кабинете → «Мои анализы». Запись на забор крови — через «+» или меню «Запись».';
      }
      if (q.contains('wifi') || q.contains('wi-fi') || q.contains('вайф')) {
        return 'Wi‑Fi для гостей на ресепшен: сеть CULT Guest. Пароль выдаст администратор.';
      }
      if (q.contains('скидк') || q.contains('акци') || q.contains('промо')) {
        return 'Актуальные предложения — на главной. Новым клиентам welcome-бонус 3 000 ₽ после входа по телефону.';
      }
      if (q.contains('врач') || q.contains('специалист') || q.contains('доктор')) {
        return 'Команда врачей — в меню «Врачи». Откройте карточку специалиста и запишитесь или напишите в чат.';
      }
      if (q.contains('беремен') || q.contains('кормлен')) {
        return 'При беременности и лактации часть процедур ограничена. Напишите срок врачу в чате — подскажем безопасный протокол.';
      }
      if (q.contains('аппарат') || q.contains('rf') || q.contains('smas')) {
        return 'Аппаратная косметология — в меню «Аппаратная»: RF, IPL и SMAS. Выберите зону и запишитесь.';
      }
      if (q.contains('инъек') || q.contains('филлер') || q.contains('ботокс')) {
        return 'Инъекции — в меню «Инъекции». Перед визитом врач уточнит показания на консультации.';
      }
      if (q.contains('инфуз') || q.contains('капель')) {
        return 'Инфузии — в меню «Инфузии»: NAD+, Immunity и Beauty & Glow. Запись через «+» на главной.';
      }
      if (q.contains('nad') ||
          q.contains('longevity') ||
          q.contains('долголет')) {
        return 'NAD+ и longevity-протоколы — в разделе «Инфузии». Курс подберём на консультации.';
      }
      if (q.contains('консультац')) {
        return 'Консультацию можно открыть через «+» на главной или в карточке врача. Первый визит часто начинается с осмотра.';
      }
      if (q.contains('дет') ||
          q.contains('ребён') ||
          q.contains('ребен') ||
          q.contains('несовершеннолет')) {
        return 'Большинство эстетических протоколов — с 18 лет. Для подростков нужна очная консультация врача и согласие опекуна.';
      }
      return 'Клиника открыта ежедневно с 9:00 до 21:00. Запись — в разделе «Запись» или через «+» на главной.';
    }
    if (contactId == 'specialist') {
      if (q.contains('отёк') ||
          q.contains('сып') ||
          q.contains('боль') ||
          q.contains('синяк') ||
          q.contains('гематом') ||
          q.contains('зуд') ||
          q.contains('покрасн')) {
        return 'Не наносите активные средства. Опишите зону и когда была процедура — врач ответит в приоритете.';
      }
      if (q.contains('анализ') || q.contains('результат')) {
        return 'Результаты появятся в кабинете → «Мои анализы». Если срочно — пришлите номер протокола.';
      }
      if (q.contains('формул') || q.contains('сыворот') || q.contains('крем')) {
        return 'По уходу дома уточните название формулы и как реагирует кожа — скорректируем схему.';
      }
      return 'Сообщение у врача. Если это отёк или сыпь после процедуры, не наносите активные средства до ответа.';
    }
    if (q.contains('запис')) {
      return 'Администратор поможет с записью. Укажите услугу и удобный день — ответим в часы клиники.';
    }
    if (q.contains('трансфер') || q.contains('такси')) {
      return 'Приняли запрос на трансфер. Уточните адрес подачи — подтвердим машину.';
    }
    if (q.contains('сертификат')) {
      return 'Сертификат оформим в приложении или на ресепшен. Напишите номинал — подскажем оплату.';
    }
    if (q.contains('парков')) {
      return 'Парковка у клиники свободная для гостей. Если места заняты — напишите, подскажем ближайший двор.';
    }
    if (q.contains('заказ') || q.contains('доставк') || q.contains('курьер')) {
      return 'Заказ из шопа видим. Уточните адрес или время самовывоза — подтвердим сборку.';
    }
    if (q.contains('бонус') || q.contains('лояльн')) {
      return 'Баланс бонусов — в профиле. Списать можно в корзине и на сертификат, правила — в «Лояльности».';
    }
    return 'Администратор получил сообщение и ответит в часы клиники.';
  }

  void setNotice(String key, bool value) {
    notices[key] = value;
    _save();
  }

  void setProfileName(String value) {
    profileName = value.trim();
    _save();
  }
}
