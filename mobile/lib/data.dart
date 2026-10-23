const photo = <String, String>{
  'sculpt': 'assets/media/0f50c015ddb4.png',
  'rf': 'assets/media/ed85bec7dbca.png',
  'hydra': 'assets/media/9673a90ea88f.png',
  'iv': 'assets/media/db95226522cc.png',
  'peel': 'assets/media/54ec98ffc172.png',
  'botox': 'assets/media/7070852df8a3.png',
  'filler': 'assets/media/da3e5b7e455d.png',
  'meso': 'assets/media/0dbdd37ca755.png',
  'neuro': 'assets/media/703bace11489.png',
  'catalyst': 'assets/media/de5704e17ec8.png',
  'gluta': 'assets/media/3ec07c2190fe.png',
  'mito': 'assets/media/e85ade9228ba.png',
  'scan': 'assets/media/0de7a9521861.png',
  'light': 'assets/media/8d4508751748.png',
  'patch': 'assets/media/bf076514c376.png',
  'alethia': 'assets/media/47e87da7ca21.png',
  'thorne': 'assets/media/1bd093d6ad83.png',
  'julian': 'assets/media/b0c7c749a4ab.png',
  'nad': 'assets/media/c752e2b47458.png',
  'sleep': 'assets/media/4f8413825d75.png',
  'avatar': 'assets/media/ef89f0b1f854.png',
  'offer': 'assets/media/46459e283ff3.png',
  'interior': 'assets/media/bc16b5df11db.png',
  'after': 'assets/media/7fc1b76736d8.png',
  'before': 'assets/media/d2d1c0de0870.png',
  'tone': 'assets/media/bfdbd6534f81.png',
  'glow': 'assets/media/7d03db2a4f04.png',
  'science': 'assets/media/4a5e5d6e77a9.png',
  'logo': 'assets/media/172e126eb1b3.png',
};

enum ClientGender {
  woman,
  man;

  String get label => this == ClientGender.woman ? 'Женщина' : 'Мужчина';
  String get forLabel =>
      this == ClientGender.woman ? 'для женщин' : 'для мужчин';
  String get servicesTitle =>
      this == ClientGender.woman ? 'Женские услуги' : 'Мужские услуги';
  int get ycSexId => this == ClientGender.man ? 1 : 2;
  String get storage => this == ClientGender.woman ? 'woman' : 'man';

  static ClientGender? tryParse(String? raw) {
    return switch (raw) {
      'woman' || 'female' || 'ж' => ClientGender.woman,
      'man' || 'male' || 'м' => ClientGender.man,
      _ => null,
    };
  }
}

enum ServiceAudience {
  all,
  women,
  men;

  bool matches(ClientGender gender) {
    return this == ServiceAudience.all ||
        (this == ServiceAudience.women && gender == ClientGender.woman) ||
        (this == ServiceAudience.men && gender == ClientGender.man);
  }
}

ServiceAudience audienceFromText(String title, [String category = '']) {
  final text = '${title.toLowerCase()} ${category.toLowerCase()}';
  if (RegExp(r'мужск|для мужчин|барбер|gentleman|для него').hasMatch(text)) {
    return ServiceAudience.men;
  }
  if (RegExp(r'женск|для женщин|антицеллюлит|для не[её]').hasMatch(text)) {
    return ServiceAudience.women;
  }
  return ServiceAudience.all;
}

class Service {
  const Service({
    required this.slug,
    required this.title,
    required this.category,
    required this.group,
    required this.priceLabel,
    required this.duration,
    required this.blurb,
    required this.long,
    required this.image,
    required this.results,
    required this.steps,
    required this.contraindications,
    this.audience = ServiceAudience.all,
  });

  final String slug;
  final String title;
  final String category;
  final String group;
  final String priceLabel;
  final String duration;
  final String blurb;
  final String long;
  final String image;
  final List<String> results;
  final List<String> steps;
  final List<String> contraindications;
  final ServiceAudience audience;
}

const services = <Service>[
  Service(
    slug: 'sculpt',
    title: 'Скульптурный массаж лица',
    category: 'Эстетика',
    group: 'Эстетика и уход',
    priceLabel: '18 000 ₽',
    duration: '60 мин',
    blurb: 'Мануальный лифтинг контура и снятие мышечного напряжения.',
    long:
        'Трансформирующая мануальная техника для лифтинга контуров лица и снятия мышечного напряжения. Улучшает лимфодренаж и возвращает коже сияние.',
    image: 'sculpt',
    results: ['Лифтинг и контуринг', 'Естественное сияние', 'Снятие отечности'],
    steps: ['Глубокое очищение', 'Проработка мышц', 'Лимфодренаж и уход'],
    contraindications: [
      'Острое воспаление кожи',
      'Температура',
      'Пилинг короче 7 дней назад',
    ],
    audience: ServiceAudience.women,
  ),
  Service(
    slug: 'rf',
    title: 'Микроигольчатый RF',
    category: 'Точность',
    group: 'Эстетика и уход',
    priceLabel: '45 000 ₽',
    duration: '90 мин',
    blurb: 'Радиочастота и иглы для уплотнения дермы.',
    long:
        'Импульс доходит до глубоких слоёв дермы и запускает уплотнение кожи без долгого восстановления.',
    image: 'rf',
    results: ['Плотность кожи', 'Сужение пор', 'Ровный рельеф'],
    steps: [
      'Анестезия и разметка',
      'Проходы RF-насадкой',
      'Успокаивающий уход',
    ],
    contraindications: [
      'Металлические импланты в зоне',
      'Беременность',
      'Кардиостимулятор',
    ],
  ),
  Service(
    slug: 'hydra',
    title: 'Инфузия HydraPure',
    category: 'Увлажнение',
    group: 'Эстетика и уход',
    priceLabel: '21 000 ₽',
    duration: '45 мин',
    blurb: 'Очищение и сыворотки за один визит.',
    long:
        'Многоэтапный уход очищает кожу и насыщает её сыворотками. Подходит как подготовка к инъекциям и как самостоятельный ритуал.',
    image: 'hydra',
    results: ['Чистота пор', 'Гладкость', 'Мгновенное увлажнение'],
    steps: ['Очищение', 'Вакуумная экстракция', 'Инфузия сыворотки'],
    contraindications: ['Активный герпес', 'Нарушенный барьер после кислот'],
    audience: ServiceAudience.women,
  ),
  Service(
    slug: 'iv',
    title: 'Витаминная IV-терапия',
    category: 'Велнес',
    group: 'Инфузии',
    priceLabel: '32 000 ₽',
    duration: '60 мин',
    blurb: 'Персональный коктейль для энергии и кожи.',
    long:
        'Состав собирается после короткой консультации. Нутриенты попадают сразу в кровоток.',
    image: 'iv',
    results: ['Энергия', 'Иммунная поддержка', 'Сияние кожи'],
    steps: ['Подбор коктейля', 'Постановка катетера', 'Наблюдение 60 минут'],
    contraindications: [
      'Почечная недостаточность',
      'Аллергия на компоненты коктейля',
    ],
  ),
  Service(
    slug: 'peel',
    title: 'Химический пилинг L3',
    category: 'Клинический',
    group: 'Эстетика и уход',
    priceLabel: '29 000 ₽',
    duration: '40 мин',
    blurb: 'Обновление тона и мелких морщин.',
    long:
        'Глубина L3 подбирается по фототипу и сезону. Цель — ровный тон без агрессивного шелушения.',
    image: 'peel',
    results: ['Ровный тон', 'Мягкое обновление', 'Меньше пигмента'],
    steps: ['Подготовка кожи', 'Нанесение состава', 'Нейтрализация и защита'],
    contraindications: ['Свежий загар', 'Изотретиноин', 'Беременность'],
    audience: ServiceAudience.women,
  ),
  Service(
    slug: 'botox',
    title: 'Ботулинотерапия',
    category: 'Инъекции',
    group: 'Инъекции',
    priceLabel: 'от 12 000 ₽',
    duration: '30 мин',
    blurb: 'Спокойная мимика без застывшего лица.',
    long:
        'Коррекция мимических морщин с сохранением живой мимики. Эффект обычно держится 4–6 месяцев.',
    image: 'botox',
    results: ['Спокойный лоб', 'Живая мимика', 'Эффект 4–6 месяцев'],
    steps: ['Осмотр мимики', 'Разметка точек', 'Введение препарата'],
    contraindications: [
      'Миастения',
      'Беременность',
      'Воспаление в точке вкола',
    ],
  ),
  Service(
    slug: 'filler',
    title: 'Контурная пластика',
    category: 'Инъекции',
    group: 'Инъекции',
    priceLabel: 'от 24 500 ₽',
    duration: '60 мин',
    blurb: 'Объём и контур гиалуроновой кислотой.',
    long:
        'Восполнение утраченных объёмов и гармонизация черт. План коррекции согласуют до первого вкола.',
    image: 'filler',
    results: ['Объём', 'Чёткий контур', 'Мгновенный эффект'],
    steps: ['План коррекции', 'Введение', 'Моделирование'],
    contraindications: [
      'Аутоиммунная вспышка',
      'Инфекция кожи',
      'Беременность',
    ],
    audience: ServiceAudience.women,
  ),
  Service(
    slug: 'meso',
    title: 'Мезотерапия',
    category: 'Инъекции',
    group: 'Инъекции',
    priceLabel: 'от 8 000 ₽',
    duration: '45 мин',
    blurb: 'Витаминный коктейль курсом из четырёх визитов.',
    long:
        'Коктейль из витаминов и аминокислот для питания кожи и работы с первыми признаками старения.',
    image: 'meso',
    results: ['Сияние', 'Увлажнение', 'Курс из 4 визитов'],
    steps: ['Очищение', 'Микроинъекции', 'Успокаивающая маска'],
    contraindications: ['Нарушение свёртываемости', 'Активное акне в зоне'],
    audience: ServiceAudience.women,
  ),
  Service(
    slug: 'men-face',
    title: 'Мужской уход за лицом',
    category: 'Эстетика',
    group: 'Эстетика и уход',
    priceLabel: '16 000 ₽',
    duration: '50 мин',
    blurb: 'Очищение, тонус и уход без тяжёлого блеска.',
    long:
        'Протокол для мужской кожи: очищение, тонизация, лёгкий лифтинг и финиш без эффекта макияжа.',
    image: 'sculpt',
    results: ['Чистая кожа', 'Ровный тон', 'Матовый финиш'],
    steps: ['Диагностика', 'Очищение и пилинг', 'Уход и защита'],
    contraindications: ['Острое воспаление', 'Свежий загар'],
    audience: ServiceAudience.men,
  ),
  Service(
    slug: 'men-rf',
    title: 'Мужской RF-лифтинг',
    category: 'Точность',
    group: 'Эстетика и уход',
    priceLabel: '42 000 ₽',
    duration: '75 мин',
    blurb: 'Плотность кожи и овал с мужским протоколом.',
    long:
        'RF-протокол для более плотной кожи: овал, поры и восстановление после нагрузок.',
    image: 'rf',
    results: ['Плотность', 'Чёткий овал', 'Меньше пор'],
    steps: ['Разметка', 'Проходы RF', 'Успокаивающий уход'],
    contraindications: ['Металлические импланты', 'Кардиостимулятор'],
    audience: ServiceAudience.men,
  ),
  Service(
    slug: 'men-barber',
    title: 'Барбер-массаж лица',
    category: 'Эстетика',
    group: 'Эстетика и уход',
    priceLabel: '12 000 ₽',
    duration: '40 мин',
    blurb: 'Глубокая проработка мышц и лимфы.',
    long: 'Плотный массаж лица и шеи для снятия зажимов после спорта и экрана.',
    image: 'sculpt',
    results: ['Снятие напряжения', 'Свежий вид', 'Лёгкость'],
    steps: ['Разогрев', 'Проработка мышц', 'Лимфодренаж'],
    contraindications: ['Температура', 'Острое воспаление кожи'],
    audience: ServiceAudience.men,
  ),
];

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.blurb,
    required this.price,
    required this.image,
    required this.tab,
    required this.composition,
    required this.about,
    this.stock = 'in',
    this.badge,
  });

  final String id;
  final String name;
  final String blurb;
  final int price;

  /// Asset key or `https://…` photo URL.
  /// Later: take URL from YClients service/good comment field.
  final String image;
  final String tab;
  final String stock;
  final String? badge;
  final String composition;
  final String about;
}

/// Temporary CDN photos for the shop; swap to YClients comment URLs when wired.
const products = <Product>[
  Product(
    id: 'neuro',
    name: 'Neuro-Regen IV Serum',
    blurb: 'Сыворотка для когнитивного усиления',
    price: 18400,
    image:
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=800&q=80',
    tab: 'supplements',
    composition: 'Фосфатидилсерин, цитиколин, витамин B12',
    about:
        'Формула к курсам, где важны ясность и восстановление после нагрузок.',
  ),
  Product(
    id: 'catalyst',
    name: 'Cellular Catalyst 01',
    blurb: 'Формула-предшественник NAD+',
    price: 24500,
    image:
        'https://images.unsplash.com/photo-1620916569866-af8c5a8a1260?w=800&q=80',
    tab: 'supplements',
    badge: 'Фаворит CULT',
    composition: 'Никотинамидрибозид, птеростильбен',
    about: 'Назначают вместе с инфузией или отдельным курсом.',
  ),
  Product(
    id: 'gluta',
    name: 'Liposomal Gluta-Pure',
    blurb: 'Мастер-антиоксидантный комплекс',
    price: 12000,
    image:
        'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=800&q=80',
    tab: 'supplements',
    composition: 'Липосомальный глутатион, витамин C',
    about: 'Антиоксидантная поддержка после аппаратных процедур.',
  ),
  Product(
    id: 'mito',
    name: 'Mitochondrial Fuel',
    blurb: 'Ускоритель производства АТФ',
    price: 15500,
    image:
        'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=800&q=80',
    tab: 'supplements',
    stock: 'low',
    composition: 'Коэнзим Q10, PQQ, магний',
    about: 'Поддержка выработки энергии. Не принимать вечером.',
  ),
  Product(
    id: 'lumen',
    name: 'Lumen Barrier Cream',
    blurb: 'Барьерный крем с церамидами',
    price: 8900,
    image:
        'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=800&q=80',
    tab: 'cosmetics',
    composition: 'Церамиды NP, холестерол, сквалан',
    about: 'Восстанавливает липидный слой после пилингов и RF.',
  ),
  Product(
    id: 'veil',
    name: 'Veil Peptide Serum',
    blurb: 'Ночная сыворотка плотности',
    price: 14200,
    image:
        'https://images.unsplash.com/photo-1620916297397-a4a5402a3ed6?w=800&q=80',
    tab: 'cosmetics',
    badge: 'Фаворит CULT',
    composition: 'Матриксил, медь, пантенол',
    about: 'Домашний шаг между визитами к AlethiaPro.',
  ),
  Product(
    id: 'aura',
    name: 'Aura Mineral Mist',
    blurb: 'Минеральный спрей сияния',
    price: 6400,
    image:
        'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=800&q=80',
    tab: 'cosmetics',
    stock: 'low',
    composition: 'Цинк, термальная вода, ниацинамид',
    about: 'Лёгкий шаг в течение дня, когда крем уже есть.',
  ),
  Product(
    id: 'scan',
    name: 'Home Bio-Scan Kit',
    blurb: 'Домашний набор биомаркеров',
    price: 32000,
    image:
        'https://images.unsplash.com/photo-1582719471384-894fbb16e074?w=800&q=80',
    tab: 'biohack',
    badge: 'Новинка',
    composition: 'Ланцеты, полоски, инструкция по 12 маркерам',
    about: 'Результат приходит в кабинет, врач комментирует в чате.',
  ),
  Product(
    id: 'light',
    name: 'Circadian Light Panel',
    blurb: 'Панель утреннего света',
    price: 27500,
    image:
        'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=800&q=80',
    tab: 'biohack',
    composition: 'Светодиоды 480 нм и 650 нм',
    about: '10 минут в первый час после подъёма.',
  ),
  Product(
    id: 'patch',
    name: 'NAD+ Micro-Patch',
    blurb: 'Пластырь-предшественник на 12 часов',
    price: 9800,
    image:
        'https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?w=800&q=80',
    tab: 'biohack',
    stock: 'low',
    composition: 'Предшественник NAD+, клеевая основа',
    about: 'Носится в дни без инфузии.',
  ),
];

class Doctor {
  const Doctor({
    required this.slug,
    required this.name,
    required this.role,
    required this.exp,
    required this.image,
    required this.education,
    required this.about,
    required this.reviews,
  });

  final String slug;
  final String name;
  final String role;
  final String exp;
  final String image;
  final String education;
  final String about;
  final List<String> reviews;
}

const doctors = <Doctor>[
  Doctor(
    slug: 'alethia',
    name: 'AlethiaPro',
    role: 'Эстетическая дерматология',
    exp: '12+ лет',
    image: 'alethia',
    education: 'Morpheus8, Ultherapy, инъекции лица.',
    about: 'Контур, аппараты и уход между визитами.',
    reviews: ['Овал собрался к третьему сеансу — без «сделанного» лица.'],
  ),
  Doctor(
    slug: 'thorne',
    name: 'Д-р Элара Торн',
    role: 'Холистическое здоровье',
    exp: '15+ лет',
    image: 'thorne',
    education: 'MD · нутрициология · долголетие.',
    about: 'Инфузии и добавки после разбора сна и анализов.',
    reviews: ['Beauty & Glow дал плотность кожи без инъекций.'],
  ),
  Doctor(
    slug: 'julian',
    name: 'Д-р Джулиан Торн',
    role: 'Инфузии и нутрициология',
    exp: '10+ лет',
    image: 'julian',
    education: 'NAD+ и архитектура сна.',
    about: 'Подбирает инфузии по задаче, без лишних капельниц.',
    reviews: ['После NAD+ утро стало собранным.'],
  ),
];

class Article {
  const Article({
    required this.slug,
    required this.title,
    required this.kicker,
    required this.author,
    required this.image,
    required this.body,
  });
  final String slug;
  final String title;
  final String kicker;
  final String author;
  final String image;
  final List<String> body;
}

const articles = <Article>[
  Article(
    slug: 'nad',
    title: 'Правда об инфузиях NAD+',
    kicker: 'CULT TV',
    author: 'Д-р Джулиан Торн',
    image: 'nad',
    body: [
      'NAD+ участвует в восстановлении клеток и в работе митохондрий. С возрастом его уровень падает, поэтому инфузия ощущается как ясность, а не как витаминная капельница.',
      'В CULT дозу собирают после короткого разбора: сон, нагрузка, анализы. Курс обычно четыре визита.',
    ],
  ),
  Article(
    slug: 'sleep',
    title: 'Оптимизация архитектуры сна',
    kicker: 'Нутрициология',
    author: 'Нутрициология и биохакинг',
    image: 'sleep',
    body: [
      'Сон ломается от света после 22:00 и кофе после обеда. Мы смотрим на это как на протокол.',
      'Начинают со светового окна утром. Добавки подключают, только если дневник сна за неделю не сдвигается.',
    ],
  ),
];

class ClinicCase {
  const ClinicCase({
    required this.slug,
    required this.title,
    required this.procedure,
    required this.doctor,
    required this.image,
    required this.text,
  });
  final String slug;
  final String title;
  final String procedure;
  final String doctor;
  final String image;
  final String text;
}

const cases = <ClinicCase>[
  ClinicCase(
    slug: 'oval',
    title: 'Чёткий овал без операции',
    procedure: 'Morpheus8',
    doctor: 'AlethiaPro',
    image: 'after',
    text:
        'Три сеанса с паузой четыре недели. Без филлеров. Покраснение на два дня.',
  ),
  ClinicCase(
    slug: 'tone',
    title: 'Ровный тон за два визита',
    procedure: 'Lumecca IPL',
    doctor: 'AlethiaPro',
    image: 'tone',
    text:
        'Два сеанса. Между ними только барьер и SPF. Тон выровнялся к третьей неделе.',
  ),
  ClinicCase(
    slug: 'glow',
    title: 'Сияние изнутри',
    procedure: 'Beauty & Glow',
    doctor: 'Д-р Элара Торн',
    image: 'glow',
    text: 'Три инфузии и домашний барьерный крем. Без инъекций.',
  ),
];

class Device {
  const Device({
    required this.title,
    required this.meta,
    required this.price,
    required this.text,
    this.badge = '',
    this.tag = '',
    this.zone = 'Лицо / шея',
    this.image = 'science',
    this.indications = const [],
    this.benefits = const [],
  });
  final String title;
  final String meta;
  final String price;
  final String text;
  final String badge;
  final String tag;
  final String zone;
  final String image;
  final List<String> indications;
  final List<String> benefits;
}

const devices = <Device>[
  Device(
    title: 'Ultherapy®',
    meta: '90 мин',
    price: '85 000 ₽',
    badge: 'TOP 2026',
    tag: 'Face Lift',
    image: 'after',
    text: 'SMAS-лифтинг с визуализацией. Без операции.',
    indications: ['Снижение овала', 'Дряблость', 'Морщины шеи'],
    benefits: [
      'Лифтинг на уровне SMAS',
      'Короткий период восстановления',
      'Эффект до 2–3 лет',
    ],
  ),
  Device(
    title: 'Morpheus8',
    meta: '60 мин',
    price: '42 000 ₽',
    badge: 'Выбор Голливуда',
    tag: 'Skin Tightening',
    image: 'rf',
    text: 'Игольчатый RF для плотности кожи и овала.',
    indications: ['Дряблость', 'Потеря овала', 'Неровный рельеф', 'Постакне'],
    benefits: ['Стимуляция коллагена', 'Реабилитация 2–3 дня', 'Лицо и шея'],
  ),
  Device(
    title: 'Lumecca IPL',
    meta: '45 мин',
    price: '18 500 ₽',
    badge: 'CULT рекомендует',
    tag: 'Photo-rejuvenation',
    image: 'tone',
    text: 'Фотоомоложение пигмента и сосудов за 1–2 сеанса.',
    indications: ['Пигмент', 'Сосуды', 'Нервный тон'],
    benefits: ['Быстрый результат', 'Мягкая реабилитация', 'Ровный тон'],
  ),
  Device(
    title: 'BodyTite',
    meta: '90 мин',
    price: '95 000 ₽',
    badge: 'Тело',
    tag: 'Body Contour',
    zone: 'Тело',
    image: 'science',
    text: 'RF-липосакция и уплотнение кожи тела без длинной реабилитации.',
    indications: ['Локальный жир', 'Дряблость тела', 'Контур'],
    benefits: [
      'Лицо не затрагивается',
      'Короткая реабилитация',
      'Точный контур',
    ],
  ),
];

class Infusion {
  const Infusion({
    required this.title,
    required this.price,
    required this.duration,
    required this.blurb,
    required this.image,
    required this.chip,
  });
  final String title;
  final String price;
  final String duration;
  final String blurb;
  final String image;
  final String chip;
}

const infusions = <Infusion>[
  Infusion(
    title: 'NAD+ Energy',
    price: '15 000 ₽',
    duration: '60 мин',
    blurb: 'Клеточная энергия и ясность.',
    image: 'nad',
    chip: 'Energy',
  ),
  Infusion(
    title: 'Immunity Boost',
    price: '12 000 ₽',
    duration: '45 мин',
    blurb: 'Защита в период стресса.',
    image: 'iv',
    chip: 'Detox',
  ),
  Infusion(
    title: 'Beauty & Glow',
    price: '18 000 ₽',
    duration: '75 мин',
    blurb: 'Сияние кожи изнутри.',
    image: 'glow',
    chip: 'Beauty',
  ),
];

class PastVisit {
  const PastVisit({
    required this.date,
    required this.title,
    required this.doctor,
    required this.place,
    required this.receipt,
  });
  final String date;
  final String title;
  final String doctor;
  final String place;
  final String receipt;
}

const pastVisits = <PastVisit>[
  PastVisit(
    date: '2 февраля 2026',
    title: 'Morpheus8',
    doctor: 'AlethiaPro',
    place: 'Кабинет 4',
    receipt: '42 000 ₽',
  ),
  PastVisit(
    date: '18 января 2026',
    title: 'NAD+ Energy',
    doctor: 'Д-р Элара Торн',
    place: 'Инфузионная',
    receipt: '15 000 ₽',
  ),
  PastVisit(
    date: '9 декабря 2025',
    title: 'Консультация',
    doctor: 'AlethiaPro',
    place: 'Кабинет 2',
    receipt: '0 ₽',
  ),
];

class LabVisit {
  const LabVisit({
    required this.title,
    required this.date,
    required this.status,
  });
  final String title;
  final String date;
  final String status;
}

const labVisits = <LabVisit>[
  LabVisit(
    title: 'ДНК-тест старения',
    date: '20 марта 2026',
    status: 'Назначен',
  ),
  LabVisit(title: 'Анализ крови', date: '2 февраля 2026', status: 'Готов'),
  LabVisit(title: 'Гормональный тест', date: '18 января 2026', status: 'Сдан'),
];

class PharmacyItem {
  const PharmacyItem({
    required this.productId,
    required this.dose,
    required this.doctor,
    required this.until,
    required this.note,
  });
  final String productId;
  final String dose;
  final String doctor;
  final String until;
  final String note;
}

const pharmacy = <PharmacyItem>[
  PharmacyItem(
    productId: 'gluta',
    dose: '1 капсула утром, после еды',
    doctor: 'AlethiaPro',
    until: 'до апреля 2026',
    note: 'После Morpheus8, вечером, без кислот.',
  ),
  PharmacyItem(
    productId: 'catalyst',
    dose: 'по схеме NAD+, 4 недели',
    doctor: 'Д-р Элара Торн',
    until: 'до марта 2026',
    note: 'Курс энергии, если сон короче 6 часов.',
  ),
];

const certificateNominals = [5000, 15000, 30000];

class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.role,
    required this.seed,
  });
  final String id;
  final String name;
  final String role;
  final String seed;
}

/// Bump when shipping a user-visible feature so a Mac pull proves the build is fresh.
const cultBuildTag = 'mira-live-v27';

const contacts = <Contact>[
  Contact(
    id: 'bot',
    name: 'Мира',
    role: 'Косметолог CULT · голосом',
    seed:
        'Здравствуйте, я Мира — косметолог CULT. Расскажите, что с кожей или самочувствием: подберу наши услуги и уход. Если захотите визит — уточню детали и попрошу ваше подтверждение.',
  ),
  Contact(
    id: 'admin',
    name: 'Администратор',
    role: 'Расписание и логистика',
    seed: 'Здравствуйте. Помогу с записью, трансфером и сертификатом.',
  ),
  Contact(
    id: 'specialist',
    name: 'Специалист',
    role: 'Клиническая консультация',
    seed: 'Здравствуйте. Я на связи по уходу после процедур.',
  ),
];

const loyaltyRules = [
  'Платина: до 30% чека можно закрыть бонусами.',
  'Начисление — 10% от оплаченных услуг.',
  'Бонус новым клиентам 3 000 ₽ действует 12 месяцев.',
];

Service? serviceBySlug(String slug) {
  for (final item in services) {
    if (item.slug == slug) return item;
  }
  return null;
}

Product? productById(String id) {
  for (final item in products) {
    if (item.id == id) return item;
  }
  return null;
}

Doctor? doctorBySlug(String slug) {
  for (final item in doctors) {
    if (item.slug == slug) return item;
  }
  return null;
}
