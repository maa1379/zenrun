import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenrun/src/profile_pages/providers/coin_provider.dart';
import 'package:zenrun/src/profile_pages/providers/wallet_provider.dart';
import '../../../core/widgets/Costance.dart';
import '../../../core/widgets/simple_circular_progress_bar.dart';
import '../providers/pedometer_service.dart';

/// ------------------- Daily Progress Widget -------------------
class DailyProgressWidget extends StatelessWidget {
  const DailyProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthData>(
      builder: (context, healthData, child) {
        final double goal = healthData.rewardMilestones
            .map((m) => m.steps)
            .fold(0.0, (prev, curr) => curr > prev ? curr.toDouble() : prev);

        final double currentSteps = healthData.currentDaySteps.toDouble();
        final double percent = (goal == 0) ? 0.0 : (currentSteps / goal * 100).clamp(0.0, 100.0);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HealthDetailsScreen()),
            );
          },
          child: SimpleCircularProgressBar(
            backColor: Colors.black12,
            maxValue: 100,
            valueNotifier: ValueNotifier(percent),
            onGetText: (v) {
              return Text(
                'R\n${v.toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              );
            },
            progressColors: const [Colors.blue, Colors.purple],
          ),
        );
      },
    );
  }
}

/// ------------------- Health Details Screen -------------------
class HealthDetailsScreen extends StatelessWidget {
  const HealthDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthData = context.watch<HealthData>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Activity Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: RefreshIndicator(
        color: ColorsHelper.btn2,
        onRefresh: () => healthData.refreshData(),
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            TodayStepsCard(
              steps: healthData.currentDaySteps,
              distance: healthData.metrics.distance,
              calories: healthData.metrics.calories,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

            const Gap(24),
            _buildSectionTitle("Weekly Overview"),
            const Gap(12),
            _WeeklyActivityChart(dailyData: healthData.dailySteps).animate().fadeIn(delay: 100.ms),

            const Gap(24),
            _buildSectionTitle("Rewards Timeline"),
            const Gap(12),
            const StepRewardsWidget().animate().fadeIn(delay: 200.ms),

            const Gap(24),
            _buildSectionTitle("Recent History"),
            const Gap(12),
            HistoryCard(dailySteps: healthData.dailySteps).animate().fadeIn(delay: 300.ms),

            const Gap(40), // Spacing at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: 0.5),
    );
  }
}

/// ------------------- Weekly Activity Chart -------------------
class _WeeklyActivityChart extends StatelessWidget {
  final Map<String, int> dailyData;
  const _WeeklyActivityChart({required this.dailyData});

  @override
  Widget build(BuildContext context) {
    if (dailyData.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: UiHelper.shadow2),
        child: const Center(child: Text("No Data. Keep walking!", style: TextStyle(color: Colors.grey))),
      );
    }

    final entries = dailyData.entries.map((e) => MapEntry(DateTime.parse(e.key), e.value)).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final last7Entries = entries.length > 7 ? entries.sublist(entries.length - 7) : entries;
    final maxValue = last7Entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);
    final double calculatedMaxY = ((maxValue + 999) ~/ 1000) * 1000 + 1000.0;
    final double maxY = calculatedMaxY < 2000 ? 2000 : calculatedMaxY;

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          barGroups: last7Entries.mapIndexed((index, e) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.purple.shade400],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey.shade100,
                  ),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= last7Entries.length) return const SizedBox();
                  final date = last7Entries[index].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _calculateInterval(maxY),
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Text(_formatLargeNumber(value), style: const TextStyle(fontSize: 11, color: Colors.grey));
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(maxY),
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: [5, 5]),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black87,
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} steps',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _calculateInterval(double maxY) {
    if (maxY <= 2000) return 500;
    if (maxY <= 5000) return 1000;
    if (maxY <= 10000) return 2000;
    return ((maxY / 5) / 1000).ceil() * 1000.0;
  }

  String _formatLargeNumber(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toInt().toString();
  }
}

/// ------------------- Today Steps Card -------------------
class TodayStepsCard extends StatelessWidget {
  final int steps;
  final double distance;
  final double calories;

  const TodayStepsCard({super.key, required this.steps, required this.distance, required this.calories});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: context.read<HealthData>().stepStream,
      initialData: steps,
      builder: (context, snapshot) {
        final currentSteps = snapshot.data ?? 0;
        final currentDist = currentSteps * 0.762;
        final currentCal = currentSteps * 0.04;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.purple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Column(
            children: [
              const Text('Today\'s Progress', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
              const Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.decimalPattern().format(currentSteps),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                  ),
                  const Gap(8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text('steps', style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Gap(24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniMetric(Icons.route_outlined, '${(currentDist / 1000).toStringAsFixed(2)} km', 'Distance'),
                    Container(width: 1, height: 40, color: Colors.white30),
                    _buildMiniMetric(Icons.local_fire_department_outlined, '${currentCal.toStringAsFixed(0)} kcal', 'Calories'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const Gap(6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

/// ------------------- History Card -------------------
class HistoryCard extends StatelessWidget {
  final Map<String, int> dailySteps;
  const HistoryCard({super.key, required this.dailySteps});

  @override
  Widget build(BuildContext context) {
    final sortedKeys = dailySteps.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ListView.separated(
        itemCount: sortedKeys.length > 7 ? 7 : sortedKeys.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100, height: 1, indent: 20, endIndent: 20),
        itemBuilder: (context, index) {
          final dateStr = sortedKeys[index];
          final date = DateTime.parse(dateStr);
          final steps = dailySteps[dateStr] ?? 0;
          final isToday = date.isAtSameMomentAs(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: isToday ? Colors.blue.shade50 : Colors.grey.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.calendar_today_rounded, size: 20, color: isToday ? Colors.blue : Colors.grey.shade500),
                    ),
                    const Gap(16),
                    Text(
                      isToday ? 'Today' : DateFormat('EEEE, MMM d').format(date),
                      style: TextStyle(fontSize: 15, fontWeight: isToday ? FontWeight.bold : FontWeight.w500, color: Colors.black87),
                    ),
                  ],
                ),
                Text(
                  NumberFormat.compact().format(steps),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isToday ? Colors.blue : Colors.black54),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ------------------- Step Rewards Widget -------------------
class StepRewardsWidget extends StatelessWidget {
  const StepRewardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final healthData = context.watch<HealthData>();
    final milestones = healthData.rewardMilestones;
    final currentSteps = healthData.currentDaySteps;

    if (milestones.isEmpty) return const SizedBox();

    return Column(
      children: milestones.map((milestone) {
        final isCollected = healthData.isMilestoneCollected(milestone.key);
        final isAchieved = currentSteps >= milestone.steps;
        final progress = (currentSteps / milestone.steps).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCollected ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isCollected ? Colors.green.shade100 : Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 45,
                    height: 45,
                    child: CircularProgressIndicator(
                      value: isCollected ? 1.0 : progress,
                      backgroundColor: Colors.grey.shade100,
                      color: isCollected ? Colors.green : Colors.amber.shade500,
                      strokeWidth: 4,
                    ),
                  ),
                  Icon(
                    isCollected ? Icons.check_rounded : (isAchieved ? Icons.star_rounded : Icons.lock_outline_rounded),
                    color: isCollected ? Colors.green : (isAchieved ? Colors.amber.shade600 : Colors.grey.shade400),
                    size: 20,
                  ),
                ],
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${NumberFormat.decimalPattern().format(milestone.steps)} Steps",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Gap(4),
                    Text(
                      isCollected ? "Reward Collected" : "Reward: ${milestone.reward} R Coins",
                      style: TextStyle(fontSize: 13, color: isCollected ? Colors.green.shade700 : Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (!isCollected)
                ElevatedButton(
                  onPressed: isAchieved
                      ? () async {
                    ViewHelper.showLoading();
                    await context.read<CoinProvider>().setAddCoin("0", milestone.reward.toString(), "0", "0");
                    healthData.collectReward(milestone.key);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Got ${milestone.reward} R Coins!"), backgroundColor: Colors.green));
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade500,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade100,
                    disabledForegroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Claim", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}