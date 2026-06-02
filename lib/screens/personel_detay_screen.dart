import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igt_masraf_takip/models/personel.dart';
import 'package:igt_masraf_takip/models/maas_avansi.dart';
import 'package:igt_masraf_takip/models/is_avansi.dart';
import 'package:igt_masraf_takip/models/harcama.dart';
import 'package:igt_masraf_takip/providers/personel_provider.dart';
import 'package:igt_masraf_takip/providers/lookup_provider.dart' hide personellerProvider;
import 'package:igt_masraf_takip/providers/harcama_provider.dart';
import 'package:igt_masraf_takip/screens/harcama_detay_screen.dart';
import 'package:igt_masraf_takip/widgets/loading_widget.dart';
import 'package:igt_masraf_takip/utils/formatters.dart';
import 'package:igt_masraf_takip/utils/validators.dart';

class PersonelDetayScreen extends ConsumerWidget {
  final String personelId;

  const PersonelDetayScreen({super.key, required this.personelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personelAsync = ref.watch(personelDetayProvider(personelId));

    return personelAsync.when(
      data: (p) => _PersonelDetayIcerik(p: p),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Personel Detayı')),
        body: const LoadingWidget(message: 'Personel bilgileri yükleniyor...'),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Personel Detayı')),
        body: IgtErrorWidget(
          message: 'Hata oluştu: ${err.toString()}',
          onRetry: () => ref.invalidate(personelDetayProvider(personelId)),
        ),
      ),
    );
  }
}

class _PersonelDetayIcerik extends ConsumerStatefulWidget {
  final Personel p;

  const _PersonelDetayIcerik({required this.p});

  @override
  ConsumerState<_PersonelDetayIcerik> createState() => _PersonelDetayIcerikState();
}

class _PersonelDetayIcerikState extends ConsumerState<_PersonelDetayIcerik>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.adSoyad),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Özlük Bilgilerini Düzenle',
            onPressed: () => _showDuzenleBottomSheet(context, ref, p),
          ),
        ],
      ),
      body: Column(
        children: [
          // Üst Profil Özet Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: p.aktif
                      ? colorScheme.primaryContainer
                      : Colors.grey.shade300,
                  child: Text(
                    p.adSoyad.isNotEmpty ? p.adSoyad.substring(0, 1).toUpperCase() : '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: p.aktif
                          ? colorScheme.onPrimaryContainer
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.adSoyad,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4.0),
                      Text(p.eposta, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.aktif
                                  ? colorScheme.primary.withOpacity(0.1)
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              p.aktif ? 'Aktif' : 'Pasif',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: p.aktif
                                    ? colorScheme.primary
                                    : Colors.red.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              p.rol == 'yonetici'
                                  ? 'Yönetici'
                                  : p.rol == 'muhasebe'
                                      ? 'Muhasebe'
                                      : 'Saha Personeli',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Özlük & Maaş'),
              Tab(text: 'Maaş Avansları'),
              Tab(text: 'İş Avansları'),
            ],
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OzlukTab(p: p),
                _MaasAvanslariTab(personelId: p.id),
                _IsAvanslariTab(personelId: p.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Özlük bilgilerini düzenleme formu (Bottom Sheet)
  void _showDuzenleBottomSheet(BuildContext context, WidgetRef ref, Personel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return _PersonelDuzenleForm(p: p);
      },
    );
  }
}

// ─── SEKME 1: ÖZLÜK & MAAŞ TAB ───────────────────────────────────
class _OzlukTab extends StatelessWidget {
  final Personel p;

  const _OzlukTab({required this.p});

  Widget _buildBilgiSatiri(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İletişim & Kişisel
          Text(
            'İletişim & Kişisel Bilgiler',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildBilgiSatiri(context, 'Telefon No', p.telefon ?? '-'),
                  const Divider(),
                  _buildBilgiSatiri(context, 'Kan Grubu', p.kanGrubu ?? '-'),
                  const Divider(),
                  _buildBilgiSatiri(context, 'Acil Durum Kişisi', p.acilDurumKisi ?? '-'),
                  const Divider(),
                  _buildBilgiSatiri(context, 'Acil Durum Telefon', p.acilDurumTelefon ?? '-'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20.0),

          // Görev & İş
          Text(
            'İş & Görev Bilgileri',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildBilgiSatiri(context, 'Görev / Unvan', p.gorevUnvan ?? '-'),
                  const Divider(),
                  _buildBilgiSatiri(context, 'Bölüm', p.bolumAdi ?? '-'),
                  const Divider(),
                  _buildBilgiSatiri(
                    context,
                    'İşe Giriş Tarihi',
                    p.iseGirisTarihi != null ? tarihFormat(p.iseGirisTarihi!) : '-',
                  ),
                  const Divider(),
                  _buildBilgiSatiri(
                    context,
                    'İşten Çıkış Tarihi',
                    p.istenCikisTarihi != null ? tarihFormat(p.istenCikisTarihi!) : '-',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20.0),

          // Finansal
          Text(
            'Maaş & Banka Bilgileri',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildBilgiSatiri(context, 'Güncel Net Maaş', tutarFormat(p.guncelMaas)),
                  const Divider(),
                  _buildBilgiSatiri(context, 'IBAN Numarası', p.iban ?? '-'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SEKME 2: MAAŞ AVANSLARI TAB ─────────────────────────────────
class _MaasAvanslariTab extends ConsumerWidget {
  final String personelId;

  const _MaasAvanslariTab({required this.personelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avansAsync = ref.watch(maasAvanslariProvider(personelId));
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showAddMaasAvansiDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: avansAsync.when(
        data: (avanslar) {
          double toplamAvans = avanslar.fold(0.0, (sum, a) => sum + a.tutar);

          return Column(
            children: [
              // Özet Kartı
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Toplam Maaş Avansı',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      tutarFormat(toplamAvans),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Avans Geçmiş Listesi
              Expanded(
                child: avanslar.isEmpty
                    ? const EmptyWidget(
                        icon: Icons.payments_outlined,
                        message: 'Bu personele ait maaş avansı bulunmuyor.',
                      )
                    : ListView.builder(
                        itemCount: avanslar.length,
                        itemBuilder: (context, index) {
                          final a = avanslar[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            elevation: 0.5,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
                                child: Icon(Icons.payments, color: theme.colorScheme.primary),
                              ),
                              title: Text(
                                tutarFormat(a.tutar),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${tarihFormat(a.tarih)}${a.aciklama != null ? ' - ${a.aciklama}' : ''}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _handleDelete(context, ref, a.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(message: 'Avanslar yükleniyor...'),
        error: (err, _) => IgtErrorWidget(
          message: 'Hata oluştu: $err',
          onRetry: () => ref.invalidate(maasAvanslariProvider(personelId)),
        ),
      ),
    );
  }

  void _showAddMaasAvansiDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _MaasAvansiEkleDialog(personelId: personelId),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, String avansId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avansı Sil'),
        content: const Text('Bu maaş avansı kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(personelServiceProvider).cancelMaasAvansi(avansId);
        ref.invalidate(maasAvanslariProvider(personelId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maaş avansı silindi.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silinemedi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

// ─── SEKME 3: İŞ AVANSLARI TAB ────────────────────────────────────
class _IsAvanslariTab extends ConsumerWidget {
  final String personelId;

  const _IsAvanslariTab({required this.personelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ozetAsync = ref.watch(personelFinansalOzetProvider(personelId));
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _showAddIsAvansiDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: ozetAsync.when(
        data: (ozet) {
          final double toplamAlinan = ozet['toplamAlinan'] ?? 0.0;
          final double toplamHarcanan = ozet['toplamHarcanan'] ?? 0.0;
          final double netBakiye = ozet['netBakiye'] ?? 0.0;
          final List<Map<String, dynamic>> akis = List<Map<String, dynamic>>.from(ozet['akisListesi'] ?? []);

          final isPozitif = netBakiye >= 0;
          final bakiyeColor = isPozitif ? Colors.green.shade700 : Colors.red.shade700;
          final bakiyeBg = isPozitif ? Colors.green.shade50 : Colors.red.shade50;
          final bakiyeTitle = isPozitif ? 'Eldeki İş Avansı' : 'Cebinden Harcanan (Şirket Borcu)';

          return Column(
            children: [
              // Finansal Durum Kartı
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: bakiyeBg,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: bakiyeColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      bakiyeTitle,
                      style: TextStyle(
                        color: bakiyeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      tutarFormat(netBakiye.abs()),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: bakiyeColor,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    const Divider(height: 1),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Toplam Alınan', style: TextStyle(fontSize: 11, color: Colors.black54)),
                            const SizedBox(height: 2),
                            Text(
                              tutarFormat(toplamAlinan),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 24, color: Colors.grey.shade300),
                        Column(
                          children: [
                            const Text('Harcanan (Nakit Avans)', style: TextStyle(fontSize: 11, color: Colors.black54)),
                            const SizedBox(height: 2),
                            Text(
                              tutarFormat(toplamHarcanan),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Akış Günlüğü Başlığı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'İş Avansı Hareketleri',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Akış Günlüğü Listesi
              Expanded(
                child: akis.isEmpty
                    ? const EmptyWidget(
                        icon: Icons.swap_horiz_outlined,
                        message: 'Bu personele ait avans hareketi bulunmuyor.',
                      )
                    : ListView.builder(
                        itemCount: akis.length,
                        itemBuilder: (context, index) {
                          final item = akis[index];
                          final isAvans = item['tip'] == 'avans';
                          final isPoz = item['isPozitif'] as bool;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            elevation: 0.2,
                            child: ListTile(
                              onTap: isAvans
                                  ? null
                                  : () => _openExpenseDetail(context, ref, item['id'] as String),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isPoz
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                                child: Icon(
                                  isPoz ? Icons.arrow_downward : Icons.receipt_long,
                                  color: isPoz ? Colors.green.shade700 : Colors.orange.shade700,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                item['aciklama'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              subtitle: Text(
                                tarihFormat(item['tarih'] as DateTime),
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${isPoz ? "+" : "-"}${tutarFormat(item['tutar'] as double)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPoz ? Colors.green.shade700 : Colors.red.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isAvans) ...[
                                    const SizedBox(width: 8.0),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => _handleDeleteIsAvansi(context, ref, item['id'] as String),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ] else ...[
                                    const Icon(Icons.chevron_right, size: 18),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(message: 'Finansal özet hesaplanıyor...'),
        error: (err, _) => IgtErrorWidget(
          message: 'Hata oluştu: $err',
          onRetry: () => ref.invalidate(personelFinansalOzetProvider(personelId)),
        ),
      ),
    );
  }

  void _showAddIsAvansiDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _IsAvansiEkleDialog(personelId: personelId),
    );
  }

  Future<void> _handleDeleteIsAvansi(BuildContext context, WidgetRef ref, String avansId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İş Avansını Sil'),
        content: const Text('Bu iş avansı gönderimi kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(personelServiceProvider).cancelIsAvansi(avansId);
        ref.invalidate(personelFinansalOzetProvider(personelId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İş avansı silindi.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silinemedi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Akış günlüğündeki harcamaya tıklayınca detayını açma (lazy loading)
  Future<void> _openExpenseDetail(BuildContext context, WidgetRef ref, String harcamaId) async {
    // Yükleme göstergesi göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    try {
      final harcama = await ref.read(harcamaServiceProvider).getHarcamaById(harcamaId);
      if (context.mounted) {
        Navigator.pop(context); // Yükleme dialogunu kapat
      }
      
      if (harcama != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HarcamaDetayScreen(harcama: harcama),
          ),
        );
      } else {
        throw Exception('Harcama kaydı bulunamadı.');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Yükleme dialogunu kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harcama yüklenemedi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ─── ALT DIALOGLAR VE FORMLAR ─────────────────────────────────────

// Personel Düzenleme Formu (Bottom Sheet)
class _PersonelDuzenleForm extends ConsumerStatefulWidget {
  final Personel p;

  const _PersonelDuzenleForm({required this.p});

  @override
  ConsumerState<_PersonelDuzenleForm> createState() => _PersonelDuzenleFormState();
}

class _PersonelDuzenleFormState extends ConsumerState<_PersonelDuzenleForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _telController;
  late TextEditingController _unvanController;
  late TextEditingController _kanController;
  late TextEditingController _acilKisiController;
  late TextEditingController _acilTelController;
  late TextEditingController _maasController;
  late TextEditingController _ibanController;

  String? _selectedBolumId;
  DateTime? _iseGirisTarihi;
  DateTime? _istenCikisTarihi;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.p;
    _telController = TextEditingController(text: p.telefon);
    _unvanController = TextEditingController(text: p.gorevUnvan);
    _kanController = TextEditingController(text: p.kanGrubu);
    _acilKisiController = TextEditingController(text: p.acilDurumKisi);
    _acilTelController = TextEditingController(text: p.acilDurumTelefon);
    _maasController = TextEditingController(text: p.guncelMaas > 0 ? p.guncelMaas.toStringAsFixed(2) : '');
    _ibanController = TextEditingController(text: p.iban);

    _selectedBolumId = p.bolumId;
    _iseGirisTarihi = p.iseGirisTarihi;
    _istenCikisTarihi = p.istenCikisTarihi;
  }

  @override
  void dispose() {
    _telController.dispose();
    _unvanController.dispose();
    _kanController.dispose();
    _acilKisiController.dispose();
    _acilTelController.dispose();
    _maasController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _secIseGirisTarihi() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _iseGirisTarihi ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() {
        _iseGirisTarihi = picked;
      });
    }
  }

  Future<void> _secIstenCikisTarihi() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _istenCikisTarihi ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() {
        _istenCikisTarihi = picked;
      });
    }
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final double maas = double.tryParse(_maasController.text.replaceAll(',', '.')) ?? 0.0;
      final data = {
        'telefon': _telController.text.trim().isEmpty ? null : _telController.text.trim(),
        'gorev_unvan': _unvanController.text.trim().isEmpty ? null : _unvanController.text.trim(),
        'kan_grubu': _kanController.text.trim().isEmpty ? null : _kanController.text.trim(),
        'acil_durum_kisi': _acilKisiController.text.trim().isEmpty ? null : _acilKisiController.text.trim(),
        'acil_durum_telefon': _acilTelController.text.trim().isEmpty ? null : _acilTelController.text.trim(),
        'bolum_id': _selectedBolumId,
        'ise_giris_tarihi': _iseGirisTarihi?.toIso8601String().split('T')[0],
        'isten_cikis_tarihi': _istenCikisTarihi?.toIso8601String().split('T')[0],
        'guncel_maas': maas,
        'iban': _ibanController.text.trim().isEmpty ? null : _ibanController.text.trim(),
      };

      await ref.read(personelServiceProvider).updatePersonel(widget.p.id, data);
      
      ref.invalidate(personelDetayProvider(widget.p.id));
      ref.invalidate(personellerProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Personel bilgileri güncellendi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bolumlerAsync = ref.watch(bolumlerProvider);
    final isKeyboard = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Özlük & Maaş Düzenle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12.0),

              // Unvan & Bölüm
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unvanController,
                      decoration: const InputDecoration(labelText: 'Görev / Unvan', prefixIcon: Icon(Icons.badge)),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: bolumlerAsync.when(
                      data: (bolumler) => DropdownButtonFormField<String?>(
                        value: _selectedBolumId,
                        decoration: const InputDecoration(labelText: 'Bölüm', prefixIcon: Icon(Icons.business)),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Seçilmedi')),
                          ...bolumler.map((b) => DropdownMenuItem<String?>(value: b.id, child: Text(b.ad))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedBolumId = val;
                          });
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Bölümler yüklenemedi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Telefon & Kan Grubu
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _telController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Telefon No', prefixIcon: Icon(Icons.phone)),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: TextFormField(
                      controller: _kanController,
                      decoration: const InputDecoration(labelText: 'Kan Grubu', prefixIcon: Icon(Icons.bloodtype)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Acil Durum İrtibat
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _acilKisiController,
                      decoration: const InputDecoration(labelText: 'Acil Durum Kişisi', prefixIcon: Icon(Icons.contact_phone)),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: TextFormField(
                      controller: _acilTelController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Acil Durum Tel', prefixIcon: Icon(Icons.phone_iphone)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // İşe Giriş & İşten Çıkış Tarihleri
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _secIseGirisTarihi,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'İşe Giriş Tarihi', prefixIcon: Icon(Icons.calendar_today)),
                        child: Text(_iseGirisTarihi != null ? tarihFormat(_iseGirisTarihi!) : 'Seçilmedi'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: InkWell(
                      onTap: _secIstenCikisTarihi,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'İşten Çıkış Tarihi', prefixIcon: Icon(Icons.calendar_today)),
                        child: Text(_istenCikisTarihi != null ? tarihFormat(_istenCikisTarihi!) : 'Seçilmedi'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Net Maaş & IBAN
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maasController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final parsed = double.tryParse(value.replaceAll(',', '.'));
                        if (parsed == null || parsed < 0) return 'Geçerli bir maaş girin';
                        return null;
                      },
                      decoration: const InputDecoration(labelText: 'Net Maaş (TL)', prefixIcon: Icon(Icons.monetization_on)),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: TextFormField(
                      controller: _ibanController,
                      decoration: const InputDecoration(labelText: 'IBAN Numarası', prefixIcon: Icon(Icons.credit_card)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              ElevatedButton(
                onPressed: _isSaving ? null : _kaydet,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Kaydet'),
              ),
              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ),
    );
  }
}

// Maaş Avansı Ekleme Dialogu
class _MaasAvansiEkleDialog extends ConsumerStatefulWidget {
  final String personelId;

  const _MaasAvansiEkleDialog({required this.personelId});

  @override
  ConsumerState<_MaasAvansiEkleDialog> createState() => _MaasAvansiEkleDialogState();
}

class _MaasAvansiEkleDialogState extends ConsumerState<_MaasAvansiEkleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tutarController = TextEditingController();
  final _aciklamaController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  Future<void> _secTarih() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final double tutar = double.parse(_tutarController.text.replaceAll(',', '.'));
      await ref.read(personelServiceProvider).addMaasAvansi(
            personelId: widget.personelId,
            tutar: tutar,
            tarih: _selectedDate,
            aciklama: _aciklamaController.text.trim().isEmpty ? null : _aciklamaController.text.trim(),
          );
      ref.invalidate(maasAvanslariProvider(widget.personelId));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Maaş avansı eklendi.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tutarController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Maaş Avansı Ekle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _tutarController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: tutarValidator,
              decoration: const InputDecoration(labelText: 'Tutar (TL)', prefixIcon: Icon(Icons.payments)),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _secTarih,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tarih', prefixIcon: Icon(Icons.calendar_today)),
                child: Text(tarihFormat(_selectedDate)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aciklamaController,
              decoration: const InputDecoration(labelText: 'Açıklama (İsteğe Bağlı)', prefixIcon: Icon(Icons.description)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: _isSaving ? null : _kaydet,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Ekle'),
        ),
      ],
    );
  }
}

// İş Avansı Ekleme Dialogu
class _IsAvansiEkleDialog extends ConsumerStatefulWidget {
  final String personelId;

  const _IsAvansiEkleDialog({required this.personelId});

  @override
  ConsumerState<_IsAvansiEkleDialog> createState() => _IsAvansiEkleDialogState();
}

class _IsAvansiEkleDialogState extends ConsumerState<_IsAvansiEkleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tutarController = TextEditingController();
  final _aciklamaController = TextEditingController();
  String? _selectedProjeId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  Future<void> _secTarih() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final double tutar = double.parse(_tutarController.text.replaceAll(',', '.'));
      await ref.read(personelServiceProvider).addIsAvansi(
            personelId: widget.personelId,
            tutar: tutar,
            tarih: _selectedDate,
            aciklama: _aciklamaController.text.trim().isEmpty ? null : _aciklamaController.text.trim(),
            projeId: _selectedProjeId,
          );
      ref.invalidate(personelFinansalOzetProvider(widget.personelId));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ İş avansı eklendi.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tutarController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projelerAsync = ref.watch(projelerProvider);

    return AlertDialog(
      title: const Text('İş Avansı Gönder'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tutarController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: tutarValidator,
                decoration: const InputDecoration(labelText: 'Tutar (TL)', prefixIcon: Icon(Icons.payments)),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _secTarih,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tarih', prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(tarihFormat(_selectedDate)),
                ),
              ),
              const SizedBox(height: 12),
              projelerAsync.when(
                data: (projeler) => DropdownButtonFormField<String?>(
                  value: _selectedProjeId,
                  decoration: const InputDecoration(labelText: 'İlgili Proje (İsteğe Bağlı)', prefixIcon: Icon(Icons.business)),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Seçilmedi')),
                    ...projeler.map((p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.ad))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedProjeId = val;
                    });
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Projeler yüklenemedi'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aciklamaController,
                decoration: const InputDecoration(labelText: 'Açıklama', prefixIcon: Icon(Icons.description)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        ElevatedButton(
          onPressed: _isSaving ? null : _kaydet,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Gönder'),
        ),
      ],
    );
  }
}
