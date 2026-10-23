import 'data.dart';
import 'yclients.dart';

/// On-device CULT assistant: FAQ + retrieval over services and shop products.
/// Voice UI calls [answer] after speech recognition; replies can be spoken via TTS.
class CultAgent {
  const CultAgent();

  /// Full reply for the bot contact.
  /// Strong catalog title hits beat FAQ; otherwise operational FAQ wins.
  String answer(
    String text, {
    List<Service> localServices = services,
    List<Product> localProducts = products,
    List<YcService> liveServices = const [],
    List<Device> localDevices = devices,
    List<Infusion> localInfusions = infusions,
    ClientGender? gender,
  }) {
    final q = _normalize(text);
    if (q.isEmpty) {
      return 'Спросите голосом или текстом про услугу, цену или формулу из шопа.';
    }

    final hit = _catalogHit(
      q,
      localServices: localServices,
      localProducts: localProducts,
      liveServices: liveServices,
      localDevices: localDevices,
      localInfusions: localInfusions,
      gender: gender,
    );
    final faq = _faqReply(q);

    // Title-level catalog match (score ≥ 9) answers product/service questions.
    if (hit != null && hit.score >= 9) return hit.reply;
    if (faq != null) return faq;
    if (hit != null && hit.score >= 7) return hit.reply;

    return 'Не нашла точного совпадения в каталоге CULT. '
        'Спросите название услуги или формулы, откройте «Прайс» / «Магазин», '
        'или запишитесь через «+» на главной. '
        'Клиника: ежедневно 9:00–21:00, Черноморская, 6.';
  }

  ({String reply, int score})? _catalogHit(
    String q, {
    required List<Service> localServices,
    required List<Product> localProducts,
    required List<YcService> liveServices,
    required List<Device> localDevices,
    required List<Infusion> localInfusions,
    ClientGender? gender,
  }) {
    final tokens = _tokens(q);
    if (tokens.isEmpty) return null;

    final productHits = <({Product item, int score})>[];
    for (final item in localProducts) {
      final score = _score(
        tokens,
        title: item.name,
        fields: [
          item.blurb,
          item.about,
          item.composition,
          item.tab,
          if (item.badge != null) item.badge!,
        ],
      );
      if (score > 0) productHits.add((item: item, score: score));
    }
    productHits.sort((a, b) => b.score.compareTo(a.score));

    final serviceHits = <({Service item, int score})>[];
    for (final item in localServices) {
      if (gender != null && !item.audience.matches(gender)) continue;
      final score = _score(
        tokens,
        title: item.title,
        fields: [
          item.category,
          item.group,
          item.blurb,
          ...item.results,
        ],
      );
      if (score > 0) serviceHits.add((item: item, score: score));
    }
    serviceHits.sort((a, b) => b.score.compareTo(a.score));

    final liveHits = <({YcService item, int score})>[];
    for (final item in liveServices) {
      final score = _score(
        tokens,
        title: item.title,
        fields: [item.category, item.priceLabel, item.durationLabel],
      );
      if (score > 0) liveHits.add((item: item, score: score));
    }
    liveHits.sort((a, b) => b.score.compareTo(a.score));

    final deviceHits = <({Device item, int score})>[];
    for (final item in localDevices) {
      final score = _score(
        tokens,
        title: item.title,
        fields: [item.meta, item.price, item.text, item.tag, ...item.indications],
      );
      if (score > 0) deviceHits.add((item: item, score: score));
    }
    deviceHits.sort((a, b) => b.score.compareTo(a.score));

    final infusionHits = <({Infusion item, int score})>[];
    for (final item in localInfusions) {
      final score = _score(
        tokens,
        title: item.title,
        fields: [item.blurb, item.price, item.chip],
      );
      if (score > 0) infusionHits.add((item: item, score: score));
    }
    infusionHits.sort((a, b) => b.score.compareTo(a.score));

    final bestProduct = productHits.isEmpty ? 0 : productHits.first.score;
    final bestService = serviceHits.isEmpty ? 0 : serviceHits.first.score;
    final bestLive = liveHits.isEmpty ? 0 : liveHits.first.score;
    final bestDevice = deviceHits.isEmpty ? 0 : deviceHits.first.score;
    final bestInfusion = infusionHits.isEmpty ? 0 : infusionHits.first.score;
    final best = [
      bestProduct,
      bestService,
      bestLive,
      bestDevice,
      bestInfusion,
    ].reduce((a, b) => a > b ? a : b);

    if (best < 7) return null;

    final wantsPrice = RegExp(
      r'цен|стоим|скольк|прайс|руб|₽',
    ).hasMatch(q);
    final wantsCompose = RegExp(
      r'состав|ингредиент|компонент|из чего',
    ).hasMatch(q);
    final wantsStock = RegExp(
      r'наличи|остал|закончил|есть ли',
    ).hasMatch(q);

    late final String reply;
    if (bestProduct == best && productHits.isNotEmpty) {
      final top = productHits.take(2).map((h) => h.item).toList();
      reply = _formatProducts(
        top,
        wantsPrice: wantsPrice || !wantsCompose,
        wantsCompose: wantsCompose,
        wantsStock: wantsStock,
      );
    } else if (bestLive == best && liveHits.isNotEmpty) {
      reply = _formatLive(liveHits.take(3).map((h) => h.item).toList());
    } else if (bestService == best && serviceHits.isNotEmpty) {
      reply = _formatServices(
        serviceHits.take(2).map((h) => h.item).toList(),
        wantsPrice: wantsPrice,
      );
    } else if (bestInfusion == best && infusionHits.isNotEmpty) {
      final item = infusionHits.first.item;
      reply =
          '${item.title} — ${item.price}, ${item.duration}. ${item.blurb} '
          'Запись: «+» на главной или меню «Инфузии».';
    } else if (bestDevice == best && deviceHits.isNotEmpty) {
      final item = deviceHits.first.item;
      reply =
          '${item.title}: ${item.meta}. Ориентир по цене — ${item.price}. '
          'Подробности в меню «Аппаратная».';
    } else {
      return null;
    }
    return (reply: reply, score: best);
  }

  String _formatProducts(
    List<Product> items, {
    required bool wantsPrice,
    required bool wantsCompose,
    required bool wantsStock,
  }) {
    final parts = <String>[];
    for (final item in items) {
      final stock = switch (item.stock) {
        'low' => 'осталось мало',
        'out' => 'сейчас нет в наличии',
        _ => 'в наличии',
      };
      final bits = <String>[
        item.name,
        if (wantsPrice) _rub(item.price),
        item.blurb,
        if (wantsCompose) 'состав: ${item.composition}',
        if (wantsStock || item.stock != 'in') stock,
        item.about,
      ];
      parts.add(bits.join(' · '));
    }
    final tail = items.length == 1
        ? 'Откройте карточку в «Магазин» или добавьте в корзину.'
        : 'Ещё формулы — во вкладке «Магазин».';
    return '${parts.join('\n')}\n$tail';
  }

  String _formatServices(List<Service> items, {required bool wantsPrice}) {
    final parts = <String>[];
    for (final item in items) {
      parts.add(
        '${item.title} — ${item.priceLabel}, ${item.duration}. '
        '${item.blurb}'
        '${wantsPrice ? '' : ' ${item.results.take(2).join(', ')}. '}'
        'Противопоказания: ${item.contraindications.take(2).join('; ')}.',
      );
    }
    return '${parts.join('\n')}\nЗапись — через «+» или меню «Услуги».';
  }

  String _formatLive(List<YcService> items) {
    final lines = [
      for (final item in items)
        '${item.title}'
            '${item.priceLabel.isEmpty ? '' : ' — ${item.priceLabel}'}'
            '${item.durationLabel.isEmpty ? '' : ', ${item.durationLabel}'}'
            '${item.category.isEmpty ? '' : ' · ${item.category}'}',
    ];
    return 'В филиале CULT Сочи:\n${lines.join('\n')}\n'
        'Актуальный прайс — в меню «Прайс», запись — через «+».';
  }

  String? _faqReply(String q) {
    if (q.contains('отмен') || q.contains('перенес') || q.contains('перенос')) {
      return 'Отменить или перенести визит можно в профиле → «Мои записи» или через чат администратора.';
    }
    if (q.contains('опозда') ||
        q.contains('опаздыв') ||
        q.contains('задерж') ||
        q.contains('не успева')) {
      return 'Если опаздываете — напишите администратору в чат с запасом 10–15 минут. Слот могут сдвинуть или предложить ближайшее окно.';
    }
    if (q.contains('запис')) {
      return 'Откройте «Запись» в меню или нажмите «+» на главной — подберём услугу, врача и время. Можно сказать голосом название процедуры.';
    }
    if (q.contains('доставк') ||
        q.contains('курьер') ||
        q.contains('магазин') ||
        q.contains('шоп') ||
        q.contains('биохакинг')) {
      return 'Биохакинг-шоп — во вкладке «Магазин». Самовывоз на ресепшен или курьер при оформлении корзины. Спросите формулу голосом — подскажу цену и состав.';
    }
    if (q.contains('ии-подбор') ||
        q.contains('ии подбор') ||
        q.contains('ии помощник') ||
        q.contains('помощник') ||
        (q.contains('подбор') &&
            (q.contains('ии') || q.contains('формул') || q.contains('шоп')))) {
      return 'В магазине кнопка «ИИ Помощник» подскажет формулу под профиль. Здесь же можно спросить голосом: название, цену или состав.';
    }
    if (q.contains('микрофон') ||
        q.contains('голосом') ||
        q.contains('голосовой') ||
        q.contains('распознаван') ||
        RegExp(r'(^|\s)(голос|озвуч)').hasMatch(q)) {
      return 'Нажмите микрофон внизу чата и спросите, например: «сколько стоит микроигольчатый RF» или «есть ли Mitochondrial Fuel». Ответ могу проговорить вслух.';
    }
    if (q.contains('остал') ||
        q.contains('закончил') ||
        q.contains('в наличии') ||
        q.contains('нет в наличии')) {
      return 'Остатки шопа обновляются в карточке формулы. Спросите название товара — скажу, в наличии ли он. Если «Осталось мало» — берите сейчас или напишите администратору.';
    }
    if (q.contains('состав') ||
        q.contains('ингредиент') ||
        q.contains('компонент')) {
      return 'Назовите формулу из шопа — отвечу составом. Или откройте карточку в «Магазин»: долгое нажатие копирует текст.';
    }
    if (q.contains('массаж') || q.contains('лимфодрен')) {
      return 'Массаж и лимфодренаж — в меню «Услуги» и на записи. Спросите конкретное название — подскажу цену и длительность.';
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
    if (q.contains('мезотерап') ||
        q.contains('биоревитал') ||
        q.contains('плазмо')) {
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
    if (q.contains('телефон') ||
        q.contains('позвон') ||
        q.contains('номер клиник')) {
      return 'Телефон филиала: +7 495 000-00-07. Или напишите администратору в чате — ответим в часы работы.';
    }
    if (q.contains('подготов') ||
        q.contains('что взять') ||
        q.contains('перед визит') ||
        q.contains('перед процедур')) {
      return 'Перед визитом: приходите без тяжёлого макияжа на лицо, если процедура на коже; паспорт или документ — на ресепшен. Точную подготовку врач напишет в чате после записи.';
    }
    if (q.contains('документ') ||
        q.contains('паспорт') ||
        q.contains('удостоверен')) {
      return 'На ресепшен достаточно паспорта или другого документа с фото. Для несовершеннолетних — согласие опекуна и его документ.';
    }
    if (q.contains('аллерг')) {
      return 'Сообщите об аллергиях на анестезию, металлы или косметику до процедуры — в чате врача или на осмотре. Не скрывайте реакции: подберём безопасный протокол.';
    }
    if (q.contains('телеграм') ||
        q.contains('whatsapp') ||
        q.contains('вацап') ||
        q.contains('ватсап') ||
        q.contains('инстаграм') ||
        q.contains('instagram') ||
        q.contains('соцсет')) {
      return 'Основной канал в приложении — чат с администратором и врачом. Соцсети и мессенджеры филиала уточняйте на ресепшен или по телефону +7 495 000-00-07.';
    }
    if (q.contains('длительн') ||
        q.contains('сколько длит') ||
        q.contains('сколько занимает') ||
        q.contains('сколько по времени')) {
      return 'Длительность зависит от протокола: уход 45–90 минут, инъекции и аппаратные — обычно до часа с консультацией. Спросите название услуги — скажу точное время из каталога.';
    }
    if (q.contains('солнц') ||
        q.contains('загар') ||
        q.contains('spf') ||
        q.contains('ультрафиолет')) {
      return 'После большинства процедур избегайте прямого солнца 7–14 дней и используйте SPF 50. Солярий и интенсивный загар — только с разрешения врача.';
    }
    if (q.contains('алкогол') || q.contains('вино') || q.contains('выпив')) {
      return 'Алкоголь лучше исключить за сутки до инъекций и аппаратных протоколов и 24–48 часов после — меньше отёков и синяков. Уточните у врача по вашей процедуре.';
    }
    if (q.contains('спорт') ||
        q.contains('фитнес') ||
        q.contains('трениров') ||
        q.contains('спортзал')) {
      return 'Интенсивный спорт обычно пауза 24–72 часа после инъекций и аппаратных. Лёгкая ходьба — чаще можно; точные сроки скажет врач в чате.';
    }
    if (q.contains('бассейн') ||
        q.contains('саун') ||
        q.contains('хамам') ||
        q.contains('парн')) {
      return 'Бассейн, сауна и хамам — обычно пауза несколько дней после инъекций и травматичных протоколов. Спросите врача по вашей дате процедуры.';
    }
    if (q.contains('натощак') ||
        q.contains('голодн') ||
        q.contains('не есть') ||
        q.contains('перед анализ')) {
      return 'На забор крови чаще приходят натощак 8–12 часов, водой можно. Точный список анализов и подготовку подтвердит администратор или лаборатория.';
    }
    if (q.contains('макияж') && !q.contains('перманент')) {
      return 'Декоративный макияж на зону процедуры обычно откладывают на 24 часа и дольше после инъекций. На визит лучше прийти без плотного тона на лице.';
    }
    if (q.contains('надеть') || q.contains('одежд') || q.contains('дресс')) {
      return 'Удобная одежда, которую легко снять с зоны процедуры. Для лица — без плотного макияжа; сменную обувь не обязательна, на ресепшен подскажут.';
    }
    if (q.contains('бонус')) {
      return 'Новым клиентам — 3 000 ₽ welcome-бонус. Баланс смотрите в профиле.';
    }
    if (q.contains('активир') ||
        q.contains('погасить') ||
        q.contains('использовать сертификат') ||
        (q.contains('сертификат') && q.contains('код'))) {
      return 'Код сертификата покажите на ресепшен или напишите администратору в чат — зачислим на визит или услуги.';
    }
    if (q.contains('сертификат') || q.contains('подарок')) {
      return 'Сертификаты — в профиле → «Купить сертификат». Номинал и дизайн выбираете сами, код копируется в один тап.';
    }
    if (q.contains('трансфер') || q.contains('такси') || q.contains('машин')) {
      return 'VIP-трансфер заказывается в профиле. Укажите адрес — водитель напишет в чат администратора.';
    }
    if (q.contains('прайс') || q.contains('цен') || q.contains('стоим')) {
      return 'Актуальный прайс филиала — в меню «Прайс». Назовите услугу голосом — подскажу цену из каталога.';
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
    if (q.contains('врач') ||
        q.contains('специалист') ||
        q.contains('доктор') ||
        q.contains('команда')) {
      return 'Команда врачей — в меню «Врачи». Откройте карточку специалиста и запишитесь или напишите в чат.';
    }
    if (q.contains('беремен') || q.contains('кормлен')) {
      return 'При беременности и лактации часть процедур ограничена. Напишите срок врачу в чате — подскажем безопасный протокол.';
    }
    if (q.contains('аппарат') || q.contains('rf') || q.contains('smas')) {
      return 'Аппаратная косметология — в меню «Аппаратная»: RF, IPL и SMAS. Спросите название — отвечу ценой и длительностью.';
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
      return 'NAD+ и longevity-протоколы — в разделе «Инфузии» и шопе (Catalyst, NAD+ Micro-Patch). Спросите формулу — расскажу подробнее.';
    }
    if (q.contains('постакне') || q.contains('рубец') || q.contains('шрам')) {
      return 'Постакне и рубцы — комбинация аппаратных и инъекционных протоколов. Запишитесь на консультацию — оценим тип кожи.';
    }
    if (q.contains('купероз') ||
        q.contains('сосудист') ||
        q.contains('розацеа')) {
      return 'Купероз и сосудистые сетки часто ведём IPL и уходом. Подробности — в «Аппаратной» и на осмотре врача.';
    }
    if (q.contains('отбеливан') || q.contains('пятн')) {
      return 'Пигментацию разбираем на консультации: пилинги, IPL или домашний протокол. Не отбеливайте кожу самостоятельно до визита.';
    }
    if (q.contains('мимическ') || q.contains('морщин')) {
      return 'Мимические морщины — зона инъекций и ухода. Запишитесь к специалисту через меню «Врачи» или «+».';
    }
    if (q.contains('онлайн') || q.contains('приложен')) {
      return 'В приложении CULT: запись, голосовой агент, чат, шоп, бонусы и сертификаты. Каталог синхронизируется с филиалом Сочи.';
    }
    if (q.contains('блог') ||
        q.contains('культ тв') ||
        q.contains('cult tv') ||
        q.contains('youtube') ||
        q.contains('ютуб')) {
      return 'Материалы CULT TV — в меню «Блог». Там же ссылка на YouTube; вопросы по теме можно задать врачу в чате.';
    }
    if (q.contains('кейс') || q.contains('до и после')) {
      return 'Клинические кейсы — в меню «Кейсы»: процедура, врач и комментарий. Запись на похожий протокол — с карточки кейса.';
    }
    if (q.contains('рассрочк') || q.contains('кредит') || q.contains('частям')) {
      return 'Рассрочку и оплату частями уточняйте на ресепшен или у администратора в чате — условия зависят от суммы протокола.';
    }
    if (q.contains('предоплат') ||
        q.contains('депозит') ||
        q.contains('аванс')) {
      return 'Предоплата нужна не на все услуги — уточните у администратора по протоколу. Оплатить можно картой на ресепшен или при записи.';
    }
    if (q.contains('оплат') ||
        q.contains('картой') ||
        q.contains('безнал') ||
        q.contains('наличн')) {
      return 'Оплата картой, наличными и бонусами CULT. В шопе можно смешать карту и до 30% бонусами.';
    }
    if (q.contains('чаевы') || q.contains('чаевые') || q.contains('tip')) {
      return 'Чаевые — по желанию, наличными или переводом персоналу. Это не влияет на бонусы CULT.';
    }
    if (q.contains('лифт') || q.contains('этаж') || q.contains('вход')) {
      return 'Клиника на Черноморской, 6. Ориентир — ресепшен CULT; парковка у входа. Если нужна помощь с входом — напишите администратору.';
    }
    if (q.contains('отзыв') || q.contains('рейтинг')) {
      return 'Спасибо за интерес к отзывам. Реальные кейсы — в меню «Кейсы»; оставить отзыв можно администратору в чате.';
    }
    if (q.contains('гарант') || q.contains('ожидан')) {
      return 'Результат зависит от протокола и кожи. Врач честно обсудит ожидания на консультации до процедуры.';
    }
    if (q.contains('обезбол') ||
        q.contains('анестез') ||
        q.contains('больн')) {
      return 'Большинство аппаратных и инъекционных протоколов делают с аппликационной анестезией. Уточните на консультации, если есть аллергии.';
    }
    if (q.contains('реабилитац') ||
        q.contains('восстанов') ||
        q.contains('послепроцедур')) {
      return 'Реабилитация зависит от протокола. Врач даст схему ухода в чате или на визите — не наносите активные средства сами.';
    }
    if (q.contains('противопоказ') ||
        q.contains('нельзя') ||
        q.contains('огранич')) {
      return 'Противопоказания индивидуальны. При беременности, острых воспалениях и аллергиях сначала напишите врачу в чат. У конкретной услуги они есть в карточке.';
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
    return null;
  }

  int _score(
    List<String> tokens, {
    required String title,
    required List<String> fields,
  }) {
    final titleNorm = _normalize(title);
    final hay = _normalize('$title ${fields.join(' ')}');
    if (hay.isEmpty) return 0;
    var score = 0;
    var titleHits = 0;
    for (final token in tokens) {
      if (token.length < 3) continue;
      if (titleNorm.contains(token)) {
        titleHits++;
        score += token.length >= 6 ? 8 : 6;
        continue;
      }
      // Body matches only for longer tokens — avoid FAQ words leaking in.
      if (token.length >= 5 && hay.contains(token)) {
        score += 2;
      }
    }
    final phrase = tokens.where((t) => t.length >= 3).join(' ');
    if (phrase.length >= 6 && titleNorm.contains(phrase)) score += 10;
    // Require at least one title token for a usable hit.
    if (titleHits == 0) return 0;
    return score;
  }

  List<String> _tokens(String q) {
    return q
        .split(RegExp(r'[^a-zа-я0-9+]+'))
        .where((t) => t.length >= 3)
        .where(
          (t) => !const {
            'про',
            'для',
            'есть',
            'какой',
            'какая',
            'какие',
            'сколько',
            'стоит',
            'стоим',
            'цена',
            'цены',
            'хочу',
            'можно',
            'нужен',
            'нужна',
            'скажите',
            'расскажи',
            'подскажи',
            'соста',
            'состав',
            'наличи',
            'наличии',
            'средств',
            'средство',
            'услуга',
            'услуги',
            'товар',
            'товары',
            'формул',
            'формула',
          }.contains(t),
        )
        .toList();
  }

  String _normalize(String raw) {
    return raw.toLowerCase().replaceAll('ё', 'е').trim();
  }

  String _rub(int value) {
    final digits = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('\u00a0');
      buf.write(digits[i]);
    }
    return '$buf ₽';
  }
}

const cultAgent = CultAgent();
