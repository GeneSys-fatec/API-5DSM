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
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: widget.section.steps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final step = widget.section.steps[index];
        return Row(
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
        );
      },
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
