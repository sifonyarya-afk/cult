import 'package:cult_clinic/agent.dart';
import 'package:cult_clinic/data.dart';
import 'package:cult_clinic/store.dart';
import 'package:cult_clinic/yclients.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Агент отвечает ценой услуги из каталога', () {
    final reply = cultAgent.answer('Сколько стоит микроигольчатый RF?');
    expect(reply.toLowerCase(), contains('rf'));
    expect(reply, contains('45 000'));
  });

  test('Агент находит товар шопа и состав', () {
    final reply = cultAgent.answer('Состав Veil Peptide Serum');
    expect(reply, contains('Veil Peptide'));
    expect(reply.toLowerCase(), contains('матриксил'));
  });

  test('Агент знает наличие Mitochondrial Fuel', () {
    final reply = cultAgent.answer('Есть ли Mitochondrial Fuel в наличии?');
    expect(reply, contains('Mitochondrial Fuel'));
    expect(reply.toLowerCase(), contains('мало'));
  });

  test('Агент учитывает live-услуги филиала', () {
    final live = [
      YcService(
        id: 1,
        title: 'Консультация косметолога CULT',
        priceMin: 5000,
        priceMax: 5000,
        seanceLength: 1800,
        category: 'Консультации',
      ),
    ];
    final reply = cultAgent.answer(
      'Консультация косметолога CULT цена',
      liveServices: live,
    );
    expect(reply, contains('Консультация косметолога CULT'));
    expect(reply, contains('5'));
  });

  test('FAQ по часам работы сохраняется', () {
    final reply = cultAgent.answer('Часы работы');
    expect(reply, contains('9:00'));
    expect(reply, contains('21:00'));
  });

  test('Русский запрос сыворотка находит Serum в шопе', () {
    final reply = cultAgent.answer('есть ли сыворотка');
    expect(reply.toLowerCase(), anyOf(contains('serum'), contains('сыворот')));
    expect(reply.toLowerCase(), isNot(contains('не нашла точного совпадения')));
  });

  test('Крем и барьерный крем попадают в каталог', () {
    final cream = cultAgent.answer('крем');
    expect(cream, contains('Lumen Barrier Cream'));
    final barrier = cultAgent.answer('барьерный крем');
    expect(barrier, contains('Lumen Barrier Cream'));
  });

  test('Короткий бренд Veil и слово serum находятся', () {
    expect(cultAgent.answer('Veil'), contains('Veil Peptide'));
    expect(cultAgent.answer('serum').toLowerCase(), contains('serum'));
  });

  test('Общий вопрос про услуги не уходит в пустой каталог', () {
    final reply = cultAgent.answer('какие услуги');
    expect(reply.toLowerCase(), isNot(contains('не нашла точного совпадения')));
    expect(reply.toLowerCase(), anyOf(contains('услуг'), contains('прайс')));
  });

  test('Голосовая подсказка про микрофон', () {
    final reply = cultAgent.answer('Как спросить голосом?');
    expect(reply.toLowerCase(), contains('микрофон'));
  });

  test('Агент отвечает на привет и как дела как живой консультант', () {
    final hi = cultAgent.answer('Привет');
    expect(
      hi.toLowerCase(),
      anyOf(contains('здравств'), contains('привет')),
    );
    expect(hi.toLowerCase(), contains('мира'));
    expect(hi.toLowerCase(), isNot(contains('не нашла')));
    expect(hi, isNot(contains('(')));
    final mood = cultAgent.answer('Как дела?');
    expect(
      mood.toLowerCase(),
      anyOf(
        contains('ровн'),
        contains('чувству'),
        contains('хорошо'),
        contains('нормальн'),
        contains('живу'),
        contains('отлично'),
      ),
    );
    final thanks = cultAgent.answer('Спасибо');
    expect(
      thanks.toLowerCase(),
      anyOf(contains('спасибо'), contains('пожалуйста'), contains('рада')),
    );
    final tip = cultAgent.answer('Подскажи');
    expect(tip.toLowerCase(), anyOf(contains('вместе'), contains('лицо')));
  });

  test('Мира обучена на клинические вопросы без слабого fallback', () {
    final lips = cultAgent.answer('Хочу губы натуральные');
    expect(lips.toLowerCase(), anyOf(contains('губ'), contains('натурал')));
    expect(lips.toLowerCase(), isNot(contains('не уверена')));
    final peel = cultAgent.answer('Что лучше пилинг или чистка?');
    expect(peel.toLowerCase(), contains('чистка'));
    expect(peel.toLowerCase(), contains('пилинг'));
    final burn = cultAgent.answer('Кожа горит после кислоты');
    expect(burn.toLowerCase(), anyOf(contains('барьер'), contains('актив')));
    expect(burn.toLowerCase(), isNot(contains('к вечеру')));
    final flake = cultAgent.answer('Норм ли шелушение после пилинга?');
    expect(flake.toLowerCase(), anyOf(contains('норма'), contains('spf'), contains('барьер')));
    final drip = cultAgent.answer('Можно натощак на капельницу?');
    expect(drip.toLowerCase(), contains('капельниц'));
    expect(drip.toLowerCase(), isNot(contains('забор крови')));
    final admin = cultAgent.answer('Чем ты отличаешься от чата админа?');
    expect(admin.toLowerCase(), contains('администратор'));
    expect(admin.toLowerCase(), contains('мира'));
    final filler = cultAgent.answer('Сколько держится филлер?');
    expect(filler.toLowerCase(), anyOf(contains('месяц'), contains('год')));
    final ref = cultAgent.answer('Нужна справка для работы');
    expect(ref.toLowerCase(), anyOf(contains('справк'), contains('администратор')));
  });

  test('Мира отвечает на разные житейские вопросы по-человечески', () {
    final pregnant = cultAgent.answer('Я беременна, что можно?');
    expect(pregnant.toLowerCase(), anyOf(contains('врач'), contains('беремен')));
    expect(pregnant.toLowerCase(), isNot(contains('не нашла')));
    final sad = cultAgent.answer('Мне грустно');
    expect(
      sad.toLowerCase(),
      anyOf(
        contains('жаль'),
        contains('слышу'),
        contains('услыш'),
        contains('бывает'),
        contains('без спешки'),
      ),
    );
    final here = cultAgent.answer('Ты тут?');
    expect(here.toLowerCase(), anyOf(contains('здесь'), contains('тут'), contains('связи')));
    final weather = cultAgent.answer('Что с погодой для кожи?');
    expect(weather.toLowerCase(), anyOf(contains('spf'), contains('барьер'), contains('кож')));
    final open = cultAgent.answer('Вы сегодня открыты?');
    expect(open.toLowerCase(), anyOf(contains('9:00'), contains('ежедневн'), contains('сегодня')));
    final photo = cultAgent.answer('Можно по фото сказать что делать?');
    expect(photo.toLowerCase(), anyOf(contains('фото'), contains('врач')));
  });

  test('Ответ про морщины звучит по-человечески без каталожных скобок', () {
    final wrinkles = cultAgent.answer('Как избавиться от морщин?');
    expect(wrinkles.toLowerCase(), anyOf(contains('массаж'), contains('морщи')));
    expect(RegExp(r'«[^»]+»\s*\(').hasMatch(wrinkles), isFalse);
    expect(wrinkles, isNot(contains('₽')));
    expect(wrinkles.toLowerCase(), isNot(contains('ориентир по цене')));
  });

  test('Мира отвечает на базовые живые вопросы', () {
    final name = cultAgent.answer('Как тебя зовут?');
    expect(name.toLowerCase(), contains('мира'));
    final name2 = cultAgent.answer('Как вас зовут');
    expect(name2.toLowerCase(), contains('мира'));
    final about = cultAgent.answer('Расскажи о себе');
    expect(about.toLowerCase(), contains('мира'));
    final wrinkles = cultAgent.answer('Как избавиться от морщин?');
    expect(
      wrinkles.toLowerCase(),
      anyOf(contains('массаж'), contains('бот'), contains('морщи')),
    );
    expect(wrinkles.toLowerCase(), isNot(contains('не нашла')));
    final help = cultAgent.answer('Помоги с морщинами');
    expect(
      help.toLowerCase(),
      anyOf(contains('массаж'), contains('морщи'), contains('линии')),
    );
  });

  test('Свободный разговор по жалобе без названия услуги', () {
    final dry = cultAgent.answer('Кожа очень сухая и стягивает');
    expect(
      dry.toLowerCase(),
      anyOf(contains('барьер'), contains('barrier'), contains('влаг')),
    );
    expect(dry.toLowerCase(), isNot(contains('точного совпадения')));
    final tired = cultAgent.answer('Я устала, нет сил');
    expect(
      tired.toLowerCase(),
      anyOf(contains('инфуз'), contains('капельн')),
    );
    final fear = cultAgent.answer('Боюсь что будет больно');
    expect(fear.toLowerCase(), anyOf(contains('анестез'), contains('страх')));
  });

  test('Follow-up после уточнения лицо или тело', () {
    final reply = cultAgent.answer(
      'лицо',
      lastBot:
          'Вам сейчас ближе лицо или тело? Можете просто сказать, что не нравится.',
    );
    expect(reply.toLowerCase(), contains('лицо'));
    expect(reply.toLowerCase(), anyOf(contains('сухость'), contains('морщин')));
  });

  test('Сравнение массаж или RF отвечает по делу', () {
    final reply = cultAgent.answer('Что лучше: массаж или RF?');
    expect(reply.toLowerCase(), contains('массаж'));
    expect(reply.toLowerCase(), contains('rf'));
    expect(reply.toLowerCase(), isNot(contains('не нашла')));
  });

  test('Сравнение крем и сыворотка без каталожного тупика', () {
    final reply = cultAgent.answer('Что выбрать: крем или сыворотка?');
    expect(
      reply.toLowerCase(),
      anyOf(contains('крем'), contains('сыворот'), contains('barrier')),
    );
    expect(reply.toLowerCase(), isNot(contains('точного совпадения')));
  });

  test('«Да» после предложения записи ведёт к записи', () {
    final reply = cultAgent.answer(
      'да',
      lastBot: 'Запишем через «+» на главной? Могу помочь с консультацией.',
    );
    expect(reply.toLowerCase(), anyOf(contains('запись'), contains('«+»'), contains('+')));
    expect(reply.toLowerCase(), isNot(contains('лицо, тело, энергия или запись')));
  });

  test('Запись требует кнопку подтверждения после уточнений', () {
    final ask = cultAgent.respond('Запиши меня на массаж');
    expect(ask.pendingBooking, isNull);
    expect(ask.reply.toLowerCase(), anyOf(contains('когда'), contains('утро')));
    final ready = cultAgent.respond(
      'вечером в пятницу',
      lastBot: ask.reply,
      lastUser: 'Запиши меня на массаж',
      recentUsers: ['Запиши меня на массаж'],
    );
    expect(ready.pendingBooking, isNotNull);
    expect(ready.reply.toLowerCase(), contains('кнопк'));
    expect(ready.pendingBooking!.service.toLowerCase(), contains('массаж'));
  });

  test('Событие завтра — без тяжёлой реабилитации', () {
    final reply = cultAgent.answer('Завтра свадьба, что можно сделать с лицом?');
    expect(reply.toLowerCase(), anyOf(contains('массаж'), contains('уход')));
    expect(reply.toLowerCase(), contains('реабилитац'));
  });

  test('Посоветуй что-нибудь учитывает пол', () {
    final woman = cultAgent.answer('посоветуй что-нибудь');
    expect(woman.toLowerCase(), anyOf(contains('массаж'), contains('уход')));
    final man = cultAgent.answer(
      'посоветуй что-нибудь',
      gender: ClientGender.man,
    );
    expect(man.toLowerCase(), anyOf(contains('муж'), contains('барбер'), contains('овал')));
  });

  test('Смешанная жалоба сухость + усталость', () {
    final reply = cultAgent.answer('Кожа сухая и совсем нет сил');
    expect(reply.toLowerCase(), contains('барьер'));
    expect(reply.toLowerCase(), contains('инфуз'));
  });

  test('Повтори опирается на lastBot', () {
    final reply = cultAgent.answer(
      'Повтори пожалуйста',
      lastBot: 'CULT Сочи открыта с 9:00 до 21:00. Черноморская, 6.',
    );
    expect(reply.toLowerCase(), contains('повтор'));
    expect(reply, contains('9:00'));
  });

  test('Короткое «лицо» без контекста уточняет симптом', () {
    final reply = cultAgent.answer('лицо');
    expect(reply.toLowerCase(), contains('лицо'));
    expect(reply.toLowerCase(), anyOf(contains('сухость'), contains('морщин')));
  });

  test('А дальше продолжает lastUser', () {
    final reply = cultAgent.answer(
      'а дальше',
      lastUser: 'Кожа очень сухая и стягивает',
    );
    expect(reply.toLowerCase(), contains('барьер'));
    expect(reply.toLowerCase(), contains('продолж'));
  });

  test('Бюджет до 10000 предлагает мягкий вход', () {
    final reply = cultAgent.answer('до 10000 что можно на лицо');
    expect(reply.toLowerCase(), anyOf(contains('уход'), contains('массаж'), contains('шоп')));
    expect(reply, contains('10'));
  });

  test('ASR чинит микро игольчатый RF', () {
    final reply = cultAgent.answer('Сколько стоит микро игольчатый эр эф?');
    expect(reply.toLowerCase(), contains('rf'));
    expect(reply, contains('45 000'));
  });

  test('А сколько подтягивает цену из lastBot', () {
    final reply = cultAgent.answer(
      'а сколько',
      lastBot:
          'По услуге «Микроигольчатый RF»: 45 000 ₽, занимает 1 ч. Короткий текст.',
    );
    expect(reply.toLowerCase(), contains('rf'));
    expect(reply, contains('45'));
  });

  test('Подарок без слова сертификат', () {
    final reply = cultAgent.answer('Что подарить подруге?');
    expect(reply.toLowerCase(), contains('сертификат'));
  });

  test('Вопрос про безопасность', () {
    final reply = cultAgent.answer('Это безопасно?');
    expect(reply.toLowerCase(), contains('осмотр'));
  });

  test('Короткий симптом с topic про лицо', () {
    final reply = cultAgent.answer(
      'сухость',
      lastUser: 'Давайте про лицо',
      recentUsers: ['Давайте про лицо'],
    );
    expect(reply.toLowerCase(), contains('лиц'));
    expect(reply.toLowerCase(), anyOf(contains('барьер'), contains('влаг')));
  });

  test('Не то сбрасывает и просит ориентир', () {
    final reply = cultAgent.answer('не то');
    expect(reply.toLowerCase(), contains('сбрас'));
    expect(reply.toLowerCase(), contains('лицо'));
  });

  test('Без уколов не предлагает инъекции', () {
    final reply = cultAgent.answer('Хочу освежить лицо без уколов');
    expect(reply.toLowerCase(), contains('без укол'));
    expect(reply.toLowerCase(), anyOf(contains('массаж'), contains('уход')));
    expect(reply.toLowerCase(), isNot(contains('ботулин')));
  });

  test('Запись вечером принимает слот', () {
    final reply = cultAgent.answer('Хочу записаться вечером');
    expect(reply.toLowerCase(), contains('вечер'));
    expect(reply.toLowerCase(), anyOf(contains('услуг'), contains('массаж')));
  });

  test('Агент знает врача Элара', () {
    final reply = cultAgent.answer('Кто такая Элара Торн?');
    expect(reply.toLowerCase(), contains('элара'));
    expect(reply.toLowerCase(), anyOf(contains('врач'), contains('инфуз'), contains('холист')));
  });

  test('Первый вариант после двух опций', () {
    final reply = cultAgent.answer(
      'первый',
      lastBot:
          'Нашла два близких варианта. Чем отличаются: Veil Peptide Serum — пептиды; Lumen Barrier Cream — барьер.',
    );
    expect(reply.toLowerCase(), contains('veil'));
  });

  test('Почему объясняет lastBot', () {
    final reply = cultAgent.answer(
      'почему',
      lastBot: 'Для сухости мягко заходит барьерный крем Lumen Barrier.',
    );
    expect(reply.toLowerCase(), contains('потому'));
    expect(reply.toLowerCase(), contains('барьер'));
  });

  test('Запиши на массаж ведёт к записи', () {
    final reply = cultAgent.answer('Запиши меня на массаж');
    expect(reply.toLowerCase(), anyOf(contains('массаж'), contains('услуг')));
    expect(reply.toLowerCase(), anyOf(contains('когда'), contains('утро'), contains('вечер')));
  });

  test('Сессия помнит без уколов', () {
    final reply = cultAgent.answer(
      'морщины на лбу',
      recentUsers: ['Хочу без уколов'],
      lastUser: 'Хочу без уколов',
    );
    expect(reply.toLowerCase(), contains('без укол'));
    expect(reply.toLowerCase(), isNot(contains('ботулин')));
  });

  test('Запиши на массаж вечером учитывает время', () {
    final turn = cultAgent.respond('Запиши меня на массаж вечером');
    expect(turn.reply.toLowerCase(), contains('массаж'));
    expect(turn.reply.toLowerCase(), contains('вечер'));
    expect(turn.pendingBooking, isNotNull);
    expect(turn.reply.toLowerCase(), contains('кнопк'));
  });

  test('Дорого после цены предлагает мягче', () {
    final reply = cultAgent.answer(
      'дорого',
      lastBot: 'По услуге «Микроигольчатый RF»: стоит 45 000 ₽.',
    );
    expect(reply.toLowerCase(), contains('бюджет'));
    expect(reply.toLowerCase(), anyOf(contains('уход'), contains('массаж'), contains('шоп')));
  });

  test('Составь план даёт шаги', () {
    final reply = cultAgent.answer('Составь план ухода');
    expect(reply.toLowerCase(), contains('1)'));
    expect(reply.toLowerCase(), anyOf(contains('2)'), contains('дом')));
  });

  test('Как проходит визит', () {
    final reply = cultAgent.answer('Как проходит визит?');
    expect(reply.toLowerCase(), contains('осмотр'));
    expect(reply.toLowerCase(), contains('ресепшен'));
  });

  test('Возьму это после рекомендации кладёт в корзину', () {
    final turn = cultAgent.respond(
      'возьму это',
      lastBot: 'Посмотрела Veil Peptide Serum. Стоит 12 500 ₽.',
    );
    expect(turn.reply.toLowerCase(), contains('veil'));
    expect(turn.reply.toLowerCase(), contains('корзин'));
    expect(turn.cartAdd, isNotNull);
    expect(turn.cartAdd!.name.toLowerCase(), contains('veil'));
  });

  test('Положи в корзину крем добавляет Lumen Barrier', () {
    final turn = cultAgent.respond('положи в корзину барьерный крем');
    expect(turn.cartAdd, isNotNull);
    expect(turn.cartAdd!.name.toLowerCase(), contains('barrier'));
    expect(turn.reply.toLowerCase(), contains('корзин'));
  });

  test('Трансфер из аэропорта создаёт заявку', () {
    final turn = cultAgent.respond('Нужен трансфер из аэропорта');
    expect(turn.transfer, isNotNull);
    expect(turn.transfer!.ready, isTrue);
    expect(turn.transfer!.from.toLowerCase(), contains('аэропорт'));
    expect(turn.reply.toLowerCase(), anyOf(contains('трансфер'), contains('администратор')));
  });

  test('Трансфер без адреса спрашивает откуда', () {
    final turn = cultAgent.respond('Вызови трансфер');
    expect(turn.transfer?.ready ?? false, isFalse);
    expect(
      turn.reply.toLowerCase(),
      anyOf(contains('откуда'), contains('адрес')),
    );
    expect(turn.reply.toLowerCase(), contains('трансфер'));
  });

  test('Хочу живого врача — handoff открывает чат', () {
    final turn = cultAgent.respond('Хочу живого врача');
    expect(turn.openChat, 'specialist');
    expect(turn.reply.toLowerCase(), anyOf(contains('врач'), contains('чат')));
  });

  test('Переведи на администратора открывает admin', () {
    final turn = cultAgent.respond('Переведи на администратора');
    expect(turn.openChat, 'admin');
    expect(turn.reply.toLowerCase(), contains('администратор'));
  });

  test('Кейсы до и после', () {
    final reply = cultAgent.answer('Покажи результаты до и после');
    expect(reply.toLowerCase(), contains('кейс'));
  });

  test('Сначала потом — последовательность', () {
    final reply = cultAgent.answer('Что сначала, что потом?');
    expect(reply.toLowerCase(), contains('сначала'));
    expect(reply.toLowerCase(), contains('потом'));
  });

  test('Короче сжимает lastBot', () {
    final reply = cultAgent.answer(
      'короче',
      lastBot:
          'По услуге «Микроигольчатый RF»: 45 000 ₽, занимает 1 ч. Длинный текст про кожу и консультацию.',
    );
    expect(reply.toLowerCase(), contains('короче'));
    expect(reply.toLowerCase(), contains('rf'));
  });

  test('Помогло — тёплый feedback', () {
    final reply = cultAgent.answer('помогло');
    expect(reply.toLowerCase(), anyOf(contains('рада'), contains('ясн')));
  });

  test('Аллергия в сессии добавляет caution', () {
    final reply = cultAgent.answer(
      'кожа сухая',
      lastUser: 'У меня аллергия на анестезию',
      recentUsers: ['У меня аллергия на анестезию'],
    );
    expect(reply.toLowerCase(), contains('аллерг'));
  });

  test('Запись в пятницу', () {
    final reply = cultAgent.answer('Хочу записаться в пятницу');
    expect(reply.toLowerCase(), contains('пятниц'));
    expect(reply.toLowerCase(), anyOf(contains('услуг'), contains('массаж')));
  });

  test('Напомни собирает якоря диалога', () {
    final reply = cultAgent.answer(
      'напомни о чём говорили',
      lastUser: 'Кожа сухая',
      lastBot: 'Попробуйте барьерный крем Lumen Barrier.',
      recentUsers: ['Хочу без уколов', 'Кожа сухая'],
    );
    expect(reply.toLowerCase(), contains('говорили'));
    expect(reply.toLowerCase(), anyOf(contains('сух'), contains('барьер'), contains('укол')));
  });

  test('Мужской профиль не предлагает женский массаж первым', () {
    final reply = cultAgent.answer(
      'скульптурный массаж лица',
      gender: ClientGender.man,
      localServices: [
        for (final item in services)
          if (item.audience.matches(ClientGender.man)) item,
      ],
    );
    expect(reply.toLowerCase(), isNot(contains('18 000')));
  });

  test('Помолодеть не путает с детскими процедурами', () {
    final reply = cultAgent.answer('хочу помолодеть');
    expect(reply.toLowerCase(), isNot(contains('18 лет')));
    expect(reply.toLowerCase(), isNot(contains('подрост')));
    expect(
      reply.toLowerCase(),
      anyOf(contains('помолодеть'), contains('свеж'), contains('массаж'), contains('уход')),
    );
  });

  test('Лицо после «не знаю с чего начать» не спрашивает снова зону', () {
    final first = cultAgent.answer('не знаю с чего начать');
    final reply = cultAgent.answer('лицо', lastBot: first, lastUser: 'не знаю с чего начать');
    expect(reply.toLowerCase(), contains('лиц'));
    expect(reply.toLowerCase(), isNot(contains('лицо или тело')));
  });

  test('Ты робот — отвечает про Миру', () {
    final reply = cultAgent.answer('ты робот?');
    expect(reply.toLowerCase(), contains('мира'));
    expect(
      reply.toLowerCase(),
      anyOf(contains('cult'), contains('культ'), contains('косметолог')),
    );
  });

  test('Подробнее дополняет lastBot', () {
    final reply = cultAgent.answer(
      'подробнее',
      lastBot: 'К близкой дате не берём тяжёлую реабилитацию. Чаще — уход или массаж.',
    );
    expect(reply.toLowerCase(), contains('дополн'));
    expect(reply.toLowerCase(), anyOf(contains('уход'), contains('массаж')));
  });

  test('Возраст после прыщей опирается на тему', () {
    final reply = cultAgent.answer(
      'мне 20',
      lastUser: 'прыщи',
      recentUsers: ['прыщи'],
    );
    expect(reply.toLowerCase(), anyOf(contains('воспален'), contains('уход'), contains('пилинг')));
  });

  test('После свадьбы «что можно» продолжает событие', () {
    final first = cultAgent.answer('для свадьбы через неделю');
    final reply = cultAgent.answer(
      'что можно',
      lastBot: first,
      lastUser: 'для свадьбы через неделю',
    );
    expect(reply.toLowerCase(), anyOf(contains('массаж'), contains('уход'), contains('glow')));
    expect(reply.toLowerCase(), isNot(contains('лицо, тело, энергия')));
  });

  test('English massage price hits catalog', () {
    final reply = cultAgent.answer('massage price');
    expect(reply.toLowerCase(), contains('массаж'));
    expect(reply, contains('₽'));
  });

  test('Для мамы предлагает сертификат или запись', () {
    final reply = cultAgent.answer('для мамы');
    expect(reply.toLowerCase(), anyOf(contains('сертификат'), contains('запис')));
  });

  test('Выпадение волос не уходит в generic', () {
    final reply = cultAgent.answer('выпадение волос');
    expect(reply.toLowerCase(), anyOf(contains('волос'), contains('мезо'), contains('голов')));
    expect(reply.toLowerCase(), isNot(contains('слышу вас — давайте сузим')));
  });

  test('VIP / консьерж отвечает по делу', () {
    final reply = cultAgent.answer('консьерж');
    expect(reply.toLowerCase(), anyOf(contains('vip'), contains('администратор'), contains('трансфер')));
  });

  test('ok после thanks не generic', () {
    final reply = cultAgent.answer(
      'ok',
      lastBot: 'И вам спасибо за доверие. Я рядом — можно продолжить голосом или текстом, без спешки.',
    );
    expect(
      reply.toLowerCase(),
      anyOf(
        contains('хорошо'),
        contains('ок'),
        contains('договор'),
        contains('приняла'),
        contains('слушаю'),
        contains('продолж'),
      ),
    );
    expect(reply.toLowerCase(), isNot(contains('слышу вас — давайте сузим')));
  });

  test('Что делать после опоздания', () {
    final reply = cultAgent.answer(
      'что делать',
      lastBot: 'Если опаздываете — напишите администратору в чат с запасом 10–15 минут.',
      lastUser: 'опоздаю на 15 минут',
    );
    expect(reply.toLowerCase(), contains('администратор'));
  });

  test('Что тогда после без уколов', () {
    final pref = cultAgent.answer('без уколов', lastUser: 'морщины');
    final reply = cultAgent.answer(
      'что тогда',
      lastBot: pref,
      lastUser: 'без уколов',
      recentUsers: ['морщины', 'без уколов'],
    );
    expect(reply.toLowerCase(), anyOf(contains('массаж'), contains('уход')));
  });

  test('Apple Pay FAQ', () {
    final reply = cultAgent.answer('apple pay');
    expect(reply.toLowerCase(), anyOf(contains('оплат'), contains('pay'), contains('карт')));
  });

  test('Отёк с буквой ё не падает в generic', () {
    final reply = cultAgent.answer('отёк');
    expect(reply.toLowerCase(), anyOf(contains('отёк'), contains('отек'), contains('массаж')));
    expect(reply.toLowerCase(), isNot(contains('слышу вас — давайте сузим')));
  });

  test('Каменное лицо — про натуральность', () {
    final reply = cultAgent.answer('лицо не будет каменным');
    expect(reply.toLowerCase(), anyOf(contains('натураль'), contains('мимик'), contains('массаж')));
  });

  test('Диабет уводит к врачу', () {
    final reply = cultAgent.answer('диабет');
    expect(reply.toLowerCase(), anyOf(contains('врач'), contains('чат'), contains('консультац')));
  });

  test('English parking hits FAQ', () {
    final reply = cultAgent.answer('parking');
    expect(reply.toLowerCase(), contains('парков'));
  });

  test('how to book на английском', () {
    final reply = cultAgent.answer('how to book');
    expect(reply.toLowerCase(), anyOf(contains('запис'), contains('+')));
  });

  test('Хочу к Эларе находит врача', () {
    final reply = cultAgent.answer('хочу к эларе');
    expect(reply.toLowerCase(), contains('элара'));
  });

  test('Носогубки не generic', () {
    final reply = cultAgent.answer('носогубки');
    expect(reply.toLowerCase(), contains('носогуб'));
    expect(reply.toLowerCase(), isNot(contains('слышу вас — давайте сузим')));
  });

  test('Что успеем после события вечером', () {
    final mid = cultAgent.answer('сегодня вечером событие');
    final reply = cultAgent.answer(
      'что успеем',
      lastBot: mid,
      lastUser: 'сегодня вечером событие',
    );
    expect(reply.toLowerCase(), anyOf(contains('массаж'), contains('уход'), contains('успеем')));
  });

  test('А сколько без контекста просит название', () {
    final reply = cultAgent.answer('а сколько');
    expect(reply.toLowerCase(), anyOf(contains('назовите'), contains('прайс')));
  });

  test('Старое приветствие бота обновляется на Миру', () async {
    SharedPreferences.setMockInitialValues({
      'cult-flutter':
          '{"threads":{"bot":[{"id":"old","from":"them","text":"Я ассистент CULT. Спросите про услуги."}]},"chatRead":{"bot":"old"},"cart":[],"appointments":[],"orders":[],"gifts":[],"favorites":[],"spent":0,"welcomeBonus":0,"welcomeGranted":false,"notices":{},"profileName":"","profilePhone":"","profileEmail":""}',
    });
    final store = ClinicStore();
    await store.load();
    final bot = store.threads['bot']!;
    expect(bot.length, 1);
    expect(bot.first.text, contains('Мира'));
    expect(
      bot.first.text.toLowerCase(),
      anyOf(
        contains('запис'),
        contains('корзин'),
        contains('трансфер'),
        contains('услуг'),
      ),
    );
  });

  test('Store: Мира кладёт товар в корзину по голосу', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    final before = store.cartCount;
    store.sendMessage('bot', 'Положи в корзину Veil Peptide');
    expect(store.cartCount, greaterThan(before));
    expect(store.agentLastCartName!.toLowerCase(), contains('veil'));
    expect(
      store.cart.any((c) => c.name.toLowerCase().contains('veil')),
      isTrue,
    );
  });

  test('Store: Мира вызывает трансфер в чат админа', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Нужен трансфер из аэропорта к 15:00');
    final admin = store.threads['admin'] ?? [];
    expect(admin.any((m) => m.text.toLowerCase().contains('трансфер')), isTrue);
    expect(admin.any((m) => m.text.toLowerCase().contains('аэропорт')), isTrue);
  });

  test('Не дублирует уточняющий вопрос подряд', () {
    const ask =
        'Слышу вас — давайте сузим без жёстких названий. Одного ориентира достаточно: лицо, тело, энергия или домашний уход.';
    final reply = cultAgent.answer('ну', lastBot: ask);
    expect(reply.toLowerCase(), contains('без повтора'));
    expect(reply.toLowerCase(), isNot(contains('одного ориентира достаточно')));
  });

  test('Кнопка Запись фиксирует визит из черновика Миры', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClinicStore();
    await store.load();
    store.sendMessage('bot', 'Запиши меня на скульптурный массаж вечером в пятницу');
    expect(store.agentBookingDraft, isNotNull);
    final before = store.upcoming.length;
    final line = store.confirmAgentBooking();
    expect(line, isNotNull);
    expect(store.agentBookingDraft, isNull);
    expect(store.upcoming.length, before + 1);
    expect(store.upcoming.first.service.toLowerCase(), contains('массаж'));
  });
}
