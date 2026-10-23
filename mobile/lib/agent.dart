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
  }) {
    final q = _normalize(text);
    if (q.isEmpty) {
      return 'Я вас слушаю. Расскажите своими словами, что беспокоит или чего хотите — '
          'подберу спокойный следующий шаг: процедура, уход или запись.';
    }

    // Small talk and short acknowledgements first.
    final chat = _chatReply(q);
    if (chat != null) return chat;

    // Follow-ups after clarifying questions («лицо или тело?»…).
    final follow = _followUpReply(q, lastBot);
    if (follow != null) return follow;

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
    if (hit != null && hit.score >= 8) return hit.reply;
    if (faq != null) return faq;
    if (hit != null && hit.score >= 5) return hit.reply;

    return 'Хорошо, давайте разберём без каталога. '
        'Вам сейчас ближе лицо, тело, энергия или домашний уход? '
        'Можете просто сказать, что не нравится в отражении — предложу мягкий шаг и, если нужно, запись.';
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
          'Запишем через «+» на главной или в меню «Инфузии» — перед капельницей врач уточнит показания.';
    } else if (bestDevice == best && deviceHits.isNotEmpty) {
      final item = deviceHits.first.item;
      reply =
          'Аппаратный протокол «${item.title}»: ${item.meta}. '
          'Ориентир по цене — ${item.price}. '
          'Подробности в меню «Аппаратная», на консультации подберём интенсивность под вашу кожу.';
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
        'low' => 'На полке осталось мало — если подходит, лучше взять сейчас.',
        'out' => 'Сейчас этой формулы нет в наличии, могу предложить соседнюю из шопа.',
        _ => 'Формула сейчас в наличии.',
      };
      final about = _firstSentence(item.about);
      final buf = StringBuffer('Обратите внимание на ${item.name}. ');
      if (wantsPrice) buf.write('Ориентир по цене — ${_rub(item.price)}. ');
      buf.write('${item.blurb}. ');
      if (wantsCompose) {
        buf.write('В составе: ${item.composition}. ');
      }
      if (wantsStock || item.stock != 'in') buf.write('$stock ');
      if (about.isNotEmpty) buf.write('$about ');
      parts.add(buf.toString().trim());
    }
    final tail = items.length == 1
        ? 'Карточку откройте в «Магазин» или сразу положите в корзину — при необходимости скорректируем на консультации.'
        : 'Другие формулы смотрите во вкладке «Магазин», могу сузить выбор под вашу задачу.';
    return '${parts.join(' ')}\n$tail';
  }

  String _formatServices(List<Service> items, {required bool wantsPrice}) {
    final parts = <String>[];
    for (final item in items) {
      final buf = StringBuffer(
        'По протоколу «${item.title}»: ${item.priceLabel}, занимает ${item.duration}. ',
      );
      buf.write('${item.blurb} ');
      if (!wantsPrice && item.results.isNotEmpty) {
        buf.write('Ожидаемый эффект: ${item.results.take(2).join(', ')}. ');
      }
      if (item.contraindications.isNotEmpty) {
        buf.write(
          'Важно учесть противопоказания: ${item.contraindications.take(2).join('; ')}. ',
        );
      }
      parts.add(buf.toString().trim());
    }
    return '${parts.join(' ')}\nЕсли откликается — запишем через «+» или меню «Услуги», на осмотре уточним детали.';
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
        'Актуальный прайс — в меню «Прайс», запись удобнее через «+».';
  }

  String _firstSentence(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final cut = t.split(RegExp(r'(?<=[.!?])\s+')).first.trim();
    return cut.length > 160 ? '${cut.substring(0, 157)}…' : cut;
  }

  /// Greetings and bedside manner — answers before catalog/FAQ ops.
  /// Note: Dart `\b` is ASCII-only, so we avoid it for Cyrillic.
  String? _chatReply(String q) {
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final words = compact.split(' ').where((w) => w.isNotEmpty).toList();
    final first = words.isEmpty ? '' : words.first;
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
      return 'Здравствуйте, очень приятно. '
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

  String? _followUpReply(String q, String? lastBot) {
    if (lastBot == null || lastBot.isEmpty) return null;
    final prev = _normalize(lastBot);
    final compact = q
        .replaceAll(RegExp(r'[!?.,…:;]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (prev.contains('лицо или тело') || prev.contains('лицо, тело')) {
      if (compact.contains('лиц')) {
        return 'Отлично, про лицо. Что заметнее: сухость, тусклость, морщинки, отёк или пигмент? '
            'От этого выберу массаж, уход, аппаратную или домашний крем.';
      }
      if (compact.contains('тел')) {
        return 'Хорошо, тело. Чаще смотрим плотность, рельеф или общий тонус. '
            'Могу рассказать про аппаратные протоколы или записаться на консультацию — что ближе?';
      }
      if (compact.contains('энерг') ||
          compact.contains('сил') ||
          compact.contains('устало')) {
        return 'Тогда ближе инфузии и поддержка изнутри: NAD+, Immunity или Beauty & Glow. '
            'Могу коротко сравнить или сразу открыть запись через плюс на главной.';
      }
      if (compact.contains('уход') ||
          compact.contains('дом') ||
          compact.contains('крем') ||
          compact.contains('сывор')) {
        return 'Для дома хорошо заходят барьерный крем и пептидная сыворотка из шопа. '
            'Скажите «крем» или «сыворотка» — назову цену и наличие.';
      }
    }
    if (prev.contains('что не нравится') ||
        prev.contains('что видите в зеркале') ||
        prev.contains('что беспокоит')) {
      return _concernReply(q) ??
          'Слышу вас. Давайте уточним зону — лицо или тело — и подберём самый спокойный старт.';
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
      return 'Похоже на дефицит влаги и барьера. '
          'В клинике мягко заходит увлажняющий уход, дома — барьерный крем Lumen Barrier. '
          'Если скажете «крем» или «записаться на уход» — продолжим конкретно.';
    }
    if (q.contains('жирн') ||
        q.contains('блеск') ||
        q.contains('расшир') ||
        q.contains('поры') ||
        q.contains('пор ')) {
      return 'При блеске и порах часто помогает плотный уход или аппаратное уплотнение вроде микроигольчатого RF. '
          'Могу назвать цену RF или предложить сначала консультацию — как комфортнее?';
    }
    // Not «постакне» — that has its own FAQ path.
    if (((q.contains('акне') || q.contains('acne')) &&
            !q.contains('постакне') &&
            !q.contains('postacne')) ||
        q.contains('прыщ') ||
        q.contains('воспал') ||
        q.contains('высып')) {
      return 'Воспаления не трогаем агрессивно сами. Лучше очный осмотр: подберём уход или пилинг без лишней травмы. '
          'Запись на консультацию — через плюс на главной, или опишите зону подробнее.';
    }
    if (q.contains('морщин') ||
        q.contains('мими') ||
        q.contains('лоб') ||
        q.contains('гусиные')) {
      return 'Мимические морщины обычно ведём ботулинотерапией и поддержкой кожи. '
          'Могу рассказать про инъекции или сначала массаж и уход, если хотите мягкий вход. Что ближе?';
    }
    if (q.contains('овал') ||
        q.contains('второй подбородок') ||
        q.contains('брыл') ||
        q.contains('контур лиц')) {
      return man
          ? 'За овал у мужчин часто берём RF-лифтинг или барбер-массаж — без «перекачанного» вида. Хотите цену или запись?'
          : 'За овал хорошо работают скульптурный массаж и аппаратное уплотнение. Могу сравнить или записать на консультацию.';
    }
    if (q.contains('отёк') ||
        q.contains('мешк') ||
        q.contains('одутл') ||
        q.contains('пастоз')) {
      return 'Отёк и тяжесть в лице часто снимает лимфодренажный или скульптурный массаж, плюс питьевой режим. '
          'Спросите «массаж» — назову длительность и цену.';
    }
    if (q.contains('пигмент') ||
        q.contains('пятн') ||
        q.contains('веснуш') ||
        q.contains('неравном')) {
      return 'Пигмент разбираем спокойно: пилинг, IPL или домашний протокол — без самостоятельного отбеливания. '
          'Назовите «пилинг» или «лазер», если хотите цифры из прайса.';
    }
    if (q.contains('тускл') ||
        q.contains('серый') ||
        q.contains('сияни') ||
        q.contains('свежий вид') ||
        q.contains('освежить') ||
        q.contains('перед мероприя') ||
        q.contains('на выход') ||
        q.contains('выглядеть')) {
      return 'Для быстрого «свежего вида» люблю уход с сыворотками или скульптурный массаж. '
          'Если есть день-два до события — скажите дату, подберём протокол без сильной реабилитации.';
    }
    if (q.contains('устал') ||
        q.contains('нет сил') ||
        q.contains('энерг') ||
        q.contains('выгоран') ||
        q.contains('иммун')) {
      return 'Когда сил мало, смотрим инфузии: NAD+ для энергии, Immunity для поддержки, Beauty & Glow для кожи. '
          'Могу коротко сравнить три варианта или сразу записать.';
    }
    if (q.contains('сон') || q.contains('не высып') || q.contains('бессон')) {
      return 'Сон сильно влияет на кожу и отёк. Из клиники — поддержка инфузиями и мягкий уход, плюс режим. '
          'Если хотите продукт из шопа под восстановление — скажите «шоп» или название формулы.';
    }
    if (q.contains('глаз') || q.contains('тёмные круги') || q.contains('синяк под')) {
      return 'Зона глаз деликатная: чаще начинаем с осмотра, иногда мезотерапия или уход без агрессии. '
          'Расскажите, больше отёк или тень — уточню направление.';
    }
    if (q.contains('шея') || q.contains('декольте')) {
      return 'Шея и декольте любят плотность и аккуратный уход. На консультации смотрим, нужен ли аппаратный протокол или достаточно домашнего крема. Запишем осмотр?';
    }
    if (q.contains('похудеть') ||
        q.contains('жир на') ||
        q.contains('целлюлит') ||
        q.contains('живот')) {
      return 'По телу честно: эстетика дополняет питание и нагрузку, а не заменяет их. '
          'Могу рассказать про аппаратные протоколы на консультации — без обещаний «минус размеры за раз».';
    }
    if (q.contains('стресс') || q.contains('нервн') || q.contains('тревож')) {
      return 'Стресс часто читается по коже и мышцам лица. Иногда достаточно массажа и спокойного визита без «тяжёлой артиллерии». '
          'Хотите мягкий ритуал ухода или просто записаться поговорить с врачом?';
    }
    return null;
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
    // Only generic catalog questions — not «на процедуру» / «длится процедура».
    if (RegExp(r'(^|\s)услуг').hasMatch(q) ||
        q.contains('каталог услуг') ||
        q.contains('что делаете') ||
        q.contains('чем занима')) {
      return 'В CULT Сочи: уходы и пилинги, массаж, инъекции, аппаратная (RF, IPL, SMAS), '
          'инфузии и лаборатория. Откройте «Услуги» / «Прайс» или назовите процедуру голосом — отвечу ценой.';
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
