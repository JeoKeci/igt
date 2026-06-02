import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:igt_masraf_takip/services/harcama_service.dart';
import 'package:igt_masraf_takip/models/harcama.dart';
import 'package:igt_masraf_takip/providers/auth_provider.dart';

/// Harcama servisi provider'ı
final harcamaServiceProvider = Provider<HarcamaService>(
  (ref) => HarcamaService(),
);

/// Seçili ay provider'ı (varsayılan: mevcut ay)
final selectedMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

/// Seçili ay için harcamalar
final harcamalarProvider = FutureProvider<List<Harcama>>((ref) async {
  final service = ref.watch(harcamaServiceProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final personel = ref.watch(currentPersonelProvider).value;

  String? pId;
  if (personel != null && personel.isSaha) {
    pId = personel.id;
  }

  return service.getHarcamalar(ay: selectedMonth, personelId: pId);
});

// ─── FİLTRE PROVİDER'LAR ────────────────────────────────────

/// Kategori filtresi
final selectedKategoriFilterProvider = StateProvider<String?>((ref) => null);

/// Ödeme şekli filtresi
final selectedOdemeFilterProvider = StateProvider<String?>((ref) => null);

/// Proje filtresi
final selectedProjeFilterProvider = StateProvider<String?>((ref) => null);

/// Personel filtresi
final selectedPersonelFilterProvider = StateProvider<String?>((ref) => null);

/// Filtrelenmiş harcamalar — lokal filtreleme uygular
final filteredHarcamalarProvider = Provider<AsyncValue<List<Harcama>>>((ref) {
  final harcamalarAsync = ref.watch(harcamalarProvider);
  final kategoriFilter = ref.watch(selectedKategoriFilterProvider);
  final odemeFilter = ref.watch(selectedOdemeFilterProvider);
  final projeFilter = ref.watch(selectedProjeFilterProvider);
  final personelFilter = ref.watch(selectedPersonelFilterProvider);

  return harcamalarAsync.whenData((harcamalar) {
    var filtered = harcamalar;

    if (kategoriFilter != null) {
      filtered = filtered
          .where((h) => h.kategoriId == kategoriFilter)
          .toList();
    }

    if (odemeFilter != null) {
      filtered = filtered
          .where((h) => h.odemeSekliId == odemeFilter)
          .toList();
    }

    if (projeFilter != null) {
      filtered = filtered
          .where((h) => h.projeId == projeFilter)
          .toList();
    }

    if (personelFilter != null) {
      filtered = filtered
          .where((h) => h.personelId == personelFilter)
          .toList();
    }

    return filtered;
  });
});
