import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              _buildHeader(),
              _buildStatsBar(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? Sizes.md : Sizes.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(),
                      const SizedBox(height: Sizes.md),
                      Expanded(
                        child: isMobile
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: 860,
                                  child: _buildInventoryTable(),
                                ),
                              )
                            : _buildInventoryTable(),
                      ),
                      const SizedBox(height: Sizes.md),
                      _buildViewMoreButton(),
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

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

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
                    onPressed: () {},
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
                        onPressed: () {},
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
      },
    );
  }

  Widget _buildStatsBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

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
                'TOTAL MADEJAS:',
                '1,250',
                AppColors.verdeOliva,
                trend: '+5%',
              ),
              if (!isMobile) _buildStatDivider(),
              _buildStatItem('POR AGOTAR:', '12', AppColors.error),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color valueColor, {
    String? trend,
  }) {
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
        if (trend != null) ...[
          const SizedBox(width: 4),
          Text(
            trend,
            style: const TextStyle(fontSize: 9, color: AppColors.success),
          ),
        ],
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
          onPressed: () {
            // TODO: Filtros
          },
          icon: const Icon(Icons.filter_alt_outlined),
          iconSize: 20,
          color: AppColors.texto,
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildInventoryTable() {
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
                    Expanded(flex: 2, child: _TableHeaderCell('COLOR')),
                    Expanded(flex: 1, child: _TableHeaderCell('PESO')),
                    Expanded(flex: 2, child: _TableHeaderCell('ESTADO')),
                    Expanded(flex: 2, child: _TableHeaderCell('STOCK')),
                    SizedBox(width: 48),
                  ],
                ),
              ),
              // Table rows
              _buildTableRow(
                image:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDbXkUeLoUTwMXlIqn1xubaFp519aSrOv5jVZWZvgg0TUgEm6eRbTGMrsWDnOYTaspqBZtPlBhyz8vHz_g6FnIAW0oCu3oE2dxniH4kPbb-mvblw-pewpZaR15TKlAk2SsMGN3Lbzxbda5YSD75edVBLKmtxs3vN2lRNvrMGvJT-48d6KF-PZijHddPh94hDqfZOIam67ND-geIRcn2ogkAa_MrI1T3dKk1uLZfZw5yP4ktbEfSbrpfB-y2JHWU4PTFUfEWkh-8sTg',
                name: 'Algodón Premium',
                category: 'Madeja',
                color: const Color(0xFFE9967A),
                colorHex: '#E9967A',
                weight: '100g',
                status: 'OK',
                statusColor: AppColors.success,
                currentStock: 45,
                totalStock: 50,
              ),
              _buildTableRow(
                image:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDw0X8AB0tGQPGNS_5rmSGARVF6onezuefnnohzFKKgRoB11QWyKqSt7LZXnAtNP6IJnEBMaQCaNA59tRuhMYJZkilDbI4XH-yOOWlc4i1l7V7FsqepIWP8fTnyN4h69o6PFYNFQsjrwH5216jDNL02fK6fq6xK-Gh6Rxx_ftazZSTD21gfy3LKaiA3m8QjKZf07IuaBj4JslyDVXepuD2xi6j4LnS5X4vvOhcySjd9ljWyW-D_REgsP6g6pCgXvr7y4GsZ47OJqGs',
                name: 'Lana Merino',
                category: 'Madeja',
                color: const Color(0xFFF5F5DC),
                colorHex: '#F5F5DC',
                weight: '50g',
                status: 'BAJO STOCK',
                statusColor: AppColors.error,
                currentStock: 5,
                totalStock: 100,
              ),
              _buildTableRow(
                image:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDyMdcqV9qQeMzewA5i_8YFw82jhTCnU6j1BKc2EzCOfWSxyqIyEdLfH-W7bxsb74v_npd7pxTWEi2W1HNuwdVHtZM-7zcYG8LTn8OKkIFdFtrhkfFhfkIlNXAolibIaS0a69L5qk_i7CwDuQj_6VvBvmYtd2g8b1GrYIBNugeX3U4y7_kVaNYBR5uQl1BefIDuS47Ay3U2_7faElOWeJQVme5fkVzfB9FOPoT4C72epuKWOaqxzr5O0nhKBpWwYMQlILtnsNwwtQE',
                name: 'Trapillo Soft',
                category: 'Madeja',
                color: const Color(0xFF808080),
                colorHex: '#808080',
                weight: '500g',
                status: 'LLENO',
                statusColor: AppColors.success,
                currentStock: 20,
                totalStock: 20,
              ),
              _buildTableRow(
                image:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBYmoS69opIPg2nXgY3-BKGej_pVKlfxtm4OjhOWnuSwtCQkctTz4xHNPq-RL8A1CDNDniDswKdwAfboMU-ev9g1pA9BZik0zhFUatddjyMG7youdC0j9SCJUNqrYzBKnFyIxNXWuPTUYVI4_K9xt5kcSwqFkhVyR__JUZCO5eRHrAJdhS-ALMFuJib11r0OEbHw8LXdhQ3xeCtI2HjrcGB1Y-c5iTWucSN01l94XKy0VqiRX6K91qazH9jZos2IEyuEdrohaOR13E',
                name: 'Hilo de Seda',
                category: 'Madeja',
                color: const Color(0xFFFFFACD),
                colorHex: '#FFFACD',
                weight: '25g',
                status: 'REORDENAR',
                statusColor: AppColors.warning,
                currentStock: 12,
                totalStock: 60,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow({
    required String image,
    required String name,
    required String category,
    required Color color,
    required String colorHex,
    required String weight,
    required String status,
    required Color statusColor,
    required int currentStock,
    required int totalStock,
  }) {
    return InkWell(
      onTap: () {
        // TODO: Ver detalles
      },
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
            // Product
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
                        image: DecorationImage(
                          image: NetworkImage(image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: Sizes.md),
                    SizedBox(
                      width: 120,
                      child: Text(
                        name,
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
                  category,
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
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.lino),
                      ),
                    ),
                    const SizedBox(width: Sizes.sm),
                    Text(
                      colorHex,
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
                  weight,
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
                      status,
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
                      TextSpan(text: '$currentStock '),
                      TextSpan(
                        text: '/ $totalStock',
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
              child: IconButton(
                onPressed: () {
                  // TODO: Menu de opciones
                },
                icon: Icon(Icons.more_horiz, color: AppColors.texto),
                iconSize: 20,
                splashRadius: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMoreButton() {
    return Center(
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(foregroundColor: AppColors.resaltado),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VER CATÁLOGO COMPLETO',
              style: TextStyle(
                fontSize: Sizes.fontSizeSm,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(width: Sizes.xs),
            Icon(Icons.arrow_forward, size: 16),
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
