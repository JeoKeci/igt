import 'package:flutter/material.dart';
import '../models/harcama.dart';
import '../utils/formatters.dart';

class HarcamaCard extends StatelessWidget {
  final Harcama harcama;
  final VoidCallback onTap;

  const HarcamaCard({
    super.key,
    required this.harcama,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Kategoriye göre renk belirleme (basit bir hash mantığı)
    final int categoryHash = harcama.kategoriAdi?.hashCode ?? 0;
    final Color avatarColor = Colors.primaries[categoryHash % Colors.primaries.length];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: avatarColor.withValues(alpha: 0.2),
                    foregroundColor: avatarColor,
                    child: Text(
                      harcama.kategoriAdi?.isNotEmpty == true 
                          ? harcama.kategoriAdi![0].toUpperCase() 
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          harcama.firma,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tarihFormat(harcama.tarih)} • ${harcama.kategoriAdi ?? ''}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tutarFormat(harcama.fisTutari),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTag(context, Icons.payment, harcama.odemeSekliAdi ?? '', colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
                  if (harcama.projeAdi != null) ...[
                    const SizedBox(width: 8),
                    _buildTag(context, Icons.work_outline, harcama.projeAdi!, colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, IconData icon, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bgColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
