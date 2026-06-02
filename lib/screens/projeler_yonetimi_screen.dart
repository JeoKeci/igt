import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lookup_provider.dart';
import '../models/proje.dart';
import '../models/bolum.dart';
import '../widgets/loading_widget.dart';

class ProjelerYonetimiScreen extends ConsumerStatefulWidget {
  const ProjelerYonetimiScreen({super.key});

  @override
  ConsumerState<ProjelerYonetimiScreen> createState() => _ProjelerYonetimiScreenState();
}

class _ProjelerYonetimiScreenState extends ConsumerState<ProjelerYonetimiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _lokasyonController = TextEditingController();
  
  String? _selectedBolumId;
  String _durum = 'aktif';
  bool _isAktif = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _adController.dispose();
    _lokasyonController.dispose();
    super.dispose();
  }

  void _showFormDialog({Proje? proje, List<Bolum>? bolumler}) {
    if (proje != null) {
      _adController.text = proje.ad;
      _lokasyonController.text = proje.lokasyon ?? '';
      _selectedBolumId = proje.bolumId;
      _durum = proje.durum;
      _isAktif = proje.aktif;
    } else {
      _adController.clear();
      _lokasyonController.clear();
      _selectedBolumId = null;
      _durum = 'aktif';
      _isAktif = true;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(proje == null ? 'Yeni Proje' : 'Proje Düzenle'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _adController,
                        decoration: const InputDecoration(labelText: 'Proje Adı'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lokasyonController,
                        decoration: const InputDecoration(labelText: 'Lokasyon (Opsiyonel)'),
                      ),
                      const SizedBox(height: 16),
                      if (bolumler != null && bolumler.isNotEmpty)
                        DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(labelText: 'İlgili Bölüm (Opsiyonel)'),
                          value: _selectedBolumId,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Seçilmedi')),
                            ...bolumler.map((b) => DropdownMenuItem(value: b.id, child: Text(b.ad))),
                          ],
                          onChanged: (v) => setDialogState(() => _selectedBolumId = v),
                        ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Proje Durumu'),
                        value: _durum,
                        items: const [
                          DropdownMenuItem(value: 'aktif', child: Text('Aktif (Devam Ediyor)')),
                          DropdownMenuItem(value: 'beklemede', child: Text('Beklemede')),
                          DropdownMenuItem(value: 'tamamlandi', child: Text('Tamamlandı')),
                          DropdownMenuItem(value: 'iptal', child: Text('İptal Edildi')),
                        ],
                        onChanged: (v) => setDialogState(() => _durum = v ?? 'aktif'),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Aktif Durum'),
                        subtitle: const Text('Pasife alınan projeler yeni harcamalarda seçilemez'),
                        value: _isAktif,
                        onChanged: (val) {
                          setDialogState(() => _isAktif = val);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setDialogState(() => _isSaving = true);

                          final lookupService = ref.read(lookupServiceProvider);
                          final data = {
                            'ad': _adController.text.trim(),
                            'lokasyon': _lokasyonController.text.trim().isEmpty ? null : _lokasyonController.text.trim(),
                            'bolum_id': _selectedBolumId,
                            'durum': _durum,
                            'aktif': _isAktif,
                          };

                          try {
                            if (proje == null) {
                              await lookupService.addProje(data);
                            } else {
                              await lookupService.updateProje(proje.id, data);
                            }
                            ref.invalidate(projelerProvider);
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Hata: $e'),
                                    backgroundColor: Theme.of(context).colorScheme.error),
                              );
                            }
                          } finally {
                            if (mounted) setDialogState(() => _isSaving = false);
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Proje proje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Projeyi Sil'),
        content: Text('"${proje.ad}" projesini silmek istediğinize emin misiniz? (Geçmiş kayıtlar silinmez, proje pasife alınır)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final lookupService = ref.read(lookupServiceProvider);
              try {
                await lookupService.updateProje(proje.id, {'iptal': true});
                ref.invalidate(projelerProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error),
                  );
                }
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projelerProvider);
    final bolumlerState = ref.watch(bolumlerProvider);
    final bolumler = bolumlerState.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projeler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showFormDialog(bolumler: bolumler),
            tooltip: 'Yeni Proje Ekle',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.when(
        data: (liste) {
          if (liste.isEmpty) {
            return const Center(child: Text('Kayıtlı proje bulunmuyor.'));
          }
          return ListView.builder(
            itemCount: liste.length,
            itemBuilder: (context, index) {
              final proje = liste[index];
              final ilgiliBolum = bolumler.where((b) => b.id == proje.bolumId).firstOrNull;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: proje.aktif
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.work,
                      color: proje.aktif
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    proje.ad,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: proje.aktif ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Durum: ${proje.durum.toUpperCase()}'),
                      if (ilgiliBolum != null) Text('Bölüm: ${ilgiliBolum.ad}'),
                      if (proje.lokasyon != null && proje.lokasyon!.isNotEmpty) Text('Lokasyon: ${proje.lokasyon}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showFormDialog(proje: proje, bolumler: bolumler),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        onPressed: () => _confirmDelete(proje),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Yükleniyor...'),
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
    );
  }
}
