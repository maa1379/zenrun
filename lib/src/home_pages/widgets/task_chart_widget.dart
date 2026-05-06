import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/src/home_pages/providers/task_provider.dart';

class TaskCharts extends StatelessWidget {
  const TaskCharts({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.state == ViewState.Loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final progress = provider.dailyProgressPercentage;

        return GestureDetector(
          onTap: () {
            _showWeeklyChartModal(context, provider.last7DaysCompletedTasks);
          },
          child: SimpleCircularProgressBar(
            backColor: Colors.black12,
            maxValue: 100,
            valueNotifier: ValueNotifier(progress),
            onGetText: (v) {
              return Text(
                "Z\n%${v.toInt()}".toLn(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              );
            },
            progressColors: const [
              ColorsHelper.btn1,
              ColorsHelper.btn1,
              ColorsHelper.btn2,
              ColorsHelper.btn2,
            ],
          ),
        );
      },
    );
  }

  void _showWeeklyChartModal(BuildContext context, Map<DateTime, int> weeklyData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.8,
          minChildSize: 0.4,
          builder: (BuildContext context, ScrollController scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Weekly Progress".toLn(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  SizedBox(
                    height: 50.h,
                    child: TaskCompletionBarChart(dailyData: weeklyData),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// A bar chart to display task completions for the last 7 days.
class TaskCompletionBarChart extends StatefulWidget {
  const TaskCompletionBarChart({super.key, required this.dailyData});
  final Map<DateTime, int> dailyData;

  @override
  State<TaskCompletionBarChart> createState() => _TaskCompletionBarChartState();
}

class _TaskCompletionBarChartState extends State<TaskCompletionBarChart> {
  int? _touchedGroupIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.dailyData.isEmpty) {
      return Center(child: Text("No Data".toLn()));
    }

    // Sort entries from oldest to newest for correct chart display
    final entries = widget.dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxValue = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);
    final maxY = maxValue > 0 ? (maxValue + (5 - maxValue % 5)).toDouble() : 5.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          barGroups: entries.mapIndexed((index, e) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.green],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
              showingTooltipIndicators: _touchedGroupIndex == index ? [0] : [],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) return const SizedBox();
                  final date = entries[index].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_weekdayLabel(date), style: const TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _calculateInterval(maxY),
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value % _calculateInterval(maxY) == 0) {
                    return Text(value.toInt().toString());
                  }
                  return const SizedBox();
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
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[300], strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchCallback: (event, response) {
              if (response?.spot != null && (event is FlTapUpEvent || event is FlLongPressEnd)) {
                setState(() => _touchedGroupIndex = response?.spot!.touchedBarGroupIndex);
              } else if (event is FlPointerExitEvent || event is FlPointerEnterEvent) {
                // Remove touch highlight when the finger is lifted or moves away
                setState(() => _touchedGroupIndex = -1);
              }
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final date = entries[groupIndex].key;
                final formattedDate = intl.DateFormat.yMMMd().format(date);
                return BarTooltipItem(
                  '${rod.toY.toInt()} tasks\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: formattedDate,
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _calculateInterval(double maxY) {
    if (maxY <= 10) return 1;
    if (maxY <= 50) return 5;
    return (maxY / 5).ceilToDouble();
  }

  String _weekdayLabel(DateTime date) {
    // Using intl package for reliable day labels
    return intl.DateFormat('E').format(date); // E.g., "Mon", "Tue"
  }
}
