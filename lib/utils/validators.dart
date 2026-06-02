/// Zorunlu alan doğrulaması
String? zorunluAlan(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Bu alan zorunludur';
  }
  return null;
}

/// Tutar doğrulaması: zorunlu, pozitif sayı olmalı
String? tutarValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Tutar giriniz';
  }
  // Türkçe format desteği: virgülü noktaya çevir
  final normalized = value.replaceAll('.', '').replaceAll(',', '.');
  final parsed = double.tryParse(normalized);
  if (parsed == null) {
    return 'Geçerli bir sayı giriniz';
  }
  if (parsed <= 0) {
    return 'Tutar sıfırdan büyük olmalıdır';
  }
  return null;
}

/// KDV doğrulaması: 0 veya pozitif, tutar değerinden büyük olamaz
String? kdvValidator(String? value, String? tutarStr) {
  if (value == null || value.trim().isEmpty) {
    return 'KDV giriniz';
  }
  final normalizedKdv = value.replaceAll('.', '').replaceAll(',', '.');
  final kdv = double.tryParse(normalizedKdv);
  if (kdv == null) {
    return 'Geçerli bir sayı giriniz';
  }
  if (kdv < 0) {
    return 'KDV negatif olamaz';
  }
  if (tutarStr != null && tutarStr.trim().isNotEmpty) {
    final normalizedTutar = tutarStr.replaceAll('.', '').replaceAll(',', '.');
    final tutar = double.tryParse(normalizedTutar);
    if (tutar != null && kdv > tutar) {
      return 'KDV, fiş tutarından büyük olamaz';
    }
  }
  return null;
}

/// E-posta doğrulaması
String? epostaValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'E-posta giriniz';
  }
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Geçerli bir e-posta adresi giriniz';
  }
  return null;
}

/// Şifre doğrulaması: en az 4 karakter
String? sifreValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Şifre giriniz';
  }
  if (value.length < 4) {
    return 'Şifre en az 4 karakter olmalıdır';
  }
  return null;
}
