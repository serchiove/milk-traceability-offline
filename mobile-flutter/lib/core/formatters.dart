import 'package:intl/intl.dart';

String number(num n, [int decimals = 2]) => NumberFormat.decimalPatternDigits(
  locale: 'es_PE',
  decimalDigits: decimals,
).format(n);

String dateLabel(String raw) {
  final date = DateTime.tryParse(raw);
  return date == null
      ? raw
      : DateFormat('dd/MM/yyyy HH:mm', 'es_PE').format(date.toLocal());
}

String timeLabel(String raw) {
  final date = DateTime.tryParse(raw);
  return date == null
      ? raw
      : DateFormat('hh:mm a', 'es_PE').format(date.toLocal());
}
