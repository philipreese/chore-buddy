/// Household chore-name -> emoji guesser (spec 23). Pure and
/// presentation-free so both the editor's live prefill and the card/widget
/// fallback chain can share one source of truth.
///
/// Case-insensitive, first-match-wins scan over [_keywordEmojis]. Matching
/// is word-ish, not substring: a keyword only matches a whole word token (or
/// that token's simple singular, e.g. "plants" -> "plant"), so "car" fires
/// on "Change Car Oil" but never on "Vacuum the carpet".
library;

const List<(String keyword, String emoji)> _keywordEmojis = [
  ('trash', '🗑️'),
  ('garbage', '🗑️'),
  ('recycle', '♻️'),
  ('recycling', '♻️'),
  ('compost', '🍂'),
  ('dish', '🍽️'),
  ('kitchen', '🍽️'),
  ('plant', '🪴'),
  ('water', '🪴'),
  ('litter', '🐈'),
  ('cat', '🐈'),
  ('dog', '🐕'),
  ('walk', '🐕'),
  ('laundry', '🧺'),
  ('clothes', '🧺'),
  ('sheet', '🛏️'),
  ('sheets', '🛏️'),
  ('bed', '🛏️'),
  ('vacuum', '🧹'),
  ('sweep', '🧹'),
  ('mop', '🧽'),
  ('floor', '🧽'),
  ('bathroom', '🚽'),
  ('toilet', '🚽'),
  ('shower', '🚿'),
  ('window', '🪟'),
  ('dust', '🪶'),
  ('cook', '🍳'),
  ('dinner', '🍳'),
  ('meal', '🍳'),
  ('grocery', '🛒'),
  ('groceries', '🛒'),
  ('shop', '🛒'),
  ('car', '🚗'),
  ('oil', '🚗'),
  ('lawn', '🌱'),
  ('mow', '🌱'),
  ('grass', '🌱'),
  ('garden', '🌻'),
  ('weed', '🌻'),
  ('mail', '📬'),
  ('bill', '💸'),
  ('pay', '💸'),
  ('gym', '💪'),
  ('exercise', '💪'),
  ('workout', '💪'),
  ('med', '💊'),
  ('pill', '💊'),
  ('vitamin', '💊'),
  ('filter', '🌀'),
  ('battery', '🔋'),
  ('smoke', '🔋'),
  ('fridge', '🧊'),
  ('refrigerator', '🧊'),
  ('freezer', '🧊'),
  ('oven', '🔥'),
  ('stove', '🔥'),
  ('grill', '🔥'),
  ('fish', '🐠'),
  ('tank', '🐠'),
  ('bird', '🦜'),
  ('sink', '🚰'),
  ('gutter', '🏠'),
  ('roof', '🏠'),
];

/// Splits [text] into lowercase word tokens (runs of letters/digits) --
/// keeps keyword matching from crossing word boundaries.
List<String> _wordTokens(String text) {
  return RegExp(
    r'[a-z0-9]+',
  ).allMatches(text.toLowerCase()).map((m) => m[0]!).toList();
}

/// A token and its simple singular form (plants -> plant, batteries ->
/// battery), so a plural typed by the user still matches a singular keyword
/// without resorting to substring matching.
Iterable<String> _tokenForms(String token) sync* {
  yield token;
  if (token.length > 4 && token.endsWith('ies')) {
    yield '${token.substring(0, token.length - 3)}y';
  } else if (token.length > 4 && token.endsWith('es')) {
    yield token.substring(0, token.length - 2);
  } else if (token.length > 3 && !token.endsWith('ss')) {
    if (token.endsWith('s')) yield token.substring(0, token.length - 1);
  }
}

/// Guesses an emoji for a chore named [name] from a household-chore keyword
/// map, or `null` if nothing matches.
String? guessChoreEmoji(String name) {
  final tokens = _wordTokens(name);
  if (tokens.isEmpty) return null;

  final forms = tokens.expand(_tokenForms).toSet();

  for (final (keyword, emoji) in _keywordEmojis) {
    if (forms.contains(keyword)) {
      return emoji;
    }
  }
  return null;
}
