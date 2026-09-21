import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

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
  NavItem(label: 'Configurações do Sistema', icon: Icons.settings_rounded, route: '/settings'),
];

class AppNavbar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onSelect;
  final bool syncConnected;

  const AppNavbar({
    super.key,
    required this.currentRoute,
    required this.onSelect,
    this.syncConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Logo(),
        _SyncStatus(connected: syncConnected),
        const SizedBox(height: 8),
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

class _SyncStatus extends StatelessWidget {
  final bool connected;
  const _SyncStatus({required this.connected});

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.success : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                connected ? 'BDGD Sync: Conectado' : 'BDGD Sync: Offline',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Text('v4.2.1', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
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