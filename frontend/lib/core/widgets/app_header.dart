import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userName;
  final String? userEmail;
  final VoidCallback? onMenuTap;
  final VoidCallback? onHelpTap;
  final VoidCallback? onLogout;

  const AppHeader({
    super.key,
    required this.title,
    this.userName = 'Usuário',
    this.userEmail,
    this.onMenuTap,
    this.onHelpTap,
    this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
            ),
            child: Row(
              children: [
                if (isMobile)
                  IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: onMenuTap,
                    tooltip: 'Abrir menu',
                  ),
                _Avatar(name: userName, radius: isMobile ? 18 : 22),
                const SizedBox(width: 12),
                Expanded(
                  child: _UserInfo(
                    name: userName,
                    email: userEmail,
                  ),
                ),
                if (onHelpTap != null) ...[
                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
                    onPressed: onHelpTap,
                    tooltip: 'Tutorial & Ajuda desta tela',
                  ),
                  const SizedBox(width: 8),
                ],
                const SizedBox(width: 12),
                _LogoutButton(compact: isMobile, onPressed: onLogout),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

class _Avatar extends StatelessWidget {
  final String name;
  final double radius;

  const _Avatar({required this.name, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: Text(
        _initials(name),
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  final String name;
  final String? email;

  const _UserInfo({required this.name, this.email});

  @override
  Widget build(BuildContext context) {
    final hasEmail = email != null && email!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.25,
          ),
        ),
        if (hasEmail)
          Text(
            email!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final bool compact;
  final VoidCallback? onPressed;

  const _LogoutButton({required this.compact, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        onPressed: onPressed,
        tooltip: 'Sair',
        icon: const Icon(Icons.logout_rounded, size: 18),
        color: AppColors.textSecondary,
      );
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text('Sair'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
