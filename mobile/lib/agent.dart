import 'data.dart';
import 'yclients.dart';

/// On-device CULT cosmetologist [cultAgentName]: FAQ + services/shop + booking draft.
/// Voice UI speaks [AgentTurn.reply]; booking only after the user taps «Запись».
class CultAgent {
  const CultAgent();

  /// Convenience: reply text only (tests / simple callers).
  String answer(
    String text, {
    List<Service> localServices = services,
    List<Product> localProducts = products,
    List<YcService> liveServices = const [],
    List<Device> localDevices = devices,
    List<Infusion> localInfusions = infusions,
    ClientGender? gender,
    String? lastBot,
    String? lastUser,
    List<String> recentUsers = const [],
  }) {
    return respond(
      text,
      localServices: localServices,
      localProducts: localProducts,
      liveServices: liveServices,
      localDevices: localDevices,
      localInfusions: localInfusions,
      gender: gender,
      lastBot: lastBot,
      lastUser: lastUser,
      recentUsers: recentUsers,
    ).reply;
  }

  /// Full turn: living reply + optional booking draft awaiting «Запись» tap.
  AgentTurn respond(
    String text, {
    List<Service> localServices = services,
    List<Product> localProducts = products,
    List<YcService> liveServices = const [],
    List<Device> localDevices = devices,
    List<Infusion> localInfusions = infusions,
    ClientGender? gender,
    String? lastBot,
    String? lastUser,
    List<String> recentUsers = const [],
  }) {
    final q = _repairAsr(_normalize(text));
    final book = _bookFlow(
      q,
      raw: text,
      gender: gender,
      lastBot: lastBot,
      lastUser: lastUser,
      recentUsers: recentUsers,
      localServices: localServices,
      localProducts: localProducts,
      liveServices: liveServices,
      localDevices: localDevices,
      localInfusions: localInfusions,
    );
    if (book != null) {
      final reply = _naturalize(
        _dedupeClarify(book.reply, lastBot, user: text),
        seed: '$text|${lastBot ?? ''}|${lastUser ?? ''}',
        lastBot: lastBot,
      );
      return AgentTurn(reply: reply, pendingBooking: book.draft);
    }

    final raw = _answerBody(
      text,
      localServices: localServices,
      localProducts: localProducts,
      liveServices: liveServices,
      localDevices: localDevices,
      localInfusions: localInfusions,
      gender: gender,
      lastBot: lastBot,
      lastUser: lastUser,
      recentUsers: recentUsers,
    );
    return AgentTurn(
      reply: _naturalize(
        _dedupeClarify(raw, lastBot, user: text),
        seed: '$text|${lastBot ?? ''}|${lastUser ?? ''}',
        lastBot: lastBot,
      ),
    );
  }

  String _answerBody(
    String text, {
    List<Service> localServices = services,
    List<Product> localProducts = products,
    List<YcService> liveServices = const [],
    List<Device> localDevices = devices,
    List<Infusion> localInfusions = infusions,
    ClientGender? gender,
    String? lastBot,
    String? lastUser,
    List<String> recentUsers = const [],
  }) {
    final q = _repairAsr(_normalize(text));
    if (q.isEmpty) {
      return _pick('empty', const [
        'Я рядом. Расскажите, что с кожей или самочувствием — как на приёме, своими словами.',
        'Слушаю. Чаще всего начинаем с того, что видно в зеркале, или с усталости — а я уже предложу из CULT.',
        'Давайте с главного: лицо, тело или силы? Подберу спокойный протокол из наших услуг и шопа.',
      ], text);
    }

    if (RegExp(r'^[.…\-\s]+$').hasMatch(q) || q == 'мм' || q == 'эм' || q == 'хм') {
      return _pick('filler', const [
        'Пауза нормальна. Можно одно слово — сухость, овал, прыщи, усталость — и я уже в теме.',
        'Ничего страшного. Кожа, силы или массаж — с любого края зайдём.',
        'Я подожду. Без названий процедур тоже можно: что беспокоит на ощупь или в зеркале.',
      ], text);
    }

    // Small talk first — greetings, name, mood — before booking/catalog stealers.
    final chatEarly = _chatReply(q, lastBot: lastBot, gender: gender);
    if (chatEarly != null) return chatEarly;

    final topic = _topicBlob(lastUser: lastUser, recentUsers: recentUsers);

    // «Повтори / короче / подробнее / не поняла».
    final meta = _metaReply(q, lastBot);
    if (meta != null) return meta;

    // «Помогло / не помогло».
    final feedback = _feedbackReply(q);
    if (feedback != null) return feedback;

    // «Напомни» / «о чём говорили».
    final remind = _remindReply(q, topic: topic, lastBot: lastBot, lastUser: lastUser);
    if (remind != null) return remind;

    // «Не то / мимо» — reset without arguing.
    final correction = _correctionReply(q);
    if (correction != null) return correction;

    // «Первый / второй» after a two-option bot reply.
    final choice = _choiceIndexReply(q, lastBot);
    if (choice != null) return choice;

    // «Почему?» about the last recommendation.
    final why = _whyReply(q, lastBot);
    if (why != null) return why;

    // План / визит / фрустрация / вдвоём / тип кожи.
    final care = _careFlowReply(q, gender: gender);
    if (care != null) return care;

    // «Возьму это» after a named recommendation.
    final take = _takeItReply(q, lastBot);
    if (take != null) return take;

    // Живой врач / администратор.
    final handoff = _handoffReply(q);
    if (handoff != null) return handoff;

    // Booking is handled in [respond] → [_bookFlow] (needs confirm button).

    // «Без уколов / только дом» preferences before catalog suggestions.
    final preference = _preferenceReply(q, gender: gender);
    if (preference != null) return preference;

    final sessionPrefs = _sessionPrefs(topic);

    // Утро / вечер / выходные для записи.
    final slot = _slotReply(q);
    if (slot != null) return slot;

    // Врач из команды CULT.
    final doctor = _doctorReply(q);
    if (doctor != null) return doctor;

    // «А сколько?» after a named service/product in last bot reply.
    final priceFollow = _priceFollowUp(
      q,
      lastBot,
      localServices: localServices,
      localProducts: localProducts,
      liveServices: liveServices,
      localDevices: localDevices,
      localInfusions: localInfusions,
      gender: gender,
    );
    if (priceFollow != null) return priceFollow;
    // Bare price ask without catalog anchor.
    final compactPrice = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (compactPrice == 'а сколько' ||
        compactPrice == 'сколько' ||
        compactPrice == 'сколько стоит' ||
        compactPrice == 'какая цена') {
      return 'Назовите услугу или формулу — скажу цену из каталога. '
          'Или откройте «Прайс» в меню; для записи без цифры сначала — «+» на главной.';
    }

    // «Дорого» right after a priced recommendation.
    final priceObj = _priceObjectionReply(q, lastBot);
    if (priceObj != null) return priceObj;

    // Follow-ups when we have context (so «да» after CTA is not generic).
    // Small talk already handled above.
    final follow = _followUpReply(
      q,
      lastBot,
      gender: gender,
      lastUser: lastUser,
    );
    if (follow != null) return follow;

    // Bare «лицо» / «тело» without prior turn.
    final zone = _zoneOnlyReply(q);
    if (zone != null) return zone;

    // «Что лучше…» comparisons before raw catalog dump.
    final compare = _compareReply(q, gender: gender);
    if (compare != null) return compare;

    // Deadline / event / budget / gift / safety / course / season.
    final situation = _situationReply(q, gender: gender, topic: topic);
    if (situation != null) return situation;

    final intent = _intentReply(q, gender: gender);
    if (intent != null) return intent;

    // Topic from earlier turns + short symptom now («сухость» after «лицо»).
    final grounded = _groundedConcern(q, topic, gender: gender);
    if (grounded != null) {
      return _withSessionPrefs(grounded, sessionPrefs);
    }

    // Two concerns in one phrase (dry + tired…).
    final blend = _blendConcernReply(q, gender: gender);
    if (blend != null) {
      return _withSessionPrefs(blend, sessionPrefs);
    }

    // Free-form concerns / goals without exact catalog names.
    final concern = _concernReply(q, gender: gender);
    if (concern != null) {
      return _withSessionPrefs(concern, sessionPrefs);
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

    // Strong title/phrase hits beat FAQ; softer catalog hits fill after FAQ.
    if (hit != null && hit.score >= 8) {
      return _withCatalogWarmth(q, hit.reply);
    }
    if (faq != null) return faq;
    if (hit != null && hit.score >= 5) {
      return _withCatalogWarmth(q, hit.reply, soft: true);
    }

    // Resume from previous user concern if this turn is vague.
    final resume = _resumeLastUser(q, lastUser, gender: gender);
    if (resume != null) return resume;

    if (q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length >= 8) {
      return _pick('long-detail', const [
        'Много деталей сразу — давайте зафиксируем одну цель визита: лицо, тело, силы или дата события. От этого назову услугу и шаг записи.',
        'Слышу много нюансов. Выберите один якорь — сухость / овал / тон, тело, инфузия или дата — и разложу спокойно.',
        'Чтобы не размазать совет: что сейчас главнее — кожа в зеркале, самочувствие или запись на осмотр?',
      ], text);
    }
    return _pick('fallback-soft', const [
      'Давайте без угадываний: массаж и уход, RF, пилинг, инфузия или крем из шопа — что ближе к вашей задаче?',
      'Могу опереться на прайс CULT. Скажите зону или ощущение — подберу спокойный следующий шаг.',
      'Чаще всего хватает одного ориентира: лицо, тело, энергия или запись. С чего вам удобнее?',
      'Если сложно сформулировать — одно слово про кожу или силы, и я сопоставлю с каталогом филиала.',
    ], text);
  }

  /// Fix common RU voice / ASR slips before matching.
  String _repairAsr(String q) {
    var t = q;
    const pairs = <List<String>>[
      ['микро иголь', 'микроиголь'],
      ['микро-иголь', 'микроиголь'],
      ['эр эф', 'rf'],
      ['рф лифтинг', 'rf лифтинг'],
      ['нат плюс', 'nad+'],
      ['нэд плюс', 'nad+'],
      ['н ад+', 'nad+'],
      ['вейла пептид', 'veil peptide'],
      ['вейл пептид', 'veil peptide'],
      ['veil peptide serum', 'veil peptide serum'],
      ['митохондриал', 'mitochondrial'],
      ['фьюэл', 'fuel'],
      ['фюел', 'fuel'],
      ['льюмен', 'lumen'],
      ['люмен барьер', 'lumen barrier'],
      ['капельницу', 'капельница'],
      ['биоревитализацю', 'биоревитализацию'],
      ['скульптурны массаж', 'скульптурный массаж'],
      ['лимфо дренаж', 'лимфодренаж'],
      ['айпиэль', 'ipl'],
      ['ай пи эль', 'ipl'],
      ['ботокс', 'ботокс'],
      ['ботулинотерапи', 'ботулинотерапи'],
      ['мезо терап', 'мезотерап'],
      ['био ревитал', 'биоревитал'],
      ['смас', 'smas'],
      ['с мас', 'smas'],
      ['ультразвуковой лифтинг', 'smas'],
      ['ультразвуковый лифтинг', 'smas'],
      ['контурн пластик', 'контурная пластика'],
      ['липофилинг', 'липофилинг'],
      ['beauty and glow', 'beauty & glow'],
      ['бьюти глоу', 'beauty & glow'],
      ['иммунити', 'immunity'],
      ['имьюнити', 'immunity'],
      // Light EN → RU so mixed voice queries hit catalog/FAQ.
      ['massage', 'массаж'],
      ['facial', 'уход для лица'],
      [' price', ' цена'],
      ['price ', 'цена '],
      ['how much', 'сколько стоит'],
      ['booking', 'запись'],
      ['appointment', 'запись'],
      ['book ', 'запиши '],
      [' please', ''],
      ['how to book', 'как записаться'],
      ['cancel appointment', 'отменить запись'],
      ['opening hours', 'часы работы'],
      ['parking', 'парковка'],
      ['address', 'адрес'],
      ['botox', 'ботокс'],
      ['filler', 'филлер'],
      ['fillers', 'филлеры'],
      ['lips', 'губы'],
      ['iv drip', 'капельница'],
      ['iv drips', 'капельницы'],
      ['hair removal', 'эпиляция'],
      ['laser hair', 'лазерная эпиляция'],
      ['pedicure', 'маникюр'],
      ['hello', 'привет'],
      ['thanks', 'спасибо'],
      ['thank you', 'спасибо'],
      ['bye', 'пока'],
    ];
    for (final pair in pairs) {
      t = t.replaceAll(pair[0], pair[1]);
    }
    return t;
  }

  String _topicBlob({String? lastUser, List<String> recentUsers = const []}) {
    final parts = <String>[
      for (final item in recentUsers) _normalize(item),
      if (lastUser != null && lastUser.trim().isNotEmpty) _normalize(lastUser),
    ];
    return parts.where((p) => p.isNotEmpty).join(' ');
  }

  String? _priceFollowUp(
    String q,
    String? lastBot, {
    required List<Service> localServices,
    required List<Product> localProducts,
    required List<YcService> liveServices,
    required List<Device> localDevices,
    required List<Infusion> localInfusions,
    ClientGender? gender,
  }) {
    if (lastBot == null || lastBot.isEmpty) return null;
    final asksPrice = q == 'цена' ||
        q == 'а цена' ||
        q == 'стоимость' ||
        q == 'а сколько' ||
        q == 'сколько' ||
        q == 'почем' ||
        q == 'почем' ||
        q.contains('сколько стоит') ||
        q.contains('а сколько стоит') ||
        q.contains('какая цена') ||
        (q.contains('скольк') && q.split(' ').length <= 4);
    if (!asksPrice) return null;
    // Already names a catalog item — let normal catalog path work.
    if (q.contains('rf') ||
        q.contains('массаж') ||
        q.contains('serum') ||
        q.contains('cream') ||
        q.contains('veil') ||
        q.contains('nad')) {
      return null;
    }
    final named = RegExp(r'«([^»]+)»').firstMatch(lastBot);
    final titled = named?.group(1) ??
        RegExp(
          r'Посмотрела ([^.]+)\.',
        ).firstMatch(lastBot)?.group(1);
    if (titled == null || titled.trim().isEmpty) return null;
    final hit = _catalogHit(
      _normalize('$titled цена'),
      localServices: localServices,
      localProducts: localProducts,
      liveServices: liveServices,
      localDevices: localDevices,
      localInfusions: localInfusions,
      gender: gender,
    );
    if (hit == null) {
      return 'По «$titled» точную цифру лучше смотреть в «Прайс» или карточке услуги. '
          'Могу помочь записаться на консультацию через «+» — там же подтвердят стоимость.';
    }
    return 'Да, по цене. ${hit.reply}';
  }

  String? _intentReply(String q, {ClientGender? gender}) {
    if (q.contains('безопасно') ||
        q.contains('вредно ли') ||
        q.contains('опасно ли') ||
        q.contains('есть ли риск') ||
        q.contains('не опасно')) {
      return 'Безопасность всегда важнее скорости: сначала осмотр, сбор противопоказаний и честный разговор о рисках. '
          'Я подскажу направление, но допуск даёт врач на консультации. Запишем осмотр через «+»?';
    }
    if (q.contains('сколько сеанс') ||
        q.contains('сколько процедур') ||
        q.contains('сколько раз') ||
        q.contains('какой курс') ||
        q.contains('на сколько сеанс')) {
      return 'Длина курса зависит от задачи и кожи: массаж и уходы часто от одного визита, RF и пилинги — курсом после осмотра. '
          'Без оценки не обещаю «ровно N раз». Скажите цель — предложу реалистичный порядок и запись на консультацию.';
    }
    if (q.contains('в подарок') ||
        q.contains('подарить') ||
        q.contains('сюрприз') ||
        q.contains('для мамы') ||
        q.contains('для мам ') ||
        q.contains('для подруг') ||
        q.contains('для жены') ||
        q.contains('для мужа') ||
        q.contains('для него') ||
        q.contains('для нее') ||
        q.contains('записать мужа') ||
        q.contains('записать жену') ||
        q.contains('записать подруг') ||
        (q.contains('подарок') && !q.contains('сертификат'))) {
      return 'Для близкого человека чаще всего сертификат CULT — номинал выбираете сами, код в профиле. '
          'Можно сразу записать его на массаж или уход через «+» / чат администратора. '
          'Скажите, кому и что ближе — ритуал ухода, энергия или просто сертификат?';
    }
    if (q.contains('после родов') ||
        q.contains('послеродов') ||
        q.contains('восстанов после рож')) {
      return 'После родов темп только спокойный и после разрешения вашего врача: чаще мягкий уход, барьер, иногда поддержка энергии — без агрессии «сразу всё». '
          'Напишите срок в чат специалисту или запишитесь на консультацию через «+» — подберём безопасный вход.';
    }
    if (q.contains('vip') ||
        q.contains('вип') ||
        q.contains('консьерж') ||
        q.contains('личное сопровожд') ||
        q.contains('персональн менеджер')) {
      return 'VIP-контур в CULT: приоритетная запись через администратора в чате, трансфер в профиле, спокойный ритм визита. '
          'Напишите, что нужно — слот, водитель или сопровождение в день процедуры — соберём без лишней суеты.';
    }
    if (q.contains('деньги не проблем') ||
        q.contains('бюджет не важен') ||
        q.contains('бюджет не ограничен') ||
        q.contains('хочу лучшее') ||
        q.contains('все лучшее') ||
        q.contains('все лучшее') ||
        q.contains('premium') ||
        q.contains('премиум')) {
      return 'Без потолка всё равно идём от задачи, не от «самого дорогого»: осмотр → честный протокол (уход/массаж, при необходимости курс RF или инъекции, инфузии). '
          'Скажите цель и срок — соберу сильный, но спокойный маршрут и запись.';
    }
    if (q.contains('сразу видно') ||
        q.contains('быстрый эффект') ||
        q.contains('чтобы сразу') ||
        q.contains('чтобы было видно') ||
        q.contains('без реабилита') ||
        q.contains('без даунтайм') ||
        q.contains('без downtime')) {
      return 'Если нужен заметный, но спокойный эффект без долгой реабилитации — чаще скульптурный массаж или увлажняющий уход; иногда Beauty & Glow. '
          'Тяжёлые протоколы к выходу «завтра» не беру. Скажите дату и зону — выберу один шаг.';
    }
    if (q.contains('интервал') ||
        q.contains('между процедур') ||
        q.contains('как часто можно') ||
        q.contains('перерыв между')) {
      return 'Интервалы зависят от протокола: уходы и массаж — чаще гибко; RF, пилинги и инъекции — по схеме врача, обычно с паузой под заживление. '
          'Назовите процедуры — ориентирую; точный график зафиксируем на консультации.';
    }
    if (q.contains('совмеща') ||
        q.contains('можно ли вместе') ||
        (q.contains('в один день') && q.contains(' и '))) {
      return 'Совмещать можно не всё: мягкий уход и массаж часто дружат; инъекции и травматичную аппаратную в один день — только если так решит врач. '
          'Скажите пару процедур — скажу, что обычно разделяют.';
    }
    if (q.contains('верн') &&
        (q.contains('деньг') || q.contains('оплат') || q.contains('средства'))) {
      return 'Возвраты и переносы оплаты — через администратора: чат или ресепшен. Условия зависят от услуги и сроков; разберём спокойно по вашей записи.';
    }
    if (q.contains('перед морем') ||
        q.contains('к морю') ||
        q.contains('перед пляж') ||
        q.contains('перед отпуск')) {
      return 'Перед морем и солнцем бережём кожу: SPF, мягкий уход; пилинги/IPL/инъекции — с запасом до загара, иначе риск пятна. '
          'Если отпуск скоро — чаще массаж или увлажнение. Назовите дату выезда.';
    }
    if (q.contains('зим') ||
        q.contains('мороз') ||
        q.contains('отоплен') ||
        q.contains('холодное время') ||
        q.contains('в холод')) {
      return 'Зимой и в отоплении чаще страдает барьер: сухость, стянутость, чувствительность. '
          'Мягкий путь — увлажняющий уход и барьерный крем, без агрессивных кислот «для блеска». Скажите «крем» или «уход» — продолжим.';
    }
    if ((q.contains('лет') || q.contains('жар')) &&
        (q.contains('кожа') ||
            q.contains('лиц') ||
            q.contains('пигмент') ||
            q.contains('солнц') ||
            q.contains('что делать'))) {
      return 'Летом бережём тон и пигмент: SPF, аккуратный уход, агрессивные протоколы — только после оценки фототипа. '
          'Если уже есть пятна — лучше осмотр, а не самостоятельное отбеливание.';
    }
    if (q.contains('мужчин') ||
        q.contains('для муж') ||
        q.contains('мужск') ||
        q.contains('барбер') ||
        q.contains('бород')) {
      return gender == ClientGender.man || gender == null
          ? 'Для мужчин обычно спокойный вход: барбер-массаж, уход без «лишнего блеска», при необходимости RF по овалу. '
              'Что важнее — свежий вид или плотность?'
          : 'Могу сориентировать и по мужским протоколам: массаж, уход, RF без перегруза. Кому подбираем — вам или в подарок?';
    }
    if (q.contains('стрижк') ||
        q.contains('маникюр') ||
        q.contains('педикюр') ||
        q.contains('ресниц') ||
        (q.contains('бров') && !q.contains('перманент'))) {
      return 'Стрижки, маникюр и наращивание ресниц — не наш профиль: CULT — эстетика кожи, инъекции, аппаратная и инфузии. '
          'Могу помочь с лицом, телом или энергией. Что ближе вам?';
    }
    if (q.contains('сколько восстанавли') ||
        q.contains('как быстро сойдет') ||
        q.contains('как быстро сойдет') ||
        q.contains('синяк сколько') ||
        q.contains('отек сколько') ||
        q.contains('отек сколько') ||
        q.contains('когда выходить в люди') ||
        q.contains('реабилитация сколько') ||
        q.contains('даунтайм') ||
        q.contains('downtime')) {
      return 'Сроки разные: после массажа и мягкого ухода часто можно сразу; после инъекций и части аппаратных — день–несколько с возможным отёком или синяком. '
          'Точный даунтайм скажет врач по протоколу. Назовите процедуру — ориентирую мягче или строже.';
    }
    if (q.contains('сравни капель') ||
        q.contains('сравни инфуз') ||
        q.contains('какие капельниц') ||
        q.contains('какие инфуз') ||
        (q.contains('nad') && q.contains('immunity')) ||
        (q.contains('капельниц') && q.contains('сравни'))) {
      return 'Коротко по трём: NAD+ — энергия и ясность; Immunity — поддержка; Beauty & Glow — кожа и «свежий» вид. '
          'Перед капельницей врач уточнит показания. Могу помочь записаться через «+» или открыть меню «Инфузии».';
    }
    return null;
  }

  String? _groundedConcern(
    String q,
    String topic, {
    ClientGender? gender,
  }) {
    if (topic.isEmpty) return null;
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final shortSymptom = compact.split(' ').where((w) => w.isNotEmpty).length <= 4;
    if (!shortSymptom) return null;
    final aboutFace = topic.contains('лиц') || topic.contains('зеркал');
    final aboutEnergy = topic.contains('энерг') || topic.contains('сил');
    final aboutBody = topic.contains('тел') && !topic.contains('тела лица');
    // «сухость» after talking about face → full dry concern (already ok), but add zone cue.
    if (aboutFace &&
        (q.contains('сух') ||
            q.contains('тускл') ||
            q.contains('отек') ||
            q.contains('морщин') ||
            q.contains('пигмент') ||
            q.contains('жирн') ||
            q.contains('пор'))) {
      final base = _blendConcernReply(q, gender: gender) ??
          _concernReply(q, gender: gender);
      if (base == null) return null;
      return 'Раз мы про лицо. $base';
    }
    if (aboutEnergy &&
        (q.contains('устал') || q.contains('капель') || q.contains('инфуз'))) {
      final base = _concernReply(q, gender: gender);
      if (base == null) return null;
      return 'Да, продолжаем про энергию. $base';
    }
    if (aboutBody &&
        (q.contains('целлюлит') ||
            q.contains('живот') ||
            q.contains('рельеф') ||
            q.contains('аппарат'))) {
      final base = _concernReply(q, gender: gender);
      if (base == null) {
        return 'Про тело без жёстких обещаний: эстетика дополняет режим. '
            'Запишем консультацию по аппаратным или скажете зону точнее?';
      }
      return 'Про тело: $base';
    }
    return null;
  }

  ({
    bool noInject,
    bool noDevice,
    bool onlyHome,
    bool noInfus,
    bool allergy,
  }) _sessionPrefs(
    String topic,
  ) {
    final t = topic;
    return (
      noInject: t.contains('без укол') ||
          t.contains('не хочу укол') ||
          t.contains('без инъек') ||
          t.contains('без ботокс') ||
          t.contains('без филлер'),
      noDevice: t.contains('без аппарат') ||
          t.contains('не хочу аппарат') ||
          t.contains('без лазера') ||
          t.contains('без rf'),
      onlyHome: t.contains('только дом') ||
          t.contains('только дома') ||
          t.contains('без клиник') ||
          t.contains('только крем'),
      noInfus: t.contains('без капель') ||
          t.contains('без инфуз') ||
          t.contains('не хочу капель'),
      allergy: t.contains('аллерг') ||
          t.contains('не переношу') ||
          t.contains('реакция на'),
    );
  }

  String _withSessionPrefs(
    String reply,
    ({
      bool noInject,
      bool noDevice,
      bool onlyHome,
      bool noInfus,
      bool allergy,
    }) prefs,
  ) {
    final low = reply.toLowerCase();
    if (prefs.onlyHome) {
      return 'Учитывая, что хотите домашний формат: $reply '
          'Если уводим в кресло — скажите, иначе остаёмся в шопе и домашних ритуалах.';
    }
    if (prefs.noInject &&
        (low.contains('инъек') ||
            low.contains('ботокс') ||
            low.contains('ботулин') ||
            low.contains('филлер') ||
            low.contains('укол'))) {
      return 'Помню про «без уколов». Морщины и плотность можно начать с массажа, ухода и домашнего барьера; '
          'инъекции не предлагаю, пока сами не попросите. Что ближе — массаж или крем?';
    }
    if (prefs.noDevice &&
        (low.contains('аппарат') ||
            low.contains('rf') ||
            low.contains('ipl') ||
            low.contains('лазер'))) {
      return 'Помню: без аппаратной. $reply '
          'Аппаратные протоколы пропускаем, пока не попросите иначе.';
    }
    if (prefs.noInfus &&
        (low.contains('инфуз') || low.contains('капель') || low.contains('nad'))) {
      return 'Помню: без капельниц. Давайте через уход, массаж или шоп — без инфузий. '
          'Что смущает в коже или самочувствии без капельниц?';
    }
    if (prefs.allergy) {
      return '$reply '
          'Важно: вы упоминали аллергию — на осмотре обязательно скажите врачу про реакции на анестезию, металлы или косметику; я не заменяю сбор анамнеза.';
    }
    return reply;
  }

  String? _choiceIndexReply(String q, String? lastBot) {
    if (lastBot == null || lastBot.isEmpty) return null;
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    int? idx;
    if (compact == 'первый' ||
        compact == 'первая' ||
        compact == 'первое' ||
        compact == '1' ||
        compact == 'вариант 1' ||
        compact == 'первый вариант' ||
        compact == 'давай первый') {
      idx = 0;
    } else if (compact == 'второй' ||
        compact == 'вторая' ||
        compact == 'второе' ||
        compact == '2' ||
        compact == 'вариант 2' ||
        compact == 'второй вариант' ||
        compact == 'давай второй') {
      idx = 1;
    } else if (compact == 'оба' ||
        compact == 'оба варианта' ||
        compact == 'и то и то' ||
        compact == 'оба давай') {
      idx = -1;
    } else {
      return null;
    }

    final named = RegExp(r'«([^»]+)»')
        .allMatches(lastBot)
        .map((m) => m.group(1)!.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final differ = RegExp(
      r'Чем отличаются:\s*([^.]+)\s*—\s*([^;]+);\s*([^.]+)\s*—\s*([^.]+)',
    ).firstMatch(lastBot);

    if (idx == -1) {
      if (named.length >= 2) {
        return 'Можно и связку: «${named[0]}» и «${named[1]}» — часто так и делают, если задачи разные. '
            'Откройте «Магазин» или «+» для записи; на консультации подтвердим порядок.';
      }
      return 'Оба пути рабочие — можно начать с более мягкого, а второй оставить на курс после осмотра. '
          'Скажите, что мягче для вас, или откройте «+» для записи.';
    }

    String? label;
    if (named.length > idx) {
      label = named[idx];
    } else if (differ != null) {
      label = idx == 0 ? differ.group(1)!.trim() : differ.group(3)!.trim();
    }
    if (label == null || label.isEmpty) {
      return idx == 0
          ? 'Беру первый путь. Откройте «+» или карточку в меню — оформлю следующий шаг; если назовёте точнее, подтвержу цену.'
          : 'Беру второй путь. Откройте «+» или карточку в меню — оформлю следующий шаг; если назовёте точнее, подтвержу цену.';
    }
    return 'Отлично, остаёмся на «$label». '
        'Можно открыть карточку в приложении или нажать «+» для записи. '
        'Если нужна цена ещё раз — спросите «сколько стоит».';
  }

  String? _whyReply(String q, String? lastBot) {
    final asks = q == 'почему' ||
        q == 'а почему' ||
        q == 'зачем' ||
        q == 'а зачем' ||
        q.startsWith('почему ') ||
        q.startsWith('зачем ') ||
        q.contains('почему именно') ||
        q.contains('почему так') ||
        q.contains('на каком основании');
    if (!asks) return null;
    if (lastBot == null || lastBot.trim().isEmpty) {
      return 'Чтобы не гадать: опишите зону или цель — объясню, почему один шаг спокойнее другого.';
    }
    final brief = _briefRestate(lastBot);
    return 'Потому что из вашего запроса это самый спокойный следующий шаг. Кратко: $brief '
        'Если логика не зашла — назовите ограничение: без уколов, только дом, к дате или бюджет.';
  }

  /// Collect service + when; ready draft only after clarifying — user must tap «Запись».
  ({String reply, AgentBookingDraft? draft})? _bookFlow(
    String q, {
    required String raw,
    ClientGender? gender,
    String? lastBot,
    String? lastUser,
    List<String> recentUsers = const [],
    required List<Service> localServices,
    required List<Product> localProducts,
    required List<YcService> liveServices,
    required List<Device> localDevices,
    required List<Infusion> localInfusions,
  }) {
    final prev = _normalize(lastBot ?? '');
    final topic = _topicBlob(lastUser: lastUser, recentUsers: recentUsers);
    final awaitingConfirm = prev.contains('нажмите кнопку «запись»') ||
        prev.contains('голосом «да» я визит ещё не оформлю') ||
        prev.contains('проверяем наговорённое');
    final awaitingService = prev.contains('на какую услугу') ||
        prev.contains('скажите услугу') ||
        prev.contains('уточним процедуру');
    final awaitingWhen = prev.contains('когда удобнее') ||
        prev.contains('подскажите день') ||
        prev.contains('осталось окно') ||
        prev.contains('утро, день или вечер');
    final continuing = awaitingConfirm || awaitingService || awaitingWhen;
    final wants = q.contains('запиши') ||
        q.contains('записать меня') ||
        q.contains('запишите') ||
        q.contains('давай запишемся') ||
        q.contains('давайте запишемся') ||
        q.contains('хочу записаться') ||
        q.contains('хочу на процедуру') ||
        q.contains('запишемся') ||
        (q.contains('хочу на') &&
            (q.contains('массаж') ||
                q.contains('rf') ||
                q.contains('уход') ||
                q.contains('пилинг') ||
                q.contains('инфуз') ||
                q.contains('капель') ||
                q.contains('консульт') ||
                q.contains('чистка') ||
                q.contains('лазер')));
    final slotOnly = _extractTimeLabel(q) != null ||
        _extractWeekday(q) != null ||
        q.contains('завтра') ||
        q.contains('послезавтра') ||
        q.contains('сегодня');
    if (!wants && !(continuing && (slotOnly || awaitingService || awaitingConfirm))) {
      return null;
    }

    if (continuing &&
        (q.contains('не надо запис') ||
            q.contains('не нужно запис') ||
            compactCancel(q) ||
            (q.contains('отмен') && !q.contains('отмен запис')))) {
      return (
        reply: 'Хорошо, запись не оформляю. Если передумаете — просто скажите, на какую услугу и когда удобнее.',
        draft: null,
      );
    }

    // Voice «да» after summary is not enough — need the Запись button.
    if (awaitingConfirm && _isShortYes(q)) {
      return (
        reply:
            'Чтобы я зафиксировала визит, нажмите кнопку «Запись» ниже — голосом «да» мало, нужна ваша подтверждённая отметка.',
        draft: _draftFromConversation(
          q: q,
          topic: topic,
          lastBot: lastBot,
          gender: gender,
          localServices: localServices,
          localProducts: localProducts,
          liveServices: liveServices,
          localDevices: localDevices,
          localInfusions: localInfusions,
        ),
      );
    }

    final service = _resolveBookService(
      q: q,
      topic: '$topic ${lastBot ?? ''}',
      gender: gender,
      localServices: localServices,
      localProducts: localProducts,
      liveServices: liveServices,
      localDevices: localDevices,
      localInfusions: localInfusions,
    );
    final whenLabel = _extractWhenLabel(q) ??
        (continuing ? _extractWhenLabel(_normalize(lastUser ?? '')) : null);
    final doctor = _resolveBookDoctor(q) ??
        (gender == ClientGender.man ? doctors.last.name : doctors.first.name);

    if (service == null || service.trim().length < 3) {
      final whenHint = whenLabel == null ? '' : ' Ориентир по времени уже есть: $whenLabel.';
      return (
        reply: _pick('book-ask-service', [
          'Запишем.$whenHint На какую услугу из CULT — массаж, уход, RF, пилинг, инфузия или консультация?',
          'С удовольствием.$whenHint Скажите услугу: скульптурный массаж, HydraPure, микроигольчатый RF, пилинг или капельница?',
          'Давайте уточним процедуру.$whenHint Что берём в кресло — массаж, уход, аппаратная, инъекции или инфузия?',
        ], raw),
        draft: null,
      );
    }

    if (whenLabel == null) {
      return (
        reply: _pick('book-ask-when', [
          '«$service» — хороший выбор. Когда удобнее: завтра, день недели, утро или вечер?',
          'Беру «$service». Подскажите день и время — утро, день или вечер, можно «в пятницу вечером».',
          'Ок, «$service». Осталось окно: завтра / день недели и утро или вечер?',
        ], raw),
        draft: null,
      );
    }

    final dateIso = _resolveBookDate(q, fallbackUser: lastUser);
    final time = _resolveBookTime(q, fallbackUser: lastUser);
    final draft = AgentBookingDraft(
      service: service,
      doctor: doctor,
      date: dateIso,
      time: time,
      summary: '$service · $doctor · ${_humanBookWhen(dateIso, time, whenLabel)}',
    );
    return (
      reply: 'Проверяем наговорённое: ${draft.summary}. '
          'Если всё верно — нажмите кнопку «Запись» ниже. '
          'Голосом «да» я визит ещё не оформлю: нужна ваша отметка на кнопке. '
          'Можем поправить услугу или время — просто скажите.',
      draft: draft,
    );
  }

  bool compactCancel(String q) =>
      q == 'отмена' || q == 'не надо' || q == 'потом' || q == 'не сейчас';

  bool _isShortYes(String q) {
    final c = q.replaceAll(RegExp(r'[!?.,…]+'), ' ').trim();
    return const {
      'да',
      'ага',
      'угу',
      'ок',
      'окей',
      'хорошо',
      'давай',
      'конечно',
      'подтверждаю',
      'верно',
    }.contains(c);
  }

  String? _extractTimeLabel(String q) {
    if (q.contains('утром') ||
        q.contains('с утра') ||
        q.contains('на утро') ||
        q.contains('пораньше') ||
        q == 'утро') {
      return 'утро';
    }
    if (q.contains('днём') || q.contains('днем') || q.contains('на день') || q == 'день') {
      return 'день';
    }
    if (q.contains('вечером') ||
        q.contains('на вечер') ||
        q.contains('после работ') ||
        q.contains('попозже') ||
        q == 'вечер') {
      return 'вечер';
    }
    return null;
  }

  String? _extractWeekday(String q) {
    if (q.contains('понедельник')) return 'понедельник';
    if (q.contains('вторник')) return 'вторник';
    if (q.contains('сред')) return 'среда';
    if (q.contains('четверг')) return 'четверг';
    if (q.contains('пятниц')) return 'пятница';
    if (q.contains('суббот')) return 'суббота';
    if (q.contains('воскресень')) return 'воскресенье';
    return null;
  }

  String? _extractWhenLabel(String q) {
    final parts = <String>[
      if (q.contains('сегодня')) 'сегодня',
      if (q.contains('послезавтра')) 'послезавтра',
      if (q.contains('завтра')) 'завтра',
      if (_extractWeekday(q) != null) _extractWeekday(q)!,
      if (q.contains('выходн')) 'выходные',
      if (_extractTimeLabel(q) != null) _extractTimeLabel(q)!,
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  String? _resolveBookService({
    required String q,
    required String topic,
    ClientGender? gender,
    required List<Service> localServices,
    required List<Product> localProducts,
    required List<YcService> liveServices,
    required List<Device> localDevices,
    required List<Infusion> localInfusions,
  }) {
    var rest = q
        .replaceAll('запиши меня на', ' ')
        .replaceAll('запиши на', ' ')
        .replaceAll('записать меня на', ' ')
        .replaceAll('запишите на', ' ')
        .replaceAll('хочу записаться на', ' ')
        .replaceAll('хочу записаться', ' ')
        .replaceAll('давай запишемся на', ' ')
        .replaceAll('давайте запишемся на', ' ')
        .replaceAll('хочу на процедуру', ' ')
        .replaceAll(RegExp(r'^хочу на\s+'), ' ')
        .replaceAll('запиши меня', ' ')
        .replaceAll('запиши', ' ')
        .replaceAll('запишемся', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    for (final noise in [
      'вечером',
      'утром',
      'днём',
      'днем',
      'на вечер',
      'на утро',
      'с утра',
      'после работы',
      'после работ',
      'завтра',
      'послезавтра',
      'сегодня',
      'в понедельник',
      'во вторник',
      'в среду',
      'в четверг',
      'в пятницу',
      'в субботу',
      'в воскресенье',
      'на выходных',
      'в выходные',
      'пожалуйста',
    ]) {
      rest = rest.replaceAll(noise, ' ');
    }
    rest = rest.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (rest.length >= 3) {
      final hit = _catalogHit(
        rest,
        localServices: localServices,
        localProducts: localProducts,
        liveServices: liveServices,
        localDevices: localDevices,
        localInfusions: localInfusions,
        gender: gender,
      );
      if (hit != null && hit.score >= 5) {
        return RegExp(r'«([^»]+)»').firstMatch(hit.reply)?.group(1) ?? rest;
      }
      if (rest.length >= 4 &&
          !const {'утро', 'вечер', 'день', 'завтра', 'сегодня'}.contains(rest)) {
        final svc = _clinicService(rest, gender: gender);
        if (svc != null) return svc.title;
        final inf = _clinicInfusion(rest);
        if (inf != null) return inf.title;
      }
    }

    // Recover service from prior bot/user turns («…»).
    final named = RegExp(r'«([^»]+)»').allMatches(topic).toList();
    for (final m in named.reversed) {
      final title = m.group(1)?.trim() ?? '';
      if (title.length < 3) continue;
      if (_clinicService(title, gender: gender) != null ||
          _clinicInfusion(title) != null ||
          liveServices.any((s) => _normalize(s.title).contains(_normalize(title)))) {
        return title;
      }
    }
    return null;
  }

  String? _resolveBookDoctor(String q) {
    for (final d in doctors) {
      final n = _normalize(d.name);
      final short = n.split(RegExp(r'\s+')).where((w) => w.length >= 4);
      if (q.contains(n)) return d.name;
      for (final w in short) {
        if (q.contains(w)) return d.name;
      }
    }
    return null;
  }

  String _resolveBookDate(String q, {String? fallbackUser}) {
    final blob = '$q ${_normalize(fallbackUser ?? '')}';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime day = today.add(const Duration(days: 1));
    if (blob.contains('сегодня')) {
      day = today;
    } else if (blob.contains('послезавтра')) {
      day = today.add(const Duration(days: 2));
    } else if (blob.contains('завтра')) {
      day = today.add(const Duration(days: 1));
    } else {
      final wd = _extractWeekday(blob);
      if (wd != null) {
        const map = {
          'понедельник': DateTime.monday,
          'вторник': DateTime.tuesday,
          'среда': DateTime.wednesday,
          'четверг': DateTime.thursday,
          'пятница': DateTime.friday,
          'суббота': DateTime.saturday,
          'воскресенье': DateTime.sunday,
        };
        final target = map[wd]!;
        var probe = today.add(const Duration(days: 1));
        while (probe.weekday != target) {
          probe = probe.add(const Duration(days: 1));
        }
        day = probe;
      } else if (blob.contains('выходн')) {
        var probe = today.add(const Duration(days: 1));
        while (probe.weekday != DateTime.saturday) {
          probe = probe.add(const Duration(days: 1));
        }
        day = probe;
      }
    }
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '${day.year}-$m-$d';
  }

  String _resolveBookTime(String q, {String? fallbackUser}) {
    final blob = '$q ${_normalize(fallbackUser ?? '')}';
    final label = _extractTimeLabel(blob);
    return switch (label) {
      'утро' => '10:30',
      'день' => '14:00',
      'вечер' => '18:30',
      _ => '12:00',
    };
  }

  String _humanBookWhen(String dateIso, String time, String whenLabel) {
    return '$whenLabel · $time';
  }

  AgentBookingDraft? _draftFromConversation({
    required String q,
    required String topic,
    String? lastBot,
    ClientGender? gender,
    required List<Service> localServices,
    required List<Product> localProducts,
    required List<YcService> liveServices,
    required List<Device> localDevices,
    required List<Infusion> localInfusions,
  }) {
    final service = _resolveBookService(
      q: q,
      topic: '$topic ${lastBot ?? ''}',
      gender: gender,
      localServices: localServices,
      localProducts: localProducts,
      liveServices: liveServices,
      localDevices: localDevices,
      localInfusions: localInfusions,
    );
    if (service == null) return null;
    final when = _extractWhenLabel(q) ??
        _extractWhenLabel(_normalize(topic)) ??
        'ближайшее окно';
    final dateIso = _resolveBookDate(q, fallbackUser: topic);
    final time = _resolveBookTime(q, fallbackUser: topic);
    final doctor =
        _resolveBookDoctor(q) ??
        (gender == ClientGender.man ? doctors.last.name : doctors.first.name);
    return AgentBookingDraft(
      service: service,
      doctor: doctor,
      date: dateIso,
      time: time,
      summary: '$service · $doctor · ${_humanBookWhen(dateIso, time, when)}',
    );
  }

  String? _priceObjectionReply(String q, String? lastBot) {
    final objects = q.contains('дорого') ||
        q.contains('многовато') ||
        q.contains('длинновато по цене') ||
        q.contains('есть дешевле') ||
        q.contains('подешевле') ||
        q.contains('не потяну') ||
        q.contains('слишком дорог');
    if (!objects) return null;
    final priced = lastBot != null &&
        (lastBot.contains('₽') ||
            lastBot.contains('руб') ||
            lastBot.toLowerCase().contains('стоит') ||
            lastBot.toLowerCase().contains('цен'));
    if (!priced) return null;
    final named = RegExp(r'«([^»]+)»').firstMatch(lastBot)?.group(1);
    final about = named == null ? 'этого варианта' : '«$named»';
    return 'Слышу про бюджет — без давления по $about. '
        'Мягче по входу: уход или массаж, домашний шоп, консультация без процедуры в тот же день; курс иногда выгоднее разового визита. '
        'Назовите потолок цифрой или зону — подберу реалистичную ступень.';
  }

  String? _careFlowReply(String q, {ClientGender? gender}) {
    final man = gender == ClientGender.man;
    if (q.contains('составь план') ||
        q.contains('план ухода') ||
        q.contains('план на месяц') ||
        q.contains('пошагово') ||
        q.contains('что делать по шагам') ||
        q.contains('схему ухода') ||
        q.contains('дорогую схему')) {
      return man
          ? 'Спокойный план на старт: 1) короткая консультация или барбер-массаж; 2) простой домашний барьер; 3) при необходимости RF по овалу после осмотра. '
              'Без «сделанного» лица. С чего начнём — осмотр или массаж?'
          : 'Спокойный план на старт: 1) осмотр или мягкий уход/массаж; 2) дом — барьерный крем и при необходимости сыворотка; 3) курс (RF/пилинг/инъекции) только если цель глубже и после согласия. '
              'Куда шагнуть первым — клиника или домашний уход?';
    }
    if (q.contains('как проходит прием') ||
        q.contains('как проходит прием') ||
        q.contains('что будет на прием') ||
        q.contains('что будет на прием') ||
        q.contains('как проходит визит') ||
        q.contains('что меня ждет') ||
        q.contains('что меня ждет') ||
        q.contains('как выглядит визит')) {
      return 'Обычный визит: ресепшен и короткое ожидание → разговор и осмотр → согласование протокола → сама процедура или только консультация, если так решите. '
          'На лицо лучше без плотного макияжа; документ — на ресепшен. Вопросы можно заранее врачу в чате.';
    }
    if (q.contains('ничего не помогает') ||
        q.contains('уже все пробовал') ||
        q.contains('уже все пробовал') ||
        q.contains('уже все пробовала') ||
        q.contains('уже все пробовала') ||
        q.contains('бесит') ||
        q.contains('достало') ||
        q.contains('надоело') ||
        q.contains('замучал') ||
        q.contains('замучила')) {
      return 'Слышу усталость от бесконечных попыток — это важно. Не будем наслаивать ещё десять средств. '
          'Один спокойный шаг: очный осмотр без обязательства процедуры в тот же день, либо максимально простой домашний барьер. '
          'Расскажите, что уже пробовали — уколы, аппараты, кремы — чтобы не повторять лишнее.';
    }
    if (q.contains('вдвоем') ||
        q.contains('вдвоем') ||
        q.contains('с подругой') ||
        q.contains('с мужем') ||
        q.contains('с женой') ||
        q.contains('вместе прид') ||
        q.contains('на двоих')) {
      return 'Вдвоём удобно: можно соседние окна или один за другим — администратор поможет через чат или «+». '
          'Сертификат тоже хорошо заходит как жест. Скажите, вам уход/массаж или разным задачи?';
    }
    if (q.contains('комбинир') ||
        q.contains('т-зона') ||
        q.contains('т зона') ||
        (q.contains('жирн') && q.contains('сух'))) {
      return 'Комбинированная кожа — частый случай: Т-зона блестит, щёки суше. Не сушим всё лицо агрессивно. '
          'Чаще: мягкий уход в клинике + барьерный крем, а плотные активы — точечно. Могу назвать крем или записать на уход.';
    }
    if (q.contains('чувствительная кожа') ||
        q.contains('реактивная кожа') ||
        q.contains('кожа реагирует на все')) {
      return 'Реактивной коже сначала возвращаем барьер, а не «мощный эффект». '
          'Старт: мягкий уход без кислот и барьерный крем; аппаратные и пилинги — только после осмотра. Запишем спокойную консультацию?';
    }
    if (q.contains('до и после') ||
        q.contains('до/после') ||
        q.contains('результаты есть') ||
        q.contains('есть результаты') ||
        q.contains('покажи результат') ||
        q.contains('покажите результат') ||
        q.contains('фото работ') ||
        (q.contains('кейс') && !q.contains('чемодан'))) {
      return 'Живые клинические кейсы — в меню «Кейсы»: процедура, врач и комментарий. '
          'Это не обещание идентичного результата, а ориентир. С карточки кейса можно перейти к записи на похожий протокол.';
    }
    if (q.contains('сначала') &&
        (q.contains('потом') || q.contains('затем') || q.contains('после этого'))) {
      return 'Логичная последовательность обычно такая: сначала осмотр и мягкий вход (уход/массаж), '
          'потом при необходимости курс — аппаратная или инъекции — уже после согласия и без спешки. '
          'Назовите цель и срок: соберу порядок под вас в двух шагах.';
    }
    if (q.contains('после моря') ||
        q.contains('после пляж') ||
        q.contains('после отпуск') ||
        q.contains('обгорела') ||
        q.contains('обгорел') ||
        (q.contains('сочи') && (q.contains('кожа') || q.contains('влажн') || q.contains('солнц')))) {
      return 'После моря и солнца в Сочи кожа часто обезвожена и чувствительна: сначала барьер и SPF, без агрессивных протоколов сразу. '
          'Через несколько спокойных дней — уход или массаж; пилинг/IPL только после оценки. Могу подсказать крем или запись на мягкий уход.';
    }
    if (q.contains('не сейчас') ||
        q.contains('потом как-нибудь') ||
        q.contains('отложим') ||
        q.contains('не готова') ||
        q.contains('не готов')) {
      return 'Хорошо, без спешки. Когда будете готовы — напишите или нажмите «Голос»: продолжим с того же места. '
          'Могу коротко оставить домашний шаг (барьерный уход), если хотите не терять ритм.';
    }
    return null;
  }

  String? _takeItReply(String q, String? lastBot) {
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final hit = compact == 'возьму' ||
        compact == 'беру' ||
        compact == 'оформляй' ||
        compact == 'оформляем' ||
        compact == 'давай это' ||
        compact == 'давайте это' ||
        compact == 'согласна на это' ||
        compact == 'согласен на это' ||
        compact.contains('возьму это') ||
        compact.contains('беру это') ||
        compact.contains('давай его') ||
        compact.contains('давай ее') ||
        compact.contains('давай ее');
    if (!hit) return null;
    if (lastBot == null || lastBot.isEmpty) {
      return 'Отлично. Уточните, что берём — услугу через «+» или формулу в «Магазин» — и оформлю следующий шаг.';
    }
    final named = RegExp(r'«([^»]+)»').firstMatch(lastBot)?.group(1) ??
        RegExp(r'Посмотрела ([^.]+)\.').firstMatch(lastBot)?.group(1)?.trim();
    final shop = lastBot.toLowerCase().contains('магазин') ||
        lastBot.toLowerCase().contains('корзин') ||
        lastBot.contains('Посмотрела') ||
        (lastBot.contains('₽') && lastBot.toLowerCase().contains('состав'));
    if (named != null && named.isNotEmpty) {
      if (shop) {
        return 'Супер, берём «$named». Откройте карточку в «Магазин» и положите в корзину — или скажите администратору в чат для самовывоза. '
            'На консультации при необходимости скорректируем.';
      }
      return 'Супер, остаёмся на «$named». Запись: «+» на главной или меню «Запись» — врач и время. '
          'Если слот не находится, напишите администратору в чат.';
    }
    return 'Приняла. Откройте «+» для записи или «Магазин» для формулы — и завершите шаг. '
        'Если нужно, коротко назовите ещё раз, что именно берём.';
  }

  String? _handoffReply(String q) {
    final wantsHuman = q.contains('живого врача') ||
        q.contains('настоящего врача') ||
        q.contains('живого человека') ||
        q.contains('реального человека') ||
        q.contains('переведи на врача') ||
        q.contains('соедини с врачом') ||
        q.contains('позови врача') ||
        q.contains('хочу к врачу') ||
        q.contains('нужен врач не бот') ||
        q.contains('хватит бота') ||
        q.contains('оператор') ||
        (q.contains('администратор') &&
            (q.contains('напиш') || q.contains('позов') || q.contains('соеди')));
    if (!wantsHuman) return null;
    return 'Конечно — я только помощник, решение и осмотр за специалистом. '
        'Откройте чат «Врач» или «Администратор» в разделе Чат, либо запишитесь через «+» / меню «Врачи». '
        'Могу перед этим коротко сузить задачу, чтобы врачу было проще.';
  }

  String? _remindReply(
    String q, {
    required String topic,
    String? lastBot,
    String? lastUser,
  }) {
    final asks = q.contains('напомни') ||
        q.contains('о чем мы') ||
        q.contains('о чем мы') ||
        q.contains('что мы обсужд') ||
        q.contains('к чему пришли') ||
        q.contains('на чем останови') ||
        q.contains('на чем останови');
    if (!asks) return null;
    final bits = <String>[];
    if (lastUser != null && lastUser.trim().isNotEmpty) {
      bits.add('вы говорили: «${_briefRestate(lastUser)}»');
    }
    if (lastBot != null && lastBot.trim().isNotEmpty) {
      bits.add('я отвечала: «${_briefRestate(lastBot)}»');
    }
    if (topic.contains('без укол')) bits.add('ограничение: без уколов');
    if (topic.contains('аллерг')) bits.add('важно: аллергия в анамнезе разговора');
    if (bits.isEmpty) {
      return 'Пока мало якорей в диалоге. Скажите зону или цель — зафиксируем и пойдём дальше.';
    }
    return 'Коротко, где мы: ${bits.join('; ')}. '
        'Продолжим с этого или сбросим через «не то».';
  }

  String? _correctionReply(String q) {
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final hit = compact == 'не то' ||
        compact == 'мимо' ||
        compact == 'нет не то' ||
        compact == 'не то совсем' ||
        q.contains('не то что') ||
        q.contains('не об этом') ||
        q.contains('другое имела') ||
        q.contains('другое имел') ||
        q.contains('ты не понял') ||
        q.contains('вы не понял') ||
        q.contains('неправильно понял') ||
        q.contains('давай по-другому') ||
        q.contains('давай по другому') ||
        q.contains('не про то');
    if (!hit) return null;
    return 'Хорошо, сбрасываю прошлый вариант — без споров. '
        'Скажите заново одним ориентиром: лицо, тело, энергия, домашний уход или запись. '
        'Или коротко, что не так в прошлом ответе.';
  }

  String? _preferenceReply(String q, {ClientGender? gender}) {
    final noInject = q.contains('без укол') ||
        q.contains('не хочу укол') ||
        q.contains('не хочу инъек') ||
        q.contains('без инъек') ||
        q.contains('без ботокс') ||
        q.contains('без филлер');
    final noDevice = q.contains('без аппарат') ||
        q.contains('не хочу аппарат') ||
        q.contains('без лазера') ||
        q.contains('без rf') ||
        q.contains('без рф');
    final onlyHome = q.contains('только дом') ||
        q.contains('только дома') ||
        q.contains('без клиник') ||
        q.contains('сама дома') ||
        q.contains('сам дома') ||
        q.contains('только крем') ||
        q.contains('только уход дома');
    final noInfus = q.contains('без капель') ||
        q.contains('без инфуз') ||
        q.contains('не хочу капель') ||
        q.contains('не хочу инфуз');
    if (!noInject && !noDevice && !onlyHome && !noInfus) return null;

    final wantsFresh = q.contains('свеж') ||
        q.contains('тускл') ||
        q.contains('морщин') ||
        q.contains('овал') ||
        q.contains('сух') ||
        q.contains('отек');

    if (onlyHome) {
      return 'Тогда остаёмся в домашнем контуре: барьерный крем и пептидная сыворотка из шопа — без записи в кресло. '
          'Скажите «крем» или «сыворотка» — назову цену и наличие.';
    }
    if (noInject && noDevice) {
      return 'Поняла: без инъекций и без аппаратной. Спокойный путь — массаж, уходы и домашний барьер; при силах — можно позже обсудить инфузии отдельно. '
          'Что ближе: массаж, уход или крем?';
    }
    if (noInject) {
      return wantsFresh
          ? 'Без уколов тоже можно двигаться: скульптурный массаж, уходы, при необходимости аппаратная после осмотра, дома — барьер и пептиды. '
              'Инъекции не предлагаю, пока сами не попросите. С чего начнём — массаж или уход?'
          : 'Ок, инъекции снимаем со стола. Остаются массаж, уходы, домашний шоп и при желании аппаратная или инфузии. '
              'Скажите задачу кожи или «посоветуй что-нибудь» без уколов.';
    }
    if (noDevice) {
      return 'Без аппаратной — тоже рабочий путь: массаж, уходы, домашний уход; инъекции только если сами захотите и после осмотра. '
          'Что в приоритете — свежий вид или комфорт кожи?';
    }
    if (noInfus) {
      return 'Капельницы пропускаем. Тогда смотрим лицо или тело через уход, массаж или шоп — либо просто консультацию. '
          'Что смущает сильнее: кожа или общий тонус без капельниц?';
    }
    return null;
  }

  String? _slotReply(String q) {
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final morning = q.contains('утром') ||
        q.contains('с утра') ||
        q.contains('на утро') ||
        q.contains('к открытию') ||
        q.contains('пораньше') ||
        compact == 'утро' ||
        compact == 'с утра';
    final evening = q.contains('вечером') ||
        q.contains('на вечер') ||
        q.contains('после работ') ||
        q.contains('попозже') ||
        compact == 'вечер' ||
        compact == 'на вечер';
    final weekend = q.contains('в выходн') ||
        q.contains('на выходн') ||
        q.contains('в субботу') ||
        q.contains('в воскресенье');
    final weekday = <String>[
      if (q.contains('в понедельник') || q.contains('на понедельник')) 'понедельник',
      if (q.contains('во вторник') || q.contains('на вторник')) 'вторник',
      if (q.contains('в среду') || q.contains('на среду')) 'среда',
      if (q.contains('в четверг') || q.contains('на четверг')) 'четверг',
      if (q.contains('в пятницу') || q.contains('на пятницу')) 'пятница',
    ];
    final bookingCue = q.contains('запис') ||
        q.contains('приех') ||
        q.contains('прийт') ||
        q.contains('слот') ||
        q.contains('удобн') ||
        q.contains('хочу на') ||
        q.contains('можно на') ||
        q.contains('давайте на');
    final bareSlot = compact == 'утро' ||
        compact == 'вечер' ||
        compact == 'с утра' ||
        compact == 'на вечер' ||
        compact == 'на утро';
    // Don't steal «сегодня вечером событие» from situation/event flow.
    if (!(morning || evening || weekend || weekday.isNotEmpty)) return null;
    if (!bookingCue && !bareSlot && weekday.isEmpty) return null;
    if (!bookingCue && weekend && weekday.isEmpty) return null;
    if ((morning || evening) && !bookingCue && !bareSlot) return null;
    final when = [
      if (morning) 'утро',
      if (evening) 'вечер',
      if (weekend) 'выходные',
      ...weekday,
    ].join(' / ');
    return 'Ориентир по времени приняла: $when. Клиника ежедневно 9:00–21:00. '
        'Откройте «+» или «Запись» и выберите окно; если нужен конкретный врач — напишите имя. '
        'Могу сначала сузить услугу под вашу задачу.';
  }

  String? _doctorReply(String q) {
    bool partHit(String part) {
      if (part.length < 4) return false;
      if (q.contains(part)) return true;
      // «Элара» → «эларе» / «элару»; «Джулиан» → «джулиану».
      if (part.length >= 5 && q.contains(part.substring(0, part.length - 1))) {
        return true;
      }
      return false;
    }

    for (final doc in doctors) {
      final name = _normalize(doc.name);
      final slug = _normalize(doc.slug);
      final nameHit = name.length >= 4 && q.contains(name);
      final slugHit = slug.length >= 4 && q.contains(slug);
      final parts = name
          .split(RegExp(r'[^a-zа-я0-9]+'))
          .where((w) => w.length >= 4)
          .toList();
      final anyPart = parts.any(partHit);
      final strongPart = parts.any((w) => w.length >= 5 && partHit(w));
      if (!(nameHit || slugHit || anyPart)) continue;
      final cue = q.contains('врач') ||
          q.contains('доктор') ||
          q.contains('специалист') ||
          q.contains('к ') ||
          q.contains('про ') ||
          q.contains('хочу к');
      // Distinctive name piece (Элара, Джулиан…) needs no extra cue.
      if (!nameHit && !slugHit && !cue && !strongPart) continue;
      return 'Это ${doc.name} — ${doc.role}, опыт ${doc.exp}. ${doc.about} '
          'Запись к специалисту — через «+» или карточку в меню «Врачи». '
          'Если скажете задачу (лицо, инфузии, аппаратная), подскажу, насколько профиль совпадает.';
    }
    return null;
  }

  String _withCatalogWarmth(String q, String reply, {bool soft = false}) {
    var out = reply;
    if (q.contains('боюсь') ||
        q.contains('страшно') ||
        q.contains('пережива')) {
      out = 'В CULT процедуры согласуем на осмотре, с анестезией где нужно — $reply';
    } else if (q.contains('не знаю') ||
        q.contains('подскажи') ||
        q.contains('посоветуй')) {
      out = 'Ориентир из прайса CULT: $reply';
    }
    if (soft) {
      return _pick('catalog-soft', [
        'Похоже на позицию из каталога CULT. $out Если мимо — скажите «не то» или одно слово точнее.',
        'Из прайса CULT ближе всего так: $out Если не то — поправьте одним словом.',
        'Нашла в каталоге. $out Можно уточнить или сказать «не то».',
      ], q);
    }
    return out;
  }

  String? _metaReply(String q, String? lastBot) {
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final wantsShort = compact == 'короче' ||
        compact == 'покороче' ||
        compact == 'кратко' ||
        compact == 'в двух словах' ||
        q.contains('скажи короче') ||
        q.contains('можно короче') ||
        q.contains('покороче пожалуйста');
    final wantsRepeat = q.contains('повтори') ||
        q.contains('повтор') ||
        q.contains('еще раз') ||
        q.contains('еще раз') ||
        q.contains('не понял') ||
        q.contains('не поняла') ||
        q.contains('не расслыша') ||
        q.contains('что ты сказа') ||
        q.contains('что вы сказа');
    final wantsOtherWords = q.contains('по-другому') ||
        q.contains('по другому') ||
        q.contains('другими словами') ||
        q.contains('объясни проще') ||
        q.contains('попроще') ||
        compact == 'проще';
    final wantsMore = compact == 'подробнее' ||
        compact == 'поподробнее' ||
        compact == 'разверни' ||
        compact == 'еще' ||
        compact == 'еще' ||
        compact == 'а еще' ||
        compact == 'а еще' ||
        compact == 'что еще' ||
        compact == 'что еще' ||
        compact == 'еще варианты' ||
        compact == 'еще варианты' ||
        compact == 'другие варианты' ||
        q.contains('расскажи подробнее') ||
        q.contains('можно подробнее') ||
        q.contains('еще вариант') ||
        q.contains('еще вариант');
    final wantsSlower = q.contains('медленнее') ||
        q.contains('помедленнее') ||
        q.contains('говори тише') ||
        q.contains('говори громче') ||
        q.contains('говори медлен') ||
        compact == 'тише' ||
        compact == 'громче' ||
        compact == 'потише' ||
        compact == 'погромче';
    if (wantsSlower &&
        !q.contains('массаж') &&
        !q.contains('уход') &&
        !q.contains('крем')) {
      return 'Хорошо — дальше короче и спокойнее. '
          'Повторите тему одним словом: массаж, сухость или запись — отвечу в двух фразах.';
    }
    if (!wantsRepeat && !wantsShort && !wantsOtherWords && !wantsMore) {
      return null;
    }
    if (lastBot == null || lastBot.trim().isEmpty) {
      if (wantsShort) {
        return 'Хорошо, буду короче. Сформулируйте вопрос одним предложением — отвечу в двух фразах.';
      }
      if (wantsMore || wantsOtherWords) {
        return 'Конечно. Назовите тему — лицо, энергия, запись или услугу из прайса — разберу спокойно и по шагам.';
      }
      return 'Конечно. Скажите ещё раз вопрос своими словами — отвечу короче и по шагам.';
    }
    final brief = _briefRestate(lastBot);
    if (wantsShort) {
      final one = brief.split(RegExp(r'(?<=[.!?])\s+')).first.trim();
      return 'Короче: $one '
          'Если нужно действие — скажите «запись», «крем» или «не то».';
    }
    if (wantsMore) {
      return 'Дополню. $brief '
          'Рядом обычно смотрят ещё мягкий уход/массаж, домашний барьер или короткую консультацию без процедуры в тот же день. '
          'Скажите «запись», «крем» или «не то» — сузим.';
    }
    if (wantsOtherWords) {
      return 'Иначе: $brief '
          'Если всё ещё мимо — одно слово: зона, симптом или «запись».';
    }
    return 'Коротко повторю: $brief '
        'Если удобнее иначе — уточните зону или цель одним словом.';
  }

  String? _feedbackReply(String q) {
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final good = compact == 'помогло' ||
        compact == 'помогла' ||
        compact.contains('очень помогло') ||
        compact.contains('стало яснее') ||
        compact.contains('теперь понятно') ||
        compact.contains('супер спасибо') ||
        (compact.contains('полезно') && compact.length <= 24);
    final bad = compact == 'не помогло' ||
        compact == 'не помогла' ||
        compact.contains('вообще не то') ||
        compact.contains('ерунда') ||
        compact.contains('бесполезно') ||
        compact.contains('не понятнее');
    if (good) {
      return 'Рада, что стало яснее. Если захотите следующий шаг — запись через «+», формула в «Магазин» или просто продолжим голосом.';
    }
    if (bad) {
      return 'Спасибо, что сказали честно. Давайте иначе: одно слово — лицо, энергия, уход или запись — и я отвечу короче, без лишнего. '
          'Или откройте чат врача, если нужен человек.';
    }
    return null;
  }

  String _briefRestate(String raw) {
    final t = raw.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final parts = t.split(RegExp(r'(?<=[.!?])\s+'));
    final take = parts.take(2).join(' ').trim();
    if (take.length <= 220) return take.endsWith('.') || take.endsWith('?') || take.endsWith('!') ? take : '$take.';
    return '${take.substring(0, 217).trim()}…';
  }

  String? _zoneOnlyReply(String q) {
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (compact == 'лицо' || compact == 'про лицо' || compact == 'для лица') {
      return 'Хорошо, лицо. Что заметнее: сухость, тусклость, морщинки, отёк или пигмент? '
          'От этого выберу массаж, уход, аппаратную или домашний крем.';
    }
    if (compact == 'тело' || compact == 'про тело' || compact == 'для тела') {
      return 'Хорошо, тело. Чаще смотрим плотность, рельеф или тонус — без обещаний «за один раз». '
          'Ближе консультация с аппаратной или сначала просто осмотр?';
    }
    if (compact == 'энергия' || compact == 'энергетика' || compact == 'про энергию') {
      return 'Про энергию чаще говорим про инфузии: NAD+, Immunity, Beauty & Glow. '
          'Могу коротко сравнить три или помочь записаться через «+».';
    }
    if (compact == 'уход' || compact == 'домашний уход' || compact == 'дом') {
      return 'Для дома хорошо заходят барьерный крем и пептидная сыворотка. '
          'Скажите «крем» или «сыворотка» — назову цену и наличие.';
    }
    return null;
  }

  String? _resumeLastUser(
    String q,
    String? lastUser, {
    ClientGender? gender,
  }) {
    if (lastUser == null || lastUser.trim().isEmpty) return null;
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // Never resume over clear new questions / small talk.
    if (compact.contains('как ') ||
        compact.contains('что ты') ||
        compact.contains('кто ты') ||
        compact.contains('расскажи') ||
        compact.contains('зовут') ||
        compact.contains('имя') ||
        compact.contains('умеешь') ||
        compact.contains('привет') ||
        compact.contains('здравств') ||
        compact.contains('избавиться') ||
        compact.contains('помоги с') ||
        compact.contains('что с ') ||
        compact.startsWith('а как') ||
        compact.startsWith('а что')) {
      return null;
    }
    final vague = compact.contains('а дальше') ||
        compact.contains('что дальше') ||
        compact.contains('ну и') ||
        compact == 'дальше' ||
        compact == 'продолжим' ||
        compact == 'и все' ||
        compact == 'что можно' ||
        compact == 'а что можно' ||
        compact == 'что делать' ||
        compact == 'и что делать' ||
        compact == 'какие варианты' ||
        compact == 'а еще' ||
        compact == 'а ещё' ||
        compact.contains('а что с этим') ||
        compact == 'и что';
    if (!vague) return null;
    final prev = _normalize(lastUser);
    final blend = _blendConcernReply(prev, gender: gender);
    if (blend != null) {
      return 'Продолжим с того, о чём вы говорили. $blend';
    }
    final concern = _concernReply(prev, gender: gender);
    if (concern != null) {
      return 'Продолжим с того, о чём вы говорили. $concern';
    }
    return null;
  }

  String? _blendConcernReply(String q, {ClientGender? gender}) {
    final dry = q.contains('сух') ||
        q.contains('стягив') ||
        q.contains('шелуш') ||
        q.contains('обезвож');
    final tired = q.contains('устал') ||
        q.contains('нет сил') ||
        q.contains('энерг') ||
        q.contains('выгоран');
    final dull = q.contains('тускл') ||
        q.contains('серый') ||
        q.contains('серая') ||
        q.contains('серое') ||
        q.contains('сияни') ||
        q.contains('свежий');
    final wrinkle = q.contains('морщин') || q.contains('мими') || q.contains('гусиные');
    final oval = q.contains('овал') ||
        q.contains('второй подбородок') ||
        q.contains('брыл') ||
        q.contains('контур лиц');
    final edema = q.contains('отек') || q.contains('мешк') || q.contains('пастоз');
    final pigment = q.contains('пигмент') || q.contains('пятн');
    final stress = q.contains('стресс') || q.contains('нервн') || q.contains('тревож');

    final hits = [dry, tired, dull, wrinkle, oval, edema, pigment, stress]
        .where((x) => x)
        .length;
    if (hits < 2) return null;

    if (dry && tired) {
      return 'Слышу и про барьер, и про силы — часто идут рядом. '
          'Снаружи: мягкий увлажняющий уход и барьерный крем; изнутри при необходимости — инфузия (NAD+ или Beauty & Glow). '
          'С чего начнём: дом, уход в клинике или капельница?';
    }
    if (dull && tired) {
      return 'Тусклость плюс усталость — обычно связка «лицо + энергия». '
          'На лицо: массаж или уход без тяжёлой реабилитации; для сил — коротко про инфузии. '
          'Что сейчас важнее — зеркало или самочувствие?';
    }
    if (wrinkle && oval) {
      return gender == ClientGender.man
          ? 'Мимика и овал у мужчин часто ведём связкой: сначала массаж или осмотр, затем при необходимости RF — без «перекачанного» вида. '
              'Хотите сравнить мягкий и курсовой путь или сразу запись на консультацию?'
          : 'Мимика и овал можно развести по темпу: мягкий вход — массаж и уход; стойкость — RF или инъекции после осмотра. '
              'Что ближе — быстрый свежий вид или курс?';
    }
    if (edema && dry) {
      return 'Отёк и сухость вместе бывают при нарушенном барьере и лимфе. '
          'Спокойный старт: лимфодренажный или скульптурный массаж плюс барьерный крем дома — без агрессии. '
          'Скажите «массаж» или «крем», продолжим цифрами.';
    }
    if (pigment && dull) {
      return 'Пигмент и тусклый тон разбираем спокойно: чаще пилинг или IPL после оценки фототипа, дома — аккуратный уход без самоотбеливания. '
          'Запишем осмотр или сначала назову мягкий уход из прайса?';
    }
    if (stress && (dry || dull || edema)) {
      return 'Стресс часто читается и в коже, и в лице. Иногда достаточно массажа и паузы без «тяжёлой артиллерии», плюс простой домашний барьер. '
          'Хотите мягкий ритуал ухода или запись просто поговорить с врачом?';
    }
    return null;
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

    if (best < 5) return null;

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
          'По инфузии «${item.title}»: ${item.price}, ${item.duration}. '
          '${item.blurb} '
          'Перед капельницей врач уточнит показания. '
          'Запись — через «+» или меню «Инфузии».';
    } else if (bestDevice == best && deviceHits.isNotEmpty) {
      final item = deviceHits.first.item;
      reply =
          'Аппаратный протокол «${item.title}»: ${item.meta}. '
          'Ориентир по цене — ${item.price}. '
          'Интенсивность подберём на консультации под вашу кожу — подробности в «Аппаратной».';
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
        'low' => 'Осталось мало — если откликается, разумнее взять сейчас.',
        'out' => 'Сейчас нет в наличии; могу предложить соседнюю формулу из шопа.',
        _ => 'Сейчас в наличии.',
      };
      final about = _firstSentence(item.about);
      final buf = StringBuffer(
        items.length == 1
            ? 'Посмотрела ${item.name}. '
            : '${item.name}. ',
      );
      if (wantsPrice) buf.write('Стоит ${_rub(item.price)}. ');
      buf.write('${item.blurb}. ');
      if (wantsCompose) {
        buf.write('В составе: ${item.composition}. ');
      }
      if (wantsStock || item.stock != 'in') buf.write('$stock ');
      if (about.isNotEmpty && items.length == 1) buf.write('$about ');
      parts.add(buf.toString().trim());
    }
    if (items.length == 1) {
      return '${parts.first}\n'
          'Можно открыть карточку в «Магазин» или сразу в корзину — на консультации при необходимости скорректируем.';
    }
    final a = items[0];
    final b = items[1];
    final contrast =
        'Чем отличаются: ${a.name} — ${a.blurb}; ${b.name} — ${b.blurb}. ';
    return 'Нашла два близких варианта. ${parts.join(' ')}\n'
        '$contrast'
        'Скажите задачу кожи (барьер, плотность, энергия) — оставим одну формулу.';
  }

  String _formatServices(List<Service> items, {required bool wantsPrice}) {
    final parts = <String>[];
    for (final item in items) {
      final buf = StringBuffer(
        'По услуге «${item.title}»: ${item.priceLabel}, занимает ${item.duration}. ',
      );
      buf.write('${item.blurb} ');
      if (!wantsPrice && item.results.isNotEmpty) {
        buf.write('Обычно ждут: ${item.results.take(2).join(', ')}. ');
      }
      if (item.contraindications.isNotEmpty) {
        buf.write(
          'Важно учесть противопоказания: ${item.contraindications.take(2).join('; ')}. ',
        );
      }
      parts.add(buf.toString().trim());
    }
    return '${parts.join(' ')}\n'
        'Если откликается — запишем через «+» или «Услуги»; на осмотре уточним детали под вашу кожу.';
  }

  String _formatLive(List<YcService> items) {
    final lines = [
      for (final item in items)
        '${item.title}'
            '${item.priceLabel.isEmpty ? '' : ' — ${item.priceLabel}'}'
            '${item.durationLabel.isEmpty ? '' : ', ${item.durationLabel}'}'
            '${item.category.isEmpty ? '' : ', ${item.category}'}',
    ];
    return 'В филиале CULT Сочи сейчас так: ${lines.join('; ')}. '
        'Полный прайс — в меню «Прайс», запись удобнее через «+». '
        'Могу сузить по зоне или бюджету, если скажете.';
  }

  String _firstSentence(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final cut = t.split(RegExp(r'(?<=[.!?])\s+')).first.trim();
    return cut.length > 160 ? '${cut.substring(0, 157)}…' : cut;
  }

  /// Greetings and bedside manner — answers before catalog/FAQ ops.
  /// Note: Dart `\b` is ASCII-only, so we avoid it for Cyrillic.
  String? _chatReply(
    String q, {
    String? lastBot,
    ClientGender? gender,
  }) {
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final words = compact.split(' ').where((w) => w.isNotEmpty).toList();
    final first = words.isEmpty ? '' : words.first;
    final hasContext = lastBot != null && lastBot.trim().isNotEmpty;
    final isGreeting = const {
          'привет',
          'приветик',
          'здравствуй',
          'здравствуйте',
          'хай',
          'hello',
          'hi',
          'hey',
          'здорово',
          'хелло',
          'салют',
          'йо',
        }.contains(first) ||
        compact.startsWith('добрый день') ||
        compact.startsWith('доброе утро') ||
        compact.startsWith('добрый вечер') ||
        compact.startsWith('доброй ночи') ||
        compact == 'добрый' ||
        compact == 'доброе';
    if (isGreeting && words.length <= 6) {
      final man = gender == ClientGender.man;
      return man
          ? _pick('greet-m', const [
              'Здравствуйте, я Мира. Рада вас слышать — давайте как на приёме: что сейчас с кожей или самочувствием?',
              'Здравствуйте! Я Мира, косметолог CULT. Чем могу помочь — освежить вид, разобрать морщинки или просто поговорить?',
              'Здравствуйте, это Мира. Я рядом: расскажите своими словами про кожу или самочувствие.',
            ], q)
          : _pick('greet-w', const [
              'Здравствуйте, я Мира. Рада вас слышать — давайте спокойно: что сейчас с кожей или самочувствием?',
              'Здравствуйте! Я Мира, косметолог CULT. Чем помочь — освежить вид, морщинки, усталость или запись?',
              'Здравствуйте, это Мира. Говорите как удобно — я подстроюсь и предложу из наших протоколов.',
            ], q);
    }
    if (q.contains('как дела') ||
        q.contains('как ты') ||
        q.contains('как вы') ||
        q.contains('как настроен') ||
        q.contains('как жизнь') ||
        q.contains('как пожива') ||
        q.contains('how are you') ||
        compact == 'как самочувствие' ||
        compact == 'как настроение') {
      return _pick('how-are', const [
        'Спасибо, у меня всё ровно — и я целиком для вас. А вы как себя чувствуете сегодня?',
        'Хорошо, спасибо. Как вы себя чувствуете: кожа спокойная или что-то тянет?',
        'Всё ровно, спасибо. Расскажите про себя — вместе найдём, что подтянуть.',
      ], q);
    }
    if (words.any(
      (w) => const {
        'спасибо',
        'благодарю',
        'сенкс',
        'thanks',
        'благодарствую',
      }.contains(w),
    )) {
      return _pick('thanks', const [
        'И вам спасибо. Я рядом — можно продолжить без спешки.',
        'Спасибо вам. Если ещё что-то всплывёт — просто скажите.',
        'Вам спасибо. Остаюсь на связи.',
      ], q);
    }
    if (compact == 'пока' ||
        compact.startsWith('до встречи') ||
        compact.startsWith('всего доброго') ||
        compact.startsWith('до свидания') ||
        compact == 'спокойной ночи') {
      return _pick('bye', const [
        'Всего доброго. Берегите себя — буду рада снова услышать вас.',
        'До связи. Если что-то всплывёт — я здесь.',
        'Хорошего дня. Загляните, когда захотите продолжить.',
      ], q);
    }
    final asksName = q.contains('как тебя зовут') ||
        q.contains('как вас зовут') ||
        q.contains('как зовут') ||
        q.contains('твое имя') ||
        q.contains('твоё имя') ||
        q.contains('ваше имя') ||
        q.contains('как имя') ||
        compact == 'имя' ||
        compact == 'представься' ||
        compact == 'представитесь';
    final asksAbout = q.contains('кто ты') ||
        q.contains('кто вы') ||
        q.contains('что ты умеешь') ||
        q.contains('что вы умеете') ||
        q.contains('чем можешь помочь') ||
        q.contains('чем можете помочь') ||
        q.contains('расскажи о себе') ||
        q.contains('расскажите о себе') ||
        q.contains('ты врач') ||
        q.contains('ты бот') ||
        q.contains('ты робот') ||
        q.contains('ты ии') ||
        q.contains('ты нейросет') ||
        q.contains('ты искусствен') ||
        q.contains('are you a bot') ||
        q.contains('are you ai') ||
        q.contains('ты человек');
    if (asksName) {
      return _pick('my-name', const [
        'Меня зовут Мира. Я косметолог CULT — можно просто поговорить о коже или сразу про визит.',
        'Я Мира. Работаю с эстетикой и уходом в CULT: слушаю задачу и предлагаю спокойный следующий шаг.',
        'Мира. Приятно познакомиться — расскажите, что сейчас важнее для кожи или самочувствия.',
      ], q);
    }
    if (asksAbout) {
      return _pick('who-am-i', const [
        'Я Мира, косметолог CULT в приложении. Не заменяю очный осмотр, но могу разобрать задачу и предложить наши услуги или шоп. О чём подумаем?',
        'Я из команды CULT, зовут Мира. Говорю как на приёме: кожа, энергия, запись — без роботского сценария. Чем помочь?',
        'Коротко: я Мира. Помогаю сориентироваться в протоколах CULT и домашнем уходе; окончательное решение — за врачом очно.',
      ], q);
    }
    if (q.contains('на английском') ||
        q.contains('speak english') ||
        q.contains('do you speak') ||
        q.contains('говорите по-англий') ||
        q.contains('говорите по англий') ||
        q.contains('переводчик') ||
        compact == 'english' ||
        compact == 'английский') {
      return 'I can help in simple English: booking, massage, facials, RF, IV drips, and shop formulas at CULT Sochi (Chernomorskaya 6, 9:00–21:00). '
          'For an interpreter or English-speaking staff — ask admin in chat. Clinical decisions need a doctor. Or continue in Russian.';
    }
    if (words.length <= 6 &&
        const {
          'подскажи',
          'посоветуй',
          'помоги',
          'совет',
          'поможешь',
          'подскажете',
        }.contains(first)) {
      // Open «посоветуй что-нибудь» → _situationReply (richer, gender-aware).
      if (compact.contains('что-нибудь') ||
          compact.contains('что нибудь') ||
          compact.contains('что мне') ||
          compact.startsWith('порекомендуй')) {
        return null;
      }
      // «Помоги с морщинами» / «подскажи про сухость» → concern, not empty tip.
      if (_concernReply(q, gender: gender) != null) return null;
      return _pick('tip-soft', const [
        'Конечно, давайте вместе. Коротко: лицо или тело, что хотите улучшить?',
        'С удовольствием, вместе разберём. Что ближе — лицо, самочувствие или запись?',
        'Да, подскажу. Одного ориентира хватит: лицо, тело или энергия.',
      ], q);
    }
    if (compact == 'нужен совет' ||
        compact == 'что посоветуешь' ||
        compact == 'есть вопрос' ||
        compact == 'давай поговорим' ||
        compact == 'поговорим' ||
        compact.contains('просто поговорить') ||
        compact.contains('можно поговорить')) {
      return 'Да, давайте поговорим спокойно. '
          'Можете начать с ощущения: сухость, усталость, «хочу свежий вид» — или спросить про клинику. Я подстроюсь.';
    }
    // With prior bot line, let _followUpReply own short yes/no.
    if (hasContext &&
        words.length <= 3 &&
        const {
          'да',
          'ага',
          'угу',
          'ок',
          'окей',
          'хорошо',
          'ладно',
          'понятно',
          'ясно',
          'давай',
          'конечно',
          'нет',
          'не надо',
          'не нужно',
          'потом',
        }.contains(compact)) {
      return null;
    }
    if (words.length <= 3 &&
        const {
          'да',
          'ага',
          'угу',
          'ок',
          'ok',
          'okay',
          'окей',
          'хорошо',
          'ладно',
          'ну ладно',
          'понятно',
          'ясно',
          'давай',
          'конечно',
        }.contains(compact)) {
      return 'Хорошо. Тогда скажите чуть конкретнее: лицо, тело, энергия или запись — продолжим в вашем темпе.';
    }
    if (words.length <= 4 &&
        const {
          'нет',
          'не надо',
          'не нужно',
          'потом',
          'ну ладно потом',
        }.contains(compact)) {
      return 'Хорошо, без давления. Если позже захотите совет или запись — просто напишите или нажмите «Голос».';
    }
    if (q.contains('голос стран') ||
        q.contains('робот голос') ||
        q.contains('звучит как робот') ||
        q.contains('неживой голос')) {
      return _pick('voice-robot', const [
        'Понимаю, синтетический голос раздражает. Могу отвечать короче — скажите «короче» или тему одним словом.',
        'Слышу. Давайте текстом короче и по делу: одно слово — сухость, массаж, запись — и продолжим.',
        'Ок, без лишней озвучки. Напишите или скажите коротко, что важно — отвечу спокойно.',
      ], q);
    }
    if (compact.contains('не знаю') ||
        compact == 'хз' ||
        compact.contains('затрудняюсь') ||
        compact.contains('без понятия')) {
      return 'Это нормально — не нужно сразу знать название процедуры. '
          'Скажите, что видите в зеркале: тусклость, отёк, морщинки, пигмент? Я предложу два мягких варианта.';
    }
    if (q.contains('боюсь') ||
        q.contains('страшно') ||
        q.contains('больно ли') ||
        q.contains('это больно') ||
        q.contains('пережива')) {
      return 'Страх перед процедурой понятен. Большинство протоколов делаем с аппликационной анестезией, темп спокойный. '
          'На консультации честно скажем, чего ждать — можете начать с осмотра без процедуры в тот же день.';
    }
    if (q.contains('дорого') ||
        q.contains('бюджет') ||
        q.contains('подешевле') ||
        q.contains('недорого')) {
      return 'Бюджет учтём. Есть уходы и домашний шоп как более мягкий вход, а курсы иногда выгоднее разового визита. '
          'Назовите потолок или зону — подберу реалистичные варианты и запись.';
    }
    if (q.contains('первый раз') ||
        q.contains('никогда не был') ||
        q.contains('никогда не была') ||
        q.contains('новичок')) {
      return 'Добро пожаловать. Обычно начинаем с короткой консультации: смотрим кожу, цели и противопоказания, затем предлагаем один понятный шаг. '
          'Welcome-бонус 3 000 ₽ новым клиентам после входа по телефону. Запишем через «+»?';
    }
    if (q.contains('расскажи о клиник') ||
        q.contains('что за культ') ||
        q.contains('про клинику') ||
        q.contains('чем вы занима')) {
      return 'CULT в Сочи — клиника эстетики и биохакинга на Черноморской, 6. '
          'Уходы, инъекции, аппаратная, инфузии, лаборатория и шоп формул. Работаем ежедневно с девяти до девяти вечера. Чем помочь лично вам?';
    }
    if (q.contains('скучно') ||
        q.contains('расскажи что') ||
        q.contains('анекдот') ||
        q.contains('пошути')) {
      return 'Могу быть лёгкой, но по делу: лучше расскажу, как за один визит освежить тон или снять отёк массажем. '
          'Хотите «быстрый эффект к вечеру» или «долгий результат курсом»?';
    }
    return null;
  }

  String? _followUpReply(
    String q,
    String? lastBot, {
    ClientGender? gender,
    String? lastUser,
  }) {
    if (lastBot == null || lastBot.isEmpty) {
      // Still allow «а дальше» from last user concern without bot CTA.
      if (lastUser != null && lastUser.trim().isNotEmpty) {
        final resume = _resumeLastUser(q, lastUser, gender: gender);
        if (resume != null) return resume;
      }
      return null;
    }
    final prev = _normalize(lastBot);
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final words = compact.split(' ').where((w) => w.isNotEmpty).toList();
    final shortYes = words.length <= 3 &&
        const {
          'да',
          'ага',
          'угу',
          'ок',
          'ok',
          'okay',
          'окей',
          'хорошо',
          'ладно',
          'ну ладно',
          'понятно',
          'ясно',
          'давай',
          'конечно',
          'согласна',
          'согласен',
        }.contains(compact);
    final shortNo = words.length <= 3 &&
        const {
          'нет',
          'не надо',
          'не нужно',
          'потом',
          'не сейчас',
          'позже',
          'ну ладно потом',
        }.contains(compact);

    final offeredBooking = prev.contains('запис') ||
        prev.contains('через «+»') ||
        prev.contains('через "+"') ||
        prev.contains('через плюс') ||
        prev.contains('консультац') ||
        prev.contains('осмотр');
    final offeredCompare = prev.contains('сравнить') ||
        prev.contains('что ближе') ||
        prev.contains('с чего начн');
    final askedMirror = prev.contains('что видите в зеркале') ||
        prev.contains('что заметнее') ||
        prev.contains('что не нравится') ||
        prev.contains('что беспокоит') ||
        prev.contains('что смущает');

    if (shortYes) {
      if (offeredBooking) {
        return _pick('yes-book', const [
          'Отлично. Нажмите «+» на главной или откройте «Запись»: услуга, врач, время. Если протокол ещё не ясен — возьмите консультацию.',
          'Хорошо, к записи. «+» на главной или меню «Запись» — выберете окно; на осмотре уточним детали.',
          'Договорились. Оформить визит удобно через «+» или «Запись»; можно начать с короткой консультации.',
        ], q);
      }
      if (offeredCompare) {
        return _pick('yes-compare', const [
          'Хорошо. Скажите полюса: массаж или RF, крем или сыворотка — или что видите в зеркале.',
          'Ок, сравню. Два ориентира или одна зона в зеркале — и разложу спокойно.',
          'Приняла. Назовите два варианта или задачу — без каталожного языка.',
        ], q);
      }
      if (askedMirror) {
        return _pick('yes-mirror', const [
          'Давайте по зеркалу: сухость, тусклость, морщинки, отёк или пигмент? Одного слова хватит.',
          'Ок, смотрим в зеркало. Что заметнее — стянутость, тусклость, линии или отёк?',
          'Хорошо. Коротко: сухость, пигмент, морщинки или тяжесть в лице?',
        ], q);
      }
      return _pick('yes-soft', const [
        'Хорошо, продолжаем. Лицо, тело, энергия или запись — что сейчас ближе?',
        'Ок, идём дальше. Ближе кожа в зеркале, самочувствие или сразу запись?',
        'Договорились. С чего удобнее — зона, ощущение или визит?',
      ], q);
    }
    if (shortNo) {
      return _pick('short-no', const [
        'Хорошо, без давления. Можем просто поговорить о коже или уходе — или вернётесь позже.',
        'Ок, не настаиваю. Если позже захотите совет — просто скажите или нажмите микрофон.',
        'Поняла, пауза нормальна. Я на связи, когда будете готовы.',
      ], q);
    }

    // Choice after «быстрый эффект / курс» or massage vs RF.
    if (prev.contains('быстрый эффект') ||
        prev.contains('долгий результат') ||
        prev.contains('к вечеру')) {
      if (compact.contains('быстр') ||
          compact.contains('вечер') ||
          compact.contains('сейчас') ||
          compact.contains('срочно')) {
        return 'Тогда ближе уход или скульптурный массаж — свежий вид без долгой реабилитации. '
            'Скажите дату события или «массаж» — уточню и помогу с записью.';
      }
      if (compact.contains('курс') ||
          compact.contains('долг') ||
          compact.contains('надолго') ||
          compact.contains('стойк')) {
        return 'Для стойкого эффекта смотрим курс: RF, пилинги или инъекции — только после осмотра. '
            'Запишем короткую консультацию через «+», чтобы не гадать по фото?';
      }
    }
    if (prev.contains('массаж') && prev.contains('rf')) {
      if (compact.contains('массаж') || compact.contains('мягк')) {
        return 'Отличный мягкий вход — массаж. Спросите «массаж» для цены и длительности '
            'или сразу «+» на запись. Если позже захотите плотность — вернёмся к RF.';
      }
      if (compact.contains('rf') ||
          compact.contains('рф') ||
          compact.contains('аппарат') ||
          compact.contains('плотност')) {
        return 'Тогда логичен микроигольчатый RF после осмотра — курс и интенсивность под вашу кожу. '
            'Могу назвать ориентир по цене («микроигольчатый RF») или записать на консультацию через «+».';
      }
    }

    if (prev.contains('лицо или тело') ||
        prev.contains('лицо, тело') ||
        prev.contains('лицо, тело, энергия') ||
        prev.contains('с чего начн')) {
      if (compact.contains('лиц')) {
        return 'Отлично, про лицо. Что заметнее: сухость, тусклость, морщинки, отёк или пигмент? '
            'От этого мягко выберу массаж, уход, аппаратную или домашний крем.';
      }
      if (compact.contains('тел')) {
        return 'Хорошо, про тело. Чаще смотрим плотность, рельеф или общий тонус — без жёстких обещаний «за один раз». '
            'Могу рассказать про аппаратные протоколы или спокойно записаться на консультацию. Что ближе?';
      }
      if (compact.contains('энерг') ||
          compact.contains('сил') ||
          compact.contains('устало')) {
        return 'Тогда ближе поддержка изнутри: инфузии NAD+, Immunity или Beauty & Glow. '
            'Могу коротко сравнить три или сразу открыть запись через «+» на главной.';
      }
      if (compact.contains('уход') ||
          compact.contains('дом') ||
          compact.contains('крем') ||
          compact.contains('сывор') ||
          compact.contains('запис')) {
        if (compact.contains('запис')) {
          return 'Тогда запись: «+» на главной или меню «Запись» — услуга, врач, время. '
              'Если протокол ещё не ясен, возьмите консультацию.';
        }
        return 'Для дома хорошо заходят барьерный крем и пептидная сыворотка из шопа. '
            'Скажите «крем» или «сыворотка» — назову цену и наличие, без лишней суеты.';
      }
    }
    if (prev.contains('сравнить') ||
        prev.contains('два спокойных') ||
        prev.contains('что ближе')) {
      final concern = _concernReply(q, gender: gender);
      if (concern != null) return concern;
      if (compact.contains('запис') ||
          compact.contains('консульт') ||
          compact.contains('врач')) {
        return 'Тогда логичный шаг — короткая консультация: посмотрим кожу и цели, без процедуры в тот же день, если не готовы. '
            'Запись через «+» на главной или меню «Запись».';
      }
    }
    if (askedMirror) {
      final zone = _zoneOnlyReply(q);
      if (zone != null) return zone;
      if (compact.contains('лиц')) {
        return 'Отлично, про лицо. Что заметнее: сухость, тусклость, морщинки, отёк или пигмент? '
            'От этого мягко выберу массаж, уход, аппаратную или домашний крем.';
      }
      if (compact.contains('тел') && !compact.contains('телефон')) {
        return 'Хорошо, про тело. Чаще смотрим плотность, рельеф или тонус — без обещаний «за один раз». '
            'Ближе консультация с аппаратной или сначала просто осмотр?';
      }
      final concern = _concernReply(q, gender: gender);
      if (concern != null) return concern;
      return 'Слышу вас. Одного слова из зеркала достаточно: сухость, тусклость, морщинки, отёк или пигмент — '
          'предложу мягкий старт.';
    }
    // Continue after event / near-date advice («что можно» after wedding).
    if (prev.contains('близкой дате') ||
        prev.contains('под дату') ||
        prev.contains('реабилитац')) {
      if (compact.contains('что можно') ||
          compact.contains('какие вариант') ||
          compact.contains('что делать') ||
          compact == 'можно' ||
          compact.contains('без реабилита')) {
        return 'К близкой дате спокойно: скульптурный массаж, увлажняющий уход, иногда Beauty & Glow — без тяжёлой реабилитации. '
            'Скажите зону (лицо / отёк / тон) или «запись» — зафиксируем один шаг.';
      }
    }
    // Late / reschedule follow-ups.
    if (prev.contains('опаздыва') ||
        prev.contains('опозда') ||
        prev.contains('сдвинут')) {
      if (compact.contains('что делать') ||
          compact.contains('и что') ||
          compact == 'дальше' ||
          compact.contains('а дальше')) {
        return 'Напишите администратору в чат прямо сейчас — слот сдвинут или предложат ближайшее окно. '
            'Если уже в пути, напишите примерно, на сколько минут опаздываете.';
      }
    }
    // «Что тогда» after без уколов / preference.
    if (prev.contains('без укол') ||
        prev.contains('инъекции снимаем') ||
        prev.contains('инъекции не предлагаю') ||
        prev.contains('без инъек') ||
        prev.contains('без аппарат')) {
      if (compact.contains('что тогда') ||
          compact.contains('тогда что') ||
          compact.contains('а что тогда') ||
          compact.contains('чем заменить') ||
          compact.contains('что оста') ||
          compact.contains('а чем') ||
          compact == 'и что') {
        if (prev.contains('без аппарат') || prev.contains('без инъекций и без аппарат')) {
          return 'Остаются массаж, уходы и домашний барьер — без кресла «тяжёлой» аппаратной и без уколов. '
              'Скажите «массаж», «крем» или «запись на уход».';
        }
        return 'Тогда без уколов: скульптурный массаж, увлажняющий уход, домашний барьер; при цели по овалу — RF после осмотра. '
            'Скажите «массаж», «уход» или «запись» — продолжим конкретно.';
      }
    }
    if (prev.contains('камен') ||
        prev.contains('мимик') ||
        prev.contains('натуральн')) {
      if (compact.contains('тогда') ||
          compact.contains('что тогда') ||
          compact.contains('тогда что') ||
          compact.contains('а что') ||
          compact.contains('чем ')) {
        return 'Тогда держим натуральность: массаж и уход без «заморозки»; если позже инъекции — только после осмотра и с сохранением мимики. '
            'Скажите «массаж» или «запись на консультацию».';
      }
    }
    if ((prev.contains('близкой дате') ||
            prev.contains('событ') ||
            prev.contains('к вечеру') ||
            prev.contains('реабилитац')) &&
        (compact.contains('что успеем') ||
            compact.contains('что успеть') ||
            compact.contains('успеем'))) {
      return 'Успеем спокойное: скульптурный массаж или увлажняющий уход — без отёка «на выход». '
          'Запись через «+» на ближайшее окно; если уже поздно вечером — лучше перенести на утро перед событием.';
    }
    if ((prev.contains('кислот') ||
            prev.contains('пилинг') ||
            prev.contains('ретинол') ||
            prev.contains('воспален')) &&
        (compact == 'а дома' ||
            compact.contains('а дома') ||
            compact.contains('дома что') ||
            compact.contains('что дома'))) {
      return 'Дома сейчас мягко: барьерный крем, без новых кислот и ретинола, пока врач не скажет иначе. '
          'Скажите «крем» — назову формулу из шопа.';
    }
    if ((prev.contains('аллерг') || prev.contains('анестез')) &&
        (compact.contains('что можно') ||
            compact.contains('какие вариант') ||
            compact.contains('тогда что') ||
            compact.contains('что тогда'))) {
      return 'При аллергии двигаемся только после осмотра: часто мягкий уход и массаж без лишней анестезии; инъекции и аппаратную — по допуску врача. '
          'Напишите аллерген в чат специалиста или запишитесь через «+».';
    }
    return null;
  }

  /// «Что лучше…» / сравнения до сырого каталога.
  String? _compareReply(String q, {ClientGender? gender}) {
    final asksCompare = q.contains('что лучше') ||
        q.contains('что выбрать') ||
        q.contains('что предпочесть') ||
        q.contains('сравни') ||
        q.contains('чем отлича') ||
        q.contains('или лучше') ||
        (q.contains(' лучше ') && (q.contains(' или ') || q.contains(' vs ')));
    if (!asksCompare) return null;

    final man = gender == ClientGender.man;
    final hasMassage = q.contains('массаж') || q.contains('лимфодрен');
    final hasRf = q.contains('rf') ||
        q.contains('рф') ||
        q.contains('аппарат') ||
        q.contains('микроиголь');
    final hasInject = q.contains('инъек') ||
        q.contains('ботокс') ||
        q.contains('филлер') ||
        q.contains('мезо');
    final hasPeel = q.contains('пилинг') || q.contains('чистка');
    final hasCare = q.contains('уход') || q.contains('крем') || q.contains('сывор');
    final hasInfusion = q.contains('инфуз') ||
        q.contains('капель') ||
        q.contains('nad') ||
        q.contains('immunity');

    if (hasMassage && hasRf) {
      return man
          ? 'Коротко: массаж даёт свежий вид и снятие напряжения уже после визита; RF — про плотность и овал курсом, без «перекачанного» эффекта. '
              'Если хотите мягкий вход — массаж; если цель — уплотнить контур — смотрим RF на консультации. С чего начнём?'
          : 'Коротко: массаж — быстрый «живой» рельеф и лимфа; микроигольчатый RF — плотность и овал на дистанции курса. '
              'К событию через пару дней чаще массаж или уход; для стойкого эффекта — RF после осмотра. Что ближе вашей задаче?';
    }
    if (hasInject && (hasMassage || hasCare || hasPeel)) {
      return 'Инъекции сильнее меняют мимику или объём, но это уже медицинский шаг. '
          'Массаж, уход или пилинг — мягче: можно начать с них, а инъекции обсудить на осмотре, если не хватит эффекта. '
          'Скажите зону и срок — предложу спокойную последовательность.';
    }
    if (hasPeel && hasCare) {
      return 'Пилинг работает интенсивнее и даёт смену тона и текстуры, но нужна подготовка и уход после. '
          'Домашний крем или сыворотка — ежедневная поддержка без реабилитации. '
          'Если кожа чувствительная или скоро солнце или мероприятие — чаще начинаем с ухода. Подсказать формулу из шопа?';
    }
    if (hasInfusion ||
        (q.contains('энерг') && (q.contains('уход') || q.contains('лицо')))) {
      return 'Если тянет «нет сил» — ближе инфузии: NAD+ для энергии, Immunity для поддержки, Beauty & Glow для кожи. '
          'Если задача в зеркале (тон, овал, сухость) — сначала уход, массаж или аппаратная. '
          'Могу сравнить три капельницы или сузить по лицу — что сейчас важнее?';
    }
    if (q.contains('крем') && q.contains('сывор')) {
      return 'Сыворотка — активный концентрат (пептиды, плотность), крем — барьер и комфорт на весь день. '
          'Часто берут вместе: Veil Peptide под низ, Lumen Barrier сверху. '
          'Скажите «сыворотка» или «крем» — назову цену и наличие.';
    }
    if (q.contains('ipl') || (q.contains('лазер') && q.contains('пилинг'))) {
      return 'IPL и лазер сильнее работают с пигментом и сосудами, но важны фототип и пауза от солнца. '
          'Пилинг мягче входит в сезон и тон, реабилитация обычно короче. '
          'Без осмотра не выбираю «что мощнее» — запишем короткую консультацию через «+»?';
    }

    return 'Чтобы честно сравнить, нужны два полюса: например массаж или RF, крем или сыворотка, энергия или лицо. '
        'Или опишите результат к дате — предложу два спокойных варианта без давления.';
  }

  /// Deadline, event, age band, open-ended «посоветуй».
  String? _situationReply(
    String q, {
    ClientGender? gender,
    String topic = '',
  }) {
    final man = gender == ClientGender.man;
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final wordCount =
        compact.split(' ').where((w) => w.isNotEmpty).length;
    final soon = q.contains('завтра') ||
        q.contains('послезавтра') ||
        q.contains('сегодня') ||
        q.contains('через день') ||
        q.contains('через два') ||
        q.contains('через три') ||
        q.contains('через 3') ||
        q.contains('на выходн') ||
        q.contains('к вечеру') ||
        q.contains('к понедельник') ||
        q.contains('на работу') ||
        q.contains('срочно');
    final event = q.contains('свадьб') ||
        q.contains('день рожден') ||
        q.contains('мероприят') ||
        q.contains('событ') ||
        q.contains('съемк') ||
        q.contains('фотосес') ||
        q.contains('отпуск') ||
        q.contains('выпускн') ||
        q.contains('праздник');
    final weekish = q.contains('через недел') ||
        q.contains('через две') ||
        q.contains('через месяц') ||
        q.contains('к лету') ||
        q.contains('к отпуск');

    if (soon ||
        (event && (soon || q.contains('скоро') || q.contains('через')))) {
      return 'К близкой дате не берём тяжёлую реабилитацию. Чаще — уход с сыворотками или скульптурный массаж, иногда лёгкая инфузия Beauty & Glow. '
          'Скажите точную дату и зону (лицо / отёк / тон) — предложу один спокойный протокол и запись.';
    }
    if (event || weekish) {
      return 'Под дату есть запас — можно сочетать мягкий старт сейчас и при необходимости курс после осмотра. '
          'Назовите, что важнее в кадре: тон, овал, свежесть или энергия — сузим до двух вариантов.';
    }
    if (RegExp(r'(мне |мне)\s*\d{2}').hasMatch(q) ||
        RegExp(r'\d{2}\s*лет').hasMatch(q)) {
      final blob = '$topic $q';
      if (blob.contains('прыщ') ||
          blob.contains('акне') ||
          blob.contains('acne') ||
          blob.contains('воспал') ||
          blob.contains('высып')) {
        return 'В вашем возрасте воспаления в CULT: осмотр → щадящий уход или химический пилинг L3 по фототипу, без агрессии дома. '
            'Запись через «+»; зона одним словом поможет выбрать протокол.';
      }
      if (blob.contains('морщин') ||
          blob.contains('овал') ||
          blob.contains('помолод') ||
          blob.contains('антивозраст')) {
        return 'Возраст — фон: в CULT смотрим кожу. Мягкий вход — скульптурный массаж или HydraPure; RF/инъекции — после осмотра. '
            'Свежесть, плотность овала или запись на консультацию?';
      }
      return 'Цифра в паспорте не диктует протокол CULT. Скажите задачу — сухость, овал, мимика или энергия — сопоставлю с прайсом филиала.';
    }
    if (q.contains('посоветуй что') ||
        q.contains('порекомендуй') ||
        q.contains('не знаю с чего') ||
        q.contains('с чего начать') ||
        q.contains('что мне сделать') ||
        q.contains('что мне подходит') ||
        compact.contains('посоветуй что-нибудь') ||
        (compact.startsWith('посоветуй') && wordCount <= 6) ||
        (compact.startsWith('порекомендуй') && wordCount <= 6)) {
      return man
          ? 'Частый спокойный старт для мужчин: барбер-массаж или осмотр с разговором про овал и кожу, дома — простой барьерный уход. '
              'Скажите, что важнее — свежий вид к дате или плотность курсом — и сузим.'
          : 'Частый спокойный старт: скульптурный массаж или увлажняющий уход, дома — барьерный крем; если сил мало — коротко про инфузии. '
              'Скажите, что важнее сейчас — зеркало, энергия или запись — и выберем один шаг.';
    }

    final budgetMatch = RegExp(r'до\s*(\d+[\s\u00a0]?\d*)').firstMatch(q);
    final thousands = RegExp(r'до\s*(\d+)\s*тыс').firstMatch(q);
    if (budgetMatch != null ||
        thousands != null ||
        q.contains('не больше') ||
        q.contains('максимум')) {
      final raw = thousands != null
          ? (int.tryParse(thousands.group(1)!) ?? 0) * 1000
          : int.tryParse(
                (budgetMatch?.group(1) ?? '').replaceAll(RegExp(r'[\s\u00a0]'), ''),
              ) ??
              0;
      if (raw > 0 && raw <= 15000) {
        return 'В коридоре до ${_rub(raw)} реалистичны уходы, массаж и формулы из шопа; тяжёлую аппаратную лучше обсуждать отдельно. '
            'Скажите зону — лицо или тело — подберу спокойный вход в бюджет.';
      }
      if (raw > 15000) {
        return 'Ориентир до ${_rub(raw)} уже открывает уходы, массаж и часть аппаратных/инъекционных протоколов после осмотра. '
            'Что в приоритете — свежий вид, овал или энергия? Сузим до двух вариантов.';
      }
      return 'Бюджет учтём без давления. Назовите потолок цифрой или зону — подберу вход: уход, массаж, шоп или консультацию.';
    }
    return null;
  }

  /// Free-form goals mapped onto real CULT catalog (services / shop / infusions).
  String? _concernReply(String q, {ClientGender? gender}) {
    final man = gender == ClientGender.man;
    final massage = _clinicService(
      man ? 'барбер-массаж' : 'скульптурный массаж',
      gender: gender,
    );
    final rf = _clinicService(man ? 'мужской rf' : 'микроигольчатый rf', gender: gender);
    final hydra = _clinicService('hydrapure', gender: gender);
    final peel = _clinicService('химический пилинг', gender: gender);
    final botox = _clinicService('ботулинотерап', gender: gender);
    final meso = _clinicService('мезотерап', gender: gender);
    final barrier = _clinicProduct('lumen barrier');
    final peptide = _clinicProduct('veil peptide');
    final nad = _clinicInfusion('nad');
    final glow = _clinicInfusion('beauty');
    final immunity = _clinicInfusion('immunity');

    if (q.contains('сух') ||
        q.contains('стягив') ||
        q.contains('шелуш') ||
        q.contains('обезвож')) {
      final chair = _lineService(hydra) ?? 'увлажняющий уход HydraPure';
      final home = _lineProduct(barrier) ?? 'Lumen Barrier Cream';
      return _pick('concern-dry', [
        'Стянутость очень знакома — чаще всего это барьер, а не «надо сильнее кислоты». '
            'У нас спокойный путь: $chair в кресле и дома $home. Хотите сначала крем или визит?',
        'Если кожа шелушится и стягивает, я бы не сушила её пилингом сразу. '
            'В CULT обычно: $chair, дома — $home. Могу подсказать по крему или записать на уход.',
        'Похоже на обезвоженность и слабый барьер. Давайте мягко: $chair и $home, без агрессии в первый шаг. Что ближе — шоп или кресло?',
      ], q);
    }
    if (q.contains('жирн') ||
        q.contains('блеск') ||
        q.contains('расшир') ||
        q.contains('поры') ||
        q.contains('пор ')) {
      return 'Блеск и поры: сначала осмотр, затем либо плотный уход ${_lineService(hydra) ?? 'HydraPure'}, '
          'либо уплотнение ${_lineService(rf) ?? 'микроигольчатым RF'} после согласования. '
          'Жёсткую чистку «в лоб» не предлагаю. Нужна цена RF или запись на консультацию?';
    }
    // Not «постакне» — that has its own FAQ path.
    if (((q.contains('акне') || q.contains('acne')) &&
            !q.contains('постакне') &&
            !q.contains('postacne')) ||
        q.contains('прыщ') ||
        q.contains('воспал') ||
        q.contains('высып')) {
      final peelLine = _lineService(peel) ?? 'химический пилинг L3';
      return _pick('concern-acne', [
        'Воспаления в CULT не «жжём» дома: очный осмотр → щадящий уход или $peelLine по фототипу. '
            'Запись через «+»; зона одним словом поможет сузить протокол.',
        'С прыщами и воспалением лучше не экспериментировать самой: осмотр, затем мягкий уход или $peelLine. '
            'Могу помочь записаться через «+».',
        'Для высыпаний сначала смотрим кожу вживую — домашний жёсткий разбор часто ухудшает. '
            'В прайсе дальше уход или $peelLine. Запишем осмотр?',
      ], q);
    }
    if (q.contains('каменн') ||
        q.contains('каменным') ||
        q.contains('без мимик') ||
        q.contains('натуральн результат') ||
        q.contains('натуральный результат') ||
        q.contains('не хочу чтобы было видно') ||
        q.contains('коллеги не') ||
        q.contains('чтобы не заметил') ||
        q.contains('чтобы не было видно') ||
        q.contains('естественн результат')) {
      return 'Натуральный результат в CULT: старт ${_lineService(massage) ?? 'массажем лица'} или уходом, '
          'ботулинотерапия/филлеры — только после осмотра и с сохранением мимики. '
          'Что важнее — свежесть без следов или обсудить дозировку на консультации?';
    }
    if (q.contains('помолодеть') ||
        q.contains('омоложен') ||
        q.contains('антивозраст') ||
        q.contains('anti age') ||
        q.contains('anti-age') ||
        q.contains('antiage') ||
        (q.contains('моложе') && (q.contains('выгляд') || q.contains('хочу')))) {
      return man
          ? 'Свежий вид без «перекачки»: ${_lineService(massage) ?? 'барбер-массаж'}, '
              'при необходимости ${_lineService(rf) ?? 'мужской RF-лифтинг'} после осмотра, дома — ${_lineProduct(barrier) ?? 'барьерный крем'}. '
              'Быстрый эффект к дате или курс на плотность?'
          : 'Омоложение без жёстких обещаний: ${_lineService(massage) ?? 'скульптурный массаж'} или уход, дома ${_lineProduct(barrier) ?? 'барьер'} / ${_lineProduct(peptide) ?? 'пептиды'}; '
              'RF или инъекции — только после осмотра. Свежесть к дате или плотность курсом?';
    }
    if (q.contains('морщин') ||
        q.contains('мими') ||
        q.contains('лоб') ||
        q.contains('гусиные') ||
        q.contains('избавиться от морщ') ||
        q.contains('убрать морщ') ||
        q.contains('разгладить')) {
      final inject = _lineService(botox) ?? 'ботулинотерапия';
      final soft = _lineService(massage) ?? 'скульптурный массаж';
      final home = _lineProduct(peptide) ?? 'Veil Peptide Serum';
      return _pick('concern-wrinkle', [
        'Морщинки часто обидно замечать в зеркале — понимаю. Мягкий старт у нас: $soft или плотный уход, дома — $home. '
            'Если хотите заметнее и быстрее — $inject после осмотра. С чего вам спокойнее начать?',
        'От мимических линий обычно идём двумя путями: без укола — $soft и пептиды, или $inject, когда готовы. '
            'Я не тороплю к инъекциям. Что ближе — мягкий ритуал или обсудить уколы на консультации?',
        'Избавиться «насовсем» честно нельзя обещать, но освежить — да. В CULT чаще начинают с $soft, '
            'а $inject подключают точечно после осмотра. Расскажите, зона — лоб, глаза или носогубки?',
      ], q);
    }
    if (q.contains('овал') ||
        q.contains('второй подбородок') ||
        q.contains('брыл') ||
        q.contains('контур лиц')) {
      return man
          ? 'Овал у мужчин в CULT: ${_lineService(rf) ?? 'мужской RF-лифтинг'} или ${_lineService(massage) ?? 'барбер-массаж'} — контур без объёма «на показ». '
              'Ориентир по цене или сразу запись на осмотр?'
          : 'Овал: чаще ${_lineService(massage) ?? 'скульптурный массаж лица'}, при необходимости ${_lineService(rf) ?? 'микроигольчатый RF'}. '
              'Сравнить два варианта или сразу консультация?';
    }
    if (q.contains('отек') ||
        q.contains('мешк') ||
        q.contains('одутл') ||
        q.contains('пастоз')) {
      return 'Отёк и тяжесть: в прайсе CULT это ${_lineService(massage) ?? 'скульптурный / лимфодренажный массаж'} плюс питьевой режим. '
          'Скажите «массаж» — уточню длительность и цену из каталога.';
    }
    if (q.contains('пигмент') ||
        q.contains('пятн') ||
        q.contains('веснуш') ||
        q.contains('неравном')) {
      return 'Пигмент по фототипу: ${_lineService(peel) ?? 'химический пилинг L3'} или аппарат Lumecca IPL из раздела «Аппаратная», без домашнего отбеливания. '
          'Скажите «пилинг» / «IPL» для цифр или запишем осмотр через «+».';
    }
    if (q.contains('тускл') ||
        q.contains('серый') ||
        q.contains('серая') ||
        q.contains('серое') ||
        q.contains('серой') ||
        q.contains('сияни') ||
        q.contains('свежий вид') ||
        q.contains('освежить') ||
        q.contains('перед мероприя') ||
        q.contains('на выход') ||
        q.contains('выглядеть')) {
      return 'К событию без долгой реабилитации: ${_lineService(hydra) ?? 'HydraPure'} или ${_lineService(massage) ?? 'скульптурный массаж'}; '
          'при запасе по силам — инфузия ${_lineInfusion(glow) ?? 'Beauty & Glow'}. Назовите дату — подстроим протокол.';
    }
    if (q.contains('носогуб') ||
        q.contains('носо губ') ||
        (q.contains('складк') && q.contains('губ'))) {
      return 'Носогубки: сначала ${_lineService(massage) ?? 'массаж'}/${_lineService(hydra) ?? 'уход'}; '
          'контурная пластика — только после осмотра, если объём действительно нужен. Запись на консультацию через «+».';
    }
    if (q.contains('черные точки') ||
        q.contains('комедон') ||
        q.contains('черн точки') ||
        (q.contains('точки') && q.contains('пор'))) {
      return 'Комедоны: не выдавливать агрессивно. В CULT — осмотр и ${_lineService(hydra) ?? 'HydraPure'} или ${_lineService(peel) ?? 'пилинг L3'} без пересушивания. '
          '«Чистка» / «пилинг» — для ориентира из прайса, либо «+» на запись.';
    }
    if (q.contains('ультразвук') ||
        q.contains('узи чист') ||
        q.contains('ультразвуков')) {
      return 'УЗ-чистка — мягкий уход; Ultherapy® в аппаратном блоке CULT — уже SMAS-лифтинг другой силы и цены. '
          'Нужно очищение или лифтинг? От этого зависит ветка записи.';
    }
    if (q.contains('устал') ||
        q.contains('нет сил') ||
        q.contains('энерг') ||
        q.contains('выгоран') ||
        q.contains('иммун')) {
      return 'Силы в CULT — через инфузии: ${_lineInfusion(nad) ?? 'NAD+ Energy'}, '
          '${_lineInfusion(immunity) ?? 'Immunity Boost'}, ${_lineInfusion(glow) ?? 'Beauty & Glow'}. '
          'Могу сравнить три или сразу помочь с записью на капельницу.';
    }
    if (q.contains('сон') || q.contains('не высып') || q.contains('бессон')) {
      return 'Сон клиника не заменяет, но поддерживает: мягкий уход от отёка и при необходимости ${_lineInfusion(nad) ?? 'NAD+'} / шоп (например Mitochondrial Fuel). '
          'Скажите «шоп» или «инфузия» — сузим.';
    }
    if (q.contains('глаз') ||
        q.contains('темные круги') ||
        q.contains('темные круги') ||
        q.contains('синяк под')) {
      return 'Зона глаз: осмотр, затем ${_lineService(meso) ?? 'мезотерапия'} или щадящий уход — без агрессии. '
          'Больше отёк или тень? От этого зависит протокол.';
    }
    if (q.contains('шея') || q.contains('декольте')) {
      return 'Шея/декольте в CULT смотрим на консультации: плотность (иногда RF/уход) или домашний крем из шопа. '
          'Запишем осмотр через «+»?';
    }
    if (q.contains('похудеть') ||
        q.contains('жир на') ||
        q.contains('целлюлит') ||
        q.contains('живот')) {
      return 'Тело: эстетика CULT (в т.ч. BodyTite в аппаратной) дополняет режим, не заменяет его. '
          'Без обещаний «минус размеры за раз» — сначала консультация по зоне.';
    }
    if (q.contains('стресс') || q.contains('нервн') || q.contains('тревож')) {
      return 'Стресс по лицу: в прайсе спокойный вход — ${_lineService(massage) ?? 'массаж лица'} или уход без тяжёлой артиллерии. '
          'Можно сразу «+» к врачу, если хотите только осмотр и разговор.';
    }
    if (q.contains('выпаден') ||
        q.contains('волосы лезут') ||
        q.contains('алопец') ||
        q.contains('редеют волос') ||
        (q.contains('волос') &&
            (q.contains('реде') || q.contains('теря') || q.contains('густот')))) {
      return 'Выпадение: в CULT сначала осмотр и причина, затем обсуждаем ${_lineService(meso) ?? 'мезотерапию'} кожи головы — не «чудо-укол сразу». '
          'Запись на консультацию через «+».';
    }
    if (q.contains('растяж') || q.contains('стрии')) {
      return 'Растяжки ведём аккуратно и курсом: аппаратные и инъекционные протоколы подбирает врач после осмотра — без обещания «как не было». '
          'Могу записать на консультацию через «+».';
    }
    if (q.contains('детокс') || q.contains('очищен организм') || q.contains('вывести токсин')) {
      return '«Детокс» в клинике — скорее про поддержку: инфузии, режим и кожа, а не про чудо за час. '
          'Могу сравнить капельницы или предложить мягкий уход. Что важнее — энергия или кожа?';
    }
    if (q.contains('ретинол') ||
        (q.contains('кислот') && q.contains('дом'))) {
      return 'Ретинол и кислоты дома — только если барьер в порядке и нет острого воспаления; после клиники врач скажет паузу. '
          'Если кожа уже жжёт или шелушится — сначала барьерный крем, активы отложим. Скажите «крем» или опишите реакцию.';
    }
    if (q.contains('когда результат') ||
        q.contains('когда эффект') ||
        q.contains('когда будет видно') ||
        q.contains('как скоро эффект')) {
      return 'Сроки разные: массаж и уход часто дают свежесть сразу; курс RF и инъекций — нарастающе, по схеме врача. '
          'Назовите процедуру из нашего разговора или прайса — ориентирую реалистично, без сказки.';
    }
    if (q.contains('чувствительн') ||
        q.contains('красне') ||
        q.contains('жжет') ||
        q.contains('жжет') ||
        q.contains('щипл')) {
      return 'Чувствительность — сигнал снизить агрессию: сначала барьер и мягкий уход, аппаратные и кислоты — только после осмотра. '
          'Могу подсказать барьерный крем из шопа или записать на спокойную консультацию.';
    }
    // Keep sun/sport/alcohol/fasting on the FAQ path.
    final aftercareToFaq = q.contains('алкогол') ||
        q.contains('солнц') ||
        q.contains('загар') ||
        q.contains('spf') ||
        q.contains('спорт') ||
        q.contains('бассейн') ||
        q.contains('саун') ||
        q.contains('хамам') ||
        q.contains('натощак');
    if (!aftercareToFaq &&
        (q.contains('после процедур') ||
            q.contains('после укол') ||
            q.contains('после инъек') ||
            q.contains('после пилинг') ||
            q.contains('после массаж') ||
            q.contains('что нельзя после') ||
            q.contains('как ухаживать после'))) {
      return 'После процедуры обычно бережём кожу: без жёстких активов и сауны, пока врач не разрешит; точную схему дадут в чате или на визите. '
          'Если есть жжение, сильный отёк или боль — опишите зону и дату визита врачу в чате специалиста.';
    }
    if (q.contains('хочу красиво') ||
        q.contains('хочу лучше') ||
        q.contains('просто улучшить') ||
        q.contains('навести порядок') ||
        q.contains('привести себя')) {
      return 'Давайте без хаоса: один спокойный шаг. Чаще начинают с осмотра или массажа/ухода, дома — барьер. '
          'Скажите, что важнее в зеркале или по самочувствию — сузим.';
    }
    return null;
  }

  String? _faqReply(String q) {
    if (q.contains('отмен') || q.contains('перенес') || q.contains('перенос')) {
      return 'Без стресса: отменить или перенести визит можно в профиле → «Мои записи» или через чат администратора. '
          'Чем раньше напишете, тем проще подобрать новое окно.';
    }
    if (q.contains('опозда') ||
        q.contains('опаздыв') ||
        q.contains('задерж') ||
        q.contains('не успева')) {
      return 'Если опаздываете — напишите администратору в чат с запасом 10–15 минут. Слот могут сдвинуть или предложить ближайшее окно.';
    }
    if (q.contains('запис')) {
      return 'Записаться просто: откройте «Запись» в меню или нажмите «+» на главной — подберём услугу, врача и время. '
          'Можно сказать голосом название процедуры, я подскажу следующий шаг.';
    }
    if (q.contains('доставк') ||
        q.contains('курьер') ||
        q.contains('магазин') ||
        q.contains('шоп') ||
        q.contains('биохакинг')) {
      return 'Биохакинг-шоп — во вкладке «Магазин»: самовывоз на ресепшен или курьер при оформлении корзины. '
          'Спросите формулу голосом — спокойно подскажу цену, состав и наличие.';
    }
    if (q.contains('ии-подбор') ||
        q.contains('ии подбор') ||
        q.contains('ии помощник') ||
        q.contains('помощник') ||
        (q.contains('подбор') &&
            (q.contains('ии') || q.contains('формул') || q.contains('шоп')))) {
      return 'В магазине смотрите карточки ухода и БАДов. Здесь голосом можно спросить название, цену или состав — или откройте вкладку «Магазин».';
    }
    if (q.contains('микрофон') ||
        q.contains('голосом') ||
        q.contains('голосовой') ||
        q.contains('распознаван') ||
        RegExp(r'(^|\s)(голос|озвуч)').hasMatch(q)) {
      return 'Нажмите одну кнопку микрофона и говорите своими словами — например: «сколько стоит микроигольчатый RF» или «есть ли Mitochondrial Fuel». Клавиатура не нужна. '
          'Ответ могу проговорить вслух, как на спокойной консультации.';
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
    // Only generic catalog questions — not «на процедуру» / «длится процедура».
    if (RegExp(r'(^|\s)услуг').hasMatch(q) ||
        q.contains('каталог услуг') ||
        q.contains('что делаете') ||
        q.contains('чем занима')) {
      return 'В CULT Сочи собрали уходы и пилинги, массаж, инъекции, аппаратную (RF, IPL, SMAS), '
          'инфузии и лабораторию. Откройте «Услуги» или «Прайс» — или назовите процедуру голосом, отвечу ценой и мягким следующим шагом.';
    }
    if (q.contains('формул') &&
        !q.contains('сыворот') &&
        !q.contains('крем') &&
        !q.contains('serum') &&
        !q.contains('cream')) {
      return 'Формулы биохакинг-шопа — во вкладке «Магазин»: сыворотки, кремы, NAD+ и катализаторы. '
          'Спросите, например: «Veil Peptide» или «барьерный крем».';
    }
    if (q.contains('массаж') || q.contains('лимфодрен')) {
      return 'Массаж и лимфодренаж — один из самых спокойных стартов: меню «Услуги» и запись через «+». '
          'Спросите конкретное название — подскажу цену и длительность.';
    }
    if (q.contains('лазер') || q.contains('ipl') || q.contains('пигмент')) {
      return 'Лазер и IPL — в разделе «Аппаратная». Перед курсом врач спокойно оценит фототип и зону — без самодеятельности с отбеливанием. '
          'Могу сориентировать по направлению или помочь с записью на осмотр.';
    }
    if (q.contains('пилинг') || q.contains('чистка')) {
      return 'Пилинги и уходы — в меню «Услуги». Интенсивность подберём под сезон и тип кожи, чтобы не перегрузить барьер. '
          'Если скажете задачу кожи — сузим до одного протокола.';
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
      return 'CULT Сочи открыта ежедневно, включая выходные, с 9:00 до 21:00 — Черноморская, 6. '
          'Могу помочь записаться в удобное окно.';
    }
    if (q.contains('добр') ||
        q.contains('адрес') ||
        q.contains('ехать') ||
        q.contains('доехать') ||
        q.contains('находитесь') ||
        q.contains('находится') ||
        q.contains('где вы') ||
        q.contains('где клиник') ||
        q.contains('как найти')) {
      return 'Ждём вас в Сочи, Черноморская, 6. Если нужен трансфер — закажите в профиле, водитель напишет в чат.';
    }
    if (q.contains('меню на русском') ||
        q.contains('интерфейс на русском') ||
        q.contains('приложение на русском')) {
      return 'Приложение CULT на русском: запись, чат, прайс и шоп. Если что-то отображается иначе — перезапустите приложение или напишите администратору в чат.';
    }
    if ((q.contains('чек') && !q.contains('чекап') && !q.contains('чек-ап')) &&
        (q.contains('нужен') ||
            q.contains('выпиш') ||
            q.contains('кассов') ||
            q == 'чек')) {
      return 'Кассовый чек и закрывающие документы выдают на ресепшен после оплаты. Для юрлица напишите администратору в чат заранее.';
    }
    if (q.contains('крипт') ||
        q.contains('bitcoin') ||
        q.contains('btc') ||
        q.contains('usdt') ||
        q.contains('криптовалют')) {
      return 'Криптовалюту обычно не принимаем — оплата в рублях картой, наличными или бонусами CULT. Уточните на ресепшен, если появятся новые способы.';
    }
    if (q.contains('кэшбек') ||
        q.contains('кешбек') ||
        q.contains('cashback') ||
        q.contains('мили') ||
        q.contains('программа лояльн') ||
        q.contains('как потратить бонус') ||
        q.contains('сколько бонус')) {
      return 'Лояльность CULT: welcome-бонус 3 000 ₽ новым клиентам, начисление и списание — в профиле (до 30% чека бонусами на платине). '
          'Отдельного кэшбека милями банков обычно нет — детали у администратора.';
    }
    if (q.contains('корпоратив') ||
        q.contains('для сотрудник') ||
        q.contains('для офиса') ||
        q.contains('мастер-класс') ||
        q.contains('мастер класс') ||
        q.contains('день открытых') ||
        q.contains('экскурсия по клиник')) {
      return 'Корпоративы, мастер-классы и дни открытых дверей согласует администратор — напишите в чат задачу и число гостей. '
          'Сертификаты для команды тоже удобно оформить в профиле.';
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
      return 'Новым клиентам после входа по телефону — 3 000 ₽ welcome-бонус. Баланс смотрите в профиле; могу подсказать, куда удобнее применить.';
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
      return 'Актуальный прайс филиала — в меню «Прайс». Назовите услугу голосом — подскажу цену из каталога и мягкий следующий шаг к записи.';
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
    if (q.contains('беремен') ||
        q.contains('кормлен') ||
        q.contains('кормл') ||
        q.contains('грудным') ||
        q.contains('грудью')) {
      return 'При беременности и лактации часть процедур ограничена. Напишите срок врачу в чате — подскажем безопасный протокол.';
    }
    if ((q.contains('мезотерап') && q.contains('волос')) ||
        (q.contains('мезотерап') && q.contains('голов')) ||
        (q.contains('мезотерап') && q.contains('скальп'))) {
      return 'Мезотерапия кожи головы обсуждается на осмотре: показания, курс и паузы — индивидуально. '
          'Запись на консультацию через «+» или меню «Инъекции»; без оценки не обещаю густоту «за раз».';
    }
    if (q.contains('нитк') ||
        q.contains('тредлифт') ||
        q.contains('thread')) {
      return 'Нити и тредлифтинг — медицинский протокол после очной оценки овала и тканей. '
          'Запишитесь на консультацию через «+» или «Врачи» — без обещаний «лифтинг за один визит» до осмотра.';
    }
    if (q.contains('экзосом') || q.contains('exosome')) {
      return 'Экзосомы и подобные биопротоколы обсуждаем только на консультации: показания, сочетание с уходом и курс. '
          'Откройте «+» или чат врача — подберём, если направление вам подходит.';
    }
    if (q.contains('карбокси') || q.contains('озонотерап')) {
      return 'Карбокси- и озонотерапию назначают по показаниям на осмотре — не как универсальный «детокс». '
          'Запишитесь на консультацию через «+», расскажем, уместно ли в вашей задаче.';
    }
    if (q.contains('prp') ||
        q.contains('плазмолифт') ||
        q.contains('плазмотерап') ||
        q.contains('плазмой') ||
        q.contains('плазма') ||
        q == 'plasma') {
      return 'PRP и плазмотерапия — в контуре инъекционных протоколов после осмотра и анализов по назначению врача. '
          'Запись на консультацию через «+» или меню «Инъекции».';
    }
    if (q.contains('липолитик')) {
      return 'Липолитики рассматриваем точечно и только после оценки зоны — без обещаний «минус объём за сеанс». '
          'Консультация через «+» или «Инъекции».';
    }
    if (q.contains('apple pay') ||
        q.contains('google pay') ||
        q.contains('сбп') ||
        (q.contains('быстр') && q.contains('платеж'))) {
      return 'Оплата: карта, наличные, бонусы CULT; Apple Pay / Google Pay и СБП — если терминал на ресепшен принимает (уточнит администратор). '
          'В шопе можно смешать карту и до 30% бонусами.';
    }
    if (q.contains('информирован') ||
        q.contains('согласие на процедур') ||
        q.contains('договор на услуг')) {
      return 'Перед процедурой подписывают информированное согласие на ресепшен или у врача — это нормальный спокойный шаг. '
          'Вопросы по тексту можно задать специалисту до начала.';
    }
    if (q.contains('адлер') ||
        q.contains('красной полян') ||
        q.contains('красная поляна') ||
        q.contains('как добрать') ||
        q.contains('на каком транспорте')) {
      return 'Мы в Сочи, Черноморская, 6. Из Адлера и Красной Поляны удобнее такси или VIP-трансфер из профиля; парковка у входа. '
          'Точный маршрут подскажет администратор в чате.';
    }
    if (q.contains('питомц') ||
        q.contains('с собакой') ||
        q.contains('с котом') ||
        q.contains('животн')) {
      return 'С питомцами в процедурные зоны обычно нельзя — на ресепшен уточнят исключения. Лучше оставить питомца дома или с сопровождающим снаружи.';
    }
    if (q.contains('душ') || q.contains('переодеть') || q.contains('раздевалк')) {
      return 'Душ и переодевание — по протоколу и кабинету; детали скажет администратор при записи. На лицо лучше прийти без плотного макияжа.';
    }
    if (q.contains('коляск') ||
        q.contains('инвалид') ||
        q.contains('доступн сред') ||
        q.contains('пандус')) {
      return 'По доступной среде и входу с коляской лучше заранее написать администратору в чат — подскажут удобный путь и слот без спешки.';
    }
    if (q.contains('метро') || q.contains('остановк') || q.contains('автобус')) {
      return 'Ориентир — Черноморская, 6, Сочи; парковка у входа. Городской транспорт и такси — по навигатору; точную подсказку даст администратор в чате.';
    }
    if (q.contains('доллар') ||
        q.contains('евро') ||
        q.contains('валют') ||
        q.contains('валюта')) {
      return 'Оплата в клинике в рублях (карта / наличные / бонусы). Валюту на ресепшен обычно не принимаем — уточните у администратора при необходимости.';
    }
    if (q.contains('юрлиц') ||
        q.contains('для компании') ||
        q.contains('безнал для') ||
        q.contains('счет на оплат') ||
        q.contains('счет на оплат')) {
      return 'Оплату от юрлица и закрывающие документы оформляет администратор — напишите в чат реквизиты и услугу, подскажем порядок.';
    }
    if (q.contains('аппарат') || q.contains('rf') || q.contains('smas')) {
      return 'Аппаратная — в меню «Аппаратная»: RF, IPL и SMAS. Спросите название — отвечу ценой и длительностью; интенсивность всегда уточняем на консультации под вашу кожу.';
    }
    if (q.contains('инъек') || q.contains('филлер') || q.contains('ботокс')) {
      return 'Инъекции — в меню «Инъекции». Перед визитом врач спокойно уточнит показания на консультации — можно начать с осмотра без процедуры в тот же день.';
    }
    if (q.contains('инфуз') || q.contains('капель')) {
      return 'Инфузии — в меню «Инфузии»: NAD+ для энергии, Immunity для поддержки, Beauty & Glow для кожи. '
          'Могу коротко сравнить или помочь записаться через «+» на главной.';
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
      return 'Большинство аппаратных и инъекционных протоколов делаем с аппликационной анестезией, темп спокойный. '
          'Если есть аллергии — скажите на консультации заранее, подберём безопасный вариант.';
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
      return 'Консультацию удобно открыть через «+» на главной или в карточке врача. Первый визит часто начинается с осмотра — без давления «сделать всё сразу».';
    }
    if (q.contains('гематом') ||
        q.contains('синяк после') ||
        q.contains('синяки после')) {
      return 'Гематома и синяк после инъекций бывают; обычно спадают за несколько дней — холод по схеме врача, без разминания зоны. '
          'Если нарастает боль, температура или асимметрия — сразу напишите врачу в чат.';
    }
    if (q.contains('когда можно красить') ||
        q.contains('когда можно краситься') ||
        q.contains('макияж после') ||
        q.contains('краситься после')) {
      return 'Декоративный макияж на зону после инъекций и части аппаратных обычно откладывают минимум на сутки — точнее скажет врач по протоколу. '
          'На сам визит лучше без плотного тона.';
    }
    if (q.contains('самолет') ||
        q.contains('перелет') ||
        q.contains('лететь')) {
      return 'Перелёт после инъекций и части аппаратных лучше планировать с запасом — сроки скажет врач (часто сутки и больше). '
          'Напишите дату вылета в чат специалиста до записи.';
    }
    if (q.contains('кафе') ||
        q.contains('попить') ||
        (q.contains('воды') && q.contains('можно')) ||
        q.contains('есть ли вода')) {
      return 'Воду на ресепшен обычно предложат; полноценного кафе в клинике нет — ориентир на комфорт до/после визита. Спросите администратора на месте.';
    }
    if (q.contains('температура в кабинет') || q.contains('холодно в кабинет')) {
      return 'В кабинетах поддерживаем комфортную температуру; если зябко — скажите специалисту, дадут плед. На процедуру удобнее многослойная одежда.';
    }
    if (q.contains('подарочный набор') || q.contains('набор в подарок')) {
      return 'Подарочный набор удобно собрать из шопа или взять сертификат CULT в профиле — номинал на выбор. '
          'Могу подсказать мягкую пару «крем + сыворотка» или открыть «Купить сертификат».';
    }
    if (q.contains('очищен') ||
        q.contains('тоник') ||
        q.contains('мицелляр') ||
        q.contains('маска для') ||
        q.contains('патч')) {
      return 'Базовый дом: мягкое очищение, тоник по необходимости, маска/патчи — по задаче кожи; в шопе CULT сильнее заходят барьерный крем и пептидная сыворотка. '
          'Скажите «крем» или «сыворотка» — назову наличие и цену.';
    }
    if (q.contains('коллаген') ||
        q.contains('бад') ||
        q.contains('бад ') ||
        q.contains('нутрицевт') ||
        q.contains('витамин пить')) {
      return 'Коллаген и БАДы — поддержка, не замена протокола. В шопе смотрите формулы вроде Mitochondrial Fuel; назначение лучше согласовать с врачом. '
          'Спросите название из шопа — расскажу состав и наличие.';
    }
    if (q.contains('чек-ап') ||
        q.contains('чекап') ||
        q.contains('checkup') ||
        q.contains('генетическ') ||
        q.contains('гормоны анализ')) {
      return 'Чек-ап, гормоны и генетические панели обсуждают на консультации и через «Мои анализы» / запись на забор. '
          'Без осмотра не назначаю список сама — запишем врача через «+».';
    }
    if (q.contains('интим') || q.contains('интимно')) {
      return 'Интимные эстетические вопросы — только очно со специалистом, конфиденциально. Запись через «+» или чат врача; в общем чате детали можно не писать.';
    }
    if (q.contains('гипергидр') || q.contains('потливость') || q.contains('сильно поте')) {
      return 'Гипергидроз часто ведут ботулинотерапией после осмотра. Запишитесь на консультацию через «+» или «Инъекции» — оценим зону и показания.';
    }
    if (q.contains('келоид') ||
        (q.contains('рубец') && q.contains('операц'))) {
      return 'Келоиды и послеоперационные рубцы разбираем на осмотре — протокол под тип рубца, без универсального «сотрём». '
          'Консультация через «+».';
    }
    if (q.contains('тату') &&
        (q.contains('удал') || q.contains('свест') || q.contains('вывест'))) {
      return 'Сведение тату и перманента — отдельный протокол (часто лазер) после оценки цвета и кожи. '
          'Запись на консультацию в «Аппаратную» или через «+».';
    }
    if (q.contains('по фото') ||
        q.contains('скину фото') ||
        q.contains('фото скаж') ||
        q.contains('по снимк')) {
      return 'По фото могу лишь мягко сориентировать, диагноз и протокол — только очно. '
          'Лучше запись на осмотр через «+» или отправить фото врачу в чат «Специалист».';
    }
    if (q.contains('конфиденциальн') ||
        q.contains('тайна') ||
        q.contains('не разглаш') ||
        (q.contains('фото') && q.contains('процедур') && q.contains('можно'))) {
      return 'Конфиденциальность соблюдаем: фото и кейсы — только с вашего согласия. '
          'Съёмку процедуры и публикации можно запретить — скажите на ресепшен или врачу до начала.';
    }
    if (q.contains('врач женщина') ||
        q.contains('женщина специалист') ||
        q.contains('только женщина') ||
        q.contains('врач мужчина') ||
        q.contains('мужчина специалист')) {
      return 'Пол специалиста можно выбрать в меню «Врачи» или попросить администратора в чате подобрать окно. '
          'Назовите задачу кожи — подскажу, чей профиль ближе.';
    }
    if (q.contains('астм') ||
        q.contains('диабет') ||
        q.contains('эпилепс') ||
        q.contains('онколог') ||
        (q.contains('давлен') &&
            (q.contains('высок') || q.contains('гипертон'))) ||
        q.contains('гипертония')) {
      return 'Хронические состояния обязательно скажите врачу до процедуры — часть протоколов ограничивают или готовят иначе. '
          'Напишите в чат специалиста или отметьте на консультации; я не заменяю допуск врача.';
    }
    if (q.contains('герпес') ||
        q.contains('простуда на губ') ||
        q.contains('простыл') ||
        q.contains('орви') ||
        q.contains('температура у меня')) {
      return 'При герпесе, простуде или температуре визит обычно переносят — так безопаснее для вас и заживления. '
          'Напишите администратору в чат: перенесём окно без стресса.';
    }
    if (q.contains('месячн') ||
        q.contains('цикл влия') ||
        q.contains('критическ дни')) {
      return 'Цикл иногда учитывают при отёчности и чувствительности; жёсткого запрета на все процедуры нет — решает врач по протоколу. '
          'Если сильный дискомфорт в эти дни — лучше выбрать другую дату.';
    }
    if (q.contains('имплант') ||
        q.contains('филлеры уже') ||
        q.contains('филлер уже') ||
        q.contains('ботокс был') ||
        q.contains('уже кололи')) {
      return 'Предыдущие филлеры, ботулотоксин и импланты важно назвать на осмотре — от этого зависят техника и сроки. '
          'Запись на консультацию через «+»; можете коротко перечислить, что и когда делали.';
    }
    if (q.contains('стоматолог') ||
        q.contains('чистки зуб') ||
        q.contains('чистка зуб')) {
      return 'Со стоматологией лучше развести по времени: после инъекций в лицо и части аппаратных — пауза, чтобы не смещать ткани и не усиливать отёк. '
          'Точный интервал скажет врач по вашей дате.';
    }
    if (q.contains('курю') || q.contains('курен') || q.contains('никотин')) {
      return 'Курение замедляет заживление и ухудшает тон кожи — на результате протоколов это заметно. '
          'Не запрет на визит, но врач учтёт это в ожиданиях. Можем подобрать более мягкий вход.';
    }
    if (q.contains('веган') || q.contains('без запаха') || q.contains('без аромат')) {
      return 'Предпочтения по составу и аромату учтём на консультации и в шопе — скажите «без отдушки» или «веган», подберём из доступных формул. '
          'Спросите «крем» — назову варианты с ценой.';
    }
    if (q.contains('линз') ||
        q.contains('ношу линзы') ||
        q.contains('чувствительн глаз')) {
      return 'При линзах и чувствительных глазах зону вокруг глаз ведём осторожно; иногда линзы снимают на процедуру. '
          'Предупредите врача на осмотре — подстроим протокол.';
    }
    if (q.contains('spf') ||
        q.contains('солнцезащит') ||
        q.contains('санскрин')) {
      return 'SPF после большинства протоколов обязателен; в повседневности — тоже база. '
          'Формулу подберём на консультации или в шопе; пока скажите задачу кожи — сузим уход.';
    }
    // Avoid false hits like «помолодеть» / «долголетие» on bare «дет».
    if (q.contains('детск') ||
        q.contains('детям') ||
        q.contains('ребен') ||
        q.contains('несовершеннолет') ||
        q.contains('подрост') ||
        RegExp(r'(^|[^а-яa-z])дети([^а-яa-z]|$)').hasMatch(q) ||
        RegExp(r'(^|[^а-яa-z])дитя([^а-яa-z]|$)').hasMatch(q) ||
        RegExp(r'(^|[^а-яa-z])для\s+дет').hasMatch(q)) {
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
    var bodyHits = 0;
    for (final token in tokens) {
      if (token.length < 3) continue;
      if (titleNorm.contains(token)) {
        titleHits++;
        // Short brand tokens (veil, nad) still count as real title hits.
        score += token.length >= 6 ? 8 : 6;
        continue;
      }
      // Blurb/composition matches: Russian type words often live only in body.
      if (token.length >= 4 && hay.contains(token)) {
        bodyHits++;
        score += token.length >= 6 ? 4 : 3;
      }
    }
    final phrase = tokens.where((t) => t.length >= 3).join(' ');
    if (phrase.length >= 6 && titleNorm.contains(phrase)) score += 10;
    // Title hit preferred; strong body-only (e.g. «сыворотка», «барьерный крем») OK.
    if (titleHits == 0 && bodyHits == 0) return 0;
    if (titleHits == 0 && score < 5) return 0;
    return score;
  }

  List<String> _tokens(String q) {
    final raw = q
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
            'лицо',
            'лица',
            'кожа',
            'кожи',
          }.contains(t),
        )
        .toList();
    return _expandSynonyms(raw);
  }

  /// RU/EN catalog synonyms so voice queries hit English titles.
  List<String> _expandSynonyms(List<String> tokens) {
    const pairs = <String, List<String>>{
      'сыворотка': ['serum', 'сыворот'],
      'сыворотки': ['serum', 'сыворот'],
      'сывороткой': ['serum', 'сыворот'],
      'сыворотк': ['serum'],
      'serum': ['сыворот', 'сыворотка'],
      'крем': ['cream'],
      'крема': ['cream'],
      'кремом': ['cream'],
      'cream': ['крем'],
      'пептид': ['peptide'],
      'пептиды': ['peptide'],
      'пептидн': ['peptide'],
      'peptide': ['пептид'],
      'барьерный': ['barrier', 'барьер'],
      'барьерная': ['barrier', 'барьер'],
      'барьер': ['barrier'],
      'barrier': ['барьер'],
      'митохондриальн': ['mitochondrial'],
      'митохондри': ['mitochondrial'],
      'mitochondrial': ['митохондри'],
      'липосомальн': ['liposomal'],
      'liposomal': ['липосомальн'],
      'глутатион': ['gluta'],
      'патч': ['patch'],
      'патчи': ['patch'],
      'капельниц': ['infusion', 'инфуз'],
      'капельница': ['infusion', 'инфуз'],
      'инфузия': ['infusion', 'инфуз'],
      'инфузии': ['infusion', 'инфуз'],
    };
    final out = <String>[...tokens];
    for (final t in tokens) {
      final extra = pairs[t];
      if (extra != null) {
        out.addAll(extra);
        continue;
      }
      for (final entry in pairs.entries) {
        if (t.startsWith(entry.key) || entry.key.startsWith(t)) {
          out.addAll(entry.value);
        }
      }
    }
    return out.toSet().toList();
  }

  /// Avoid repeating clarifying questions when the user didn't advance the topic.
  String _dedupeClarify(String reply, String? lastBot, {String user = ''}) {
    if (lastBot == null || lastBot.trim().isEmpty) return reply;
    final prev = _normalize(lastBot);
    final next = _normalize(reply);
    final u = _normalize(user);
    const markers = <String>[
      'лицо или тело',
      'лицо, тело, энергия',
      'лицо, тело или про силы',
      'что видите в зеркале',
      'что заметнее',
      'одного ориентира достаточно',
      'одного намёка',
      'хватит одного',
      'слышу вас — давайте сузим',
      'давайте ближе к вам',
      'сузим мягко',
      'скажите зону',
      'назовите зону',
      'с чего начнём',
      'с чего начнем',
      'с чего удобнее',
      'больше про лицо, тело или про силы',
      'как выглядит кожа или как вы себя чувствуете',
      'зона, ощущение или визит',
    ];
    var sameHits = 0;
    for (final m in markers) {
      if (prev.contains(m) && next.contains(m)) sameHits++;
    }
    if (sameHits > 0) {
      return _pick('dedupe-same', const [
        'Без повтора. Дальше по делу: сухость → HydraPure / Lumen Barrier; овал → массаж или RF; силы → NAD+; либо «запись» через «+».',
        'Без повтора того же вопроса. Якорь — сухость, овал, усталость или сразу запись — и двинемся.',
        'Без повтора. Один ориентир из прайса CULT или симптом — подберу следующий шаг.',
      ], '$user|$reply');
    }

    // Soft loop: last turn asked to narrow, this turn asks again, user said almost nothing.
    final vagueUser = u.isEmpty ||
        u.length <= 2 ||
        const {
          'ну',
          'нуу',
          'хм',
          'эм',
          'мм',
          'а',
          'и',
          'угу',
          'ага',
          'хз',
          'не знаю',
          'ладно',
        }.contains(u);
    final prevHit = markers.any(prev.contains);
    // Vague «ну/хм» after a clarify ask: jump to catalog anchors, don't re-ask.
    if (vagueUser && prevHit) {
      return _pick('dedupe-vague', const [
        'Без повтора. Назовите услугу из прайса (массаж, RF, пилинг, инфузия) или симптом — сухость, овал, прыщи, усталость.',
        'Без повтора — проще: одно слово «сухость», «овал», «устала» или «запись», и я уже с конкретикой.',
        'Без повтора. Массаж, RF, пилинг, инфузия или что видите в зеркале — одним словом.',
      ], '$user|$reply');
    }
    return reply;
  }

  /// Stable pick among variants so replies don't sound copy-pasted.
  String _pick(String key, List<String> variants, String seed) {
    if (variants.isEmpty) return '';
    if (variants.length == 1) return variants.first;
    final h = Object.hash(key, seed);
    final i = h.abs() % variants.length;
    return variants[i];
  }

  /// Soften canned openers; keep clinic facts intact.
  String _naturalize(
    String reply, {
    required String seed,
    String? lastBot,
  }) {
    var out = reply.trim();
    if (out.isEmpty) return out;

    // Drop stacked identical CTA tails when we already said them last turn.
    if (lastBot != null && lastBot.isNotEmpty) {
      final prev = _normalize(lastBot);
      if (prev.contains('через «+»') &&
          _normalize(out).contains('через «+»') &&
          out.split(RegExp(r'[.!?]')).length > 2) {
        out = out
            .replaceAll(
              RegExp(
                r'\s*Запись через «\+»[^.?!]*[.?!]',
                caseSensitive: false,
              ),
              '',
            )
            .replaceAll(
              RegExp(
                r'\s*Запишем через «\+»[^.?!]*[.?!]',
                caseSensitive: false,
              ),
              '',
            )
            .trim();
      }
    }

    if (RegExp(r'Скажите «[^»]+».{0,40}Скажите «').hasMatch(out)) {
      out = out.replaceFirst('Скажите «', 'Можно «');
    }

    // Vary a few overused robotic openers so replies don't sound copy-pasted.
    final swaps = <String, List<String>>{
      'Слышу вас —': ['Поняла вас —', 'Услышала —', 'Хорошо, '],
      'Слышу вас.': ['Поняла. ', 'Услышала. ', 'Хорошо. '],
      'В CULT без угадываний:': [
        'Давайте без угадываний: ',
        'Опираясь на прайс: ',
        'Спокойно и по делу: ',
      ],
      'Слышу про': ['Понимаю про', 'Учту', 'Беру в расчёт'],
      'Отлично, остаёмся': [
        'Хорошо, остаёмся',
        'Договорились, остаёмся',
        'Ок, держим',
      ],
      'Понимаю:': ['Вижу: ', 'Учитываю: ', 'Да, '],
      'Коротко по трём:': [
        'Если коротко про три: ',
        'По трём: ',
        'Сразу про три: ',
      ],
      'Без повтора того же вопроса.': [
        'Без повтора. ',
        'Не буду крутить то же. ',
        'Ок, дальше по делу. ',
      ],
    };
    for (final entry in swaps.entries) {
      if (out.startsWith(entry.key)) {
        final alt = _pick('nat-${entry.key}', entry.value, seed);
        out = '$alt${out.substring(entry.key.length)}';
        break;
      }
    }

    // Soften doubled identical sentence openers inside one reply.
    out = out.replaceAll('Скажите, скажите', 'Скажите');
    out = out.replaceAll('Скажите Скажите', 'Скажите');
    out = out.replaceAll(' в CULT обычно ', ' у нас обычно ');

    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Service? _clinicService(String needle, {ClientGender? gender}) {
    final n = _normalize(needle);
    for (final item in services) {
      if (gender != null && !item.audience.matches(gender)) continue;
      final hay = _normalize('${item.title} ${item.slug} ${item.blurb}');
      if (hay.contains(n)) return item;
    }
    for (final item in services) {
      final hay = _normalize('${item.title} ${item.slug}');
      if (hay.contains(n)) return item;
    }
    return null;
  }

  Product? _clinicProduct(String needle) {
    final n = _normalize(needle);
    for (final item in products) {
      if (_normalize('${item.name} ${item.blurb}').contains(n)) return item;
    }
    return null;
  }

  Infusion? _clinicInfusion(String needle) {
    final n = _normalize(needle);
    for (final item in infusions) {
      if (_normalize('${item.title} ${item.blurb} ${item.chip}').contains(n)) {
        return item;
      }
    }
    return null;
  }

  String? _lineService(Service? item) {
    if (item == null) return null;
    return '«${item.title}» (${item.priceLabel}, ${item.duration})';
  }

  String? _lineProduct(Product? item) {
    if (item == null) return null;
    return '«${item.name}» (${_rub(item.price)})';
  }

  String? _lineInfusion(Infusion? item) {
    if (item == null) return null;
    return '«${item.title}» (${item.price})';
  }

  /// Push-style catalog cards from the latest reply + user topic.
  List<AgentOffer> suggestOffers(
    String reply, {
    String? lastUser,
    List<Service> localServices = services,
    List<Product> localProducts = products,
    List<Infusion> localInfusions = infusions,
    ClientGender? gender,
  }) {
    final blob = _normalize('$reply ${lastUser ?? ''}');
    final offers = <AgentOffer>[];
    final seen = <String>{};

    void add(AgentOffer offer) {
      final key = _normalize(offer.title);
      if (seen.contains(key) || offers.length >= 3) return;
      seen.add(key);
      offers.add(offer);
    }

    for (final item in localServices) {
      if (gender != null && !item.audience.matches(gender)) continue;
      final title = _normalize(item.title);
      final hay = _normalize('${item.title} ${item.blurb} ${item.category}');
      var score = 0;
      for (final token in _tokens(blob)) {
        if (token.length < 4) continue;
        if (title.contains(token)) score += 6;
        else if (hay.contains(token)) score += 3;
      }
      if (blob.contains('массаж') && title.contains('массаж')) score += 8;
      if (blob.contains('rf') && title.contains('rf')) score += 8;
      if (blob.contains('уход') && title.contains('уход')) score += 5;
      if (score < 6) continue;
      add(
        AgentOffer(
          title: item.title,
          subtitle: item.blurb,
          priceLabel: item.priceLabel,
          kind: 'service',
          ask: item.title,
        ),
      );
    }

    for (final item in localProducts) {
      final title = _normalize(item.name);
      final hay = _normalize('${item.name} ${item.blurb} ${item.composition}');
      var score = 0;
      for (final token in _tokens(blob)) {
        if (token.length < 4) continue;
        if (title.contains(token)) score += 6;
        else if (hay.contains(token)) score += 3;
      }
      if (blob.contains('крем') && (title.contains('cream') || hay.contains('крем'))) {
        score += 7;
      }
      if (blob.contains('сыворот') && title.contains('serum')) score += 7;
      if (score < 6) continue;
      add(
        AgentOffer(
          title: item.name,
          subtitle: item.blurb,
          priceLabel: _rub(item.price),
          kind: 'product',
          ask: item.name,
        ),
      );
    }

    for (final item in localInfusions) {
      final title = _normalize(item.title);
      var score = 0;
      if (blob.contains('инфуз') || blob.contains('капель') || blob.contains('энерг')) {
        score += 4;
      }
      if (blob.contains('nad') && title.contains('nad')) score += 8;
      if (blob.contains('glow') && title.contains('glow')) score += 8;
      if (blob.contains('immunity') && title.contains('immunity')) score += 8;
      if (score < 6) continue;
      add(
        AgentOffer(
          title: item.title,
          subtitle: item.blurb,
          priceLabel: item.price,
          kind: 'infusion',
          ask: item.title,
        ),
      );
    }

    if (offers.isEmpty) {
      // Soft defaults so the push rail is never empty after a real turn.
      if (blob.contains('энерг') || blob.contains('устал') || blob.contains('инфуз')) {
        final drip = localInfusions.isNotEmpty ? localInfusions.first : null;
        if (drip != null) {
          add(
            AgentOffer(
              title: drip.title,
              subtitle: drip.blurb,
              priceLabel: drip.price,
              kind: 'infusion',
              ask: drip.title,
            ),
          );
        }
      } else if (blob.contains('сух') || blob.contains('барьер') || blob.contains('крем')) {
        for (final item in localProducts) {
          if (_normalize(item.name).contains('barrier') ||
              _normalize(item.blurb).contains('барьер')) {
            add(
              AgentOffer(
                title: item.name,
                subtitle: item.blurb,
                priceLabel: _rub(item.price),
                kind: 'product',
                ask: item.name,
              ),
            );
            break;
          }
        }
      } else {
        for (final item in localServices) {
          if (gender != null && !item.audience.matches(gender)) continue;
          if (_normalize(item.title).contains('массаж')) {
            add(
              AgentOffer(
                title: item.title,
                subtitle: item.blurb,
                priceLabel: item.priceLabel,
                kind: 'service',
                ask: item.title,
              ),
            );
            break;
          }
        }
      }
    }
    return offers;
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

/// Pending visit collected by Мира — applied only after the user taps «Запись».
class AgentBookingDraft {
  const AgentBookingDraft({
    required this.service,
    required this.doctor,
    required this.date,
    required this.time,
    required this.summary,
  });

  final String service;
  final String doctor;
  final String date;
  final String time;
  final String summary;
}

class AgentTurn {
  const AgentTurn({required this.reply, this.pendingBooking});

  final String reply;
  final AgentBookingDraft? pendingBooking;
}

/// Display name of the on-device cosmetologist agent.
const cultAgentName = 'Мира';

/// Catalog card helper (kept for tests; voice UI no longer pushes suggestions).
class AgentOffer {
  const AgentOffer({
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    required this.kind,
    required this.ask,
  });

  final String title;
  final String subtitle;
  final String priceLabel;
  final String kind;
  final String ask;
}

const cultAgent = CultAgent();
