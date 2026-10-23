import 'package:cult_clinic/tts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forSpeech произносит бренды по-русски и убирает каталожные знаки', () {
    final spoken = CultTts.forSpeech(
      'Veil Peptide Serum · 14 200 ₽\nЕсть NAD+ и RF.',
    );
    expect(spoken.toLowerCase(), contains('вейл'));
    expect(spoken.toLowerCase(), contains('эн эй ди'));
    expect(spoken.toLowerCase(), contains('эр эф'));
    expect(spoken, contains('рублей'));
    expect(spoken.toLowerCase(), contains('тысяч'));
    expect(spoken, isNot(contains('·')));
    expect(spoken, isNot(contains('₽')));
  });

  test('speechChunks не рвёт короткую фразу', () {
    const line = 'Здравствуйте. Я консультант культ.';
    expect(CultTts.speechChunks(line), hasLength(1));
  });

  test('spokenGreeting короткий для озвучки', () {
    expect(CultTts.spokenGreeting.length, lessThan(160));
    expect(CultTts.spokenGreeting.toLowerCase(), contains('здравствуйте'));
    expect(CultTts.spokenGreeting.toLowerCase(), contains('кнопк'));
  });

  test('toSpokenBrief complete договаривает длинный ответ', () {
    final long = List.filled(
      10,
      'Это отдельное предложение про массаж, уход и запись через плюс.',
    ).join(' ');
    final brief = CultTts.toSpokenBrief(long, maxLen: 220);
    final full = CultTts.toSpokenBrief(long, maxLen: 900, complete: true);
    expect(full.length, greaterThan(brief.length));
    expect(full.toLowerCase(), contains('массаж'));
  });

  test('toSpokenBrief сжимает длинный каталожный ответ', () {
    final long =
        List.filled(8, 'Это длинное предложение про услугу и уход.').join(' ');
    final brief = CultTts.toSpokenBrief(long);
    expect(brief.length, lessThan(long.length));
    expect(brief.length, lessThanOrEqualTo(320));
    expect(brief.toLowerCase(), contains('длинное'));
  });

  test('humanize смягчает канцелярит для озвучки', () {
    final h = CultTts.humanize('Обратите внимание на крем. Ориентир по цене — 100.');
    expect(h.toLowerCase(), contains('посмотрите'));
    expect(h.toLowerCase(), contains('стоит примерно'));
  });

  test('humanize смягчает новые фразы агента', () {
    final h = CultTts.humanize(
      'Если правильно поняла запрос — вот ближайшее. По услуге «RF». 1) осмотр. 2) уход.',
    );
    expect(h.toLowerCase(), contains('правильно поняла'));
    expect(h.toLowerCase(), contains('по процедуре'));
    expect(h.toLowerCase(), contains('во-первых'));
  });

  test('toSpokenBrief убирает мягкий хвост каталога', () {
    final brief = CultTts.toSpokenBrief(
      'Если правильно поняла запрос — вот ближайшее. '
      'Посмотрела Veil Peptide Serum. Стоит 12 500 ₽. '
      'Если мимо — скажите «не то» или уточните название.',
    );
    expect(brief.toLowerCase(), contains('вейл'));
    expect(brief.toLowerCase(), isNot(contains('мимо')));
    expect(brief.length, lessThan(220));
  });

  test('toSpokenBrief tight короче обычного', () {
    final long =
        '${List.filled(6, 'Это предложение про массаж и запись через плюс.').join(' ')} '
        'Стоит примерно 18 тысяч рублей.';
    final normal = CultTts.toSpokenBrief(long);
    final tight = CultTts.toSpokenBrief(long, maxLen: 170);
    expect(tight.length, lessThanOrEqualTo(normal.length));
    expect(tight.length, lessThanOrEqualTo(200));
  });

  test('breathGroups дробит длинную фразу', () {
    final words = List.filled(24, 'слово').join(' ');
    final groups = CultTts.breathGroups(words);
    expect(groups.length, greaterThan(1));
  });
}
