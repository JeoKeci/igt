import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:igt_masraf_takip/services/lookup_service.dart';
import 'package:igt_masraf_takip/models/kategori.dart';
import 'package:igt_masraf_takip/models/odeme_sekli.dart';
import 'package:igt_masraf_takip/models/proje.dart';
import 'package:igt_masraf_takip/models/bolum.dart';

/// Lookup servisi provider'ı
final lookupServiceProvider = Provider<LookupService>(
  (ref) => LookupService(),
);

/// Kategoriler provider'ı
final kategorilerProvider = FutureProvider<List<Kategori>>((ref) async {
  final service = ref.watch(lookupServiceProvider);
  return service.getKategoriler();
});

/// Ödeme şekilleri provider'ı
final odemeSekilleriProvider = FutureProvider<List<OdemeSekli>>((ref) async {
  final service = ref.watch(lookupServiceProvider);
  return service.getOdemeSekilleri();
});

/// Projeler provider'ı (sadece aktif projeler)
final projelerProvider = FutureProvider<List<Proje>>((ref) async {
  final service = ref.watch(lookupServiceProvider);
  return service.getProjeler();
});

/// Bölümler provider'ı
final bolumlerProvider = FutureProvider<List<Bolum>>((ref) async {
  final service = ref.watch(lookupServiceProvider);
  return service.getBolumler();
});
