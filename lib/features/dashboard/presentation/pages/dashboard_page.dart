import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/agenda/data/models/order_model.dart';
import 'package:andicrochett/features/agenda/data/repositories/order_repository.dart';
import 'package:andicrochett/features/agenda/presentation/pages/agenda_page.dart';
import 'package:andicrochett/features/auth/presentation/pages/profile_page.dart';
import 'package:andicrochett/features/dashboard/presentation/widgets/dashboard_footer.dart';
import 'package:andicrochett/features/dashboard/presentation/widgets/sidebar_menu.dart';
import 'package:andicrochett/features/designs/presentation/pages/designs_page.dart';
import 'package:andicrochett/features/inventory/data/models/product_model.dart';
import 'package:andicrochett/features/inventory/data/repositories/inventory_repository.dart';
import 'package:andicrochett/features/inventory/presentation/pages/inventory_page.dart';
import 'package:andicrochett/features/patterns/data/models/pattern_model.dart';
import 'package:andicrochett/features/patterns/data/repositories/pattern_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedRoute = 'home';

  void _onMenuItemSelected(String route) {
    setState(() {
      _selectedRoute = route;
    });
  }

  /// Construye el widget de contenido según la ruta activa del sidebar.
  Widget _buildContent() {
    return switch (_selectedRoute) {
      'home' => const _HomeView(),
      'inventory' => const InventoryPage(),
      'agenda' => const AgendaPage(),
      'designs' => const DesignsPage(),
      'profile' => const ProfilePage(),
      _ => const _HomeView(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            return Row(
              children: [
                SidebarMenu(
                  selectedRoute: _selectedRoute,
                  onRouteSelected: _onMenuItemSelected,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
                          color: AppColors.background,
                          child: _buildContent(),
                        ),
                      ),
                      const SizedBox(height: 60, child: DashboardFooter()),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.verdeOliva,
                foregroundColor: Colors.white,
                title: const Text('AndiCrochett'),
              ),
              drawer: Drawer(
                child: SidebarMenu(
                  selectedRoute: _selectedRoute,
                  onRouteSelected: (route) {
                    _onMenuItemSelected(route);
                    Navigator.pop(context);
                  },
                ),
              ),
              body: Column(
                children: [
                  Expanded(child: _buildContent()),
                  const SizedBox(height: 60, child: DashboardFooter()),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final _inventoryRepo = InventoryRepository();
  final _orderRepo = OrderRepository();
  final _patternRepo = PatternRepository();

  late final Future<List<ProductModel>> _productsFuture;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _productsFuture = _inventoryRepo.getAllProducts();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Sizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panel Principal',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textoFuerte,
              fontFamily: 'Lora',
            ),
          ),
          const SizedBox(height: Sizes.lg),
          Wrap(
            spacing: Sizes.md,
            runSpacing: Sizes.md,
            children: [
              FutureBuilder<List<ProductModel>>(
                future: _productsFuture,
                builder: (_, snap) => _DashboardCard(
                  title: 'Inventario',
                  value: '${snap.data?.length ?? 0}',
                  subtitle: 'productos',
                  color: AppColors.bronce,
                  icon: Icons.inventory_2,
                ),
              ),
              // Añadido <List<OrderModel>> para resolver el error en .where() y .length
              StreamBuilder<List<OrderModel>>(
                stream: _orderRepo.watchByUser(uid),
                builder: (_, snap) {
                  final pending = snap.data?.where(
                        (o) => o.status == OrderStatus.pending || o.status == OrderStatus.inProgress,
                      ).length ?? 0;
                  return _DashboardCard(
                    title: 'Pedidos',
                    value: '$pending',
                    subtitle: 'pendientes',
                    color: AppColors.verdeOliva,
                    icon: Icons.receipt_long,
                  );
                },
              ),
              StreamBuilder<List<PatternModel>>(
                stream: _patternRepo.watchByUser(uid),
                builder: (_, snap) => _DashboardCard(
                  title: 'Patrones',
                  value: '${snap.data?.length ?? 0}',
                  subtitle: 'creados',
                  color: AppColors.resaltado,
                  icon: Icons.grid_on,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(Sizes.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Sizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Sizes.radiusMd),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: Sizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: Sizes.fontSizeSm,
                    color: AppColors.texto,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textoFuerte,
                    fontFamily: 'Lora',
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: Sizes.fontSizeSm,
                    color: AppColors.texto,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}