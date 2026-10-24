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

  test('Второй подбородок не уходит в мужской барбер-сценарий', () {
    final reply = cultAgent.answer('Хочу убрать второй подбородок без операции');
    expect(reply.toLowerCase(), anyOf(contains('овал'), contains('массаж'), contains('rf')));
    expect(reply.toLowerCase(), isNot(contains('барбер')));
  });

  test('Боюсь игл + лифтинг — безъинекционный путь, не только анестезия', () {
    final reply = cultAgent.answer('Боюсь иглы, есть безъинекционный лифтинг?');
    expect(reply.toLowerCase(), anyOf(contains('без укол'), contains('массаж'), contains('rf')));
    expect(reply.toLowerCase(), isNot(contains('аппликационной анестезией')));
  });

  test('Срок гиалуронки и ботокса — не прайс', () {
    final hya = cultAgent.answer('Через сколько рассосётся гиалуронка?');
    expect(hya.toLowerCase(), anyOf(contains('месяц'), contains('год')));
    expect(hya, isNot(contains('₽')));
    final botox = cultAgent.answer('На сколько хватает ботокса?');
    expect(botox.toLowerCase(), contains('месяц'));
    expect(botox, isNot(contains('₽')));
  });

  test('Загар после пилинга и спорт после пилинга', () {
    final sun = cultAgent.answer('Можно ли загорать после пилинга?');
    expect(sun.toLowerCase(), anyOf(contains('spf'), contains('загар'), contains('пауз')));
    final sport = cultAgent.answer('После пилинга можно спорт?');
    expect(sport.toLowerCase(), anyOf(contains('пилинг'), contains('спорт'), contains('пауз')));
  });

  test('Мира не заменяет врача', () {
    final reply = cultAgent.answer('Мира, ты заменишь врача?');
    expect(reply.toLowerCase(), contains('не заменя'));
  });

  test('Биоревитализация простыми словами', () {
    final reply = cultAgent.answer('Что такое биоревитализация простыми словами?');
    expect(reply.toLowerCase(), contains('биоревитал'));
    expect(reply.toLowerCase(), isNot(contains('скажите проще')));
  });

  test('Носогубки без филлера не уходят в губы', () {
    final reply = cultAgent.answer('Хочу убрать носогубки без филлера');
    expect(reply.toLowerCase(), contains('носогуб'));
    expect(reply.toLowerCase(), isNot(contains('уточк')));
  });

  test('RF при кардиостимуляторе — ограничение', () {
    final reply = cultAgent.answer('Можно ли делать RF при кардиостимуляторе?');
    expect(reply.toLowerCase(), anyOf(contains('кардио'), contains('запрет'), contains('огранич')));
    expect(reply.toLowerCase(), isNot(contains('меню «аппаратная»')));
  });

  test('Длительность скульптурного массажа из прайса', () {
    final reply = cultAgent.answer('Сколько длится сеанс скульптурного массажа?');
    expect(reply.toLowerCase(), contains('массаж'));
    expect(reply.toLowerCase(), anyOf(contains('мин'), contains('час')));
    expect(reply.toLowerCase(), isNot(contains('меню «')));
  });

  test('Плазмолифтинг и витилиго не generic', () {
    final plasma = cultAgent.answer('Делаете ли плазмолифтинг?');
    expect(plasma.toLowerCase(), anyOf(contains('плазмо'), contains('prp')));
    final vit = cultAgent.answer('У меня витилиго на лице');
    expect(vit.toLowerCase(), contains('витилиго'));
    expect(vit.toLowerCase(), isNot(contains('если сложно сформулировать')));
  });

  test('Биоревитализация отличается от филлера', () {
    final reply = cultAgent.answer('Чем отличается биоревитализация от филлера?');
    expect(reply.toLowerCase(), contains('филлер'));
    expect(reply.toLowerCase(), anyOf(contains('увлажн'), contains('объём'), contains('объем')));
  });

  test('SMAS и RF летом не уходят в меню-дамп', () {
    final smas = cultAgent.answer('Делаете ли SMAS-лифтинг?');
    expect(smas.toLowerCase(), contains('smas'));
    expect(smas.toLowerCase(), isNot(contains('меню «аппаратная»')));
    final rf = cultAgent.answer('Можно ли делать RF летом?');
    expect(rf.toLowerCase(), anyOf(contains('spf'), contains('лет'), contains('загар')));
  });

  test('HydraPure простыми словами и нос без операции', () {
    final hp = cultAgent.answer('Что такое HydraPure простыми словами?');
    expect(hp.toLowerCase(), contains('hydrapure'));
    expect(hp.toLowerCase(), isNot(contains('скажите проще')));
    final nose = cultAgent.answer('Хочу сузить нос без операции');
    expect(nose.toLowerCase(), anyOf(contains('нос'), contains('консульт'), contains('операц')));
    expect(nose.toLowerCase(), isNot(contains('если сложно сформулировать')));
  });

  test('Мигрень + ботокс — не постпроцедурная головная боль', () {
    final reply = cultAgent.answer('У меня мигрени часто — ботокс поможет?');
    expect(reply.toLowerCase(), contains('мигрен'));
    expect(reply.toLowerCase(), isNot(contains('после ботулинотерапии бывает')));
  });

  test('Ребёнка с собой на процедуру — не подростковый протокол', () {
    final reply = cultAgent.answer('Можно ли брать ребёнка с собой на процедуру?');
    expect(reply.toLowerCase(), anyOf(contains('кабинет'), contains('не берут'), contains('снаружи')));
    expect(reply.toLowerCase(), isNot(contains('согласие родителя')));
  });

  test('Веки без операции и руль после капельницы', () {
    final lids = cultAgent.answer('Хочу подтянуть веки без операции');
    expect(lids.toLowerCase(), contains('век'));
    expect(lids.toLowerCase(), isNot(contains('если сложно сформулировать')));
    final drive = cultAgent.answer('После капельницы можно за руль?');
    expect(drive.toLowerCase(), anyOf(contains('руль'), contains('такси'), contains('самочувств')));
    expect(drive.toLowerCase(), isNot(contains('меню «инфузии»')));
  });

  test('Перелёт ≠ лето; милиумы ≠ мили лояльности', () {
    final flight = cultAgent.answer('Лицо отекло после перелёта — что поможет быстро?');
    expect(flight.toLowerCase(), anyOf(contains('перелёт'), contains('перелет'), contains('массаж')));
    expect(flight.toLowerCase(), isNot(contains('летом бережём')));
    final milia = cultAgent.answer('Делаете ли удаление милиумов?');
    expect(milia.toLowerCase(), contains('милиум'));
    expect(milia.toLowerCase(), isNot(contains('кэшбек')));
  });

  test('Кисетные морщины не уходят в губы-уточку', () {
    final reply = cultAgent.answer('Хочу убрать кисетные морщины над губой');
    expect(reply.toLowerCase(), contains('кисет'));
    expect(reply.toLowerCase(), isNot(contains('уточк')));
  });

  test('Единицы ботокса на лоб — не прайс', () {
    final reply = cultAgent.answer('Сколько единиц ботокса нужно на лоб?');
    expect(reply.toLowerCase(), contains('единиц'));
    expect(reply, isNot(contains('₽')));
  });

  test('Veil Peptide в корзину не путает с Neuro-Regen', () {
    final turn = cultAgent.respond('Положи Veil Peptide Serum в корзину');
    expect(turn.cartAdd, isNotNull);
    expect(turn.cartAdd!.name.toLowerCase(), contains('veil'));
    expect(turn.cartAdd!.name.toLowerCase(), isNot(contains('neuro')));
  });

  test('ГВ аббревиатура и блеск через час не часы работы', () {
    final gv = cultAgent.answer('Можно ли делать массаж при ГВ?');
    expect(gv.toLowerCase(), anyOf(contains('грудн'), contains('вскармл'), contains('врач')));
    expect(gv.toLowerCase(), isNot(contains('мануальный лифтинг контура')));
    final shine = cultAgent.answer('Кожа блестит через час после умывания');
    expect(shine.toLowerCase(), anyOf(contains('блеск'), contains('т-зон'), contains('барьер')));
    expect(shine.toLowerCase(), isNot(contains('9:00')));
  });

  test('SMAS простыми словами и RF при зубных имплантах', () {
    final smas = cultAgent.answer('Что такое SMAS простыми словами?');
    expect(smas.toLowerCase(), contains('smas'));
    expect(smas.toLowerCase(), isNot(contains('скажите проще')));
    final rf = cultAgent.answer('Можно ли делать RF если стоят металлические импланты в зубах?');
    expect(rf.toLowerCase(), anyOf(contains('зуб'), contains('металл'), contains('имплант')));
    expect(rf.toLowerCase(), isNot(contains('меню «аппаратная»')));
  });

  test('Похмелье на капельницу не меню инфузий', () {
    final reply = cultAgent.answer('Можно ли прийти на капельницу с похмелья?');
    expect(reply.toLowerCase(), contains('похмел'));
    expect(reply.toLowerCase(), isNot(contains('меню «инфузии»')));
  });

  test('Гиалуронидаза не путается со вторым подбородком', () {
    final reply = cultAgent.answer('Хочу убрать второй подбородок гиалуронидазой');
    expect(reply.toLowerCase(), contains('гиалуронидаз'));
    expect(reply.toLowerCase(), isNot(contains('скульптурный массаж лица, при необходимости')));
  });

  test('Программа для невест и демодекс не generic', () {
    final bride = cultAgent.answer('Есть ли программа для невест?');
    expect(bride.toLowerCase(), anyOf(contains('невест'), contains('свадьб'), contains('дат')));
    expect(bride.toLowerCase(), isNot(contains('если сложно сформулировать')));
    final dem = cultAgent.answer('У меня демодекс — что можно?');
    expect(dem.toLowerCase(), contains('демодекс'));
  });

  test('Immunity простыми словами и золотые нити + RF', () {
    final imm = cultAgent.answer('Что такое Immunity простыми словами?');
    expect(imm.toLowerCase(), contains('immunity'));
    expect(imm.toLowerCase(), isNot(contains('скажите проще')));
    final threads = cultAgent.answer('Можно ли делать RF если есть золотые нити?');
    expect(threads.toLowerCase(), anyOf(contains('нит'), contains('допуск'), contains('врач')));
    expect(threads.toLowerCase(), isNot(contains('меню «аппаратная»')));
  });

  test('Что взять на капельницу не сужает выбор кожи', () {
    final reply = cultAgent.answer('Что взять с собой на капельницу?');
    expect(reply.toLowerCase(), anyOf(contains('капель'), contains('документ'), contains('вен')));
    expect(reply.toLowerCase(), isNot(contains('давайте сузим вместе')));
  });

  test('Носослёзная борозда не уходит в сужение носа', () {
    final reply = cultAgent.answer('Хочу убрать носослёзную борозду без филлера');
    expect(reply.toLowerCase(), anyOf(contains('носослёз'), contains('носослез'), contains('борозд')));
    expect(reply.toLowerCase(), isNot(contains('сузить нос')));
  });

  test('Плацентарная терапия и папилломы не generic', () {
    final plac = cultAgent.answer('Делаете ли плацентарную терапию?');
    expect(plac.toLowerCase(), contains('плацентар'));
    expect(plac.toLowerCase(), isNot(contains('меню «прайс»')));
    final pap = cultAgent.answer('Делаете ли удаление папиллом?');
    expect(pap.toLowerCase(), contains('папиллом'));
    expect(pap.toLowerCase(), isNot(contains('если сложно сформулировать')));
  });

  test('RF при эндометриозе и страх ожога RF', () {
    final endo = cultAgent.answer('Можно ли делать RF при эндометриозе?');
    expect(endo.toLowerCase(), anyOf(contains('эндометр'), contains('допуск'), contains('врач')));
    expect(endo.toLowerCase(), isNot(contains('меню «аппаратная»')));
    final burn = cultAgent.answer('Боюсь что RF сожжёт кожу');
    expect(burn.toLowerCase(), anyOf(contains('сжига'), contains('мощност'), contains('врач')));
    expect(burn.toLowerCase(), isNot(contains('кислоты или ретинола')));
  });

  test('Вино после ботокса не прайс; Cellular Catalyst простыми словами', () {
    final wine = cultAgent.answer('Сколько нельзя пить вино после ботокса?');
    expect(wine.toLowerCase(), anyOf(contains('алкогол'), contains('вино'), contains('сутк')));
    expect(wine, isNot(contains('₽')));
    final cat = cultAgent.answer('Что такое Cellular Catalyst простыми словами?');
    expect(cat.toLowerCase(), contains('catalyst'));
    expect(cat.toLowerCase(), isNot(contains('скажите проще')));
  });

  test('Пилинг+биоревитал и умывание после чистки', () {
    final combo = cultAgent.answer('Можно ли совместить пилинг и биоревитализацию?');
    expect(combo.toLowerCase(), anyOf(contains('биоревитал'), contains('пилинг')));
    expect(combo.toLowerCase(), isNot(contains('без сауны и бассейна пару дней')));
    final wash = cultAgent.answer('После чистки можно умываться водой?');
    expect(wash.toLowerCase(), anyOf(contains('умыв'), contains('вод'), contains('барьер')));
    expect(wash.toLowerCase(), isNot(contains('если сложно сформулировать')));
  });

  test('ОРВИ+ботокс и капельница после операции', () {
    final orvi = cultAgent.answer('Можно ли делать ботокс при ОРВИ без температуры?');
    expect(orvi.toLowerCase(), anyOf(contains('орви'), contains('простуд'), contains('отлож')));
    expect(orvi.toLowerCase(), isNot(contains('массаж иногда допустим')));
    final op = cultAgent.answer('Можно ли капельницу если недавно была операция?');
    expect(op.toLowerCase(), anyOf(contains('операц'), contains('допуск'), contains('врач')));
    expect(op.toLowerCase(), isNot(contains('меню «инфузии»')));
  });

  test('Гусиные лапки без ботокса и массаж после ботокса', () {
    final crow = cultAgent.answer('Хочу убрать гусиные лапки без ботокса');
    expect(crow.toLowerCase(), anyOf(contains('гусин'), contains('лапк'), contains('глаз')));
    expect(crow.toLowerCase(), isNot(contains('инъекции снимаем со стола')));
    final mass = cultAgent.answer('После ботокса можно делать массаж лица?');
    expect(mass.toLowerCase(), anyOf(contains('бот'), contains('массаж'), contains('отклад')));
    expect(mass.toLowerCase(), isNot(contains('мануальный лифтинг контура')));
  });

  test('Брови после ботокса ≠ перманент; Mitochondrial Fuel простыми словами', () {
    final brows = cultAgent.answer('После ботокса брови разной высоты — норма?');
    expect(brows.toLowerCase(), anyOf(contains('бров'), contains('асимметр'), contains('бот')));
    expect(brows.toLowerCase(), isNot(contains('перманентн')));
    final fuel = cultAgent.answer('Что такое Mitochondrial Fuel простыми словами?');
    expect(fuel.toLowerCase(), contains('mitochondrial'));
    expect(fuel.toLowerCase(), isNot(contains('скажите проще')));
    expect(fuel, isNot(contains('₽')));
  });

  test('Подготовка к массажу и изотретиноин+пилинг', () {
    final prep = cultAgent.answer('Как подготовиться к скульптурному массажу?');
    expect(prep.toLowerCase(), contains('массаж'));
    expect(prep.toLowerCase(), isNot(contains('меню «услуги»')));
    final iso = cultAgent.answer('Можно ли делать пилинг если пью изотретиноин?');
    expect(iso.toLowerCase(), contains('изотретиноин'));
    expect(iso.toLowerCase(), isNot(contains('если откликается — можем записаться')));
  });

  test('Продление сертификата и запись на имя подруги', () {
    final cert = cultAgent.answer('Хочу продлить сертификат');
    expect(cert.toLowerCase(), anyOf(contains('продл'), contains('администратор'), contains('срок')));
    expect(cert.toLowerCase(), isNot(contains('купить сертификат')));
    final friend = cultAgent.answer('Можно ли записаться на имя подруги?');
    expect(friend.toLowerCase(), anyOf(contains('администратор'), contains('другого'), contains('подруг'), contains('гост')));
  });

  test('Капельница при анемии и нитевой лифтинг ≠ лифт здания', () {
    final anemia = cultAgent.answer('Можно ли капельницу при анемии?');
    expect(anemia.toLowerCase(), contains('анеми'));
    expect(anemia.toLowerCase(), isNot(contains('меню «инфузии»')));
    final threads = cultAgent.answer('Делаете ли нитевой лифтинг?');
    expect(threads.toLowerCase(), anyOf(contains('нитев'), contains('нит')));
    expect(threads.toLowerCase(), isNot(contains('черноморск')));
  });

  test('Поцелуи после ботокса ≠ филлер; Gluta-Pure простыми словами', () {
    final kiss = cultAgent.answer('После ботокса можно целоваться?');
    expect(kiss.toLowerCase(), anyOf(contains('бот'), contains('поцел')));
    expect(kiss.toLowerCase(), isNot(contains('филлера в губы')));
    final gluta = cultAgent.answer('Что такое Liposomal Gluta-Pure простыми словами?');
    expect(gluta.toLowerCase(), anyOf(contains('gluta'), contains('глута')));
    expect(gluta.toLowerCase(), isNot(contains('скажите проще')));
  });

  test('Синие губы после филлера и перед ботоксом', () {
    final blue = cultAgent.answer('После филлера губы синие — это норма?');
    expect(blue.toLowerCase(), anyOf(contains('синев'), contains('гиалуронидаз'), contains('врач')));
    expect(blue.toLowerCase(), isNot(contains('подбирает врач после осмотра')));
    final prep = cultAgent.answer('Что нельзя делать перед ботоксом?');
    expect(prep.toLowerCase(), anyOf(contains('перед'), contains('алкогол'), contains('накануне')));
  });

  test('Отёк после массажа и биоревитал рук', () {
    final edema = cultAgent.answer('Что делать если после массажа лицо отекло?');
    expect(edema.toLowerCase(), contains('массаж'));
    expect(edema.toLowerCase(), isNot(contains('после филлера или уколов')));
    final hands = cultAgent.answer('Делаете ли биоревитализацию рук?');
    expect(hands.toLowerCase(), anyOf(contains('рук'), contains('кист')));
    expect(hands.toLowerCase(), isNot(contains('давайте проще')));
  });

  test('HydraPure+капельница и чистка+ботокс', () {
    final hydra = cultAgent.answer('Можно ли совместить HydraPure и капельницу?');
    expect(hydra.toLowerCase(), anyOf(contains('hydrapure'), contains('капель')));
    expect(hydra.toLowerCase(), isNot(contains('скажите пару процедур')));
    final clean = cultAgent.answer('Можно ли совместить чистку и ботокс?');
    expect(clean.toLowerCase(), anyOf(contains('чистк'), contains('бот')));
    expect(clean.toLowerCase(), isNot(contains('скажите пару процедур')));
  });

  test('Вегетарианство и астма + капельница не меню инфузий', () {
    final veg = cultAgent.answer('Можно ли капельницу если я вегетарианка?');
    expect(veg.toLowerCase(), contains('вегетариан'));
    expect(veg.toLowerCase(), isNot(contains('меню «инфузии»')));
    final asthma = cultAgent.answer('У меня астма — капельницу можно?');
    expect(asthma.toLowerCase(), contains('астм'));
    expect(asthma.toLowerCase(), isNot(contains('меню «инфузии»')));
  });

  test('Опущенное веко после ботокса и рыбий жир', () {
    final lid = cultAgent.answer('Что делать если после ботокса опущено веко?');
    expect(lid.toLowerCase(), anyOf(contains('веко'), contains('птоз'), contains('врач')));
    expect(lid.toLowerCase(), isNot(contains('подбирает врач после осмотра')));
    final oil = cultAgent.answer('Можно ли делать ботокс если пью рыбий жир?');
    expect(oil.toLowerCase(), anyOf(contains('рыбий'), contains('омега'), contains('синяк')));
  });

  test('Aura Mist простыми словами и сертификат на английском', () {
    final aura = cultAgent.answer('Что такое Aura Mineral Mist простыми словами?');
    expect(aura.toLowerCase(), contains('aura'));
    expect(aura.toLowerCase(), isNot(contains('скажите проще')));
    final cert = cultAgent.answer('Хочу подарочный сертификат на английском');
    expect(cert.toLowerCase(), anyOf(contains('сертификат'), contains('английск'), contains('админ')));
    expect(cert.toLowerCase(), isNot(contains('i can help in simple english')));
  });

  test('Массаж+ботокс один день и подушка после филлера', () {
    final combo = cultAgent.answer('Можно ли совместить массаж и ботокс в один день?');
    expect(combo.toLowerCase(), anyOf(contains('массаж'), contains('бот')));
    expect(combo.toLowerCase(), isNot(contains('скажите пару процедур')));
    final pillow = cultAgent.answer('Сколько нельзя спать лицом в подушку после филлера?');
    expect(pillow.toLowerCase(), anyOf(contains('филлер'), contains('подуш'), contains('лицом')));
    expect(pillow.toLowerCase(), isNot(contains('на боку спать обычно можно')));
  });

  test('После RF пилинг и капельница+баня', () {
    final rf = cultAgent.answer('После RF можно делать пилинг?');
    expect(rf.toLowerCase(), anyOf(contains('rf'), contains('пилинг'), contains('пауз')));
    expect(rf.toLowerCase(), isNot(contains('химический пилинг l3')));
    final bath = cultAgent.answer('После капельницы можно в баню в тот же день?');
    expect(bath.toLowerCase(), anyOf(contains('капель'), contains('бан'), contains('саун')));
  });

  test('Гастрит/эпилепсия + капельница не меню инфузий', () {
    final gas = cultAgent.answer('Можно ли капельницу при гастрите?');
    expect(gas.toLowerCase(), contains('гастрит'));
    expect(gas.toLowerCase(), isNot(contains('меню «инфузии»')));
    final ep = cultAgent.answer('У меня эпилепсия — капельницу можно?');
    expect(ep.toLowerCase(), contains('эпилепс'));
    expect(ep.toLowerCase(), isNot(contains('меню «инфузии»')));
  });

  test('Блеск на лбу и пора на биоревитализацию', () {
    final shine = cultAgent.answer('Кожа блестит только на лбу');
    expect(shine.toLowerCase(), anyOf(contains('блеск'), contains('т-зон'), contains('лбу'), contains('себум')));
    expect(shine.toLowerCase(), isNot(contains('не уверена')));
    final bio = cultAgent.answer('Как понять что пора на биоревитализацию?');
    expect(bio.toLowerCase(), contains('биоревитал'));
    expect(bio.toLowerCase(), isNot(contains('меню «инъекции»')));
  });

  test('RF+спираль и NAD+ Micro-Patch простыми словами', () {
    final iud = cultAgent.answer('Можно ли делать RF если стоит спираль?');
    expect(iud.toLowerCase(), anyOf(contains('спирал'), contains('вмс'), contains('допуск')));
    expect(iud.toLowerCase(), isNot(contains('меню «аппаратная»')));
    final patch = cultAgent.answer('Что такое NAD+ Micro-Patch простыми словами?');
    expect(patch.toLowerCase(), anyOf(contains('патч'), contains('patch'), contains('пластыр')));
    expect(patch.toLowerCase(), isNot(contains('капельница из блока')));
  });

  test('Купить крем без консультации не кладёт в корзину; барбер-цена', () {
    final turn = cultAgent.respond('Можно ли купить крем без консультации?');
    expect(turn.cartAdd, isNull);
    expect(turn.reply.toLowerCase(), anyOf(contains('без процедур'), contains('шоп'), contains('корзин')));
    final barber = cultAgent.answer('Сколько стоит барбер-массаж лица?');
    expect(barber, contains('12'));
    expect(barber.toLowerCase(), contains('барбер'));
  });

  test('Розацеа+Beauty Glow и очки после ботокса', () {
    final ros = cultAgent.answer('У меня розацеа — капельницу Beauty & Glow можно?');
    expect(ros.toLowerCase(), anyOf(contains('розацеа'), contains('beauty'), contains('капель')));
    expect(ros.toLowerCase(), isNot(contains('сначала крем из шопа')));
    final glasses = cultAgent.answer('После ботокса можно носить очки?');
    expect(glasses.toLowerCase(), anyOf(contains('очк'), contains('бот')));
    expect(glasses.toLowerCase(), isNot(contains('подбирает врач после осмотра')));
  });

  test('Щитовидка/гепатит + капельница; RF+варикоз', () {
    final thyroid = cultAgent.answer('Можно ли капельницу при заболеваниях щитовидки?');
    expect(thyroid.toLowerCase(), contains('щитовид'));
    expect(thyroid.toLowerCase(), isNot(contains('меню «инфузии»')));
    final hep = cultAgent.answer('У меня гепатит в анамнезе — капельницу можно?');
    expect(hep.toLowerCase(), contains('гепатит'));
    expect(hep.toLowerCase(), isNot(contains('меню «инфузии»')));
    final varicose = cultAgent.answer('Можно ли делать RF при варикозе ног?');
    expect(varicose.toLowerCase(), contains('варикоз'));
    expect(varicose.toLowerCase(), isNot(contains('меню «аппаратная»')));
  });

  test('Пакет массажей, мужской RF цена, SMAS+перелёт', () {
    final pack = cultAgent.answer('Есть ли пакет из 5 массажей со скидкой?');
    expect(pack.toLowerCase(), anyOf(contains('пакет'), contains('курс'), contains('лояльн')));
    expect(pack.toLowerCase(), isNot(contains('меню «услуги»')));
    final menRf = cultAgent.answer('Сколько стоит мужской RF-лифтинг?');
    expect(menRf, contains('42'));
    expect(menRf.toLowerCase(), contains('rf'));
    final flight = cultAgent.answer('После SMAS можно лететь на следующий день?');
    expect(flight.toLowerCase(), anyOf(contains('перел'), contains('рейс'), contains('запас')));
    expect(flight.toLowerCase(), isNot(contains('массаж посильнее')));
  });

  test('Каменное лицо, RF горячее, Circadian, HydraPure сауна', () {
    final stone = cultAgent.answer('Что делать если после ботокса лицо «каменное»?');
    expect(stone.toLowerCase(), anyOf(contains('камен'), contains('мимик'), contains('чат')));
    expect(stone.toLowerCase(), isNot(contains('натуральный результат')));
    final hot = cultAgent.answer('После RF лицо горячее вечером — норма?');
    expect(hot.toLowerCase(), anyOf(contains('горяч'), contains('тёпл'), contains('тепл'), contains('норм')));
    expect(hot.toLowerCase(), isNot(contains('я рядом')));
    final light = cultAgent.answer('Что такое Circadian Light Panel простыми словами?');
    expect(light.toLowerCase(), anyOf(contains('circadian'), contains('панель'), contains('свет')));
    expect(light.toLowerCase(), isNot(contains('скажу проще')));
    final sauna = cultAgent.answer('Сколько нельзя сауну после HydraPure?');
    expect(sauna.toLowerCase(), contains('hydrapure'));
    expect(sauna.toLowerCase(), anyOf(contains('саун'), contains('пауз')));
  });

  test('Диабет/почки/ВИЧ + капельница/эстетика', () {
    final diabetes = cultAgent.answer('У меня диабет 2 типа — капельницу можно?');
    expect(diabetes.toLowerCase(), contains('диабет'));
    expect(diabetes.toLowerCase(), isNot(contains('меню «инфузии»')));
    final kidney = cultAgent.answer('Можно ли капельницу при почечной недостаточности?');
    expect(kidney.toLowerCase(), anyOf(contains('почечн'), contains('почк')));
    expect(kidney.toLowerCase(), isNot(contains('меню «инфузии»')));
    final hiv = cultAgent.answer('У меня ВИЧ — эстетику можно?');
    expect(hiv.toLowerCase(), contains('вич'));
    expect(hiv.toLowerCase(), isNot(contains('не уверена')));
  });

  test('Антидепрессанты+ботокс, асимметрия губ, SMAS отёк', () {
    final ad = cultAgent.answer('Можно ли делать ботокс если пью антидепрессанты?');
    expect(ad.toLowerCase(), contains('антидепресс'));
    expect(ad.toLowerCase(), isNot(contains('подбирает врач после осмотра')));
    final lips = cultAgent.answer('Что делать если после филлера губы сильно асимметричны?');
    expect(lips.toLowerCase(), anyOf(contains('филлер'), contains('губ')));
    expect(lips.toLowerCase(), isNot(contains('ботулин')));
    final edema = cultAgent.answer('После SMAS лицо отекло на третий день — норма?');
    expect(edema.toLowerCase(), anyOf(contains('отёк'), contains('отек'), contains('smas')));
    expect(edema.toLowerCase(), isNot(contains('массаж посильнее')));
  });

  test('Барбер+RF цена, отмена записи, синяки к съёмке', () {
    final combo = cultAgent.answer('Сколько стоит мужской барбер-массаж и RF вместе?');
    expect(combo, contains('12'));
    expect(combo, contains('42'));
    final cancel = cultAgent.answer('Хочу отменить запись голосом на завтра');
    expect(cancel.toLowerCase(), anyOf(contains('отмен'), contains('моих записей'), contains('перенес')));
    expect(cancel.toLowerCase(), isNot(contains('beauty & glow')));
    final bruise = cultAgent.answer('Боюсь синяков после мезо к важной фотосессии');
    expect(bruise.toLowerCase(), anyOf(contains('съёмк'), contains('съемк'), contains('фотосесс'), contains('запас')));
    expect(bruise.toLowerCase(), isNot(contains('анестезией')));
  });

  test('Тромбоз/онкология + капельница; коррекция ушей', () {
    final throm = cultAgent.answer('У меня тромбоз в анамнезе — капельницу можно?');
    expect(throm.toLowerCase(), contains('тромбоз'));
    expect(throm.toLowerCase(), isNot(contains('меню «инфузии»')));
    final onco = cultAgent.answer('Можно ли капельницу при онкологии в ремиссии?');
    expect(onco.toLowerCase(), contains('онколог'));
    expect(onco.toLowerCase(), isNot(contains('меню «инфузии»')));
    final ears = cultAgent.answer('Делаете ли коррекцию ушей?');
    expect(ears.toLowerCase(), anyOf(contains('уш'), contains('не делаем'), contains('отопласт')));
    expect(ears.toLowerCase(), isNot(contains('давайте проще')));
  });

  test('Вино после NAD+, пигмент без лазера, SMAS с собой', () {
    final wine = cultAgent.answer('После капельницы NAD+ можно пить вино вечером?');
    expect(wine.toLowerCase(), anyOf(contains('после'), contains('вечером'), contains('алкогол'), contains('вино')));
    expect(wine.toLowerCase(), isNot(contains('накануне')));
    final pigment = cultAgent.answer('Хочу убрать пигмент кремом без лазера');
    expect(pigment.toLowerCase(), anyOf(contains('пигмент'), contains('spf'), contains('барьер')));
    expect(pigment.toLowerCase(), isNot(contains('без аппаратной — тоже рабочий')));
    final smas = cultAgent.answer('Что взять с собой на SMAS?');
    expect(smas.toLowerCase(), contains('smas'));
    expect(smas.toLowerCase(), isNot(contains('на первый визит')));
  });

  test('Мигрень+ботокс страх, пляж после массажа, без отдушки', () {
    final mig = cultAgent.answer('Боюсь мигрени после ботокса в лоб');
    expect(mig.toLowerCase(), anyOf(contains('мигрен'), contains('головн'), contains('лоб')));
    expect(mig.toLowerCase(), isNot(contains('анестезией')));
    final beach = cultAgent.answer('После массажа можно сразу на пляж?');
    expect(beach.toLowerCase(), contains('пляж'));
    expect(beach.toLowerCase(), isNot(contains('ужин')));
    final scent = cultAgent.answer('Хочу домашний уход без отдушки для чувствительной кожи');
    expect(scent.toLowerCase(), anyOf(contains('отдуш'), contains('lumen'), contains('барьер')));
  });

  test('Аутоиммунное+IV, корочки≠очки, астма+RF', () {
    final auto = cultAgent.answer('Можно ли капельницу при аутоиммунном заболевании?');
    expect(auto.toLowerCase(), contains('аутоиммун'));
    expect(auto.toLowerCase(), isNot(contains('силы на нуле')));
    final crust = cultAgent.answer('Что делать если после RF появились корочки?');
    expect(crust.toLowerCase(), anyOf(contains('короч'), contains('rf'), contains('барьер')));
    expect(crust.toLowerCase(), isNot(contains('оправой')));
    expect(crust.toLowerCase(), isNot(contains('ботулин')));
    final asthma = cultAgent.answer('У меня астма — RF можно?');
    expect(asthma.toLowerCase(), anyOf(contains('rf'), contains('астм')));
    expect(asthma.toLowerCase(), isNot(contains('капельницу не назначаю')));
  });

  test('IPL+ретинол, филлер губы частота, макияж после чистки', () {
    final ret = cultAgent.answer('После IPL можно наносить ретинол через пять дней?');
    expect(ret.toLowerCase(), contains('ipl'));
    expect(ret.toLowerCase(), anyOf(contains('ретинол'), contains('пауз')));
    final lips = cultAgent.answer('Как часто можно колоть филлер в губы?');
    expect(lips.toLowerCase(), contains('филлер'));
    expect(lips.toLowerCase(), isNot(contains('ботулин обычно не колют')));
    final makeup = cultAgent.answer('После чистки можно красить лицо вечером?');
    expect(makeup.toLowerCase(), anyOf(contains('чистк'), contains('макияж'), contains('лёгк'), contains('легк')));
    expect(makeup.toLowerCase(), isNot(contains('я рядом')));
  });

  test('SMAS+ботокс, поцелуи после мезо, мужской без блеска', () {
    final combo = cultAgent.answer('Можно ли совместить SMAS и ботокс через месяц?');
    expect(combo.toLowerCase(), anyOf(contains('smas'), contains('ботулин')));
    expect(combo.toLowerCase(), isNot(contains('скажите пару процедур')));
    final kiss = cultAgent.answer('После биоревитализации можно целоваться в тот же день?');
    expect(kiss.toLowerCase(), anyOf(contains('поцел'), contains('целов'), contains('папул')));
    final men = cultAgent.answer('Хочу спокойный уход для мужчины без блеска');
    expect(men.toLowerCase(), anyOf(contains('блеск'), contains('барбер'), contains('мат')));
    expect(men.toLowerCase(), isNot(contains('кому подбираем')));
  });

  test('Печень+IV, блефаропластика, аспирин+ботокс', () {
    final liver = cultAgent.answer('Можно ли капельницу при заболеваниях печени?');
    expect(liver.toLowerCase(), contains('печен'));
    expect(liver.toLowerCase(), isNot(contains('меню «инфузии»')));
    final bleph = cultAgent.answer('Делаете ли блефаропластику?');
    expect(bleph.toLowerCase(), anyOf(contains('блефаропласт'), contains('не делаем'), contains('хирург')));
    expect(bleph.toLowerCase(), isNot(contains('давайте проще')));
    final asp = cultAgent.answer('Можно ли делать ботокс если пью аспирин?');
    expect(asp.toLowerCase(), contains('аспирин'));
    expect(asp.toLowerCase(), isNot(contains('подбирает врач после осмотра')));
  });

  test('Глаз выше, Beauty+массаж, подарок коллеге-женщине', () {
    final eye = cultAgent.answer('Что делать если после ботокса один глаз выше другого?');
    expect(eye.toLowerCase(), anyOf(contains('выше'), contains('асимметр'), contains('бров')));
    expect(eye.toLowerCase(), isNot(contains('мезотерап')));
    final glow = cultAgent.answer('Можно ли совместить Beauty & Glow и массаж в один день?');
    expect(glow.toLowerCase(), anyOf(contains('массаж'), contains('beauty'), contains('капель')));
    expect(glow.toLowerCase(), isNot(contains('две капельницы')));
    final gift = cultAgent.answer('Хочу подарок коллеге-женщине до 15000');
    expect(gift.toLowerCase(), contains('женщин'));
    expect(gift.toLowerCase(), isNot(contains('барбер')));
  });

  test('Витамин C после пилинга, йод+IV, сон на животе', () {
    final vit = cultAgent.answer('После пилинга можно наносить сыворотку с витамином C через неделю?');
    expect(vit.toLowerCase(), anyOf(contains('витамин'), contains('пилинг'), contains('пауз')));
    expect(vit.toLowerCase(), isNot(contains('под дату')));
    final iodine = cultAgent.answer('У меня аллергия на йод — капельницу можно?');
    expect(iodine.toLowerCase(), contains('йод'));
    expect(iodine.toLowerCase(), isNot(contains('металлы или косметику')));
    final sleep = cultAgent.answer('После ботокса можно спать на животе через два дня?');
    expect(sleep.toLowerCase(), contains('живот'));
    expect(sleep.toLowerCase(), isNot(contains('на боку спать обычно можно ближе к вечеру')));
  });

  test('Ринопластика, увеличение груди, ферритин+IV', () {
    final rhino = cultAgent.answer('Делаете ли ринопластику?');
    expect(rhino.toLowerCase(), anyOf(contains('ринопласт'), contains('не делаем'), contains('хирург')));
    expect(rhino.toLowerCase(), isNot(contains('давайте проще')));
    final breast = cultAgent.answer('Делаете ли увеличение груди?');
    expect(breast.toLowerCase(), anyOf(contains('груди'), contains('маммопласт'), contains('не делаем')));
    expect(breast.toLowerCase(), isNot(contains('если сложно сформулировать')));
    final ferr = cultAgent.answer('У меня низкий ферритин — капельницу можно?');
    expect(ferr.toLowerCase(), contains('ферритин'));
    expect(ferr.toLowerCase(), isNot(contains('hydrapure')));
  });

  test('Инфаркт+RF, желчнокаменная, ботокс+пилинг через 2 нед', () {
    final infarct = cultAgent.answer('Можно ли делать RF если недавно был инфаркт?');
    expect(infarct.toLowerCase(), anyOf(contains('инфаркт'), contains('кардиолог'), contains('сердечн')));
    expect(infarct.toLowerCase(), isNot(contains('слышу много нюансов')));
    final gall = cultAgent.answer('Можно ли капельницу при желчнокаменной болезни?');
    expect(gall.toLowerCase(), contains('желч'));
    expect(gall.toLowerCase(), isNot(contains('hydrapure')));
    final peel = cultAgent.answer('После ботокса можно делать пилинг через две недели?');
    expect(peel.toLowerCase(), anyOf(contains('ботулин'), contains('пилинг'), contains('недел')));
    expect(peel.toLowerCase(), isNot(contains('под дату')));
  });

  test('IPL зуд, никель+RF, Veil простыми, запись без кнопки', () {
    final itch = cultAgent.answer('После IPL лицо чешется на второй день — норма?');
    expect(itch.toLowerCase(), anyOf(contains('зуд'), contains('чеш')));
    expect(itch.toLowerCase(), isNot(contains('пятна иногда временно темнеют')));
    final nick = cultAgent.answer('У меня аллергия на никель — RF можно?');
    expect(nick.toLowerCase(), contains('никель'));
    expect(nick.toLowerCase(), isNot(contains('анестезию, металлы или косметику')));
    final veil = cultAgent.answer('Что такое Veil Peptide Serum простыми словами?');
    expect(veil.toLowerCase(), contains('veil'));
    expect(veil.toLowerCase(), isNot(contains('neuro-regen')));
    final conf = cultAgent.answer('Хочу подтвердить запись голосом без кнопки');
    expect(conf.toLowerCase(), anyOf(contains('кнопк'), contains('нельзя')));
    expect(conf.toLowerCase(), isNot(contains('или откройте запись в меню')));
  });

  test('Липосакция, панкреатит+IV, Aptos, латекс', () {
    final lipo = cultAgent.answer('Делаете ли липосакцию?');
    expect(lipo.toLowerCase(), anyOf(contains('липосак'), contains('не делаем'), contains('хирург')));
    expect(lipo.toLowerCase(), isNot(contains('контурная пластика')));
    final panc = cultAgent.answer('Можно ли капельницу при панкреатите?');
    expect(panc.toLowerCase(), contains('панкреатит'));
    expect(panc.toLowerCase(), isNot(contains('меню «инфузии»')));
    final aptos = cultAgent.answer('Делаете ли лифтинг нитями Aptos?');
    expect(aptos.toLowerCase(), anyOf(contains('нит'), contains('aptos'), contains('осмотр')));
    expect(aptos.toLowerCase(), isNot(contains('я рядом')));
    final latex = cultAgent.answer('У меня аллергия на латекс — филлер можно?');
    expect(latex.toLowerCase(), contains('латекс'));
    expect(latex.toLowerCase(), isNot(contains('анестезию, металлы или косметику')));
  });

  test('IPL+чистка, ботокс+Beauty, домашний уход после RF', () {
    final combo = cultAgent.answer('Можно ли совместить IPL и чистку в один день?');
    expect(combo.toLowerCase(), anyOf(contains('ipl'), contains('чистк')));
    expect(combo.toLowerCase(), isNot(contains('скажите пару процедур')));
    final glow = cultAgent.answer('Можно ли совместить ботокс и Beauty & Glow через неделю?');
    expect(glow.toLowerCase(), anyOf(contains('ботулин'), contains('beauty'), contains('капель')));
    expect(glow.toLowerCase(), isNot(contains('скажите пару')));
    final home = cultAgent.answer('Хочу домашний уход после микроигольчатого RF');
    expect(home.toLowerCase(), anyOf(contains('барьер'), contains('rf'), contains('дом')));
    expect(home.toLowerCase(), isNot(contains('меню «аппаратная»')));
  });

  test('Рассрочка Ultherapy, сертификат маме, спорт после IPL', () {
    final credit = cultAgent.answer('Есть ли рассрочка на Ultherapy?');
    expect(credit.toLowerCase(), contains('рассроч'));
    expect(credit.toLowerCase(), isNot(contains('массаж посильнее')));
    final gift = cultAgent.answer('Можно ли подарить сертификат на день рождения маме?');
    expect(gift.toLowerCase(), contains('сертификат'));
    expect(gift.toLowerCase(), isNot(contains('под дату')));
    final sport = cultAgent.answer('Сколько нельзя спорт после IPL?');
    expect(sport.toLowerCase(), contains('ipl'));
    expect(sport.toLowerCase(), isNot(contains('напишите, что делали')));
  });

  test('Абдоминопластика, пересадка волос, пролактин+IV', () {
    final abdo = cultAgent.answer('Делаете ли абдоминопластику?');
    expect(abdo.toLowerCase(), anyOf(contains('абдоминопласт'), contains('не делаем'), contains('хирург')));
    expect(abdo.toLowerCase(), isNot(contains('давайте проще')));
    final hair = cultAgent.answer('Делаете ли пересадку волос?');
    expect(hair.toLowerCase(), anyOf(contains('пересадк'), contains('не делаем'), contains('трихо')));
    expect(hair.toLowerCase(), isNot(contains('не уверена')));
    final prol = cultAgent.answer('У меня повышенный пролактин — капельницу можно?');
    expect(prol.toLowerCase(), contains('пролактин'));
    expect(prol.toLowerCase(), isNot(contains('меню «инфузии»')));
  });

  test('Язва+IV, SMAS+брекеты, RF+пилинг через 10 дней', () {
    final ulcer = cultAgent.answer('Можно ли капельницу при язвенной болезни?');
    expect(ulcer.toLowerCase(), anyOf(contains('язв'), contains('жкт')));
    expect(ulcer.toLowerCase(), isNot(contains('меню «инфузии»')));
    final braces = cultAgent.answer('Можно ли делать SMAS если стоят брекеты?');
    expect(braces.toLowerCase(), anyOf(contains('smas'), contains('брекет')));
    expect(braces.toLowerCase(), isNot(contains('запишем скульптурный массаж')));
    final peel = cultAgent.answer('Можно ли совместить RF и пилинг через десять дней?');
    expect(peel.toLowerCase(), anyOf(contains('rf'), contains('пилинг'), contains('7–10'), contains('через')));
    expect(peel.toLowerCase(), isNot(contains('скажите пару')));
  });

  test('Асимметрия страх, пакет массажей, бонусы подруге', () {
    final asym = cultAgent.answer('Боюсь асимметрии после филлера губ');
    expect(asym.toLowerCase(), contains('асимметр'));
    expect(asym.toLowerCase(), isNot(contains('без уколов в губы')));
    final pack = cultAgent.answer('Есть ли скидка на пакет из пяти массажей?');
    expect(pack.toLowerCase(), anyOf(contains('пакет'), contains('5 масс'), contains('курс')));
    expect(pack.toLowerCase(), isNot(contains('акции точнее скажет')));
    final bonus = cultAgent.answer('Можно ли оплатить бонусами CULT капельницу подруге?');
    expect(bonus.toLowerCase(), anyOf(contains('подруг'), contains('сертификат'), contains('владельц')));
  });

  test('Мигрень+IV, подагра+IV, домашний уход после пилинга', () {
    final mig = cultAgent.answer('У меня мигрени часто — капельницу можно?');
    expect(mig.toLowerCase(), contains('мигрен'));
    expect(mig.toLowerCase(), isNot(contains('меню «инфузии»')));
    final gout = cultAgent.answer('Можно ли капельницу при подагре?');
    expect(gout.toLowerCase(), contains('подагр'));
    expect(gout.toLowerCase(), isNot(contains('меню «инфузии»')));
    final home = cultAgent.answer('Хочу домашний уход после химического пилинга L3');
    expect(home.toLowerCase(), anyOf(contains('барьер'), contains('пилинг'), contains('spf')));
    expect(home.toLowerCase(), isNot(contains('меню «услуги»')));
  });

  test('SMAS+улыбка, IPL+тату, мезо+массаж через неделю', () {
    final smile = cultAgent.answer('Что делать если после SMAS нельзя улыбнуться?');
    expect(smile.toLowerCase(), anyOf(contains('улыб'), contains('мимик'), contains('отёк'), contains('отек')));
    expect(smile.toLowerCase(), isNot(contains('массаж посильнее')));
    final tattoo = cultAgent.answer('Можно ли делать IPL если есть тату на лице?');
    expect(tattoo.toLowerCase(), contains('тату'));
    expect(tattoo.toLowerCase(), isNot(contains('разделе «аппаратная»')));
    final meso = cultAgent.answer('Можно ли совместить мезотерапию и массаж через неделю?');
    expect(meso.toLowerCase(), anyOf(contains('мезо'), contains('массаж'), contains('недел')));
    expect(meso.toLowerCase(), isNot(contains('скажите пару')));
  });

  test('Мужской абонемент барбер, Neuro-Regen, губа больше', () {
    final men = cultAgent.answer('Есть ли мужской абонемент на барбер-массаж?');
    expect(men.toLowerCase(), anyOf(contains('мужск'), contains('барбер'), contains('абонемент')));
    expect(men.toLowerCase(), isNot(contains('пакет из 5')));
    final neuro = cultAgent.answer('Что такое Neuro-Regen IV Serum простыми словами?');
    expect(neuro.toLowerCase(), contains('neuro'));
    expect(neuro.toLowerCase(), isNot(contains('veil peptide')));
    final lip = cultAgent.answer('После филлера одна губа больше другой на второй день');
    expect(lip.toLowerCase(), anyOf(contains('асимметр'), contains('отёк'), contains('отек'), contains('губ')));
    expect(lip.toLowerCase(), isNot(contains('подбирает врач после осмотра')));
  });

  test('Гипертония+RF, мочекаменная+IV, изотретиноин+филлер', () {
    final ht = cultAgent.answer('У меня гипертония — RF можно?');
    expect(ht.toLowerCase(), anyOf(contains('гипертон'), contains('давлен'), contains('допуск')));
    expect(ht.toLowerCase(), isNot(contains('меню «аппаратная»')));
    final stone = cultAgent.answer('Можно ли капельницу при мочекаменной болезни?');
    expect(stone.toLowerCase(), contains('мочекамен'));
    expect(stone.toLowerCase(), isNot(contains('натуральный результат')));
    final iso = cultAgent.answer('Можно ли делать филлер если пью изотретиноин?');
    expect(iso.toLowerCase(), anyOf(contains('изотретиноин'), contains('инъек')));
    expect(iso.toLowerCase(), isNot(contains('да, пилим')));
  });

  test('IPL корочки, йод+IPL, двоих, сменить врача', () {
    final crust = cultAgent.answer('После IPL появились корочки — норма?');
    expect(crust.toLowerCase(), contains('ipl'));
    expect(crust.toLowerCase(), isNot(contains('после rf')));
    final iodine = cultAgent.answer('У меня аллергия на йод — IPL можно?');
    expect(iodine.toLowerCase(), anyOf(contains('йод'), contains('ipl')));
    expect(iodine.toLowerCase(), isNot(contains('до капельницы')));
    final pair = cultAgent.answer('Можно ли записаться сразу на двоих с подругой?');
    expect(pair.toLowerCase(), anyOf(contains('дво'), contains('соседн')));
    expect(pair.toLowerCase(), isNot(contains('осталось окно')));
    final doc = cultAgent.answer('Хочу сменить врача в записи голосом');
    expect(doc.toLowerCase(), anyOf(contains('сменить'), contains('врач'), contains('админ')));
  });

  test('Диабет+мезо, Beauty частота, доставка за город', () {
    final dm = cultAgent.answer('Можно ли делать мезотерапию при диабете?');
    expect(dm.toLowerCase(), contains('диабет'));
    expect(dm.toLowerCase(), isNot(contains('без сауны и бассейна')));
    final glow = cultAgent.answer('Как часто можно делать Beauty & Glow?');
    expect(glow.toLowerCase(), anyOf(contains('beauty'), contains('glow'), contains('недел')));
    expect(glow.toLowerCase(), isNot(contains('назовите процедуры')));
    final ship = cultAgent.answer('Можно ли заказать шоп с доставкой за город?');
    expect(ship.toLowerCase(), anyOf(contains('город'), contains('област'), contains('курьер')));
  });

  test('Аритмия+IV, лабиопластика, холецистит+IV', () {
    final arr = cultAgent.answer('У меня аритмия — капельницу можно?');
    expect(arr.toLowerCase(), contains('аритм'));
    expect(arr.toLowerCase(), isNot(contains('меню «инфузии»')));
    final lab = cultAgent.answer('Делаете ли лабиопластику?');
    expect(lab.toLowerCase(), contains('лабиопласт'));
    expect(lab.toLowerCase(), isNot(contains('не уверена')));
    final chol = cultAgent.answer('Можно ли капельницу при холецистите?');
    expect(chol.toLowerCase(), contains('холецист'));
    expect(chol.toLowerCase(), isNot(contains('меню «инфузии»')));
  });

  test('Детский прайс, биоревитал частота, латекс+IV', () {
    final kids = cultAgent.answer('Есть ли детский прайс до 16 лет?');
    expect(kids.toLowerCase(), anyOf(contains('детск'), contains('18')));
    expect(kids.toLowerCase(), isNot(contains('цифра в паспорте')));
    final freq = cultAgent.answer('Как часто можно колоть биоревитализацию?');
    expect(freq.toLowerCase(), anyOf(contains('недел'), contains('интервал'), contains('курс')));
    expect(freq.toLowerCase(), isNot(contains('без сауны и бассейна')));
    final latex = cultAgent.answer('У меня аллергия на латекс — капельницу можно?');
    expect(latex.toLowerCase(), anyOf(contains('капельниц'), contains('инфуз')));
    expect(latex.toLowerCase(), isNot(contains('до инъекций')));
  });

  test('Сертификат+карта, IPL+перелёт, вторая услуга', () {
    final pay = cultAgent.answer('Можно ли оплатить визит сертификатом частично картой?');
    expect(pay.toLowerCase(), anyOf(contains('остат'), contains('карт'), contains('частич')));
    expect(pay.toLowerCase(), isNot(contains('другого человека')));
    final fly = cultAgent.answer('После IPL можно лететь через четыре дня?');
    expect(fly.toLowerCase(), contains('ipl'));
    expect(fly.toLowerCase(), isNot(contains('разделе «аппаратная»')));
    final add = cultAgent.answer('Хочу добавить вторую услугу к уже собранной записи');
    expect(add.toLowerCase(), anyOf(contains('вторую'), contains('админ'), contains('мои записи')));
    expect(add.toLowerCase(), isNot(contains('скажите услугу и когда')));
  });

  test('Брадикардия+IV, студенческий прайс, панкреатит ремиссия', () {
    final brady = cultAgent.answer('У меня брадикардия — капельницу можно?');
    expect(brady.toLowerCase(), anyOf(contains('брадикард'), contains('аритм'), contains('кардиолог')));
    expect(brady.toLowerCase(), isNot(contains('меню «инфузии»')));
    final stud = cultAgent.answer('Есть ли студенческий прайс?');
    expect(stud.toLowerCase(), contains('студенч'));
    expect(stud.toLowerCase(), isNot(contains('меню «прайс»')));
    final panc = cultAgent.answer('Можно ли капельницу при панкреатите в ремиссии?');
    expect(panc.toLowerCase(), contains('панкреатит'));
    expect(panc.toLowerCase(), isNot(contains('онколог')));
  });

  test('Никель+IV, IPL+брекеты, сертификат только шоп', () {
    final ni = cultAgent.answer('У меня аллергия на никель — капельницу можно?');
    expect(ni.toLowerCase(), anyOf(contains('капельниц'), contains('инфуз')));
    expect(ni.toLowerCase(), isNot(contains('до rf')));
    final br = cultAgent.answer('Можно ли делать IPL если стоят брекеты?');
    expect(br.toLowerCase(), contains('ipl'));
    expect(br.toLowerCase(), isNot(contains('массаж лица часто можно')));
    final shop = cultAgent.answer('Можно ли оплатить сертификатом только шоп без процедуры?');
    expect(shop.toLowerCase(), anyOf(contains('шоп'), contains('магазин'), contains('номинал')));
    expect(shop.toLowerCase(), isNot(contains('другого человека')));
  });

  test('SMAS стянуто, RF сон, домашний набор после чистки', () {
    final smas = cultAgent.answer('После SMAS лицо стянуто на пятый день — норма?');
    expect(smas.toLowerCase(), anyOf(contains('стянут'), contains('восстанов')));
    expect(smas.toLowerCase(), isNot(contains('массаж посильнее')));
    final sleep = cultAgent.answer('После RF можно спать на животе через сутки?');
    expect(sleep.toLowerCase(), contains('rf'));
    expect(sleep.toLowerCase(), isNot(contains('bodytite')));
    final home = cultAgent.answer('Хочу домашний набор после чистки');
    expect(home.toLowerCase(), anyOf(contains('барьер'), contains('чистк'), contains('lumen')));
    expect(home.toLowerCase(), isNot(contains('биомаркер')));
  });

  test('Чистка горячее, витамин D+ботокс, хлоргексидин+IV', () {
    final hot = cultAgent.answer('После чистки лицо горячее вечером — норма?');
    expect(hot.toLowerCase(), anyOf(contains('горяч'), contains('чистк'), contains('барьер')));
    expect(hot.toLowerCase(), isNot(contains('если сложно')));
    final vit = cultAgent.answer('Можно ли делать ботокс если пью витамин D?');
    expect(vit.toLowerCase(), anyOf(contains('витамин'), contains('бот')));
    expect(vit.toLowerCase(), isNot(contains('витаминная iv')));
    final chx = cultAgent.answer('У меня аллергия на хлоргексидин — капельницу можно?');
    expect(chx.toLowerCase(), contains('хлоргексид'));
    expect(chx.toLowerCase(), isNot(contains('сообщите об аллергиях на анестезию')));
  });

  test('Beauty+лимфо цена, акне+Glow, пилинг+перелёт', () {
    final price = cultAgent.answer('Сколько стоит Beauty & Glow и лимфодренаж вместе?');
    expect(price.toLowerCase(), anyOf(contains('beauty'), contains('glow')));
    expect(price.toLowerCase(), anyOf(contains('лимфо'), contains('массаж')));
    expect(price.toLowerCase(), contains('отдельн'));
    final acne = cultAgent.answer('У меня акне — Beauty & Glow можно?');
    expect(acne.toLowerCase(), anyOf(contains('акне'), contains('beauty'), contains('glow')));
    expect(acne.toLowerCase(), isNot(contains('химический пилинг')));
    final fly = cultAgent.answer('После пилинга можно лететь через пять дней?');
    expect(fly.toLowerCase(), contains('пилинг'));
    expect(fly.toLowerCase(), isNot(contains('после процедуры обычно')));
  });

  test('Экстрасистолия+IV, колит+IV, военный прайс', () {
    final ex = cultAgent.answer('У меня экстрасистолия — капельницу можно?');
    expect(ex.toLowerCase(), anyOf(contains('экстрасистол'), contains('аритм'), contains('кардиолог')));
    expect(ex.toLowerCase(), isNot(contains('меню «инфузии»')));
    final col = cultAgent.answer('Можно ли капельницу при колите?');
    expect(col.toLowerCase(), contains('колит'));
    expect(col.toLowerCase(), isNot(contains('меню «инфузии»')));
    final mil = cultAgent.answer('Есть ли военный прайс или скидка военнослужащим?');
    expect(mil.toLowerCase(), contains('военн'));
    expect(mil.toLowerCase(), isNot(contains('меню «прайс»')));
  });

  test('Головокружение после массажа, тяжёлый лоб, новокаин+IV', () {
    final dizzy = cultAgent.answer('После массажа голова кружится — норма?');
    expect(dizzy.toLowerCase(), anyOf(contains('круж'), contains('головокруж'), contains('массаж')));
    expect(dizzy.toLowerCase(), isNot(contains('меню «услуги»')));
    final heavy = cultAgent.answer('После ботокса лоб тяжёлый на третий день — норма?');
    expect(heavy.toLowerCase(), anyOf(contains('тяжёл'), contains('тяжел'), contains('лоб')));
    expect(heavy.toLowerCase(), isNot(contains('скульптурный массаж лица или плотный')));
    final nov = cultAgent.answer('У меня аллергия на новокаин — капельницу можно?');
    expect(nov.toLowerCase(), contains('новокаин'));
    expect(nov.toLowerCase(), isNot(contains('сообщите об аллергиях на анестезию')));
  });

  test('Стенокардия+IV, зуд после чистки, пенсионный прайс, родинки лазером', () {
    final sten = cultAgent.answer('У меня стенокардия — капельницу можно?');
    expect(sten.toLowerCase(), contains('стенокард'));
    expect(sten.toLowerCase(), isNot(contains('меню «инфузии»')));
    final itch = cultAgent.answer('После чистки зудит лицо — норма?');
    expect(itch.toLowerCase(), anyOf(contains('зуд'), contains('чистк'), contains('барьер')));
    expect(itch.toLowerCase(), isNot(contains('если сложно')));
    final pens = cultAgent.answer('Есть ли пенсионный прайс?');
    expect(pens.toLowerCase(), contains('пенсион'));
    expect(pens.toLowerCase(), isNot(contains('меню «прайс»')));
    final mole = cultAgent.answer('Делаете ли удаление родинок лазером?');
    expect(mole.toLowerCase(), anyOf(contains('родин'), contains('новообразован')));
    expect(mole.toLowerCase(), anyOf(contains('лазер'), contains('осмотр'), contains('врач')));
    expect(mole.toLowerCase(), isNot(contains('меню «')));
  });

  test('Цинк+ботокс, щёки после филлера, барбер+мужской цена, RF шелушится', () {
    final zn = cultAgent.answer('Можно ли делать ботокс если пью цинк?');
    expect(zn.toLowerCase(), contains('цинк'));
    expect(zn.toLowerCase(), isNot(contains('витаминная iv')));
    final cheeks = cultAgent.answer('После филлера щёки горят на второй день — норма?');
    expect(cheeks.toLowerCase(), anyOf(contains('щек'), contains('щёк'), contains('лиц'), contains('филлер')));
    expect(cheeks.toLowerCase(), isNot(contains('жжение губ')));
    final price = cultAgent.answer('Сколько стоит барбер-массаж и мужской уход вместе?');
    expect(price.toLowerCase(), contains('барбер'));
    expect(price.toLowerCase(), anyOf(contains('мужск'), contains('уход')));
    expect(price.toLowerCase(), contains('отдельн'));
    final rf = cultAgent.answer('Что делать если после RF лицо шелушится на четвёртый день?');
    expect(rf.toLowerCase(), contains('rf'));
    expect(rf.toLowerCase(), anyOf(contains('шелуш'), contains('барьер')));
    expect(rf.toLowerCase(), isNot(contains('обезвоженность и слабый барьер')));
  });

  test('Neuro-Regen самовывоз, набор после мезо, брови после ботокса, йод+ботокс', () {
    final neuro = cultAgent.answer('Можно ли купить Neuro-Regen с самовывозом сегодня?');
    expect(neuro.toLowerCase(), anyOf(contains('neuro'), contains('нейро'), contains('самовывоз')));
    expect(neuro.toLowerCase(), isNot(contains('близкой дате')));
    final home = cultAgent.answer('Хочу домашний набор после мезо');
    expect(home.toLowerCase(), anyOf(contains('барьер'), contains('мезо'), contains('lumen')));
    expect(home.toLowerCase(), isNot(contains('без сауны и бассейна пару дней')));
    final brows = cultAgent.answer('После ботокса можно красить брови через два дня?');
    expect(brows.toLowerCase(), contains('бров'));
    expect(brows.toLowerCase(), isNot(contains('макияж на зону обычно откладывают минимум на сутки')));
    final iodine = cultAgent.answer('У меня аллергия на йод — ботокс можно?');
    expect(iodine.toLowerCase(), contains('йод'));
    expect(iodine.toLowerCase(), anyOf(contains('бот'), contains('инъек')));
    expect(iodine.toLowerCase(), isNot(contains('до капельницы')));
  });

  test('RF зуд, IPL+биоревитал, сертификат филиал, тату удаление', () {
    final itch = cultAgent.answer('После RF зудит лицо — норма?');
    expect(itch.toLowerCase(), contains('rf'));
    expect(itch.toLowerCase(), anyOf(contains('зуд'), contains('барьер')));
    expect(itch.toLowerCase(), isNot(contains('давайте проще')));
    final combo = cultAgent.answer('Можно ли совместить IPL и биоревитализацию через две недели?');
    expect(combo.toLowerCase(), contains('ipl'));
    expect(combo.toLowerCase(), anyOf(contains('биоревитал'), contains('мезо')));
    expect(combo.toLowerCase(), isNot(contains('скажите пару процедур')));
    final cert = cultAgent.answer('Можно ли перенести сертификат на другой филиал голосом?');
    expect(cert.toLowerCase(), contains('филиал'));
    expect(cert.toLowerCase(), isNot(contains('другого человека')));
    final tattoo = cultAgent.answer('Делаете ли удаление татуировок лазером?');
    expect(tattoo.toLowerCase(), anyOf(contains('тату'), contains('сведен')));
    expect(tattoo.toLowerCase(), isNot(contains('запишем консультацию по ipl')));
  });

  test('Pacemaker родственник, стянутость пилинг, HydraPure+массаж, губы помада', () {
    final pace = cultAgent.answer('Можно ли делать RF если стоит кардиостимулятор у родственника дома?');
    expect(pace.toLowerCase(), contains('родствен'));
    expect(pace.toLowerCase(), isNot(contains('жёстким ограничением или запретом')));
    final tight = cultAgent.answer('Что делать если после пилинга лицо стянуто на пятый день?');
    expect(tight.toLowerCase(), anyOf(contains('стянут'), contains('барьер'), contains('пилинг')));
    expect(tight.toLowerCase(), isNot(contains('после процедуры обычно бережём')));
    final price = cultAgent.answer('Сколько стоит HydraPure и скульптурный массаж вместе?');
    expect(price.toLowerCase(), contains('hydrapure'));
    expect(price.toLowerCase(), contains('массаж'));
    expect(price.toLowerCase(), contains('отдельн'));
    final lips = cultAgent.answer('После филлера можно красить губы через день?');
    expect(lips.toLowerCase(), anyOf(contains('губ'), contains('помад'), contains('филлер')));
    expect(lips.toLowerCase(), isNot(contains('что делали или планируете')));
  });

  test('Отёк к свадьбе, мезо+чистка, мерцательная аритмия', () {
    final wed = cultAgent.answer('Боюсь отёка после филлера к свадьбе через десять дней');
    expect(wed.toLowerCase(), anyOf(contains('свадьб'), contains('запас'), contains('отёк'), contains('отек')));
    expect(wed.toLowerCase(), isNot(contains('голова выше подушки')));
    final meso = cultAgent.answer('Можно ли совместить мезо и чистку через неделю?');
    expect(meso.toLowerCase(), anyOf(contains('мезо'), contains('чистк')));
    expect(meso.toLowerCase(), isNot(contains('скажите пару процедур')));
    final af = cultAgent.answer('У меня мерцательная аритмия — капельницу можно?');
    expect(af.toLowerCase(), anyOf(contains('аритм'), contains('кардиолог')));
    expect(af.toLowerCase(), isNot(contains('меню «инфузии»')));
  });

  test('Стеноз аорты+IV, Крон+IV, SMAS горячее, RF+биоревитал', () {
    final sten = cultAgent.answer('У меня стеноз аорты — капельницу можно?');
    expect(sten.toLowerCase(), anyOf(contains('стеноз'), contains('аорт'), contains('кардиолог')));
    expect(sten.toLowerCase(), isNot(contains('меню «инфузии»')));
    final crohn = cultAgent.answer('Можно ли капельницу при болезни Крона?');
    expect(crohn.toLowerCase(), contains('крон'));
    expect(crohn.toLowerCase(), isNot(contains('меню «инфузии»')));
    final hot = cultAgent.answer('После SMAS лицо горячее вечером — норма?');
    expect(hot.toLowerCase(), contains('smas'));
    expect(hot.toLowerCase(), anyOf(contains('горяч'), contains('тёпл'), contains('тепл')));
    expect(hot.toLowerCase(), isNot(contains('не «массаж посильнее»')));
    final combo = cultAgent.answer('Можно ли совместить RF и биоревитализацию через три недели?');
    expect(combo.toLowerCase(), contains('rf'));
    expect(combo.toLowerCase(), anyOf(contains('биоревитал'), contains('мезо')));
    expect(combo.toLowerCase(), isNot(contains('скажите пару процедур')));
  });

  test('Многодетный прайс, вино+скулы, лидокаин+филлер, сменить услугу', () {
    final kids = cultAgent.answer('Есть ли прайс для многодетных семей?');
    expect(kids.toLowerCase(), contains('многодетн'));
    expect(kids.toLowerCase(), isNot(contains('семейного абонемента')));
    final wine = cultAgent.answer('Кожа краснеет только на скулах после вина');
    expect(wine.toLowerCase(), anyOf(contains('вин'), contains('сосуд'), contains('скул')));
    expect(wine.toLowerCase(), isNot(contains('жевательн')));
    final lido = cultAgent.answer('У меня аллергия на лидокаин — филлер можно?');
    expect(lido.toLowerCase(), contains('лидокаин'));
    expect(lido.toLowerCase(), anyOf(contains('филлер'), contains('инъек')));
    expect(lido.toLowerCase(), isNot(contains('до rf')));
    final swap = cultAgent.answer('Хочу сменить услугу в записи голосом');
    expect(swap.toLowerCase(), anyOf(contains('услуг'), contains('моих записей'), contains('админ')));
    expect(swap.toLowerCase(), isNot(contains('собрали уходы и пилинги')));
  });

  test('Lumen самовывоз, набор после SMAS, мезо зуд, пилинг+HydraPure цена', () {
    final lumen = cultAgent.answer('Можно ли купить Lumen Barrier с самовывозом завтра?');
    expect(lumen.toLowerCase(), anyOf(contains('lumen'), contains('самовывоз')));
    expect(lumen.toLowerCase(), isNot(contains('посмотрела lumen')));
    final home = cultAgent.answer('Хочу домашний набор после SMAS');
    expect(home.toLowerCase(), anyOf(contains('барьер'), contains('smas'), contains('lumen')));
    expect(home.toLowerCase(), isNot(contains('не «массаж посильнее»')));
    final itch = cultAgent.answer('После мезо зудит лицо на второй день — норма?');
    expect(itch.toLowerCase(), anyOf(contains('зуд'), contains('мезо'), contains('папул')));
    expect(itch.toLowerCase(), isNot(contains('без сауны и бассейна пару дней')));
    final price = cultAgent.answer('Сколько стоит пилинг L3 и HydraPure вместе?');
    expect(price.toLowerCase(), contains('hydrapure'));
    expect(price.toLowerCase(), contains('пилинг'));
    expect(price.toLowerCase(), contains('отдельн'));
  });

  test('RF стянуто, губы гиалуронка, железо+ботокс, IPL горячее', () {
    final tight = cultAgent.answer('Что делать если после RF лицо стянуто на третий день?');
    expect(tight.toLowerCase(), contains('rf'));
    expect(tight.toLowerCase(), anyOf(contains('стянут'), contains('барьер')));
    expect(tight.toLowerCase(), isNot(contains('слышу много нюансов')));
    final lips = cultAgent.answer('Делаете ли увеличение губ гиалуронкой?');
    expect(lips.toLowerCase(), anyOf(contains('губ'), contains('филлер'), contains('гиалурон')));
    expect(lips.toLowerCase(), isNot(contains('если сложно сформулировать')));
    final iron = cultAgent.answer('Можно ли делать ботокс если пью железо?');
    expect(iron.toLowerCase(), contains('желез'));
    expect(iron.toLowerCase(), isNot(contains('инъекции (ботулин, филлеры')));
    final ipl = cultAgent.answer('После IPL лицо горячее вечером — норма?');
    expect(ipl.toLowerCase(), contains('ipl'));
    expect(ipl.toLowerCase(), anyOf(contains('горяч'), contains('тёпл'), contains('тепл')));
    expect(ipl.toLowerCase(), isNot(contains('ближайше')));
  });

  test('Новокаин+филлер, подарить сертификат, выпускной отёк, брови после RF', () {
    final nov = cultAgent.answer('У меня аллергия на новокаин — филлер можно?');
    expect(nov.toLowerCase(), contains('новокаин'));
    expect(nov.toLowerCase(), anyOf(contains('филлер'), contains('инъек')));
    expect(nov.toLowerCase(), isNot(contains('до капельницы')));
    final gift = cultAgent.answer('Можно ли подарить сертификат голосом другому человеку?');
    expect(gift.toLowerCase(), anyOf(contains('оформить'), contains('номинал'), contains('админ')));
    expect(gift.toLowerCase(), isNot(contains('оплатить визит другого')));
    final grad = cultAgent.answer('Боюсь отёка после ботокса к выпускному через неделю');
    expect(grad.toLowerCase(), anyOf(contains('выпускн'), contains('ботулин'), contains('запас')));
    expect(grad.toLowerCase(), isNot(contains('близкой дате')));
    final brows = cultAgent.answer('После RF можно красить брови через два дня?');
    expect(brows.toLowerCase(), contains('rf'));
    expect(brows.toLowerCase(), contains('бров'));
    expect(brows.toLowerCase(), isNot(contains('после ботулина брови')));
  });

  test('Immunity частота, ретинол шелушение, Cellular самовывоз, именинник', () {
    final imm = cultAgent.answer('Как часто можно делать Immunity Boost?');
    expect(imm.toLowerCase(), contains('immunity'));
    expect(imm.toLowerCase(), isNot(contains('назовите процедуры')));
    final ret = cultAgent.answer('Кожа шелушится только на подбородке после ретинола');
    expect(ret.toLowerCase(), contains('ретинол'));
    expect(ret.toLowerCase(), isNot(contains('обезвоженность и слабый барьер')));
    final cat = cultAgent.answer('Можно ли купить Cellular Catalyst с самовывозом сегодня?');
    expect(cat.toLowerCase(), anyOf(contains('cellular'), contains('catalyst'), contains('самовывоз')));
    expect(cat.toLowerCase(), isNot(contains('посмотрела cellular')));
    final bday = cultAgent.answer('Есть ли скидка имениннику?');
    expect(bday.toLowerCase(), contains('именинник'));
    expect(bday.toLowerCase(), isNot(contains('welcome-бонус')));
  });

  test('Биотин+ботокс, Beauty+NAD цена, промокод, отмена трансфера', () {
    final biotin = cultAgent.answer('Можно ли делать ботокс если пью биотин?');
    expect(biotin.toLowerCase(), contains('биотин'));
    expect(biotin.toLowerCase(), isNot(contains('инъекции (ботулин, филлеры')));
    final price = cultAgent.answer('Сколько стоит Beauty & Glow и NAD+ вместе?');
    expect(price.toLowerCase(), contains('beauty'));
    expect(price.toLowerCase(), contains('nad'));
    expect(price.toLowerCase(), contains('отдельн'));
    final promo = cultAgent.answer('Есть ли скидка по промокоду голосом?');
    expect(promo.toLowerCase(), contains('промокод'));
    expect(promo.toLowerCase(), isNot(contains('welcome-бонус')));
    final cancel = cultAgent.respond('Хочу отменить трансфер голосом');
    expect(cancel.reply.toLowerCase(), anyOf(contains('отмен'), contains('админ')));
    expect(cancel.transfer, isNull);
    expect(cancel.reply.toLowerCase(), isNot(contains('откуда забрать')));
  });

  test('Лимфо+перелёт, купероз+RF, мезо+краска, набор после барбера', () {
    final flight = cultAgent.answer('После лимфодренажа можно лететь через день?');
    expect(flight.toLowerCase(), anyOf(contains('лимфодрен'), contains('перел')));
    expect(flight.toLowerCase(), isNot(contains('близкой дате')));
    final kup = cultAgent.answer('У меня купероз — RF можно?');
    expect(kup.toLowerCase(), contains('rf'));
    expect(kup.toLowerCase(), contains('купероз'));
    final dye = cultAgent.answer('После мезо можно красить волосы через четыре дня?');
    expect(dye.toLowerCase(), anyOf(contains('мезо'), contains('окраш'), contains('красить')));
    expect(dye.toLowerCase(), isNot(contains('без сауны и бассейна пару дней')));
    final home = cultAgent.answer('Хочу домашний набор после барбер-массажа');
    expect(home.toLowerCase(), anyOf(contains('барбер'), contains('барьер'), contains('магазин')));
    expect(home.toLowerCase(), isNot(contains('кому подбираем')));
  });

  test('Филлер губы стянуты, NAD частота, баланс сертификата, свадьба асимметрия', () {
    final lips = cultAgent.answer('Что делать если после филлера губы стянуты на второй день?');
    expect(lips.toLowerCase(), anyOf(contains('филлер'), contains('губ')));
    expect(lips.toLowerCase(), anyOf(contains('стянут'), contains('отёк'), contains('отек')));
    final nad = cultAgent.answer('Как часто можно делать NAD+ Energy?');
    expect(nad.toLowerCase(), contains('nad'));
    expect(nad.toLowerCase(), isNot(contains('назовите процедуры')));
    final bal = cultAgent.answer('Можно ли проверить баланс сертификата голосом?');
    expect(bal.toLowerCase(), anyOf(contains('баланс'), contains('остаток')));
    expect(bal.toLowerCase(), isNot(contains('купить сертификат')));
    final wed = cultAgent.answer('Боюсь асимметрии после ботокса к свадьбе через две недели');
    expect(wed.toLowerCase(), anyOf(contains('свадьб'), contains('асимметр')));
    expect(wed.toLowerCase(), isNot(contains('аппликационной анестезией')));
  });

  test('Immunity+Beauty цена, язва+IV, студент, перенос трансфера', () {
    final price = cultAgent.answer('Сколько стоит Immunity Boost и Beauty & Glow вместе?');
    expect(price.toLowerCase(), contains('immunity'));
    expect(price.toLowerCase(), contains('beauty'));
    expect(price.toLowerCase(), contains('отдельн'));
    final ulcer = cultAgent.answer('Можно ли капельницу при язве в ремиссии?');
    expect(ulcer.toLowerCase(), anyOf(contains('язв'), contains('жкт')));
    expect(ulcer.toLowerCase(), isNot(contains('hydrapure')));
    final stud = cultAgent.answer('Есть ли скидка студенту на массаж?');
    expect(stud.toLowerCase(), contains('студенч'));
    expect(stud.toLowerCase(), isNot(contains('welcome-бонус')));
    final move = cultAgent.respond('Хочу перенести трансфер на час позже');
    expect(move.reply.toLowerCase(), anyOf(contains('перенес'), contains('админ')));
    expect(move.transfer, isNull);
    expect(move.reply.toLowerCase(), isNot(contains('заказала трансфер')));
  });

  test('SMAS+мезонити, губы без гиалуронки, аритмия+гипертония', () {
    final threads = cultAgent.answer('Можно ли делать SMAS если есть мезонити?');
    expect(threads.toLowerCase(), anyOf(contains('мезонит'), contains('нит')));
    expect(threads.toLowerCase(), contains('smas'));
    expect(threads.toLowerCase(), isNot(contains('не «массаж посильнее»')));
    final lips = cultAgent.answer('Делаете ли увеличение губ без гиалуронки?');
    expect(lips.toLowerCase(), contains('без гиалурон'));
    expect(lips.toLowerCase(), isNot(contains('шаблонная уточка')));
    final afib = cultAgent.answer('У меня мерцательная аритмия и гипертония — капельницу можно?');
    expect(afib.toLowerCase(), contains('аритм'));
    expect(afib.toLowerCase(), isNot(contains('консультацию по rf')));
  });
}
