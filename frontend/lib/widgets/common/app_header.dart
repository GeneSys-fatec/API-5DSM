import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userName;
  final VoidCallback? onMenuTap;

  const AppHeader({
    super.key,
    required this.title,
    this.userName = 'Usuário',
    this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      height: preferredSize.height,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: onMenuTap,
              tooltip: 'Abrir menu',
            ),
          const Spacer(),
          _UserBadge(userName: userName, compact: isMobile),
        ],
      ),
    );
  }
}

class _UserBadge extends StatelessWidget {
  final String userName;
  final bool compact;

  const _UserBadge({required this.userName, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          Text(
            userName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
        ],
        const CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
        ),
      ],
    );
  }
}