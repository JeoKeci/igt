import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:igt_masraf_takip/providers/harcama_provider.dart';

/// Aylık özet provider'ı — seçili ayın özet verilerini getirir
final ozetProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(harcamaServiceProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  return service.getOzet(ay: selectedMonth);
});
