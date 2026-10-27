import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/auth/data/auth_service.dart';
import '../../features/manual/presentation/widgets/contextual_help_dialog.dart';
import 'app_footer.dart';
import 'app_header.dart';
import 'app_navbar.dart';

class AppScaffold extends StatefulWidget {
  final String title;
  final String currentRoute;
  final Widget body;
  final bool showFooter;
  final VoidCallback? onHelpTap;
  final bool showHelpButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.body,
    this.showFooter = true,
    this.onHelpTap,
    this.showHelpButton = true,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final AuthService _authService = AuthService();
  String _userName = 'Usuário';
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getSavedUser();
    if (!mounted || user == null) return;
    setState(() {
      if (user.name.isNotEmpty) _userName = user.name;
      _userEmail = user.email;
    });
  }

  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);
    await _authService.logout();
    navigator.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  void _handleSelect(BuildContext context, String route) {
    if (Responsive.isMobile(context)) Navigator.of(context).pop();
    if (route != widget.currentRoute) {
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
              backgroundColor: AppColors.surfaceWhite,
              child: SafeArea(
                child: AppNavbar(
                  currentRoute: widget.currentRoute,
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
                color: AppColors.surfaceWhite,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                right: false,
                child: AppNavbar(
                  currentRoute: widget.currentRoute,
                  onSelect: (r) => _handleSelect(context, r),
                ),
              ),
            ),
          Expanded(
            child: Builder(
              builder: (innerContext) {
                final helpCallback = widget.showHelpButton && widget.currentRoute != '/manual'
                    ? (widget.onHelpTap ?? () => showContextualHelpDialog(innerContext, route: widget.currentRoute))
                    : null;
                return Column(
                  children: [
                    AppHeader(
                      title: widget.title,
                      userName: _userName,
                      userEmail: _userEmail,
                      onMenuTap: () => Scaffold.of(innerContext).openDrawer(),
                      onHelpTap: helpCallback,
                      onLogout: _handleLogout,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(
                            Responsive.horizontalPadding(context)),
                        child: widget.body,
                      ),
                    ),
                    if (widget.showFooter) const AppFooter(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
