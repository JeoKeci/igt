import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/harcama.dart';
import '../providers/harcama_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/formatters.dart';

class HarcamaDetayScreen extends ConsumerWidget {
  final Harcama harcama;

  const HarcamaDetayScreen({
    super.key,
    required this.harcama,
  });

  Future<void> _handleIptal(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İptal Et'),
        content: const Text('Bu harcamayı iptal etmek istediğinize emin misiniz?'),
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
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final service = ref.read(harcamaServiceProvider);
        await service.cancelHarcama(harcama.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Harcama iptal edildi.')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata oluştu: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final currentPersonelAsync = ref.watch(currentPersonelProvider);
    final currentPersonelId = currentPersonelAsync.value?.id;
    final isOwnRecord = harcama.personelId == currentPersonelId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcama Detayı'),
        actions: [
          if (isOwnRecord) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: colorScheme.error,
              onPressed: () => _handleIptal(context, ref),
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(context, 'Firma', harcama.firma, isLarge: true),
                    const Divider(height: 32),
                    _buildDetailRow(context, 'Tarih', tarihFormat(harcama.tarih)),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Kategori', harcama.kategoriAdi ?? '-'),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Ödeme Şekli', harcama.odemeSekliAdi ?? '-'),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Personel', harcama.personelAdi ?? '-'),
                    
                    if (harcama.projeAdi != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(context, 'Proje', harcama.projeAdi!),
                    ],
                    
                    if (harcama.fisNo?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(context, 'Fiş/Fatura No', harcama.fisNo!),
                    ],
                    
                    if (harcama.plakaStok?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(context, 'Plaka/Stok', harcama.plakaStok!),
                    ],
                    
                    if (harcama.aciklama?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Açıklama',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(harcama.aciklama!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildFinancialRow(context, 'Matrah', harcama.hesaplananMatrah),
                    const SizedBox(height: 8),
                    _buildFinancialRow(context, 'KDV', harcama.kdv),
                    const Divider(height: 24),
                    _buildFinancialRow(context, 'Toplam Tutar', harcama.fisTutari, isTotal: true),
                  ],
                ),
              ),
            ),
            if (harcama.belgeUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Fiş Fotoğrafı',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: harcama.belgeUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => const SizedBox(
                          height: 100,
                          child: Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isLarge = false}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: isLarge
                ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialRow(BuildContext context, String label, double amount, {bool isTotal = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          tutarFormat(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
