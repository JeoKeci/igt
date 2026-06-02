import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igt_masraf_takip/models/personel.dart';
import 'package:igt_masraf_takip/providers/personel_provider.dart';
import 'package:igt_masraf_takip/screens/personel_detay_screen.dart';
import 'package:igt_masraf_takip/widgets/loading_widget.dart';
import 'package:igt_masraf_takip/utils/formatters.dart';

class PersonelListesiScreen extends ConsumerWidget {
  const PersonelListesiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredPersonAsync = ref.watch(filteredPersonellerProvider);
    final aramaQuery = ref.watch(personelAramaQueryProvider);
    final aktifFiltre = ref.watch(personelFiltreAktifProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel Yönetimi'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Personel veya Bölüm Ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: aramaQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(personelAramaQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              value: TextEditingValue(
                text: aramaQuery,
                selection: TextSelection.collapsed(offset: aramaQuery.length),
              ),
              onChanged: (val) {
                ref.read(personelAramaQueryProvider.notifier).state = val;
              },
            ),
          ),

          // Filtre Chip'leri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Aktifler'),
                  selected: aktifFiltre == true,
                  onSelected: (selected) {
                    ref.read(personelFiltreAktifProvider.notifier).state =
                        selected ? true : null;
                  },
                ),
                const SizedBox(width: 8.0),
                FilterChip(
                  label: const Text('Pasifler'),
                  selected: aktifFiltre == false,
                  onSelected: (selected) {
                    ref.read(personelFiltreAktifProvider.notifier).state =
                        selected ? false : null;
                  },
                ),
                const SizedBox(width: 8.0),
                FilterChip(
                  label: const Text('Tümü'),
                  selected: aktifFiltre == null,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(personelFiltreAktifProvider.notifier).state = null;
                    }
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Personel Listesi
          Expanded(
            child: filteredPersonAsync.when(
              data: (personeller) {
                if (personeller.isEmpty) {
                  return const EmptyWidget(
                    icon: Icons.people_outline,
                    message: 'Aranan kriterlere uygun personel bulunamadı.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(personellerProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    itemCount: personeller.length,
                    itemBuilder: (context, index) {
                      final p = personeller[index];
                      return _PersonelKart(p: p);
                    },
                  ),
                );
              },
              loading: () => const LoadingWidget(message: 'Personel listesi yükleniyor...'),
              error: (err, stack) => IgtErrorWidget(
                message: 'Hata oluştu: ${err.toString()}',
                onRetry: () => ref.invalidate(personellerProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonelKart extends StatelessWidget {
  final Personel p;

  const _PersonelKart({required this.p});

  String _getRolMetni(String rol) {
    switch (rol) {
      case 'yonetici':
        return 'Yönetici';
      case 'muhasebe':
        return 'Muhasebe';
      case 'saha':
        return 'Saha Personeli';
      default:
        return rol;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ilkHarfler = p.adSoyad.isNotEmpty
        ? p.adSoyad
            .trim()
            .split(' ')
            .map((s) => s.isNotEmpty ? s[0] : '')
            .join()
            .toUpperCase()
        : '';
    final avatarText = ilkHarfler.length > 2 ? ilkHarfler.substring(0, 2) : ilkHarfler;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonelDetayScreen(personelId: p.id),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: p.aktif
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade300,
          child: Text(
            avatarText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: p.aktif
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Colors.grey.shade700,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                p.adSoyad,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: p.aktif ? null : TextDecoration.lineThrough,
                  color: p.aktif ? null : Colors.grey,
                ),
              ),
            ),
            if (!p.aktif)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Pasif',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4.0),
            Text(
              '${_getRolMetni(p.rol)}${p.bolumAdi != null ? ' • ${p.bolumAdi}' : ''}',
              style: TextStyle(
                fontSize: 12.0,
                color: p.aktif ? Colors.grey.shade700 : Colors.grey.shade500,
              ),
            ),
            if (p.gorevUnvan != null && p.gorevUnvan!.isNotEmpty) ...[
              const SizedBox(height: 2.0),
              Text(
                p.gorevUnvan!,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: p.aktif ? Colors.black87 : Colors.grey,
                ),
              ),
            ]
          ],
        ),
        trailing: p.aktif ? _PersonelBakiyeBadge(personelId: p.id) : null,
      ),
    );
  }
}

class _PersonelBakiyeBadge extends ConsumerWidget {
  final String personelId;

  const _PersonelBakiyeBadge({required this.personelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ozetAsync = ref.watch(personelFinansalOzetProvider(personelId));

    return ozetAsync.when(
      data: (ozet) {
        final double netBakiye = ozet['netBakiye'] ?? 0.0;
        if (netBakiye == 0) {
          return const Text(
            '₺0,00',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 12,
            ),
          );
        }

        final isPozitif = netBakiye >= 0;
        final color = isPozitif ? Colors.green.shade700 : Colors.red.shade700;
        final sign = isPozitif ? '' : '-';
        final label = isPozitif ? 'Eldeki' : 'Borç';

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$sign${tutarFormat(netBakiye.abs())}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(
        Icons.error_outline,
        color: Colors.red,
        size: 16,
      ),
    );
  }
}
