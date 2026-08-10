String formatDateTime(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final month = months[dt.month - 1];
  final day = dt.day.toString().padLeft(2, '0');
  final year = dt.year;
  final hourNum = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
  final hour = hourNum.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$month $day, $year @ $hour:$minute $ampm';
}

String formatChoreDate(DateTime? dt) {
  if (dt == null) return '';
  return formatDateTime(dt);
}
