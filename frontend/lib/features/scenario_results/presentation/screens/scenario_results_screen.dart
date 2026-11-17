import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../models/scenario_results_models.dart';
import '../../../scenario_config/data/services/scenario_storage_service.dart';
import '../widgets/scenario_kpi_row.dart';
import '../widgets/scenario_map.dart';
import '../../data/services/scenario_report_service.dart';

class ScenarioResultsScreen extends StatefulWidget {
  final SimulationScenario? scenario;

  const ScenarioResultsScreen({super.key, this.scenario});

  @override
  State<ScenarioResultsScreen> createState() => _ScenarioResultsScreenState();
}

class _ScenarioResultsScreenState extends State<ScenarioResultsScreen> {
  final ScenarioStorageService _storageService = ScenarioStorageService();
  final ScenarioReportService _reportService = ScenarioReportService();
  final GlobalKey _mapCaptureKey = GlobalKey();
  SimulationScenario? _scenario;
  bool _isLoading = false;
  bool _isExportingReport = false;

  @override
  void initState() {
    super.initState();
    if (widget.scenario != null) {
      _scenario = widget.scenario;
      _storageService.saveLastSimulationScenario(widget.scenario!);
    } else {
      _loadPersistedScenario();
    }
  }

  Future<void> _loadPersistedScenario() async {
    setState(() {
      _isLoading = true;
    });

    final cached = await _storageService.loadLastSimulationScenario();
    if (mounted) {
      setState(() {
        _scenario = cached;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportReport() async {
    final scenario = _scenario;
    if (scenario == null || _isExportingReport) return;
    setState(() => _isExportingReport = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final renderObject = _mapCaptureKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw const ScenarioReportException(
          'O mapa ainda não está pronto para captura.',
        );
      }
      final image = await renderObject.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw const ScenarioReportException(
          'Não foi possível converter o mapa para imagem.',
        );
      }
      final saved = await _reportService.exportReport(
        scenario: scenario,
        mapImageBytes: byteData.buffer.asUint8List(),
      );
      if (mounted && saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Relatório exportado com sucesso!', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (error) {
      if (mounted) {
        final message = error is ScenarioReportException
            ? error.message
            : 'Não foi possível gerar o relatório: $error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingReport = false);
    }
  }

  Future<void> _handleSaveScenario() async {
    final scenario = _scenario;
    if (scenario == null) return;

    final initialName = scenario.name?.isNotEmpty == true
        ? scenario.name!
        : (scenario.parameters.feederName.isNotEmpty
            ? scenario.parameters.feederName
            : 'Cenário ${scenario.region}');
    final initialRegion = scenario.region;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _SaveScenarioDialog(
        initialName: initialName,
        initialRegion: initialRegion,
      ),
    );

    if (result == null || !mounted) return;

    final updatedName = result['name'] ?? initialName;
    final updatedRegion = result['region'] ?? initialRegion;

    final updatedScenario = scenario.copyWith(
      name: updatedName,
      region: updatedRegion,
    );

    await _storageService.saveLastSimulationScenario(updatedScenario);

    if (!mounted) return;
    setState(() {
      _scenario = updatedScenario;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        // Com "action", o Flutter mantém o SnackBar na tela até o usuário dispensar (persist = true
        // por padrão). Sem isto a barra verde nunca sumia sozinha.
        persist: false,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cenário "$updatedName" salvo na região "$updatedRegion"!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Ver Histórico',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/history');
          },
        ),
      ),
    );
  }

  static const double _actionHeight = 44;

  ButtonStyle _outlinedActionStyle() => OutlinedButton.styleFrom(
    foregroundColor: AppColors.primaryPurple,
    side: const BorderSide(color: AppColors.primaryPurple),
    minimumSize: const Size(0, _actionHeight),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );

  ButtonStyle _filledActionStyle() => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryPurple,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, _actionHeight),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (_isLoading) {
      return const AppScaffold(
        title: 'Resultados & Cobertura',
        currentRoute: '/results',
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(color: AppColors.primaryPurple),
          ),
        ),
      );
    }

    if (_scenario == null) {
      return AppScaffold(
        title: 'Resultados & Cobertura',
        currentRoute: '/results',
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurpleUltraLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_tethering_off_rounded,
                    color: AppColors.primaryPurple,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nenhuma simulação recente encontrada',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Execute uma simulação de cobertura RF nas Etapas 1 e 2 para visualizar os resultados detalhados nesta tela.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/scenario');
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Configurar Nova Simulação'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final scenario = _scenario!;

    return AppScaffold(
      title: 'Resultados & Cobertura',
      currentRoute: '/results',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 620;
                    final heading = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scenario.name?.isNotEmpty == true
                              ? scenario.name!
                              : scenario.parameters.feederName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Região: ${scenario.region} • Modelo: ${scenario.parameters.propagationModel}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );

                    final saveButton = OutlinedButton.icon(
                      onPressed: _handleSaveScenario,
                      style: _outlinedActionStyle(),
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: const Text('Salvar Cenário'),
                    );

                    final exportButton = OutlinedButton.icon(
                      onPressed: _isExportingReport ? null : _exportReport,
                      style: _outlinedActionStyle(),
                      icon: _isExportingReport
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryPurple,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(
                        _isExportingReport ? 'Gerando relatório...' : 'Exportar relatório',
                      ),
                    );

                    final newSimulationButton = ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/scenario');
                      },
                      style: _filledActionStyle(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Nova Simulação'),
                    );

                    final actions = isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              saveButton,
                              const SizedBox(height: 8),
                              exportButton,
                              const SizedBox(height: 8),
                              newSimulationButton,
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              saveButton,
                              const SizedBox(width: 12),
                              exportButton,
                              const SizedBox(width: 12),
                              newSimulationButton,
                            ],
                          );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          heading,
                          const SizedBox(height: 16),
                          actions,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: heading),
                        const SizedBox(width: 16),
                        actions,
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ScenarioKpiRow(scenario: scenario),
            const SizedBox(height: 16),
            SizedBox(
              height: isMobile ? 320 : 520,
              child: ScenarioMap(
                scenario: scenario,
                captureKey: _mapCaptureKey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveScenarioDialog extends StatefulWidget {
  final String initialName;
  final String initialRegion;

  const _SaveScenarioDialog({
    required this.initialName,
    required this.initialRegion,
  });

  @override
  State<_SaveScenarioDialog> createState() => _SaveScenarioDialogState();
}

class _SaveScenarioDialogState extends State<_SaveScenarioDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _regionController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _regionController = TextEditingController(text: widget.initialRegion);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.bookmark_add_outlined, color: AppColors.primaryPurple),
          SizedBox(width: 8),
          Text('Salvar Cenário'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Defina o nome e confirme a região para organizar este cenário no histórico.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Cenário *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe um nome para o cenário' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regionController,
              decoration: const InputDecoration(
                labelText: 'Região *',
                hintText: 'Ex: Campinas - SP, Regional Leste',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe a região do cenário' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'region': _regionController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
