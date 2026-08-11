/// Finds a free name for a duplicated chore: `"$baseName II"`, then `III`,
/// `IV`, ... until [nameExists] reports the candidate is free. Starts at II
/// since [baseName] itself is already taken by the chore being duplicated.
Future<String> uniqueDuplicateName(
  String baseName,
  Future<bool> Function(String candidate) nameExists,
) async {
  var n = 2;
  while (true) {
    final candidate = '$baseName ${_toRoman(n)}';
    if (!await nameExists(candidate)) {
      return candidate;
    }
    n++;
  }
}

const _romanValues = [10, 9, 5, 4, 1];
const _romanSymbols = ['X', 'IX', 'V', 'IV', 'I'];

/// Converts a positive integer to a Roman numeral. Only ever called with
/// small suffix counters here, so it need not handle values beyond a
/// realistic number of duplicates (thousands place and up are unsupported).
String _toRoman(int n) {
  final buffer = StringBuffer();
  var remaining = n;
  for (var i = 0; i < _romanValues.length; i++) {
    while (remaining >= _romanValues[i]) {
      buffer.write(_romanSymbols[i]);
      remaining -= _romanValues[i];
    }
  }
  return buffer.toString();
}
