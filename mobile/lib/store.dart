import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  CartItem({required this.id, required this.name, required this.price, this.qty = 1});

  final String id;
  final String name;
  final int price;
  int qty;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price, 'qty': qty};

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
  });

  final String id;
  final String service;
  final String doctor;
  final String date;
  final String time;
  String status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'service': service,
        'doctor': doctor,
        'date': date,
        'time': time,
        'status': status,
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        service: json['service'] as String,
        doctor: json['doctor'] as String,
        date: json['date'] as String,
        time: json['time'] as String,
        status: json['status'] as String? ?? 'upcoming',
      );
}

class ShopOrder {
  ShopOrder({required this.id, required this.title, required this.total, required this.pay, required this.at});

  final String id;
  final String title;
  final int total;
  final String pay;
  final String at;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'total': total, 'pay': pay, 'at': at};

  factory ShopOrder.fromJson(Map<String, dynamic> json) => ShopOrder(
        id: json['id'] as String,
        title: json['title'] as String,
        total: json['total'] as int,
        pay: json['pay'] as String,
        at: json['at'] as String,
      );
}

class GiftCard {
  GiftCard({required this.id, required this.nominal, required this.design, required this.code});

  final String id;
  final int nominal;
  final String design;
  final String code;

  Map<String, dynamic> toJson() => {'id': id, 'nominal': nominal, 'design': design, 'code': code};

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
  ClinicStore() {
    appointments = [
      Appointment(
        id: 'seed-visit',
        service: 'Скульптурный массаж лица',
        doctor: 'AlethiaPro',
        date: '2026-03-12',
        time: '10:30',
      ),
    ];
  }

  static const _key = 'cult-flutter';

  List<CartItem> cart = [];
  List<Appointment> appointments = [];
  List<ShopOrder> orders = [];
  List<GiftCard> gifts = [];
  List<String> favorites = [];
  Map<String, List<ChatMessage>> threads = {};
  Map<String, bool> notices = {'visits': true, 'analyses': true, 'pharmacy': true, 'offers': false};
  int spent = 0;
  String profileName = 'Александра В.';

  int get balance => max(0, 12450 - spent);
  int get cartCount => cart.fold(0, (sum, item) => sum + item.qty);
  int get cartTotal => cart.fold(0, (sum, item) => sum + item.price * item.qty);

  List<Appointment> get upcoming => appointments.where((item) => item.status == 'upcoming').toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _seedThreads();
      return;
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    cart = (json['cart'] as List<dynamic>? ?? []).map((item) => CartItem.fromJson(item as Map<String, dynamic>)).toList();
    appointments = (json['appointments'] as List<dynamic>? ?? []).map((item) => Appointment.fromJson(item as Map<String, dynamic>)).toList();
    orders = (json['orders'] as List<dynamic>? ?? []).map((item) => ShopOrder.fromJson(item as Map<String, dynamic>)).toList();
    gifts = (json['gifts'] as List<dynamic>? ?? []).map((item) => GiftCard.fromJson(item as Map<String, dynamic>)).toList();
    favorites = (json['favorites'] as List<dynamic>? ?? []).cast<String>();
    spent = json['spent'] as int? ?? 0;
    profileName = json['profileName'] as String? ?? profileName;
    final savedNotices = json['notices'] as Map<String, dynamic>?;
    if (savedNotices != null) {
      notices = savedNotices.map((key, value) => MapEntry(key, value as bool));
    }
    final savedThreads = json['threads'] as Map<String, dynamic>?;
    threads = {};
    if (savedThreads != null) {
      for (final entry in savedThreads.entries) {
        threads[entry.key] = (entry.value as List<dynamic>).map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
      }
    }
    _seedThreads();
    notifyListeners();
  }

  void _seedThreads() {
    const seeds = {
      'admin': 'Здравствуйте. Помогу с записью, трансфером и сертификатом.',
      'bot': 'Я ассистент CULT. Спросите про услуги, часы или запись.',
      'specialist': 'Здравствуйте. Я на связи по уходу после процедур.',
    };
    for (final entry in seeds.entries) {
      threads.putIfAbsent(entry.key, () => [ChatMessage(id: '${entry.key}-seed', from: 'them', text: entry.value)]);
    }
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
      'profileName': profileName,
      'notices': notices,
      'threads': threads.map((key, value) => MapEntry(key, value.map((item) => item.toJson()).toList())),
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

  void toggleFavorite(String id) {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    _save();
  }

  void bookVisit({required String service, required String doctor, required String date, required String time}) {
    appointments.insert(
      0,
      Appointment(
        id: 'visit-${DateTime.now().microsecondsSinceEpoch}',
        service: service,
        doctor: doctor,
        date: date,
        time: time,
      ),
    );
    _save();
  }

  void cancelVisit(String id) {
    appointments.firstWhere((item) => item.id == id).status = 'cancelled';
    _save();
  }

  bool spendBonus(int amount) {
    if (amount <= 0 || amount > balance) return false;
    spent += amount;
    _save();
    return true;
  }

  void placeOrder({required String title, required int total, required String pay}) {
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
    final tail = List.generate(4, (_) => alphabet[random.nextInt(alphabet.length)]).join();
    final code = 'CULT-${nominal ~/ 1000}-$tail';
    gifts.insert(0, GiftCard(id: 'gift-${DateTime.now().microsecondsSinceEpoch}', nominal: nominal, design: design, code: code));
    _save();
    return code;
  }

  void sendMessage(String contactId, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final list = threads.putIfAbsent(contactId, () => []);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    list.add(ChatMessage(id: 'me-$stamp', from: 'me', text: trimmed));
    final reply = contactId == 'bot'
        ? 'Клиника открыта ежедневно с 9:00 до 21:00. Запись можно создать в разделе «Запись онлайн».'
        : contactId == 'specialist'
            ? 'Сообщение у врача. Если это отёк или сыпь после процедуры, не наносите активные средства до ответа.'
            : 'Администратор получил сообщение и ответит в часы клиники.';
    list.add(ChatMessage(id: 'them-$stamp', from: 'them', text: reply));
    _save();
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
