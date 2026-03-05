import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/features/auth/presentation/providers/auth_provider.dart';

class SidebarMenu extends StatefulWidget {
  const SidebarMenu({
    super.key,
    required this.selectedRoute,
    required this.onRouteSelected,
  });

  final String selectedRoute;
  final ValueChanged<String> onRouteSelected;

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  bool _isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isCollapsed = false),
      onExit: (_) => setState(() => _isCollapsed = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isCollapsed ? 120 : 250,
        color: AppColors.verdeOliva,
        child: Column(
          children: [
            // Header con logo
            Container(
              padding: const EdgeInsets.all(Sizes.lg),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Sizes.radiusLg),
                    ),
                    child: Image.asset(
                      'assets/images/logoAndi.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (!_isCollapsed) ...[
                    const SizedBox(height: Sizes.md),
                    const Text(
                      'AndiCrochett',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textoFuerte,
                        fontSize: Sizes.fontSizeXl,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lora',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: AppColors.border),
            // Menú items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: Sizes.md),
                children: [
                  _MenuItem(
                    icon: Icons.dashboard,
                    label: 'Inicio',
                    route: 'home',
                    isSelected: widget.selectedRoute == 'home',
                    isCollapsed: _isCollapsed,
                    onTap: () => widget.onRouteSelected('home'),
                  ),
                  _MenuItem(
                    icon: Icons.inventory_2,
                    label: 'Inventario',
                    route: 'inventory',
                    isSelected: widget.selectedRoute == 'inventory',
                    isCollapsed: _isCollapsed,
                    onTap: () => widget.onRouteSelected('inventory'),
                  ),
                  _MenuItem(
                    icon: Icons.calendar_today,
                    label: 'Agenda',
                    route: 'agenda',
                    isSelected: widget.selectedRoute == 'agenda',
                    isCollapsed: _isCollapsed,
                    onTap: () => widget.onRouteSelected('agenda'),
                  ),
                  _MenuItem(
                    icon: Icons.design_services,
                    label: 'Diseños',
                    route: 'designs',
                    isSelected: widget.selectedRoute == 'designs',
                    isCollapsed: _isCollapsed,
                    onTap: () => widget.onRouteSelected('designs'),
                  ),
                  _MenuItem(
                    icon: Icons.person,
                    label: 'Perfil',
                    route: 'profile',
                    isSelected: widget.selectedRoute == 'profile',
                    isCollapsed: _isCollapsed,
                    onTap: () => widget.onRouteSelected('profile'),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border),
            // Botón de cierre de sesión
            // Llama a AuthProvider.signOut() para que Firebase.Auth() invalide
            // la sesión y _AuthGate redirija automáticamente a LoginPage.
            // NO se navega manualmente — _AuthGate escucha el stream de auth.
            _MenuItem(
              icon: Icons.logout,
              label: 'Cerrar Sesión',
              route: 'logout',
              isSelected: false,
              isCollapsed: _isCollapsed,
              onTap: () {
                context.read<AuthProvider>().signOut();
              },
            ),
            const SizedBox(height: Sizes.md),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.md,
        vertical: Sizes.xs,
      ),
      child: Material(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Sizes.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Sizes.radiusMd),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? Sizes.md : Sizes.sm,
              vertical: Sizes.md,
            ),
            child: isCollapsed
                ? Center(
                    child: Icon(
                      icon,
                      color: AppColors.texto,
                      size: Sizes.iconMd,
                    ),
                  )
                : Row(
                    children: [
                      Icon(icon, color: AppColors.texto, size: Sizes.iconMd),
                      const SizedBox(width: Sizes.sm),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.texto,
                            fontSize: isSelected
                                ? Sizes.fontSizeLg
                                : Sizes.fontSizeMd,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isSelected) const SizedBox(width: Sizes.xs),
                      if (isSelected)
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.textoFuerte,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
