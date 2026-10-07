import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../models/manual_content.dart';
import '../widgets/manual_section_previews.dart';

class ManualScreen extends StatefulWidget {
  final String? initialSectionId;

  const ManualScreen({super.key, this.initialSectionId});

  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  late String _selectedSectionId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSectionId = widget.initialSectionId ?? kManualSections.first.id;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && findManualSectionById(args) != null) {
      _selectedSectionId = args;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ManualSection get _currentSection {
    return findManualSectionById(_selectedSectionId) ?? kManualSections.first;
  }

  List<ManualSection> get _filteredSections {
    if (_searchQuery.trim().isEmpty) {
      return kManualSections;
    }
    final q = _searchQuery.toLowerCase();
    return kManualSections.where((s) {
      final matchesTitle = s.title.toLowerCase().contains(q);
      final matchesSubtitle = s.subtitle.toLowerCase().contains(q);
      final matchesOverview = s.overview.toLowerCase().contains(q);
      final matchesSteps = s.steps.any((step) =>
          step.title.toLowerCase().contains(q) ||
          step.description.toLowerCase().contains(q));
      final matchesFields = s.fields.any((field) =>
          field.name.toLowerCase().contains(q) ||
          field.description.toLowerCase().contains(q));
      return matchesTitle || matchesSubtitle || matchesOverview || matchesSteps || matchesFields;
    }).toList();
  }

  void _selectSection(String id) {
    setState(() {
      _selectedSectionId = id;
    });
  }

  void _nextSection() {
    final currentIndex = kManualSections.indexWhere((s) => s.id == _selectedSectionId);
    if (currentIndex < kManualSections.length - 1) {
      _selectSection(kManualSections[currentIndex + 1].id);
    }
  }

  void _prevSection() {
    final currentIndex = kManualSections.indexWhere((s) => s.id == _selectedSectionId);
    if (currentIndex > 0) {
      _selectSection(kManualSections[currentIndex - 1].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppScaffold(
      title: 'Manual do Usuário',
      currentRoute: '/manual',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroBanner(context),
          const SizedBox(height: 20),
          if (isMobile)
            _buildMobileLayout()
          else
            _buildDesktopLayout(),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual do Usuário & Guia de Operação',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Documentação completa de cada funcionalidade da plataforma Tecsys.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Pesquise por funcionalidades, parâmetros de RF, BDGD ou passos...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 300,
          child: _buildSectionSidebar(),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildSectionContent(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filteredSections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final section = _filteredSections[index];
              final isSelected = section.id == _selectedSectionId;
              return FilterChip(
                selected: isSelected,
                label: Text(section.title),
                avatar: Icon(section.icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                backgroundColor: AppColors.surfaceWhite,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                ),
                onSelected: (_) => _selectSection(section.id),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionContent(),
      ],
    );
  }

  Widget _buildSectionSidebar() {
    final sections = _filteredSections;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Text(
              'SEÇÕES DO MANUAL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (sections.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Nenhuma seção encontrada para o termo pesquisado.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sections.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final section = sections[index];
                final isSelected = section.id == _selectedSectionId;

                return InkWell(
                  onTap: () => _selectSection(section.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: isSelected ? AppColors.primaryLight.withOpacity(0.6) : Colors.transparent,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            section.icon,
                            size: 18,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${section.steps.length} passos',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionContent() {
    final section = _currentSection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          section.subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(section.routeTarget);
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Ir para Tela'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ManualSectionPreviewCard(sectionId: section.id),
              const SizedBox(height: 24),
              const Text(
                'Visão Geral',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                section.overview,
                style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              const Text(
                'Guia Passo a Passo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ...section.steps.map((step) => _buildStepCard(step)),
              if (section.fields.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text(
                  'Campos & Parâmetros Detalhados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                ...section.fields.map((f) => _buildFieldCard(f)),
              ],
              const SizedBox(height: 28),
              _buildTipsAndWarnings(section),
              const SizedBox(height: 32),
              _buildPaginationControls(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(ManualStepItem step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.stepNumber}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(ManualFieldItem field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                field.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              field.description,
              style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary),
            ),
          ),
          if (field.example != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                'Exemplo: ${field.example}',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          if (field.rule != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text(
                'Regra: ${field.rule}',
                style: const TextStyle(fontSize: 11, color: Colors.brown),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipsAndWarnings(ManualSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.tips.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7).withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dicas & Boas Práticas',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...section.tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                          Expanded(
                            child: Text(tip, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF78350F))),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (section.warnings.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.vermelhoErro, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Atenção & Limitações Regulamentares',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...section.warnings.map((warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
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
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaginationControls() {
    final currentIndex = kManualSections.indexWhere((s) => s.id == _selectedSectionId);
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < kManualSections.length - 1;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      children: [
        if (hasPrev)
          OutlinedButton.icon(
            onPressed: _prevSection,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text(kManualSections[currentIndex - 1].title),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        if (hasNext)
          ElevatedButton.icon(
            onPressed: _nextSection,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(kManualSections[currentIndex + 1].title),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
      ],
    );
  }
}
