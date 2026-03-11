import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';
import 'package:andicrochett/features/inventory/data/repositories/inventory_repository.dart';
import 'package:andicrochett/features/inventory/presentation/widgets/product_form.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final InventoryRepository _repo = InventoryRepository();
  String _searchQuery = '';
  String? _filterCategory;
  String? _filterStatus;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

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
              if (existing != null) {
                await _repo.update(
                  product.copyWith(id: existing.id, userId: existing.userId),
                );
              } else {
                await _repo.create(product.copyWith(userId: _userId));
              }
              if (mounted) Navigator.pop(context);
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
    if (confirmed == true) await _repo.delete(product.id);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          color: AppColors.background,
          child: Column(
            children: [
              _buildHeader(isMobile),
              Expanded(
                child: StreamBuilder<List<ProductModel>>(
                  stream: _repo.watchByUser(_userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.verdeOliva,
                        ),
                      );
                    }

                    final allProducts = snapshot.data ?? [];
                    final products = allProducts.where((p) {
                      if (_searchQuery.isNotEmpty &&
                          !p.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          )) {
                        return false;
                      }
                      if (_filterCategory != null &&
                          p.category != _filterCategory) {
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

                    final totalStock = allProducts.fold<int>(
                      0,
                      (s, p) => s + p.currentStock,
                    );
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
                          totalStock: totalStock,
                          lowCount: lowCount,
                          isMobile: isMobile,
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(
                              isMobile ? Sizes.md : Sizes.lg,
                            ),
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
                                            child: _buildInventoryTable(
                                              products,
                                            ),
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
                  },
                ),
              ),
            ],
          ),
        );
      },
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.lino),
        borderRadius: BorderRadius.circular(Sizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.border,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Sizes.radiusXl),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sizes.lg,
                  vertical: Sizes.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lino,
                  border: const Border(
                    bottom: BorderSide(color: AppColors.lino),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: _TableHeaderCell('PRODUCTO')),
                    Expanded(flex: 1, child: _TableHeaderCell('CATEGORÍA')),
                    Expanded(flex: 2, child: _TableHeaderCell('MARCA')),
                    Expanded(flex: 2, child: _TableHeaderCell('COLOR')),
                    Expanded(flex: 1, child: _TableHeaderCell('PESO')),
                    Expanded(flex: 2, child: _TableHeaderCell('ESTADO')),
                    Expanded(flex: 2, child: _TableHeaderCell('STOCK')),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              // Table rows from Firestore
              ...products.map((p) => _buildTableRow(product: p)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow({required ProductModel product}) {
    final statusLabel = product.status.label;
    final statusColor = switch (product.status) {
      ProductStatus.available => AppColors.success,
      ProductStatus.lowStock => AppColors.warning,
      ProductStatus.outOfStock => AppColors.error,
    };

    // Parse color hex
    Color displayColor = AppColors.lino;
    if (product.color.isNotEmpty) {
      try {
        final hex = product.color.replaceFirst('#', '');
        displayColor = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }

    return InkWell(
      onTap: () => _showProductForm(existing: product),
      hoverColor: AppColors.lino,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Sizes.lg,
          vertical: Sizes.md,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.lino, width: 0.5)),
        ),
        child: Row(
          children: [
            // Product name
            Expanded(
              flex: 3,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Sizes.radiusMd),
                        border: Border.all(color: AppColors.lino),
                        color: displayColor.withValues(alpha: 0.2),
                      ),
                      child: product.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                Sizes.radiusMd,
                              ),
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  _categoryIcons[product.category] ??
                                      Icons.inventory_2,
                                  color: displayColor,
                                  size: 20,
                                ),
                              ),
                            )
                          : Icon(
                              _categoryIcons[product.category] ??
                                  Icons.inventory_2,
                              color: displayColor,
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: Sizes.md),
                    SizedBox(
                      width: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: Sizes.fontSizeMd,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textoFuerte,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (product.brand.isNotEmpty)
                            Text(
                              product.brand,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.texto.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Category
            Expanded(
              flex: 1,
              child: Tooltip(
                message: product.category,
                child: Center(
                  child: Icon(
                    _categoryIcons[product.category] ?? Icons.category,
                    color: AppColors.texto,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Brand
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  product.brand.isNotEmpty ? product.brand : '—',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Sizes.fontSizeSm,
                    color: AppColors.texto,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Color
            Expanded(
              flex: 2,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: displayColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.lino),
                      ),
                    ),
                    const SizedBox(width: Sizes.sm),
                    Text(
                      product.color.isNotEmpty ? product.color : '—',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Sizes.fontSizeSm,
                        color: AppColors.texto,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Weight
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  product.weight.isNotEmpty ? product.weight : '—',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: Sizes.fontSizeSm,
                    color: AppColors.texto,
                  ),
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Sizes.fontSizeSm,
                      fontWeight: FontWeight.w600,
                      color: statusColor.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            // Stock
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: Sizes.fontSizeSm,
                      fontWeight: FontWeight.bold,
                      color: AppColors.texto,
                    ),
                    children: [
                      TextSpan(text: '${product.currentStock} '),
                      TextSpan(
                        text: '/ ${product.totalStock}',
                        style: TextStyle(color: AppColors.texto),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            SizedBox(
              width: 48,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: AppColors.texto),
                iconSize: 20,
                onSelected: (action) {
                  if (action == 'edit') {
                    _showProductForm(existing: product);
                  } else if (action == 'delete') {
                    _confirmDelete(product);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(
                          'Eliminar',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppColors.textoFuerte,
        letterSpacing: 1.2,
      ),
    );
  }
}
