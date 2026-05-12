// lib/features/analytics/presentation/widgets/status_breakdown_bar.dart
//
// Barra horizontal proporcional que muestra la distribución de pedidos por
// estado. No usa ningún package de charts — solo Flex + Container. Liviano.

import 'package:flutter/material.dart';
import 'package:andicrochett/features/analytics/data/models/dashboard_metrics.dart';

class StatusBreakdownBar extends StatelessWidget {
  const StatusBreakdownBar({super.key, required this.breakdown});

  final List<StatusBreakdown> breakdown;

  static const _statusColors = {
    'pending': Color(0xFFE0A800),
    'inProgress': Color(0xFF3B82F6),
    'completed': Color(0xFF22C55E),
    'cancelled': Color(0xFFEF4444),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (breakdown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Aún no hay pedidos registrados.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final total = breakdown.fold<int>(0, (a, b) => a + b.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 18,
            child: Row(
              children: breakdown.map((b) {
                final flex = total == 0 ? 1 : b.count;
                return Expanded(
                  flex: flex,
                  child: Container(color: _colorFor(b.statusKey)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: breakdown.map((b) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _colorFor(b.statusKey),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${b.label} · ${b.count}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _colorFor(String statusKey) =>
      _statusColors[statusKey] ?? const Color(0xFF9CA3AF);
}
