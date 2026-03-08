import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';
import 'package:andicrochett/features/inventory/presentation/pages/product_detail_page.dart';
import 'package:andicrochett/features/inventory/presentation/pages/product_form_page.dart';
import 'package:andicrochett/features/inventory/presentation/widgets/inventory_filter_sheet.dart';
import 'package:andicrochett/features/inventory/presentation/widgets/product_table.dart';
import 'package:andicrochett/features/inventory/presentation/widgets/inventory_stats_bar.dart';
import 'package:andicrochett/features/inventory/presentation/providers/inventory_provider.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final InventoryProvider _provider = InventoryProvider();

  List<ProductModel> _filtered = [];
  InventoryFilters _filters = InventoryFilters.empty();

  @override
  void initState() {
    super.initState();
    _provider.startListening();
    _provider.addListener(_applyFilters);
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _provider.removeListener(_applyFilters);
    _provider.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // -- Filtrado / busqueda local --

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    final allProducts = _provider.products;

    setState(() {
      _filtered = allProducts.where((p) {
        // busqueda por texto
        if (query.isNotEmpty &&
            !p.name.toLowerCase().contains(query) &&
            !p.category.toLowerCase().contains(query) &&
            !p.colorHex.toLowerCase().contains(query)) {
          return false;
        }
        // filtro por categoria
        if (_filters.categories.isNotEmpty &&
            !_filters.categories.contains(p.category)) {
          return false;
        }
        // filtro por estado
        if (_filters.statuses.isNotEmpty &&
            !_filters.statuses.contains(p.status)) {
          return false;
        }
        return true;
      }).toList();

      // ordenar
      _filtered.sort((a, b) {
        int cmp;
        switch (_filters.sortBy) {
          case 'stock':
            cmp = a.currentStock.compareTo(b.currentStock);
          case 'category':
            cmp = a.category.compareTo(b.category);
          default:
            cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        return _filters.sortAsc ? cmp : -cmp;
      });
    });
  }

  // -- Navegacion --

  Future<void> _openDetail(ProductModel product) async {
    final result = await Navigator.of(context).push<ProductModel?>(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product),
      ),
    );
    if (result != null && result.id.isEmpty) {
      // eliminado desde detalle
      _deleteProduct(product);
    } else if (result != null) {
      _updateProduct(result);
    }
  }

  Future<void> _openAddProduct() async {
    final result = await Navigator.of(context).push<ProductModel>(
      MaterialPageRoute(builder: (_) => const ProductFormPage()),
    );
    if (result != null) {
      final id = await _provider.createProduct(result);
      if (mounted && id != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${result.name}" creado'),
            backgroundColor: AppColors.verdeOliva,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openEditProduct(ProductModel product) async {
    final result = await Navigator.of(context).push<ProductModel>(
      MaterialPageRoute(
        builder: (_) => ProductFormPage(product: product),
      ),
    );
    if (result != null) {
      _updateProduct(result);
    }
  }

  Future<void> _updateProduct(ProductModel updated) async {
    final success = await _provider.updateProduct(updated);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${updated.name}" actualizado'),
          backgroundColor: AppColors.verdeOliva,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openFilters() async {
    final result = await InventoryFilterSheet.show(
      context,
      current: _filters,
    );
    if (result != null) {
      _filters = result;
      _applyFilters();
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final success = await _provider.deleteProduct(product.id);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${product.name}" eliminado'),
          backgroundColor: AppColors.textoFuerte,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // -- Build --

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        // Estado de carga
        if (_provider.loading && _provider.products.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.verdeOliva),
          );
        }

        // Estado de error
        if (_provider.error != null && _provider.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 64,
                    color: AppColors.error.withValues(alpha: 0.5)),
                const SizedBox(height: Sizes.md),
                const Text('Error al cargar inventario',
                    style: TextStyle(
                        fontSize: Sizes.fontSizeXl,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textoFuerte)),
                const SizedBox(height: Sizes.sm),
                Text(_provider.error!,
                    style: const TextStyle(
                        fontSize: Sizes.fontSizeSm, color: AppColors.texto)),
                const SizedBox(height: Sizes.lg),
                ElevatedButton.icon(
                  onPressed: () => _provider.startListening(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdeOliva,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          color: AppColors.background,
          child: Column(
            children: [
              _buildHeader(isMobile),
              InventoryStatsBar(products: _filtered),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? Sizes.md : Sizes.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(),
                      const SizedBox(height: Sizes.md),
                      Expanded(
                        child: _filtered.isEmpty
                            ? _buildEmptyState()
                            : isMobile
                                ? SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: 860,
                                      child: ProductTable(
                                        products: _filtered,
                                        onTap: _openDetail,
                                        onEdit: _openEditProduct,
                                        onDelete: _deleteProduct,
                                      ),
                                    ),
                                  )
                                : ProductTable(
                                    products: _filtered,
                                    onTap: _openDetail,
                                    onEdit: _openEditProduct,
                                    onDelete: _deleteProduct,
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -- Header --

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(Sizes.md),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            bottom: BorderSide(color: AppColors.lino, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventario General',
              style: TextStyle(
                fontSize: Sizes.fontSizeXxl,
                fontWeight: FontWeight.bold,
                color: AppColors.textoFuerte,
              ),
            ),
            const SizedBox(height: Sizes.sm),
            _SearchField(controller: _searchController),
            const SizedBox(height: Sizes.sm),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: _openAddProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.resaltado,
                  foregroundColor: AppColors.background,
                  padding:
                      const EdgeInsets.symmetric(horizontal: Sizes.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Agregar',
                      style: TextStyle(
                        fontSize: Sizes.fontSizeSm,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                const Flexible(
                  child: Text(
                    'Inventario General',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Sizes.fontSizeXxl,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoFuerte,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: Sizes.lg),
                SizedBox(
                  width: 350,
                  child: _SearchField(controller: _searchController),
                ),
              ],
            ),
          ),
          const SizedBox(width: Sizes.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: _openAddProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.resaltado,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: Sizes.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Agregar',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Sizes.fontSizeSm,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Section header --

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'STOCK ACTUAL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.texto,
                letterSpacing: 1.5,
              ),
            ),
            if (_filters.hasActiveFilters) ...[
              const SizedBox(width: Sizes.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.verdeOliva.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_filtered.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.verdeOliva,
                  ),
                ),
              ),
            ],
          ],
        ),
        IconButton(
          onPressed: _openFilters,
          icon: Icon(
            _filters.hasActiveFilters
                ? Icons.filter_alt
                : Icons.filter_alt_outlined,
            color: _filters.hasActiveFilters
                ? AppColors.verdeOliva
                : AppColors.texto,
          ),
          iconSize: 20,
          splashRadius: 20,
          tooltip: 'Filtros',
        ),
      ],
    );
  }

  // -- Empty state --

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.texto.withValues(alpha: 0.3),
          ),
          const SizedBox(height: Sizes.md),
          const Text(
            'Sin productos',
            style: TextStyle(
              fontSize: Sizes.fontSizeXl,
              fontWeight: FontWeight.bold,
              color: AppColors.textoFuerte,
            ),
          ),
          const SizedBox(height: Sizes.sm),
          Text(
            _searchController.text.isNotEmpty || _filters.hasActiveFilters
                ? 'No hay coincidencias con los filtros actuales'
                : 'Agrega tu primer producto para empezar',
            style: const TextStyle(
              fontSize: Sizes.fontSizeMd,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: Sizes.lg),
          if (!_filters.hasActiveFilters &&
              _searchController.text.isEmpty)
            ElevatedButton.icon(
              onPressed: _openAddProduct,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar producto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeOliva,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// -- Search field --

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Buscar...',
        hintStyle: TextStyle(
          fontSize: Sizes.fontSizeSm,
          color: AppColors.texto,
        ),
        prefixIcon: Icon(Icons.search, size: 18, color: AppColors.texto),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              onPressed: controller.clear,
              icon: const Icon(Icons.close, size: 16),
              splashRadius: 16,
              color: AppColors.texto,
            );
          },
        ),
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
