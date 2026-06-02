import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/harcama_provider.dart';
import '../providers/ozet_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/ay_secici.dart';
import '../widgets/loading_widget.dart';
import '../utils/formatters.dart';
import '../services/excel_export_service.dart';

class OzetScreen extends ConsumerStatefulWidget {
  const OzetScreen({super.key});

  @override
  ConsumerState<OzetScreen> createState() => _OzetScreenState();
}

class _OzetScreenState extends ConsumerState<OzetScreen> {
  bool _excelYukleniyor = false;

  Future<void> _excelIndir() async {
    final ay = ref.read(selectedMonthProvider);
    setState(() => _excelYukleniyor = true);
    try {
      await ExcelExportService().exportVePaylas(ay);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel oluşturulurken hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _excelYukleniyor = false);
    }
  }

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
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final ozetAsync = ref.watch(ozetProvider);
    final personelAsync = ref.watch(currentPersonelProvider);
    final isSaha = personelAsync.value?.isSaha ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aylık Özet'),
        actions: [
          if (isSaha)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _handleLogout(context),
              tooltip: 'Çıkış Yap',
            ),
          _excelYukleniyor
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.table_chart_outlined),
                  tooltip: 'Excel İndir',
                  onPressed: _excelIndir,
                ),
        ],
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
