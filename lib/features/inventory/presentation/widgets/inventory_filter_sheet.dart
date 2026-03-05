import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';

/// Bottom sheet de filtros para la tabla de inventario.
///
/// Devuelve un [InventoryFilters] con las opciones elegidas.
class InventoryFilterSheet extends StatefulWidget {
  const InventoryFilterSheet({super.key, this.initial});

  final InventoryFilters? initial;

  /// Muestra el sheet y devuelve los filtros elegidos (o `null` si cancela).
  static Future<InventoryFilters?> show(
    BuildContext context, {
    InventoryFilters? current,
  }) {
    return showModalBottomSheet<InventoryFilters>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InventoryFilterSheet(initial: current),
    );
  }

  @override
  State<InventoryFilterSheet> createState() => _InventoryFilterSheetState();
}

class _InventoryFilterSheetState extends State<InventoryFilterSheet> {
  late String _sortBy;
  late bool _sortAsc;
  late Set<String> _categories;
  late Set<String> _statuses;

  static const _allCategories = [
    'Madeja',
    'Ovillo',
    'Hilo',
    'Herramientas',
    'Accesorios',
    'Otro',
  ];

  static const _allStatuses = [
    ('available', 'Disponible', AppColors.success),
    ('low_stock', 'Bajo stock', AppColors.warning),
    ('out_of_stock', 'Agotado', AppColors.error),
    ('full', 'Lleno', AppColors.success),
    ('reorder', 'Reordenar', AppColors.resaltado),
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.initial ?? InventoryFilters.empty();
    _sortBy = f.sortBy;
    _sortAsc = f.sortAsc;
    _categories = Set.from(f.categories);
    _statuses = Set.from(f.statuses);
  }

  void _apply() {
    Navigator.pop(
      context,
      InventoryFilters(
        sortBy: _sortBy,
        sortAsc: _sortAsc,
        categories: _categories.toList(),
        statuses: _statuses.toList(),
      ),
    );
  }

  void _reset() {
    setState(() {
      _sortBy = 'name';
      _sortAsc = true;
      _categories.clear();
      _statuses.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Sizes.lg,
        right: Sizes.lg,
        top: Sizes.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + Sizes.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: Sizes.md),

          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: Sizes.fontSizeXl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textoFuerte,
                ),
              ),
              TextButton(
                onPressed: _reset,
                child: const Text(
                  'Limpiar',
                  style: TextStyle(
                    color: AppColors.resaltado,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Sizes.md),

          // ── Ordenar por ──
          _SectionTitle('Ordenar por'),
          const SizedBox(height: Sizes.sm),
          Wrap(
            spacing: Sizes.sm,
            runSpacing: Sizes.sm,
            children: [
              _SortChip(
                label: 'Nombre',
                value: 'name',
                selected: _sortBy == 'name',
                onTap: () => setState(() => _sortBy = 'name'),
              ),
              _SortChip(
                label: 'Stock',
                value: 'stock',
                selected: _sortBy == 'stock',
                onTap: () => setState(() => _sortBy = 'stock'),
              ),
              _SortChip(
                label: 'Categoría',
                value: 'category',
                selected: _sortBy == 'category',
                onTap: () => setState(() => _sortBy = 'category'),
              ),
              const SizedBox(width: Sizes.sm),
              IconButton(
                onPressed: () => setState(() => _sortAsc = !_sortAsc),
                icon: Icon(
                  _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 20,
                  color: AppColors.verdeOliva,
                ),
                tooltip: _sortAsc ? 'Ascendente' : 'Descendente',
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: Sizes.lg),

          // ── Categorías ──
          _SectionTitle('Categoría'),
          const SizedBox(height: Sizes.sm),
          Wrap(
            spacing: Sizes.sm,
            runSpacing: Sizes.sm,
            children: _allCategories
                .map(
                  (cat) => FilterChip(
                    label: Text(cat),
                    selected: _categories.contains(cat),
                    onSelected: (sel) {
                      setState(() {
                        sel ? _categories.add(cat) : _categories.remove(cat);
                      });
                    },
                    selectedColor: AppColors.verdeOliva.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.verdeOliva,
                    labelStyle: TextStyle(
                      fontSize: Sizes.fontSizeSm,
                      color: _categories.contains(cat)
                          ? AppColors.verdeOliva
                          : AppColors.texto,
                      fontWeight: _categories.contains(cat)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _categories.contains(cat)
                            ? AppColors.verdeOliva
                            : AppColors.lino,
                      ),
                    ),
                    backgroundColor: Colors.white,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: Sizes.lg),

          // ── Estado ──
          _SectionTitle('Estado'),
          const SizedBox(height: Sizes.sm),
          Wrap(
            spacing: Sizes.sm,
            runSpacing: Sizes.sm,
            children: _allStatuses
                .map(
                  (s) => FilterChip(
                    label: Text(s.$2),
                    selected: _statuses.contains(s.$1),
                    onSelected: (sel) {
                      setState(() {
                        sel ? _statuses.add(s.$1) : _statuses.remove(s.$1);
                      });
                    },
                    selectedColor: s.$3.withValues(alpha: 0.15),
                    checkmarkColor: s.$3,
                    labelStyle: TextStyle(
                      fontSize: Sizes.fontSizeSm,
                      color: _statuses.contains(s.$1) ? s.$3 : AppColors.texto,
                      fontWeight: _statuses.contains(s.$1)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _statuses.contains(s.$1) ? s.$3 : AppColors.lino,
                      ),
                    ),
                    backgroundColor: Colors.white,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: Sizes.xl),

          // ── Aplicar ──
          SizedBox(
            width: double.infinity,
            height: Sizes.buttonHeightLg,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeOliva,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Sizes.radiusLg),
                ),
              ),
              child: const Text(
                'Aplicar filtros',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: Sizes.fontSizeLg,
                ),
              ),
            ),
          ),
          const SizedBox(height: Sizes.sm),
        ],
      ),
    );
  }
}

// ── Filtros DTO ──────────────────────────────────────────────────────────────

class InventoryFilters {
  final String sortBy;
  final bool sortAsc;
  final List<String> categories;
  final List<String> statuses;

  const InventoryFilters({
    required this.sortBy,
    required this.sortAsc,
    required this.categories,
    required this.statuses,
  });

  factory InventoryFilters.empty() => const InventoryFilters(
        sortBy: 'name',
        sortAsc: true,
        categories: [],
        statuses: [],
      );

  bool get hasActiveFilters =>
      categories.isNotEmpty || statuses.isNotEmpty;
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: Sizes.fontSizeSm,
          fontWeight: FontWeight.bold,
          color: AppColors.textoFuerte,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.verdeOliva.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.verdeOliva : AppColors.lino,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: Sizes.fontSizeSm,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? AppColors.verdeOliva : AppColors.texto,
          ),
        ),
      ),
    );
  }
}
