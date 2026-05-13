import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/core/widgets/empty_state_view.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';
import 'package:andicrochett/features/patterns/data/repositories/pattern_repository.dart';
import 'package:andicrochett/features/patterns/presentation/pages/pattern_detail_page.dart';
import 'package:andicrochett/features/patterns/presentation/pages/pattern_editor_page.dart';
import 'package:andicrochett/features/patterns/presentation/widgets/pattern_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PatternsPage
//  Pantalla principal de patrones: muestra todos los patrones del usuario.
// ─────────────────────────────────────────────────────────────────────────────

class PatternsPage extends StatefulWidget {
  const PatternsPage({super.key});

  @override
  State<PatternsPage> createState() => _PatternsPageState();
}

class _PatternsPageState extends State<PatternsPage> {
  final _repo = PatternRepository();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  PatternType? _selectedType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PatternModel> _applyFilters(List<PatternModel> all) {
    return all.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty || p.name.toLowerCase().contains(q);
      final matchType = _selectedType == null || p.type == _selectedType;
      return matchSearch && matchType;
    }).toList();
  }

  void _openEditor({PatternModel? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatternEditorPage(
          designId: existing?.designId ?? 0,
          existing: existing,
        ),
      ),
    );
  }

  //abre la vista de detalle del patron seleccionado
  void _openDetail(PatternModel pattern) {
    if (pattern.id == null) return;
    //se usa navigator.push para abrir una nueva pagina
    Navigator.push(
      //context es para navegar dentro del arbol de widgets actual
      context,
      //MaterialPageRoute es una ruta que hace una transición de material design
      MaterialPageRoute(
        //builder es una función que recibe un contexto y devuelve el widget a mostrar
        builder: (_) => PatternDetailPage(patternId: pattern.id as int),
        //con el as int pattern.id que es un int opcional se fuerza a tratarlo como int Normalito,
        //esto es seguro porque el botón de detalle solo se muestra si pattern.id no es null
      ),
    );
  }

  Future<void> _confirmDelete(PatternModel pattern) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
        ),
        title: const Text('Eliminar patrón'),
        content: Text(
          '¿Eliminar "${pattern.name}"? Esta acción es irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && pattern.id != null) {
      await _repo.delete(pattern.id as int);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Patrón eliminado')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    // Solo cargar patrones del usuario autenticado.
    // Si no hay sesión activa se emite una lista vacía — watchAll() de todas
    // formas sería rechazado por las reglas de seguridad de Firestore.
    final stream = userId != null
        ? _repo.watchByUser(userId)
        : Stream.value(const <PatternModel>[]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          color: AppColors.background,
          child: Column(
            children: [
              _buildHeader(isMobile),
              _buildFilterBar(isMobile),
              Expanded(
                child: StreamBuilder<List<PatternModel>>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.verdeOliva,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      );
                    }
                    final filtered = _applyFilters(snapshot.data ?? []);
                    if (filtered.isEmpty) {
                      return const EmptyStateView(
                        icon: Icons.grid_off_outlined,
                        title: 'Aún no hay patrones',
                        subtitle:
                            'Crea tu primer patrón con el botón "Nuevo patrón".',
                      );
                    }
                    return _PatternGrid(
                      patterns: filtered,
                      isMobile: isMobile,
                      onTap: _openDetail,
                      onEdit: (p) => _openEditor(existing: p),
                      onDelete: _confirmDelete,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    final button = ElevatedButton.icon(
      onPressed: () => _openEditor(),
      icon: const Icon(Icons.add, size: 18),
      label: const Text(
        'Nuevo patrón',
        style: TextStyle(
          fontSize: Sizes.fontSizeSm,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.resaltado,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, Sizes.buttonHeightSm),
        padding: const EdgeInsets.symmetric(horizontal: Sizes.md),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );

    final search = TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Buscar patrones...',
        hintStyle: const TextStyle(
          fontSize: Sizes.fontSizeSm,
          color: AppColors.texto,
        ),
        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.texto),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.lino),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.lino),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.verdeOliva),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.md,
          vertical: Sizes.sm,
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: Sizes.fontSizeSm),
    );

    const title = Text(
      'Patrones de Crochet',
      style: TextStyle(
        fontSize: Sizes.fontSizeXxl,
        fontWeight: FontWeight.bold,
        color: AppColors.textoFuerte,
        fontFamily: 'Lora',
      ),
    );

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(Sizes.md),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(bottom: BorderSide(color: AppColors.lino)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: Sizes.sm),
            search,
            const SizedBox(height: Sizes.sm),
            Align(alignment: Alignment.centerLeft, child: button),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.lg,
        vertical: Sizes.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.lino)),
      ),
      child: Row(
        children: [
          title,
          const SizedBox(width: Sizes.lg),
          SizedBox(width: 280, child: search),
          const Spacer(),
          button,
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? Sizes.md : Sizes.lg,
        vertical: Sizes.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'Tipo:',
              style: TextStyle(
                fontSize: Sizes.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(width: Sizes.sm),
            _FilterChip(
              label: 'Todos',
              isSelected: _selectedType == null,
              onTap: () => setState(() => _selectedType = null),
            ),
            ...PatternType.values.map(
              (t) => Padding(
                padding: const EdgeInsets.only(left: Sizes.xs),
                child: _FilterChip(
                  label: t.label,
                  isSelected: _selectedType == t,
                  onTap: () => setState(
                    () => _selectedType = _selectedType == t ? null : t,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cuadrícula de patrones ───────────────────────────────────────────────────

class _PatternGrid extends StatelessWidget {
  const _PatternGrid({
    required this.patterns,
    required this.isMobile,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PatternModel> patterns;
  final bool isMobile;
  final void Function(PatternModel) onTap;
  final void Function(PatternModel) onEdit;
  final void Function(PatternModel) onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? Sizes.md : Sizes.lg),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          mainAxisExtent: 180,
          crossAxisSpacing: Sizes.md,
          mainAxisSpacing: Sizes.md,
        ),
        itemCount: patterns.length,
        itemBuilder: (_, i) {
          final p = patterns[i];
          return PatternCard(
            pattern: p,
            onTap: () => onTap(p),
            onEdit: () => onEdit(p),
            onDelete: () => onDelete(p),
          );
        },
      ),
    );
  }
}

// ── Chip de filtro ───────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: Sizes.sm,
          vertical: Sizes.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.verdeOliva : Colors.white,
          borderRadius: BorderRadius.circular(Sizes.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.verdeOliva : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: Sizes.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.texto,
          ),
        ),
      ),
    );
  }
}
