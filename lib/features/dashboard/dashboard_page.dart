import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfresh/service/firestore provider.dart';

import '../../core/theme/color_palette.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalAsync = ref.watch(totalProductsProvider);
    final freshAsync = ref.watch(freshProductsProvider);
    final expiringSoonAsync = ref.watch(expiringSoonCountProvider);
    final expiredAsync = ref.watch(expiredCountProvider);
    final statsAsync = ref.watch(annualStatsProvider);
final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('dashboard'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900 ? 4 : 2;
            final cards = [
              _StatCard(
                title: 'totalProducts'.tr(),
                asyncValue: totalAsync,
                icon: Icons.inventory_2_rounded,
                color: ColorPalette.primary,
                subtitle: 'totalProductsSubtitle'.tr(),
              ),
              _StatCard(
                title: 'freshProducts'.tr(),
                asyncValue: freshAsync,
                icon: Icons.eco_rounded,
                color: ColorPalette.success,
                subtitle: 'freshProductsSubtitle'.tr(),
              ),
              _StatCard(
                title: 'expiringSoon'.tr(),
                asyncValue: expiringSoonAsync,
                icon: Icons.hourglass_bottom_rounded,
                color: ColorPalette.warning,
                subtitle: 'expiringSoonSubtitle'.tr(),
              ),
              _StatCard(
                title: 'expired'.tr(),
                asyncValue: expiredAsync,
                icon: Icons.dangerous_rounded,
                color: ColorPalette.danger,
                subtitle: 'expiredSubtitle'.tr(),
              ),
            ];

            return GridView.builder(
              itemCount: cards.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemBuilder: (_, i) => cards[i],
            );
          }),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'annualStatistics'.tr(),
                style:TextStyle(fontWeight: FontWeight.w700,color:isDark ? Colors.white : Colors.black,),
                    
              ),
              const Spacer(),
              Text(
                DateTime.now().year.toString(),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: ColorPalette.secondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ChartLegend(),
          const SizedBox(height: 12),
          statsAsync.when(
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'loadError'.tr(),
                  style: const TextStyle(color: ColorPalette.danger),
                ),
              ),
            ),
            data: (stats) {
              double maxY = 5;
              for (final s in stats) {
                maxY = [maxY, s.zone1, s.zone2, s.zone3, s.pirimi]
                    .reduce((a, b) => a > b ? a : b);
              }
              maxY = (maxY + 2).ceilToDouble();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.4),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: ColorPalette.secondary),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 1,
                              getTitlesWidget: (value, _) {
                                final i = value.toInt();
                                if (i < 0 || i >= stats.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    stats[i].month,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 10,
                                        color: ColorPalette.secondary),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots.map((s) {
                              const colors = [
                                ColorPalette.success,
                                ColorPalette.primary,
                                ColorPalette.warning,
                                ColorPalette.danger,
                              ];
                              const lbl = ['Z1', 'Z2', 'Z3', 'Pir'];
                              final i = s.barIndex;
                              return LineTooltipItem(
                                '${lbl[i]}: ${s.y.toInt()}',
                                TextStyle(
                                    color: colors[i],
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
                              );
                            }).toList(),
                          ),
                        ),
                        lineBarsData: [
                          _areaLine(
                              stats.map((e) => e.zone1).toList(),
                              ColorPalette.success),
                          _areaLine(
                              stats.map((e) => e.zone2).toList(),
                              ColorPalette.primary),
                          _areaLine(
                              stats.map((e) => e.zone3).toList(),
                              ColorPalette.warning),
                          _areaLine(
                              stats.map((e) => e.pirimi).toList(),
                              ColorPalette.danger),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  LineChartBarData _areaLine(List<double> values, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++)
          FlSpot(i.toDouble(), values[i])
      ],
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.5,
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.12),
      ),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
          radius: spot.y > 0 ? 3 : 0,
          color: color,
          strokeWidth: 0,
        ),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.asyncValue,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final String title;
  final AsyncValue<int> asyncValue;
  final IconData icon;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                        color: color, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            asyncValue.when(
              loading: () => SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
              ),
              error: (_, __) => Text(
                '—',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: color),
              ),
              data: (value) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.toDouble()),
                duration: const Duration(milliseconds: 700),
                builder: (context, v, _) => Text(
                  v.toInt().toString(),
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColorPalette.secondary,
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chart Legend ──────────────────────────────────────────────────────────────
class _ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<_LegendItem> items = [
      _LegendItem(label: 'zone1'.tr(), color: ColorPalette.success),
      _LegendItem(label: 'zone2'.tr(), color: ColorPalette.primary),
      _LegendItem(label: 'zone3'.tr(), color: ColorPalette.warning),
      _LegendItem(label: 'pirimi'.tr(), color: ColorPalette.danger),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: items
          .map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ))
          .toList(),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  _LegendItem({required this.label, required this.color});
}