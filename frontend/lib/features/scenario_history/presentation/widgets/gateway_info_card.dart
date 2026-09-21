import 'package:flutter/material.dart';
import '../../models/scenario_history_models.dart';

class GatewayInfoCard extends StatelessWidget {
  final GatewayPoint gateway;
  final VoidCallback onClose;

  const GatewayInfoCard({
    super.key,
    required this.gateway,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${gateway.id} · ${gateway.posteId}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Altura antena', value: '${gateway.antennaHeight} m'),
            _InfoRow(label: 'Potência TX', value: '+${gateway.txPowerDbm} dBm'),
            _InfoRow(label: 'Ativos vinculados', value: '${gateway.linkedAssets}'),
            _InfoRow(
              label: 'Margem fade média',
              value: '${gateway.avgFadeMarginDb} dB',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}