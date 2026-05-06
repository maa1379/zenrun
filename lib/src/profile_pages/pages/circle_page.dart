import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/custom_sacffold.dart';
import 'package:zenrun/core/widgets/dropDown_widget.dart';
import 'package:zenrun/core/widgets/extetions.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';
import 'package:toln/toln.dart';

class CirclePage extends StatefulWidget {
  const CirclePage({super.key, this.email});

  final String? email;

  @override
  State<CirclePage> createState() => _CirclePageState();
}

class _CirclePageState extends State<CirclePage> {
  @override
  void initState() {
    if (widget.email == null) {
      if (context.read<ProfileProvider>().viewState == ProfileViewState.loading) {
        context.read<ProfileProvider>().getProfile();
      }
    } else {}
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final pieRadius = min(screenWidth / 3.2, 80);

    return CustomScaffold(
      title: "Circles",
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          return PopScope(
            onPopInvokedWithResult: (didPop, result) {
              provider.clean();
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                spacing: 15,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Circles Chart'.toLn(),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: Card(
                      color: ColorsHelper.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: PieChart(_buildFixedCirclePieChart(pieRadius)),
                      ),
                    ),
                  ),
                  Text(
                    'Interaction report'.toLn(),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Column(
                    spacing: 15,
                    children: [
                      UiHelper.buttonMain2(
                        () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialEntryMode:
                                DatePickerEntryMode.calendarOnly,
                            saveText: "Select",
                          );
                          if (picked != null) {
                            setState(() {
                              provider.startDate = picked.start;
                              provider.endDate = picked.end;
                            });
                          }
                        },
                        provider.startDate != null && provider.endDate != null
                            ? 'From ${provider.startDate!.formatToTextOnlyDate()} To ${provider.endDate!.formatToTextOnlyDate()}'
                            : 'Select date range',
                        fontSize: 14,
                        width: 100.w,
                        height: 5.h,
                      ),
                      CustomDropdown<String>(
                        enabled: true,
                        hintText: "Select Circle",
                        items: provider.circleList
                            .map((e) => e.title ?? "")
                            .toList(),
                        selectedItem: provider.selectedCircleTitle,
                        onChanged: (val) {
                          provider.selectedCircleTitle = val;
                          provider.update();
                        },
                        itemLabel: (value) {
                          return value;
                        },
                      ),
                    ],
                  ),
                  AspectRatio(
                    aspectRatio: 1.6,
                    child: Card(
                      color: ColorsHelper.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: BarChart(
                          _buildBarData(provider.activityByDate()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PieChartData _buildFixedCirclePieChart(num radius) {
    final circleTitles = ['Family', 'Close friends', 'Friends', 'Relatives' , "All"];
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];

    final Map<String, int> data = {
      for (var title in circleTitles)
        title: context
                .read<ProfileProvider>()
                .circleList
                .firstWhereOrNull((c) => c.title == title)
                ?.followList
                .length ??
            0,
    };

    final total = data.values.fold(0, (a, b) => a + b);

    return PieChartData(
      sections: List.generate(circleTitles.length, (i) {
        final value = data[circleTitles[i]] ?? 0;
        final percent = (total > 0) ? ((value * 100) ~/ total) : 0;
        return PieChartSectionData(
          title: '${circleTitles[i]}\n$percent%',
          value: value.toDouble(),
          color: colors[i % colors.length],
          radius: radius.toDouble(),
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        );
      }),
      sectionsSpace: 3,
      centerSpaceRadius: 30,
    );
  }

  BarChartData _buildBarData(Map<String, List<String>> data) {
    final entries = data.entries.toList();
    final maxValue = entries.map((e) => e.value.length).fold(0, max);

    return BarChartData(
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              final index = value.toInt();
              if (index >= entries.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  entries[index].key,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, _) => Text(value.toInt().toString()),
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: entries.mapIndexed((index, e) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: e.value.length.toDouble(),
              color: ColorsHelper.btn2,
              width: 16,
              borderRadius: BorderRadius.circular(6),
              rodStackItems: [],
            ),
          ],
          barsSpace: 4,
        );
      }).toList(),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          // tooltipBgColor: Colors.black87,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final names = entries[group.x].value.toSet().join(", ");
            return BarTooltipItem(
              '${entries[group.x].key}\n$names',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            );
          },
        ),
        touchCallback: (event, response) {
          if (event.isInterestedForInteractions &&
              response != null &&
              response.spot != null) {
            final spot = response.spot!;
            final names = entries[spot.touchedBarGroupIndex].value.toSet().join(
                  ", ",
                );
            context.read<ProfileProvider>().tooltipText =
                '📅 ${entries[spot.touchedBarGroupIndex].key} → 👤 $names';
          }
        },
      ),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey[300], strokeWidth: 1),
      ),
      maxY: maxValue.toDouble().roundToDouble(),
      minY: 1,
    );
  }
}
