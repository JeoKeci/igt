import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/harcama_provider.dart';
import '../providers/ozet_provider.dart';
import '../widgets/harcama_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/ay_secici.dart';
import '../utils/formatters.dart';
import 'harcama_detay_screen.dart';
import 'harcama_ekle_screen.dart';

class HarcamalarScreen extends ConsumerWidget {
  const HarcamalarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final harcamalarAsyncValue = ref.watch(filteredHarcamalarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcamalar'),
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
      body: harcamalarAsyncValue.when(
        data: (harcamalar) {
          if (harcamalar.isEmpty) {
            return const EmptyWidget(
              icon: Icons.receipt_long_outlined,
              message: 'Bu ay için harcama bulunmuyor.',
            );
          }

          double toplamTutar = 0;
          double toplamKdv = 0;
          double toplamMatrah = 0;

          for (final h in harcamalar) {
            toplamTutar += h.fisTutari;
            toplamKdv += h.kdv;
            toplamMatrah += h.hesaplananMatrah;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: harcamalar.length,
                  itemBuilder: (context, index) {
                    final harcama = harcamalar[index];
                    return HarcamaCard(
                      harcama: harcama,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HarcamaDetayScreen(harcama: harcama),
                          ),
                        ).then((_) {
                          // Detaydan dönünce yenile
                          ref.invalidate(harcamalarProvider);
                        });
                      },
                    );
                  },
                ),
              ),
              _buildSummaryBar(context, toplamTutar, toplamKdv, toplamMatrah),
            ],
          );
        },
        loading: () => const LoadingWidget(message: 'Harcamalar yükleniyor...'),
        error: (error, stack) => IgtErrorWidget(
          message: 'Harcamalar yüklenirken hata oluştu: $error',
          onRetry: () => ref.refresh(harcamalarProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const HarcamaEkleScreen()),
          );
          ref.invalidate(harcamalarProvider);
          ref.invalidate(ozetProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context, double tutar, double kdv, double matrah) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryColumn(context, 'Matrah', matrah, colorScheme.onSurfaceVariant),
            _buildSummaryColumn(context, 'KDV', kdv, colorScheme.onSurfaceVariant),
            _buildSummaryColumn(context, 'Toplam', tutar, colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(BuildContext context, String label, double amount, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tutarFormat(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
