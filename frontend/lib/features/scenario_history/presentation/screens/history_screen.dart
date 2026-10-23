import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../scenario_config/data/services/scenario_storage_service.dart';
import '../../../scenario_config/domain/models/scenario_config_model.dart';
import '../../data/models/scenario_models.dart';
import '../controllers/scenario_history_controller.dart';
import '../widgets/scenario_comparison_dialog.dart';
import '../widgets/scenario_detail_sheet.dart';
import '../widgets/scenario_history_card.dart';

const double _compactContentWidth = 640;

class HistoryScreen extends StatefulWidget {
  final ScenarioHistoryController? controller;
  final bool enableMapTiles;

  const HistoryScreen({
    super.key,
    this.controller,
    this.enableMapTiles = true,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final ScenarioHistoryController _controller;
  final ScenarioStorageService _storageService = ScenarioStorageService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScenarioHistoryController();
    _controller.loadScenarios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? AppColors.vermelhoErro : AppColors.verdeSucesso,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _showLastFeedback({required bool succeeded}) {
    final message = succeeded
        ? _controller.successMessage
        : _controller.errorMessage;
    if (message != null) {
      _showMessage(message, isError: !succeeded);
    }
    _controller.clearMessages();
  }

  Future<void> _handleViewDetails(ScenarioSummary scenario) async {
    final detail = await _controller.loadScenarioDetail(scenario.id);
    if (!mounted) return;

    if (detail == null) {
      _showLastFeedback(succeeded: false);
      return;
    }
    await ScenarioDetailSheet.show(
      context,
      detail,
      enableMapTiles: widget.enableMapTiles,
      onViewResult: () => _handleViewResult(scenario),
      onReuseConfig: () => _handleReuseConfig(scenario),
    );
  }

  Future<void> _handleViewResult(ScenarioSummary scenario) async {
    final detail = await _controller.loadScenarioDetail(scenario.id);
    if (!mounted) return;

    if (detail == null) {
      _showLastFeedback(succeeded: false);
      return;
    }

    final simScenario = detail.toSimulationScenario();
    await _storageService.saveLastSimulationScenario(simScenario);
    if (!mounted) return;

    Navigator.of(context).pushNamed('/results', arguments: simScenario);
  }

  Future<void> _handleReuseConfig(ScenarioSummary scenario) async {
    final detail = await _controller.loadScenarioDetail(scenario.id);
    if (!mounted) return;

    if (detail == null) {
      _showLastFeedback(succeeded: false);
      return;
    }

    final config = ScenarioConfigModel(
      propagationModel: detail.propagationModel ?? 'OKUMURA_HATA_SUBURBAN',
      minCoveragePercent: detail.coverageTargetPct ?? 85.0,
      maxGateways: detail.maxGateways ?? 12,
      frequencyMhz: detail.rfParameter?.frequencyMhz ?? 915.0,
      txPowerDbm: detail.rfParameter?.transmitPowerDbm ?? 21.0,
      rxSensitivityDbm: detail.rfParameter?.receiverSensitivityDbm ?? -120.0,
      gatewayHeightM: detail.rfParameter?.antennaHeightM ?? 6.0,
      deviceHeightM: detail.rfParameter?.deviceHeightM ?? 5.0,
      fadeMarginDb: 10.0,
    );

    await _storageService.saveScenario(config);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Parâmetros do cenário reaproveitados para nova simulação!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryPurple,
      ),
    );

    Navigator.of(context).pushNamed('/scenario/rf');
  }

  Future<void> _handleCompareScenarios() async {
    final comparison = await _controller.compareSelectedScenarios();
    if (!mounted) return;

    if (comparison == null) {
      _showLastFeedback(succeeded: false);
      return;
    }

    await ScenarioComparisonDialog.show(
      context,
      scenarios: comparison.scenarios,
      onViewResult: (scen) => _handleViewResult(scen),
    );
  }

  Future<void> _handleDuplicate(ScenarioSummary scenario) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => _DuplicateScenarioDialog(suggestedName: '${scenario.name} (cópia)'),
    );

    if (newName == null || !mounted) return;

    final succeeded = await _controller.duplicateScenario(scenario.id, name: newName);
    if (!mounted) return;
    _showLastFeedback(succeeded: succeeded);
  }

  Future<void> _handleDelete(ScenarioSummary scenario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Cenário'),
        content: Text(
          'Deseja realmente excluir o cenário "${scenario.name.isEmpty ? scenario.id : scenario.name}"? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final succeeded = await _controller.deleteScenario(scenario.id);
    if (!mounted) return;
    _showLastFeedback(succeeded: succeeded);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Histórico de Simulações',
      currentRoute: '/history',
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < _compactContentWidth;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, isCompact: isCompact),
                  SizedBox(height: isCompact ? 16 : 20),
                  _buildFilters(isCompact: isCompact),
                  if (_controller.selectedIds.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildComparisonBar(isCompact: isCompact),
                  ],
                  SizedBox(height: isCompact ? 14 : 18),
                  _buildList(isCompact: isCompact),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isCompact}) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cenários Salvos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Consulte os cenários salvos, filtre por região, compare indicadores e reaproveite parâmetros para novas simulações.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
      ],
    );

    final action = ElevatedButton.icon(
      onPressed: () => Navigator.of(context).pushReplacementNamed('/scenario'),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Nova Simulação'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: Size(0, isCompact ? 44 : 40),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const SizedBox(height: 12), action],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Expanded(child: title), const SizedBox(width: 16), action],
    );
  }

  void _handleRegionSelected(String? region) {
    _controller.selectRegion(region == _controller.selectedRegion ? null : region);
  }

  Widget _buildFilters({required bool isCompact}) {
    final searchField = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _controller.setSearchQuery,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Buscar por nome do cenário...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _controller.setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );

    final regions = _controller.regions;
    final selected = _controller.selectedRegion;

    final dropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selected,
          hint: const Text(
            'Todas as regiões',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          items: regions
              .map(
                (region) => DropdownMenuItem<String>(
                  value: region,
                  child: Text(
                    region,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
          onChanged: _controller.isLoading ? null : _handleRegionSelected,
        ),
      ),
    );

    final regionLabel = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        const Flexible(
          child: Text(
            'Filtrar por região:',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 10),
          regionLabel,
          const SizedBox(height: 6),
          dropdown,
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: searchField,
        ),
        const SizedBox(width: 16),
        regionLabel,
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
          child: dropdown,
        ),
      ],
    );
  }

  Widget _buildComparisonBar({required bool isCompact}) {
    final count = _controller.selectedIds.length;
    final canCompare = _controller.canCompare;

    final infoText = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.compare_arrows_rounded, color: AppColors.primaryPurple, size: 20),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            '$count cenário${count > 1 ? 's' : ''} selecionado${count > 1 ? 's' : ''} para comparação',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );

    final compareBtn = ElevatedButton.icon(
      onPressed: canCompare && !_controller.isLoading ? _handleCompareScenarios : null,
      icon: _controller.isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.compare_rounded, size: 18),
      label: Text(canCompare ? 'Comparar Lado a Lado' : 'Selecione mais um'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    final clearBtn = TextButton(
      onPressed: _controller.clearSelection,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
      ),
      child: const Text('Limpar seleção'),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryPurpleUltraLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                infoText,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: compareBtn),
                    const SizedBox(width: 8),
                    clearBtn,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: infoText),
                clearBtn,
                const SizedBox(width: 12),
                compareBtn,
              ],
            ),
    );
  }

  Widget _buildList({required bool isCompact}) {
    if (_controller.isLoading && _controller.rawScenarios.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: isCompact ? 40 : 48),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
      );
    }

    final error = _controller.errorMessage;
    if (error != null && _controller.rawScenarios.isEmpty) {
      return _MessageState(
        icon: Icons.cloud_off_rounded,
        iconColor: AppColors.vermelhoErro,
        title: 'Não foi possível carregar os cenários',
        description: error,
        actionLabel: 'Tentar novamente',
        onAction: _controller.loadScenarios,
        isCompact: isCompact,
      );
    }

    if (_controller.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: isCompact ? 32 : 48),
        child: const Center(
          child: Text(
            'Nenhuma informação encontrada',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Se o usuário selecionou uma região específica, não precisamos do agrupamento repetido
    if (_controller.selectedRegion != null) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _controller.scenarios.length,
        separatorBuilder: (_, index) => SizedBox(height: isCompact ? 10 : 12),
        itemBuilder: (context, index) {
          final scenario = _controller.scenarios[index];
          return ScenarioHistoryCard(
            scenario: scenario,
            isMutating: _controller.isMutating,
            isSelected: _controller.isSelected(scenario.id),
            onToggleSelect: () => _controller.toggleSelection(scenario.id),
            onViewDetails: () => _handleViewDetails(scenario),
            onViewResult: () => _handleViewResult(scenario),
            onReuseConfig: () => _handleReuseConfig(scenario),
            onDuplicate: () => _handleDuplicate(scenario),
            onDelete: () => _handleDelete(scenario),
          );
        },
      );
    }

    // Listagem organizada e agrupada por região
    final grouped = _controller.groupedScenarios;
    final regionKeys = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < regionKeys.length; i++) ...[
          if (i > 0) SizedBox(height: isCompact ? 18 : 24),
          _buildRegionHeader(
            region: regionKeys[i],
            count: grouped[regionKeys[i]]!.length,
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 8 : 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: grouped[regionKeys[i]]!.length,
            separatorBuilder: (_, index) => SizedBox(height: isCompact ? 10 : 12),
            itemBuilder: (context, index) {
              final scenario = grouped[regionKeys[i]]![index];
              return ScenarioHistoryCard(
                scenario: scenario,
                isMutating: _controller.isMutating,
                isSelected: _controller.isSelected(scenario.id),
                onToggleSelect: () => _controller.toggleSelection(scenario.id),
                onViewDetails: () => _handleViewDetails(scenario),
                onViewResult: () => _handleViewResult(scenario),
                onReuseConfig: () => _handleReuseConfig(scenario),
                onDuplicate: () => _handleDuplicate(scenario),
                onDelete: () => _handleDelete(scenario),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRegionHeader({
    required String region,
    required int count,
    required bool isCompact,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 18,
            color: AppColors.primaryPurple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Região: $region',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleUltraLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count cenário${count > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicateScenarioDialog extends StatefulWidget {
  final String suggestedName;

  const _DuplicateScenarioDialog({required this.suggestedName});

  @override
  State<_DuplicateScenarioDialog> createState() => _DuplicateScenarioDialogState();
}

class _DuplicateScenarioDialogState extends State<_DuplicateScenarioDialog> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.suggestedName);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Duplicar Cenário'),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nome do novo cenário'),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_nameController.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Duplicar'),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isCompact;

  const _MessageState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final padding = isCompact ? 20.0 : 32.0;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              decoration: const BoxDecoration(
                color: AppColors.primaryPurpleUltraLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: isCompact ? 28 : 36),
            ),
            SizedBox(height: isCompact ? 14 : 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isCompact ? 16 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: isCompact ? 18 : 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                minimumSize: Size(isCompact ? double.infinity : 0, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
