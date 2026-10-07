import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../models/manual_content.dart';

void showContextualHelpDialog(
  BuildContext context, {
  String? route,
  String? sectionId,
}) {
  ManualSection section;
  if (sectionId != null) {
    section = findManualSectionById(sectionId) ?? kManualSections.first;
  } else if (route != null) {
    section = getManualSectionForRoute(route);
  } else {
    section = kManualSections.first;
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => ContextualHelpDialog(section: section),
  );
}

class ContextualHelpDialog extends StatefulWidget {
  final ManualSection section;

  const ContextualHelpDialog({super.key, required this.section});

  @override
  State<ContextualHelpDialog> createState() => _ContextualHelpDialogState();
}

class _ContextualHelpDialogState extends State<ContextualHelpDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void disposeValidate() {
    _tabController.dispose();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final dialogWidth = isMobile ? MediaQuery.of(context).size.width * 0.94 : 640.0;
    final dialogHeight = isMobile ? MediaQuery.of(context).size.height * 0.85 : 560.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStepsTab(),
                  _buildFieldsTab(),
                  _buildTipsTab(),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.section.icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TUTORIAL CONTEXTUAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.section.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.section.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Passo a Passo'),
          Tab(text: 'Campos & Controles'),
          Tab(text: 'Dicas & Regras'),
        ],
      ),
    );
  }

  Widget _buildStepsTab() {
    final hasImage = widget.section.imageAssetPath != null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (hasImage) ...[
          _buildScreenshotThumbnail(context),
          const SizedBox(height: 18),
        ],
        ...widget.section.steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${step.stepNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildScreenshotThumbnail(BuildContext context) {
    final imagePath = widget.section.imageAssetPath!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.photo_library_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Referência Visual da Tela',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showEnlargedImage(context),
                  icon: const Icon(Icons.fullscreen_rounded, size: 16, color: AppColors.primary),
                  label: const Text(
                    'Ampliar',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _showEnlargedImage(context),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondary),
                      ),
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.18),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Clique para ver o print em alta resolução',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEnlargedImage(BuildContext context) {
    if (widget.section.imageAssetPath == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 850),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Icon(widget.section.icon, color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.section.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.section.imageCaption ?? widget.section.subtitle,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  color: const Color(0xFF0F172A),
                  padding: const EdgeInsets.all(12),
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    child: Center(
                      child: Image.asset(
                        widget.section.imageAssetPath!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldsTab() {
    if (widget.section.fields.isEmpty) {
      return const Center(
        child: Text(
          'Esta tela não possui campos de entrada adicionais.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: widget.section.fields.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final field = widget.section.fields[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                field.description,
                style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary),
              ),
              if (field.example != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Exemplo: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Expanded(
                      child: Text(field.example!, style: const TextStyle(fontSize: 11, color: AppColors.primaryDark)),
                    ),
                  ],
                ),
              ],
              if (field.rule != null) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Regra: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                    Expanded(
                      child: Text(field.rule!, style: const TextStyle(fontSize: 11, color: Colors.brown)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.section.tips.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Dicas de Utilização',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.section.tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Expanded(
                      child: Text(tip, style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (widget.section.warnings.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.vermelhoErro),
              SizedBox(width: 8),
              Text(
                'Atenção & Limitações',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.vermelhoErro),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.section.warnings.map((warning) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('! ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.vermelhoErro)),
                    Expanded(
                      child: Text(warning, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF7F1D1D))),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed(
                '/manual',
                arguments: widget.section.id,
              );
            },
            icon: const Icon(Icons.menu_book_rounded, size: 16),
            label: const Text('Ver Manual Completo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Entendi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class ContextualHelpButton extends StatelessWidget {
  final String? route;
  final String? sectionId;
  final Color? color;
  final String tooltip;

  const ContextualHelpButton({
    super.key,
    this.route,
    this.sectionId,
    this.color,
    this.tooltip = 'Como usar esta tela',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline_rounded, color: color ?? AppColors.primary),
      tooltip: tooltip,
      onPressed: () => showContextualHelpDialog(
        context,
        route: route ?? ModalRoute.of(context)?.settings.name,
        sectionId: sectionId,
      ),
    );
  }
}
