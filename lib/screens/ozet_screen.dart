import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/harcama_provider.dart';
import '../providers/ozet_provider.dart';
import '../widgets/ay_secici.dart';
import '../widgets/loading_widget.dart';
import '../utils/formatters.dart';

class OzetScreen extends ConsumerWidget {
  const OzetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final ozetAsync = ref.watch(ozetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aylık Özet'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: AySecici(
              selectedMonth: selectedMonth,
              onChanged: (newMonth) {
                ref.read(selectedMonthProvider.notifier).state = newMonth;
              },
            ),
          ),
        ),
      ),
      body: ozetAsync.when(
        data: (ozet) {
          final toplamTutar = ozet['toplamTutar'] as double;
          final toplamKdv = ozet['toplamKdv'] as double;
          final toplamMatrah = ozet['toplamMatrah'] as double;
          final odemeSekliKirilim = ozet['odemeSekliKirilim'] as List<dynamic>? ?? [];
          final kategoriKirilim = ozet['kategoriKirilim'] as List<dynamic>? ?? [];
          final kisiKirilim = ozet['kisiKirilim'] as List<dynamic>? ?? [];

          if (toplamTutar == 0) {
            return const EmptyWidget(
              icon: Icons.pie_chart_outline,
              message: 'Bu ay için özet veri bulunmuyor.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGenelToplamCard(context, toplamTutar, toplamKdv, toplamMatrah),
                const SizedBox(height: 16),
                if (odemeSekliKirilim.isNotEmpty)
                  _buildKirilimCard(context, 'Ödeme Şekline Göre', odemeSekliKirilim, Icons.payment),
                const SizedBox(height: 16),
                if (kategoriKirilim.isNotEmpty)
                  _buildKirilimCard(context, 'Kategoriye Göre', kategoriKirilim, Icons.category),
                const SizedBox(height: 16),
                if (kisiKirilim.isNotEmpty)
                  _buildKirilimCard(context, 'Kişiye Göre', kisiKirilim, Icons.person),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Özet yükleniyor...'),
        error: (e, s) => IgtErrorWidget(
          message: 'Özet alınırken hata oluştu: $e',
          onRetry: () => ref.refresh(ozetProvider),
        ),
      ),
    );
  }

  Widget _buildGenelToplamCard(BuildContext context, double tutar, double kdv, double matrah) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Aylık Genel Toplam',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 32),
            _buildToplamRow(context, 'Toplam Matrah', matrah, colorScheme.onSurface),
            const SizedBox(height: 12),
            _buildToplamRow(context, 'Toplam KDV', kdv, colorScheme.onSurface),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildToplamRow(context, 'Toplam Tutar', tutar, colorScheme.primary, isLarge: true),
          ],
        ),
      ),
    );
  }

  Widget _buildToplamRow(BuildContext context, String label, double amount, Color valueColor, {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          tutarFormat(amount),
          style: isLarge 
            ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: valueColor)
            : Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildKirilimCard(BuildContext context, String title, List<dynamic> data, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...data.map((item) {
              final ad = item['ad'] as String? ?? '-';
              final toplam = (item['toplam'] as num).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ad,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      tutarFormat(toplam),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
