import 'package:flutter/material.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../controllers/scenario_config_controller.dart';
import '../widgets/action_footer_bar.dart';
import '../widgets/optimization_criteria_card.dart';
import '../widgets/rf_parameters_card.dart';
import '../widgets/scenario_wizard_stepper.dart';
import '../../domain/models/area_delimitation_model.dart';

class ScenarioConfigScreen extends StatefulWidget {
  final ScenarioConfigController? controller;
  final AreaDelimitationConfig? areaConfig;

  const ScenarioConfigScreen({super.key, this.controller, this.areaConfig});

  @override
  State<ScenarioConfigScreen> createState() => _ScenarioConfigScreenState();
}

class _ScenarioConfigScreenState extends State<ScenarioConfigScreen> {
  late final ScenarioConfigController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        ScenarioConfigController(
          onSimulationComplete: (scenario) {
            Navigator.of(context).pushNamed(
              '/results',
              arguments: scenario,
            );
          },
        );
    _controller.loadConfig();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _navigateToStep1() {
    _controller.saveCurrentState();
    Navigator.of(context).pushReplacementNamed('/scenario');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return AppScaffold(
          title: 'Configuração de Cenário de Radiofrequência',
          currentRoute: '/scenario',
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScenarioWizardStepper(
                    currentStep: 2,
                    onStep1Tap: _navigateToStep1,
                    showSystemPills: false,
                  ),
                  if (_controller.isCalculating)
                    const Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LinearProgressIndicator(
                            minHeight: 6,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Processando cenário, calculando otimização. Por favor aguarde...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  if (!_controller.isCalculating) const SizedBox(height: 18),
                  if (_controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _controller.errorMessage!,
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  RfParametersCard(controller: _controller),
                  const SizedBox(height: 18),
                  OptimizationCriteriaCard(controller: _controller),
                  const SizedBox(height: 18),
                  ActionFooterBar(
                    controller: _controller,
                    onBackToStep1: _navigateToStep1,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
