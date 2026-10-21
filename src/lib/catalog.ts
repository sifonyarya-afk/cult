import { img } from "./media";

export type Service = {
  slug: string;
  title: string;
  category: string;
  filter: string;
  price: string;
  duration: string;
  chip: string;
  chipIcon: string;
  badge?: string;
  blurb: string;
  long: string;
  image: string;
  results: string[];
  steps: string[];
  hiddenUntilMore?: boolean;
};

export const services: Service[] = [
  {
    slug: "sculpt",
    title: "Скульптурный массаж лица",
    category: "Эстетика",
    filter: "Эстетика",
    price: "18 000 ₽",
    duration: "60 мин",
    chip: "Эстетика",
    chipIcon: "spa",
    badge: "Авторский",
    blurb:
      "Трансформирующая мануальная техника, направленная на лифтинг контуров лица и снятие мышечного напряжения.",
    long: "Трансформирующая мануальная техника, направленная на лифтинг контуров лица и снятие мышечного напряжения. Процедура способствует улучшению лимфодренажа и возвращает коже естественное сияние.",
    image: img("AB6AXuAEwes9nqkcks7V"),
    results: ["Лифтинг и контуринг", "Естественное сияние", "Снятие отечности"],
    steps: [
      "Глубокое очищение и подготовка кожи",
      "Скульптурная проработка глубоких мышц",
      "Лимфодренажное завершение и уход",
    ],
  },
  {
    slug: "rf",
    title: "Микроигольчатый RF",
    category: "Точность",
    filter: "Эстетика",
    price: "45 000 ₽",
    duration: "90 мин",
    chip: "Точность",
    chipIcon: "bolt",
    blurb:
      "Клиническая терапия индукции коллагена в сочетании с радиочастотной энергией для глубокого восстановления дермы.",
    long: "Клиническая терапия индукции коллагена в сочетании с радиочастотной энергией. Импульс доходит до глубоких слоёв дермы и запускает уплотнение кожи без длительного восстановления.",
    image: img("AB6AXuAx2hjAVGH2zh6z"),
    results: ["Плотность кожи", "Сужение пор", "Ровный рельеф"],
    steps: ["Анестезия и разметка", "Проходы RF-насадкой", "Успокаивающий уход"],
  },
  {
    slug: "hydra",
    title: "Инфузия HydraPure",
    category: "Увлажнение",
    filter: "Эстетика",
    price: "21 000 ₽",
    duration: "45 мин",
    chip: "Увлажнение",
    chipIcon: "water_drop",
    blurb:
      "Многоэтапный уход, который очищает и отшелушивает, одновременно насыщая кожу питательными сыворотками.",
    long: "Многоэтапный уход очищает и отшелушивает кожу, одновременно насыщая её сыворотками. Подходит как подготовка к инъекциям и как самостоятельный ритуал сияния.",
    image: img("AB6AXuA6H8w-lkGAbbQ1"),
    results: ["Чистота пор", "Гладкость", "Мгновенное увлажнение"],
    steps: ["Очищение", "Вакуумная экстракция", "Инфузия сыворотки"],
  },
  {
    slug: "iv",
    title: "Витаминная IV-терапия",
    category: "Велнес",
    filter: "Велнес",
    price: "32 000 ₽",
    duration: "60 мин",
    chip: "Велнес",
    chipIcon: "medical_services",
    blurb: "Персонализированные инфузии нутриентов для максимального усвоения и клеточного омоложения.",
    long: "Персонализированные инфузии нутриентов для максимального усвоения и клеточного омоложения. Состав собирается после короткой консультации.",
    image: img("AB6AXuDLeDKcapptQhHW"),
    results: ["Энергия", "Иммунная поддержка", "Сияние кожи"],
    steps: ["Подбор коктейля", "Постановка катетера", "Наблюдение 60 минут"],
  },
  {
    slug: "peel",
    title: "Химический пилинг L3",
    category: "Клинический",
    filter: "Эстетика",
    price: "29 000 ₽",
    duration: "40 мин",
    chip: "Клинический",
    chipIcon: "science",
    blurb: "Продвинутая процедура обновления кожи, направленная на коррекцию пигментации и мимических морщин.",
    long: "Продвинутое обновление кожи для коррекции пигментации и мимических морщин. Глубина L3 подбирается по фототипу и сезону.",
    image: img("AB6AXuBDh2sZNBCIyYHy"),
    results: ["Ровный тон", "Мягкое обновление", "Меньше пигмента"],
    steps: ["Подготовка кожи", "Нанесение состава", "Нейтрализация и защита"],
  },
  {
    slug: "botox",
    title: "Ботулинотерапия",
    category: "Инъекции",
    filter: "Инъекции",
    price: "от 12 000 ₽",
    duration: "30 мин",
    chip: "Минимальная реабилитация",
    chipIcon: "spa",
    badge: "Best Seller",
    blurb:
      "Эффективная коррекция мимических морщин. Сохраняем живую мимику, возвращая лицу отдохнувший и свежий вид.",
    long: "Эффективная коррекция мимических морщин. Сохраняем живую мимику, возвращая лицу отдохнувший и свежий вид.",
    image: img("AB6AXuBz8ejdWzTqb-8_"),
    results: ["Спокойный лоб", "Живая мимика", "Эффект 4–6 месяцев"],
    steps: ["Осмотр мимики", "Разметка точек", "Введение препарата"],
    hiddenUntilMore: true,
  },
  {
    slug: "filler",
    title: "Контурная пластика",
    category: "Инъекции",
    filter: "Инъекции",
    price: "от 24 500 ₽",
    duration: "60 мин",
    chip: "Мгновенный результат",
    chipIcon: "auto_awesome",
    blurb:
      "Восполнение утраченных объемов и гармонизация черт лица с помощью филлеров на основе гиалуроновой кислоты.",
    long: "Восполнение утраченных объёмов и гармонизация черт лица филлерами на основе гиалуроновой кислоты.",
    image: img("AB6AXuBZ4UyHUzMv4SVc"),
    results: ["Объём", "Чёткий контур", "Мгновенный эффект"],
    steps: ["План коррекции", "Введение канюлей или иглой", "Моделирование"],
    hiddenUntilMore: true,
  },
  {
    slug: "meso",
    title: "Мезотерапия",
    category: "Инъекции",
    filter: "Инъекции",
    price: "от 8 000 ₽",
    duration: "45 мин",
    chip: "Курсовая процедура",
    chipIcon: "shutter_speed",
    blurb:
      "Коктейль из витаминов и аминокислот для глубокого питания кожи, сияния и борьбы с первыми признаками старения.",
    long: "Коктейль из витаминов и аминокислот для питания кожи, сияния и работы с первыми признаками старения.",
    image: img("AB6AXuDNFsewSwnsHP3b"),
    results: ["Сияние", "Увлажнение", "Курс из 4 визитов"],
    steps: ["Очищение", "Микроинъекции", "Успокаивающая маска"],
    hiddenUntilMore: true,
  },
];

export function serviceBySlug(slug: string) {
  return services.find((item) => item.slug === slug);
}

export type Product = {
  id: string;
  name: string;
  blurb: string;
  price: number;
  priceLabel: string;
  image: string;
  stock: "in" | "low";
  badge?: string;
  tab: "cosmetics" | "supplements";
};

export const products: Product[] = [
  {
    id: "neuro",
    name: "Neuro-Regen IV Serum",
    blurb: "Сыворотка для когнитивного усиления",
    price: 18400,
    priceLabel: "18 400 ₽",
    image: img("AB6AXuBqBNkQI9_RyhCY"),
    stock: "in",
    tab: "supplements",
  },
  {
    id: "catalyst",
    name: "Cellular Catalyst 01",
    blurb: "Формула-предшественник NAD+",
    price: 24500,
    priceLabel: "24 500 ₽",
    image: img("AB6AXuDGV7g1mn5ttGbL"),
    stock: "in",
    badge: "Фаворит CULT",
    tab: "supplements",
  },
  {
    id: "gluta",
    name: "Liposomal Gluta-Pure",
    blurb: "Мастер-антиоксидантный комплекс",
    price: 12000,
    priceLabel: "12 000 ₽",
    image: img("AB6AXuC1ENctSuipm79F"),
    stock: "in",
    tab: "supplements",
  },
  {
    id: "mito",
    name: "Mitochondrial Fuel",
    blurb: "Ускоритель производства АТФ",
    price: 15500,
    priceLabel: "15 500 ₽",
    image: img("AB6AXuB7eMIas6P0kpNt"),
    stock: "low",
    tab: "supplements",
  },
  {
    id: "lumen",
    name: "Lumen Barrier Cream",
    blurb: "Барьерный крем с церамидами",
    price: 8900,
    priceLabel: "8 900 ₽",
    image: img("AB6AXuA6H8w-lkGAbbQ1"),
    stock: "in",
    tab: "cosmetics",
  },
  {
    id: "veil",
    name: "Veil Peptide Serum",
    blurb: "Ночная сыворотка плотности",
    price: 14200,
    priceLabel: "14 200 ₽",
    image: img("AB6AXuAEwes9nqkcks7V"),
    stock: "in",
    badge: "Фаворит CULT",
    tab: "cosmetics",
  },
  {
    id: "aura",
    name: "Aura Mineral Mist",
    blurb: "Минеральный спрей сияния",
    price: 6400,
    priceLabel: "6 400 ₽",
    image: img("AB6AXuBDh2sZNBCIyYHy"),
    stock: "low",
    tab: "cosmetics",
  },
];

export type Device = {
  slug: string;
  title: string;
  italic: string;
  badge: string;
  badgeClass: string;
  price: string;
  priceShort: string;
  duration: string;
  zone: string;
  zoneLabel: string;
  blurb: string;
  image: string;
  hero: string;
  about: string[];
  indications: string[];
  quote: string;
  checks: string[];
};

export const devices: Device[] = [
  {
    slug: "morpheus8",
    title: "Morpheus8",
    italic: "Лифтинг и регенерация",
    badge: "ВЫБОР ГОЛЛИВУДА",
    badgeClass: "bg-secondary text-white",
    price: "42 000 ₽",
    priceShort: "42,000 ₽",
    duration: "60 мин",
    zone: "ЛИЦО / ШЕЯ",
    zoneLabel: "Skin Tightening",
    blurb: "Фракционная игольчатая RF-терапия для глубокой реконструкции кожи и подкожно-жировой клетчатки.",
    image: img("AB6AXuCuDFZwkRoSthYZ"),
    hero: img("AB6AXuCZRv02gMJT"),
    about: [
      "Фракционная игольчатая RF-терапия для глубокой реконструкции кожи и подкожно-жировой клетчатки. Стимулирует выработку коллагена и эластина, обеспечивая эффект лифтинга без хирургического вмешательства.",
      "Morpheus8 воздействует на глубокие слои дермы микроиглами, которые передают радиочастотную энергию. Кожа подтягивается, текстура выравнивается, поры и мелкие морщины становятся менее заметны.",
    ],
    indications: ["Дряблость кожи", "Морщины и заломы", "Потеря четкости овала лица", "Неровный рельеф"],
    quote: "Золотой стандарт неинвазивного лифтинга, сочетающий безопасность медицинской технологии с комфортом спа-ухода.",
    checks: [
      "Стимуляция собственного коллагена и эластина",
      "Минимальный период реабилитации (2-3 дня)",
      "Устранение рубцов постакне и растяжек",
    ],
  },
  {
    slug: "ultherapy",
    title: "Ultherapy®",
    italic: "SMAS-лифтинг без операции",
    badge: "TOP ПРОЦЕДУРА 2026",
    badgeClass: "bg-primary text-white",
    price: "85 000 ₽",
    priceShort: "85,000 ₽",
    duration: "90 мин",
    zone: "ЛИЦО / ШЕЯ",
    zoneLabel: "Face Lift",
    blurb: "Единственная процедура с визуализацией, одобренная FDA для безоперационного лифтинга на уровне SMAS.",
    image: img("AB6AXuDfEbRsTwitGL1W"),
    hero: img("AB6AXuD46SLnfL8HM2"),
    about: [
      "Ультразвуковой лифтинг с визуализацией слоёв. Энергия доходит до SMAS — той же плоскости, с которой работает хирург.",
      "Врач видит глубину импульса на экране и ставит линии точно по карте лица.",
    ],
    indications: ["Опущение овала", "Второй подбородок", "Дряблость шеи", "Потеря тонуса"],
    quote: "Лифтинг с контролем глубины: врач видит слой, в который уходит энергия.",
    checks: ["FDA-протокол SMAS", "Результат нарастает 3 месяца", "Без разрезов"],
  },
  {
    slug: "lumecca",
    title: "Lumecca IPL",
    italic: "Свет и ровный тон",
    badge: "CULT РЕКОМЕНДУЕТ",
    badgeClass: "bg-on-background/80 text-white",
    price: "18 500 ₽",
    priceShort: "18,500 ₽",
    duration: "45 мин",
    zone: "ЛИЦО",
    zoneLabel: "Photo-rejuvenation",
    blurb: "Самая мощная система фотоомоложения для удаления пигментации и сосудистых дефектов за 1-2 сеанса.",
    image: img("AB6AXuDaXMzrLpWHAiJe"),
    hero: img("AB6AXuDaXMzrLpWHAiJe"),
    about: [
      "Интенсивный импульсный свет выравнивает тон, гасит сосуды и пигмент за один-два сеанса.",
      "Процедура короткая. Кожа светлеет постепенно, без агрессивного шелушения.",
    ],
    indications: ["Пигментные пятна", "Купероз", "Тусклый тон", "Фотостарение"],
    quote: "Свет, который возвращает коже ровный, спокойный тон.",
    checks: ["1–2 сеанса", "Короткое восстановление", "Лицо, шея, декольте"],
  },
];

export function deviceBySlug(slug: string) {
  return devices.find((item) => item.slug === slug);
}

export const infusions = [
  {
    id: "nad",
    title: "NAD+ Energy",
    price: "15 000 ₽",
    minutes: "60 min",
    text: "Золотой стандарт клеточной регенерации и ментальной ясности.",
    image: img("AB6AXuBns-XjqX4tveqv"),
    chip: "Energy",
  },
  {
    id: "immunity",
    title: "Immunity Boost",
    price: "12 000 ₽",
    minutes: "45 min",
    text: "Защитный барьер и поддержка организма в период стресса.",
    image: img("AB6AXuAuCx8Kn_M8c3dt"),
    chip: "Longevity",
  },
  {
    id: "glow",
    title: "Beauty & Glow",
    price: "18 000 ₽",
    minutes: "75 min",
    text: "Глубокое увлажнение и сияние кожи изнутри.",
    image: img("AB6AXuCN9PTu3AkRBmoO"),
    chip: "Beauty",
  },
];

export const contacts = [
  {
    id: "admin",
    name: "Администратор",
    role: "Расписание и логистика",
    text: "Управление записями, вопросы по оплате и документации через нашу консьерж-службу.",
    image: img("AB6AXuAcN18o8Noxrg2l"),
    seed: "Добрый день. Консьерж CULT на связи — помогу с записью, оплатой и трансфером.",
  },
  {
    id: "bot",
    name: "Бот клиники",
    role: "ИИ-ассистент, 24/7",
    text: "Мгновенные ответы на общие вопросы и помощь в навигации по услугам клиники в любое время.",
    image: "",
    seed: "Я ассистент CULT. Спросите про услуги, часы работы или как записаться.",
  },
  {
    id: "specialist",
    name: "Специалист",
    role: "Клиническая консультация",
    text: "Обсуждение результатов лечения, послеоперационного ухода или медицинских вопросов напрямую.",
    image: img("AB6AXuA4DpKF82rugW6x"),
    seed: "Здравствуйте. Я на связи по уходу после процедур и клиническим вопросам.",
  },
];

export const pastVisits = [
  { date: "2 февраля 2026", title: "Morpheus8", doctor: "AlethiaPro", place: "Кабинет 4" },
  { date: "18 января 2026", title: "NAD+ Energy", doctor: "Д-р Элара Торн", place: "Инфузионная" },
  { date: "9 декабря 2025", title: "Консультация", doctor: "AlethiaPro", place: "Кабинет 2" },
];

export const analyses = [
  { id: "blood", name: "Анализ крови Фев_24.pdf" },
  { id: "hormone", name: "Гормональный тест Янв_24.pdf" },
];

export const doctors = [
  {
    slug: "alethia",
    name: "AlethiaPro",
    role: "Специалист эстетической дерматологии",
    image: img("AB6AXuBWhsXgCtKoSN"),
    href: "/specialists",
    chat: "/chat/specialist",
    exp: "12+ лет",
  },
  {
    slug: "thorne",
    name: "Д-р Элара Торн, MD",
    role: "Директор по холистическому здоровью",
    image: img("AB6AXuC_2g-J0di2yK"),
    href: "/doctors/thorne",
    chat: "/chat/specialist",
    exp: "15+ лет",
  },
  {
    slug: "julian",
    name: "Д-р Джулиан Торн",
    role: "Инфузии и нутрициология",
    image: img("AB6AXuDB0rcVzIawlY4J"),
    href: "/doctors/julian",
    chat: "/chat/specialist",
    exp: "10+ лет",
  },
];

export const articles = [
  {
    slug: "nad",
    title: "Правда об инфузиях NAD+",
    kicker: "CULT TV",
    minutes: "15:20",
    author: "Д-р Джулиан Торн",
    image: img("AB6AXuASlJ4xAxwuwk"),
    kind: "video" as const,
    lead: "Коротко о том, что NAD+ делает с клеточной энергией и кому курс действительно нужен.",
    body: [
      "NAD+ участвует в восстановлении клеток и в работе митохондрий. С возрастом его уровень падает, поэтому инфузия ощущается как ясность и запас сил, а не как «витаминная капельница».",
      "В CULT дозу собирают после короткого разбора: сон, нагрузка, анализы. Один сеанс не заменяет режим, но часто становится точкой, с которой человек возвращает утро.",
      "Курс обычно 4 визита. Между ними не нужны активные кислоты на лице, если в тот же день была эстетическая процедура.",
    ],
  },
  {
    slug: "sleep",
    title: "Оптимизация архитектуры сна",
    kicker: "Нутрициология",
    minutes: "08:45",
    author: "Нутрициология и биохакинг",
    image: img("AB6AXuCKU4PMdaaQHE"),
    kind: "video" as const,
    lead: "Как свет, еда и температура собирают глубокий сон без снотворных.",
    body: [
      "Архитектура сна ломается не от одного позднего ужина, а от света после 22:00 и кофе после обеда. Мы смотрим на это как на протокол, а не на силу воли.",
      "В клинике начинают со светового окна утром и тёплого приёма пищи вечером. Добавки подключают только если дневник сна за неделю не сдвигается.",
    ],
  },
  {
    slug: "sculpt-guide",
    title: "Как читать результат массажа лица",
    kicker: "Практика",
    minutes: "чтение 4 мин",
    author: "AlethiaPro",
    image: img("AB6AXuAEwes9nqkcks7V"),
    kind: "article" as const,
    lead: "Что считается нормальным на следующий день и когда ждать контур.",
    body: [
      "Сразу после скульптурного массажа лицо может быть чуть розовым. Это приток, не воспаление. Отёк, наоборот, обычно спадает к утру.",
      "Контур читается на 3–5 день, когда уходит лишняя жидкость. Повтор имеет смысл через 7–10 дней, не на следующий день.",
    ],
  },
];

export function articleBySlug(slug: string) {
  return articles.find((item) => item.slug === slug);
}

export const cases = [
  {
    slug: "oval",
    title: "Чёткий овал без операции",
    procedure: "Morpheus8",
    doctor: "AlethiaPro",
    image: img("AB6AXuAT42Rrdjnuii"),
    before: img("AB6AXuDfygIvD0sRch"),
    after: img("AB6AXuAT42Rrdjnuii"),
    quote: "Плотность кожи изменилась после первого сеанса. Овал собрался к третьему.",
    text: "Три сеанса Morpheus8 с паузой четыре недели. Без филлеров. Реабилитация — покраснение на два дня.",
  },
  {
    slug: "tone",
    title: "Ровный тон за два визита",
    procedure: "Lumecca IPL",
    doctor: "AlethiaPro",
    image: img("AB6AXuDaXMzrLpWHAiJe"),
    before: img("AB6AXuDfygIvD0sRch"),
    after: img("AB6AXuDaXMzrLpWHAiJe"),
    quote: "Пигмент после лета ушёл спокойно, без корочек.",
    text: "Два сеанса Lumecca. Между ними только восстановление барьера и SPF. Тон выровнялся к третьей неделе.",
  },
  {
    slug: "glow",
    title: "Сияние изнутри",
    procedure: "Beauty & Glow",
    doctor: "Д-р Элара Торн",
    image: img("AB6AXuCN9PTu3AkRBmoO"),
    before: img("AB6AXuA6H8w-lkGAbbQ1"),
    after: img("AB6AXuCN9PTu3AkRBmoO"),
    quote: "Кожа стала плотнее на ощупь, хотя на лице ничего не кололи.",
    text: "Курс из трёх инфузий Beauty & Glow и домашний барьерный крем. Без инъекций.",
  },
];

export function caseBySlug(slug: string) {
  return cases.find((item) => item.slug === slug);
}

export const pharmacy = [
  {
    productId: "gluta",
    dose: "1 капсула утром, после еды",
    doctor: "AlethiaPro",
    until: "до апреля 2026",
  },
  {
    productId: "catalyst",
    dose: "по схеме NAD+, 4 недели",
    doctor: "Д-р Элара Торн",
    until: "до марта 2026",
  },
];

export const loyaltyLedger = [
  { date: "Янв 2023", title: "Вступление в клуб", points: "+2 000 ₽" },
  { date: "Дек 2025", title: "Визит: консультация", points: "+450 ₽" },
  { date: "Янв 2026", title: "Инфузия NAD+", points: "+1 200 ₽" },
  { date: "Фев 2026", title: "Morpheus8", points: "+8 800 ₽" },
];

export const YOUTUBE_CHANNEL = "https://www.youtube.com/results?search_query=CULT+Clinic+%D0%BA%D0%BE%D1%81%D0%BC%D0%B5%D1%82%D0%BE%D0%BB%D0%BE%D0%B3%D0%B8%D1%8F";

export function youtubeFor(title: string) {
  return `https://www.youtube.com/results?search_query=${encodeURIComponent(`${title} CULT Clinic`)}`;
}

export const productNotes: Record<string, { about: string; use: string[] }> = {
  neuro: {
    about: "Сыворотка для когнитивного тонуса. В линейке клиники это формула к курсам, где важны ясность и восстановление после нагрузок.",
    use: ["Утром натощак или по схеме врача", "Курс 30 дней", "Не смешивать с другими стимуляторами в тот же приём"],
  },
  catalyst: {
    about: "Предшественник NAD+. Назначают вместе с инфузией или отдельным курсом, если капельница пока не нужна.",
    use: ["1 порция в первой половине дня", "Запивать водой", "Контроль самочувствия на 14-й день"],
  },
  gluta: {
    about: "Липосомальный глутатион. В личной аптеке чаще всего стоит как антиоксидантная поддержка после аппаратных процедур.",
    use: ["1 капсула после завтрака", "Курс совпадает с протоколом врача", "Хранить вдали от света"],
  },
  mito: {
    about: "Поддержка выработки АТФ. Остаток небольшой, перед курсом лучше подтвердить наличие у администратора.",
    use: ["До тренировки или утром", "Не вечером", "Пауза при бессоннице"],
  },
  lumen: {
    about: "Барьерный крем, который клиника планирует отпускать после пилингов и RF. Восстанавливает липидный слой.",
    use: ["Вечером на сухое лицо", "Поверх — только SPF утром", "7 дней после процедуры без кислот"],
  },
  veil: {
    about: "Ночная пептидная сыворотка плотности. В плане продаж — домашний шаг между визитами к AlethiaPro.",
    use: ["2–3 капли на ночь", "После тоника без спирта", "Курс 8 недель"],
  },
  aura: {
    about: "Минеральный спрей сияния. Лёгкий шаг в течение дня, когда крем уже есть.",
    use: ["По необходимости", "Не на открытое солнце сразу после", "Можно поверх макияжа"],
  },
};

export const mediaIds = {
  splash: img("AB6AXuA8Xdrx5MdKtm"),
  logo: img("AB6AXuC9DCI3w4l5Tm"),
  offer: img("AB6AXuAP-v4eNThui6"),
  tv1: img("AB6AXuASlJ4xAxwuwk"),
  tv2: img("AB6AXuCKU4PMdaaQHE"),
  avatar: img("AB6AXuBS4-MnnNReQ2"),
  alethia: img("AB6AXuBWhsXgCtKoSN"),
  alethiaVideo: img("AB6AXuDB0rcVzIawlY4J"),
  hardwareHero: img("AB6AXuD46SLnfL8HM2"),
  injectionHero: img("AB6AXuBXQ5Y6S32vGw"),
  infusionLogo: img("AB6AXuBPSg_17vyVof"),
  scienceHero: img("AB6AXuAuqTQXU9ni61"),
  scienceA: img("AB6AXuB62jtez_3oeM"),
  scienceB: img("AB6AXuCx1hmuceMtr0"),
  scienceC: img("AB6AXuDDKdhXlLpR4G"),
  scienceD: img("AB6AXuA2hiIUnEENUs"),
  scienceE: img("AB6AXuBsterRBjzQYm"),
  deviceAfter: img("AB6AXuAT42Rrdjnuii"),
  deviceBefore: img("AB6AXuDfygIvD0sRch"),
  thorneLogo: img("AB6AXuDv7tXrU2SOsU"),
  thorne: img("AB6AXuC_2g-J0di2yK"),
  thorneVideo: img("AB6AXuB6N_kn3s8sC4"),
  reviewA: img("AB6AXuA_UA-_Bl_dR4"),
  reviewB: img("AB6AXuAa9yTsfGbFtG"),
  reviewC: img("AB6AXuAfjDu0YzdmjP"),
  sculpt: img("AB6AXuAEwes9nqkcks7V"),
};
