import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../models/scenario_results_models.dart';
import '../../../scenario_config/data/services/scenario_storage_service.dart';
import '../widgets/scenario_kpi_row.dart';
import '../widgets/scenario_map.dart';

class ScenarioResultsScreen extends StatefulWidget {
  final SimulationScenario? scenario;

  const ScenarioResultsScreen({super.key, this.scenario});

  @override
  State<ScenarioResultsScreen> createState() => _ScenarioResultsScreenState();
}

class _ScenarioResultsScreenState extends State<ScenarioResultsScreen> {
  final ScenarioStorageService _storageService = ScenarioStorageService();
  SimulationScenario? _scenario;
  bool _isLoading = false;

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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scenario.parameters.feederName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/scenario');
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Nova Simulação'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ScenarioKpiRow(scenario: scenario),
            const SizedBox(height: 16),
            SizedBox(
              height: isMobile ? 320 : 520,
              child: ScenarioMap(scenario: scenario),
            ),
          ],
        ),
      ),
    );
  }
}