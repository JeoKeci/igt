import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:igt_masraf_takip/providers/auth_provider.dart';

/// Aylık özet provider'ı — seçili ayın özet verilerini getirir
final ozetProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(harcamaServiceProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final personel = ref.watch(currentPersonelProvider).value;

  String? pId;
  if (personel != null && personel.isSaha) {
    pId = personel.id;
  }

  return service.getOzet(ay: selectedMonth, personelId: pId);
});
