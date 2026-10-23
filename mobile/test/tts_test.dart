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
    expect(spoken, isNot(contains('·')));
    expect(spoken, isNot(contains('₽')));
  });

  test('speechChunks не рвёт короткую фразу', () {
    const line = 'Здравствуйте. Я консультант культ.';
    expect(CultTts.speechChunks(line), hasLength(1));
  });

  test('spokenGreeting короткий для озвучки', () {
    expect(CultTts.spokenGreeting.length, lessThan(120));
    expect(CultTts.spokenGreeting.toLowerCase(), contains('здравствуйте'));
  });
}
