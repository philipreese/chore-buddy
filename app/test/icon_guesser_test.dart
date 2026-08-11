import 'package:chorebuddy/features/chores/domain/icon_guesser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guessChoreEmoji', () {
    test('matches a direct keyword hit', () {
      expect(guessChoreEmoji('Take Out Trash'), equals('🗑️'));
    });

    test('is case-insensitive', () {
      expect(guessChoreEmoji('TAKE OUT TRASH'), equals('🗑️'));
      expect(guessChoreEmoji('take out trash'), equals('🗑️'));
    });

    test('matches a plural noun against its singular keyword', () {
      expect(guessChoreEmoji('Water Plants'), equals('🪴'));
      expect(guessChoreEmoji('Replace Batteries'), equals('🔋'));
    });

    test('matches any keyword in the chore name, not just the first word',
        () {
      expect(guessChoreEmoji('Weekly Mow'), equals('🌱'));
    });

    test('returns null for a chore name with no known keyword', () {
      expect(guessChoreEmoji('Sharpen Pencils'), isNull);
    });

    test('returns null for an empty name', () {
      expect(guessChoreEmoji(''), isNull);
    });

    test('word-boundary: "car" does not fire inside "carpet"', () {
      expect(guessChoreEmoji('Vacuum the Carpet'), equals('🧹'));
      expect(guessChoreEmoji('Clean Carpet'), isNull);
    });

    test('word-boundary: a real "car" chore still matches', () {
      expect(guessChoreEmoji('Change Car Oil'), equals('🚗'));
      expect(guessChoreEmoji('Wash the Car'), equals('🚗'));
    });

    test(
        'the earliest matching token in the NAME wins, not the earliest '
        'entry in the keyword map (review B / N10)', () {
      // "trash" is both earlier in the name and earlier in the keyword map
      // than "recycle" here, so this alone doesn't distinguish the two
      // rules -- kept as a baseline sanity check.
      expect(guessChoreEmoji('Take Out Trash and Recycling'), equals('🗑️'));

      // "roof" is declared near the END of the keyword map, well after
      // "trash" (declared first) -- but "roof" is the first word in this
      // name. A map-declaration-order scan would find "trash" first and
      // return the wrong glyph; the fix scans the name's tokens in order
      // and stops at the first one that has ANY match.
      expect(guessChoreEmoji('Roof and Trash'), equals('🏠'));
    });

    test(
        '"Water the dog" guesses by the first word that matches anything, '
        'not by what a human would consider the "main" word', () {
      // "water" is the first word in the name and matches a keyword
      // ("water" -> the plant glyph), so it wins even though "dog" reads as
      // the more obviously relevant word to a person.
      expect(guessChoreEmoji('Water the Dog'), equals('🪴'));
    });
  });
}
