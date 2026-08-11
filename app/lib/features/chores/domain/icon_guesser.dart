/// Household chore-name -> emoji guesser (spec 23). Pure and
/// presentation-free so both the editor's live prefill and the card/widget
/// fallback chain can share one source of truth.
///
/// Case-insensitive. Matching is word-ish, not substring: a keyword only
/// matches a whole word token (or that token's simple singular, e.g.
/// "plants" -> "plant"), so "car" fires on "Change Car Oil" but never on
/// "Vacuum the carpet". Priority is by the matching token's POSITION in the
/// name, earliest wins -- not [_keywordEmojis]' declaration order (review B
/// / N10, spec 27): "Water the dog" guesses the plant emoji, not the dog
/// one, because "water" is the first word that matches anything. Declaration
/// order in [_keywordEmojis] only breaks a tie between two keywords that
/// both match forms of the very same token.
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

/// The 48 icons offered by the chore editor's picker grid (spec 24), 6 per
/// row. Every emoji [_keywordEmojis] can guess is drawn from this same set,
/// so a name-based guess always lands on something the user could also have
/// picked by hand.
const List<String> curatedChoreIcons = [
  '🗑️', '♻️', '🍂', '🍽️', '🪴', '🐈', '🐕', '🧺',
  '🛏️', '🧹', '🧽', '🚽', '🚿', '🪟', '🪶', '🍳',
  '🛒', '🚗', '🌱', '🌻', '📬', '💸', '💪', '💊',
  '🌀', '🔋', '🧊', '🔥', '🐠', '🦜', '🚰', '🏠',
  '🧴', '🧼', '🪣', '🧯', '🔧', '🛠️', '💡', '🧻',
  '🚪', '🪑', '🛋️', '📦', '🧦', '🧸', '📚', '🚲',
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
/// map, or `null` if nothing matches. Walks [name]'s tokens in order --
/// earliest position wins -- and for each token scans [_keywordEmojis] in
/// declaration order to find any keyword matching one of that token's forms.
String? guessChoreEmoji(String name) {
  final tokens = _wordTokens(name);

  for (final token in tokens) {
    final forms = _tokenForms(token).toSet();
    for (final (keyword, emoji) in _keywordEmojis) {
      if (forms.contains(keyword)) {
        return emoji;
      }
    }
  }
  return null;
}
