// import 'package:flutter/material.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/widgets/app_scaffold.dart';
// import '../../models/scenario_history_models.dart';
// import 'scenario_history_screen.dart';

// class HistoryScreen extends StatelessWidget {
//   const HistoryScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return AppScaffold(
//       title: 'Histórico de Simulações',
//       currentRoute: '/history',
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Simulações Processadas',
//                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.textPrimary,
//                         ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Visualize cenários anteriores e compare as métricas de cobertura de RF.',
//                     style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
//                   ),
//                 ],
//               ),
//               ElevatedButton.icon(
//                 onPressed: () => Navigator.of(context).pushReplacementNamed('/scenario'),
//                 icon: const Icon(Icons.add_rounded, size: 18),
//                 label: const Text('Nova Simulação'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primaryPurple,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: kMockScenarios.length,
//             separatorBuilder: (_, index) => const SizedBox(height: 12),
//             itemBuilder: (context, index) {
//               final item = kMockScenarios[index];
//               return _ScenarioHistoryCard(scenario: item);
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ScenarioHistoryCard extends StatelessWidget {
//   final SimulationScenario scenario;

//   const _ScenarioHistoryCard({required this.scenario});

//   @override
//   Widget build(BuildContext context) {
//     final coverage = scenario.results.coveragePercent;
//     final isHighCoverage = coverage >= 90.0;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.surfaceWhite,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.cardBorder),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: AppColors.primaryPurpleUltraLight,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(Icons.wifi_tethering_rounded, color: AppColors.primaryPurple, size: 24),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(
//                       scenario.code,
//                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
//                     ),
//                     const SizedBox(width: 8),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: isHighCoverage ? AppColors.statusGreenLight : AppColors.badgeYellowLight,
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         '${coverage.toStringAsFixed(1)}% Cobertura',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           color: isHighCoverage ? AppColors.statusGreen : AppColors.badgeYellow,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   scenario.parameters.feederName,
//                   style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
//                     const SizedBox(width: 4),
//                     Text(scenario.region, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
//                     const SizedBox(width: 16),
//                     const Icon(Icons.router_outlined, size: 14, color: AppColors.textMuted),
//                     const SizedBox(width: 4),
//                     Text('${scenario.results.gateways.length} Gateways', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           OutlinedButton.icon(
//             onPressed: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (_) => ScenarioHistoryScreen(scenario: scenario),
//                 ),
//               );
//             },
//             icon: const Icon(Icons.visibility_outlined, size: 16),
//             label: const Text('Ver Resultados'),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: AppColors.primaryPurple,
//               side: const BorderSide(color: AppColors.primaryPurple),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
