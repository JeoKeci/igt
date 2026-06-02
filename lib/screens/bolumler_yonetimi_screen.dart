import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lookup_provider.dart';
import '../models/bolum.dart';
import '../widgets/loading_widget.dart';

class BolumlerYonetimiScreen extends ConsumerStatefulWidget {
  const BolumlerYonetimiScreen({super.key});

  @override
  ConsumerState<BolumlerYonetimiScreen> createState() => _BolumlerYonetimiScreenState();
}

class _BolumlerYonetimiScreenState extends ConsumerState<BolumlerYonetimiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  bool _isAktif = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _adController.dispose();
    super.dispose();
  }

  void _showFormDialog({Bolum? bolum}) {
    if (bolum != null) {
      _adController.text = bolum.ad;
      _isAktif = bolum.aktif;
    } else {
      _adController.clear();
      _isAktif = true;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(bolum == null ? 'Yeni Bölüm' : 'Bölüm Düzenle'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _adController,
                      decoration: const InputDecoration(labelText: 'Bölüm Adı'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Zorunlu alan' : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Aktif Durum'),
                      subtitle: const Text('Pasife alınan bölümler yeni harcamalarda seçilemez'),
                      value: _isAktif,
                      onChanged: (val) {
                        setDialogState(() => _isAktif = val);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
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
                            'aktif': _isAktif,
                          };

                          try {
                            if (bolum == null) {
                              await lookupService.addBolum(data);
                            } else {
                              await lookupService.updateBolum(bolum.id, data);
                            }
                            ref.invalidate(bolumlerProvider);
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

  void _confirmDelete(Bolum bolum) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bölümü Sil'),
        content: Text('"${bolum.ad}" bölümünü silmek istediğinize emin misiniz? (Geçmiş kayıtlar silinmez, bölüm pasife alınır)'),
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
                await lookupService.updateBolum(bolum.id, {'iptal': true});
                ref.invalidate(bolumlerProvider);
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
    final state = ref.watch(bolumlerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bölümler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showFormDialog(),
            tooltip: 'Yeni Bölüm Ekle',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.when(
        data: (liste) {
          if (liste.isEmpty) {
            return const Center(child: Text('Kayıtlı bölüm bulunmuyor.'));
          }
          return ListView.builder(
            itemCount: liste.length,
            itemBuilder: (context, index) {
              final bolum = liste[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: bolum.aktif
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.business,
                      color: bolum.aktif
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    bolum.ad,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: bolum.aktif ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(bolum.aktif ? 'Aktif' : 'Pasif'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showFormDialog(bolum: bolum),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        onPressed: () => _confirmDelete(bolum),
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
