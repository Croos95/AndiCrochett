import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';
import 'package:andicrochett/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:andicrochett/features/inventory/presentation/widgets/product_form.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterCategory;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    // Cargar productos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductForm({ProductModel? existing}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusXl),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ProductForm(
            existing: existing,
            onSave: (product) async {
              final provider = context.read<InventoryProvider>();
              bool success;
              final messenger = ScaffoldMessenger.of(context);
              if (existing != null) {
                success = await provider.updateProduct(
                  product.copyWith(id: existing.id),
                );
              } else {
                success = await provider.addProduct(product);
              }
              if (mounted && success) {
                Navigator.pop(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      existing != null
                          ? 'Producto actualizado'
                          : 'Producto agregado',
                    ),
                    backgroundColor: AppColors.verdeOliva,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusLg),
        ),
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Eliminar "${product.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && product.id != null) {
      if (!mounted) return;
      final provider = context.read<InventoryProvider>();
      final messenger = ScaffoldMessenger.of(context);
      final success = await provider.deleteProduct(product.id!);
      if (mounted && success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado'),
            backgroundColor: AppColors.verdeOliva,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Consumer<InventoryProvider>(
          builder: (context, inventoryProvider, _) {
            return Container(
              color: AppColors.background,
              child: Column(
                children: [
                  _buildHeader(isMobile, inventoryProvider),
                  Expanded(child: _buildContent(isMobile, inventoryProvider)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent(bool isMobile, InventoryProvider provider) {
    if (provider.status == InventoryStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.verdeOliva),
      );
    }

    if (provider.status == InventoryStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: Sizes.md),
            Text(
              'Error: ${provider.error}',
              style: const TextStyle(
                fontSize: Sizes.fontSizeMd,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Sizes.md),
            ElevatedButton(
              onPressed: () => provider.loadProducts(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final allProducts = provider.products;
    final products = allProducts.where((p) {
      if (_searchQuery.isNotEmpty &&
          !p.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_filterCategory != null && p.category != _filterCategory) {
        return false;
      }
      if (_filterStatus != null) {
        final statusVal = switch (_filterStatus) {
          'available' => ProductStatus.available,
          'low_stock' => ProductStatus.lowStock,
          'out_of_stock' => ProductStatus.outOfStock,
          _ => null,
        };
        if (statusVal != null && p.status != statusVal) {
          return false;
        }
      }
      return true;
    }).toList();

    final lowCount = allProducts
        .where(
          (p) =>
              p.status == ProductStatus.lowStock ||
              p.status == ProductStatus.outOfStock,
        )
        .length;

    return Column(
      children: [
        _buildStatsBar(
          totalStock: provider.totalStock,
          lowCount: lowCount,
          isMobile: isMobile,
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? Sizes.md : Sizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(allProducts),
                const SizedBox(height: Sizes.md),
                Expanded(
                  child: products.isEmpty
                      ? _buildEmptyState()
                      : isMobile
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 1000,
                            child: _buildInventoryTable(products),
                          ),
                        )
                      : _buildInventoryTable(products),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.border,
          ),
          const SizedBox(height: Sizes.md),
          Text(
            _searchQuery.isEmpty
                ? 'No hay productos aún'
                : 'No se encontraron resultados',
            style: const TextStyle(
              fontSize: Sizes.fontSizeXl,
              fontWeight: FontWeight.bold,
              color: AppColors.textoFuerte,
            ),
          ),
          const SizedBox(height: Sizes.sm),
          Text(
            _searchQuery.isEmpty
                ? 'Agrega tu primer producto con el botón de arriba.'
                : 'Intenta con otro término de búsqueda.',
            style: const TextStyle(
              fontSize: Sizes.fontSizeMd,
              color: AppColors.texto,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: Sizes.md),
            ElevatedButton.icon(
              onPressed: () => _showProductForm(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar producto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.resaltado,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile, InventoryProvider provider) {
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
            const Text(
              'Inventario General',
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: Sizes.fontSizeXxl,
                fontWeight: FontWeight.bold,
                color: AppColors.textoFuerte,
              ),
            ),
            const SizedBox(height: Sizes.sm),
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Buscar...',
                hintStyle: TextStyle(
                  fontSize: Sizes.fontSizeSm,
                  color: AppColors.texto,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.texto,
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
            ),
            const SizedBox(height: Sizes.sm),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: () => _showProductForm(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.resaltado,
                  foregroundColor: Colors.white,
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
                      fontFamily: 'Lora',
                      fontSize: Sizes.fontSizeXxl,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoFuerte,
                    ),
                  ),
                ),
                const SizedBox(width: Sizes.lg),
                SizedBox(
                  width: 350,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      hintStyle: TextStyle(
                        fontSize: Sizes.fontSizeSm,
                        color: AppColors.texto,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.texto,
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
                        borderSide: const BorderSide(
                          color: AppColors.verdeOliva,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Sizes.md,
                        vertical: Sizes.sm,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: Sizes.fontSizeSm),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Sizes.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => _showProductForm(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.resaltado,
                      foregroundColor: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildStatsBar({
    required int totalStock,
    required int lowCount,
    required bool isMobile,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.lg,
        vertical: Sizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.lino.withValues(alpha: 0.5),
        border: const Border(
          bottom: BorderSide(color: AppColors.lino, width: 1),
        ),
      ),
      child: Wrap(
        spacing: Sizes.lg,
        runSpacing: Sizes.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildStatItem(
            'TOTAL STOCK:',
            totalStock.toString(),
            AppColors.verdeOliva,
          ),
          if (!isMobile) _buildStatDivider(),
          _buildStatItem('POR AGOTAR:', lowCount.toString(), AppColors.error),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.texto,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: Sizes.sm),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: Sizes.lg),
      color: AppColors.lino,
    );
  }

  static const Map<String, IconData> _categoryIcons = {
    'Estambre': Icons.adjust,
    'Hilo': Icons.linear_scale,
    'Agujas y Ganchos': Icons.create,
    'Herramientas': Icons.build,
    'Accesorios': Icons.stars,
    'Botones': Icons.radio_button_unchecked,
    'Relleno': Icons.cloud,
    'Otro': Icons.category,
  };

  void _showFilterDialog(BuildContext context, List<ProductModel> allProducts) {
    final uniqueCategories = allProducts.map((p) => p.category).toSet().toList()
      ..sort();
    String? tempCategory = _filterCategory;
    String? tempStatus = _filterStatus;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Sizes.radiusLg),
          ),
          title: const Row(
            children: [
              Icon(Icons.filter_alt_outlined, color: AppColors.verdeOliva),
              SizedBox(width: 8),
              Text('Filtrar inventario'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CATEGORÍA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.texto,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilterChip(
                      label: const Text('Todas'),
                      selected: tempCategory == null,
                      onSelected: (_) => setDlg(() => tempCategory = null),
                      selectedColor: AppColors.verdeOliva.withValues(
                        alpha: 0.25,
                      ),
                    ),
                    ...uniqueCategories.map(
                      (c) => FilterChip(
                        avatar: Icon(
                          _categoryIcons[c] ?? Icons.category,
                          size: 14,
                        ),
                        label: Text(c),
                        selected: tempCategory == c,
                        onSelected: (v) =>
                            setDlg(() => tempCategory = v ? c : null),
                        selectedColor: AppColors.verdeOliva.withValues(
                          alpha: 0.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'ESTADO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.texto,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: tempStatus == null,
                      onSelected: (_) => setDlg(() => tempStatus = null),
                      selectedColor: AppColors.verdeOliva.withValues(
                        alpha: 0.25,
                      ),
                    ),
                    FilterChip(
                      label: const Text('Disponible'),
                      selected: tempStatus == 'available',
                      onSelected: (v) =>
                          setDlg(() => tempStatus = v ? 'available' : null),
                      selectedColor: AppColors.success.withValues(alpha: 0.25),
                    ),
                    FilterChip(
                      label: const Text('Bajo stock'),
                      selected: tempStatus == 'low_stock',
                      onSelected: (v) =>
                          setDlg(() => tempStatus = v ? 'low_stock' : null),
                      selectedColor: AppColors.warning.withValues(alpha: 0.25),
                    ),
                    FilterChip(
                      label: const Text('Sin existencias'),
                      selected: tempStatus == 'out_of_stock',
                      onSelected: (v) =>
                          setDlg(() => tempStatus = v ? 'out_of_stock' : null),
                      selectedColor: AppColors.error.withValues(alpha: 0.25),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterCategory = null;
                  _filterStatus = null;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Limpiar filtros'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterCategory = tempCategory;
                  _filterStatus = tempStatus;
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verdeOliva,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(List<ProductModel> allProducts) {
    final hasFilter = _filterCategory != null || _filterStatus != null;
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
            if (hasFilter) ...[
              const SizedBox(width: Sizes.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.resaltado.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.resaltado.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  (_filterCategory != null ? 1 : 0) +
                              (_filterStatus != null ? 1 : 0) ==
                          1
                      ? '1 filtro activo'
                      : '2 filtros activos',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.resaltado,
                  ),
                ),
              ),
            ],
          ],
        ),
        IconButton(
          onPressed: () => _showFilterDialog(context, allProducts),
          icon: Icon(
            hasFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
            color: hasFilter ? AppColors.resaltado : AppColors.texto,
          ),
          iconSize: 20,
          splashRadius: 20,
          tooltip: 'Filtrar inventario',
        ),
      ],
    );
  }

  Widget _buildInventoryTable(List<ProductModel> products) {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Producto')),
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Precio')),
          DataColumn(label: Text('Stock')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: products
            .map(
              (product) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(Text(product.category)),
                  DataCell(Text('\$${product.price.toStringAsFixed(2)}')),
                  DataCell(Text(product.currentStock.toString())),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          product.status,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.status.label,
                        style: TextStyle(
                          color: _statusColor(product.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () => _showProductForm(existing: product),
                          tooltip: 'Editar',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 16,
                            color: AppColors.error,
                          ),
                          onPressed: () => _confirmDelete(product),
                          tooltip: 'Eliminar',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Color _statusColor(ProductStatus status) {
    return switch (status) {
      ProductStatus.available => AppColors.verdeOliva,
      ProductStatus.lowStock => Colors.orange,
      ProductStatus.outOfStock => AppColors.error,
    };
  }
}
