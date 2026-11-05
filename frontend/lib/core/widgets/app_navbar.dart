import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NavItem {
  final String label;
  final IconData icon;
  final String route;

  const NavItem({required this.label, required this.icon, required this.route});
}

const List<NavItem> kNavItems = [
  NavItem(label: 'Importação BDGD', icon: Icons.cloud_upload_rounded, route: '/bdgd-import'),
  NavItem(label: 'Configuração de Cenário', icon: Icons.tune_rounded, route: '/scenario'),
  NavItem(label: 'Resultados & Cobertura', icon: Icons.wifi_tethering_rounded, route: '/results'),
  NavItem(label: 'Histórico de Simulações', icon: Icons.history_rounded, route: '/history'),
  // NavItem(label: 'Configurações do Sistema', icon: Icons.settings_rounded, route: '/settings'),
];

const NavItem kManualNavItem = NavItem(
  label: 'Manual do Usuário',
  icon: Icons.menu_book_rounded,
  route: '/manual',
);

class AppNavbar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onSelect;

  const AppNavbar({
    super.key,
    required this.currentRoute,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Logo(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: kNavItems
                .map((item) => _NavTile(
                      item: item,
                      selected: item.route == currentRoute,
                      onTap: () => onSelect(item.route),
                    ))
                .toList(),
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          child: _NavTile(
            item: kManualNavItem,
            selected: currentRoute == kManualNavItem.route,
            onTap: () => onSelect(kManualNavItem.route),
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
            Image.asset('assets/images/logo.png', height: 32),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
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