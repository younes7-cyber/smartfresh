import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_providers.dart';
import '../../core/theme/color_palette.dart';
import '../../mock/mock_data.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(mockProductStatsProvider) as List<MonthlyStat>;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('dashboard'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(color: ColorPalette.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${'fridgeStatus'.tr()}: ${'optimal'.tr()} | Temp: 4°C | ${'doorClosed'.tr()}'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 4 : 2;
              final cards = [
                _SummaryCard(title: 'totalProducts'.tr(), value: 48, icon: Icons.inventory_2_rounded, color: ColorPalette.primary),
                _SummaryCard(title: 'freshProducts'.tr(), value: 30, icon: Icons.eco_rounded, color: ColorPalette.success),
                _SummaryCard(title: 'expiringSoon'.tr(), value: 12, icon: Icons.hourglass_bottom_rounded, color: ColorPalette.warning),
                _SummaryCard(title: 'expired'.tr(), value: 6, icon: Icons.dangerous_rounded, color: ColorPalette.danger),
              ];

              return GridView.builder(
                itemCount: cards.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemBuilder: (context, index) => cards[index],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('annualStatistics'.tr(), style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: AspectRatio(
              aspectRatio: 1.5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 60,
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= stats.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(stats[index].month, style: theme.textTheme.bodySmall),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      _line(stats.map((e) => e.fresh).toList(), ColorPalette.success),
                      _line(stats.map((e) => e.expiringSoon).toList(), ColorPalette.warning),
                      _line(stats.map((e) => e.expired).toList(), ColorPalette.danger),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _line(List<double> values, Color color) {
    return LineChartBarData(
      spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
      isCurved: true,
      color: color,
      barWidth: 3,
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.14)),
      dotData: const FlDotData(show: false),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  final String title;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 800),
              builder: (context, animatedValue, child) {
                return Text(
                  animatedValue.toInt().toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                );
              },
            ),
            Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
      ),
    );
  }
}
