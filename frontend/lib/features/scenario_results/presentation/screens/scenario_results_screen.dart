import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../models/scenario_results_models.dart';
import '../widgets/scenario_kpi_row.dart';
import '../widgets/scenario_map.dart';

class ScenarioResultsScreen extends StatelessWidget {
  final SimulationScenario scenario;

  const ScenarioResultsScreen({super.key, required this.scenario});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

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
                child: Text(
                  scenario.parameters.feederName,
                  style: Theme.of(context).textTheme.titleLarge,
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