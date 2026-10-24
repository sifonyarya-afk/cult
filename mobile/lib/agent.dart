import 'data.dart';
import 'yclients.dart';

/// On-device CULT cosmetologist [cultAgentName]: FAQ + services/shop + real actions.
/// Voice UI speaks [AgentTurn.reply]; booking confirms via «Запись»;
/// cart/transfer/handoff apply through [ClinicStore] after each turn.
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

  /// Full turn: living reply + booking draft / cart / transfer / open chat.
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
    final seed = '$text|${lastBot ?? ''}|${lastUser ?? ''}';

    AgentTurn wrap(
      String raw, {
      AgentBookingDraft? pendingBooking,
      AgentCartAdd? cartAdd,
      AgentTransferRequest? transfer,
      String? openChat,
    }) {
      return AgentTurn(
        reply: _naturalize(
          _dedupeClarify(raw, lastBot, user: text),
          seed: seed,
          lastBot: lastBot,
        ),
        pendingBooking: pendingBooking,
        cartAdd: cartAdd,
        transfer: transfer,
        openChat: openChat,
      );
    }

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
      return wrap(book.reply, pendingBooking: book.draft);
    }

    final cart = _cartFlow(
      q,
      raw: text,
      lastBot: lastBot,
      lastUser: lastUser,
      recentUsers: recentUsers,
      localProducts: localProducts,
    );
    if (cart != null) {
      return wrap(cart.reply, cartAdd: cart.add);
    }

    final transfer = _transferFlow(
      q,
      raw: text,
      lastBot: lastBot,
      lastUser: lastUser,
    );
    if (transfer != null) {
      return wrap(transfer.reply, transfer: transfer.request);
    }

    final handoff = _handoffTurn(q, raw: text);
    if (handoff != null) {
      return wrap(handoff.reply, openChat: handoff.openChat);
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
    return wrap(raw);
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
        'Я рядом. Расскажите, что с кожей или самочувствием — своими словами, как удобно.',
        'Слушаю. Можно с того, что видно в зеркале, или с усталости — а я уже предложу, что у нас есть.',
        'Давайте с главного: лицо, тело или силы? Подберу спокойный вариант из наших услуг и шопа.',
      ], text);
    }

    if (RegExp(r'^[.…\-\s]+$').hasMatch(q) || q == 'мм' || q == 'эм' || q == 'хм') {
      return _pick('filler', const [
        'Пауза нормальна. Можно одно слово — сухость, овал, прыщи, усталость — и я уже в теме.',
        'Ничего страшного. Кожа, силы или массаж — с любого края зайдём.',
        'Я подожду. Без названий тоже можно: что беспокоит на ощупь или в зеркале.',
      ], text);
    }

    // Small talk first — greetings, name, mood — before booking/catalog stealers.
    final chatEarly = _chatReply(q, lastBot: lastBot, gender: gender);
    if (chatEarly != null) return chatEarly;

    // Focused clinical Q&A the generic FAQ/catalog otherwise mishandles.
    final taught = _teachReply(q, gender: gender);
    if (taught != null) return taught;

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

    // Cart / handoff / transfer / booking are handled in [respond] (real actions).

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
        'Много всего сразу — давайте выберем одно: лицо, тело, силы или дата. От этого уже подскажу, что делать.',
        'Слышу много нюансов. Хватит одного якоря — сухость, овал, усталость или запись — и разложу спокойно.',
        'Чтобы не размазать совет: что сейчас главнее — зеркало, самочувствие или визит?',
      ], text);
    }
    return _pick('fallback-soft', const [
      'Не уверена, что попала в точку. Расскажите своими словами — кожа, самочувствие или запись? Я подстроюсь.',
      'Давайте проще: что сейчас важнее — освежить лицо, набрать сил или записаться?',
      'Я рядом. Можно одно слово: сухость, морщинки, усталость, массаж — и уже пойду дальше.',
      'Если сложно сформулировать — опишите, что видно в зеркале или что чувствуете. Остальное доберём вместе.',
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
    // «перелёт» / «перелета» contains «лет» — don't treat as summer.
    if ((RegExp(r'(^|[^а-я])лет(ом|о|а|у)?([^а-я]|$)').hasMatch(q) ||
            q.contains('жар')) &&
        !q.contains('перелет') &&
        !q.contains('самолет') &&
        (q.contains('кожа') ||
            q.contains('лиц') ||
            q.contains('пигмент') ||
            q.contains('солнц') ||
            q.contains('что делать'))) {
      return 'Летом бережём тон и пигмент: SPF, аккуратный уход, агрессивные протоколы — только после оценки фототипа. '
          'Если уже есть пятна — лучше осмотр, а не самостоятельное отбеливание.';
    }
    if ((q.contains('мужчин') ||
            q.contains('для муж') ||
            q.contains('мужск') ||
            q.contains('барбер') ||
            // «борода», but not «подбородок».
            RegExp(r'(^|[^а-я])бород(а|ы|е|ой|у)([^а-я]|$)').hasMatch(q)) &&
        !q.contains('ботокс') &&
        !q.contains('ботулин') &&
        !q.contains('филлер') &&
        !q.contains('скольк') &&
        !q.contains('стоит') &&
        !q.contains('цен')) {
      if (q.contains('без блеск') || q.contains('не блесте') || q.contains('матовый')) {
        return 'Для мужчины без блеска: барбер-массаж или мужской уход с матовым финишем, дома — простой барьер без «розового» сияния; RF по овалу после осмотра. '
            'Запишем барбер-массаж или консультацию?';
      }
      return gender == ClientGender.man ||
              gender == null ||
              q.contains('для муж') ||
              q.contains('мужчине') ||
              q.contains('мужчинам')
          ? 'Для мужчин обычно спокойный вход: барбер-массаж, уход без «лишнего блеска», при необходимости RF по овалу. '
              'Что важнее — свежий вид или плотность?'
          : 'Могу сориентировать и по мужским протоколам: массаж, уход, RF без перегруза. Кому подбираем — вам или в подарок?';
    }
    if (q.contains('стрижк') ||
        q.contains('маникюр') ||
        q.contains('педикюр') ||
        q.contains('ресниц') ||
        (q.contains('бров') &&
            !q.contains('перманент') &&
            !q.contains('ботокс') &&
            !q.contains('ботулин') &&
            !q.contains('пирсинг') &&
            !q.contains('инъек') &&
            !q.contains('укол'))) {
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
        q.contains('забронируй') ||
        q.contains('забронировать') ||
        q.contains('оформи запись') ||
        q.contains('оформить запись') ||
        q.contains('давай запишемся') ||
        q.contains('давайте запишемся') ||
        q.contains('хочу записаться') ||
        q.contains('можно записаться') ||
        q.contains('можно ли записаться') ||
        q.contains('записаться на') ||
        q.contains('хочу на процедуру') ||
        q.contains('запишемся') ||
        q.contains('на запись') ||
        q.contains('запиши меня') ||
        (q.contains('хочу на') &&
            !q.contains('набор') &&
            (q.contains('массаж') ||
                q.contains('rf') ||
                q.contains('уход') ||
                q.contains('пилинг') ||
                q.contains('инфуз') ||
                q.contains('капель') ||
                q.contains('nad') ||
                q.contains('консульт') ||
                q.contains('чистка') ||
                q.contains('лазер') ||
                q.contains('ботокс') ||
                q.contains('мезо')));
    final slotOnly = _extractTimeLabel(q) != null ||
        _extractWeekday(q) != null ||
        q.contains('завтра') ||
        q.contains('послезавтра') ||
        q.contains('сегодня');
    if (!wants && !(continuing && (slotOnly || awaitingService || awaitingConfirm))) {
      return null;
    }

    // «записаться на двоих» without a named service — not a single-slot draft.
    final pairBook = q.contains('двоих') ||
        q.contains('вдвоём') ||
        q.contains('вдвоем') ||
        q.contains('с подруг') ||
        q.contains('с мужем') ||
        q.contains('с женой');
    final pairHasService = q.contains('массаж') ||
        q.contains('пилинг') ||
        q.contains('rf') ||
        q.contains('рф') ||
        q.contains('ipl') ||
        q.contains('капель') ||
        q.contains('nad') ||
        q.contains('ботокс') ||
        q.contains('hydrapure') ||
        q.contains('чистк') ||
        q.contains('smas') ||
        q.contains('уход');
    if (pairBook && !pairHasService && !continuing) {
      return (
        reply:
            'Вдвоём удобно: соседние окна или один за другим — администратор поможет через чат. '
            'Скажите процедуру и день, соберём два слота на подтверждение кнопкой «Запись».',
        draft: null,
      );
    }

    // «на имя подруги / гостя» — admin owns guest booking, not a self-slot draft.
    if (!continuing &&
        (q.contains('на имя') || q.contains('на другого') || q.contains('за подруг') || q.contains('за друга')) &&
        (q.contains('подруг') ||
            q.contains('друг') ||
            q.contains('гост') ||
            q.contains('маму') ||
            q.contains('мужа') ||
            q.contains('жену'))) {
      return (
        reply:
            'Запись на имя подруги или другого гостя удобнее через администратора в чате — паспортные данные и согласие на ресепшен. '
            'Могу открыть чат админа или собрать вашу собственную запись кнопкой «Запись».',
        draft: null,
      );
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
        .replaceAll('можно ли записаться на', ' ')
        .replaceAll('можно записаться на', ' ')
        .replaceAll('хочу записаться на', ' ')
        .replaceAll('хочу записаться', ' ')
        .replaceAll('запиши меня на', ' ')
        .replaceAll('запиши на', ' ')
        .replaceAll('записать меня на', ' ')
        .replaceAll('запишите на', ' ')
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
      'на понедельник',
      'на вторник',
      'на среду',
      'на четверг',
      'на пятницу',
      'на субботу',
      'на воскресенье',
      'на выходных',
      'в выходные',
      'пожалуйста',
      'можно ли',
      'уже собранной',
      'уже собранную',
    ]) {
      rest = rest.replaceAll(noise, ' ');
    }
    rest = rest.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Short device/infusion aliases after stripping slot words.
    final restN = _normalize(rest);
    if (restN.contains('ipl') ||
        restN.contains('айпи') ||
        restN.contains('lumecca') ||
        restN.contains('фотоомолож')) {
      return 'Lumecca IPL';
    }
    if (restN.contains('smas') ||
        restN.contains('смас') ||
        restN.contains('ultherap')) {
      return 'Ultherapy®';
    }
    if (restN == 'rf' ||
        restN == 'рф' ||
        restN.contains('микроиголь')) {
      return 'Микроигольчатый RF';
    }
    if (restN.contains('лимфодрен')) {
      return 'Лимфодренажный массаж';
    }
    if (restN.contains('барбер')) {
      return 'Барбер-массаж';
    }
    if (restN.contains('nad') || restN.contains('над+')) {
      return 'NAD+ Energy';
    }
    if (restN.contains('beauty') && restN.contains('glow')) {
      return 'Beauty & Glow';
    }
    if (restN.contains('immunity') || restN.contains('иммунит')) {
      return 'Immunity Boost';
    }

    if (rest.length >= 3) {
      final direct = _clinicService(rest, gender: gender);
      if (direct != null) return direct.title;
      final directInf = _clinicInfusion(rest);
      if (directInf != null) return directInf.title;

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
        // Never take CTA quotes («Запись», «+») — prefer a real catalog title.
        for (final m in RegExp(r'«([^»]+)»').allMatches(hit.reply)) {
          final title = m.group(1)?.trim() ?? '';
          if (!_looksLikeBookableTitle(title)) continue;
          if (_clinicService(title, gender: gender) != null ||
              _clinicInfusion(title) != null ||
              liveServices.any(
                (s) => _normalize(s.title).contains(_normalize(title)),
              )) {
            return title;
          }
        }
        if (rest.length >= 4 && _looksLikeBookableTitle(rest) && !_looksLikeBookSentence(rest)) {
          return rest;
        }
      }
      if (rest.length >= 4 &&
          !const {'утро', 'вечер', 'день', 'завтра', 'сегодня'}.contains(rest) &&
          _looksLikeBookableTitle(rest) &&
          !_looksLikeBookSentence(rest)) {
        return rest;
      }
    }

    // Recover service from prior bot/user turns («…»).
    final named = RegExp(r'«([^»]+)»').allMatches(topic).toList();
    for (final m in named.reversed) {
      final title = m.group(1)?.trim() ?? '';
      if (!_looksLikeBookableTitle(title)) continue;
      if (_clinicService(title, gender: gender) != null ||
          _clinicInfusion(title) != null ||
          liveServices.any((s) => _normalize(s.title).contains(_normalize(title)))) {
        return title;
      }
    }
    return null;
  }

  bool _looksLikeBookableTitle(String title) {
    final n = _normalize(title);
    if (title.trim().length < 3) return false;
    if (const {
      'запись',
      '+',
      'плюс',
      'услуги',
      'магазин',
      'голос',
      'врачи',
      'инфузии',
      'аппаратная',
      'прайс',
    }.contains(n)) {
      return false;
    }
    return true;
  }

  bool _looksLikeBookSentence(String title) {
    final n = _normalize(title);
    return n.contains('можно') ||
        n.contains('запиш') ||
        n.contains('хочу') ||
        n.contains('добавить') ||
        n.contains('?') ||
        n.split(RegExp(r'\s+')).length > 6;
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

  /// Put shop formula into cart (applied by store).
  ({String reply, AgentCartAdd? add})? _cartFlow(
    String q, {
    required String raw,
    String? lastBot,
    String? lastUser,
    List<String> recentUsers = const [],
    required List<Product> localProducts,
  }) {
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final takeIt = compact == 'возьму' ||
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
        compact.contains('давай её');
    final cartVerb = q.contains('в корзину') ||
        q.contains('корзину') ||
        q.contains('добавь в корзин') ||
        q.contains('положи в корзин') ||
        q.contains('положите в корзин') ||
        q.contains('добавьте в корзин') ||
        q.contains('в корзину полож') ||
        ((q.contains('купи') ||
                q.contains('закажу') ||
                q.contains('закажи') ||
                q.contains('хочу купить') ||
                q.contains('хочу взять')) &&
            !q.contains('можно ли') &&
            !q.contains('без консультац') &&
            !q.contains('нужна ли')) ||
        (q.contains('добавь') &&
            (q.contains('крем') ||
                q.contains('сыворот') ||
                q.contains('формул') ||
                q.contains('serum') ||
                q.contains('veil') ||
                q.contains('barrier') ||
                q.contains('mito')));
    if (!cartVerb && !takeIt) return null;

    final product = _resolveCartProduct(
      q: q,
      lastBot: lastBot,
      lastUser: lastUser,
      recentUsers: recentUsers,
      localProducts: localProducts,
    );
    if (product == null) {
      return (
        reply: takeIt
            ? 'Что именно берём в корзину — крем, сыворотку или название из шопа? Могу положить сразу.'
            : 'Какую формулу положить в корзину? Скажите бренд или «крем» / «сыворотка» — добавлю сама.',
        add: null,
      );
    }
    return (
      reply: _pick('cart-added', [
        'Готово — ${product.name} уже в корзине. Можете оформить в магазине или продолжим подбор.',
        'Положила ${product.name} в корзину. Открыть корзину в магазине или ещё что-то добавить?',
        '${product.name} в корзине. Если нужна ещё формула — назовите, положу следом.',
      ], raw),
      add: AgentCartAdd(
        id: product.id,
        name: product.name,
        price: product.price,
      ),
    );
  }

  Product? _resolveCartProduct({
    required String q,
    String? lastBot,
    String? lastUser,
    List<String> recentUsers = const [],
    required List<Product> localProducts,
  }) {
    // Explicit full name first (avoid «serum» matching the wrong bottle).
    for (final item in localProducts) {
      final name = _normalize(item.name);
      if (q.contains(name)) return item;
    }
    const cartStop = {
      'serum',
      'cream',
      'plus',
      'with',
      'from',
      'complex',
      'formula',
      'patch',
      'drops',
    };
    Product? best;
    var bestScore = 0;
    for (final item in localProducts) {
      final name = _normalize(item.name);
      final parts = name
          .split(RegExp(r'[\s\-]+'))
          .where((w) => w.length >= 4 && !cartStop.contains(w))
          .toList();
      var score = 0;
      for (final w in parts) {
        if (q.contains(w)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }
    if (best != null && bestScore > 0) return best;
    // Russian aliases.
    if (q.contains('барьер') || q.contains('крем')) {
      final hit = _clinicProduct('lumen barrier') ??
          localProducts.where((p) => _normalize(p.name).contains('barrier')).firstOrNull;
      if (hit != null && (q.contains('барьер') || q.contains('крем') || q.contains('lumen'))) {
        return hit;
      }
    }
    if (q.contains('сыворот') || q.contains('пептид') || q.contains('veil')) {
      final hit = _clinicProduct('veil peptide') ??
          localProducts.where((p) => _normalize(p.name).contains('veil')).firstOrNull;
      if (hit != null) return hit;
    }
    if (q.contains('mito') || q.contains('энерг') || q.contains('топлив')) {
      final hit = _clinicProduct('mitochondrial');
      if (hit != null) return hit;
    }

    final blob = _normalize('${lastBot ?? ''} ${lastUser ?? ''} ${recentUsers.join(' ')}');
    // Named product in last bot reply.
    final looked = RegExp(
      r'посмотрела ([^.]+)\.',
      caseSensitive: false,
    ).firstMatch(lastBot ?? '');
    if (looked != null) {
      final title = looked.group(1)?.trim() ?? '';
      for (final item in localProducts) {
        if (_normalize(item.name) == _normalize(title) ||
            _normalize(title).contains(_normalize(item.name))) {
          return item;
        }
      }
    }
    for (final item in localProducts) {
      if (blob.contains(_normalize(item.name))) return item;
      final key = _normalize(item.name).split(' ').firstWhere(
            (w) => w.length >= 5,
            orElse: () => '',
          );
      if (key.isNotEmpty && blob.contains(key)) return item;
    }
    if (blob.contains('барьер') || blob.contains('barrier')) {
      return _clinicProduct('lumen barrier');
    }
    if (blob.contains('пептид') || blob.contains('veil') || blob.contains('сыворот')) {
      return _clinicProduct('veil peptide');
    }
    return null;
  }

  /// VIP transfer → admin chat (applied by store when [AgentTransferRequest.ready]).
  ({String reply, AgentTransferRequest? request})? _transferFlow(
    String q, {
    required String raw,
    String? lastBot,
    String? lastUser,
  }) {
    final prev = _normalize(lastBot ?? '');
    final awaitingPlace = prev.contains('откуда забрать') ||
        prev.contains('адрес подачи') ||
        prev.contains('откуда подать машину') ||
        prev.contains('откуда вас забрать');
    final wants = q.contains('трансфер') ||
        q.contains('такси') ||
        q.contains('машин') ||
        q.contains('заберите') ||
        q.contains('забрать меня') ||
        q.contains('подайте машин') ||
        q.contains('вызвать трансфер') ||
        q.contains('нужен трансфер') ||
        q.contains('хочу трансфер') ||
        q.contains('водитель') ||
        (q.contains('аэропорт') &&
            (q.contains('забер') || q.contains('встрет') || q.contains('машин'))) ||
        awaitingPlace;
    if (!wants) return null;

    final place = _extractTransferPlace(q) ??
        (awaitingPlace ? _extractTransferPlace(_normalize(lastUser ?? '')) : null);
    final when = _extractTransferWhen(q);

    if (place == null || place.trim().length < 3) {
      return (
        reply: _pick('transfer-ask', [
          'Оформлю трансфер до клиники. Откуда забрать — аэропорт, вокзал, отель или ваш адрес?',
          'Трансфер до Черноморской, 6 закажу. Скажите, откуда подать машину — или «аэропорт Сочи».',
          'Трансфер сделаю через администратора. Откуда вас забрать?',
        ], raw),
        request: const AgentTransferRequest(from: '', ready: false),
      );
    }

    return (
      reply: _pick('transfer-ready', [
        'Приняла: трансфер с «$place»'
            '${when == null ? '' : ' · $when'}'
            ' до Черноморской, 6. Заявку уже отправила администратору — водитель напишет в чат.',
        'Заказала трансфер: забрать с «$place»'
            '${when == null ? '' : ', $when'}'
            '. Администратор подтвердит машину в чате.',
        'Готово — трансфер с «$place» в заявке у администратора'
            '${when == null ? '' : ' ($when)'}'
            '. Могу ещё помочь с записью или шопом.',
      ], raw),
      request: AgentTransferRequest(from: place, when: when, ready: true),
    );
  }

  String? _extractTransferPlace(String q) {
    if (q.contains('аэропорт') || q.contains('адлер аэро')) {
      return 'Аэропорт Сочи';
    }
    if (q.contains('вокзал') || q.contains('жд ')) return 'ЖД вокзал';
    if (q.contains('риксос') || q.contains('rixos')) return 'Отель Rixos';
    if (q.contains('marriott') || q.contains('марриотт')) return 'Отель Marriott';
    if (q.contains('красная поляна') || q.contains('полян')) {
      return 'Красная Поляна';
    }
    if (q.contains('центр сочи') || q.contains('из центра')) return 'Центр Сочи';
    if (q.contains('адлер') && !q.contains('аэропорт')) return 'Адлер';
    // Free-form: «с отеля …», «с улицы …», «от …»
    final from = RegExp(
      r'(?:с|со|от|из)\s+(.{3,48})$',
    ).firstMatch(q.trim());
    if (from != null) {
      var place = from.group(1)!.trim();
      place = place
          .replaceAll(RegExp(r'[.!?]+$'), '')
          .replaceAll(
            RegExp(
              r'\s+(пожалуйста|срочн\w*|сейчас|сегодня|завтра)$',
            ),
            '',
          )
          .trim();
      if (place.length >= 3 &&
          !place.contains('трансфер') &&
          !place.contains('машин') &&
          place != 'клиники' &&
          place != 'вас') {
        return place[0].toUpperCase() + place.substring(1);
      }
    }
    // Bare hotel / address-ish line while awaiting.
    if (q.contains('отел') || q.contains('улиц') || q.contains('проспект')) {
      final cleaned = q
          .replaceAll('нужен трансфер', '')
          .replaceAll('трансфер', '')
          .replaceAll('пожалуйста', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (cleaned.length >= 5) {
        return cleaned[0].toUpperCase() + cleaned.substring(1);
      }
    }
    return null;
  }

  String? _extractTransferWhen(String q) {
    if (q.contains('как можно скорее') || q.contains('скорее') || q.contains('сейчас')) {
      return 'как можно скорее';
    }
    final clock = RegExp(r'\b([01]?\d|2[0-3])[:.]([0-5]\d)\b').firstMatch(q);
    if (clock != null) return 'к ${clock.group(1)}:${clock.group(2)}';
    if (q.contains('к 10') || q.contains('к десяти')) return 'к 10:00';
    if (q.contains('к 12') || q.contains('к двенадцат')) return 'к 12:00';
    if (q.contains('к 15') || q.contains('к пятнадцат')) return 'к 15:00';
    if (q.contains('к 18') || q.contains('к восемнадцат')) return 'к 18:00';
    if (q.contains('утром')) return 'к утру';
    if (q.contains('вечером')) return 'к вечеру';
    return null;
  }

  /// Open admin / doctor chat (UI navigates via [AgentTurn.openChat]).
  ({String reply, String openChat})? _handoffTurn(String q, {required String raw}) {
    final toDoctor = q.contains('живого врача') ||
        q.contains('настоящего врача') ||
        q.contains('переведи на врача') ||
        q.contains('соедини с врачом') ||
        q.contains('позови врача') ||
        q.contains('хочу к врачу') ||
        q.contains('нужен врач') ||
        q.contains('чат врача') ||
        q.contains('напиши врачу') ||
        (q.contains('врач') &&
            (q.contains('перевед') ||
                q.contains('соедини') ||
                q.contains('позов') ||
                q.contains('живой') ||
                q.contains('настоящ')));
    final toAdmin = q.contains('оператор') ||
        q.contains('администратор') ||
        q.contains('админу') ||
        q.contains('переведи на человек') ||
        q.contains('соедини с человек') ||
        q.contains('живого человека') ||
        q.contains('реального человека') ||
        q.contains('хватит бота') ||
        q.contains('не бот') ||
        q.contains('позови человек') ||
        q.contains('живой консультант') ||
        (q.contains('переведи') && !toDoctor) ||
        (q.contains('соедини') && !toDoctor);
    if (!toDoctor && !toAdmin) return null;
    if (toDoctor) {
      return (
        reply: _pick('handoff-doc', [
          'Конечно — открываю чат с врачом. Напишите зону и что беспокоит: специалист ответит лично.',
          'Перевожу к врачу в чат. Я только помощник; осмотр и назначение — за ним.',
          'Открываю переписку с врачом CULT. Кратко опишите задачу — так быстрее разберёте.',
        ], raw),
        openChat: 'specialist',
      );
    }
    return (
      reply: _pick('handoff-admin', [
        'Хорошо — открываю чат с администратором. Там помогут с записью, трансфером и сертификатом.',
        'Соединяю с администратором. Можете сразу написать, что нужно.',
        'Перевожу на живого консультанта в чат администратора.',
      ], raw),
      openChat: 'admin',
    );
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
    // Named service + slot → let [_bookFlow] / catalog teach own the turn.
    final namedService = q.contains('nad') ||
        q.contains('beauty') ||
        q.contains('glow') ||
        q.contains('массаж') ||
        q.contains('пилинг') ||
        q.contains('ботокс') ||
        q.contains('rf') ||
        q.contains('рф') ||
        q.contains('ipl') ||
        q.contains('smas') ||
        q.contains('капель') ||
        q.contains('hydrapure') ||
        q.contains('чистка');
    // Don't steal «сегодня вечером событие» from situation/event flow.
    if (!(morning || evening || weekend || weekday.isNotEmpty)) return null;
    if (namedService && bookingCue) return null;
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
      out = 'Процедуры согласуем на осмотре, с анестезией где нужно. $reply';
    } else if (q.contains('не знаю') ||
        q.contains('подскажи') ||
        q.contains('посоветуй')) {
      out = 'Из нашего прайса ближе всего так: $reply';
    }
    if (soft) {
      return _pick('catalog-soft', [
        'Похоже, вот это: $out Если мимо — скажите «не то» или одно слово точнее.',
        'Ближе всего так: $out Если не то — поправьте одним словом.',
        'Нашла у нас. $out Можно уточнить или сказать «не то».',
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
          'Про капельницу ${item.title}: обычно ${item.price}, занимает ${item.duration}. '
          '${item.blurb} '
          'Перед капельницей врач уточнит показания. '
          'Если откликается — можем записаться.';
    } else if (bestDevice == best && deviceHits.isNotEmpty) {
      final item = deviceHits.first.item;
      reply =
          'Про аппарат ${item.title}: ${item.meta}. '
          'По цене ориентир — ${item.price}. '
          'Интенсивность подберём на консультации под вашу кожу.';
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
      final buf = StringBuffer('Про ${item.title}');
      if (wantsPrice) {
        buf.write(
          ' — обычно около ${item.priceLabel}, занимает ${item.duration}',
        );
      }
      buf.write('. ${item.blurb} ');
      if (!wantsPrice && item.results.isNotEmpty) {
        buf.write('Чаще всего ждут: ${item.results.take(2).join(', ')}. ');
      }
      if (item.contraindications.isNotEmpty) {
        buf.write(
          'На осмотре важно сказать про: ${item.contraindications.take(2).join('; ')}. ',
        );
      }
      parts.add(buf.toString().trim());
    }
    return '${parts.join(' ')}\n'
        'Если откликается — можем записаться: нажмите «Запись» или скажите, когда удобно. '
        'На осмотре уточним детали под вашу кожу.';
  }

  String _formatLive(List<YcService> items) {
    final lines = [
      for (final item in items)
        '${item.title}'
            '${item.priceLabel.isEmpty ? '' : ' — примерно ${item.priceLabel}'}'
            '${item.durationLabel.isEmpty ? '' : ', ${item.durationLabel}'}',
    ];
    return 'В филиале в Сочи сейчас так: ${lines.join('; ')}. '
        'Полный прайс — в меню, а записаться проще кнопкой «Запись». '
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
              'Привет! Я Мира — рада вас слышать. Что сейчас важнее: кожа, самочувствие или просто поболтать?',
              'Здравствуйте, это Мира. Расскажите, как вы — освежить вид, разобрать зону или записаться?',
              'Привет, я Мира, рядом. Говорите как удобно, без сложных названий — я пойму.',
            ], q)
          : _pick('greet-w', const [
              'Привет! Я Мира. Рада вас слышать — что у вас сегодня: кожа, усталость или запись?',
              'Здравствуйте, это Мира. Чем помочь — освежить вид, морщинки или просто поговорить?',
              'Привет, я Мира, рядом. Скажите своими словами — подстроюсь.',
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
        'Спасибо, у меня всё хорошо — и я целиком для вас. А вы как себя чувствуете сегодня?',
        'Хорошо, спасибо, что спросили. А у вас как: кожа спокойная или что-то тянет?',
        'Живу-пожитаю, спасибо. Расскажите про себя — вместе найдём, что подтянуть.',
        'Отлично, когда есть с кем поговорить о деле. Как вы?',
      ], q);
    }
    if (words.any(
      (w) => const {
        'спасибо',
        'благодарю',
        'сенкс',
        'thanks',
        'благодарствую',
        'мерси',
      }.contains(w),
    )) {
      return _pick('thanks', const [
        'И вам спасибо — приятно помогать. Можем продолжить без спешки.',
        'Всегда пожалуйста. Если ещё что-то всплывёт — просто скажите.',
        'Вам спасибо. Я рядом, если понадоблюсь.',
        'Рада была помочь. Остаюсь на связи.',
      ], q);
    }
    if (compact == 'пожалуйста' || compact == 'пожалуйста дальше') {
      return 'Конечно. О чём продолжим — кожа, запись или шоп?';
    }
    if (compact == 'пока' ||
        compact.startsWith('до встречи') ||
        compact.startsWith('всего доброго') ||
        compact.startsWith('до свидания') ||
        compact == 'спокойной ночи' ||
        compact == 'увидимся' ||
        compact.startsWith('хорошего дня') ||
        compact.startsWith('хорошего вечера')) {
      return _pick('bye', const [
        'Всего доброго. Берегите себя — буду рада снова услышать вас.',
        'До связи. Если что-то всплывёт — я здесь.',
        'Хорошего дня. Загляните, когда захотите продолжить.',
        'Пока-пока. Пусть кожа и настроение будут спокойными.',
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
        'Меня зовут Мира. Можно просто поговорить о коже или сразу про визит — как удобнее.',
        'Я Мира. Слушаю, что беспокоит, и предлагаю спокойный следующий шаг.',
        'Мира. Приятно познакомиться — что сейчас важнее: кожа или самочувствие?',
      ], q);
    }
    if (asksAbout) {
      return _pick('who-am-i', const [
        'Я Мира, косметолог клиники Культ. Очный осмотр не заменяю, но могу разобрать задачу, записать на услугу, положить уход в корзину или вызвать трансфер. О чём подумаем?',
        'Я косметолог команды Культ, зовут Мира. Говорю как на приёме: кожа, энергия, запись — без жёсткого сценария. Чем помочь?',
        'Коротко: я Мира, косметолог Культ. Помогаю сориентироваться в уходах и шопе; если нужно — переведу к врачу или администратору.',
      ], q);
    }
    if (q.contains('переводчик') ||
        q.contains('с перевод') ||
        q.contains('нужен перевод')) {
      return null; // [_teachReply] owns interpreter logistics.
    }
    if ((q.contains('на английском') ||
            q.contains('speak english') ||
            q.contains('do you speak') ||
            q.contains('говорите по-англий') ||
            q.contains('говорите по англий') ||
            compact == 'english' ||
            compact == 'английский') &&
        !q.contains('сертификат')) {
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
        'Конечно, давайте вместе. Лицо или тело — что хотите улучшить?',
        'С удовольствием разберём. Что ближе — лицо, самочувствие или запись?',
        'Да, подскажу. Хватит одного слова: лицо, тело или энергия.',
      ], q);
    }
    if (compact == 'нужен совет' ||
        compact == 'что посоветуешь' ||
        compact == 'есть вопрос' ||
        compact == 'давай поговорим' ||
        compact == 'поговорим' ||
        compact.contains('просто поговорить') ||
        compact.contains('можно поговорить') ||
        compact == 'поболтаем' ||
        compact.contains('давай поболтаем')) {
      return _pick('lets-talk', const [
        'Да, давайте спокойно. Можно с ощущения: сухость, усталость, «хочу свежий вид» — или спросить про клинику.',
        'С удовольствием. С чего вам легче — кожа в зеркале, самочувствие или просто вопрос про визит?',
        'Я слушаю. Говорите как другу на приёме — без правильных формулировок.',
      ], q);
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
      return 'Хорошо. Тогда чуть конкретнее: лицо, тело, энергия или запись — продолжим в вашем темпе.';
    }
    if (words.length <= 4 &&
        const {
          'нет',
          'не надо',
          'не нужно',
          'потом',
          'ну ладно потом',
        }.contains(compact)) {
      return 'Хорошо, без давления. Если позже захотите совет или запись — просто напишите или скажите голосом.';
    }
    if (q.contains('голос стран') ||
        q.contains('робот голос') ||
        q.contains('звучит как робот') ||
        q.contains('неживой голос')) {
      return _pick('voice-robot', const [
        'Понимаю, синтетический голос раздражает. Могу отвечать короче — скажите «короче» или тему одним словом.',
        'Слышу вас. Давайте короче и по делу: одно слово — сухость, массаж, запись — и продолжим.',
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
    // Don't steal «боюсь игл / губы / без уколов» — [_teachReply] owns alternatives.
    final asksNoInjectLift = q.contains('без укол') ||
        q.contains('безъинъек') ||
        q.contains('безынек') ||
        q.contains('без инек') ||
        q.contains('без игол') ||
        q.contains('боюсь игл') ||
        q.contains('боюсь иголка') ||
        q.contains('боюсь укол') ||
        q.contains('боюсь аппарат') ||
        q.contains('альтернатив') ||
        q.contains('ручной уход') ||
        q.contains('только ручн') ||
        q.contains('поплыв') ||
        q.contains('выйти в люди') ||
        q.contains('не смогу выйти') ||
        (q.contains('боюсь') &&
            (q.contains('губ') || q.contains('массаж') || q.contains('пилинг'))) ||
        ((q.contains('лифтинг') || q.contains('подтя')) &&
            (q.contains('без') || q.contains('игл') || q.contains('игол')));
    if (!asksNoInjectLift &&
        (q.contains('боюсь') ||
            q.contains('страшно') ||
            q.contains('больно ли') ||
            q.contains('это больно') ||
            q.contains('пережива')) &&
        !q.contains('сожж') &&
        !q.contains('сожг') &&
        !q.contains('сгорит') &&
        !q.contains('ожог') &&
        !q.contains('мигрир') &&
        !q.contains('мигриру') &&
        !q.contains('smas') &&
        !q.contains('смас') &&
        !q.contains('ultherap') &&
        !q.contains('синяк') &&
        !q.contains('гематом') &&
        !q.contains('синяч') &&
        !q.contains('фотосесс') &&
        !q.contains('мигрен') &&
        !q.contains('отек') &&
        !q.contains('отёк') &&
        !q.contains('капель') &&
        !q.contains('инфуз') &&
        !q.contains('rf') &&
        !q.contains('рф') &&
        !q.contains('микроиголь') &&
        !(q.contains('выйти в люди') || q.contains('не смогу выйти'))) {
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
      return 'Добро пожаловать — у нас без давления. Обычно начинаем с короткой консультации: смотрим кожу, цели и противопоказания, потом один понятный шаг. '
          'Новым клиентам после входа по телефону — welcome-бонус 3 000 ₽. Запишем осмотр?';
    }
    if (q.contains('расскажи о клиник') ||
        q.contains('что за культ') ||
        q.contains('про клинику') ||
        q.contains('чем вы занима') ||
        q.contains('что у вас за место')) {
      return 'Культ в Сочи — клиника эстетики и биохакинга на Черноморской, 6. '
          'Уходы, инъекции, аппаратная, капельницы, лаборатория и шоп. Ежедневно с девяти до девяти вечера. Чем помочь лично вам?';
    }
    if (q.contains('скучно') ||
        q.contains('расскажи что') ||
        q.contains('анекдот') ||
        q.contains('пошути') ||
        q.contains('повесели')) {
      return 'Могу быть лёгкой, но по делу: лучше расскажу, как за один визит освежить тон или снять отёк массажем. '
          'Хотите быстрый эффект к вечеру или долгий результат курсом?';
    }

    // Broader everyday questions — answer like a living consultant, not a menu.
    final life = _lifeChatReply(q, compact: compact, words: words);
    if (life != null) return life;

    return null;
  }

  /// Everyday / emotional / off-catalog questions with a human bedside manner.
  String? _lifeChatReply(
    String q, {
    required String compact,
    required List<String> words,
  }) {
    if (q.contains('люблю тебя') ||
        q.contains('ты милая') ||
        q.contains('ты классн') ||
        q.contains('ты умниц') ||
        q.contains('ты лучш') ||
        compact == 'красавица' ||
        compact == 'умница') {
      return _pick('compliment', const [
        'Спасибо, приятно. Давайте лучше про вас — чем помочь с кожей или визитом?',
        'Ой, спасибо. Я тут, чтобы вам стало спокойнее и понятнее. О чём подумаем?',
        'Рада слышать. А что у вас на повестке — уход, запись или просто вопрос?',
      ], q);
    }
    if (q.contains('грустн') ||
        q.contains('плохое настроен') ||
        q.contains('подавлен') ||
        q.contains('устала от всего') ||
        q.contains('накрыло') ||
        compact == 'мне плохо' ||
        compact == 'плохо') {
      return _pick('mood-low', const [
        'Жаль, что тяжело. Я не психолог, но могу мягко помочь с кожей или силами — иногда маленький ритуал уже поднимает. Что ближе?',
        'Слышу вас. Давайте без спешки: усталость, кожа или просто хотите, чтобы кто-то подсказал следующий шаг?',
        'Бывает. Если тело и лицо тоже «просят внимания» — подберу спокойный уход или капельницу. Или просто поговорим про визит.',
      ], q);
    }
    if (q.contains('радост') ||
        q.contains('отлично настроен') ||
        q.contains('всё супер') ||
        q.contains('всё хорошо у меня') ||
        compact == 'я счастлив' ||
        compact == 'я счастлива') {
      return 'Как здорово. Можем закрепить настроение свежим уходом или лёгким массажем — или просто подскажу, что взять домой.';
    }
    if (q.contains('беремен') ||
        q.contains('кормлю грудь') ||
        q.contains('кормить грудь') ||
        q.contains('кормит грудь') ||
        q.contains('грудном вскарм') ||
        q.contains('грудным вскарм') ||
        q.contains('грудное вскарм') ||
        q.contains('лактац') ||
        (q.contains('груд') && q.contains('вскарм')) ||
        RegExp(r'(^|[^а-я])гв([^а-я]|$)').hasMatch(q) ||
        q.contains('при гв') ||
        q.contains('на гв')) {
      if (q.contains('массаж') || q.contains('уход') || q.contains('лица')) {
        return 'При грудном вскармливании и в беременность аппаратные и инъекции часто под запретом; мягкий массаж лица и уход — только после допуска врача. '
            'Без осмотра не записываю «на всё». Могу открыть чат врача или консультацию.';
      }
      return 'В беременность и при грудном вскармливании многие процедуры и активы под запретом — это решает только врач очно. '
          'Могу записать на консультацию или перевести в чат специалиста; дома без кислот и ретинола, пока не скажут иначе.';
    }
    if ((q.contains('ребёнк') ||
            q.contains('ребенк') ||
            q.contains('ребенка') ||
            q.contains('ребёнка') ||
            q.contains('с ребенком') ||
            q.contains('с ребёнком') ||
            q.contains('с детьми')) &&
        (q.contains('с собой') ||
            q.contains('на процедур') ||
            q.contains('взять') ||
            q.contains('привест') ||
            q.contains('брать'))) {
      return 'Ребёнка в кабинет на взрослую процедуру обычно не берут — так спокойнее и вам, и специалисту. '
          'На ресепшен подскажут, где подождать с сопровождающим. Лучше прийти без малыша или с кем-то, кто побудет с ним снаружи.';
    }
    if (q.contains('подрост') ||
        q.contains('ребёнк') ||
        q.contains('ребенк') ||
        q.contains('дочке') ||
        q.contains('сыну') ||
        q.contains('школьн')) {
      return 'С подростками и детьми идём очень бережно: чаще осмотр и мягкий уход, без «взрослой» артиллерии. '
          'Лучше запись на консультацию — и согласие родителя, если несовершеннолетний.';
    }
    if (q.contains('климакс') ||
        q.contains('менопауз') ||
        q.contains('перименопауз') ||
        q.contains('гормональн фон')) {
      return 'В период гормональных перемен кожа часто суше и тоньше — это нормально. '
          'Обычно начинаем с барьера, увлажнения и осмотра; инъекции и аппаратные — только после врача. Расскажите, что беспокоит сильнее.';
    }
    if (q.contains('после родов') ||
        q.contains('послеродов') ||
        q.contains('растяжки после')) {
      return 'После родов темп спокойный: сначала восстановление и осмотр, потом курс по растяжкам или тонусу — без обещаний «как не было». '
          'Кормите грудью? Это важно для выбора процедур.';
    }
    if (q.contains('муж') &&
        (q.contains('подари') || q.contains('удиви') || q.contains('хочет'))) {
      return 'Для него часто заходит барбер-массаж, мужской уход или сертификат — без «розового» давления. '
          'Могу подсказать сертификат или записать на консультацию. Что ближе?';
    }
    if (q.contains('жен') &&
        (q.contains('подари') || q.contains('удиви') || q.contains('сюрприз'))) {
      return 'Красивый жест — сертификат или запись на уход/массаж. Могу помочь оформить сертификат через администратора или подобрать процедуру. Какой бюджет примерно?';
    }
    // Wi‑Fi / parking — keep in [_faqReply] (has network name CULT Guest).
    if (q.contains('туалет') || q.contains('гардероб') || q.contains('раздевал')) {
      return 'В клинике есть гардероб и санузлы — подскажут на ресепшен. Приходите чуть заранее, чтобы спокойно переодеться перед процедурой.';
    }
    if (q.contains('можно с собакой') ||
        q.contains('с питомц') ||
        q.contains('с животн') ||
        q.contains('с кошкой')) {
      return 'Питомцев в процедурные зоны обычно не пускаем — уточните у администратора, если нужна помощь с ожиданием. Лучше оставить друга дома или с сопровождающим снаружи.';
    }
    if (q.contains('можно курить') ||
        q.contains('кальян') ||
        q.contains('вейп') ||
        q.contains('электронк')) {
      return 'В клинике без курения и вейпа. После части процедур дым и жар ещё и вредят заживлению — врач скажет паузу.';
    }
    if (q.contains('можно алкогол') ||
        q.contains('можно вино') ||
        q.contains('выпить перед') ||
        q.contains('выпить после')) {
      return 'Алкоголь до и после многих процедур лучше убрать — отёк и синяки любят усиливаться. Точный срок скажет врач под вашу процедуру.';
    }
    if (q.contains('можно спорт') ||
        q.contains('можно в зал') ||
        q.contains('можно бегать') ||
        q.contains('можно бассейн') ||
        q.contains('можно саун') ||
        q.contains('можно баню') ||
        ((q.contains('после') || q.contains('после ')) &&
            (q.contains('спорт') ||
                q.contains('бассейн') ||
                q.contains('саун') ||
                q.contains('баню') ||
                q.contains('баню') ||
                q.contains('баня')))) {
      if (q.contains('пилинг') || q.contains('кислот') || q.contains('ретин')) {
        return 'После пилинга и кислот спорт, бассейн и сауну обычно ставим на паузу несколько дней: пот и хлор раздражают обновляющуюся кожу, SPF всё равно обязателен. '
            'Точный срок — по глубине пилинга у врача. Когда делали?';
      }
      if (q.contains('smas') || q.contains('смас') || q.contains('ultherap')) {
        return 'После SMAS спорт и баню обычно ставят на паузу несколько дней — ориентир даст врач по протоколу, чаще дольше, чем после мягкого ухода. '
            'Когда была процедура?';
      }
      if (q.contains('rf') || q.contains('рф') || q.contains('микроиголь')) {
        return 'После RF обычно пауза на баню, сауну и жёсткий спорт несколько дней — кожа восстанавливается, лишний жар не нужен. '
            'Точный срок скажет врач по вашему протоколу. Когда была процедура?';
      }
      if (q.contains('ipl') || q.contains('айпи') || q.contains('lumecca')) {
        return 'После IPL спорт, бассейн и сауну обычно ставят на паузу пару дней — пот и жар раздражают зону вспышки; SPF обязателен. '
            'Точный срок скажет врач по протоколу. Когда была вспышка?';
      }
      if (q.contains('массаж') || q.contains('лимфодрен')) {
        return 'После массажа баню и сауну в тот же день лучше не планировать — сосуды и лимфа ещё «разогреты»; чаще пауза до следующего дня, без жёсткого пара. '
            'Лёгкая прогулка обычно ок. Когда был массаж?';
      }
      if (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц')) {
        return 'После капельницы баню и сауну в тот же день лучше не планировать — сосуды и самочувствие ещё «разгоняются»; чаще пауза до следующего дня. '
            'Точнее скажет врач по составу. Когда была инфузия?';
      }
      if (q.contains('hydrapure') ||
          q.contains('hydra') ||
          q.contains('гидрапур') ||
          q.contains('гидра пьюр')) {
        return 'После HydraPure сауну и жёсткий спорт обычно не в тот же вечер — кожа ещё «открыта» после сывороток; чаще пауза до следующего дня, без распаривания. '
            'Точный срок на ресепшен по протоколу. Когда делали уход?';
      }
      if (q.contains('чистк') || q.contains('чистка')) {
        return 'После чистки бассейн и сауну обычно ставят на паузу 1–2 дня — хлор и пот раздражают обновлённую кожу; через два дня часто уже мягко, если нет красноты. '
            'Точный срок на ресепшен по протоколу. Когда делали чистку?';
      }
      if (q.contains('филлер') ||
          q.contains('ботокс') ||
          q.contains('инъек') ||
          q.contains('мезо') ||
          q.contains('биоревитал')) {
        return 'После уколов спортзал, бассейн и сауну чаще откладывают на пару дней — меньше отёк и синяки. Лёгкая ходьба обычно ок. '
            'Напишите, что кололи — подскажу ориентир или переведу к врачу.';
      }
      return 'Спорт, бассейн и сауна зависят от процедуры: после уколов и аппаратных часто пауза несколько дней. Напишите, что делали или планируете — подскажу ориентир или переведу к врачу.';
    }
    if (q.contains('погод') ||
        q.contains('на улице жарк') ||
        q.contains('на улице холод')) {
      return 'Погоду не предскажу, зато про кожу в жару и холод — да: SPF и барьер летом, плотнее крем и меньше кислот зимой. Хотите домашний совет или визит?';
    }
    if (q.contains('сколько тебе лет') ||
        q.contains('сколько вам лет') ||
        q.contains('ты девушка') ||
        q.contains('ты женщина')) {
      return 'Я Мира из команды Культ — цифры возраста не важны. Важнее, чем помочь вам: кожа, силы или запись.';
    }
    if (q.contains('ты замуж') ||
        q.contains('есть парень') ||
        q.contains('личная жизнь') ||
        q.contains('давай встретим')) {
      return 'Я здесь как косметолог-консультант клиники, не для свиданий. Зато честно помогу с кожей, записью и уходом — о чём подумаем?';
    }
    if (q.contains('молч') ||
        compact == 'алло' ||
        compact == 'эй' ||
        compact == 'ты тут' ||
        compact == 'вы тут' ||
        compact == 'мира') {
      return _pick('ping', const [
        'Я здесь, на связи. Слушаю вас.',
        'Да, я тут. Расскажите, что нужно.',
        'Тут, на месте. Кожа, запись, корзина или трансфер — с чего начнём?',
      ], q);
    }
    if (q.contains('не понял') ||
        q.contains('не поняла') ||
        q.contains('непонятно') ||
        q.contains('поясни') ||
        q.contains('объясни проще') ||
        (q.contains('простыми словами') &&
            !q.contains('биоревитал') &&
            !q.contains('мезотерап') &&
            !q.contains('ботокс') &&
            !q.contains('филлер') &&
            !q.contains('пилинг') &&
            !q.contains('hydrapure') &&
            !q.contains('hydra') &&
            !q.contains('smas') &&
            !q.contains('смас') &&
            !q.contains('rf') &&
            !q.contains('nad') &&
            !q.contains('immunity') &&
            !q.contains('иммунит') &&
            !q.contains('капель') &&
            !q.contains('cellular') &&
            !q.contains('catalyst') &&
            !q.contains('катализ') &&
            !q.contains('mitochondrial') &&
            !q.contains('veil') &&
            !q.contains('neuro') &&
            !q.contains('lumen') &&
            !q.contains('gluta') &&
            !q.contains('liposomal') &&
            !q.contains('глута') &&
            !q.contains('липосомальн') &&
            !q.contains('aura') &&
            !q.contains('mist') &&
            !q.contains('мист') &&
            !q.contains('patch') &&
            !q.contains('патч') &&
            !q.contains('circadian') &&
            !q.contains('циркад') &&
            !q.contains('light panel') &&
            !q.contains('лайт панель') &&
            !q.contains('панель свет'))) {
      return 'Хорошо, скажу проще. Опишите одним предложением, что беспокоит — или попросите «короче» / «подробнее» про мой прошлый ответ.';
    }
    if (q.contains('повтор') ||
        compact == 'ещё раз' ||
        compact == 'еще раз') {
      return null; // meta reply owns «повтори»
    }
    if (q.contains('что ты думаешь') ||
        q.contains('твое мнение') ||
        q.contains('твоё мнение') ||
        q.contains('как считаешь')) {
      return 'Моё мнение спокойное: сначала осмотр и мягкий вход, без гонки за «вау любой ценой». '
          'Расскажите задачу — скажу, с чего бы начала на вашем месте.';
    }
    if (q.contains('чем заняться') ||
        q.contains('что делать сегодня') ||
        q.contains('куда пойти')) {
      return 'Если рядом с визитом в Культ — можно совместить уход и спокойный вечер без тяжёлой реабилитации. '
          'Или скажите задачу кожи: подберу, что успеем за один визит.';
    }
    if (q.contains('сколько стоит консультац') ||
        q.contains('цена консультац') ||
        compact == 'консультация сколько') {
      return null; // catalog / price paths
    }
    if (words.length == 1 &&
        const {
          'ок',
          'окей',
          'угу',
          'ага',
          'ясно',
          'понятно',
          'хорошо',
          'ладно',
          'норм',
          'нормально',
          'супер',
          'класс',
          'круто',
        }.contains(compact)) {
      return _pick('ack-soft', const [
        'Хорошо. Если появится вопрос — я здесь.',
        'Договорились. Можем продолжить, когда будете готовы.',
        'Ок. Лицо, тело, запись или шоп — если что, зовите.',
      ], q);
    }
    if (q.contains('помоги выбрать') ||
        q.contains('не могу выбрать') ||
        q.contains('что мне сделать') ||
        (q.contains('что взять') &&
            !q.contains('отпуск') &&
            !q.contains('море') &&
            !q.contains('поездк') &&
            !q.contains('дорог') &&
            !q.contains('кож') &&
            !q.contains('капель') &&
            !q.contains('инфуз') &&
            !q.contains('с собой') &&
            !q.contains('на приём') &&
            !q.contains('на прием'))) {
      if (_concernReply(q) != null) return null;
      return 'Давайте сузим вместе. Вам сейчас ближе свежий вид, ровный тон, овал или силы? Одного ответа хватит.';
    }
    if ((q.contains('на сколько хватит') ||
            q.contains('на сколько хватает') ||
            q.contains('как долго держится') ||
            q.contains('надолго ли')) &&
        !q.contains('ботокс') &&
        !q.contains('ботулин') &&
        !q.contains('филлер') &&
        !q.contains('гиалурон')) {
      return 'Срок эффекта разный: уход и массаж — дни и недели ощущения свежести; курсы RF и инъекции — по схеме врача, часто месяцы. '
          'Назовите процедуру — скажу честнее по ней.';
    }
    if ((q.contains('есть ли скидк') ||
            q.contains('акции есть') ||
            q.contains('что по акци') ||
            compact == 'скидки' ||
            compact == 'акции') &&
        !q.contains('пакет') &&
        !q.contains('абонемент') &&
        !q.contains('курс')) {
      return 'Скидки и пакеты зависят от сезона и карты лояльности — welcome-бонус новым клиентам 3 000 ₽ после входа по телефону. '
          'Актуальные акции точнее скажет администратор в чате; могу перевести.';
    }
    if (q.contains('работаете ли') ||
        q.contains('вы открыты') ||
        q.contains('сейчас открыт') ||
        q.contains('сейчас открыта') ||
        (q.contains('открыт') &&
            (q.contains('сегодня') || q.contains('сейчас') || q.contains('вы '))) ||
        q.contains('можно сегодня прийт') ||
        q.contains('можно сегодня записа')) {
      return 'Мы ежедневно с 9:00 до 21:00. Если хотите сегодня — скажите услугу и утро/день/вечер, соберём запись на подтверждение.';
    }
    if (q.contains('на карте') ||
        q.contains('геолокац') ||
        q.contains('построить маршрут')) {
      return 'Адрес: Сочи, Черноморская, 6. В навигаторе так и ищите — или скажите «трансфер», вызову машину до клиники.';
    }
    if (q.contains('наличн') ||
        q.contains('можно картой') ||
        q.contains('apple pay') ||
        (q.contains('оплата') && q.contains('как'))) {
      return 'Оплата картой, наличными и бонусами CULT; Apple Pay на ресепшен обычно проходит. Крипту не берём. Уточнить способ можно у администратора.';
    }
    if (q.contains('честно') ||
        q.contains('без воды') ||
        q.contains('по делу') ||
        q.contains('короче говоря')) {
      return 'Честно и коротко: скажите зону и цель — назову один-два реальных варианта из нашего прайса и следующий шаг. Без воды.';
    }
    if (q.contains('ты меня слышишь') ||
        q.contains('меня слышно') ||
        q.contains('связь есть')) {
      return 'Да, слышу. Можно говорить — я на связи.';
    }
    if (compact == 'ещё' ||
        compact == 'еще' ||
        compact == 'дальше' ||
        compact == 'продолжай' ||
        compact == 'и ещё') {
      return 'Продолжаем. Что добавить — другая зона, цена, запись или домашний уход?';
    }
    if (q.contains('забыл') ||
        q.contains('забыла') ||
        q.contains('не помню на что')) {
      return 'Ничего страшного. Скажите «напомни» — соберу, о чём говорили, или назовите заново зону и цель.';
    }
    // «Горит» про кожу/кислоты — не путать со «срочно к вечеру».
    final skinBurn = q.contains('кож') ||
        q.contains('кислот') ||
        q.contains('жж') ||
        q.contains('щипл') ||
        q.contains('пилинг') ||
        q.contains('ретинол');
    if ((q.contains('срочно') ||
            q.contains('очень надо') ||
            q.contains('к вечеру надо') ||
            (q.contains('горит') && !skinBurn))) {
      return 'Если горит к вечеру — без тяжёлой реабилитации: уход, массаж или лёгкое освежение тона. Назовите время, до которого нужно успеть.';
    }
    if (q.contains('не помогает') ||
        q.contains('ничего не помогает') ||
        q.contains('уже всё пробовал') ||
        q.contains('уже всё пробовала')) {
      return 'Понимаю усталость от пустых попыток. Тогда честный путь — очный осмотр: разберём, что уже делали, и не будем множить то же самое. Запишем консультацию?';
    }
    if (q.contains('секрет') ||
        q.contains('конфиденциальн') ||
        q.contains('это останется')) {
      return 'Разговор в приложении на вашем телефоне; медицинские детали лучше дублировать врачу в чате специалиста. Мы не выкладываем ваши истории публично.';
    }
    if (q.contains('фото прислать') ||
        q.contains('скинуть фото') ||
        q.contains('отправить фото') ||
        q.contains('по фото скажи')) {
      return 'По фото в этом чате я диагнозов не ставлю — слишком легко ошибиться. Можете описать словами или отправить снимок врачу в чат специалиста после перевода.';
    }
    if ((q.contains('а что насчет') ||
            q.contains('а что насчёт') ||
            q.startsWith('а как же')) &&
        words.length <= 8) {
      return 'Хороший уточняющий вопрос. Сформулируйте чуть прямее — про процедуру, цену, противопоказание или запись — отвечу по делу.';
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

  /// Extra trained clinical answers — run early so FAQ/catalog don't steal them.
  String? _teachReply(String q, {ClientGender? gender}) {
    final man = gender == ClientGender.man;

    if (q.contains('отлича') &&
        (q.contains('админ') ||
            q.contains('оператор') ||
            q.contains('чат') ||
            q.contains('бот'))) {
      return 'Я Мира — косметолог-консультант: разбираю кожу и самочувствие, могу записать на услугу, положить уход в корзину или вызвать трансфер. '
          'Администратор — про слоты, оплату, сертификаты и логистику «здесь и сейчас». '
          'Врач в чате — если нужны медицинские назначения после осмотра. К кому перевести?';
    }

    if (q.contains('справк') ||
        q.contains('больничн') ||
        q.contains('для работы документ') ||
        (q.contains('документ') && q.contains('работ'))) {
      return 'Медицинские справки и закрывающие документы оформляют на ресепшен или через администратора — напишите в чат, что именно нужно и к какому визиту. '
          'Я сама справку не выписываю, но могу перевести к администратору.';
    }

    // «носогубки» / «кисетные … губой» — not lip-augmentation path.
    if (!q.contains('носогуб') &&
        !q.contains('кисет') &&
        (q.contains('губ') || q.contains('губы')) &&
        (q.contains('натурал') ||
            q.contains('естеств') ||
            q.contains('не хочу больш') ||
            q.contains('чуть') ||
            q.contains('аккурат') ||
            q.contains('умерен') ||
            q.contains('хочу'))) {
      return 'Натуральные губы в CULT — без «уточки»: объём и форма только после осмотра, часто хватает мягкой коррекции или вообще ухода и увлажнения. '
          'Если боитесь перебора — начнём с консультации и фото-примеров «до/после» у врача. Запишем осмотр?';
    }

    if (q.contains('филлер') &&
        (q.contains('сколько держ') ||
            q.contains('как долго') ||
            q.contains('надолго') ||
            q.contains('когда рассос'))) {
      return 'Филлеры на гиалуронке обычно держатся от нескольких месяцев до года-полутора — зависит от зоны, плотности препарата и вашего обмена. '
          'Точный ориентир скажет врач на осмотре. Могу записать на консультацию по контуру.';
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('жар') ||
            q.contains('солнц') ||
            q.contains('загар') ||
            (RegExp(r'(^|[^а-я])лет(ом|о|а|у)?([^а-я]|$)').hasMatch(q) &&
                !q.contains('перелет') &&
                !q.contains('самолет')))) {
      return 'Ботулотоксин летом можно, если нет активного воспаления и вы готовы к SPF и без бани/жёсткого спорта пару дней. '
          'Жару и перелёт лучше обсудить с врачом под вашу дату. Запишем консультацию или сразу зону (лоб, глаза, всё лицо)?';
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('свадеб') ||
            q.contains('свадьб') ||
            q.contains('мероприят') ||
            q.contains('перед событ')) &&
        (q.contains('недел') ||
            q.contains('за недел') ||
            q.contains('скоро') ||
            q.contains('через'))) {
      return 'За неделю до свадьбы ботулин — на грани: кому-то хватает, но отёк и «посадка» эффекта непредсказуемы в кадре. '
          'Чаще за 2–4 недели или мягкий уход/массаж ближе к дате. Запишем консультацию под ваш день?';
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('мигрен') || q.contains('головн боль')) &&
        (q.contains('поможет') ||
            q.contains('лечит') ||
            q.contains('от мигрен') ||
            (q.contains('часто') && !q.contains('после')))) {
      return 'Ботулин при мигренях — отдельный медицинский протокол, не «косметический лоб». Показания и схему решает врач очно, без обещаний «сниму все приступы». '
          'Могу записать на консультацию или открыть чат специалиста.';
    }

    if ((q.contains('ботокс') || q.contains('ботулин') || q.contains('после укол')) &&
        (q.contains('голов') || q.contains('мигрен') || q.contains('тошн')) &&
        (q.contains('после') ||
            q.contains('болит') ||
            q.contains('боюсь') ||
            q.contains('страх') ||
            q.contains('в лоб'))) {
      if (q.contains('боюсь') || q.contains('страх')) {
        return 'Лёгкая головная боль или мигренеподобный фон после ботулина в лоб бывает не у всех и часто проходит; на осмотре скажем, чего ждать. '
            'Можно начать с консультации без процедуры в тот же день. Запишем осмотр по лбу?';
      }
      return 'Лёгкая головная боль после ботулинотерапии бывает и часто проходит сама; холод по схеме врача, без массажа зоны. '
          'Если боль сильная, с температурой или нарастает — напишите врачу в чат специалиста, не ждите. Могу перевести.';
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('всё лицо') ||
            q.contains('все лицо') ||
            q.contains('целым лицом') ||
            (q.contains('полн') && q.contains('лиц')))) {
      return '«Всё лицо» ботулином считают по зонам и единицам — прайс зависит от схемы врача, не от одной кнопки. '
          'Честный путь: консультация, разметка и смета. Могу записать на осмотр или назвать ориентир по одной зоне, если скажете какой.';
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('на сколько') ||
            q.contains('сколько держ') ||
            q.contains('как долго') ||
            q.contains('хватает') ||
            q.contains('хватит') ||
            q.contains('через сколько пройдет') ||
            q.contains('через сколько пройдёт')) &&
        !q.contains('трогать') &&
        !q.contains('трогать') &&
        !q.contains('нельзя трог') &&
        !q.contains('массир') &&
        !q.contains('размин')) {
      return 'Эффект ботулина обычно на месяцы — у кого-то ближе к трём, у кого-то дольше, зона и доза решают. '
          '«Каменное» лицо не цель: на осмотре держат естественную мимику. Запишем консультацию?';
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('единиц') ||
            q.contains('сколько ед') ||
            (q.contains('скольк') &&
                (q.contains('на лоб') ||
                    q.contains('на глаз') ||
                    q.contains('нужно'))))) {
      return 'Единицы ботулина считает врач по мышцам и мимике — «среднее на лоб» без осмотра не обещаю. '
          'В прайсе ориентир по зоне, итог после разметки. Запишем консультацию по лбу или глазам?';
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('красит') || q.contains('макияж') || q.contains('тональн')) &&
        (q.contains('скольк') ||
            q.contains('нельзя') ||
            q.contains('когда') ||
            q.contains('после'))) {
      return 'После ботулина макияж на зону обычно откладывают минимум на сутки — точнее скажет врач; в день процедуры без плотного тона. '
          'Когда кололи или планируете?';
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('скольк') || q.contains('цен') || q.contains('стоит')) &&
        !q.contains('хватает') &&
        !q.contains('хватит') &&
        !q.contains('держ') &&
        !q.contains('единиц') &&
        !q.contains('красит') &&
        !q.contains('макияж') &&
        !q.contains('вино') &&
        !q.contains('алкогол') &&
        !q.contains('пить') &&
        !q.contains('выпить') &&
        !q.contains('нельзя') &&
        !q.contains('массаж') &&
        !q.contains('вместе')) {
      final botox = _clinicService('ботулинотерап', gender: gender);
      if (botox != null) {
        return 'По ботулинотерапии ориентир из прайса — ${botox.priceLabel}, ${botox.duration}. '
            'Итог по единицам и зонам утверждает врач на осмотре. Запишем консультацию или сразу зону?';
      }
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        q.contains('массаж') &&
        (q.contains('скольк') || q.contains('стоит') || q.contains('цен') || q.contains('вместе'))) {
      final botox = _clinicService('ботулинотерап', gender: gender);
      final massage = _clinicService('скульптурн', gender: gender) ??
          _clinicService('массаж', gender: gender);
      final b = botox == null ? 'ботулинотерапия' : '${botox.title} — ориентир ${botox.priceLabel}';
      final m = massage == null ? 'скульптурный массаж' : '${massage.title} — ориентир ${massage.priceLabel}';
      return 'По отдельности: $b; $m. Вместе в один визит — не всегда: порядок и допуск решает врач. '
          'Запишем консультацию или два окна отдельно?';
    }

    if ((q.contains('шелуш') || q.contains('облазит') || q.contains('лезет кож')) &&
        (q.contains('после пилинг') ||
            q.contains('после кислот') ||
            q.contains('после чистк') ||
            q.contains('после процедур'))) {
      return 'Лёгкое шелушение после пилинга или кислот — часто норма на несколько дней: не сдирайте, увлажняйте барьером, SPF обязателен. '
          'Если жжение сильное, отёк или гной — это уже к врачу в чат. Могу подсказать барьерный крем из шопа.';
    }

    if ((q.contains('горит') ||
            q.contains('жжет') ||
            q.contains('жжёт') ||
            q.contains('печет') ||
            q.contains('печёт')) &&
        !q.contains('сожж') &&
        !q.contains('сожг') &&
        !q.contains('сгорит') &&
        !(q.contains('боюсь') && (q.contains('rf') || q.contains('рф') || q.contains('аппарат'))) &&
        (q.contains('кислот') ||
            q.contains('ретинол') ||
            q.contains('после пилинг') ||
            q.contains('кож') ||
            q.contains('лицо'))) {
      return 'Если кожа горит после кислоты или ретинола — активы стоп, холодная вода без щёток, плотный барьерный крем, без сауны и солнца. '
          'Могу положить в корзину Lumen Barrier или перевести к врачу, если жжение не стихает. Как сейчас — терпимо или нарастает?';
    }

    if (q.contains('натощак') &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц'))) {
      return 'На капельницу обычно достаточно лёгкого приёма пищи и воды — жёсткий «голодный» режим как перед анализами чаще не нужен. '
          'Точную подготовку скажут при записи; если есть хронические болезни — предупредите врача. Запишем Beauty & Glow, NAD+ или другую?';
    }

    if ((q.contains('дорог') ||
            q.contains('путешеств') ||
            q.contains('в самолёт') ||
            q.contains('в отпуск') ||
            q.contains('отпуск')) &&
        (q.contains('шоп') ||
            q.contains('крем') ||
            q.contains('сыворот') ||
            q.contains('взять') ||
            q.contains('с собой') ||
            q.contains('кож'))) {
      return 'В дорогу из шопа обычно берут компактное: барьерный крем и пептидную сыворотку — меньше стресса кожи в самолёте и отеле. '
          'Могу положить Lumen Barrier или Veil Peptide в корзину. Что ближе — крем или сыворотка?';
    }

    if (q.contains('имплант') &&
        (q.contains('массаж') || q.contains('тело') || q.contains('груд'))) {
      return 'При имплантах груди массаж тела и аппаратные на зону груди только после допуска врача — технику и давление подбирают очно. '
          'Лицо и ноги чаще без ограничений по имплантам. Могу открыть чат врача или записать на консультацию.';
    }

    if (q.contains('тускл') &&
        !q.contains('мероприя') &&
        !q.contains('свадьб') &&
        !q.contains('перед ') &&
        !q.contains('к вечеру') &&
        !q.contains('на выход')) {
      return 'Тусклый тон часто отвечает на влагу и мягкое обновление: уход HydraPure или скульптурный массаж, дома — барьер и пептиды; пилинг — если фототип позволяет и после осмотра. '
          'Хотите освежить к дате или наладить спокойный курс?';
    }

    if (q.contains('купероз') || q.contains('розацеа') || q.contains('сосудист сет')) {
      if (q.contains('загар') ||
          q.contains('загор') ||
          q.contains('солнц') ||
          q.contains('соляри')) {
        return 'При розацеа и куперозе загар и солярий обычно враги — усиливают сосуды и пятна. SPF и тень важнее «красивого цвета». '
            'Эстетику после осмотра. Запишем консультацию?';
      }
      if (q.contains('чистк') || q.contains('пилинг') || q.contains('скраб')) {
        return 'При куперозе и розацеа жёсткую чистку и агрессивные пилинги часто откладываем — сначала успокаиваем сосуды и барьер, иногда свет по допуску. '
            'Без осмотра «да, чистим» не скажу. Запишем консультацию?';
      }
      if (q.contains('капель') ||
          q.contains('инфуз') ||
          q.contains('beauty') ||
          q.contains('glow')) {
        return 'При розацеа капельницу Beauty & Glow не назначаю вслепую — сначала допуск врача, на лице без обострения; иногда важнее уход и IPL, чем инфузия. '
            'Запишем консультацию или откроем чат специалиста?';
      }
      return 'При куперозе и розацеа без агрессии: мягкий уход, SPF, без домашнего «прижигания». '
          'В клинике после осмотра иногда смотрят IPL и спокойный протокол — не в остром воспалении. Запишем консультацию или сначала крем из шопа?';
    }

    if (q.contains('мужской зал') ||
        q.contains('отдельн зал') ||
        (man && q.contains('мужск') && q.contains('есть ли'))) {
      return 'Отдельного «мужского зала» как в фитнесе нет — зато есть мужские протоколы: барбер-массаж, уход и RF без женского сценария. '
          'Запишем на консультацию или сразу на массаж?';
    }

    if ((q.contains('совмест') || q.contains('вместе') || q.contains('за один визит')) &&
        q.contains('массаж') &&
        (q.contains('уход') || q.contains('чистка') || q.contains('пилинг')) &&
        !q.contains('через') &&
        !q.contains('дней') &&
        !q.contains('недел')) {
      return 'Да, массаж и уход часто ставят в один визит — порядок скажет врач или мастер по коже. '
          'Скажите, когда удобнее, и соберём запись на подтверждение.';
    }

    if ((q.contains('синяк') || q.contains('гематом') || q.contains('синяч')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('микроиголь'))) {
      return 'Синяк после RF бывает реже, чем после уколов, но возможен — холод по схеме врача, без разминания зоны и зала несколько дней. '
          'Если пятно растёт, очень болит или с температурой — сразу врачу в чат. Могу перевести к специалисту.';
    }

    if ((q.contains('синяк') || q.contains('гематом') || q.contains('синяч')) &&
        (q.contains('филлер') ||
            q.contains('укол') ||
            q.contains('инъек') ||
            q.contains('ботокс') ||
            q.contains('мезо') ||
            q.contains('биоревитал') ||
            q.contains('после')) &&
        !q.contains('rf') &&
        !q.contains('рф') &&
        !q.contains('микроиголь')) {
      if (q.contains('боюсь') ||
          q.contains('страх') ||
          q.contains('фотосесс') ||
          q.contains('съёмк') ||
          q.contains('съемк') ||
          q.contains('к важн')) {
        return 'Синяки после мезо и уколов возможны — к важной съёмке закладывают запас в несколько дней, не колим «накануне». '
            'Можно начать с осмотра без процедуры в тот же день. Когда фотосессия?';
      }
      if (q.contains('не проход') ||
          q.contains('долго') ||
          q.contains('недел') ||
          q.contains('не сходит')) {
        return 'Синяк после уколов обычно уходит за несколько дней: холод по схеме, без разминания и зала. '
            'Если не сходит дольше недели, растёт или с температурой — к врачу в чат, не ждём. Могу перевести к специалисту.';
      }
      return 'Синяк после уколов бывает — обычно проходит за несколько дней: холод по схеме врача, без разминания и спортзала. '
          'Если растёт, очень болит или с температурой — сразу врачу в чат. Могу перевести к специалисту.';
    }

    if ((q.contains('краситься') ||
            q.contains('красить') ||
            q.contains('макияж') ||
            q.contains('тональн')) &&
        (q.contains('после') || q.contains('когда можно') || q.contains('сразу') || q.contains('вечером')) &&
        !q.contains('бров') &&
        !q.contains('волос')) {
      if (q.contains('ipl') ||
          q.contains('айпи') ||
          q.contains('lumecca') ||
          q.contains('фотоомолож')) {
        return 'После IPL макияж на зону обычно откладывают минимум на сутки, иногда дольше — кожа может быть чувствительной, SPF обязателен. '
            'Точный срок скажет врач по протоколу. Когда была вспышка?';
      }
      if (q.contains('rf') || q.contains('рф') || q.contains('микроиголь')) {
        return 'После RF макияж на зону чаще с паузой — ориентир от суток и больше, через три дня часто уже мягко, если кожа спокойная; точнее врач по протоколу. '
            'Без плотного тона и кислот, пока краснота не ушла. Когда была процедура?';
      }
      if (q.contains('массаж') || q.contains('лимфодрен')) {
        return 'После массажа макияж часто можно сразу — лучше лёгкий, без плотного тона и спиртовых средств, если кожа не красная. '
            'Когда был массаж?';
      }
      if (q.contains('чистк') || q.contains('hydrapure') || q.contains('уход')) {
        return 'После мягкой чистки или ухода макияж часто можно в тот же день, но лучше лёгкий, без плотного тона и спиртовых средств. '
            'Если кожа красная — подождите до вечера. Когда делали чистку?';
      }
      return 'После инъекций и части аппаратных макияж на зону обычно откладывают минимум на сутки — точнее скажет врач. '
          'После мягкого ухода или массажа часто можно раньше, без плотного тона в первый вечер. Что делали или планируете?';
    }

    if ((q.contains('красн') || q.contains('покрасн') || q.contains('горит') || q.contains('жжет')) &&
        (q.contains('после чистк') || (q.contains('после') && q.contains('чистк'))) &&
        (q.contains('норма') || q.contains('вечером') || q.contains('что делать'))) {
      return 'Лёгкое покраснение после чистки вечером часто норма — мягкое умывание, барьерный крем, без кислот и сауны. '
          'Если жжение сильное, отёк или гной — к врачу в чат. Могу положить Lumen Barrier или открыть чат.';
    }

    // q is normalized: ё → е
    if ((q.contains('отек') || q.contains('отёк')) &&
        !q.contains('массаж') &&
        (q.contains('после') ||
            q.contains('укол') ||
            q.contains('филлер') ||
            q.contains('инъек') ||
            q.contains('ботокс')) &&
        (q.contains('сильн') ||
            q.contains('больш') ||
            q.contains('асимметр') ||
            q.contains('что делать') ||
            q.contains('филлер') ||
            q.contains('укол'))) {
      return 'Отёк после филлера или уколов на 1–3 дня бывает: голова выше подушки, без соли и алкоголя, холод по схеме врача, зону не массируем. '
          'Если отёк сильный, асимметричный или нарастает — сразу врачу в чат, не ждём. Могу перевести к специалисту.';
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('филлер') || q.contains('гиалурон')) &&
        (q.contains('совмест') ||
            q.contains('вместе') ||
            q.contains('за один') ||
            q.contains('и филлер') ||
            q.contains('или филлер'))) {
      return 'Ботулин и филлер иногда делают в один визит, иногда с паузой — решает врач по зонам и отёку. '
          'Без осмотра «да, всегда вместе» не обещаю. Запишем консультацию и разложим план.';
    }

    if (q.contains('гиалурон') &&
        (q.contains('рассос') ||
            q.contains('сколько держ') ||
            q.contains('как долго') ||
            q.contains('через сколько') ||
            q.contains('надолго'))) {
      return 'Гиалуроновые филлеры обычно держатся от нескольких месяцев до года-полутора — зона и плотность препарата решают. '
          'Если нужно ускорить рассасывание — это уже очно у врача, не дома. Могу записать на консультацию.';
    }

    if (q.contains('герпес') &&
        (q.contains('анамнез') ||
            q.contains('раньше') ||
            q.contains('бывает') ||
            q.contains('когда-то') ||
            q.contains('в анамнез'))) {
      return 'Если герпес в анамнезе, а сейчас губы спокойные — часто делают с профилактикой по схеме врача; при активных пузырьках процедуру откладываем. '
          'На осмотре обязательно скажите про герпес. Запишем консультацию?';
    }

    if (q.contains('герпес') &&
        (q.contains('на теле') ||
            q.contains('на спине') ||
            q.contains('не на лице') ||
            (q.contains('теле') && q.contains('лицо')))) {
      return 'Если герпес не на лице и зона лица спокойная — часть протоколов на лице возможна после осмотра; активную сыпь на теле всё равно скажите врачу. '
          'При пузырьках у рта процедуры в зоне откладываем. Могу открыть чат специалиста.';
    }

    if (q.contains('герпес') &&
        !q.contains('анамнез') &&
        !q.contains('на теле') &&
        (q.contains('пилинг') ||
            q.contains('чистка') ||
            q.contains('инъек') ||
            q.contains('мезо') ||
            q.contains('филлер') ||
            q.contains('можно'))) {
      return 'При активном герпесе пилинги, чистки и инъекции в зоне обычно откладываем — сначала гасим пузырьки по схеме врача. '
          'Иногда перед губными процедурами дают профилактику. Напишите врачу в чат или запишем осмотр, когда стихнет.';
    }

    if ((q.contains('после rf') ||
            q.contains('после рф') ||
            (q.contains('rf') && q.contains('после')) ||
            (q.contains('микроиголь') && q.contains('после'))) &&
        (q.contains('бан') ||
            q.contains('саун') ||
            q.contains('хамам') ||
            q.contains('бассейн') ||
            q.contains('спорт'))) {
      return 'После RF обычно пауза на баню, сауну и жёсткий спорт несколько дней — кожа восстанавливается, лишний жар не нужен. '
          'Точный срок скажет врач по вашему протоколу. Когда была процедура?';
    }

    if ((q.contains('диабет') || q.contains('сахарн диабет')) &&
        (q.contains('мезо') ||
            q.contains('биоревитал') ||
            q.contains('филлер') ||
            q.contains('ботокс') ||
            q.contains('инъек'))) {
      return 'При диабете мезо и другие инъекции только после допуска врача — заживление и сахар учитываем очно, без самозаписи. '
          'Могу открыть чат специалиста или записать на консультацию.';
    }

    if ((q.contains('мезотерап') || q.contains('биоревитал') || q.contains('после мезо')) &&
        (q.contains('уход') ||
            q.contains('после') ||
            q.contains('нельзя') ||
            q.contains('можно') ||
            q.contains('папул') ||
            q.contains('целов') ||
            q.contains('поцелу')) &&
        !q.contains('как часто') &&
        !q.contains('интервал') &&
        !q.contains('между курс') &&
        !q.contains('месячн') &&
        !q.contains('цикл') &&
        !q.contains('критическ') &&
        !q.contains('менструац') &&
        !q.contains('рук') &&
        !q.contains('кист') &&
        !q.contains('самолет') &&
        !q.contains('перелет') &&
        !q.contains('лететь') &&
        !q.contains('летать') &&
        !q.contains('диабет') &&
        !(q.contains('совмест') || q.contains('совмещ') || q.contains('вместе с')) &&
        !(q.contains('пилинг') && (q.contains('биоревитал') || q.contains('мезо')))) {
      if (q.contains('целов') || q.contains('поцелу') || q.contains('целовать')) {
        return 'После биоревитализации и мезо поцелуи лучше мягко на сутки — меньше раздражения папул; без разминания зоны. '
            'Точный лист у врача. Когда кололи?';
      }
      if (q.contains('папул') || q.contains('бугорк') || q.contains('шишечк')) {
        return 'Папулы после мезо и биоревитализации часто держатся от часов до пары дней — не давим и не скрабим. '
            'Если краснота и боль нарастают — к врачу. Могу открыть чат специалиста.';
      }
      return 'После мезо и биоревитализации обычно: без сауны и бассейна пару дней, мягкий умывание, барьерный крем, SPF, без кислот и скрабов, пока врач не разрешит. '
          'Папулы и лёгкая краснота часто проходят сами. Если жжение сильное — в чат специалисту.';
    }

    if ((q.contains('без укол') ||
            q.contains('безъинъек') ||
            q.contains('безынек') ||
            q.contains('без инек') ||
            q.contains('без игол') ||
            q.contains('боюсь игл') ||
            q.contains('боюсь иголка') ||
            q.contains('боюсь иглы')) &&
        (q.contains('лифтинг') ||
            q.contains('овал') ||
            q.contains('подтя') ||
            q.contains('есть ли') ||
            q.contains('что есть')) &&
        !q.contains('капель') &&
        !q.contains('инфуз') &&
        !q.contains('капельниц')) {
      return 'Без уколов тоже есть путь: скульптурный массаж, уходы и при необходимости микроигольчатый RF после осмотра — лифтинг-эффект без «шприца в губы». '
          'С чего спокойнее начать — массаж или консультация по RF?';
    }

    // Generic «сколько стоит / длится консультация» — not a named live-service title.
    if ((q.contains('консультац') || q.contains('прием врача') || q.contains('приём врача')) &&
        (q.contains('скольк') ||
            q.contains('стоит') ||
            q.contains('цен') ||
            q.contains('длится') ||
            q.contains('по времени')) &&
        !q.contains('cult') &&
        (q.contains('врач') ||
            q.contains('прием') ||
            q.contains('приём') ||
            q.contains('косметолог') ||
            q.trim().split(RegExp(r'\s+')).length <= 5)) {
      if (q.contains('длится') || q.contains('по времени') || q.contains('сколько идёт') || q.contains('сколько идет')) {
        return 'Консультация косметолога обычно короткий визит — ориентир 20–40 минут на осмотр и план, без спешки. '
            'Иногда в тот же день решают делать мягкий уход. Запишем окно?';
      }
      return 'Консультация косметолога — короткий осмотр и план; цену из филиала могу подсказать, если скажете «консультация» как услугу из прайса, '
          'или откроем карточку врача и запишем. Часто первый шаг — осмотр без процедуры в тот же день.';
    }

    if (q.contains('постоянн клиент') ||
        q.contains('программ лояльн') ||
        q.contains('для постоянн') ||
        q.contains('карта клиент') ||
        (q.contains('лояльн') && !q.contains('кэшбек') && !q.contains('кешбек'))) {
      return 'Для постоянных клиентов — бонусы CULT в профиле: welcome новым, дальше начисление и списание с чека (на платине до 30%). '
          'Пакеты курсов обсуждают на консультации. Могу перевести к администратору за деталями карты.';
    }

    if (q.contains('псориаз')) {
      if (q.contains('ремис') && (q.contains('пилинг') || q.contains('можно'))) {
        return 'В ремиссии псориаза пилинг иногда обсуждают после допуска дерматолога или нашего врача — не в обострение и не агрессивно. '
            'Без осмотра «да» не скажу. Запишем консультацию?';
      }
      return 'При псориазе лицо и эстетику трогаем только после допуска врача, часто дерматолога — даже если бляшки на локтях, системно кожа может быть реактивной. '
          'Могу открыть чат специалиста или записать на консультацию. Сейчас обострение?';
    }

    if (q.contains('экзем') ||
        q.contains('атопическ') ||
        q.contains('дерматит')) {
      if ((q.contains('рук') || q.contains('локте') || q.contains('теле')) &&
          (q.contains('лицо') || q.contains('лиц')) &&
          (q.contains('порядке') ||
              q.contains('спокойн') ||
              q.contains('не на лице') ||
              q.contains('пилинг'))) {
        return 'Если экзема на руках, а лицо спокойное — пилинг на лицо иногда возможен после осмотра, без агрессии и не в обострение. '
            'Руки в этот день лучше не травмировать кислотами. Запишем консультацию?';
      }
      return 'При экземе и дерматите без самодеятельности: сначала успокаиваем барьер, эстетику — только после допуска врача, часто дерматолога. '
          'Могу записать на консультацию или перевести в чат специалиста. Сейчас обострение или ремиссия?';
    }

    if (q.contains('заменишь врача') ||
        q.contains('замените врача') ||
        q.contains('вместо врача') ||
        q.contains('ты вместо врача') ||
        (q.contains('замен') && q.contains('врач'))) {
      return 'Нет — я не заменяю врача. Помогаю сориентироваться, записать и подсказать уход; осмотр, диагноз и назначения — только очно у специалиста. '
          'Могу открыть чат врача или собрать запись на консультацию.';
    }

    if ((q.contains('есть') || q.contains('есть ли') || q.contains('нельзя есть') || q.contains('диета')) &&
        (q.contains('перед капель') ||
            q.contains('перед инфуз') ||
            q.contains('до капель') ||
            q.contains('перед капельниц'))) {
      return 'Перед капельницей обычно лёгкий приём пищи и вода — жёсткой диеты «ничего с вечера» чаще не нужно. '
          'Алкоголь лучше убрать накануне. Точную подготовку подтвердят при записи под вашу капельницу.';
    }

    if (q.contains('температур') &&
        !q.contains('без температур') &&
        (q.contains('массаж') || q.contains('процедур') || q.contains('можно'))) {
      return 'При температуре и остром недомогании массаж и большинство процедур лучше перенести — так спокойнее для вас и для заживления. '
          'Перенесём через администратора или скажите, когда станет легче — подберём окно.';
    }

    if ((q.contains('простуд') || q.contains('орви') || q.contains('насморк')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('филлер') || q.contains('инъек'))) {
      return 'При ОРВИ и простуде ботулин и филлеры обычно откладываем — даже без температуры организм уже нагружен, риск отёка и слабого ответа выше. '
          'Когда выздоровеете — запишем. Как самочувствие сейчас?';
    }

    if ((q.contains('простуд') || q.contains('орви') || q.contains('насморк')) &&
        (q.contains('массаж') || q.contains('процедур') || q.contains('можно')) &&
        (q.contains('без температур') || !q.contains('температур'))) {
      return 'При простуде без температуры массаж иногда допустим, если самочувствие ровное и нет острого недомогания — решает специалист. '
          'При слабости, кашле или только что начавшейся простуде лучше перенести. Как вы себя чувствуете сейчас?';
    }

    if ((q.contains('подготов') || q.contains('как готов')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('микроиголь'))) {
      return 'К RF обычно: без загара и агрессивных кислот несколько дней, без плотного макияжа в день визита, сообщите аллергии и герпес в анамнезе. '
          'Точный лист даст врач после записи. Запишем консультацию или сразу протокол?';
    }

    if (q.contains('почему') &&
        (q.contains('стягив') || q.contains('после умыван') || q.contains('после умывания'))) {
      return 'Стянутость после умывания часто значит, что барьер сухой или средство слишком щелочное. '
          'Мягкое умывание, сразу крем-барьер, без спиртовых тоников. Могу положить Lumen Barrier в корзину или записать на увлажняющий уход.';
    }

    if ((q.contains('загар') ||
            q.contains('загор') ||
            q.contains('солнц') ||
            q.contains('соляри')) &&
        (q.contains('после пилинг') ||
            q.contains('после кислот') ||
            q.contains('после ipl') ||
            q.contains('после lumecca') ||
            (q.contains('после') && (q.contains('пилинг') || q.contains('кислот'))))) {
      return 'После пилинга и света загар и солярий обычно на паузе 1–2 недели, каждый день SPF 50 — иначе легко словить пятно. '
          'Точный срок даст врач по глубине. Когда была процедура?';
    }

    if ((q.contains('восстанов') ||
            q.contains('реабилитац') ||
            q.contains('сколько зажив') ||
            q.contains('сколько длит') ||
            q.contains('как долго восстанов')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('микроиголь'))) {
      return 'После микроигольчатого RF чаще несколько дней красноты и ощущения «горячей» кожи, полный комфорт — ориентир до недели-двух по протоколу. '
          'Баня и жёсткий спорт в это время не друзья. Записать на осмотр после или подсказать уход?';
    }

    if ((q.contains('купероз') || q.contains('розацеа') || q.contains('сосудист')) &&
        (q.contains('чистк') || q.contains('пилинг') || q.contains('можно'))) {
      return 'При куперозе и розацеа жёсткую чистку и агрессивные пилинги часто откладываем — сначала успокаиваем сосуды и барьер, иногда свет по допуску. '
          'Без осмотра «да, чистим» не скажу. Запишем консультацию?';
    }

    if (q.contains('мешк под глаз') ||
        q.contains('мешки под глаз') ||
        q.contains('темно под глаз') ||
        q.contains('тёмные круги') ||
        q.contains('темные круги') ||
        (q.contains('под глаз') &&
            (q.contains('убрать') || q.contains('отёк') || q.contains('отек') || q.contains('синяк') || q.contains('круг')))) {
      if (q.contains('без укол') || q.contains('без инъек') || q.contains('без филлер')) {
        return 'Тёмные круги без уколов: сон, соль, мягкий крем у глаза, скульптурный массаж и увлажняющий уход — инъекции только если сами захотите после осмотра. '
            'Запишем массаж или консультацию без процедуры?';
      }
      return 'Под глазами сначала разбираем: отёк, сосуды или тень от усталости — от этого массаж, уход или осмотр на инъекции. '
          'Дома мягко: сон, соль, крем без кислот у глаза. Могу записать на консультацию или скульптурный массаж.';
    }

    if (q.contains('что такое биоревитал') ||
        q.contains('что такое мезотерап') ||
        q.contains('биоревитализация это') ||
        q.contains('мезотерапия это') ||
        (q.contains('простыми словами') &&
            (q.contains('биоревитал') || q.contains('мезо')))) {
      return 'Простыми словами: биоревитализация и мезо — мелкие уколы увлажняющих и питательных составов в кожу, чтобы она была плотнее и спокойнее, не «накачать губы». '
          'Курс и препарат выбирает врач. Запишем осмотр или сравним с уходом без уколов?';
    }

    if ((q.contains('красить волос') ||
            q.contains('окрашив') ||
            q.contains('покрасить волос') ||
            q.contains('окраска волос')) &&
        (q.contains('пилинг') || q.contains('кислот') || q.contains('чистк'))) {
      return 'После пилинга окрашивание у корней и смывки у лица лучше отложить на несколько дней — кожа чувствительная, химия краски может усилить раздражение. '
          'Точный срок — по глубине пилинга у врача. Когда делали?';
    }

    if ((q.contains('красить волос') ||
            q.contains('окрашив') ||
            q.contains('покрасить волос') ||
            q.contains('окраска волос')) &&
        (q.contains('smas') || q.contains('смас') || q.contains('ultherap'))) {
      return 'После SMAS окрашивание волос лучше с паузой — часто ориентир от недели и больше, без жёсткого пара у лица и агрессивных смывок; точный срок у врача. '
          'Когда была процедура?';
    }

    // «После ботокса … пилинг через две недели» — not event/weekish situation.
    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        q.contains('пилинг') &&
        (q.contains('через') || q.contains('недел') || q.contains('дней') || q.contains('можно'))) {
      return 'Ботулин и пилинг через 1–2 недели часто уже обсуждают как рабочий интервал — в один день обычно не ставят; точный порядок и паузу решает врач по зонам и заживлению. '
          'Запишем консультацию — разложим календарь под ваши даты.';
    }

    if (q.contains('пилинг') &&
        q.contains('массаж') &&
        (q.contains('через') || q.contains('дней') || q.contains('недел')) &&
        (q.contains('совмест') || q.contains('можно'))) {
      return 'Пилинг и массаж через несколько дней часто уже дружат, если краснота ушла — в один день кислоты и интенсивный массаж зоны обычно не ставят. '
          'Запишем консультацию — скажем безопасный интервал.';
    }

    if ((q.contains('красить волос') ||
            q.contains('окрашив') ||
            q.contains('покрасить волос') ||
            q.contains('окраска волос')) &&
        (q.contains('ботокс') ||
            q.contains('филлер') ||
            q.contains('после') ||
            q.contains('можно')) &&
        !q.contains('smas') &&
        !q.contains('смас')) {
      return 'Окрашивание волос обычно не мешает ботулину и филлерам, если не трёте и не греете зону уколов в первые дни. '
          'Смывки у лица и жёсткий пар — лучше подождать. Когда была процедура?';
    }

    if (q.contains('шея обвисл') ||
        (q.contains('дрябл') &&
            (q.contains('шея') || q.contains('шеи') || q.contains('шею'))) ||
        q.contains('кольца венеры') ||
        q.contains('морщины на шее') ||
        (q.contains('шея') &&
            (q.contains('подтя') || q.contains('лифтинг') || q.contains('убрать')))) {
      return 'По шее и декольте часто начинают с ухода и массажа, при необходимости — аппаратный протокол после осмотра, без обещаний «как после операции». '
          'Запишем консультацию или скульптурный массаж с акцентом на шею?';
    }

    if ((q.contains('расширен') && q.contains('пор')) ||
        q.contains('поры на носу') ||
        q.contains('большие поры') ||
        (q.contains('поры') && (q.contains('сузить') || q.contains('убрать') || q.contains('чистк')))) {
      return 'Поры не «закрываются навсегда», но блеск и рельеф можно успокоить: мягкая чистка или пилинг по типу кожи, дома — барьер и без жёсткого спирта. '
          'Запишем осмотр или положить сыворотку в корзину?';
    }

    if ((q.contains('кофе') || q.contains('чай') || q.contains('есть ли запрет')) &&
        (q.contains('перед капель') ||
            q.contains('до капель') ||
            q.contains('перед инфуз') ||
            q.contains('перед капельниц'))) {
      return 'Перед капельницей обычно можно лёгкий завтрак и воду; кофе лучше не натощак и без перебора — ориентир даст администратор под ваш состав. '
          'Алкоголь накануне убираем. Запишем капельницу?';
    }

    if ((q.contains('капель') || q.contains('инфуз')) &&
        (q.contains('массаж') || q.contains('уход')) &&
        (q.contains('совмест') ||
            q.contains('вместе') ||
            q.contains('в один') ||
            q.contains('и массаж') ||
            q.contains('можно ли'))) {
      return 'Капельницу и массаж иногда ставят в один визит, если самочувствие ровное и так решил врач или администратор по слоту. '
          'Не всегда подряд без паузы. Скажите, что важнее первым — силы или тело?';
    }

    if ((q.contains('болит голов') || q.contains('головная боль') || q.contains('мигрень')) &&
        (q.contains('после ботокс') ||
            q.contains('после укол') ||
            q.contains('после ботулин') ||
            (q.contains('после') && q.contains('ботокс')))) {
      return 'Лёгкая головная боль после ботулина бывает в первые сутки — отдых, вода, без разминания зоны. '
          'Если боль сильная, с температурой или нарастает — сразу врачу в чат. Могу открыть чат специалиста.';
    }

    if (q.contains('беремен') &&
        (q.contains('массаж') || q.contains('лица') || q.contains('уход')) &&
        !q.contains('акне')) {
      return 'В беременность многие аппаратные и инъекции под запретом; мягкий уход и некоторые массажи — только после допуска врача. '
          'Без осмотра не записываю «на всё». Могу открыть чат врача или консультацию.';
    }

    if (q.contains('родинк') ||
        q.contains('невус') ||
        q.contains('новообразован') ||
        (q.contains('родин') && q.contains('можно'))) {
      return 'Родинки и новообразования не трогаем косметологией вслепую — сначала оценка врача, при сомнении дерматолог. '
          'Пилинги и аппаратные в зоне родинок обсуждают очно. Могу записать на консультацию.';
    }

    if (q.contains('можно ли совместить') ||
        q.contains('можно совместить') ||
        (q.contains('совмест') && q.contains('rf') && q.contains('массаж'))) {
      if (q.contains('чистк') && q.contains('пилинг')) {
        if (q.contains('через') || q.contains('недел') || q.contains('дней')) {
          return 'Чистку и пилинг через неделю часто уже обсуждают как рабочий интервал — в один день не всегда ставят; коже нужна пауза под тип и глубину. '
              'Запишем осмотр — разложим календарь под вашу кожу.';
        }
        return 'Чистку и пилинг в один день ставят не всегда — зависит от типа кожи и глубины. Часто разводят по визитам или делают мягкую связку по решению врача. '
            'Запишем осмотр — скажем, дружат ли они у вас.';
      }
      if ((q.contains('ipl') || q.contains('айпи') || q.contains('lumecca')) &&
          q.contains('пилинг')) {
        return 'IPL и пилинг в один день ставят редко — коже нужна пауза, иначе легко перегрузить барьер. Порядок и интервал решает врач по фототипу. '
            'Запишем консультацию — разложим безопасную связку.';
      }
      if ((q.contains('ipl') || q.contains('айпи') || q.contains('lumecca')) &&
          (q.contains('чистк') || q.contains('чистка'))) {
        return 'IPL и чистку в один день ставят не всегда — после света кожа чувствительная, жёсткое очищение часто разносят. Порядок решает врач по фототипу. '
            'Запишем консультацию — скажем, дружат ли они у вас.';
      }
      if ((q.contains('ipl') || q.contains('айпи') || q.contains('lumecca')) &&
          q.contains('массаж')) {
        return 'IPL и массаж иногда разносят по дням — после света кожа чувствительная; мягкий массаж позже часто ок по решению врача. '
            'Запишем консультацию — скажем порядок.';
      }
      if ((q.contains('ботокс') || q.contains('ботулин')) &&
          (q.contains('beauty') || q.contains('glow') || q.contains('капель') || q.contains('инфуз')) &&
          (q.contains('через') || q.contains('недел') || q.contains('дней'))) {
        return 'Ботулин и Beauty & Glow / капельницу через неделю часто уже обсуждают как рабочий интервал — в один день обычно не ставят без решения врача. '
            'Запишем консультацию — разложим календарь под ваши даты.';
      }
      if ((q.contains('ботокс') || q.contains('ботулин')) &&
          (q.contains('beauty') || q.contains('glow') || q.contains('капель') || q.contains('инфуз'))) {
        return 'Ботулин и капельницу в один день ставят не всегда — зависит от самочувствия и решения врача; часто разносят визиты. '
            'Запишем консультацию — скажем порядок.';
      }
      if (q.contains('массаж') &&
          q.contains('лиц') &&
          q.contains('тел') &&
          (q.contains('совмест') || q.contains('один день') || q.contains('вместе'))) {
        return 'Массаж лица и тела в один день часто ставят подряд или с короткой паузой — если самочувствие ровное и есть окна. '
            'Администратор поможет собрать слоты. Запишем оба?';
      }
      if ((q.contains('ботокс') || q.contains('ботулин')) && q.contains('пилинг')) {
        if (q.contains('через') || q.contains('недел') || q.contains('дней')) {
          return 'Ботулин и пилинг через 1–2 недели часто уже обсуждают как рабочий интервал — в один день обычно не ставят; точный порядок и паузу решает врач по зонам и заживлению. '
              'Запишем консультацию — разложим календарь под ваши даты.';
        }
        return 'Ботулин и пилинг в один день обычно не ставят — нужна пауза под заживление и чтобы не смещать зоны. Порядок скажет врач. '
            'Запишем консультацию — разложим, что первым.';
      }
      if ((q.contains('чистк') || q.contains('чистка')) && q.contains('массаж')) {
        return 'Чистку и массаж в один день часто ставят, если кожа спокойная — сначала очищение, потом мягкая скульптура, или наоборот по решению мастера. '
            'Запишем оба окна?';
      }
      if (q.contains('пилинг') &&
          q.contains('массаж') &&
          (q.contains('через') || q.contains('дней') || q.contains('недел'))) {
        return 'Пилинг и массаж через несколько дней часто уже дружат, если краснота ушла — в один день кислоты и интенсивный массаж зоны обычно не ставят. '
            'Запишем консультацию — скажем безопасный интервал.';
      }
      if ((q.contains('rf') || q.contains('рф') || q.contains('микроиголь')) &&
          (q.contains('ботокс') || q.contains('ботулин'))) {
        return 'RF и ботулин иногда ставят в разных визитах — в один день только если так решит врач по зонам и отёку. '
            'Запишем консультацию — разложим порядок.';
      }
      if ((q.contains('ipl') || q.contains('айпи') || q.contains('lumecca')) &&
          (q.contains('ботокс') || q.contains('ботулин'))) {
        return 'IPL и ботулин через 1–2 недели часто уже обсуждают как рабочий интервал — в один день обычно не ставят; точный порядок и паузу решает врач по зонам. '
            'Запишем консультацию — разложим календарь под ваши даты.';
      }
      if ((q.contains('smas') || q.contains('смас') || q.contains('ultherap')) &&
          (q.contains('ботокс') || q.contains('ботулин'))) {
        return 'SMAS и ботулин через месяц часто уже совместимы по календарю — в один день обычно не ставят; порядок и паузу решает врач по зонам и отёку. '
            'Запишем консультацию — разложим даты под ваш план.';
      }
      if ((q.contains('rf') || q.contains('рф') || q.contains('микроиголь')) &&
          q.contains('массаж')) {
        return 'RF и массаж в один день ставят не всегда: после RF кожа чувствительная, массаж зоны чаще с паузой по решению врача. '
            'Иногда мягкий массаж до RF в том же визите. Запишем консультацию — скажем порядок.';
      }
      if ((q.contains('консультац') || q.contains('осмотр')) &&
          (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц'))) {
        return 'Консультацию врача и капельницу часто ставят в один визит: сначала короткий осмотр и опрос, затем инфузия, если нет противопоказаний. '
            'Запишем окно с запасом — администратор соберёт слоты.';
      }
      if ((q.contains('консультац') || q.contains('осмотр')) &&
          (q.contains('процедур') ||
              q.contains('уход') ||
              q.contains('массаж') ||
              q.contains('пилинг') ||
              q.contains('чистк'))) {
        return 'Консультацию и мягкую процедуру часто делают в один визит, если есть окно и нет противопоказаний — решает врач на месте. '
            'Инъекции и тяжёлую аппаратную иногда разносят. Запишем осмотр с запасом времени?';
      }
      if ((q.contains('чистк') || q.contains('чистка')) &&
          (q.contains('rf') || q.contains('рф') || q.contains('микроиголь'))) {
        return 'Чистку и RF через неделю часто уже обсуждают как рабочий интервал — в один день обычно не ставят; коже нужна пауза, порядок решает врач. '
            'Запишем консультацию — разложим календарь под ваши даты.';
      }
      if (q.contains('пилинг') &&
          (q.contains('биоревитал') || q.contains('мезотерап') || q.contains('мезо'))) {
        return 'Пилинг и биоревитализацию/мезо редко ставят в один день — чаще разносят, чтобы кожа успела успокоиться; порядок решает врач. '
            'Запишем осмотр и соберём спокойный план по датам?';
      }
      if ((q.contains('beauty') || q.contains('glow') || q.contains('nad') || q.contains('immunity') || q.contains('капель') || q.contains('инфуз')) &&
          q.contains('массаж') &&
          !q.contains('лимфодрен')) {
        return 'Beauty & Glow / капельницу и массаж часто ставят в один визит, если самочувствие ровное — порядок скажет врач или админ по слоту. '
            'Что важнее первым — силы или тело?';
      }
      if ((q.contains('лимфодрен') || (q.contains('массаж') && q.contains('лимф'))) &&
          (q.contains('rf') || q.contains('рф') || q.contains('микроиголь'))) {
        return 'Лимфодренаж и RF через 1–2 недели часто уже обсуждают как рабочий интервал — в один день обычно не ставят; коже нужна пауза. '
            'Запишем консультацию — разложим календарь.';
      }
      final wantsTwoIv = (q.contains('nad') && (q.contains('beauty') || q.contains('glow') || q.contains('immunity'))) ||
          ((q.contains('beauty') || q.contains('glow')) && q.contains('immunity')) ||
          (q.contains('две капель') || q.contains('две инфуз'));
      if (wantsTwoIv) {
        return 'Две капельницы в один день ставят не всегда — зависит от составов, самочувствия и решения врача; NAD+ и Beauty & Glow иногда разносят. '
            'Запишем консультацию по инфузиям — скажем, дружат ли они у вас.';
      }
      if ((q.contains('hydrapure') || q.contains('hydra') || q.contains('гидрапур')) &&
          (q.contains('капель') || q.contains('инфуз'))) {
        return 'HydraPure и капельницу часто ставят в один визит, если самочувствие ровное — уход на лицо и инфузия по силам; порядок скажет врач или админ по слоту. '
            'Что важнее первым — кожа или энергия?';
      }
      if ((q.contains('чистк') || q.contains('чистка')) &&
          (q.contains('ботокс') || q.contains('ботулин'))) {
        if (q.contains('через') || q.contains('недел') || q.contains('дней')) {
          return 'Чистку и ботулин через 1–2 недели часто уже обсуждают как рабочий интервал — в один день обычно не ставят; сначала успокаиваем кожу. '
              'Запишем консультацию — разложим порядок под ваши даты.';
        }
        return 'Чистку и ботулин в один день обычно не ставят — сначала успокаиваем кожу, уколы с паузой по решению врача. '
            'Запишем консультацию — разложим порядок.';
      }
      if (q.contains('массаж') &&
          (q.contains('ботокс') || q.contains('ботулин'))) {
        return 'Массаж и ботулин в один день обычно не ставят — зону уколов не разминают; массаж чаще до курса или через паузу по листу врача. '
            'Запишем консультацию — разложим порядок.';
      }
      if ((q.contains('smas') || q.contains('смас') || q.contains('ultherap')) &&
          q.contains('массаж')) {
        return 'SMAS и массаж часто дружат с паузой: массаж мягко позже, когда кожа успокоилась — через недели по решению врача, не в день SMAS. '
            'Запишем консультацию — разложим календарь.';
      }
      if ((q.contains('smas') || q.contains('смас') || q.contains('ultherap')) &&
          q.contains('пилинг')) {
        if (q.contains('через') || q.contains('месяц') || q.contains('недел') || q.contains('дней')) {
          return 'SMAS и пилинг через месяц часто уже обсуждают как рабочий интервал — в один день не ставят; коже нужна пауза, порядок решает врач. '
              'Запишем консультацию — разложим безопасный календарь.';
        }
        return 'SMAS и пилинг в один день обычно не ставят — коже нужна пауза под восстановление. '
            'Запишем консультацию — скажем интервал.';
      }
      if ((q.contains('мезо') || q.contains('биоревитал')) &&
          q.contains('массаж')) {
        if (q.contains('через') || q.contains('недел') || q.contains('дней')) {
          return 'Мезо/биоревитал и массаж через неделю часто уже обсуждают как рабочий интервал — зону уколов не разминают сразу; порядок решает врач. '
              'Запишем консультацию — разложим календарь.';
        }
        return 'Мезо/биоревитал и массаж в один день обычно не ставят — папулы и зону не массируем. '
            'Запишем консультацию — скажем паузу.';
      }
      if (q.contains('филлер') && q.contains('массаж')) {
        if (q.contains('через') || q.contains('недел') || q.contains('дней') || q.contains('десят')) {
          return 'Филлер и массаж через 7–10 дней часто уже обсуждают как рабочий интервал — зону уколов сразу не разминают; точный срок на листе врача. '
              'Запишем консультацию — разложим календарь под ваши даты.';
        }
        return 'Филлер и массаж в один день обычно не ставят — зону уколов не массируем, пока врач не разрешит. '
            'Запишем консультацию — скажем паузу.';
      }
      if ((q.contains('лимфодрен') || q.contains('массаж')) &&
          (q.contains('капель') || q.contains('инфуз'))) {
        return 'Лимфодренаж/массаж и капельницу часто ставят в один визит, если самочувствие ровное — порядок скажет врач или админ по слоту. '
            'Что важнее первым — тело или силы?';
      }
      if ((q.contains('rf') || q.contains('рф') || q.contains('микроиголь')) &&
          q.contains('пилинг')) {
        if (q.contains('через') || q.contains('дней') || q.contains('недел')) {
          return 'RF и пилинг через 7–10 дней часто уже обсуждают как рабочий интервал — в один день обычно не ставят; коже нужна пауза, порядок решает врач. '
              'Запишем консультацию — разложим безопасный календарь.';
        }
        return 'RF и пилинг в один день ставят редко — коже нужна пауза под восстановление; порядок и интервал решает врач. '
            'Запишем консультацию — скажем, через сколько можно кислоты.';
      }
      if ((q.contains('чистк') || q.contains('чистка')) &&
          (q.contains('ботокс') || q.contains('ботулин'))) {
        if (q.contains('через') || q.contains('недел') || q.contains('дней')) {
          return 'Чистку и ботулин через 1–2 недели часто уже обсуждают как рабочий интервал — в один день обычно не ставят; сначала успокаиваем кожу. '
              'Запишем консультацию — разложим порядок под ваши даты.';
        }
        return 'Чистку и ботулин в один день обычно не ставят — сначала успокаиваем кожу, уколы с паузой по решению врача. '
            'Запишем консультацию — разложим порядок.';
      }
      if ((q.contains('шоп') || q.contains('магазин') || q.contains('самовывоз')) &&
          (q.contains('процедур') || q.contains('визит') || q.contains('приём') || q.contains('прием'))) {
        return 'Да — шоп и процедуру в один визит удобно: забрать крем на ресепшен до или после кресла. '
            'Могу положить формулу в корзину и собрать запись. Что берём из шопа?';
      }
      return 'Совмещать можно не всё в один день: массаж и мягкий уход — часто да; RF и инъекции — только если так решит врач. '
          'Скажите пару процедур — скажу, дружат ли они.';
    }

    if ((q.contains('после rf') ||
            q.contains('после рф') ||
            ((q.contains('rf') || q.contains('рф') || q.contains('микроиголь')) &&
                q.contains('после'))) &&
        q.contains('пилинг')) {
      return 'После RF пилинг обычно не в тот же день — нужна пауза, пока кожа успокоится; срок скажет врач по протоколу. '
          'Запишем консультацию — разложим безопасный интервал.';
    }

    if (q.contains('первый визит') ||
        q.contains('что взять с собой') ||
        q.contains('что взять на приём') ||
        q.contains('что взять на прием') ||
        q.contains('что взять на rf') ||
        q.contains('что взять на рф') ||
        q.contains('что взять на smas') ||
        q.contains('что взять на пилинг') ||
        q.contains('что взять на лимфодрен') ||
        q.contains('что взять на ipl') ||
        q.contains('что взять на айпи') ||
        ((q.contains('что взять') || q.contains('с собой')) &&
            (q.contains('капель') ||
                q.contains('инфуз') ||
                q.contains('капельниц') ||
                q.contains('rf') ||
                q.contains('рф') ||
                q.contains('микроиголь') ||
                q.contains('ipl') ||
                q.contains('айпи') ||
                q.contains('lumecca') ||
                q.contains('smas') ||
                q.contains('смас') ||
                q.contains('ultherap') ||
                q.contains('пилинг') ||
                q.contains('лимфодрен') ||
                q.contains('массаж')))) {
      if (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц')) {
        return 'На капельницу: документ, удобная одежда с доступом к вене, вода по желанию; лучше лёгкий приём пищи заранее. '
            'Список лекарств и аллергий — врачу. Запишем Beauty & Glow, NAD+ или другую?';
      }
      if (q.contains('smas') || q.contains('смас') || q.contains('ultherap')) {
        return 'На SMAS: документ, список лекарств и аллергий, без плотного макияжа на зону; удобная одежда, вода по желанию. '
            'Остальное — на ресепшен. Запишем консультацию по SMAS сначала?';
      }
      if (q.contains('rf') || q.contains('рф') || q.contains('микроиголь')) {
        return 'На RF: документ, список лекарств и аллергий, без плотного макияжа на зону; удобная одежда. '
            'Остальное — на ресепшен. Запишем микроигольчатый RF или консультацию сначала?';
      }
      if (q.contains('ipl') || q.contains('айпи') || q.contains('lumecca')) {
        return 'На IPL: документ, список лекарств и аллергий, без плотного макияжа и автозагара на зону; SPF после вспышки обязателен. '
            'Остальное — на ресепшен. Запишем Lumecca IPL или консультацию сначала?';
      }
      if (q.contains('пилинг')) {
        return 'На пилинг: документ, список лекарств и аллергий, без плотного макияжа и ретинола накануне если так сказал врач; SPF после. '
            'Остальное — на ресепшен. Запишем пилинг или консультацию сначала?';
      }
      if (q.contains('лимфодрен') || q.contains('массаж')) {
        return 'На лимфодренаж/массаж: удобная одежда, документ; без плотного макияжа, если трогаем лицо. '
            'Остальное — на ресепшен. Запишем массаж?';
      }
      return 'На первый визит: документ с фото, список аллергий и лекарств, без плотного макияжа на зону лица. '
          'Остальное — на ресепшен. Могу сразу записать на консультацию.';
    }

    if (q.contains('несовершеннолет') ||
        q.contains('с ребенком на прием') ||
        q.contains('с ребёнком на приём') ||
        q.contains('можно с ребенком') ||
        q.contains('можно с ребёнком')) {
      return 'Несовершеннолетних ведём только с родителем или опекуном и согласием. Чаще осмотр и мягкий уход, без «взрослой» артиллерии. '
          'Запишем консультацию — и уточним возраст.';
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('месячн') ||
            q.contains('цикл') ||
            q.contains('критическ') ||
            q.contains('менструац'))) {
      return 'Жёсткого запрета на ботулин в дни цикла обычно нет — иногда учитывают отёк и чувствительность. '
          'Если сильный дискомфорт, лучше сдвинуть дату. Решает врач по самочувствию; могу записать на консультацию.';
    }

    if ((q.contains('ipl') || q.contains('айпи') || q.contains('lumecca')) &&
        (q.contains('самолет') ||
            q.contains('перелет') ||
            q.contains('лететь') ||
            q.contains('летать') ||
            q.contains('авиа') ||
            q.contains('вылет'))) {
      return 'После IPL перелёт через 3–4 дня часто уже обсуждают как рабочий ориентир — SPF в салоне обязателен, без свежего загара; точнее врач по фототипу и зоне. '
          'Когда вспышка и когда вылет?';
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('самолет') ||
            q.contains('перелет') ||
            q.contains('лететь') ||
            q.contains('летать') ||
            q.contains('авиа')) &&
        !q.contains('филлер')) {
      return 'После ботулина перелёт через 2–3 дня часто уже обсуждают как рабочий ориентир — без разминания зоны и жёсткого давления в первые сутки; точнее врач по зонам. '
          'Когда вылет и когда кололи?';
    }

    if ((q.contains('филлер') ||
            q.contains('инъек') ||
            q.contains('после укол')) &&
        (q.contains('самолет') ||
            q.contains('перелет') ||
            q.contains('лететь') ||
            q.contains('летать') ||
            q.contains('авиа'))) {
      return 'После филлера и части уколов перелёт лучше с запасом — чаще ориентир от суток и больше, чтобы не усиливать отёк в салоне. '
          'Точный срок скажет врач под зону и препарат. Когда вылет?';
    }

    if ((q.contains('тонк') && q.contains('кож')) ||
        q.contains('очень сухая кож') ||
        ((q.contains('чувствительн') && q.contains('кож')) &&
            (q.contains('нельзя') || q.contains('что нельзя')))) {
      return 'При тонкой и чувствительной коже обычно убираем жёсткие кислоты, скрабы и «сжечь для блеска»; бережём барьер, SPF, мягкий уход. '
          'Аппаратные и инъекции — только после осмотра. Могу положить Lumen Barrier в корзину или записать на консультацию.';
    }

    if ((q.contains('как часто') || q.contains('как часто можно') || q.contains('интервал')) &&
        q.contains('пилинг')) {
      return 'Частоту пилинга задаёт глубина и тип кожи: мягкие чаще, срединные — с паузой под заживление, без самодеятельности дома. '
          'Ориентир на курсе скажет врач. Запишем консультацию или пилинг L3 после осмотра?';
    }

    if ((q.contains('челюст') || q.contains('жеват') || q.contains('скул')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('после'))) {
      return 'Лёгкая тяжесть или «непривычная» челюсть после ботулина в жевательные иногда бывает первые дни — без разминания зоны. '
          'Если боль сильная, с отёком или асимметрией — сразу врачу в чат. Могу открыть чат специалиста.';
    }

    if ((q.contains('чистк') && q.contains('пилинг')) &&
        (q.contains('совмест') ||
            q.contains('вместе') ||
            q.contains('и пилинг') ||
            q.contains('или пилинг') ||
            q.contains('можно ли'))) {
      return 'Чистку и пилинг в один день ставят не всегда — зависит от типа кожи и глубины. Часто разводят по визитам или делают мягкую связку по решению врача. '
          'Запишем осмотр — скажем, дружат ли они у вас.';
    }

    if (q.contains('носогуб') &&
        (q.contains('без филлер') ||
            q.contains('без укол') ||
            q.contains('убрать') ||
            q.contains('что делать'))) {
      return 'Носогубки без филлера часто начинают с массажа и увлажняющего ухода — объём укола только если после осмотра правда нужен. '
          'Сравнить массаж и HydraPure или сразу консультация?';
    }

    if ((q.contains('синяк') || q.contains('гематом')) &&
        (q.contains('не проход') ||
            q.contains('долго') ||
            q.contains('недел') ||
            q.contains('что делать'))) {
      return 'Синяк после уколов обычно уходит за несколько дней: холод по схеме, без разминания и зала. '
          'Если не сходит дольше недели, растёт или с температурой — к врачу в чат, не ждём. Могу перевести к специалисту.';
    }

    if ((q.contains('кардиостимул') ||
            q.contains('водител ритм') ||
            q.contains('пейсмекер') ||
            q.contains('pacemaker')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц'))) {
      return 'При кардиостимуляторе капельницу не назначаю сама — нужен допуск кардиолога и врача CULT по составу и самочувствию. '
          'Могу открыть чат специалиста. Аппаратные RF при стимуляторе обычно ещё строже.';
    }

    if ((q.contains('кардиостимул') ||
            q.contains('водител ритм') ||
            q.contains('пейсмекер') ||
            q.contains('pacemaker')) &&
        (q.contains('rf') ||
            q.contains('рф') ||
            q.contains('аппарат') ||
            q.contains('можно'))) {
      return 'При кардиостимуляторе аппаратные вроде RF обычно под жёстким ограничением или запретом — без допуска вашего кардиолога не записываю. '
          'Могу открыть чат врача CULT или предложить мягкий уход/массаж вне зоны риска.';
    }

    if ((q.contains('длится') ||
            q.contains('сколько по времени') ||
            q.contains('как долго сеанс') ||
            q.contains('сколько сеанс') ||
            q.contains('сколько идет') ||
            q.contains('сколько идёт')) &&
        (q.contains('массаж') || q.contains('скульптур'))) {
      final massage = _clinicService('скульптурн', gender: gender) ??
          _clinicService('массаж', gender: gender);
      if (massage != null) {
        return 'Скульптурный массаж лица обычно около ${massage.duration} — ориентир ${massage.priceLabel}. '
            'Точное окно подтвердят при записи. Запишем на удобное время?';
      }
      return 'Скульптурный массаж лица обычно около часа — точную длительность и цену скажу из прайса филиала при записи. '
          'Запишем на удобное окно?';
    }

    if (q.contains('плазмолифт') ||
        q.contains('плазмотерап') ||
        q.contains('плазмо') ||
        q.contains('prp') ||
        (q.contains('плазма') && !q.contains('экзосом'))) {
      return 'Плазмолифтинг и PRP у нас в контуре инъекционных протоколов — только после осмотра и нужных анализов, не «укол из вены сразу в кресло» без врача. '
          'Запишем консультацию — скажем, показан ли курс.';
    }

    if ((q.contains('без записи') || q.contains('без запис')) &&
        (q.contains('шоп') ||
            q.contains('магазин') ||
            q.contains('заказ') ||
            q.contains('самовывоз') ||
            q.contains('крем') ||
            q.contains('сыворот'))) {
      return 'Да — заказ из шопа можно забрать на ресепшен без записи на процедуру: назовите код заказа или формулу. '
          'Если удобнее — положу в корзину в приложении. Что забираете?';
    }

    if (q.contains('без записи') ||
        (q.contains('без запис') && (q.contains('прийт') || q.contains('консультац')))) {
      return 'Без записи на консультацию иногда принимают, если есть окно — надёжнее согласовать с администратором в чате или собрать запись со мной кнопкой «Запись». '
          'Назовите день — проверю, как спокойнее зайти.';
    }

    if ((q.contains('интервал') || q.contains('через сколько') || q.contains('пауза между')) &&
        (q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('чистк') || q.contains('пилинг') || q.contains('уход'))) {
      return 'Между ботулином и чисткой/пилингом обычно пауза под заживление — ориентир несколько дней, точнее врач по зонам. '
          'Напишите, что уже сделали или что планируете первым — разложу порядок.';
    }

    if (q.contains('витилиго') || q.contains('vitiligo')) {
      return 'При витилиго эстетику ведём только после осмотра: без агрессивных пилингов «на глаз», часто нужна связка с дерматологом. '
          'Могу записать на консультацию или открыть чат врача. Зона стабильная или свежая?';
    }

    if ((q.contains('после ipl') ||
            q.contains('после айпи') ||
            (q.contains('ipl') && q.contains('после')) ||
            (q.contains('lumecca') && q.contains('после'))) &&
        (q.contains('макияж') || q.contains('красит') || q.contains('тон'))) {
      return 'После IPL макияж на зону обычно откладывают минимум на сутки, иногда дольше — кожа может быть чувствительной, SPF обязателен. '
          'Точный срок скажет врач по протоколу. Когда была вспышка?';
    }

    if ((q.contains('что такое') || q.contains('зачем') || q.contains('для чего') || q.contains('простыми словами')) &&
        (q.contains('micro-patch') ||
            q.contains('micropatch') ||
            q.contains('микро-патч') ||
            q.contains('микропатч') ||
            (q.contains('патч') && q.contains('nad')))) {
      return 'NAD+ Micro-Patch простыми словами — домашний пластырь-предшественник NAD+ на часы, не капельница и не укол в лицо. '
          'Носят в дни без инфузии. Могу положить в корзину или сравнить с Catalyst.';
    }

    if ((q.contains('что такое') || q.contains('зачем') || q.contains('для чего')) &&
        (q.contains('nad') || q.contains('над+')) &&
        !q.contains('patch') &&
        !q.contains('патч')) {
      return 'NAD+ у нас — капельница из блока инфузий: про энергию, ясность и восстановление, не «укол красоты в губы». '
          'Есть и домашние формулы в шопе, но капельницу подбирают после короткого опроса. Сравнить с Beauty & Glow или записать на NAD+?';
    }

    if ((q.contains('мезо') || q.contains('биоревитал') || q.contains('инъек')) &&
        q.contains('герпес') &&
        (q.contains('анамнез') ||
            q.contains('раньше') ||
            q.contains('бывает') ||
            q.contains('когда-то') ||
            q.contains('иногда'))) {
      return 'Если герпес в анамнезе, а сейчас губы спокойные — часто делают с профилактикой по схеме врача; при активных пузырьках процедуру откладываем. '
          'На осмотре обязательно скажите про герпес. Запишем консультацию?';
    }

    if ((q.contains('рубец') || q.contains('рубц') || q.contains('шрам') || q.contains('постакне')) &&
        (q.contains('акне') || q.contains('прыщ') || q.contains('после')) &&
        !q.contains('ветрян') &&
        !q.contains('оспен')) {
      return 'Рубцы после акне разбираем очно: тип рубца решает — пилинг, RF или инъекции, без обещания «сотрём за раз». '
          'Запишем консультацию — и фото в чат врачу, если удобно.';
    }

    if ((q.contains('результат') ||
            q.contains('эффект') ||
            q.contains('ждать') ||
            q.contains('когда будет видно') ||
            q.contains('когда видно')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('микроиголь'))) {
      return 'После RF первый «свежий» вид бывает уже в первые дни, а плотность и лифтинг часто нарастают неделями по курсу — не один кадр «до/после» в день процедуры. '
          'Точные ожидания скажет врач. Записать на осмотр или протокол?';
    }

    if ((q.contains('давлен') || q.contains('гипертон') || q.contains('гипотон')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('nad'))) {
      return 'При скачках давления капельницу не назначаю сама — нужен допуск врача и спокойные цифры в день визита. '
          'Могу открыть чат специалиста или записать на консультацию; админ подскажет подготовку.';
    }

    if ((q.contains('давлен') || q.contains('гипертон') || q.contains('гипотон')) &&
        (q.contains('rf') ||
            q.contains('рф') ||
            q.contains('микроиголь') ||
            q.contains('аппарат') ||
            q.contains('smas') ||
            q.contains('можно'))) {
      return 'При гипертонии RF и часть аппаратных только с допуском врача — цифры давления и лекарства важны на осмотре, без «можно всем». '
          'Могу открыть чат специалиста или записать на консультацию по RF.';
    }

    if ((q.contains('биоревитал') || q.contains('мезотерап')) &&
        (q.contains('филлер') || q.contains('контур')) &&
        (q.contains('отлича') ||
            q.contains('разниц') ||
            q.contains('чем ') ||
            q.contains('или '))) {
      return 'Биоревитализация и мезо — про увлажнение и качество кожи мелкими уколами; филлер — про объём и форму (губы, складки). '
          'Это разные задачи, иногда их сочетают по плану врача. Что важнее вам — сияние или контур?';
    }

    if ((q.contains('прыщ') || q.contains('высып') || q.contains('высып')) &&
        (q.contains('после чистк') || (q.contains('после') && q.contains('чистк')))) {
      return 'Высыпания после чистки иногда бывают как ответ кожи — не выдавливаем, мягкий уход и барьер, без кислот «добить». '
          'Если гной, боль или сыпь растёт — к врачу в чат. Могу открыть чат или записать на осмотр.';
    }

    if ((q.contains('воспален') || q.contains('воспалён') || q.contains('воспаленн') || q.contains('прыщ')) &&
        (q.contains('уход') || q.contains('чистк') || q.contains('можно')) &&
        (q.contains('если') || q.contains('когда') || q.contains('при ')) &&
        !q.contains('после')) {
      return 'На активный воспалённый прыщ агрессивный уход и чистку обычно не ставят — сначала успокаиваем, осмотр, без выдавливания дома. '
          'Запишем консультацию или мягкий протокол, когда стихнет?';
    }

    if ((q.contains('после загар') ||
            q.contains('после солнц') ||
            (q.contains('загар') && q.contains('ухаживать')) ||
            (q.contains('после') && q.contains('загар'))) &&
        (q.contains('ухаж') || q.contains('кож') || q.contains('что делать'))) {
      return 'После загара — холодный душ для кожи без жёсткого скраба, плотный барьер, SPF даже в городе, без кислот пару дней. '
          'Могу положить Lumen Barrier в корзину или записать на успокаивающий уход, когда краснота спала.';
    }

    if ((q.contains('алкогол') || q.contains('вино') || q.contains('выпить') || q.contains('пить вино')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('nad'))) {
      if (q.contains('после') || q.contains('вечером') || q.contains('в тот же')) {
        return 'После капельницы вино и алкоголь в тот же вечер лучше не планировать — сосуды и самочувствие ещё «разгоняются»; чаще пауза до следующего дня. '
            'Точнее скажет врач по составу. Когда была инфузия?';
      }
      return 'Перед капельницей алкоголь лучше убрать накануне — меньше нагрузки на сосуды и самочувствие в кресле. '
          'В день визита — вода и лёгкий приём пищи. Запишем инфузию?';
    }

    if ((q.contains('подарок') || q.contains('подари')) &&
        (q.contains('коллег') || q.contains('подруг') || q.contains('женщин') || q.contains('ей ')) &&
        (q.contains('женщин') || q.contains('ей') || q.contains('подруг') || q.contains('девушк'))) {
      return 'Коллеге-женщине хорошо заходит сертификат CULT или запись на уход/массаж — без давления «сделать всё сразу». '
          'Могу помочь с сертификатом через администратора. Какой примерно бюджет?';
    }

    if ((q.contains('подарок') || q.contains('подари')) &&
        (q.contains('коллег') || q.contains('мужчин') || q.contains('мужчине') || q.contains('ему')) &&
        !q.contains('женщин') &&
        !q.contains('подруг') &&
        !q.contains('девушк')) {
      return 'Коллеге-мужчине хорошо заходит сертификат CULT или барбер-массаж / спокойный уход — без «розового» сценария. '
          'Могу помочь с сертификатом через администратора или записью. Какой примерно бюджет?';
    }

    if ((q.contains('линз') || q.contains('контактн')) &&
        (q.contains('ботокс') ||
            q.contains('ботулин') ||
            q.contains('инъек') ||
            q.contains('можно'))) {
      return 'Линзы сами по себе не запрет на ботулин; на процедуру вокруг глаз их часто снимают, глаза не трут. '
          'Если глаза чувствительные — скажите врачу на осмотре. Запишем консультацию?';
    }

    if ((q.contains('после пилинг') || (q.contains('после') && q.contains('пилинг'))) &&
        (q.contains('красн') ||
            q.contains('горит') ||
            q.contains('норма') ||
            q.contains('это норм'))) {
      return 'Лёгкая краснота после пилинга часто норма на несколько дней: барьер, SPF, без кислот и скрабов, не сдираем шелушение. '
          'Если жжение сильное, отёк или гной — к врачу в чат. Могу положить Lumen Barrier в корзину.';
    }

    if ((q.contains('нос') || q.contains('спинку носа') || q.contains('горбинк')) &&
        !q.contains('носослез') &&
        !q.contains('носослёз') &&
        !q.contains('носогуб') &&
        (q.contains('сузить') ||
            q.contains('без операц') ||
            q.contains('без хирурги') ||
            q.contains('убрать'))) {
      return 'Сузить нос без операции косметология обещает осторожно: иногда смотрят контур и мягкие протоколы после осмотра, без «минус размер как у пластики». '
          'Честный путь — консультация. Запишем осмотр?';
    }

    if ((q.contains('наклон') ||
            q.contains('нагиба') ||
            q.contains('лежать') ||
            q.contains('нельзя наклон')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('после'))) {
      return 'После ботулина часто просят несколько часов не наклоняться низко и не разминать зону — чтобы препарат спокойно «сел». '
          'Точный лист даст врач. Если уже наклонялись и всё спокойно — обычно ок; при сильной асимметрии — в чат.';
    }

    if ((q.contains('кофе') || q.contains('кофеин')) &&
        (q.contains('филлер') || q.contains('гиалурон'))) {
      return 'Кофе после филлера обычно не жёсткий запрет на следующий день, если без перебора; важнее не разминать зону и не греть лицо чашкой. '
          'Алкоголь и зал в первые сутки важнее убрать. Когда кололи?';
    }

    if ((q.contains('кофе') || q.contains('кофеин')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('после укол'))) {
      return 'Кофе после ботулина обычно не запрет, если без перебора и без разминания зоны чашкой «обжигающе горячего» у лица. '
          'Алкоголь и зал в первые сутки важнее убрать. Когда кололи?';
    }

    if ((q.contains('брекет') || q.contains('элайнер') || q.contains('ортодонт')) &&
        (q.contains('smas') || q.contains('смас') || q.contains('ultherap'))) {
      return 'При брекетах SMAS не запрет автоматически, но врачу важно знать про металл во рту — иногда меняют зоны и мощность. '
          'Запишем консультацию по SMAS — скажете про брекеты на осмотре.';
    }

    if ((q.contains('брекет') || q.contains('элайнер') || q.contains('ортодонт')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('микроиголь') || q.contains('аппарат'))) {
      return 'При брекетах и ортодонтии RF не запрет автоматически, но врачу важно знать про металл во рту — иногда меняют зоны и мощность. '
          'Запишем консультацию по RF — скажете про брекеты на осмотре.';
    }

    if ((q.contains('брекет') || q.contains('элайнер') || q.contains('ортодонт')) &&
        (q.contains('массаж') || q.contains('можно') || q.contains('лиц')) &&
        !q.contains('smas') &&
        !q.contains('смас') &&
        !q.contains('ultherap') &&
        !q.contains('rf') &&
        !q.contains('рф')) {
      return 'При брекетах массаж лица часто можно, но без жёсткого давления на челюсть, если ортодонт не ограничивал. '
          'Скажите мастеру про конструкцию на осмотре. Запишем скульптурный массаж?';
    }

    if (((q.contains('конкретн') ||
                q.contains('определённ') ||
                q.contains('определенн')) &&
            q.contains('врач')) ||
        (q.contains('записаться к') && q.contains('врач')) ||
        (q.contains('как записаться') && q.contains('врач'))) {
      return 'К конкретному врачу: назовите имя — подскажу из команды CULT — или откройте меню «Врачи» и слот с карточки. '
          'Могу собрать запись кнопкой «Запись», если скажете специалиста и услугу.';
    }

    if ((q.contains('верн') || q.contains('возврат')) &&
        (q.contains('товар') ||
            q.contains('магазин') ||
            q.contains('шоп') ||
            q.contains('крем') ||
            q.contains('сыворот'))) {
      return 'Возврат товара из шопа — через ресепшен или администратора в чате: зависят сроки, вскрыта ли упаковка и условия. '
          'Разберём спокойно по вашей покупке. Могу открыть чат админа.';
    }

    if (q.contains('smas') ||
        q.contains('смас') ||
        q.contains('ultherap') ||
        q.contains('альтера')) {
      if (q.contains('рассрочк') || q.contains('кредит') || q.contains('частям')) {
        return 'Рассрочку и оплату частями на Ultherapy® / SMAS уточняйте на ресепшен или у администратора в чате — условия зависят от суммы протокола. '
            'Могу открыть чат админа. Запишем консультацию по SMAS параллельно?';
      }
      if (q.contains('улыб') ||
          q.contains('мимик') ||
          q.contains('не двига') ||
          q.contains('не могу') ||
          q.contains('нельзя улыб')) {
        return 'После SMAS скованность мимики или «неудобно улыбнуться» иногда бывает от отёка и чувствительности первые дни — не разминаем зону сами. '
            'Если асимметрия растёт, сильная боль или мимика «пропала» — сразу врачу в чат. Могу открыть чат специалиста.';
      }
      if (q.contains('простыми') || q.contains('что такое')) {
        return 'SMAS простыми словами — более глубокий аппаратный лифтинг каркаса лица, не массаж и не «укол в губы». '
            'Делают после осмотра, с честными ожиданиями по реабилитации. Запишем консультацию?';
      }
      if (q.contains('свадьб') ||
          q.contains('свадеб') ||
          q.contains('мероприят') ||
          (q.contains('отек') && (q.contains('боюсь') || q.contains('страх')))) {
        return 'После SMAS отёк и «усталый» вид могут держаться дни — к свадьбе закладывают запас, не ставят за сутки. '
            'Скажите дату события — подберём мягкий уход/массаж ближе к дню или SMAS заранее.';
      }
      if (q.contains('зуб') ||
          q.contains('коронк') ||
          q.contains('металл') ||
          q.contains('имплант')) {
        return 'Металл в зубах и коронки часто не абсолютный запрет на SMAS, но врачу важно знать — иногда меняют зоны и мощность. '
            'Запишем консультацию по SMAS — скажете про коронки на осмотре.';
      }
      if (q.contains('скольк') || q.contains('стоит') || q.contains('цен')) {
        final ultra = devices
            .where((d) => d.title.toLowerCase().contains('ultherap'))
            .firstOrNull;
        if (ultra != null) {
          return 'SMAS у нас в линейке Ultherapy® — ориентир ${ultra.price}, ${ultra.meta}. '
              'Итог после осмотра и карты зон. Запишем консультацию по SMAS?';
        }
      }
      if (q.contains('лететь') ||
          q.contains('летать') ||
          q.contains('самолет') ||
          q.contains('перелет') ||
          q.contains('авиа') ||
          q.contains('вылет')) {
        return 'После SMAS перелёт лучше с запасом — чаще ориентир от нескольких дней, не «утром процедура — вечером рейс»: возможны отёк и чувствительность. '
            'Точный срок скажет врач по протоколу. Когда вылет и когда SMAS?';
      }
      if (q.contains('отек') ||
          q.contains('отекл') ||
          q.contains('отёк') ||
          q.contains('опух') ||
          q.contains('опухла')) {
        return 'После SMAS отёк на 2–5 день часто ещё в норме — вода, меньше соли, без сауны и жёсткого спорта; не мнём зону. '
            'Если отёк растёт, сильная боль, температура или асимметрия — сразу врачу в чат. Могу открыть чат специалиста.';
      }
      return 'SMAS-лифтинг у нас в аппаратном блоке — это уже серьёзный протокол после осмотра, не «массаж посильнее». '
          'Интенсивность и ожидания честно разложит врач. Запишем консультацию по SMAS?';
    }

    if ((q.contains('крем') || q.contains('барьер') || q.contains('из шопа') || q.contains('из магазин')) &&
        (q.contains('после пилинг') ||
            (q.contains('после') && q.contains('пилинг')) ||
            q.contains('после кислот'))) {
      return 'После пилинга из шопа чаще всего барьерный крем — у нас Lumen Barrier: плотно, без кислот «добить». '
          'Могу положить в корзину. SPF днём всё равно обязателен.';
    }

    if ((q.contains('боюсь') || q.contains('страх')) &&
        q.contains('асимметр') &&
        (q.contains('филлер') || q.contains('губ'))) {
      return 'Страх асимметрии после филлера губ понятен — объём и симметрию смотрит врач на осмотре, часто начинают консервативно. '
          'Можно записаться на консультацию без процедуры в тот же день и разобрать риски. Запишем осмотр по губам?';
    }

    if ((q.contains('боюсь') || q.contains('страшн') || q.contains('альтернатив')) &&
        (q.contains('губ') || q.contains('филлер в губ') || q.contains('укол в губ')) &&
        !q.contains('асимметр')) {
      return 'Без уколов в губы тоже есть путь: увлажнение, уход, иногда массаж и домашний барьер — объём филлера только если сами захотите после осмотра. '
          'Начнём с консультации без процедуры или с ухода?';
    }

    if ((q.contains('rf') || q.contains('рф') || q.contains('микроиголь')) &&
        (q.contains('летом') ||
            q.contains('жар') ||
            q.contains('солнц') ||
            q.contains('загар') ||
            q.contains('в сезон'))) {
      return 'RF летом можно, если готовы к SPF и без загара/солярия в окне реабилитации — иначе риск пятна. '
          'Баню и жёсткий спорт всё равно пауза на несколько дней. Запишем консультацию под вашу дату?';
    }

    if ((q.contains('что такое') || q.contains('простыми словами')) &&
        (q.contains('hydrapure') || q.contains('hydra pure') || q.contains('гидрапур'))) {
      return 'HydraPure простыми словами — глубокое увлажняющее очищение-уход в кресле: кожа свежее и спокойнее, без «укола в губы». '
          'Хорошо как мягкий старт. Запишем или сравнить с массажем?';
    }

    if ((q.contains('бонус') || q.contains('балл')) &&
        (q.contains('подруг') || q.contains('друг') || q.contains('другому') || q.contains('чуж')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('оплат') || q.contains('можно'))) {
      return 'Бонусами CULT обычно платит владелец карты со своего профиля — оплатить капельницу подруге бонусами с вашей карты уточните на ресепшен: правила зависят от уровня. '
          'Чаще удобнее сертификат или её собственный вход. Могу открыть чат админа.';
    }

    if ((q.contains('бонус') || q.contains('балл')) &&
        (q.contains('оплат') ||
            q.contains('списать') ||
            q.contains('консультац') ||
            q.contains('можно ли')) &&
        !q.contains('подруг') &&
        !q.contains('друг') &&
        !q.contains('чуж')) {
      return 'Бонусами CULT можно частично оплачивать услуги и шоп — доля зависит от уровня карты, на платине до 30% чека. '
          'Консультацию и точный остаток лучше подтвердить на ресепшен или в профиле. Могу перевести к администратору.';
    }

    if ((q.contains('после массаж') || (q.contains('после') && q.contains('массаж'))) &&
        (q.contains('пляж') || q.contains('солнц') || q.contains('загар') || q.contains('море'))) {
      return 'После массажа на пляж сразу можно, если кожа не красная и без кислот в протоколе — SPF обязателен, лучше не в пик солнца. '
          'Если лицо сильно разогрето — подождите час–два в тени. Когда массаж?';
    }

    if ((q.contains('после массаж') || (q.contains('после') && q.contains('массаж'))) &&
        (q.contains('ужин') ||
            q.contains('ресторан') ||
            q.contains('вино') ||
            (q.contains('сразу') && q.contains('есть')))) {
      return 'После массажа на ужин обычно можно — лучше вода, без жёсткого алкоголя в тот же вечер, если лицо сильно разогрето. '
          'Макияж плотный не обязателен. Куда собираетесь — спокойный ужин или событие?';
    }

    if ((q.contains('антивозраст') ||
            q.contains('anti-age') ||
            q.contains('anti age') ||
            q.contains('возрастной уход') ||
            q.contains('antiage')) &&
        (q.contains('без инъек') ||
            q.contains('без укол') ||
            q.contains('без ботокс') ||
            q.contains('без филлер'))) {
      return 'Антивозрастной путь без уколов: скульптурный массаж, увлажняющие уходы, дома барьер и пептиды; RF — после осмотра, если нужна плотность. '
          'С чего спокойнее начать — массаж или консультация?';
    }

    if ((q.contains('веки') ||
            q.contains('веко') ||
            q.contains('век ') ||
            q.contains('нависа') ||
            q.contains('блефаро')) &&
        (q.contains('подтя') ||
            q.contains('без операц') ||
            q.contains('без хирурги') ||
            q.contains('убрать'))) {
      return 'Веки без операции поднимаем осторожно: уход, массаж, иногда аппаратные после осмотра — без обещания «как блефаропластика». '
          'Запишем консультацию по зоне глаз?';
    }

    if ((q.contains('за руль') ||
            q.contains('водить') ||
            q.contains('за рулём') ||
            q.contains('за рулем') ||
            q.contains('машин')) &&
        (q.contains('капель') ||
            q.contains('инфуз') ||
            q.contains('после капель') ||
            q.contains('после инфуз'))) {
      return 'После капельницы за руль обычно можно, если самочувствие ровное и нет головокружения — посидите 10–15 минут на ресепшен. '
          'Если слабость — такси или трансфер. Как обычно переносите капельницы?';
    }

    if (q.contains('себорей') || q.contains('себоре')) {
      return 'При себорее кожи головы лицо часто можно вести отдельно, если нет активного воспаления на лице — осмотр решит. '
          'Жёсткие пилинги «на всякий» не тороплю. Запишем консультацию или сначала уход на лицо?';
    }

    if ((q.contains('гиалурон') || q.contains('гиалуронов')) &&
        (q.contains('аллерг') || q.contains('не перенос') || q.contains('реакц'))) {
      return 'Аллергия на гиалуронку — редкость, но важный сигнал: филлеры и часть биоревитализации под вопросом до осмотра и сбора анамнеза. '
          'Не колим «на глаз». Могу открыть чат врача или записать на консультацию без процедуры.';
    }

    if ((q.contains('стягив') ||
            q.contains('стянул') ||
            q.contains('чем мазать') ||
            q.contains('чем смазать')) &&
        (q.contains('после пилинг') ||
            q.contains('после чистк') ||
            (q.contains('после') && (q.contains('пилинг') || q.contains('чистк'))))) {
      return 'После пилинга или чистки стянутость часто норма: плотный барьерный крем — у нас Lumen Barrier — без кислот и скрабов, SPF днём. '
          'Могу положить в корзину. Если жжение сильное — в чат врачу.';
    }

    if (q.contains('кисет') ||
        (q.contains('морщин') && q.contains('над губ')) ||
        (q.contains('морщин') && q.contains('вокруг губ') && q.contains('верх'))) {
      return 'Кисетные линии над губой часто начинают с увлажнения и аккуратной работы после осмотра — филлер или аппаратные не всегда первый шаг. '
          'Запишем консультацию по этой зоне?';
    }

    if ((q.contains('smas') || q.contains('смас') || q.contains('ultherap')) &&
        (q.contains('спорт') ||
            q.contains('зал') ||
            q.contains('бан') ||
            q.contains('нельзя'))) {
      return 'После SMAS спорт и баню обычно ставят на паузу несколько дней — ориентир даст врач по протоколу, чаще дольше, чем после мягкого ухода. '
          'Когда была процедура?';
    }

    if ((q.contains('филлер') || q.contains('гиалурон')) &&
        (q.contains('год назад') ||
            q.contains('уже был') ||
            q.contains('уже дела') ||
            q.contains('можно снова') ||
            q.contains('повтор'))) {
      return 'Повтор филлера через год часто возможен, если ткань спокойная — объём и сроки смотрит врач очно, иногда хватает меньше, чем в первый раз. '
          'Запишем консультацию и вспомним зону?';
    }

    if (q.contains('пора на ботокс') ||
        (q.contains('как понять') && q.contains('ботокс')) ||
        (q.contains('когда пора') && q.contains('ботокс')) ||
        q.contains('нужен ли ботокс')) {
      return 'Пора на ботулин — когда мимические заломы мешают в покое или устаёте от «вечно удивлённого» лба; возраст сам по себе не диктует. '
          'Честнее решить на осмотре, иногда хватает ухода и массажа. Запишем консультацию?';
    }

    if (q.contains('пора на биоревитал') ||
        (q.contains('как понять') && q.contains('биоревитал')) ||
        (q.contains('когда пора') && q.contains('биоревитал')) ||
        (q.contains('нужна ли') && q.contains('биоревитал'))) {
      return 'Пора на биоревитализацию — когда сухость, тусклость и потеря плотности не уходят уходом; возраст сам по себе не кнопка. '
          'Решает осмотр: иногда хватает массажа и домашнего барьера. Запишем консультацию?';
    }

    if ((q.contains('боюсь аппарат') ||
            q.contains('ручной уход') ||
            q.contains('только ручн') ||
            (q.contains('боюсь') && q.contains('аппарат'))) &&
        (q.contains('уход') ||
            q.contains('есть') ||
            q.contains('можно') ||
            q.contains('только'))) {
      return 'Да — есть полностью ручной путь: скульптурный массаж и уходы без аппаратов, дома барьер. '
          'Аппаратную подключим только если сами захотите после осмотра. Запишем массаж или консультацию?';
    }

    if (q.contains('без приложения') ||
        q.contains('без app') ||
        (q.contains('онлайн') && q.contains('запис')) ||
        (q.contains('сайт') && q.contains('запис'))) {
      return 'Запись можно со мной в приложении кнопкой «Запись», через чат администратора или по телефону ресепшен — без приложения тоже наберут окно. '
          'Скажите услугу и день — помогу здесь.';
    }

    if ((q.contains('отек') || q.contains('отёк') || q.contains('опух') || q.contains('отекло')) &&
        (q.contains('перелет') ||
            q.contains('самолет') ||
            q.contains('после перелет') ||
            q.contains('после лет'))) {
      return 'После перелёта отёк лица часто снимает сон, вода без пересола и лимфодренажный или скульптурный массаж — быстрый спокойный вход. '
          'Капельницу «сразу с трапа» не обещаю. Запишем массаж на ближайшее окно?';
    }

    if (q.contains('милиум') ||
        q.contains('милиу') ||
        q.contains('просян') ||
        q.contains('белые точки')) {
      return 'Милиумы точечно убирают на осмотре/чистке — не выдавливаем дома иглой. '
          'Запишем на консультацию или мягкую чистку после оценки кожи.';
    }

    if ((q.contains('интервал') ||
            q.contains('между курс') ||
            q.contains('как часто') ||
            q.contains('через сколько курс')) &&
        (q.contains('мезо') || q.contains('биоревитал'))) {
      return 'Между сеансами мезо и биоревитализации обычно пауза под заживление — часто 1–2 недели в курсе, точнее врач по препарату и коже. '
          'Запишем консультацию или следующий сеанс, если курс уже идёт?';
    }

    if ((q.contains('сертификат') || q.contains('подарить')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('nad') || q.contains('beauty'))) {
      return 'Сертификат CULT можно на любую сумму — капельницу Beauty & Glow или NAD+ получатель выберет сам по номиналу. '
          'Оформить в профиле или через администратора. Помочь с номиналом?';
    }

    if ((q.contains('пилинг') || q.contains('кислот')) &&
        (q.contains('самолет') ||
            q.contains('перелет') ||
            q.contains('лететь') ||
            q.contains('вылет')) &&
        (q.contains('завтра') ||
            q.contains('скоро') ||
            q.contains('перед') ||
            q.contains('если'))) {
      return 'Пилинг за день до самолёта обычно не лучшая идея: краснота и SPF в салоне не дружат с планами. '
          'Ближе к вылету — массаж или мягкий уход. Запишем спокойный вариант до или после рейса?';
    }

    if ((q.contains('асимметр') ||
            q.contains('криво') ||
            q.contains('одна сторон') ||
            (q.contains('одна губ') && (q.contains('больше') || q.contains('меньше') || q.contains('друг')))) &&
        (q.contains('филлер') || q.contains('губ')) &&
        (q.contains('после') || q.contains('сильн') || q.contains('что делать') || q.contains('день'))) {
      return 'Разная величина или асимметрия губ после филлера на 1–2 день часто от отёка — без разминания, холод по схеме. '
          'Если растёт, белеет или сильная боль — сразу врачу в чат, возможен осмотр. Могу открыть чат специалиста сейчас.';
    }

    if ((q.contains('асимметр') || q.contains('криво') || q.contains('одна сторон')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('после')) &&
        !q.contains('филлер') &&
        !q.contains('губ')) {
      return 'Лёгкая асимметрия после ботулина в первые дни бывает, пока препарат «садится» — без разминания зоны. '
          'Если перекос сильный или растёт — сразу врачу в чат, не ждём две недели молча. Могу открыть чат специалиста.';
    }

    if ((q.contains('целов') || q.contains('поцелу') || q.contains('целовать')) &&
        (q.contains('ботокс') || q.contains('ботулин')) &&
        !q.contains('филлер') &&
        !q.contains('губ')) {
      return 'После ботулина поцелуи обычно не запрет, если не разминаете зону уколов сильно в первые часы. '
          'Точный лист — у врача. Когда кололи?';
    }

    if ((q.contains('целов') || q.contains('поцелу') || q.contains('целовать')) &&
        (q.contains('филлер') || q.contains('губ') || q.contains('после'))) {
      return 'После филлера в губы поцелуи лучше отложить на сутки-двое — меньше смещения и раздражения. '
          'Точный срок скажет врач. Когда кололи?';
    }

    if ((q.contains('биоревитал') || q.contains('мезотерап')) &&
        (q.contains('шеи') || q.contains('шею') || q.contains('шея') || q.contains('декольте'))) {
      return 'Биоревитализацию шеи и декольте делаем после осмотра — зона нежная, препарат и плотность подбирает врач. '
          'Запишем консультацию по шее?';
    }

    if ((q.contains('похмел') || q.contains('после гулян') || q.contains('после вчера')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('прийт'))) {
      return 'С похмелья на капельницу не записываю вслепую: сначала вода, еда, давление; часть составов в такой день не ставят. '
          'Если совсем плохо — лучше отдохнуть или спросить врача в чате. Могу предложить окно на завтра, когда станет легче.';
    }

    if ((q.contains('прыщ') || q.contains('высып') || q.contains('акне')) &&
        (q.contains('после пилинг') || (q.contains('после') && q.contains('пилинг')))) {
      return 'Высыпания после пилинга иногда бывают на фоне обновления — не выдавливаем и не жжём спиртом. '
          'Мягкий барьер, SPF; если гнойно и нарастает — к врачу. Могу открыть чат или положить Lumen Barrier.';
    }

    if ((q.contains('мужск') || q.contains('для муж') || q.contains('мужчинам')) &&
        (q.contains('ботокс') || q.contains('ботулин'))) {
      return 'Мужской ботулин — те же мышцы, другая доза и рисунок мимики: без «кукольного» эффекта, если так договоритесь на осмотре. '
          'Запишем консультацию — разметка честнее любой «мужской кнопки».';
    }

    if ((q.contains('блестит') || q.contains('жирн') || q.contains('сальн') || q.contains('блеск')) &&
        (q.contains('после умыван') ||
            q.contains('через час') ||
            q.contains('на лбу') ||
            q.contains('т-зон') ||
            q.contains('т зон') ||
            q.contains('только на') ||
            q.contains('кожа'))) {
      return 'Блеск на лбу и в Т-зоне часто про себум и барьер, а не «надо сильнее пенку». '
          'Мягкое умывание, лёгкий крем, без спиртового тоника. Могу положить сыворотку/крем из шопа или записать на уход.';
    }

    if ((q.contains('как часто') || q.contains('как часто можно') || q.contains('интервал')) &&
        (q.contains('филлер') || (q.contains('колоть') && q.contains('губ'))) &&
        !q.contains('ботокс') &&
        !q.contains('ботулин')) {
      return 'Филлер в губы не колют «по календарю каждый месяц» — ориентир раз в несколько месяцев–год, когда объём уходит и ткань спокойная, после осмотра. '
          'Чаще не значит лучше. Запишем консультацию по губам?';
    }

    if ((q.contains('как часто') || q.contains('как часто можно') || q.contains('интервал')) &&
        (q.contains('ботокс') || q.contains('ботулин') || (q.contains('колоть') && !q.contains('филлер') && !q.contains('губ')))) {
      return 'Ботулин обычно не колют «по календарю каждый месяц» — ориентир раз в несколько месяцев, когда эффект уходит, после осмотра. '
          'Чаще не значит лучше. Запишем консультацию, когда снова заметите мимику?';
    }

    if (q.contains('ветрян') ||
        (q.contains('шрам') && (q.contains('ветр') || q.contains('оспен') || q.contains('после ветр')))) {
      return 'Шрамы после ветрянки разбираем очно: тип рубца решает — пилинг, RF или точечные протоколы, без обещания «сотрём». '
          'Запишем консультацию — можно с фото в чат врачу.';
    }

    if ((q.contains('собак') || q.contains('питомц') || q.contains('кот')) &&
        (q.contains('парков') || q.contains('у клиник') || q.contains('оставить'))) {
      return 'На парковке собаку можно оставить с сопровождающим снаружи — в процедурные зоны питомцев обычно не пускаем. '
          'Уточните у администратора на месте. Сама парковка у входа на Черноморской, 6.';
    }

    if ((q.contains('чеш') || q.contains('зуд') || q.contains('зудит') || q.contains('чешется')) &&
        (q.contains('ipl') || q.contains('айпи') || q.contains('lumecca') || q.contains('после света'))) {
      return 'Лёгкий зуд после IPL на 1–2 день иногда бывает — прохладные компрессы по листу врача, без расцарапывания, SPF обязателен. '
          'Если зуд сильный, с пузырями, нарастающим отёком или сыпью — сразу врачу. Когда была вспышка?';
    }

    if ((q.contains('после ipl') ||
            (q.contains('ipl') && q.contains('после')) ||
            (q.contains('lumecca') && q.contains('после'))) &&
        (q.contains('пятн') || q.contains('темне')) &&
        !q.contains('чеш') &&
        !q.contains('зуд')) {
      return 'После IPL пятна иногда временно темнеют — часто так и задумано, потом светлеют; SPF обязателен. '
          'Если боль, пузыри или сильный отёк — сразу врачу. Когда была вспышка?';
    }

    if ((q.contains('чужой карт') ||
            q.contains('с чужой') ||
            q.contains('картой мужа') ||
            q.contains('картой жены') ||
            q.contains('не своей карт')) &&
        (q.contains('оплат') || q.contains('можно'))) {
      return 'Оплатить чужой картой обычно можно, если банк не блокирует и человек рядом или дал согласие — детали на ресепшен. '
          'Бонусы CULT привязаны к вашему профилю. Уточню у администратора в чате при необходимости.';
    }

    if ((q.contains('есть') || q.contains('есть ли') || q.contains('нельзя есть') || q.contains('диета')) &&
        (q.contains('после капель') ||
            q.contains('после инфуз') ||
            q.contains('после капельниц'))) {
      return 'После капельницы обычно можно есть как обычно — лучше лёгкая еда и вода, без тяжёлого алкоголя в тот же вечер. '
          'Жёсткой «диеты после капельницы» чаще нет. Запишем инфузию?';
    }

    if ((q.contains('поплыв') || q.contains('отек после массаж') || q.contains('опухнет')) &&
        q.contains('массаж')) {
      return 'После скульптурного массажа лицо может быть чуть пастозным пару часов — это не «поплыло навсегда», обычно к вечеру спокойнее. '
          'Пьём воду, без жёсткого алкоголя. Запишем массаж — расскажу, чего ждать в день визита.';
    }

    if ((q.contains('ультразвук') || q.contains('узи') || q.contains('вручную') || q.contains('механическ')) &&
        q.contains('чистк')) {
      return 'Чистку делаем и ультразвуком, и комбинированно с ручной работой — выбор по типу кожи на осмотре, не «чем жёстче, тем лучше». '
          'Ultherapy® — это уже другой SMAS-протокол, не чистка. Запишем консультацию или уход?';
    }

    if ((q.contains('розацеа') || q.contains('купероз')) &&
        (q.contains('загар') || q.contains('загор') || q.contains('солнц') || q.contains('соляри'))) {
      return 'При розацеа и куперозе загар и солярий обычно враги — усиливают сосуды и пятна. SPF и тень важнее «красивого цвета». '
          'Эстетику после осмотра. Запишем консультацию?';
    }

    if ((q.contains('восстанов') ||
            q.contains('реабилитац') ||
            q.contains('сколько зажив') ||
            q.contains('сколько длит')) &&
        (q.contains('пилинг') || q.contains('l3'))) {
      return 'После пилинга L3 чаще несколько дней красноты и шелушения, полный комфорт — ориентир до недели по глубине и коже. '
          'Барьер, SPF, без скрабов. Запишем осмотр или пилинг после оценки?';
    }

    if ((q.contains('что такое') || q.contains('простыми словами')) &&
        (q.contains('veil') ||
            q.contains('вейл') ||
            (q.contains('peptide serum') && q.contains('veil')) ||
            q.contains('veil peptide'))) {
      return 'Veil Peptide Serum простыми словами — ночная сыворотка плотности для дома: пептиды между визитами, не укол и не капельница. '
          'Могу положить в корзину или сравнить с барьерным кремом.';
    }

    if ((q.contains('что такое') || q.contains('простыми словами')) &&
        (q.contains('smas') || q.contains('смас') || q.contains('ultherap'))) {
      return 'SMAS простыми словами — более глубокий аппаратный лифтинг каркаса лица, не массаж и не «укол в губы». '
          'Делают после осмотра, с честными ожиданиями по реабилитации. Запишем консультацию?';
    }

    if ((q.contains('папул') || q.contains('бугорк') || q.contains('шишечк')) &&
        (q.contains('мезо') || q.contains('биоревитал') || q.contains('после'))) {
      return 'Папулы после мезо и биоревитализации часто держатся от часов до пары дней — не давим и не скрабим. '
          'Если краснота и боль нарастают — к врачу. Могу открыть чат специалиста.';
    }

    if ((q.contains('зуб') || q.contains('металл') || q.contains('брекет') || q.contains('имплант')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('микроиголь') || q.contains('аппарат'))) {
      return 'Металл в зубах и дентальные импланты часто не абсолютный запрет на RF, но врачу важно знать — иногда меняют зоны и мощность. '
          'Без осмотра «да, всегда можно» не скажу. Запишем консультацию и перечислим, что во рту?';
    }

    if (q.contains('куриная кожа') ||
        q.contains('гусиная кожа') ||
        q.contains('кератоз') ||
        q.contains('фолликулярн')) {
      return '«Куриная кожа» на руках — часто кератоз: мягкие кислоты и уход по телу, лицо ведём отдельно, если там спокойно. '
          'Без осмотра не смешиваю протоколы. Запишем консультацию или сначала тело?';
    }

    if ((q.contains('антибиот') || q.contains('пью лекарств')) &&
        (q.contains('пилинг') || q.contains('чистк') || q.contains('лазер') || q.contains('ipl'))) {
      return 'На фоне антибиотиков пилинги и часть агрессивных протоколов часто откладывают или согласуют с врачом — зависит от препарата. '
          'Без названия лекарства «да» не скажу. Могу открыть чат специалиста или записать на консультацию.';
    }

    if ((q.contains('антибиот') || q.contains('пью лекарств')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('инъек') || q.contains('можно'))) {
      return 'На фоне антибиотиков инъекции часто откладывают или согласуют с врачом — зависит от препарата и срока курса. '
          'Без названия лекарства «да» не скажу. Могу открыть чат специалиста или записать на консультацию.';
    }

    if (q.contains('гиалуронидаз') ||
        q.contains('растворить филлер') ||
        q.contains('убрать филлер') ||
        (q.contains('фермент') && q.contains('филлер'))) {
      return 'Гиалуронидаза — растворение гиалуронового филлера, не «убрать второй подбородок чудом». Показания и объём только очно у врача. '
          'Запишем консультацию — и скажите, что и когда кололи.';
    }

    if ((q.contains('спать') || q.contains('лежать') || q.contains('на боку') || q.contains('подуш')) &&
        (q.contains('филлер') || q.contains('контурн') || q.contains('гиалурон'))) {
      return 'После филлера первые ночи лучше не спать лицом в подушку и не давить на зону — меньше смещения и отёка. '
          'Точный срок скажет врач. Когда кололи?';
    }

    if ((q.contains('спать') || q.contains('лежать') || q.contains('на живот') || q.contains('на боку')) &&
        (q.contains('ботокс') || q.contains('ботулин')) &&
        !q.contains('филлер')) {
      if (q.contains('живот')) {
        return 'После ботулина лицом в подушку / на живот первые сутки обычно не рекомендуют — меньше смещения и давления на зону; на боку чаще раньше по листу врача. '
            'Через два дня часто уже мягче, точнее скажет врач. Когда кололи?';
      }
      return 'После ботулина первые часы лучше не низко наклоняться и не разминать зону; на боку спать обычно можно ближе к вечеру, если врач не сказал иначе. '
          'Точный лист дадут на визите. Когда кололи?';
    }

    if ((q.contains('сдавала кровь') ||
            q.contains('сдавал кровь') ||
            q.contains('забор крови') ||
            q.contains('после анализ')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('можно'))) {
      return 'В день забора крови капельницу часто лучше не ставить подряд — организму нужна пауза; решает врач по самочувствию и анализам. '
          'Перенесём инфузию на другой день через администратора?';
    }

    if ((q.contains('жжет') || q.contains('жжёт') || q.contains('горит') || q.contains('печет')) &&
        (q.contains('после rf') ||
            q.contains('после рф') ||
            (q.contains('rf') && q.contains('после')) ||
            (q.contains('микроиголь') && q.contains('после')))) {
      return 'После RF лёгкое тепло нормально; сильное жжение — стоп активы, холод по схеме, барьерный крем, без сауны. '
          'Если нарастает или с пузырями — сразу врачу в чат. Могу положить Lumen Barrier или открыть чат.';
    }

    if (q.contains('невест') ||
        q.contains('свадебн пакет') ||
        q.contains('программа для невест') ||
        (q.contains('свадьб') && (q.contains('программ') || q.contains('пакет') || q.contains('курс')))) {
      return 'Отдельного «пакета невесты» как кнопки нет — собираем под дату: массаж/уход заранее, без тяжёлой реабилитации накануне. '
          'Сертификат или запись на консультацию к дате. Когда свадьба?';
    }

    if ((q.contains('подготов') || q.contains('как готов')) &&
        (q.contains('биоревитал') || q.contains('мезотерап'))) {
      return 'К биоревитализации обычно: без алкоголя накануне, сообщить герпес и лекарства, без плотного макияжа в день визита; точный лист — после записи. '
          'Запишем консультацию или курс?';
    }

    if ((q.contains('тату') || q.contains('татуаж')) &&
        (q.contains('ipl') || q.contains('айпи') || q.contains('lumecca') || q.contains('лазер'))) {
      return 'IPL и свет рядом с тату на лице обсуждают только на осмотре — пигмент тату может нагреваться и менять цвет, зону часто обходят. '
          'Без осмотра «да, вспышку поверх» не обещаю. Запишем консультацию по IPL — покажите тату врачу.';
    }

    if ((q.contains('тату') || q.contains('татуаж')) &&
        (q.contains('пилинг') || q.contains('чистк') || q.contains('рядом'))) {
      return 'Пилинг и чистку рядом с тату/татуажем обсуждают очно — пигмент и края зоны не трогаем вслепую. '
          'Запишем консультацию и покажите зону врачу.';
    }

    if (q.contains('электрокар') ||
        q.contains('электромобил') ||
        (q.contains('зарядк') && q.contains('парк')) ||
        q.contains('ev ') ||
        q.contains('тесла')) {
      return 'Парковка у входа на Черноморской, 6 — для клиентов на время визита. Отдельной зарядки EV на месте уточните у администратора в чате. '
          'Могу открыть чат админа.';
    }

    if ((q.contains('шишк') ||
            q.contains('уплотнен') ||
            q.contains('комоч') ||
            q.contains('тверд') ||
            q.contains('твёрд') ||
            q.contains('жестк губ') ||
            q.contains('жёстк губ')) &&
        (q.contains('филлер') || q.contains('губ') || q.contains('после укол') || q.contains('гиалурон'))) {
      return 'Небольшая плотность или «твёрдость» губы после филлера иногда бывает первые дни — не мнём сами. '
          'Если уплотнение растёт, белеет, очень болит или асимметрия — сразу врачу, возможен осмотр на гиалуронидазу. Могу открыть чат специалиста.';
    }

    if ((q.contains('верн') || q.contains('возврат')) &&
        q.contains('сертификат')) {
      return 'Возврат и переоформление сертификата — через администратора: чат или ресепшен, зависят сроки и активация кода. '
          'Разберём спокойно. Могу открыть чат админа.';
    }

    if (q.contains('выйти в люди') ||
        q.contains('не смогу выйти') ||
        (q.contains('реабилитац') && q.contains('пилинг')) ||
        (q.contains('боюсь') && q.contains('пилинг') && q.contains('после'))) {
      return 'После мягкого пилинга краснота и шелушение часто несколько дней — к событию лучше заложить запас или выбрать уход/массаж без «корочки». '
          'Скажите дату выхода — подберём протокол под календарь.';
    }

    if (q.contains('демодекс') || q.contains('демодекоз') || q.contains('demodex')) {
      return 'При демодексе без самолечения кислотами: сначала допуск врача, часто дерматолога, потом мягкая эстетика. '
          'Могу открыть чат специалиста или записать на консультацию. Сейчас обострение?';
    }

    if ((q.contains('что такое') || q.contains('простыми словами')) &&
        (q.contains('immunity') || q.contains('иммунит'))) {
      return 'Immunity простыми словами — капельница поддержки, когда силы и иммунитет на нуле, не «укол красоты в лицо». '
          'Состав и показания — после короткого опроса. Сравнить с NAD+ или записать?';
    }

    if ((q.contains('болит голов') || q.contains('головная боль') || q.contains('голова болит')) &&
        (q.contains('после массаж') || (q.contains('после') && q.contains('массаж')))) {
      return 'Лёгкая головная боль после массажа иногда бывает от расслабления и притока — вода, отдых, без разминания зоны до боли. '
          'Если боль сильная или с тошнотой — напишите врачу. Могу открыть чат.';
    }

    if ((q.contains('золот') && q.contains('нит')) ||
        q.contains('золотые нити') ||
        q.contains('мезонити') ||
        (q.contains('нити') && (q.contains('rf') || q.contains('аппарат') || q.contains('можно')))) {
      return 'После золотых нитей и мезонитей RF и часть аппаратных только с допуском врача — срок после установки и зоны решают. '
          'Без осмотра не записываю. Могу открыть чат специалиста или консультацию.';
    }

    if ((q.contains('подарок себе') ||
            q.contains('себе в подарок') ||
            q.contains('ко дню рождения') ||
            q.contains('на день рождения')) &&
        (q.contains('клиник') || q.contains('себе') || q.contains('хочу'))) {
      return 'Себе к дню рождения хорошо заходит сертификат CULT на любимую сумму или запись на массаж/уход — без ожидания «подарка от кого-то». '
          'Оформим сертификат или сразу «Запись»?';
    }

    if ((q.contains('лимфодренаж') || q.contains('лимфодрен')) &&
        (q.contains('скольк') || q.contains('стоит') || q.contains('цен'))) {
      final lymph = _clinicService('лимфодренаж', gender: gender) ??
          _clinicService('скульптурн', gender: gender);
      if (lymph != null) {
        return 'Лимфодренаж и скульптурный массаж у нас в линейке мануальных — ориентир ${lymph.priceLabel}, ${lymph.duration}. '
            'Точное название подтвердим при записи. Запишем окно?';
      }
      return 'Лимфодренажный массаж — в мануальной линейке; цену из филиала скажу при записи или из прайса. '
          'Запишем консультацию или массаж?';
    }

    if ((q.contains('кушетк') || q.contains('одну кушет') || q.contains('вместе на')) &&
        (q.contains('двоих') || q.contains('вдвоём') || q.contains('вдвоем') || q.contains('пар'))) {
      return 'Одну кушетку на двоих обычно не ставим — соседние кабинеты или окна друг за другом спокойнее. '
          'Администратор поможет через чат. Какая процедура вам двоим?';
    }

    if (q.contains('плацентар') ||
        q.contains('плаценто') ||
        (q.contains('плацент') && q.contains('терап'))) {
      return 'Плацентарную терапию как отдельный бренд-протокол мы не ведём — у нас инъекции, уходы, аппаратная и инфузии по показаниям врача. '
          'Если искали «омоложение изнутри», ближе биоревитал, мезо или капельница после осмотра. Запишем консультацию?';
    }

    if ((q.contains('эндометр') || q.contains('миом')) &&
        (q.contains('rf') ||
            q.contains('рф') ||
            q.contains('аппарат') ||
            q.contains('можно') ||
            q.contains('капель'))) {
      return 'При эндометриозе и миоме аппаратные и часть протоколов только с допуском врача — гинекологический фон учитываем очно, без «можно всем». '
          'Могу открыть чат специалиста или записать на консультацию. Есть свежие рекомендации гинеколога?';
    }

    if (q.contains('папиллом') ||
        q.contains('папилом') ||
        q.contains('бородавк') ||
        (q.contains('удален') && (q.contains('родинк') || q.contains('невус')))) {
      return 'Удаление папиллом и родинок — к врачу после осмотра, не «сжигаем сами» и не обещаю лазер без оценки. '
          'Могу открыть чат специалиста или записать на консультацию. Зона лица или тела?';
    }

    if ((q.contains('умыв') || q.contains('умывать') || q.contains('мыть лицо') || q.contains('водой')) &&
        (q.contains('после чистк') ||
            q.contains('после пилинг') ||
            (q.contains('после') && q.contains('чистк')))) {
      return 'После чистки умываться обычно можно мягко и без щёток — тёплая вода, без кислот и скраба в первые сутки, сразу барьерный крем. '
          'Точный лист даст врач. Могу положить Lumen Barrier в корзину.';
    }

    if ((q.contains('носослез') || q.contains('носослёз') || q.contains('слёзн борозд') || q.contains('слезн борозд')) &&
        (q.contains('убрать') ||
            q.contains('без филлер') ||
            q.contains('без укол') ||
            q.contains('что делать') ||
            q.contains('хочу'))) {
      return 'Носослёзная борозда без филлера: сон, соль, мягкий уход у глаза, иногда скульптурный массаж — объём шприцем только после осмотра, если сами захотите. '
          'Запишем массаж или консультацию без процедуры в тот же день?';
    }

    if ((q.contains('пирсинг') || q.contains('прокол')) &&
        (q.contains('ботокс') ||
            q.contains('ботулин') ||
            q.contains('инъек') ||
            q.contains('можно') ||
            q.contains('бров'))) {
      return 'Пирсинг рядом с зоной укола скажите врачу: иногда сдвигают точки или ждут, пока канал спокойный. '
          'Сам по себе пирсинг брови не отменяет ботулин на лоб/глаза. Запишем консультацию?';
    }

    if ((q.contains('алкогол') || q.contains('вино') || q.contains('выпить') || q.contains('пить вино')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('после укол') || q.contains('филлер'))) {
      return 'Алкоголь после ботулина и филлера обычно убирают на сутки–двое: меньше отёка и синяков. '
          'Точный срок — в листе врача. Когда была процедура или только планируете?';
    }

    if ((q.contains('пилинг') && (q.contains('биоревитал') || q.contains('мезотерап') || q.contains('мезо '))) &&
        (q.contains('совмест') ||
            q.contains('совмещ') ||
            q.contains('вместе') ||
            q.contains('в один') ||
            q.contains('и биоревитал') ||
            q.contains('и мезо'))) {
      return 'Пилинг и биоревитализацию/мезо редко ставят в один день — чаще разносят, чтобы кожа успела успокоиться; порядок решает врач. '
          'Запишем осмотр и соберём спокойный план по датам?';
    }

    if ((q.contains('что такое') || q.contains('простыми словами')) &&
        (q.contains('cellular') ||
            q.contains('catalyst') ||
            q.contains('катализ'))) {
      return 'Cellular Catalyst простыми словами — домашний предшественник NAD+: поддержка энергии клетки, не укол в лицо. '
          'Часто рядом с инфузиями или отдельным курсом. Могу положить в корзину или сравнить с Mitochondrial Fuel.';
    }

    if ((q.contains('обмен') || q.contains('обменять') || q.contains('замен') || q.contains('переоформ')) &&
        q.contains('сертификат')) {
      return 'Обмен сертификата на другую услугу или номинал — через администратора: чат или ресепшен, зависят активация кода и остаток. '
          'Могу открыть чат админа. Какой код или сумма примерно?';
    }

    if ((q.contains('надеть') ||
            q.contains('одежд') ||
            q.contains('во что') ||
            q.contains('что взять на массаж')) &&
        (q.contains('массаж') || q.contains('тело') || q.contains('тел'))) {
      return 'На массаж тела — удобная одежда, которую легко снять с зоны; снизу часто одноразовое бельё клиники. '
          'Для лица достаточно прийти без плотного макияжа. Запишем массаж?';
    }

    if (q.contains('мама и дочь') ||
        q.contains('мама с дочерь') ||
        q.contains('вместе с дочерь') ||
        q.contains('пакет для двоих') ||
        (q.contains('пакет') && (q.contains('мама') || q.contains('дочь')))) {
      return 'Отдельного пакета «мама и дочь» в меню нет — можно два окна подряд или соседние кабинеты: уход/массаж под возраст и задачу каждой. '
          'Администратор соберёт слоты в чате. Какие процедуры вам двоим ближе?';
    }

    if (((q.contains('сожж') ||
                q.contains('сожг') ||
                q.contains('сгорит') ||
                q.contains('ожог') ||
                (q.contains('боюсь') && q.contains('жжет'))) &&
            (q.contains('rf') || q.contains('рф') || q.contains('аппарат') || q.contains('микроиголь'))) ||
        (q.contains('боюсь') &&
            (q.contains('rf') || q.contains('рф')) &&
            (q.contains('сожж') || q.contains('кож')))) {
      return 'RF не «сжигает» кожу как открытый огонь: мощность и глубину ставит врач, кожа краснеет и восстанавливается по протоколу. '
          'Страх нормален — можно начать с консультации без процедуры в тот же день. Запишем осмотр?';
    }

    if ((q.contains('акне на спин') || q.contains('прыщи на спин') || q.contains('спина') && q.contains('акне')) &&
        (q.contains('лиц') || q.contains('чистк') || q.contains('можно'))) {
      return 'Акне на спине и лицо смотрим отдельно: лицо часто можно вести уходом или пилингом, если там спокойно; спину — своим протоколом после осмотра. '
          'Без «чистим всё сразу». Запишем консультацию по лицу, спине или обеим зонам?';
    }

    if ((q.contains('низк') && q.contains('давлен')) ||
        (q.contains('гипотон') && (q.contains('капель') || q.contains('инфуз') || q.contains('можно')))) {
      return 'При низком давлении капельницу не назначаю сама — нужен допуск врача и спокойные цифры в день визита. '
          'Могу открыть чат специалиста или записать на консультацию.';
    }

    if ((q.contains('подготов') || q.contains('как готов')) &&
        (q.contains('ipl') || q.contains('аипл') || q.contains('фотоомолож') || q.contains('lumecca'))) {
      return 'К IPL обычно: без загара и ретинола/кислот в окне, которое скажет врач, без самоотбеливания, в день визита без плотного тона на зоне. '
          'Точный лист — при записи. Запишем консультацию или Lumecca после осмотра?';
    }

    if ((q.contains('подготов') || q.contains('как готов')) &&
        (q.contains('массаж') || q.contains('скульптур'))) {
      return 'К скульптурному массажу обычно: без плотного макияжа, сообщите давление/герпес/свежие уколы, удобная одежда. '
          'Есть/пить можно как обычно. Запишем массаж — на ресепшен подскажут мелочи по кабинету.';
    }

    if ((q.contains('операц') || q.contains('хирург') || q.contains('после наркоз')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц'))) {
      return 'После операции капельницу в клинике красоты не ставлю «для восстановления» сама — нужен допуск лечащего врача и срок после вмешательства. '
          'Могу открыть чат специалиста или записать на консультацию, когда будет разрешение.';
    }

    if ((q.contains('гусин') || q.contains('лапк') || q.contains('вокруг глаз') || q.contains('у глаз')) &&
        (q.contains('без ботокс') ||
            q.contains('без укол') ||
            q.contains('без инъек') ||
            q.contains('убрать'))) {
      return 'Гусиные лапки без ботулина: увлажнение у глаза, SPF, скульптурный массаж и мягкий уход; аппаратные — только после осмотра. '
          'Инъекции не предлагаю, пока сами не попросите. Запишем массаж или консультацию?';
    }

    if ((q.contains('массаж') &&
            (q.contains('после ботокс') ||
                q.contains('после ботулин') ||
                ((q.contains('ботокс') || q.contains('ботулин')) &&
                    (q.contains('можно') || q.contains('после'))))) &&
        !q.contains('тела')) {
      return 'После ботулина массаж зоны уколов обычно откладывают на дни–недели по листу врача — иначе можно сместить эффект. '
          'Мягкий уход без давления иногда раньше. Когда кололи и какая зона?';
    }

    if (((q.contains('бров') &&
                (q.contains('разн') ||
                    q.contains('асимметр') ||
                    q.contains('высот') ||
                    q.contains('одна выше'))) ||
            (q.contains('глаз') &&
                (q.contains('выше') || q.contains('ниже') || q.contains('разн') || q.contains('асимметр')))) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('после'))) {
      return 'Разная высота брови или «один глаз выше» после ботулина иногда бывает в первые дни, пока мышцы «садятся»; сильную асимметрию смотрит врач — возможна коррекция. '
          'Не массируйте сами. Могу открыть чат специалиста. Когда кололи?';
    }

    if ((q.contains('продл') || q.contains('продлить') || q.contains('истек') || q.contains('истёк')) &&
        q.contains('сертификат')) {
      return 'Продление срока сертификата — только через администратора: зависят номинал, активация и правила акции. '
          'Могу открыть чат админа. Какой код или когда покупали?';
    }

    if ((q.contains('мигрир') || q.contains('уедет') || q.contains('поплывёт') || q.contains('поплывет')) &&
        (q.contains('филлер') || q.contains('гиалурон') || q.contains('контур'))) {
      return 'Миграция филлера — редкий, но реальный риск: техника, объём и уход после решают; при смещении смотрят гиалуронидазу. '
          'Без осмотра «никогда не мигрирует» не обещаю. Запишем консультацию или открыть чат врача?';
    }

    if (q.contains('переводчик') ||
        q.contains('с перевод') ||
        (q.contains('прийт') && q.contains('перевод'))) {
      return 'С переводчиком прийти можно — предупредите администратора в чате, чтобы спокойно провели в кабинет и учли время на перевод. '
          'Клинические решения всё равно за врачом. Могу открыть чат админа.';
    }

    if ((q.contains('на имя') || q.contains('чужим именем') || q.contains('для подруг') || q.contains('имя подруг')) &&
        (q.contains('запис') || q.contains('записать'))) {
      return 'Запись на имя другого человека лучше оформить через администратора: нужны контакты того, кто придёт, и согласие на обработку данных. '
          'Могу открыть чат админа или записать вас, а данные гостя уточним на ресепшен.';
    }

    if ((q.contains('что такое') || q.contains('простыми словами')) &&
        (q.contains('mitochondrial') || q.contains('митохондр') || q.contains('fuel'))) {
      return 'Mitochondrial Fuel простыми словами — домашняя поддержка энергии клетки (АТФ), не укол и не капельница. '
          'Часто рядом с курсами восстановления; вечером обычно не пьют. Могу положить в корзину или сравнить с Cellular Catalyst.';
    }

    if ((q.contains('изотретиноин') ||
            q.contains('аккутан') ||
            q.contains('роаккутан') ||
            q.contains('изотретин')) &&
        (q.contains('филлер') ||
            q.contains('ботокс') ||
            q.contains('инъек') ||
            q.contains('мезо') ||
            q.contains('биоревитал'))) {
      return 'На изотретиноине (и часто ещё месяцы после) инъекции тоже часто ограничивают — решает врач по сроку отмены и коже, без самозаписи. '
          'Могу открыть чат специалиста или записать на консультацию после отмены курса.';
    }

    if ((q.contains('изотретиноин') ||
            q.contains('аккутан') ||
            q.contains('роаккутан') ||
            q.contains('изотретин')) &&
        (q.contains('пилинг') ||
            q.contains('чистк') ||
            q.contains('лазер') ||
            q.contains('ipl') ||
            q.contains('rf') ||
            q.contains('можно')) &&
        !q.contains('филлер') &&
        !q.contains('ботокс') &&
        !q.contains('инъек')) {
      return 'На изотретиноине (и часто ещё месяцы после) пилинги, лазеры и часть аппаратных под запретом или сильным ограничением — решает врач по сроку отмены. '
          'Без осмотра «да, пилим» не скажу. Могу открыть чат специалиста.';
    }

    if ((q.contains('звезд') || q.contains('звёзд') || q.contains('сосудист сетк') || q.contains('телеангиэктаз')) &&
        (q.contains('удал') || q.contains('убрать') || q.contains('делаете') || q.contains('можно'))) {
      return 'Сосудистые звёздочки на лице часто смотрят через IPL/световые протоколы после оценки фототипа — не «прижигаем дома». '
          'Запишем консультацию по сосудам или аппаратной?';
    }

    if (q.contains('анеми') &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При анемии капельницу красоты не назначаю сама — нужны анализы и допуск врача, часть составов не ставят при низком гемоглобине. '
          'Могу открыть чат специалиста или записать на консультацию после свежих цифр.';
    }

    if ((q.contains('биоревитал') || q.contains('мезотерап')) &&
        (q.contains('рук') || q.contains('кист') || q.contains('тыльн'))) {
      return 'Биоревитализацию и мезо кистей рук делаем после осмотра — кожа там тонкая, препарат и объём подбирает врач. '
          'Запишем консультацию по рукам?';
    }

    if (q.contains('нитев') ||
        q.contains('нитевой лифтинг') ||
        q.contains('aptos') ||
        q.contains('аптос') ||
        (q.contains('нити') &&
            (q.contains('лифтинг') || q.contains('подтя') || q.contains('делаете') || q.contains('есть ли'))) ||
        (q.contains('лифтинг') && q.contains('нит'))) {
      return 'Нитевой лифтинг (в т.ч. Aptos) обсуждаем только на осмотре: тип нитей, зоны и ожидания — не «как SMAS за один визит». '
          'Могу записать на консультацию или открыть чат специалиста. Какая зона важнее?';
    }

    if ((q.contains('подбородок') || q.contains('второй подбород')) &&
        (q.contains('крем') || q.contains('сыворот') || q.contains('дома'))) {
      return 'Кремом второй подбородок «сжечь» нельзя — дома максимум уход за кожей; овал чаще смотрят массажем и при необходимости RF после осмотра. '
          'Могу положить крем для шеи/овала в корзину или записать на массаж. Что ближе?';
    }

    if ((q.contains('мезотерап') || q.contains('биоревитал') || q.contains('мезо ')) &&
        (q.contains('месячн') ||
            q.contains('цикл') ||
            q.contains('критическ') ||
            q.contains('менструац'))) {
      return 'В дни цикла мезо и биоревитал иногда делают, если самочувствие ровное — учитывают отёк и чувствительность; при сильной боли лучше сдвинуть. '
          'Решает врач. Запишем с запасом по дате?';
    }

    if ((q.contains('отек') || q.contains('отекл') || q.contains('отёк')) &&
        (q.contains('после массаж') || (q.contains('после') && q.contains('массаж')))) {
      return 'Лёгкий отёк после массажа иногда бывает от притока лимфы — вода, меньше соли, голова чуть выше, без жёсткого тепла. '
          'Если отёк сильный, асимметричный или с болью — напишите врачу. Могу открыть чат.';
    }

    if ((q.contains('сини') || q.contains('сине') || q.contains('цианоз') || q.contains('посинел')) &&
        (q.contains('филлер') || q.contains('губ') || q.contains('после укол'))) {
      return 'Синева или резкая бледность в зоне филлера — не «просто синяк»: лучше сразу врачу, возможен осмотр на гиалуронидазу. '
          'Не грейте и не мните. Могу открыть чат специалиста сейчас.';
    }

    if ((q.contains('перед') || q.contains('до ботокс') || q.contains('до ботулин')) &&
        (q.contains('ботокс') || q.contains('ботулин')) &&
        (q.contains('нельзя') ||
            q.contains('что не') ||
            q.contains('подготов') ||
            q.contains('не делать'))) {
      return 'Перед ботулином обычно: без алкоголя накануне, сообщить лекарства и герпес, без плотного макияжа на зону; иногда просят паузу в спортзале. '
          'Точный лист — при записи. Запишем консультацию или сразу зону?';
    }

    if ((q.contains('smas') || q.contains('смас') || q.contains('ultherap')) &&
        (q.contains('свадьб') || q.contains('свадеб') || q.contains('мероприят') || q.contains('отек'))) {
      return 'После SMAS отёк и «усталый» вид могут держаться дни — к свадьбе закладывают запас, не ставят за сутки. '
          'Скажите дату события — подберём мягкий уход/массаж ближе к дню или SMAS заранее.';
    }

    if ((q.contains('что такое') || q.contains('простыми словами')) &&
        (q.contains('gluta') ||
            q.contains('глута') ||
            q.contains('liposomal') ||
            q.contains('липосомальн'))) {
      return 'Liposomal Gluta-Pure простыми словами — антиоксидантная поддержка (глутатион) в удобной для усвоения форме, не укол в лицо. '
          'Часто после аппаратных или как курс. Могу положить в корзину.';
    }

    if ((q.contains('чеш') || q.contains('зуд') || q.contains('зудит')) &&
        (q.contains('сыворот') ||
            q.contains('крем') ||
            q.contains('шоп') ||
            q.contains('магазин') ||
            q.contains('после средств') ||
            q.contains('из шопа'))) {
      return 'Зуд после новой сыворотки или крема — стоп средство, мягкое умывание, барьерный крем без активов; если отёк/сыпь нарастает — к врачу. '
          'Могу положить Lumen Barrier или открыть чат. Чем мазали и как давно?';
    }

    if ((q.contains('вегетариан') || q.contains('веган') || q.contains('без мяс')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц'))) {
      return 'Вегетарианство само по себе не запрет на капельницу — важнее анализы, дефициты и допуск врача по составу. '
          'На осмотре скажите про питание и добавки. Запишем консультацию по инфузиям?';
    }

    if (q.contains('астм') &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц'))) {
      return 'При астме капельницу не назначаю сама — нужен допуск врача, особенно если есть гормональные или аллергические нюансы. '
          'Могу открыть чат специалиста или записать на консультацию.';
    }

    if (q.contains('астм') &&
        (q.contains('rf') || q.contains('рф') || q.contains('микроиголь') || q.contains('аппарат'))) {
      return 'При астме RF не запрет автоматически, но врачу важно знать про дыхание, аллергии и лекарства — иногда уточняют допуск. '
          'Запишем консультацию по RF — скажете про астму на осмотре.';
    }

    if ((q.contains('рыбий жир') ||
            q.contains('омега') ||
            q.contains('антикоагулянт') ||
            q.contains('разжижа') ||
            q.contains('аспирин') ||
            q.contains('ибупрофен') ||
            q.contains('нпвс')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('филлер') || q.contains('инъек'))) {
      return 'Аспирин, НПВС, рыбий жир и омега иногда просят поставить на паузу перед инъекциями — меньше риск синяка; решает врач по дозе и сроку. '
          'Напишите, что пьёте и как давно — или откроем чат специалиста.';
    }

    if ((q.contains('опущ') || q.contains('птоз') || q.contains('упало век') || q.contains('нависло век')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('после'))) {
      return 'Опущенное веко после ботулина — повод сразу написать врачу: иногда нужна коррекция, сами не массируем и не «поднимаем» кремами. '
          'Могу открыть чат специалиста сейчас. Когда кололи и какая сторона?';
    }

    if ((q.contains('трогать') || q.contains('трогать лиц') || q.contains('нельзя трог') || q.contains('массир лиц')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('после'))) {
      return 'После ботулина зону обычно не разминают и не трут несколько часов — точнее в листе врача; умывание мягкое без жёсткого давления. '
          'Когда кололи?';
    }

    if ((q.contains('экспресс') || q.contains('30 мин') || q.contains('полчаса') || q.contains('быстрый протокол')) &&
        (q.contains('протокол') ||
            q.contains('уход') ||
            q.contains('есть ли') ||
            q.contains('что есть') ||
            q.contains('за 30'))) {
      return 'Экспресс без долгой реабилитации: часто скульптурный массаж или короткий уход около часа; «ровно 30 минут» зависит от слота. '
          'К событию сегодня — без пилингов и уколов. Запишем массаж или HydraPure?';
    }

    if ((q.contains('мужск') || q.contains('мужской уход')) &&
        (q.contains('скольк') || q.contains('стоит') || q.contains('цен')) &&
        !q.contains('rf') &&
        !q.contains('рф') &&
        !q.contains('лифтинг')) {
      final men = _clinicService('мужской уход', gender: gender) ??
          _clinicService('мужск', gender: gender);
      if (men != null) {
        return 'Мужской уход за лицом — ориентир ${men.priceLabel}, ${men.duration}. '
            'Без «розового» финиша. Запишем или сравнить с барбер-массажем?';
      }
      return 'Мужской уход в прайсе филиала — цену скажу при записи или из меню «Прайс». Запишем консультацию?';
    }

    if ((q.contains('мужск') || q.contains('для муж') || q.contains('барбер')) &&
        (q.contains('rf') || q.contains('рф')) &&
        (q.contains('массаж') || q.contains('барбер')) &&
        (q.contains('скольк') ||
            q.contains('стоит') ||
            q.contains('цен') ||
            q.contains('вместе') ||
            q.contains('и rf') ||
            q.contains('и рф'))) {
      final menRf = _clinicService('мужской rf', gender: gender);
      final barber = _clinicService('барбер', gender: gender);
      final rfPart = menRf != null
          ? 'мужской RF — ориентир ${menRf.priceLabel}'
          : 'мужской RF — по прайсу филиала';
      final barberPart = barber != null
          ? 'барбер-массаж — ${barber.priceLabel}'
          : 'барбер-массаж — по прайсу';
      return 'Если брать связку: $barberPart, $rfPart; в один день не всегда — после RF массаж зоны чаще с паузой. '
          'Итог и порядок на консультации. Запишем осмотр или сначала массаж?';
    }

    if ((q.contains('мужск') || q.contains('для муж')) &&
        (q.contains('rf') || q.contains('рф')) &&
        (q.contains('скольк') || q.contains('стоит') || q.contains('цен'))) {
      final menRf = _clinicService('мужской rf', gender: gender) ??
          _clinicService('мужской RF', gender: gender);
      if (menRf != null) {
        return 'Мужской RF-лифтинг — ориентир ${menRf.priceLabel}, ${menRf.duration}. '
            'Контур без «розового» сценария, после осмотра. Запишем консультацию или сразу RF?';
      }
      return 'Мужской RF в прайсе филиала — цену подтвержу при записи. Запишем осмотр?';
    }

    if ((q.contains('боюсь игл') ||
            q.contains('боюсь иглы') ||
            q.contains('боюсь иголка') ||
            q.contains('без укол')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц'))) {
      return 'Капельница — укол в вену, не в лицо: многие так спокойнее переносят, чем мезо или филлер. '
          'Если иглы пугают сильно — можно начать с массажа/ухода без уколов вообще. Что ближе — энергия или лицо без шприца?';
    }

    if ((q.contains('скул') || q.contains('скулы') || q.contains('скулов')) &&
        (q.contains('коррекц') ||
            q.contains('форм') ||
            q.contains('филлер') ||
            q.contains('делаете') ||
            q.contains('убрать') ||
            q.contains('хочу'))) {
      return 'Форму скул смотрим на осмотре: иногда достаточно массажа и овала, объём филлером — только если правда нужен и после разметки. '
          'Запишем консультацию по контуру?';
    }

    if ((q.contains('сертификат') &&
            (q.contains('английск') || q.contains('english') || q.contains('на англий'))) ||
        (q.contains('подарочн') && q.contains('английск'))) {
      return 'Подарочный сертификат оформляют в профиле или через администратора; текст/дизайн на английском — уточните в чате админа, сделаем под получателя. '
          'Могу открыть чат. Какой номинал примерно?';
    }

    if ((q.contains('что такое') || q.contains('простыми словами')) &&
        (q.contains('veil') ||
            q.contains('вейл') ||
            q.contains('veil peptide') ||
            (q.contains('peptide') && q.contains('serum') && !q.contains('neuro')))) {
      return 'Veil Peptide Serum простыми словами — ночная сыворотка плотности для дома: пептиды между визитами, не укол и не капельница. '
          'Могу положить в корзину или сравнить с барьерным кремом.';
    }

    if ((q.contains('что такое') || q.contains('простыми словами')) &&
        (q.contains('aura') || q.contains('mist') || q.contains('мист'))) {
      return 'Aura Mineral Mist простыми словами — минеральный спрей-фиксатор сияния для дома, не процедура в кресле. '
          'Удобно поверх ухода. Могу положить в корзину.';
    }

    if ((q.contains('биоревитал') || q.contains('мезотерап')) &&
        (q.contains('самолет') ||
            q.contains('перелет') ||
            q.contains('лететь') ||
            q.contains('летать') ||
            q.contains('авиа'))) {
      return 'После биоревитализации и мезо перелёт лучше с небольшим запасом — чаще ориентир от суток-двух, чтобы не усиливать отёк в салоне. '
          'Точный срок скажет врач. Когда вылет и когда кололи?';
    }

    if ((q.contains('ретейнер') || q.contains('ретейнер') || q.contains('ортодонтическ дуг')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('можно'))) {
      return 'Ретейнер сам по себе редко отменяет ботулин — врачу важно знать про конструкции во рту, особенно если зона рядом с жевательными. '
          'Запишем консультацию — скажете про ретейнер на осмотре.';
    }

    if ((q.contains('что взять') || q.contains('с собой')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('микроиголь'))) {
      return 'На RF: документ, список лекарств и аллергий, без плотного макияжа на зону; удобная одежда. '
          'Остальное — на ресепшен. Запишем микроигольчатый RF или консультацию сначала?';
    }

    if (q.contains('гастрит') &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При гастрите капельницу не назначаю сама — состав и переносимость решает врач с учётом ЖКТ и анализов. '
          'Могу открыть чат специалиста или записать на консультацию.';
    }

    if (q.contains('эпилепс') &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При эпилепсии капельницу и часть протоколов только с допуском врача — без самозаписи «для энергии». '
          'Могу открыть чат специалиста или записать на консультацию после разрешения невролога.';
    }

    if ((q.contains('спирал') || q.contains('вмс') || q.contains('внутриматоч')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('аппарат') || q.contains('можно'))) {
      return 'ВМС/спираль обычно не абсолютный запрет на RF лица, но врачу важно знать про металл и гинекологический фон — иногда уточняют допуск. '
          'Запишем консультацию по RF — скажете про спираль на осмотре.';
    }

    if ((q.contains('никель') || q.contains('никел') || (q.contains('металл') && q.contains('аллерг'))) &&
        (q.contains('rf') || q.contains('рф') || q.contains('микроиголь') || q.contains('аппарат') || q.contains('можно'))) {
      return 'Аллергию на никель и металлы обязательно скажите до RF — насадки и контакты иногда подбирают иначе, без самозаписи «на аппарат». '
          'Запишем консультацию по RF — врач учтёт реакцию на осмотре.';
    }

    if ((q.contains('подтверд') || q.contains('подтвержу')) &&
        (q.contains('голос') || q.contains('без кнопк') || q.contains('без кнопки')) &&
        (q.contains('запис') || q.contains('визит'))) {
      return 'Подтвердить запись одним голосом «да» нельзя — нужна ваша отметка кнопкой «Запись» в приложении после сводки. '
          'Скажите услугу и время — соберу черновик, а финал закрепите кнопкой. Так мы не оформляем визит случайно.';
    }

    if ((q.contains('очки') || q.contains('очков')) &&
        !q.contains('корочк') &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('после'))) {
      return 'После ботулина очки обычно можно — главное не давить и не разминать зону уколов тяжёлой оправой первые часы. '
          'Точный лист у врача. Когда кололи?';
    }

    if ((q.contains('барбер') &&
            (q.contains('скольк') || q.contains('стоит') || q.contains('цен'))) ||
        (q.contains('барбер-массаж') &&
            (q.contains('скольк') || q.contains('стоит') || q.contains('цен')))) {
      final barber = _clinicService('барбер', gender: gender);
      if (barber != null) {
        return 'Барбер-массаж лица — ориентир ${barber.priceLabel}, ${barber.duration}. '
            'Плотный мужской протокол без «розового» финиша. Запишем?';
      }
      return 'Барбер-массаж в прайсе филиала — цену скажу при записи. Запишем окно?';
    }

    if ((q.contains('после филлер') || (q.contains('филлер') && q.contains('после'))) &&
        q.contains('массаж') &&
        (q.contains('шеи') || q.contains('шею') || q.contains('шея'))) {
      return 'После филлера массаж зоны уколов обычно на паузе; шею иногда трогают мягко, если лицо не давили — решает врач по зоне и сроку. '
          'Когда кололи и куда? Могу открыть чат специалиста.';
    }

    if ((q.contains('после филлер') || (q.contains('филлер') && q.contains('после'))) &&
        q.contains('массаж') &&
        (q.contains('лиц') || q.contains('можно') || q.contains('недел'))) {
      return 'После филлера массаж зоны уколов обычно на паузе дни–недели — срок и зона на листе врача; через неделю иногда уже мягко, если так разрешили. '
          'Не мнём сами «для ровности». Когда кололи и куда? Могу открыть чат специалиста.';
    }

    if ((q.contains('лазерн') || q.contains('лазерное омолож') || q.contains('лазер омолож')) &&
        (q.contains('омолож') || q.contains('делаете') || q.contains('есть ли') || q.contains('лиц'))) {
      return 'Лазерное и световое омоложение у нас в аппаратном блоке — чаще IPL/Lumecca и смежные протоколы после оценки фототипа, не «лазер для всех». '
          'Запишем консультацию по свету?';
    }

    if ((q.contains('лидокаин') || q.contains('анестез')) &&
        (q.contains('аллерг') || q.contains('не перенос')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('можно') || q.contains('аппарат'))) {
      return 'Аллергию на лидокаин обязательно скажите до RF: подберут другую анестезию или протокол без неё. '
          'Без осмотра «да, можно всем» не обещаю. Запишем консультацию или откроем чат врача?';
    }

    if ((q.contains('ipl') || q.contains('лазер') || q.contains('lumecca')) &&
        (q.contains('загар') || q.contains('солнц') || q.contains('сочи'))) {
      return 'После свежего загара IPL и лазеры часто откладывают — выше риск пятна; врач смотрит фототип и срок после солнца. '
          'Запишем консультацию — скажем, когда можно вспышку.';
    }

    if ((q.contains('anti-age') ||
            q.contains('anti age') ||
            q.contains('антивозраст') ||
            q.contains('омоложен')) &&
        (q.contains('мужск') || q.contains('мужчин') || q.contains('для муж') || q.contains('40'))) {
      return 'Мужской anti-age без «розового» сценария: барбер-массаж, уход, при необходимости RF по овалу — курс после осмотра. '
          'Возраст 40+ — ориентир, смотрим кожу. Запишем консультацию или массаж?';
    }

    if ((q.contains('морщин') && (q.contains('лоб') || q.contains('на лбу'))) &&
        (q.contains('без ботокс') || q.contains('без укол') || q.contains('без инъек'))) {
      return 'Морщины на лбу без ботулина: уход, SPF, скульптурный массаж; аппаратные — после осмотра. '
          'Инъекции не предлагаю, пока сами не попросите. Запишем массаж или консультацию?';
    }

    if ((q.contains('сертификат') &&
            (q.contains('частич') || q.contains('частично')) &&
            (q.contains('карт') || q.contains('остат') || q.contains('доплат'))) ||
        (q.contains('сертификат') && q.contains('оплат') && q.contains('карт'))) {
      return 'Сертификатом и картой вместе часто можно: номинал сертификата списывают, остаток — картой на ресепшен; точные правила зависят от кода и акции. '
          'Уточнит администратор в чате или на стойке. Помочь открыть чат?';
    }

    if ((q.contains('сертификат') &&
            (q.contains('чуж') ||
                q.contains('друг') ||
                q.contains('подруг') ||
                q.contains('процедур'))) ||
        (q.contains('оплатить сертификат') && q.contains('чуж'))) {
      return 'Сертификатом можно оплатить визит другого человека, если код активен и админ подтвердит на ресепшен — правила зависят от номинала. '
          'Могу открыть чат администратора. Кто придёт и какой код примерно?';
    }

    if ((q.contains('подбород') && q.contains('филлер')) ||
        (q.contains('коррекц') && q.contains('подбород'))) {
      return 'Коррекцию подбородка филлером делают после осмотра и разметки — объём и проекция индивидуальны, не «шаблонный шарик». '
          'Запишем консультацию по контуру?';
    }

    if ((q.contains('розацеа') || q.contains('купероз')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('beauty') || q.contains('glow'))) {
      return 'При розацеа капельницу Beauty & Glow не назначаю вслепую — сначала допуск врача, на лице без обострения; иногда важнее уход и IPL, чем инфузия. '
          'Запишем консультацию или откроем чат специалиста?';
    }

    if ((q.contains('бров') || q.contains('архитектур бров') || q.contains('коррекция бров')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('после')) &&
        (q.contains('студи') || q.contains('салон') || q.contains('другой') || q.contains('можно'))) {
      return 'После ботулина брови в другой студии лучше с паузой — не тянуть и не распаривать зону первые дни; точный срок в листе врача. '
          'Когда кололи?';
    }

    if ((q.contains('купить') || q.contains('взять')) &&
        (q.contains('крем') || q.contains('сыворот') || q.contains('шоп')) &&
        (q.contains('без консультац') || q.contains('можно ли') || q.contains('нужна ли'))) {
      return 'Крем и сыворотки из шопа можно купить без процедуры — самовывоз на ресепшен или корзина в приложении. '
          'Если кожа реактивная, короткий совет всё же полезен. Назовите формулу — положу в корзину или подскажу.';
    }

    if ((q.contains('щитовид') || q.contains('тиреоид') || q.contains('гипотиреоз') || q.contains('гипертиреоз')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При заболеваниях щитовидки капельницу не назначаю сама — состав и гормональный фон смотрит врач, иногда нужны свежие анализы. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('гепатит') || q.contains('hepatit')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'Гепатит в анамнезе — важный сигнал: капельницу только после допуска врача и уточнения статуса/анализов, без самозаписи «для энергии». '
          'Могу открыть чат специалиста или записать на консультацию.';
    }

    if ((q.contains('варикоз') || q.contains('варикозн')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('аппарат') || q.contains('можно'))) {
      return 'При варикозе ног RF лица часто обсуждают отдельно: ноги и лицо — разные зоны, но врачу важно знать сосудистый фон и отёки. '
          'Без осмотра «да всем» не обещаю. Запишем консультацию по RF — скажете про варикоз.';
    }

    if ((q.contains('мужск') || q.contains('барбер')) &&
        (q.contains('абонемент') || q.contains('пакет') || q.contains('курс')) &&
        (q.contains('массаж') || q.contains('барбер') || q.contains('есть ли'))) {
      return 'Отдельного «мужского абонемента» на барбер-массаж в меню нет — курс и скидку по карте лояльности собирают на консультации или у администратора. '
          'Могу записать на барбер-массаж или открыть чат админа. Как удобнее?';
    }

    if ((q.contains('пакет') || q.contains('абонемент') || q.contains('курс из')) &&
        q.contains('массаж') &&
        !q.contains('барбер') &&
        !q.contains('мужск') &&
        (q.contains('скидк') ||
            q.contains('5 ') ||
            q.contains('пять') ||
            q.contains('пяти') ||
            q.contains('пят ') ||
            q.contains('из 5') ||
            q.contains('на 5') ||
            q.contains('есть ли'))) {
      return 'Отдельной кнопки «пакет из 5 массажей» в меню нет — курс и скидку по карте лояльности собирают на консультации или у администратора. '
          'Welcome-бонус новым клиентам 3 000 ₽ после входа. Могу открыть чат админа или записать на первый массаж.';
    }

    if ((q.contains('магний') || q.contains('magnesium')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('можно'))) {
      return 'Магний сам по себе редко отменяет ботулин — врачу важно знать дозу и другие препараты/БАДы. '
          'Без осмотра «пейте и колите» не обещаю. Запишем консультацию — скажете про магний на осмотре.';
    }

    if ((q.contains('йог') ||
            q.contains('спорт') ||
            q.contains('тренир') ||
            q.contains('фитнес') ||
            q.contains('зал')) &&
        (q.contains('после капель') ||
            q.contains('после инфуз') ||
            (q.contains('после') && (q.contains('капельниц') || q.contains('инфуз'))))) {
      return 'После капельницы йогу и жёсткий спорт в тот же день лучше не планировать — сосуды и самочувствие ещё «разгоняются»; лёгкая прогулка обычно ок. '
          'Чаще пауза до следующего дня, точнее врач по составу. Когда была инфузия?';
    }

    if ((q.contains('smas') || q.contains('смас') || q.contains('ultherap')) &&
        (q.contains('лететь') ||
            q.contains('летать') ||
            q.contains('самолет') ||
            q.contains('перелет') ||
            q.contains('авиа') ||
            q.contains('вылет'))) {
      return 'После SMAS перелёт лучше с запасом — чаще ориентир от нескольких дней, не «утром процедура — вечером рейс»: возможны отёк и чувствительность. '
          'Точный срок скажет врач по протоколу. Когда вылет и когда SMAS?';
    }

    if ((q.contains('каменн') ||
            q.contains('замороз') ||
            q.contains('маска из лиц') ||
            q.contains('не двигается') ||
            q.contains('нет мимик')) &&
        !q.contains('желч') &&
        !q.contains('желчнокамен') &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('после'))) {
      return '«Каменное» лицо после ботулина бывает при сильной дозе или пока препарат «садится» первые дни — без разминания зоны. '
          'Если мимика почти исчезла или асимметрия растёт — сразу врачу в чат, не ждём молча. Могу открыть чат специалиста.';
    }

    if ((q.contains('rf') || q.contains('рф') || q.contains('микроиголь')) &&
        (q.contains('горяч') || q.contains('жар') || q.contains('печёт') || q.contains('печет') || q.contains('горит')) &&
        (q.contains('после') || q.contains('вечер') || q.contains('норм'))) {
      return 'После RF тёплое или «горячее» лицо вечером часто норма первые сутки — кожа восстанавливается; без льда «на глаз» и без сауны. '
          'Если жар с сильным отёком, пузырями или температурой — сразу врачу в чат. Могу открыть чат специалиста.';
    }

    if ((q.contains('что такое') || q.contains('простыми словами') || q.contains('зачем') || q.contains('для чего')) &&
        (q.contains('circadian') ||
            q.contains('циркад') ||
            q.contains('light panel') ||
            q.contains('лайт панель') ||
            (q.contains('панель') && q.contains('свет')))) {
      return 'Circadian Light Panel простыми словами — домашняя панель утреннего света: короткая сессия после подъёма, не процедура в кресле и не капельница. '
          'Могу положить в корзину или сравнить с другими формулами биохакинг-шопа.';
    }

    if ((q.contains('как часто') || q.contains('как часто можно') || q.contains('интервал')) &&
        (q.contains('hydrapure') || q.contains('hydra') || q.contains('гидрапур'))) {
      return 'HydraPure чаще ставят курсом или по состоянию кожи — ориентир раз в 2–4 недели, без жёсткого «каждый день»; точнее врач по барьеру. '
          'Запишем уход или консультацию — подберём ритм.';
    }

    if ((q.contains('без игл') ||
            q.contains('без укол') ||
            q.contains('без инъек') ||
            q.contains('без шприц')) &&
        (q.contains('свидан') ||
            q.contains('вечер') ||
            q.contains('сегодня') ||
            q.contains('перед'))) {
      return 'К вечеру без игл спокойно: скульптурный массаж или увлажняющий уход HydraPure — свежий вид без отёка «на выход». '
          'Пилинги и аппаратную к свиданию сегодня не беру. Запишем массаж или уход?';
    }

    if ((q.contains('диабет') || q.contains('сахарн диабет')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При диабете капельницу не назначаю сама — сахар, лекарства и состав смотрит врач, иногда нужны свежие анализы. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('диабет') || q.contains('сахарн диабет')) &&
        (q.contains('мезо') ||
            q.contains('биоревитал') ||
            q.contains('филлер') ||
            q.contains('ботокс') ||
            q.contains('инъек') ||
            q.contains('можно'))) {
      return 'При диабете мезо и другие инъекции только после допуска врача — заживление и сахар учитываем очно, без самозаписи. '
          'Могу открыть чат специалиста или записать на консультацию.';
    }

    if ((q.contains('контрацептив') ||
            q.contains('протиовозачат') ||
            q.contains('ок ') ||
            q.contains('гормонал') && q.contains('таблет')) &&
        (q.contains('пилинг') || q.contains('чистк') || q.contains('можно'))) {
      return 'Гормональные контрацептивы сами по себе редко отменяют пилинг — врачу важно знать препарат и склонность к пигменту; загар и SPF всё равно критичны. '
          'Запишем консультацию по пилингу — скажете про контрацептивы на осмотре.';
    }

    if ((q.contains('сменить врач') ||
            q.contains('другого врач') ||
            q.contains('другого доктор') ||
            q.contains('поменять врач') ||
            (q.contains('сменить') && q.contains('врач'))) &&
        (q.contains('запис') || q.contains('голос') || q.contains('хочу'))) {
      return 'Сменить врача в уже собранной записи удобнее в профиле → «Мои записи» или через чат администратора — голосом я врача в слоте сама не переписываю. '
          'Могу открыть чат админа. Какой специалист нужен?';
    }

    if ((q.contains('за город') ||
            q.contains('загород') ||
            q.contains('область') ||
            q.contains('далеко')) &&
        (q.contains('доставк') || q.contains('курьер') || q.contains('шоп') || q.contains('магазин'))) {
      return 'Доставку шопа за город и по области уточняйте у администратора в чате — зоны курьера зависят от адреса и дня. '
          'Самовывоз на ресепшен всегда доступен. Могу открыть чат админа или положить формулу в корзину.';
    }

    if ((q.contains('почечн') ||
            q.contains('почк') ||
            q.contains('хпн') ||
            q.contains('недостаточн')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При почечной недостаточности капельницу только после допуска врача — объём и состав критичны, без самозаписи. '
          'Могу открыть чат специалиста или записать на консультацию.';
    }

    if ((q.contains('вич') || q.contains('hiv') || q.contains('спид')) &&
        (q.contains('эстет') ||
            q.contains('процедур') ||
            q.contains('можно') ||
            q.contains('капель') ||
            q.contains('инъек') ||
            q.contains('уход') ||
            q.contains('массаж') ||
            q.contains('rf') ||
            q.contains('ботокс'))) {
      return 'ВИЧ-статус сам по себе не закрывает эстетику автоматически — решение после осмотра, с учётом терапии, анализов и зоны. '
          'Без допуска «на всё» не записываю. Могу открыть чат специалиста или консультацию.';
    }

    if ((q.contains('антидепресс') ||
            q.contains('антидепресант') ||
            q.contains('сертралин') ||
            q.contains('эсциталопрам') ||
            q.contains('флуоксетин') ||
            q.contains('пароксетин')) &&
        (q.contains('ботокс') || q.contains('ботулин') || q.contains('можно'))) {
      return 'Антидепрессанты сами по себе редко отменяют ботулин — врачу важно знать препарат и дозу, иногда смотрят связку с другими лекарствами. '
          'Без осмотра «пейте и колите» не обещаю. Запишем консультацию — скажете список на осмотре.';
    }

    if ((q.contains('отмен') ||
            q.contains('перенес') ||
            q.contains('перенос') ||
            q.contains('изменить время') ||
            q.contains('сдвинуть') ||
            (q.contains('час раньше') || q.contains('час позже'))) &&
        (q.contains('запис') ||
            q.contains('визит') ||
            q.contains('приём') ||
            q.contains('прием') ||
            q.contains('голос') ||
            q.contains('время'))) {
      return 'Без стресса: отменить или сдвинуть визит можно в профиле → «Мои записи» или через чат администратора. '
          'Чем раньше напишете, тем проще подобрать новое окно. Голосом слот сама не двигаю — нужна отметка в приложении или админ.';
    }

    if ((q.contains('купить') || q.contains('без консультац') || q.contains('можно ли')) &&
        (q.contains('veil') || q.contains('вейл') || q.contains('пептид')) &&
        (q.contains('без') || q.contains('можно'))) {
      return 'Veil Peptide можно купить без очной консультации — самовывоз на ресепшен или корзина в приложении. '
          'Если кожа реактивная, короткий совет всё же полезен. Могу положить в корзину.';
    }

    if ((q.contains('синяк') || q.contains('гематом') || q.contains('синяч')) &&
        (q.contains('мезо') || q.contains('биоревитал') || q.contains('инъек')) &&
        (q.contains('боюсь') ||
            q.contains('страх') ||
            q.contains('фотосесс') ||
            q.contains('съёмк') ||
            q.contains('съемк') ||
            q.contains('важн') ||
            q.contains('к встреч'))) {
      return 'Синяки после мезо возможны — к важной съёмке закладывают запас в несколько дней, не колим «накануне». '
          'Можно начать с осмотра без процедуры в тот же день. Когда фотосессия?';
    }

    if ((q.contains('без кислот') ||
            q.contains('без пилинг') ||
            q.contains('без агресс')) &&
        (q.contains('уход') || q.contains('встреч') || q.contains('утром') || q.contains('перед'))) {
      return 'Перед важной встречей без кислот спокойно: скульптурный массаж или увлажняющий уход HydraPure — свежий вид без шелушения. '
          'Пилинг и жёсткие активы к утру не беру. Запишем массаж или уход?';
    }

    if ((q.contains('тромбоз') || q.contains('тромбофлебит') || q.contains('тромбоэмбол')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При тромбозе в анамнезе капельницу не назначаю сама — сосудистый риск и состав смотрит врач, иногда нужен допуск смежника. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('онколог') || q.contains('рак ') || q.contains('опухол') || q.contains('химиотерап') || q.contains('в ремисси')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При онкологии даже в ремиссии капельницу только после допуска врача — состав и сроки решают очно, без самозаписи «для энергии». '
          'Могу открыть чат специалиста или записать на консультацию.';
    }

    if ((q.contains('коррекц') || q.contains('делаете') || q.contains('есть ли')) &&
        (q.contains('уш') || q.contains('отопласт') || q.contains('лопоух'))) {
      return 'Коррекцию ушей и отопластику не делаем — CULT про кожу, инъекции, аппаратную и инфузии, не ЛОР/пластику ушной раковины. '
          'Если задача про кожу лица рядом — могу подсказать уход или консультацию.';
    }

    if ((q.contains('пигмент') || q.contains('пятн') || q.contains('веснуш')) &&
        (q.contains('крем') || q.contains('дом') || q.contains('без лазер') || q.contains('без аппарат') || q.contains('без ipl'))) {
      return 'Пигмент кремом без лазера: дома барьер, SPF каждый день и мягкие осветляющие только по допуску; в кресле иногда пилинг по фототипу — не «сжечь пятно». '
          'Могу положить Lumen Barrier в корзину или записать на консультацию по тону.';
    }

    if ((q.contains('как часто') || q.contains('как часто можно') || q.contains('интервал')) &&
        (q.contains('лимфодрен') || (q.contains('массаж') && q.contains('лимф')))) {
      return 'Лимфодренажный массаж чаще ставят курсом или по отёку — ориентир раз в неделю–две, без жёсткого «каждый день»; точнее по самочувствию и цели. '
          'Запишем массаж или консультацию — подберём ритм.';
    }

    if ((q.contains('что взять') || q.contains('с собой')) &&
        (q.contains('smas') || q.contains('смас') || q.contains('ultherap'))) {
      return 'На SMAS: документ, список лекарств и аллергий, без плотного макияжа на зону; удобная одежда, вода по желанию. '
          'Остальное — на ресепшен. Запишем консультацию по SMAS сначала?';
    }

    if ((q.contains('без отдуш') ||
            q.contains('без аромат') ||
            q.contains('без парфюм') ||
            q.contains('непахуч')) &&
        (q.contains('уход') || q.contains('крем') || q.contains('кож') || q.contains('чувствит') || q.contains('дом'))) {
      return 'Без отдушки для чувствительной кожи из шопа чаще смотрим барьерный крем Lumen Barrier — спокойная база без «парфюма в лицо». '
          'Могу положить в корзину или сравнить с пептидной сывороткой, если кожа уже спокойная.';
    }

    if ((q.contains('рассрочк') || q.contains('кредит') || q.contains('частям')) &&
        (q.contains('rf') ||
            q.contains('рф') ||
            q.contains('курс') ||
            q.contains('есть ли') ||
            q.contains('smas') ||
            q.contains('смас') ||
            q.contains('ultherap') ||
            q.contains('альтера'))) {
      if (q.contains('smas') || q.contains('смас') || q.contains('ultherap') || q.contains('альтера')) {
        return 'Рассрочку и оплату частями на Ultherapy® / SMAS уточняйте на ресепшен или у администратора в чате — условия зависят от суммы протокола. '
            'Могу открыть чат админа. Запишем консультацию по SMAS параллельно?';
      }
      return 'Рассрочку и оплату частями на курс RF уточняйте на ресепшен или у администратора в чате — условия зависят от суммы. '
          'Могу открыть чат админа. Запишем консультацию по RF параллельно?';
    }

    if ((q.contains('корочк') || q.contains('корочка') || q.contains('струп')) &&
        (q.contains('ipl') || q.contains('айпи') || q.contains('lumecca') || q.contains('после света'))) {
      return 'Тонкие корочки после IPL иногда бывают в рамках восстановления — не сдираем, мягкий умывание, барьер, SPF, без кислот. '
          'Если мокнут, гноятся или зона сильно болит — сразу врачу в чат. Могу открыть чат специалиста.';
    }

    if ((q.contains('корочк') || q.contains('корочка') || q.contains('струп')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('микроиголь')) &&
        !q.contains('ipl') &&
        !q.contains('айпи')) {
      return 'Тонкие корочки после RF иногда бывают в рамках восстановления — не сдираем, мягкий умывание, барьер, без кислот и сауны. '
          'Если мокнут, гноятся или зона сильно болит — сразу врачу в чат. Могу открыть чат специалиста.';
    }

    if ((q.contains('ретинол') || q.contains('кислот')) &&
        (q.contains('ipl') || q.contains('айпи') || q.contains('lumecca') || q.contains('после ipl') || q.contains('после света')) &&
        (q.contains('после') || q.contains('через') || q.contains('можно'))) {
      return 'После IPL ретинол и кислоты обычно на паузе несколько дней–недель — ориентир даст врач по протоколу; через пять дней не всегда ещё рано или поздно «для всех». '
          'Пока барьер и SPF. Когда была вспышка?';
    }

    if ((q.contains('аутоиммун') || q.contains('аутоимун') || q.contains('системн заболев')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При аутоиммунном заболевании капельницу не назначаю сама — состав и активность процесса смотрит врач, иногда нужен допуск смежника. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('загар') || q.contains('загор') || q.contains('с моря') || q.contains('солнц')) &&
        (q.contains('пилинг') || q.contains('кислот')) &&
        (q.contains('можно') || q.contains('свеж') || q.contains('если'))) {
      return 'После свежего загара пилинг часто откладывают — выше риск пятна и раздражения; врач смотрит фототип и срок после солнца. '
          'Запишем консультацию — скажем, когда можно кислоты.';
    }

    if ((q.contains('отек') || q.contains('отёк') || q.contains('одутл')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц')) &&
        (q.contains('боюсь') || q.contains('страх') || q.contains('вечерин') || q.contains('событ') || q.contains('к '))) {
      return 'После капельницы сильный отёк лица бывает редко; к вечеринке в тот же день лучше лёгкий состав и запас по самочувствию — не «капельница за час до выхода». '
          'Можно начать с консультации. Когда событие?';
    }

    if ((q.contains('целов') || q.contains('поцелу') || q.contains('целовать')) &&
        (q.contains('биоревитал') || q.contains('мезо'))) {
      return 'После биоревитализации и мезо поцелуи лучше мягко на сутки — меньше раздражения папул; без разминания зоны. '
          'Точный лист у врача. Когда кололи?';
    }

    if ((q.contains('календар') || q.contains('reminder') || q.contains('напоминал') || q.contains('напоминание')) &&
        (q.contains('голос') || q.contains('добав') || q.contains('хочу') || q.contains('запис'))) {
      return 'Календарное напоминание о визите удобнее в профиле → «Мои записи» или через уведомления телефона после подтверждения кнопкой «Запись». '
          'Голосом я слот в системный календарь сама не пишу — соберём запись, а напоминание подхватит приложение.';
    }

    if ((q.contains('блефаропласт') ||
            (q.contains('пластик') && q.contains('век')) ||
            (q.contains('операц') && q.contains('век'))) &&
        (q.contains('делаете') || q.contains('есть ли') || q.contains('можно'))) {
      return 'Блефаропластику и хирургию век не делаем — CULT про кожу, инъекции, аппаратную и инфузии, не пластическую хирургию. '
          'Веки без операции иногда смотрят уходом и массажем после осмотра. Запишем консультацию по взгляду?';
    }

    if (q.contains('ринопласт') ||
        (q.contains('пластик') && q.contains('нос')) ||
        (q.contains('операц') && q.contains('нос'))) {
      return 'Ринопластику и хирургию носа не делаем — CULT про кожу, инъекции, аппаратную и инфузии, не пластическую хирургию. '
          'Форму носа косметологией «как после операции» не обещаю. Могу записать на консультацию по контуру лица, если задача мягче.';
    }

    if (q.contains('увеличение груди') ||
        q.contains('маммопласт') ||
        q.contains('имплант груди') ||
        q.contains('импланты груди') ||
        (q.contains('груди') &&
            (q.contains('увеличи') || q.contains('пластик') || q.contains('операц')))) {
      return 'Увеличение груди и маммопластику не делаем — CULT про кожу, инъекции, аппаратную и инфузии, не пластическую хирургию тела. '
          'По лицу и телу без имплантов могу предложить уход, массаж или консультацию. Что важнее сейчас?';
    }

    if (q.contains('липосакц') || (q.contains('липо') && (q.contains('операц') || q.contains('делаете')))) {
      return 'Липосакцию и хирургическое удаление жира не делаем — CULT про кожу, инъекции, аппаратную и инфузии, не пластическую хирургию тела. '
          'Овал и контур без операции иногда смотрят массажем и RF после осмотра. Запишем консультацию?';
    }

    if (q.contains('абдоминопласт') ||
        (q.contains('пластик') && q.contains('живот')) ||
        (q.contains('операц') && q.contains('живот') && q.contains('делаете'))) {
      return 'Абдоминопластику и хирургию живота не делаем — CULT про кожу, инъекции, аппаратную и инфузии, не пластическую хирургию тела. '
          'Могу предложить уход, массаж или консультацию по лицу/телу без операции. Что важнее сейчас?';
    }

    if (q.contains('пересадк') && (q.contains('волос') || q.contains('волос'))) {
      return 'Пересадку волос не делаем — CULT про кожу лица, инъекции, аппаратную и инфузии, не трихотрансплантацию. '
          'По коже головы иногда смотрят уход и консультацию врача, без обещания «как после пересадки». Могу открыть чат специалиста.';
    }

    if (q.contains('лабиопласт') ||
        q.contains('лабиопластика') ||
        (q.contains('пластик') && (q.contains('интим') || q.contains('половых губ')))) {
      return 'Лабиопластику и интимную пластику не делаем — CULT про кожу лица, инъекции, аппаратную и инфузии, не гинекологическую хирургию. '
          'Могу открыть чат специалиста или записать на консультацию по лицу/телу без операции.';
    }

    if ((q.contains('аритм') || q.contains('мерцательн') || q.contains('фибрилляц')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При аритмии капельницу не назначаю сама — нужен допуск кардиолога и решение врача CULT по составу и самочувствию. '
          'Могу открыть чат специалиста или записать на консультацию после разрешения.';
    }

    if ((q.contains('холецист') || q.contains('желчн пузыр')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При холецистите капельницу не назначаю сама — нагрузку на ЖКТ и состав смотрит врач, иногда нужен допуск гастроэнтеролога. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('пролактин') || q.contains('гиперпролактин')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При повышенном пролактине капельницу не назначаю сама — гормональный фон и состав смотрит врач, иногда нужны свежие анализы и допуск эндокринолога. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('мигрен') || (q.contains('головн') && q.contains('часто'))) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно')) &&
        !q.contains('ботокс') &&
        !q.contains('ботулин')) {
      return 'При частых мигренях капельницу не назначаю сама — состав и триггеры смотрит врач, иногда нужен допуск невролога. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('подагр') || q.contains('мочев кислот')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При подагре капельницу не назначаю сама — обмен мочевой кислоты и состав смотрит врач, иногда нужны свежие анализы. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('язвенн') || q.contains('язва желуд') || q.contains('язва двенад')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При язвенной болезни капельницу не назначаю сама — нагрузку на ЖКТ и состав смотрит врач, иногда нужен допуск гастроэнтеролога. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('домашн') || q.contains('крем') || q.contains('сыворот') || q.contains('уход') || q.contains('набор')) &&
        (q.contains('после пилинг') ||
            (q.contains('после') && q.contains('пилинг')) ||
            (q.contains('после') && q.contains('l3'))) &&
        !q.contains('витамин') &&
        !q.contains('макияж')) {
      return 'После химического пилинга дома обычно мягкий барьерный уход без кислот и ретинола первые дни, SPF обязателен; точный лист даст врач. '
          'Могу положить Lumen Barrier в корзину. Когда делали пилинг и как кожа сейчас?';
    }

    if ((q.contains('домашн') || q.contains('набор') || q.contains('крем') || q.contains('сыворот') || q.contains('уход')) &&
        (q.contains('после ipl') ||
            (q.contains('после') && (q.contains('ipl') || q.contains('айпи') || q.contains('lumecca') || q.contains('света'))))) {
      return 'После IPL дома обычно мягкий барьерный уход без кислот и ретинола первые дни, SPF обязателен; точный лист даст врач. '
          'Могу положить Lumen Barrier в корзину или собрать спокойный набор из шопа. Когда была вспышка?';
    }

    if ((q.contains('вторую услуг') ||
            q.contains('вторая услуг') ||
            q.contains('ещё услуг') ||
            q.contains('еще услуг') ||
            (q.contains('добавить') && q.contains('услуг') && q.contains('запис'))) &&
        (q.contains('запис') || q.contains('собран') || q.contains('слот'))) {
      return 'Вторую услугу к уже собранной записи удобнее добавить через чат администратора или в «Мои записи» — голосом я слот сама не переписываю. '
          'Скажите, что добавить и день — открою чат админа или соберём новую запись рядом.';
    }

    if ((q.contains('детск') || q.contains('подрост') || q.contains('несовершеннолет')) &&
        (q.contains('прайс') || q.contains('цен') || q.contains('скидк') || q.contains('тариф'))) {
      return 'Отдельного «детского прайса» в CULT нет: большинство эстетических протоколов — с 18 лет, подростков ведём только очно с согласием опекуна. '
          'Могу открыть чат администратора уточнить правила филиала.';
    }

    if ((q.contains('что такое') || q.contains('простыми словами')) &&
        (q.contains('neuro') ||
            q.contains('нейро') ||
            q.contains('neuro-regen') ||
            (q.contains('regen') && q.contains('serum')))) {
      return 'Neuro-Regen IV Serum простыми словами — домашняя сыворотка поддержки ясности и когнитивного тонуса, не капельница в кресле и не укол в лицо. '
          'Могу положить в корзину или сравнить с Mitochondrial Fuel.';
    }

    if ((q.contains('губ') &&
            (q.contains('больше') || q.contains('меньше') || q.contains('разн') || q.contains('асимметр')) &&
            (q.contains('после') || q.contains('филлер') || q.contains('день'))) ||
        (q.contains('одна губ') && q.contains('друг'))) {
      return 'Разная величина губ на 1–2 день после филлера часто от отёка — без разминания, холод по схеме врача. '
          'Если асимметрия сильная, растёт или белеет зона — сразу врачу в чат, возможен осмотр. Могу открыть чат специалиста.';
    }

    if ((q.contains('панкреатит') || q.contains('поджелудоч')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При панкреатите капельницу не назначаю сама — нагрузку на ЖКТ и состав смотрит врач, иногда нужен допуск смежника и свежие анализы. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('ipl') || q.contains('айпи') || q.contains('lumecca')) &&
        q.contains('массаж') &&
        (q.contains('скольк') || q.contains('стоит') || q.contains('цен') || q.contains('вместе'))) {
      final ipl = devices.where((d) => d.title.toLowerCase().contains('lumecca') || d.title.toLowerCase().contains('ipl')).firstOrNull;
      final massage = _clinicService('скульптурн', gender: gender) ??
          _clinicService('массаж', gender: gender);
      final i = ipl == null ? 'Lumecca IPL' : '${ipl.title} — ориентир ${ipl.price}';
      final m = massage == null ? 'скульптурный массаж' : '${massage.title} — ориентир ${massage.priceLabel}';
      return 'По отдельности: $i; $m. В один день свет и массаж зоны часто разносят — порядок скажет врач. '
          'Запишем консультацию или два окна отдельно?';
    }

    if ((q.contains('набор') || q.contains('восстанов')) &&
        (q.contains('барьер') || q.contains('после пилинг') || (q.contains('после') && q.contains('пилинг'))) &&
        (q.contains('хочу') || q.contains('нужен') || q.contains('подбери'))) {
      return 'После пилинга барьер восстанавливают мягко: Lumen Barrier Cream и спокойная сыворотка без кислот; SPF обязателен. '
          'Могу положить крем в корзину или сравнить с Veil Peptide, когда кожа уже не жжёт. Что ближе — крем или набор?';
    }

    if ((q.contains('бонус') || q.contains('балл')) &&
        (q.contains('подруг') || q.contains('друг') || q.contains('другому') || q.contains('чуж')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('оплат') || q.contains('можно'))) {
      return 'Бонусами CULT обычно платит владелец карты со своего профиля — оплатить капельницу подруге бонусами с вашей карты уточните на ресепшен: правила зависят от уровня. '
          'Чаще удобнее сертификат или её собственный вход. Могу открыть чат админа.';
    }

    if ((q.contains('домашн') || q.contains('крем') || q.contains('сыворот') || q.contains('уход')) &&
        (q.contains('после rf') ||
            q.contains('после рф') ||
            ((q.contains('rf') || q.contains('рф') || q.contains('микроиголь')) && q.contains('после')))) {
      return 'После микроигольчатого RF дома обычно мягкий барьерный уход без кислот и ретинола первые дни, SPF; точный лист даст врач. '
          'Могу положить Lumen Barrier в корзину или открыть чат, если зона сильно жжёт. Когда была процедура?';
    }

    if ((q.contains('латекс') || q.contains('latex')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц'))) {
      return 'Аллергию на латекс обязательно скажите до капельницы — жгут, перчатки и расходники подбирают иначе, без самозаписи. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('латекс') || q.contains('latex')) &&
        (q.contains('филлер') || q.contains('ботокс') || q.contains('инъек') || q.contains('можно'))) {
      return 'Аллергию на латекс обязательно скажите до инъекций — перчатки и расходники подбирают иначе, без самозаписи. '
          'Запишем консультацию — врач учтёт реакцию на осмотре.';
    }

    if ((q.contains('сертификат') || q.contains('подарить')) &&
        (q.contains('маме') ||
            q.contains('мамы') ||
            q.contains('мама') ||
            q.contains('день рожден'))) {
      return 'Сертификат CULT на день рождения маме — хороший жест: номинал выбираете сами, код в профиле или через администратора. '
          'Можно сразу записать её на массаж или уход. Какой примерно бюджет?';
    }

    if ((q.contains('горят') ||
            q.contains('горит') ||
            q.contains('жжет') ||
            q.contains('жжёт') ||
            q.contains('печет') ||
            q.contains('печёт')) &&
        (q.contains('филлер') || q.contains('губ')) &&
        (q.contains('после') || q.contains('норма'))) {
      return 'Лёгкое жжение губ на следующий день после филлера иногда бывает — холод по схеме врача, без разминания, без кислот. '
          'Если жжение сильное, нарастает, белеет зона или сильная боль — сразу врачу в чат. Могу открыть чат специалиста.';
    }

    if ((q.contains('ботокс') || q.contains('ботулин')) &&
        q.contains('массаж') &&
        (q.contains('скольк') || q.contains('стоит') || q.contains('цен') || q.contains('вместе'))) {
      final botox = _clinicService('ботулинотерап', gender: gender);
      final massage = _clinicService('скульптурн', gender: gender) ??
          _clinicService('массаж', gender: gender);
      final b = botox == null ? 'ботулинотерапия' : '${botox.title} — ориентир ${botox.priceLabel}';
      final m = massage == null ? 'скульптурный массаж' : '${massage.title} — ориентир ${massage.priceLabel}';
      return 'По отдельности: $b; $m. Вместе в один визит — не всегда: порядок и допуск решает врач. '
          'Запишем консультацию или два окна отдельно?';
    }

    if ((q.contains('ферритин') ||
            q.contains('низкое железо') ||
            q.contains('дефицит железа') ||
            (q.contains('анеми') && q.contains('желез'))) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'Низкий ферритин и железодефицит — не повод сама назначать «капельницу красоты»: состав и допуск смотрит врач, часто нужны свежие анализы. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('желчнокамен') ||
            q.contains('желчн камен') ||
            q.contains('камни в желч') ||
            (q.contains('желч') && q.contains('камен'))) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При желчнокаменной болезни капельницу не назначаю сама — нагрузку на ЖКТ и состав смотрит врач, иногда нужен допуск смежника. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('мочекамен') ||
            q.contains('камни в почк') ||
            q.contains('камни в моче') ||
            (q.contains('мочев') && q.contains('камен'))) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При мочекаменной болезни капельницу не назначаю сама — объём, состав и почки смотрит врач, иногда нужен допуск уролога. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('инфаркт') ||
            q.contains('инсульт') ||
            q.contains('сердечн') ||
            q.contains('после стент')) &&
        (q.contains('rf') ||
            q.contains('рф') ||
            q.contains('микроиголь') ||
            q.contains('аппарат') ||
            q.contains('smas') ||
            q.contains('смас') ||
            q.contains('можно'))) {
      return 'После инфаркта, инсульта или при серьёзном сердечном фоне аппаратные вроде RF не назначаю сама — нужен допуск кардиолога и решение врача CULT. '
          'Могу открыть чат специалиста или записать на консультацию после разрешения.';
    }

    if ((q.contains('печен') || q.contains('цирроз') || q.contains('гепатоз')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно'))) {
      return 'При заболеваниях печени капельницу не назначаю сама — состав и нагрузку на печень смотрит врач, иногда нужны свежие анализы. '
          'Могу открыть чат специалиста или записать на консультацию перед инфузией.';
    }

    if ((q.contains('витамин c') ||
            q.contains('витамином c') ||
            q.contains('витамин с') ||
            q.contains('аскорбин') ||
            q.contains('vitamin c')) &&
        (q.contains('после пилинг') || (q.contains('после') && q.contains('пилинг'))) &&
        (q.contains('можно') || q.contains('через') || q.contains('сыворот'))) {
      return 'После пилинга витамин C и кислоты обычно возвращают с паузой — через неделю иногда уже можно, если барьер спокойный; точнее врач по глубине. '
          'Пока SPF и барьерный крем. Когда делали пилинг?';
    }

    if ((q.contains('йод') || q.contains('йода')) &&
        (q.contains('аллерг') || q.contains('не перенос')) &&
        (q.contains('ipl') || q.contains('айпи') || q.contains('lumecca') || q.contains('лазер'))) {
      return 'Аллергию на йод скажите до IPL — антисептики и протокол иногда подбирают иначе; сам свет не «йодная капельница», но врачу важно знать. '
          'Запишем консультацию по IPL или откроем чат специалиста.';
    }

    if ((q.contains('йод') || q.contains('йода')) &&
        (q.contains('аллерг') || q.contains('не перенос')) &&
        (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц') || q.contains('можно')) &&
        !q.contains('ipl') &&
        !q.contains('айпи') &&
        !q.contains('лазер')) {
      return 'Аллергию на йод обязательно скажите до капельницы — часть составов и антисептиков подбирают иначе, без самозаписи. '
          'Могу открыть чат специалиста или записать на консультацию.';
    }

    if ((q.contains('как часто') || q.contains('как часто можно') || q.contains('интервал')) &&
        (q.contains('beauty') || q.contains('glow') || (q.contains('капель') && q.contains('часто')))) {
      return 'Beauty & Glow чаще ставят курсом или по самочувствию — ориентир раз в несколько недель, не «каждые два дня»; точнее врач по анализам и цели. '
          'Запишем консультацию по инфузиям — подберём ритм.';
    }

    if ((q.contains('как часто') || q.contains('как часто можно') || q.contains('интервал')) &&
        (q.contains('ipl') || q.contains('айпи') || q.contains('lumecca'))) {
      return 'IPL чаще ставят курсом с паузой под фототип — ориентир раз в несколько недель, не «каждую неделю»; точнее врач по коже и загару. '
          'Запишем консультацию по свету — подберём ритм.';
    }

    if ((q.contains('семей') || q.contains('для семьи') || q.contains('на всю семью')) &&
        (q.contains('абонемент') || q.contains('пакет') || q.contains('курс') || q.contains('есть ли'))) {
      return 'Отдельного «семейного абонемента» в меню нет — можно соседние окна или сертификаты на каждого; скидки по карте лояльности уточнит администратор. '
          'Могу открыть чат админа. Какие уходы вам двоим ближе?';
    }

    if ((q.contains('умыв') || q.contains('пенк') || q.contains('гель для умыв') || q.contains('умываться')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('микроиголь')) &&
        (q.contains('после') || q.contains('можно') || q.contains('тот же'))) {
      return 'После RF в тот же день умывание обычно мягкое, без жёсткой пенки и скраба — тёплая вода и успокаивающий крем по листу врача. '
          'Когда была процедура?';
    }

    if ((q.contains('статус') || q.contains('провер') || q.contains('узнать')) &&
        (q.contains('запис') || q.contains('визит') || q.contains('приём') || q.contains('прием'))) {
      return 'Статус записи смотрите в профиле → «Мои записи»; голосом я календарь филиала не открываю. '
          'Если слот не виден — напишите администратору в чат, разберём.';
    }

    if ((q.contains('что взять') || q.contains('с собой')) &&
        (q.contains('лимфодрен') || (q.contains('массаж') && q.contains('лимф')))) {
      return 'На лимфодренаж: удобная одежда, которую легко снять с зоны; документ; без плотного макияжа, если трогаем лицо. '
          'Остальное — на ресепшен. Запишем массаж?';
    }

    if ((q.contains('боюсь') || q.contains('страх') || q.contains('больно')) &&
        (q.contains('rf') || q.contains('рф') || q.contains('микроиголь'))) {
      return 'Микроигольчатый RF делаем с аппликационной анестезией, темп спокойный — дискомфорт есть, но обычно терпимый. '
          'Можно начать с консультации без процедуры в тот же день. Запишем осмотр?';
    }

    if ((q.contains('активн') || q.contains('воспал') || q.contains('гной')) &&
        q.contains('акне') &&
        (q.contains('чистк') || q.contains('чистка'))) {
      return 'При активном воспалённом акне жёсткую чистку часто откладывают — сначала успокаиваем, осмотр, потом щадящий протокол. '
          'Без «выдавить всё сегодня». Запишем консультацию?';
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
    final hasPeel = q.contains('пилинг');
    final hasClean = q.contains('чистка') || q.contains('узи чист');
    final hasCare = q.contains('уход') || q.contains('крем') || q.contains('сывор');
    final hasInfusion = q.contains('инфуз') ||
        q.contains('капель') ||
        q.contains('nad') ||
        q.contains('immunity');

    if (hasPeel && hasClean) {
      return 'Чистка — про очищение пор здесь и сейчас; пилинг — про тон, текстуру и обновление, с короткой реабилитацией. '
          'Если комедоны и «забитость» — чаще чистка или мягкий уход вроде HydraPure; если тусклость и неровный тон — смотрим пилинг по фототипу. '
          'Чувствительной коже без осмотра пилинг не тороплю. Что ближе вашей задаче?';
    }
    if (hasMassage && hasCare && !hasRf && !hasInject) {
      return 'Массаж и уход отлично дружат: часто делают в один визит или курсом — сначала очищение/уход, потом скульптура, или наоборот по решению врача. '
          'Могу записать на массаж или на уход — что важнее сегодня: овал или тон и влага?';
    }
    if (hasMassage && hasRf) {
      return man
          ? 'Коротко: массаж даёт свежий вид и снятие напряжения уже после визита; RF — про плотность и овал курсом, без «перекачанного» эффекта. '
              'Если хотите мягкий вход — массаж; если цель — уплотнить контур — смотрим RF на консультации. С чего начнём?'
          : 'Коротко: массаж — быстрый «живой» рельеф и лимфа; микроигольчатый RF — плотность и овал на дистанции курса. '
              'К событию через пару дней чаще массаж или уход; для стойкого эффекта — RF после осмотра. Что ближе вашей задаче?';
    }
    if (hasInject && (hasMassage || hasCare || hasPeel || hasClean)) {
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
    // Clinical interval questions («через две недели после ботокса…») — not event planning.
    final clinicalInterval = weekish &&
        (q.contains('ботокс') ||
            q.contains('ботулин') ||
            q.contains('филлер') ||
            q.contains('пилинг') ||
            q.contains('rf') ||
            q.contains('рф') ||
            q.contains('ipl') ||
            q.contains('smas') ||
            q.contains('смас') ||
            q.contains('массаж') ||
            q.contains('чистк') ||
            q.contains('капель') ||
            q.contains('мезо'));

    if (soon ||
        (event && (soon || q.contains('скоро') || q.contains('через')))) {
      return 'К близкой дате не берём тяжёлую реабилитацию. Чаще — уход с сыворотками или скульптурный массаж, иногда лёгкая инфузия Beauty & Glow. '
          'Скажите точную дату и зону (лицо / отёк / тон) — предложу один спокойный протокол и запись.';
    }
    if ((event || weekish) &&
        !clinicalInterval &&
        !q.contains('сертификат') &&
        !q.contains('подарить')) {
      return 'Под дату есть запас — можно сочетать мягкий старт сейчас и при необходимости курс после осмотра. '
          'Назовите, что важнее в кадре: тон, овал, свежесть или энергия — сузим до двух вариантов.';
    }
    if ((RegExp(r'(мне |мне)\s*\d{2}').hasMatch(q) ||
            RegExp(r'\d{2}\s*лет').hasMatch(q)) &&
        !q.contains('детск') &&
        !q.contains('подрост') &&
        !q.contains('несовершеннолет') &&
        !q.contains('прайс')) {
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

    // Post-peel flaking is aftercare, not «start a peel».
    if ((q.contains('шелуш') || q.contains('облазит')) &&
        (q.contains('после пилинг') ||
            q.contains('после кислот') ||
            q.contains('после чистк'))) {
      return null;
    }
    if (q.contains('сух') ||
        q.contains('стягив') ||
        q.contains('шелуш') ||
        q.contains('обезвож')) {
      final chair = _lineService(hydra) ?? 'увлажняющий уход HydraPure';
      final home = _lineProduct(barrier) ?? 'Lumen Barrier Cream';
      return _pick('concern-dry', [
        'Стянутость очень знакома — чаще всего это барьер, а не «надо сильнее кислоты». '
            'Я бы начала с ухода $chair в кресле и дома с крема $home. Хотите сначала крем или визит?',
        'Если кожа шелушится и стягивает, я бы не сушила её пилингом сразу — сначала барьер. '
            'У нас обычно $chair, дома — $home. Могу подсказать по крему или записать на уход.',
        'Похоже на обезвоженность и слабый барьер. Давайте мягко: $chair и $home, без агрессии в первый шаг. Что ближе — шоп или кресло?',
      ], q);
    }
    if (q.contains('жирн') ||
        q.contains('блеск') ||
        q.contains('расшир') ||
        q.contains('поры') ||
        q.contains('пор ')) {
      return 'С блеском и порами я бы не торопилась с жёсткой чисткой. '
          'Сначала осмотр, потом либо плотный уход ${_lineService(hydra) ?? 'HydraPure'}, '
          'либо ${_lineService(rf) ?? 'микроигольчатый RF'} — если врач согласует. '
          'Сказать примерно цену или сразу про запись?';
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
        'Воспаления дома лучше не «жечь»: нужен осмотр, потом щадящий уход или $peelLine по фототипу. '
            'Зона одним словом поможет сузить — и можем записаться.',
        'С прыщами и воспалением лучше не экспериментировать самой: осмотр, затем мягкий уход или $peelLine. '
            'Могу помочь записаться, если скажете когда удобно.',
        'Для высыпаний сначала смотрим кожу вживую — домашний жёсткий разбор часто ухудшает. '
            'Дальше обычно уход или $peelLine. Запишем осмотр?',
      ], q);
    }
    if ((q.contains('каменн') ||
            q.contains('каменным') ||
            q.contains('без мимик') ||
            q.contains('натуральн результат') ||
            q.contains('натуральный результат') ||
            q.contains('не хочу чтобы было видно') ||
            q.contains('коллеги не') ||
            q.contains('чтобы не заметил') ||
            q.contains('чтобы не было видно') ||
            q.contains('естественн результат')) &&
        !q.contains('ботокс') &&
        !q.contains('ботулин') &&
        !q.contains('после укол') &&
        !q.contains('желч') &&
        !q.contains('желчно') &&
        !q.contains('мочекамен') &&
        !q.contains('желчнокамен') &&
        !q.contains('каменн болезни') &&
        !q.contains('каменной болезни') &&
        !q.contains('капель') &&
        !q.contains('инфуз')) {
      return 'Если хотите натуральный результат — я бы начала с ${_lineService(massage) ?? 'массажа лица'} или ухода. '
          'Ботокс и филлеры — только после осмотра и с сохранением мимики. '
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
          : 'Омоложение без жёстких обещаний: ${_lineService(massage) ?? 'скульптурный массаж'} или уход, дома ${_lineProduct(barrier) ?? 'барьерный крем'} или ${_lineProduct(peptide) ?? 'пептиды'}. '
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
            'Я не тороплю к инъекциям. Что ближе — мягкий уход или обсудить уколы на консультации?',
        'Избавиться «насовсем» честно нельзя обещать, но освежить — да. Чаще начинают с $soft, '
            'а $inject подключают точечно после осмотра. Расскажите, зона — лоб, глаза или носогубки?',
      ], q);
    }
    if (q.contains('овал') ||
        q.contains('второй подбородок') ||
        q.contains('брыл') ||
        q.contains('контур лиц')) {
      return man
          ? 'По овалу у мужчин обычно ${_lineService(rf) ?? 'мужской RF-лифтинг'} или ${_lineService(massage) ?? 'барбер-массаж'} — контур без объёма «на показ». '
              'Сказать примерно цену или сразу про запись на осмотр?'
          : 'По овалу чаще помогает ${_lineService(massage) ?? 'скульптурный массаж лица'}, при необходимости — ${_lineService(rf) ?? 'микроигольчатый RF'}. '
              'Сравнить два варианта или сразу консультация?';
    }
    if (q.contains('отек') ||
        q.contains('мешк') ||
        q.contains('одутл') ||
        q.contains('пастоз')) {
      return 'Отёк и тяжесть хорошо снимает ${_lineService(massage) ?? 'скульптурный или лимфодренажный массаж'}, плюс питьевой режим. '
          'Если скажете «массаж» — уточню, сколько длится и примерно сколько стоит.';
    }
    if (q.contains('пигмент') ||
        q.contains('пятн') ||
        q.contains('веснуш') ||
        q.contains('неравном')) {
      return 'С пигментом идём по фототипу: ${_lineService(peel) ?? 'химический пилинг L3'} или аппарат Lumecca, без домашнего отбеливания. '
          'Сказать цифры по пилингу или IPL — или запишем осмотр?';
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
      return 'К событию без долгой реабилитации хорошо заходит ${_lineService(hydra) ?? 'HydraPure'} или ${_lineService(massage) ?? 'скульптурный массаж'}. '
          'Если силы позволяют — ещё капельница ${_lineInfusion(glow) ?? 'Beauty & Glow'}. Назовите дату — подстроим.';
    }
    if (q.contains('носогуб') ||
        q.contains('носо губ') ||
        (q.contains('складк') && q.contains('губ'))) {
      return 'По носогубкам я бы начала с ${_lineService(massage) ?? 'массажа'} или ${_lineService(hydra) ?? 'ухода'}. '
          'Контурную пластику — только после осмотра, если объём действительно нужен. Запишем консультацию?';
    }
    if (q.contains('черные точки') ||
        q.contains('комедон') ||
        q.contains('черн точки') ||
        (q.contains('точки') && q.contains('пор'))) {
      return 'Комедоны лучше не выдавливать агрессивно. У нас — осмотр и ${_lineService(hydra) ?? 'HydraPure'} или ${_lineService(peel) ?? 'пилинг L3'}, без пересушивания. '
          'Сказать про чистку и пилинг подробнее — или сразу про запись?';
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
        (q.contains('иммун') && !q.contains('аутоиммун'))) {
      return 'Если силы на нуле, у нас помогают капельницы: ${_lineInfusion(nad) ?? 'NAD+ Energy'}, '
          '${_lineInfusion(immunity) ?? 'Immunity Boost'} или ${_lineInfusion(glow) ?? 'Beauty & Glow'}. '
          'Могу сравнить три или сразу помочь с записью на капельницу.';
    }
    if (q.contains('сон') || q.contains('не высып') || q.contains('бессон')) {
      return 'Сон клиника не заменяет, но поддержать можно: мягкий уход от отёка и при необходимости ${_lineInfusion(nad) ?? 'NAD+'} или формула из шопа, например Mitochondrial Fuel. '
          'Скажите «шоп» или «инфузия» — сузим.';
    }
    if (q.contains('глаз') ||
        q.contains('темные круги') ||
        q.contains('темные круги') ||
        q.contains('синяк под')) {
      return 'Зону глаз смотрим спокойно: осмотр, затем ${_lineService(meso) ?? 'мезотерапия'} или щадящий уход — без агрессии. '
          'Больше отёк или тень? От этого зависит, что предложу.';
    }
    if (q.contains('шея') || q.contains('декольте')) {
      return 'Шею и декольте смотрим на консультации: иногда плотность через RF или уход, иногда домашний крем из шопа. '
          'Запишем осмотр?';
    }
    if (q.contains('похудеть') ||
        q.contains('жир на') ||
        q.contains('целлюлит') ||
        q.contains('живот')) {
      return 'По телу эстетика клиники, в том числе BodyTite, дополняет режим, а не заменяет его. '
          'Без обещаний «минус размеры за раз» — сначала консультация по зоне.';
    }
    if (q.contains('стресс') || q.contains('нервн') || q.contains('тревож')) {
      return 'Когда стресс читается по лицу, спокойный вход — ${_lineService(massage) ?? 'массаж лица'} или уход без тяжёлой артиллерии. '
          'Можно просто записаться к врачу на осмотр и разговор.';
    }
    if (q.contains('выпаден') ||
        q.contains('волосы лезут') ||
        q.contains('алопец') ||
        q.contains('редеют волос') ||
        (q.contains('волос') &&
            (q.contains('реде') || q.contains('теря') || q.contains('густот')))) {
      return 'С выпадением сначала смотрим причину на осмотре, потом обсуждаем ${_lineService(meso) ?? 'мезотерапию'} кожи головы — не «чудо-укол сразу». '
          'Запишем консультацию?';
    }
    if (q.contains('растяж') || q.contains('стрии')) {
      return 'Растяжки ведём аккуратно и курсом: аппаратные и инъекционные протоколы подбирает врач после осмотра — без обещания «как не было». '
          'Могу записать на консультацию.';
    }
    if (q.contains('детокс') || q.contains('очищен организм') || q.contains('вывести токсин')) {
      return '«Детокс» в клинике — скорее про поддержку: инфузии, режим и кожа, а не про чудо за час. '
          'Могу сравнить капельницы или предложить мягкий уход. Что важнее — энергия или кожа?';
    }
    if ((q.contains('ретинол') || (q.contains('кислот') && q.contains('дом'))) &&
        !q.contains('ipl') &&
        !q.contains('айпи') &&
        !q.contains('lumecca')) {
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
    if ((q.contains('чувствительн') ||
            q.contains('красне') ||
            q.contains('жжет') ||
            q.contains('щипл')) &&
        !q.contains('после пилинг') &&
        !q.contains('ретинол') &&
        !q.contains('кислот')) {
      return 'Чувствительность — сигнал снизить агрессию: сначала барьер и мягкий уход, аппаратные и кислоты — только после осмотра. '
          'Могу подсказать барьерный крем из шопа или записать на спокойную консультацию.';
    }
    // Keep sun/sport/alcohol/fasting on the FAQ path; clinical teach owns red/cream/dinner.
    final aftercareToFaq = q.contains('алкогол') ||
        q.contains('солнц') ||
        q.contains('загар') ||
        q.contains('spf') ||
        q.contains('спорт') ||
        q.contains('бассейн') ||
        q.contains('саун') ||
        q.contains('хамам') ||
        q.contains('натощак') ||
        q.contains('красн') ||
        q.contains('норма') ||
        q.contains('крем') ||
        q.contains('шоп') ||
        q.contains('ужин') ||
        q.contains('ресторан');
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
    if (q.contains('запис') &&
        !q.contains('подтверд') &&
        !q.contains('без кнопк') &&
        !q.contains('сменить') &&
        !q.contains('поменять') &&
        !q.contains('другого врач') &&
        !q.contains('вторую услуг') &&
        !q.contains('вторая услуг') &&
        !q.contains('добавить') &&
        !q.contains('собран')) {
      return 'Записаться можно прямо со мной: скажите услугу и когда удобнее — уточню детали и попрошу подтвердить кнопкой «Запись». '
          'Или откройте запись в меню, если так привычнее.';
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
    if ((q.contains('массаж') || q.contains('лимфодрен')) &&
        !q.contains('подготов') &&
        !q.contains('как готов') &&
        !q.contains('после ботокс') &&
        !q.contains('после ботулин') &&
        !q.contains('надеть') &&
        !q.contains('одежд') &&
        !q.contains('пакет') &&
        !q.contains('абонемент') &&
        !q.contains('скидк') &&
        !q.contains('курс из')) {
      return 'Массаж и лимфодренаж — один из самых спокойных стартов: меню «Услуги» и запись через «+». '
          'Спросите конкретное название — подскажу цену и длительность.';
    }
    if ((q.contains('лазер') || q.contains('ipl') || q.contains('пигмент')) &&
        !q.contains('загар') &&
        !q.contains('солнц') &&
        !q.contains('омоложен') &&
        !q.contains('делаете') &&
        !q.contains('тату') &&
        !q.contains('татуаж') &&
        !q.contains('лететь') &&
        !q.contains('перелет') &&
        !q.contains('самолет') &&
        !q.contains('вылет') &&
        !q.contains('домашн') &&
        !q.contains('набор') &&
        !q.contains('после')) {
      return 'Лазер и IPL — в разделе «Аппаратная». Перед курсом врач спокойно оценит фототип и зону — без самодеятельности с отбеливанием. '
          'Могу сориентировать по направлению или помочь с записью на осмотр.';
    }
    if ((q.contains('пилинг') || q.contains('чистка')) &&
        !q.contains('домашн') &&
        !q.contains('после') &&
        !q.contains('барьер') &&
        !q.contains('крем')) {
      return 'Пилинги и уходы — в меню «Услуги». Интенсивность подберём под сезон и тип кожи, чтобы не перегрузить барьер. '
          'Если скажете задачу кожи — сузим до одного протокола.';
    }
    if ((q.contains('абонемент') || q.contains('пакет') || q.contains('курс')) &&
        !q.contains('рассрочк') &&
        !q.contains('кредит') &&
        !q.contains('частям')) {
      return 'Курсы и пакеты обсуждаем на консультации. Часть протоколов выгоднее пакетом — спросите администратора.';
    }
    if (q.contains('эпиляц')) {
      return 'Лазерная эпиляция — в «Аппаратной». Курс и зону подберём на консультации с учётом фототипа.';
    }
    if (q.contains('перманент') ||
        q.contains('татуаж') ||
        (q.contains('бров') &&
            !q.contains('ботокс') &&
            !q.contains('ботулин') &&
            !q.contains('асимметр') &&
            !q.contains('высот') &&
            !q.contains('разн') &&
            !q.contains('пирсинг'))) {
      return 'Перманентный макияж обсуждаем на очной консультации. Запись — через «+» или карточку специалиста.';
    }
    if ((q.contains('мезотерап') || q.contains('биоревитал')) &&
        !q.contains('плазмо') &&
        !q.contains('чем отлича') &&
        !q.contains('отличает') &&
        !q.contains('или филлер') &&
        !q.contains('от филлер') &&
        !q.contains('шеи') &&
        !q.contains('шею') &&
        !q.contains('шея') &&
        !q.contains('папул') &&
        !q.contains('делаете') &&
        !q.contains('подготов') &&
        !q.contains('волос') &&
        !q.contains('голов') &&
        !q.contains('как понять') &&
        !q.contains('пора') &&
        !q.contains('рук')) {
      return 'Мезотерапия и биоревитализация — в меню «Инъекции». Перед курсом врач оценит показания.';
    }
    // «скульптурный массаж» contains «скульпт» — don't steal into contour inject.
    if ((q.contains('контурн') || q.contains('липо') || q.contains('скульптурир')) &&
        !q.contains('массаж') &&
        !q.contains('липосакц')) {
      return 'Контурная пластика и скульптурирование — в «Инъекциях». Объём и зоны согласуем на консультации.';
    }
    if (q.contains('ресепшен') ||
        q.contains('ресепшн') ||
        q.contains('администрац')) {
      return 'Ресепшен CULT Сочи — Черноморская, 6, ежедневно 9:00–21:00. Самовывоз шопа и вопросы по записи — там же.';
    }
    // «через час» / «часа» — not opening hours.
    if ((q.contains('часы работ') ||
            q.contains('график работ') ||
            q.contains('режим работ') ||
            q.contains('во сколько откры') ||
            q.contains('до скольки') ||
            q.contains('до скольки') ||
            (q.contains('режим') && !q.contains('через')) ||
            q.contains('выходн') ||
            q.contains('воскрес') ||
            (q.contains('суббот') && (q.contains('работ') || q.contains('открыт'))) ||
            (q.contains('час') &&
                (q.contains('работ') ||
                    q.contains('открыт') ||
                    q.contains('клиник') ||
                    q.contains('вы ')))) &&
        !q.contains('через час') &&
        !q.contains('после умыван')) {
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
      return 'Ждём вас в Сочи, Черноморская, 6. Если нужен трансфер — скажите «трансфер из аэропорта» или адрес, оформлю заявку администратору.';
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
        // «мили» банковские, но не «милиумы».
        RegExp(r'(^|[^а-я])мили([^а-я]|$)').hasMatch(q) ||
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
    if (q.contains('аллерг') &&
        !q.contains('никель') &&
        !q.contains('никел') &&
        !q.contains('йод') &&
        !q.contains('латекс') &&
        !q.contains('ферритин')) {
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
      if (q.contains('капель') || q.contains('инфуз') || q.contains('капельниц')) {
        return 'На капельницу обычно достаточно лёгкого приёма пищи и воды — не как перед анализами. Подготовку подтвердят при записи.';
      }
      return 'На забор крови чаще приходят натощак 8–12 часов, воду можно. Точный список анализов и подготовку подтвердит администратор или лаборатория.';
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
    if ((q.contains('сертификат') || q.contains('подарок')) &&
        !q.contains('продл') &&
        !q.contains('обмен') &&
        !q.contains('верн') &&
        !q.contains('возврат') &&
        !q.contains('чуж') &&
        !q.contains('друг') &&
        !q.contains('оплатить')) {
      return 'Сертификаты — в профиле → «Купить сертификат». Номинал и дизайн выбираете сами, код копируется в один тап.';
    }
    if (q.contains('трансфер') || q.contains('такси') || q.contains('машин')) {
      // Prefer [_transferFlow] in respond(); keep as soft FAQ fallback.
      return 'Трансфер до клиники оформлю сама: скажите «трансфер из аэропорта» или адрес подачи — заявку отправлю администратору.';
    }
    if (q.contains('прайс') ||
        q.contains('стоим') ||
        (q.contains('цен') &&
            !q.contains('плацентар') &&
            !q.contains('оцен') &&
            !q.contains('ценност'))) {
      return 'Актуальный прайс филиала — в меню «Прайс». Назовите услугу голосом — подскажу цену из каталога и мягкий следующий шаг к записи.';
    }
    if (q.contains('парков') &&
        !q.contains('собак') &&
        !q.contains('питомц') &&
        !q.contains('кот') &&
        !q.contains('животн')) {
      return 'Гостевая парковка у входа на Черноморской, 6. Места для клиентов CULT — бесплатно на время визита.';
    }
    if (q.contains('анализ') || q.contains('лаборатор') || q.contains('кровь')) {
      return 'Анализы и протоколы — в кабинете → «Мои анализы». Запись на забор крови — через «+» или меню «Запись».';
    }
    if (q.contains('wifi') ||
        q.contains('wi-fi') ||
        q.contains('вайф') ||
        q.contains('интернет в клиник')) {
      return 'Wi‑Fi для гостей на ресепшен: сеть CULT Guest — пароль скажет администратор при визите.';
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
    if ((q.contains('аппарат') || q.contains('rf') || q.contains('smas')) &&
        !q.contains('кардиостимул') &&
        !q.contains('водител ритм') &&
        !q.contains('результат') &&
        !q.contains('эффект') &&
        !q.contains('ждать') &&
        !q.contains('восстанов') &&
        !q.contains('после rf') &&
        !q.contains('после рф') &&
        !q.contains('летом') &&
        !q.contains('жар') &&
        !q.contains('лифтинг') &&
        !q.contains('делаете') &&
        !q.contains('есть ли') &&
        !q.contains('зуб') &&
        !q.contains('металл') &&
        !q.contains('имплант') &&
        !q.contains('простыми') &&
        !q.contains('нит') &&
        !q.contains('золот') &&
        !q.contains('жжет') &&
        !q.contains('жжёт') &&
        !q.contains('горит') &&
        !q.contains('эндометр') &&
        !q.contains('миом') &&
        !q.contains('беремен') &&
        !q.contains('сожж') &&
        !q.contains('сожг') &&
        !q.contains('боюсь') &&
        !q.contains('спирал') &&
        !q.contains('вмс') &&
        !q.contains('лидокаин') &&
        !q.contains('анестез') &&
        !q.contains('загар') &&
        !q.contains('варикоз') &&
        !q.contains('горяч') &&
        !q.contains('жар') &&
        !q.contains('инфаркт') &&
        !q.contains('инсульт') &&
        !q.contains('сердечн') &&
        !q.contains('домашн') &&
        !q.contains('синяк') &&
        !q.contains('гематом') &&
        !q.contains('гипертон') &&
        !q.contains('давлен') &&
        !q.contains('гипотон')) {
      return 'Аппаратная — в меню «Аппаратная»: RF, IPL и SMAS. Спросите название — отвечу ценой и длительностью; интенсивность всегда уточняем на консультации под вашу кожу.';
    }
    if ((q.contains('инъек') || q.contains('филлер') || q.contains('ботокс')) &&
        !q.contains('месячн') &&
        !q.contains('цикл') &&
        !q.contains('критическ') &&
        !q.contains('самолет') &&
        !q.contains('перелет') &&
        !q.contains('лететь') &&
        !q.contains('челюст') &&
        !q.contains('синяк') &&
        !q.contains('чистк') &&
        !q.contains('интервал') &&
        !q.contains('линз') &&
        !q.contains('кофе') &&
        !q.contains('наклон') &&
        !q.contains('мигрен') &&
        !q.contains('поможет') &&
        !q.contains('год назад') &&
        !q.contains('пора на') &&
        !q.contains('как понять') &&
        !q.contains('единиц') &&
        !q.contains('свадеб') &&
        !q.contains('свадьб') &&
        !q.contains('асимметр') &&
        !q.contains('целов') &&
        !q.contains('как часто') &&
        !q.contains('колоть') &&
        !q.contains('антибиот') &&
        !q.contains('спать') &&
        !q.contains('боку') &&
        !q.contains('шишк') &&
        !q.contains('красит') &&
        !q.contains('сини') &&
        !q.contains('сине') &&
        !q.contains('перед') &&
        !q.contains('нельзя') &&
        !q.contains('рыбий') &&
        !q.contains('омега') &&
        !q.contains('опущ') &&
        !q.contains('птоз') &&
        !q.contains('веко') &&
        !q.contains('ретейнер') &&
        !q.contains('трогать') &&
        !q.contains('очки') &&
        !q.contains('бров') &&
        !q.contains('подбород') &&
        !q.contains('магний') &&
        !q.contains('каменн') &&
        !q.contains('антидепресс') &&
        !q.contains('вич') &&
        !q.contains('аспирин') &&
        !q.contains('омега') &&
        !q.contains('глаз выше') &&
        !q.contains('глаз ниже') &&
        !q.contains('горят') &&
        !q.contains('горит') &&
        !q.contains('жжет') &&
        !q.contains('жжёт') &&
        !q.contains('латекс') &&
        !q.contains('больше') &&
        !q.contains('меньше') &&
        !q.contains('асимметр') &&
        !q.contains('одна губ')) {
      return 'Инъекции (ботулин, филлеры, мезо) подбирает врач после осмотра — можно начать с консультации без процедуры в тот же день. '
          'Скажите зону или цель: мимика, губы, плотность — сузим и при желании запишем.';
    }
    if ((q.contains('инфуз') || q.contains('капель')) &&
        !q.contains('давлен') &&
        !q.contains('алкогол') &&
        !q.contains('что такое') &&
        !q.contains('за руль') &&
        !q.contains('водить') &&
        !q.contains('машин') &&
        !q.contains('похмел') &&
        !q.contains('есть после') &&
        !q.contains('нельзя есть') &&
        !q.contains('после капель') &&
        !q.contains('операц') &&
        !q.contains('хирург') &&
        !q.contains('недавн') &&
        !q.contains('совмест') &&
        !q.contains('совмещ') &&
        !q.contains('анеми') &&
        !q.contains('кардиостимул') &&
        !q.contains('пейсмекер') &&
        !q.contains('астм') &&
        !q.contains('вегетариан') &&
        !q.contains('веган') &&
        !q.contains('гастрит') &&
        !q.contains('эпилепс') &&
        !q.contains('розацеа') &&
        !q.contains('купероз') &&
        !q.contains('щитовид') &&
        !q.contains('тиреоид') &&
        !q.contains('гепатит') &&
        !q.contains('диабет') &&
        !q.contains('почечн') &&
        !q.contains('почк') &&
        !q.contains('вич') &&
        !q.contains('тромбоз') &&
        !q.contains('онколог') &&
        !q.contains('ремисси') &&
        !q.contains('аутоиммун') &&
        !q.contains('печен') &&
        !q.contains('йод') &&
        !q.contains('ферритин') &&
        !q.contains('желч') &&
        !q.contains('панкреатит') &&
        !q.contains('поджелудоч') &&
        !q.contains('пролактин') &&
        !q.contains('язвенн') &&
        !q.contains('язва') &&
        !q.contains('мигрен') &&
        !q.contains('подагр') &&
        !q.contains('мочекамен') &&
        !q.contains('аритм') &&
        !q.contains('холецист') &&
        !q.contains('латекс') &&
        !q.contains('йог') &&
        !q.contains('спорт') &&
        !q.contains('тренир')) {
      return 'Инфузии — в меню «Инфузии»: NAD+ для энергии, Immunity для поддержки, Beauty & Glow для кожи. '
          'Могу коротко сравнить или помочь записаться через «+» на главной.';
    }
    if ((q.contains('nad') ||
            q.contains('longevity') ||
            q.contains('долголет')) &&
        !q.contains('что такое') &&
        !q.contains('простыми') &&
        !q.contains('patch') &&
        !q.contains('патч')) {
      return 'NAD+ и longevity-протоколы — в разделе «Инфузии» и шопе (Catalyst, NAD+ Micro-Patch). Спросите формулу — расскажу подробнее.';
    }
    if (q.contains('постакне') || q.contains('рубец') || q.contains('шрам')) {
      return 'Постакне и рубцы — комбинация аппаратных и инъекционных протоколов. Запишитесь на консультацию — оценим тип кожи.';
    }
    if (q.contains('купероз') ||
        q.contains('сосудист') ||
        q.contains('розацеа')) {
      // Prefer [_teachReply]; keep soft FAQ fallback.
      return 'Купероз и розацеа — без самолечения кислотами: осмотр, мягкий уход, иногда IPL. Могу записать на консультацию.';
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
    if ((q.contains('этаж') ||
            q.contains('вход') ||
            (q.contains('лифт') && !q.contains('лифтинг') && !q.contains('нитев'))) &&
        !q.contains('нитев') &&
        !q.contains('smas') &&
        !q.contains('овал')) {
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
    if ((q.contains('гематом') ||
            q.contains('синяк после') ||
            q.contains('синяки после')) &&
        !q.contains('rf') &&
        !q.contains('рф') &&
        !q.contains('микроиголь')) {
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

  /// Soften canned openers into spoken Russian; keep clinic facts intact.
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
      if ((prev.contains('через «+»') || prev.contains('кнопкой «запись»')) &&
          (_normalize(out).contains('через «+»') ||
              _normalize(out).contains('кнопкой «запись»')) &&
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

    // Strip leftover catalog dumps: «Title» (12 000 ₽, 60 мин) → Title
    out = out.replaceAllMapped(
      RegExp(r'«([^»]+)»\s*\([^)]*(?:₽|руб|мин|час)[^)]*\)'),
      (m) => m.group(1)!,
    );
    out = out.replaceAllMapped(
      RegExp(r'«([^»]+)»\s*\(\d[\d\s\u00a0]*₽\)'),
      (m) => m.group(1)!,
    );

    // Vary a few overused robotic openers so replies don't sound copy-pasted.
    final swaps = <String, List<String>>{
      'Слышу вас —': ['Поняла вас —', 'Услышала —', 'Хорошо, '],
      'Слышу вас.': ['Поняла. ', 'Услышала. ', 'Хорошо. '],
      'В CULT без угадываний:': [
        'Давайте без угадываний: ',
        'По прайсу так: ',
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
      'Ориентир по цене —': [
        'Стоит примерно ',
        'По цене около ',
        'Обычно это около ',
      ],
      'Ориентир по цене': [
        'По цене примерно',
        'Обычно около',
        'Стоит примерно',
      ],
    };
    for (final entry in swaps.entries) {
      if (out.startsWith(entry.key)) {
        final alt = _pick('nat-${entry.key}', entry.value, seed);
        out = '$alt${out.substring(entry.key.length)}';
        break;
      }
    }

    // Soften doubled identical sentence openers / clinic jargon mid-reply.
    out = out.replaceAll('Скажите, скажите', 'Скажите');
    out = out.replaceAll('Скажите Скажите', 'Скажите');
    out = out.replaceAll(' в CULT обычно ', ' у нас обычно ');
    out = out.replaceAll(' в CULT ', ' у нас ');
    out = out.replaceAll('В CULT ', 'У нас ');
    out = out.replaceAll(' из прайса CULT', '');
    out = out.replaceAll(' из прайса', '');
    out = out.replaceAll('в прайсе CULT это ', '');
    out = out.replaceAll('в прайсе это ', '');
    out = out.replaceAll('Запись через «+»', 'Можем записаться');
    out = out.replaceAll('запишем через «+»', 'запишем');
    out = out.replaceAll('Запишем через «+»', 'Запишем');
    out = out.replaceAll('через «+»', 'кнопкой «Запись»');
    out = out.replaceAll('Ориентир по цене —', 'Стоит примерно');
    out = out.replaceAll('Ориентир по цене', 'По цене примерно');
    out = out.replaceAll('Ориентир по времени уже есть:', 'По времени уже есть:');
    out = out.replaceAll('Ориентир по времени приняла:', 'Время приняла:');
    out = out.replaceAll('Ориентир из прайса CULT:', 'Из прайса:');
    out = out.replaceAll(' наших протоколов', ' наших процедур');
    out = out.replaceAll('подстроим протокол', 'подстроим план');
    out = out.replaceAll('сузить протокол', 'сузить план');

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

  /// Bare clinic name for mid-sentence talk — no price dump (that sounds like a robot).
  String? _lineService(Service? item) {
    if (item == null) return null;
    var t = item.title.trim();
    // Chair protocol "Инфузия HydraPure" reads like an IV drip aloud — keep the brand.
    if (t.toLowerCase().startsWith('инфузия ')) {
      t = t.substring('инфузия '.length).trim();
    }
    return t;
  }

  String? _lineProduct(Product? item) {
    if (item == null) return null;
    return item.name;
  }

  String? _lineInfusion(Infusion? item) {
    if (item == null) return null;
    return item.title;
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

/// Shop line Мира adds via [ClinicStore.addToCart].
class AgentCartAdd {
  const AgentCartAdd({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final int price;
}

/// VIP transfer request — store posts to admin when [ready].
class AgentTransferRequest {
  const AgentTransferRequest({
    required this.from,
    this.when,
    this.ready = false,
  });

  final String from;
  final String? when;
  final bool ready;
}

class AgentTurn {
  const AgentTurn({
    required this.reply,
    this.pendingBooking,
    this.cartAdd,
    this.transfer,
    this.openChat,
  });

  final String reply;
  final AgentBookingDraft? pendingBooking;
  final AgentCartAdd? cartAdd;
  final AgentTransferRequest? transfer;

  /// `admin` or `specialist` — voice/UI opens that chat.
  final String? openChat;
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
