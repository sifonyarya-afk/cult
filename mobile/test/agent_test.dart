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
    expect(hi.toLowerCase(), contains('здравств'));
    expect(hi.toLowerCase(), isNot(contains('не нашла')));
    final mood = cultAgent.answer('Как дела?');
    expect(mood.toLowerCase(), anyOf(contains('ровн'), contains('чувству')));
    final thanks = cultAgent.answer('Спасибо');
    expect(thanks.toLowerCase(), contains('спасибо'));
    final tip = cultAgent.answer('Подскажи');
    expect(tip.toLowerCase(), anyOf(contains('вместе'), contains('лицо')));
  });

  test('Свободный разговор по жалобе без названия услуги', () {
    final dry = cultAgent.answer('Кожа очень сухая и стягивает');
    expect(dry.toLowerCase(), anyOf(contains('барьер'), contains('влаг')));
    expect(dry.toLowerCase(), isNot(contains('точного совпадения')));
    final tired = cultAgent.answer('Я устала, нет сил');
    expect(tired.toLowerCase(), contains('инфуз'));
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
    expect(reply, contains('9:00'));
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
    expect(reply.toLowerCase(), contains('запис'));
    expect(reply.toLowerCase(), anyOf(contains('массаж'), contains('«+»'), contains('+')));
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
    final reply = cultAgent.answer('Запиши меня на массаж вечером');
    expect(reply.toLowerCase(), contains('массаж'));
    expect(reply.toLowerCase(), contains('вечер'));
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

  test('Возьму это после рекомендации', () {
    final reply = cultAgent.answer(
      'возьму это',
      lastBot: 'Посмотрела Veil Peptide Serum. Стоит 12 500 ₽.',
    );
    expect(reply.toLowerCase(), contains('veil'));
    expect(reply.toLowerCase(), contains('магазин'));
  });

  test('Хочу живого врача — handoff', () {
    final reply = cultAgent.answer('Хочу живого врача');
    expect(reply.toLowerCase(), anyOf(contains('врач'), contains('чат')));
    expect(reply.toLowerCase(), contains('специалист'));
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
    expect(reply, contains('9:00'));
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

  test('Ты робот — отвечает про CULT Агент', () {
    final reply = cultAgent.answer('ты робот?');
    expect(reply.toLowerCase(), contains('cult'));
    expect(reply.toLowerCase(), anyOf(contains('агент'), contains('помощ')));
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
    expect(reply.toLowerCase(), contains('хорошо'));
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

  test('Старое приветствие бота обновляется на CULT Агент', () async {
    SharedPreferences.setMockInitialValues({
      'cult-flutter':
          '{"threads":{"bot":[{"id":"old","from":"them","text":"Я ассистент CULT. Спросите про услуги."}]},"chatRead":{"bot":"old"},"cart":[],"appointments":[],"orders":[],"gifts":[],"favorites":[],"spent":0,"welcomeBonus":0,"welcomeGranted":false,"notices":{},"profileName":"","profilePhone":"","profileEmail":""}',
    });
    final store = ClinicStore();
    await store.load();
    final bot = store.threads['bot']!;
    expect(bot.length, 1);
    expect(bot.first.text, contains('CULT'));
    expect(bot.first.text, contains('Голос'));
    expect(bot.first.text.toLowerCase(), contains('поговорить'));
  });
}
