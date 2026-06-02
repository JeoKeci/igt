import 'package:igt_masraf_takip/utils/formatters.dart';

/// Zorunlu alan doğrulaması
String? zorunluAlan(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Bu alan zorunludur';
  }
  return null;
}

/// Tutar doğrulaması: zorunlu, pozitif sayı olmalı
/// Türkçe format desteği: "1.500,75" → 1500.75
String? tutarValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Tutar giriniz';
  }
  final parsed = sayiParse(value);
  if (parsed == null) {
    return 'Geçerli bir sayı giriniz (örn: 1.500,75)';
  }
  if (parsed <= 0) {
    return 'Tutar sıfırdan büyük olmalıdır';
  }
  return null;
}

/// KDV doğrulaması: 0 veya pozitif, tutar değerinden büyük olamaz
/// Türkçe format desteği: "250,50" → 250.50
String? kdvValidator(String? value, String? tutarStr) {
  if (value == null || value.trim().isEmpty) {
    return 'KDV giriniz';
  }
  final kdv = sayiParse(value);
  if (kdv == null) {
    return 'Geçerli bir sayı giriniz (örn: 250,50)';
  }
  if (kdv < 0) {
    return 'KDV negatif olamaz';
  }
  if (tutarStr != null && tutarStr.trim().isNotEmpty) {
    final tutar = sayiParse(tutarStr);
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
