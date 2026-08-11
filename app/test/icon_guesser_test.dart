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

    test('first match wins when a name contains multiple keywords', () {
      // "trash" sits earlier than "recycle" in the keyword map, so it wins
      // even though both keywords appear in the name.
      expect(guessChoreEmoji('Take Out Trash and Recycling'), equals('🗑️'));
    });
  });
}
