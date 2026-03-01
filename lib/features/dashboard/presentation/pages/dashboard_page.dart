import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/dashboard/presentation/widgets/sidebar_menu.dart';
import 'package:andicrochett/features/dashboard/presentation/widgets/dashboard_footer.dart';
import 'package:andicrochett/features/inventory/presentation/pages/inventory_page.dart';

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

  Widget _buildContent() {
    switch (_selectedRoute) {
      case 'home':
        return const _HomeView();
      case 'inventory':
        return const InventoryPage();
      case 'agenda':
        return const Center(child: Text('Agenda'));
      case 'patterns':
        return const Center(child: Text('Patrones'));
      case 'profile':
        return const Center(child: Text('Perfil'));
      default:
        return const _HomeView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            // Layout de escritorio con grid
            return Row(
              children: [
                // div1: Menú lateral animado
                SidebarMenu(
                  selectedRoute: _selectedRoute,
                  onRouteSelected: _onMenuItemSelected,
                ),
                // div2 y div3: Contenido principal + footer (4 columnas de 5)
                Expanded(
                  child: Column(
                    children: [
                      // div2: Área de contenido (4 filas de 5)
                      Expanded(
                        flex: 4,
                        child: Container(
                          color: AppColors.background,
                          child: _buildContent(),
                        ),
                      ),
                      // div3: Footer (1 fila de 5)
                      const SizedBox(height: 60, child: DashboardFooter()),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Layout móvil con Drawer
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

// Vista de inicio temporal
class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
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
              _DashboardCard(
                title: 'Inventario',
                value: '124',
                subtitle: 'productos',
                color: AppColors.bronce,
                icon: Icons.inventory_2,
              ),
              _DashboardCard(
                title: 'Pedidos',
                value: '8',
                subtitle: 'pendientes',
                color: AppColors.verdeOliva,
                icon: Icons.receipt_long,
              ),
              _DashboardCard(
                title: 'Patrones',
                value: '32',
                subtitle: 'creados',
                color: AppColors.resaltado,
                icon: Icons.grid_on,
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
