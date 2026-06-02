import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:igt_masraf_takip/services/personel_service.dart';
import 'package:igt_masraf_takip/models/personel.dart';
import 'package:igt_masraf_takip/models/is_avansi.dart';
import 'package:igt_masraf_takip/models/maas_avansi.dart';

/// Personel servisi provider'ı
final personelServiceProvider = Provider<PersonelService>(
  (ref) => PersonelService(),
);

/// Tüm personeller
final personellerProvider = FutureProvider<List<Personel>>((ref) async {
  return ref.watch(personelServiceProvider).getPersoneller();
});

/// Personel arama filtresi (Query)
final personelAramaQueryProvider = StateProvider<String>((ref) => '');

/// Personel aktiflik filtresi (true = sadece aktifler, false = sadece pasifler, null = hepsi)
final personelFiltreAktifProvider = StateProvider<bool?>((ref) => true);

/// Filtrelenmiş personel listesi
final filteredPersonellerProvider = Provider<AsyncValue<List<Personel>>>((ref) {
  final personellerAsync = ref.watch(personellerProvider);
  final query = ref.watch(personelAramaQueryProvider).trim().toLowerCase();
  final aktifFiltre = ref.watch(personelFiltreAktifProvider);

  return personellerAsync.whenData((list) {
    return list.where((p) {
      // Aktiflik filtresi
      if (aktifFiltre != null && p.aktif != aktifFiltre) {
        return false;
      }
      // Arama filtresi
      if (query.isNotEmpty) {
        final adSoyadMatch = p.adSoyad.toLowerCase().contains(query);
        final epostaMatch = p.eposta.toLowerCase().contains(query);
        final unvanMatch = p.gorevUnvan?.toLowerCase().contains(query) ?? false;
        final bolumMatch = p.bolumAdi?.toLowerCase().contains(query) ?? false;
        return adSoyadMatch || epostaMatch || unvanMatch || bolumMatch;
      }
      return true;
    }).toList();
  });
});

/// Personel detayları
final personelDetayProvider = FutureProvider.family<Personel, String>((ref, id) async {
  return ref.watch(personelServiceProvider).getPersonel(id);
});

/// Personelin maaş avansları listesi
final maasAvanslariProvider = FutureProvider.family<List<MaasAvansi>, String>((ref, id) async {
  return ref.watch(personelServiceProvider).getMaasAvanslari(id);
});

/// Personelin iş avansları listesi
final isAvanslariProvider = FutureProvider.family<List<IsAvansi>, String>((ref, id) async {
  return ref.watch(personelServiceProvider).getIsAvanslari(id);
});

/// Personel finansal özeti (Avans bakiyesi ve akış listesi)
final personelFinansalOzetProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.watch(personelServiceProvider).getPersonelFinansalOzet(id);
});
