import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';

/// Elemento de menú para el sidebar genérico.
class SidebarItem {
  const SidebarItem({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}

/// Sidebar genérico reutilizable.
///
/// El sidebar del dashboard en [SidebarMenu] usa su propia implementación
/// con animaciones. Esta versión genérica se puede usar en otros contextos.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.items,
    required this.selectedRoute,
    required this.onRouteSelected,
    this.header,
    this.footer,
  });

  final List<SidebarItem> items;
  final String selectedRoute;
  final ValueChanged<String> onRouteSelected;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.verdeOliva,
      child: Column(
        children: [
          if (header != null) header!,
          const SizedBox(height: Sizes.md),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Sizes.sm),
              children: items.map((item) {
                final isSelected = item.route == selectedRoute;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? AppColors.resaltado : Colors.white70,
                    size: 22,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: Sizes.fontSizeMd,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.white.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Sizes.radiusMd),
                  ),
                  onTap: () => onRouteSelected(item.route),
                );
              }).toList(),
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}
