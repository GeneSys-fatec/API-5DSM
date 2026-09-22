import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'app_footer.dart';
import 'app_header.dart';
import 'app_navbar.dart';

/// Layout padrão de todas as telas internas do sistema.
/// Uso:
/// ```dart
/// AppScaffold(
///   title: 'Importação de Dados BDGD & Ativos de Rede',
///   currentRoute: '/bdgd-import',
///   body: BdgdImportScreen(),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget body;
  final bool showFooter;

  const AppScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.body,
    this.showFooter = true,
  });

  void _handleSelect(BuildContext context, String route) {
    if (Responsive.isMobile(context)) Navigator.of(context).pop(); 
    if (route != currentRoute) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopOrTablet = !Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isDesktopOrTablet
          ? null
          : Drawer(
              backgroundColor: AppColors.surface,
              child: SafeArea(
                child: AppNavbar(
                  currentRoute: currentRoute,
                  onSelect: (r) => _handleSelect(context, r),
                ),
              ),
            ),
      body: Row(
        children: [
          if (isDesktopOrTablet)
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                right: false,
                child: AppNavbar(
                  currentRoute: currentRoute,
                  onSelect: (r) => _handleSelect(context, r),
                ),
              ),
            ),
          Expanded(
            child: Builder(
              builder: (innerContext) => Column(
                children: [
                  AppHeader(
                    title: title,
                    onMenuTap: () => Scaffold.of(innerContext).openDrawer(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                      child: body,
                    ),
                  ),
                  if (showFooter) const AppFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}