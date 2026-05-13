import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';

/// Layout reutilizable para pantallas del dashboard.
///
/// Proporciona un header con título, barra de búsqueda opcional
/// y acciones, más un área de contenido scrolleable.
class AppLayout extends StatelessWidget {
  const AppLayout({
    super.key,
    required this.title,
    required this.child,
    this.searchController,
    this.searchHint = 'Buscar...',
    this.onSearchChanged,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final TextEditingController? searchController;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          color: AppColors.background,
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              _buildHeader(isMobile),
              // ── Content ───────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? Sizes.md : Sizes.lg),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(Sizes.md),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(bottom: BorderSide(color: AppColors.lino, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: Sizes.fontSizeXxl,
                fontWeight: FontWeight.bold,
                color: AppColors.textoFuerte,
              ),
            ),
            if (searchController != null) ...[
              const SizedBox(height: Sizes.sm),
              _buildSearchField(),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: Sizes.sm),
              Wrap(spacing: Sizes.sm, children: actions),
            ],
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: Sizes.lg),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.lino, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: Sizes.fontSizeXxl,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoFuerte,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                if (searchController != null) ...[
                  const SizedBox(width: Sizes.lg),
                  SizedBox(width: 350, child: _buildSearchField()),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: Sizes.md),
            Row(mainAxisSize: MainAxisSize.min, children: actions),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: searchHint,
        hintStyle: TextStyle(
          fontSize: Sizes.fontSizeSm,
          color: AppColors.texto,
        ),
        prefixIcon: Icon(Icons.search, size: 18, color: AppColors.texto),
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
  }
}
