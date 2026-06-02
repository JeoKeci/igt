import 'package:intl/intl.dart';

/// Türkçe biçimli metni ("1.500,75") sayıya çevirir.
/// Binlik ayraç olarak nokta, ondalık ayraç olarak virgül kabul eder.
/// Geçersizse null döner.
double? sayiParse(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  // Önce binlik ayıracı (noktaları) sil, sonra ondalık virgülü noktaya çevir
  final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalized);
}

/// Para birimi formatı: ₺ 1.234,56
String tutarFormat(double value) {
  final formatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );
  return formatter.format(value);
}

/// Tarih formatı: 31.05.2026
String tarihFormat(DateTime date) {
  final formatter = DateFormat('dd.MM.yyyy', 'tr_TR');
  return formatter.format(date);
}

/// Kısa tarih formatı: 31 May
String tarihFormatKisa(DateTime date) {
  final formatter = DateFormat('dd MMM', 'tr_TR');
  return formatter.format(date);
}

/// Ay-Yıl formatı: Haziran 2026 (ay başlıkları için)
String tarihAyYil(DateTime date) {
  final formatter = DateFormat('MMMM yyyy', 'tr_TR');
  return formatter.format(date);
}

/// Saat formatı: 14:30
String saatFormat(DateTime date) {
  final formatter = DateFormat('HH:mm', 'tr_TR');
  return formatter.format(date);
}

/// Tam tarih-saat formatı: 31.05.2026 14:30
String tarihSaatFormat(DateTime date) {
  final formatter = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
  return formatter.format(date);
}
