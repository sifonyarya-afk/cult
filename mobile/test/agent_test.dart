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
