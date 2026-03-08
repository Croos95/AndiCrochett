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
                await _repo.update(product.copyWith(
                  id: existing.id,
                  userId: existing.userId,
                ));
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
        title: const Text('Eliminar producto'),
        content: Text('Â¿Eliminar "${product.name}"? Esta acciÃ³n no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
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
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allProducts = snapshot.data ?? [];
                    final products = _searchQuery.isEmpty
                        ? allProducts
                        : allProducts
                            .where((p) => p.name
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                            .toList();

                    final totalStock = allProducts.fold<int>(
                        0, (s, p) => s + p.currentStock);
                    final lowCount = allProducts
                        .where((p) =>
                            p.status == ProductStatus.lowStock ||
                            p.status == ProductStatus.outOfStock)
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
                                isMobile ? Sizes.md : Sizes.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(),
                                const SizedBox(height: Sizes.md),
                                Expanded(
                                  child: products.isEmpty
                                      ? _buildEmptyState()
                                      : isMobile
                                          ? SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: SizedBox(
                                                width: 860,
                                                child: _buildInventoryTable(
                                                    products),
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
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.texto),
          const SizedBox(height: Sizes.md),
          Text(
            _searchQuery.isEmpty
                ? 'No hay productos aÃºn'
                : 'No se encontraron resultados',
            style: TextStyle(
              fontSize: Sizes.fontSizeLg,
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
                      fillColor: AppColors.background,
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
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sizes.md,
                      ),
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
        color: Colors.white.withValues(alpha: 0.2),
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
          _buildStatItem(
            'POR AGOTAR:',
            lowCount.toString(),
            AppColors.error,
          ),
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

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.filter_alt_outlined),
          iconSize: 20,
          color: AppColors.texto,
          splashRadius: 20,
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
                    Expanded(flex: 1, child: _TableHeaderCell('CATEGORÃA')),
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
                              borderRadius:
                                  BorderRadius.circular(Sizes.radiusMd),
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.inventory_2,
                                  color: displayColor,
                                  size: 20,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.inventory_2,
                              color: displayColor,
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: Sizes.md),
                    SizedBox(
                      width: 120,
                      child: Text(
                        product.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: Sizes.fontSizeMd,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textoFuerte,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Category
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  product.category,
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
                      product.color.isNotEmpty ? product.color : 'â€”',
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
                  product.weight.isNotEmpty ? product.weight : 'â€”',
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: Sizes.sm),
                    Text(
                      statusLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
                        Text('Eliminar',
                            style: TextStyle(color: AppColors.error)),
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
