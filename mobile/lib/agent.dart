import 'data.dart';
import 'yclients.dart';

/// On-device CULT assistant: FAQ + retrieval over services and shop products.
/// Voice UI calls [answer] after speech recognition; replies can be spoken via TTS.
class CultAgent {
  const CultAgent();

  /// Full reply for the bot contact.
  /// Free talk → concerns → catalog/FAQ; never a cold dead-end.
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
  }) {
    final q = _normalize(text);
    if (q.isEmpty) {
      return 'Я рядом и внимательно слушаю. '
          'Можно без названий процедур: что смущает в коже или самочувствии, '
          'или какой результат хотите к дате. Подскажу мягкий следующий шаг.';
    }

    // «Повтори / не поняла» — briefly restate last bot line.
    final meta = _metaReply(q, lastBot);
    if (meta != null) return meta;

    // Follow-ups first when we have context (so «да» after CTA is not generic).
    final follow = _followUpReply(
      q,
      lastBot,
      gender: gender,
      lastUser: lastUser,
    );
    if (follow != null) return follow;

    // Small talk — short «да/нет» defer if lastBot exists (handled above).
    final chat = _chatReply(q, lastBot: lastBot, gender: gender);
    if (chat != null) return chat;

    // Bare «лицо» / «тело» without prior turn.
    final zone = _zoneOnlyReply(q);
    if (zone != null) return zone;

    // «Что лучше…» comparisons before raw catalog dump.
    final compare = _compareReply(q, gender: gender);
    if (compare != null) return compare;

    // Deadline / event / budget / «посоветуй что-нибудь».
    final situation = _situationReply(q, gender: gender);
    if (situation != null) return situation;

    // Two concerns in one phrase (dry + tired…).
    final blend = _blendConcernReply(q, gender: gender);
    if (blend != null) return blend;

    // Free-form concerns / goals without exact catalog names.
    final concern = _concernReply(q, gender: gender);
    if (concern != null) return concern;

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
      return _withCatalogWarmth(q, hit.reply);
    }

    // Resume from previous user concern if this turn is vague.
    final resume = _resumeLastUser(q, lastUser, gender: gender);
    if (resume != null) return resume;

    return 'Слышу вас — давайте сузим без жёстких названий. '
        'Одного ориентира достаточно: лицо, тело, энергия или домашний уход. '
        'Или как в зеркале: тусклость, отёк, морщинки, пигмент — '
        'дам два спокойных варианта и мягкий путь к записи, если захотите.';
  }

  String _withCatalogWarmth(String q, String reply) {
    if (q.contains('боюсь') ||
        q.contains('страшно') ||
        q.contains('пережива')) {
      return 'Понимаю осторожность — вот по делу, без давления. $reply';
    }
    if (q.contains('не знаю') || q.contains('подскажи') || q.contains('посоветуй')) {
      return 'Давайте мягко. $reply';
    }
    return reply;
  }

  String? _metaReply(String q, String? lastBot) {
    final wantsRepeat = q.contains('повтори') ||
        q.contains('повтор') ||
        q.contains('еще раз') ||
        q.contains('ещё раз') ||
        q.contains('не понял') ||
        q.contains('не поняла') ||
        q.contains('не расслыша') ||
        q.contains('что ты сказа') ||
        q.contains('что вы сказа');
    if (!wantsRepeat) return null;
    if (lastBot == null || lastBot.trim().isEmpty) {
      return 'Конечно. Скажите ещё раз вопрос своими словами — отвечу короче и по шагам.';
    }
    final brief = _briefRestate(lastBot);
    return 'Коротко повторю: $brief '
        'Если удобнее иначе — уточните зону или цель одним словом.';
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
    final vague = compact.length <= 18 ||
        compact.contains('а дальше') ||
        compact.contains('что дальше') ||
        compact.contains('и что') ||
        compact.contains('ну и') ||
        compact == 'дальше' ||
        compact == 'продолжим' ||
        compact == 'и всё' ||
        compact.contains('а что с этим');
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
        q.contains('сияни') ||
        q.contains('свежий');
    final wrinkle = q.contains('морщин') || q.contains('мими') || q.contains('гусиные');
    final oval = q.contains('овал') ||
        q.contains('второй подбородок') ||
        q.contains('брыл') ||
        q.contains('контур лиц');
    final edema = q.contains('отёк') || q.contains('мешк') || q.contains('пастоз');
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
    final lead = items.length == 1 ? '' : 'Нашла близкие варианты. ';
    final tail = items.length == 1
        ? 'Можно открыть карточку в «Магазин» или сразу в корзину — на консультации при необходимости скорректируем.'
        : 'Если скажете задачу кожи (барьер, плотность, энергия), сузим до одной формулы.';
    return '$lead${parts.join(' ')}\n$tail';
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
          'здравствуй',
          'здравствуйте',
          'хай',
          'hello',
          'hi',
          'здорово',
          'хелло',
          'салют',
        }.contains(first) ||
        compact.startsWith('добрый день') ||
        compact.startsWith('доброе утро') ||
        compact.startsWith('добрый вечер') ||
        compact.startsWith('доброй ночи');
    if (isGreeting && words.length <= 5) {
      final man = gender == ClientGender.man;
      return man
          ? 'Здравствуйте, рад вас слышать. '
              'Можно без названий: кожа, энергия, овал или запись — подстроюсь. С чего начнём?'
          : 'Здравствуйте, очень приятно. '
              'Я рядом, как на спокойной консультации: можно просто поговорить о коже, энергии или записи. '
              'С чего начнём?';
    }
    if (q.contains('как дела') ||
        q.contains('как ты') ||
        q.contains('как вы') ||
        q.contains('как настроен') ||
        q.contains('как жизнь') ||
        q.contains('how are you')) {
      return 'Спасибо, у меня всё ровно — и я целиком для вас. '
          'А вы как себя чувствуете сегодня? Если что-то тянет или хочется освежить вид — расскажите, подстроюсь.';
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
      return 'И вам спасибо за доверие. Я рядом — можно продолжить голосом или текстом, без спешки.';
    }
    if (compact == 'пока' ||
        compact.startsWith('до встречи') ||
        compact.startsWith('всего доброго') ||
        compact.startsWith('до свидания') ||
        compact == 'спокойной ночи') {
      return 'Всего доброго. Берегите себя — и буду рада снова услышать вас в CULT.';
    }
    if (q.contains('кто ты') ||
        q.contains('как тебя зовут') ||
        q.contains('что ты умеешь') ||
        q.contains('чем можешь помочь') ||
        q.contains('ты врач') ||
        q.contains('ты бот') ||
        q.contains('ты человек')) {
      return 'Я CULT Агент — голос клиники. Говорю просто, как врач на осмотре: слушаю жалобу, предлагаю мягкий протокол или уход. '
          'Окончательное решение всегда за очным специалистом. О чём подумаем?';
    }
    if (words.length <= 4 &&
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
      return 'Конечно, давайте вместе. '
          'Коротко: лицо или тело, что хотите улучшить, и был ли уже курс у нас? '
          'От этого мягко выберу услугу или домашний уход.';
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
          'окей',
          'хорошо',
          'ладно',
          'понятно',
          'ясно',
          'давай',
          'конечно',
        }.contains(compact)) {
      return 'Хорошо. Тогда скажите чуть конкретнее: лицо, тело, энергия или запись — продолжим в вашем темпе.';
    }
    if (words.length <= 3 &&
        const {'нет', 'не надо', 'не нужно', 'потом'}.contains(compact)) {
      return 'Хорошо, без давления. Если позже захотите совет или запись — просто напишите или нажмите «Голос».';
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
          'окей',
          'хорошо',
          'ладно',
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
        return 'Отлично. Нажмите «+» на главной или откройте «Запись»: выберите услугу, врача и время. '
            'Если ещё не решили протокол — возьмите консультацию, на осмотре сузим без спешки.';
      }
      if (offeredCompare) {
        return 'Хорошо. Тогда скажите полюса или задачу: например массаж или RF, крем или сыворотка, '
            'либо что видите в зеркале — сравню спокойно.';
      }
      if (askedMirror) {
        return 'Давайте тогда по зеркалу: сухость, тусклость, морщинки, отёк или пигмент? '
            'Одного слова достаточно — предложу мягкий старт.';
      }
      return 'Хорошо, продолжаем. Лицо, тело, энергия или запись — что сейчас ближе?';
    }
    if (shortNo) {
      return 'Хорошо, без давления. Можем просто поговорить о коже или уходе — или вернётесь позже голосом или текстом.';
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
      return _concernReply(q, gender: gender) ??
          'Слышу вас. Давайте уточним зону — лицо или тело — и подберём самый спокойный старт.';
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
  String? _situationReply(String q, {ClientGender? gender}) {
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
        q.contains('на выходн') ||
        q.contains('к вечеру') ||
        q.contains('срочно');
    final event = q.contains('свадьб') ||
        q.contains('день рожден') ||
        q.contains('мероприят') ||
        q.contains('съёмк') ||
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
      return 'Возраст — ориентир, не диагноз: смотрим кожу и цели, а не цифру в паспорте. '
          'Коротко опишите, что смущает (сухость, плотность, мимика, энергия) — предложу мягкий вход без лишнего.';
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

  /// Free-form goals and skin concerns without exact product names.
  String? _concernReply(String q, {ClientGender? gender}) {
    final man = gender == ClientGender.man;
    if (q.contains('сух') ||
        q.contains('стягив') ||
        q.contains('шелуш') ||
        q.contains('обезвож')) {
      return 'Понимаю: стянутость и сухость часто про барьер и влагу, а не про «ещё один актив». '
          'В клинике мягко заходит увлажняющий уход; дома — барьерный крем Lumen Barrier. '
          'Скажите «крем» или «записаться на уход» — продолжим конкретно, без спешки.';
    }
    if (q.contains('жирн') ||
        q.contains('блеск') ||
        q.contains('расшир') ||
        q.contains('поры') ||
        q.contains('пор ')) {
      return 'Блеск и поры — частая история; не обязательно сразу «жёстко чистить». '
          'Часто помогает плотный уход или аппаратное уплотнение вроде микроигольчатого RF. '
          'Могу назвать цену RF или предложить сначала спокойную консультацию — как комфортнее?';
    }
    // Not «постакне» — that has its own FAQ path.
    if (((q.contains('акне') || q.contains('acne')) &&
            !q.contains('постакне') &&
            !q.contains('postacne')) ||
        q.contains('прыщ') ||
        q.contains('воспал') ||
        q.contains('высып')) {
      return 'Воспаления лучше не трогать агрессивно дома — кожа потом дольше восстанавливается. '
          'На очном осмотре подберём уход или пилинг без лишней травмы. '
          'Запись на консультацию — через «+» на главной; или опишите зону подробнее.';
    }
    if (q.contains('морщин') ||
        q.contains('мими') ||
        q.contains('лоб') ||
        q.contains('гусиные')) {
      return 'Мимические морщины обычно ведём ботулинотерапией и поддержкой кожи — но вход может быть мягким. '
          'Могу рассказать про инъекции или сначала про массаж и уход. Что ближе вашему темпу?';
    }
    if (q.contains('овал') ||
        q.contains('второй подбородок') ||
        q.contains('брыл') ||
        q.contains('контур лиц')) {
      return man
          ? 'За овал у мужчин часто берём RF-лифтинг или барбер-массаж — свежий контур без «перекачанного» вида. '
              'Хотите ориентир по цене или сразу запись на осмотр?'
          : 'За овал хорошо работают скульптурный массаж и аппаратное уплотнение — можно начать с более мягкого. '
              'Могу коротко сравнить или записать на консультацию.';
    }
    if (q.contains('отёк') ||
        q.contains('мешк') ||
        q.contains('одутл') ||
        q.contains('пастоз')) {
      return 'Отёк и тяжесть в лице часто снимает лимфодренажный или скульптурный массаж, плюс питьевой режим. '
          'Это один из самых спокойных стартов. Спросите «массаж» — назову длительность и цену.';
    }
    if (q.contains('пигмент') ||
        q.contains('пятн') ||
        q.contains('веснуш') ||
        q.contains('неравном')) {
      return 'Пигмент разбираем спокойно и по фототипу: пилинг, IPL или домашний протокол — без самостоятельного отбеливания. '
          'Назовите «пилинг» или «лазер», если хотите цифры из прайса; иначе запишем осмотр.';
    }
    if (q.contains('тускл') ||
        q.contains('серый') ||
        q.contains('сияни') ||
        q.contains('свежий вид') ||
        q.contains('освежить') ||
        q.contains('перед мероприя') ||
        q.contains('на выход') ||
        q.contains('выглядеть')) {
      return 'Для быстрого «свежего вида» люблю уход с сыворотками или скульптурный массаж — без тяжёлой реабилитации. '
          'Если есть день-два до события, скажите дату: подберём протокол под календарь.';
    }
    if (q.contains('устал') ||
        q.contains('нет сил') ||
        q.contains('энерг') ||
        q.contains('выгоран') ||
        q.contains('иммун')) {
      return 'Когда сил мало, это слышно сразу — здесь уместны инфузии: NAD+ для энергии, Immunity для поддержки, Beauty & Glow для кожи. '
          'Могу коротко сравнить три варианта или сразу помочь с записью.';
    }
    if (q.contains('сон') || q.contains('не высып') || q.contains('бессон')) {
      return 'Сон сильно влияет на кожу и отёк; клиника не заменяет режим, но может поддержать. '
          'Из кабинета — мягкий уход и при необходимости инфузии. '
          'Если нужен продукт из шопа под восстановление — скажите «шоп» или название формулы.';
    }
    if (q.contains('глаз') ||
        q.contains('тёмные круги') ||
        q.contains('темные круги') ||
        q.contains('синяк под')) {
      return 'Зона глаз деликатная: чаще начинаем с осмотра, иногда мезотерапия или уход без агрессии. '
          'Расскажите, больше отёк или тень — уточню направление без лишних процедур.';
    }
    if (q.contains('шея') || q.contains('декольте')) {
      return 'Шея и декольте часто выдают возраст раньше лица — здесь любят плотность и аккуратный уход. '
          'На консультации смотрим, нужен ли аппаратный протокол или достаточно домашнего крема. Запишем осмотр?';
    }
    if (q.contains('похудеть') ||
        q.contains('жир на') ||
        q.contains('целлюлит') ||
        q.contains('живот')) {
      return 'По телу честно: эстетика дополняет питание и нагрузку, а не заменяет их. '
          'Могу рассказать про аппаратные протоколы на консультации — без обещаний «минус размеры за раз».';
    }
    if (q.contains('стресс') || q.contains('нервн') || q.contains('тревож')) {
      return 'Стресс часто читается по коже и мышцам лица — иногда достаточно массажа и спокойного визита. '
          'Хотите мягкий ритуал ухода или просто записаться поговорить с врачом без «тяжёлой артиллерии»?';
    }
    if (q.contains('чувствительн') ||
        q.contains('красне') ||
        q.contains('жжёт') ||
        q.contains('жжет') ||
        q.contains('щипл')) {
      return 'Чувствительность — сигнал снизить агрессию: сначала барьер и мягкий уход, аппаратные и кислоты — только после осмотра. '
          'Могу подсказать барьерный крем из шопа или записать на спокойную консультацию.';
    }
    if (q.contains('после процедур') ||
        q.contains('после укол') ||
        q.contains('после инъек') ||
        q.contains('после пилинг') ||
        q.contains('после массаж') ||
        q.contains('что нельзя после') ||
        q.contains('как ухаживать после')) {
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
      return 'В магазине кнопка «ИИ Помощник» подскажет формулу под профиль. Здесь же можно спросить голосом: название, цену или состав.';
    }
    if (q.contains('микрофон') ||
        q.contains('голосом') ||
        q.contains('голосовой') ||
        q.contains('распознаван') ||
        RegExp(r'(^|\s)(голос|озвуч)').hasMatch(q)) {
      return 'Нажмите микрофон внизу чата и говорите своими словами — например: «сколько стоит микроигольчатый RF» или «есть ли Mitochondrial Fuel». '
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
    if (q.contains('добр') || q.contains('адрес') || q.contains('ехать')) {
      return 'Ждём вас в Сочи, Черноморская, 6. Если нужен трансфер — закажите в профиле, водитель напишет в чат.';
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
    if (q.contains('беремен') || q.contains('кормлен')) {
      return 'При беременности и лактации часть процедур ограничена. Напишите срок врачу в чате — подскажем безопасный протокол.';
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
