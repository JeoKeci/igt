import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/harcama_provider.dart';
import '../providers/ozet_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/harcama_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/ay_secici.dart';
import '../utils/formatters.dart';
import 'harcama_detay_screen.dart';
import 'harcama_ekle_screen.dart';

class HarcamalarScreen extends ConsumerWidget {
  const HarcamalarScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final harcamalarAsyncValue = ref.watch(filteredHarcamalarProvider);
    final personelAsync = ref.watch(currentPersonelProvider);
    final isSaha = personelAsync.value?.isSaha ?? false;

    final Widget bodyContent = harcamalarAsyncValue.when(
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
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcamalar'),
        centerTitle: true,
        actions: [
          if (isSaha)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _handleLogout(context),
              tooltip: 'Çıkış Yap',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AySecici(
              selectedMonth: selectedMonth,
              onChanged: (newMonth) {
                ref.read(selectedMonthProvider.notifier).state = newMonth;
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          bodyContent,
          // Yandan Açılır İnce Çubuk (Side Handle)
          Positioned(
            right: 0,
            bottom: 120, // Özet barının üstünde kalsın
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  Scaffold.of(context).openEndDrawer();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(-2, 0),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.onPrimary),
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'Ekle',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      endDrawer: const Drawer(
        width: 380, // Telefondaysa ~tam ekran, tabletteyse sağda 380px kaplar
        child: HarcamaEkleScreen(),
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
