import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lookup_provider.dart';
import '../models/odeme_sekli.dart';
import '../widgets/loading_widget.dart';

class OdemeSekilleriYonetimiScreen extends ConsumerStatefulWidget {
  const OdemeSekilleriYonetimiScreen({super.key});

  @override
  ConsumerState<OdemeSekilleriYonetimiScreen> createState() => _OdemeSekilleriYonetimiScreenState();
}

class _OdemeSekilleriYonetimiScreenState extends ConsumerState<OdemeSekilleriYonetimiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _kodController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _adController.dispose();
    _kodController.dispose();
    super.dispose();
  }

  void _showFormDialog({OdemeSekli? odemeSekli}) {
    if (odemeSekli != null) {
      _adController.text = odemeSekli.ad;
      _kodController.text = odemeSekli.kod;
    } else {
      _adController.clear();
      _kodController.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(odemeSekli == null ? 'Yeni Ödeme Şekli' : 'Ödeme Şekli Düzenle'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _kodController,
                      decoration: const InputDecoration(labelText: 'Kod (Kısa Ad)'),
                      validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adController,
                      decoration: const InputDecoration(labelText: 'Ödeme Şekli Adı'),
                      validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
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
                            'kod': _kodController.text.trim(),
                          };

                          try {
                            if (odemeSekli == null) {
                              await lookupService.addOdemeSekli(data);
                            } else {
                              await lookupService.updateOdemeSekli(odemeSekli.id, data);
                            }
                            ref.invalidate(odemeSekilleriProvider);
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata: $e'), backgroundColor: Theme.of(context).colorScheme.error),
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

  void _confirmDelete(OdemeSekli odemeSekli) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödeme Şeklini Sil'),
        content: Text('"${odemeSekli.ad}" ödeme şeklini silmek istediğinize emin misiniz? Geçmiş kayıtlar etkilenmeyecek.'),
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
                await lookupService.updateOdemeSekli(odemeSekli.id, {'iptal': true});
                ref.invalidate(odemeSekilleriProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e'), backgroundColor: Theme.of(context).colorScheme.error),
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
    final state = ref.watch(odemeSekilleriProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Şekilleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showFormDialog(),
            tooltip: 'Yeni Ödeme Şekli Ekle',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.when(
        data: (liste) {
          if (liste.isEmpty) {
            return const Center(child: Text('Kayıtlı ödeme şekli bulunmuyor.'));
          }
          return ListView.builder(
            itemCount: liste.length,
            itemBuilder: (context, index) {
              final item = liste[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(item.kod, style: const TextStyle(fontSize: 12)),
                  ),
                  title: Text(item.ad, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showFormDialog(odemeSekli: item),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        onPressed: () => _confirmDelete(item),
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
