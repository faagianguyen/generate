import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/core/utils/values/colors.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/range_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

bool isClose(double a, double b, [double eps = 1]) => (a - b).abs() < eps;

List<int> getYAxisTicks(double maxValue) {
  if (maxValue <= 99) {
    return [0, 50, 100];
  } else if (maxValue <= 199) {
    return [0, 100, 200];
  } else if (maxValue <= 299) {
    return [0, 150, 300];
  } else if (maxValue <= 399) {
    return [0, 200, 400];
  } else {
    return [0, 300, 600];
  }
}

class GlucoseChartWithPaging extends StatefulWidget {
  final Map<DateTime, List<FlSpot>> glucoseByDate;
  final DateTime today;

  const GlucoseChartWithPaging({
    super.key,
    required this.glucoseByDate,
    required this.today,
  });

  @override
  State<GlucoseChartWithPaging> createState() => _GlucoseChartWithPagingState();
}

class _GlucoseChartWithPagingState extends State<GlucoseChartWithPaging> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final newPage = _pageController.page?.round() ?? 0;
    if (newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daysWithData = widget.glucoseByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    if (daysWithData.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final day = daysWithData[_currentPage.clamp(0, daysWithData.length - 1)];
    final spots = widget.glucoseByDate[day] ?? [];
    final maxY = spots.isNotEmpty
        ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final yTicks = getYAxisTicks(maxY);
    final minY = 0.0;
    final midY = yTicks[1].toDouble();
    final maxYT = yTicks[2].toDouble();

    return Column(
      children: [
        Builder(
          builder: (context) {
            if (spots.isEmpty) {
              return const Icon(CupertinoIcons.info,
                  color: CupertinoColors.systemGrey);
            }
            final minValue =
                spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
            final maxValue =
                spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
            final avgValue = spots.isNotEmpty
                ? spots.map((e) => e.y).reduce((a, b) => a + b) / spots.length
                : null;
            final rangeText = '${minValue.toInt()}–${maxValue.toInt()}';
            final dateLabel = DateFormat('EEEE, dd MMMM yyyy').format(day);
            return RangeDisplay(
              range: rangeText,
              unit: 'mg/dL',
              label: 'RANGE',
              dateLabel: dateLabel,
              textColor: textColor,
              grey: grey,
              avg: avgValue,
              avgUnit: 'mg/dL',
            );
          },
        ),
        SizedBox(
          width: double.infinity,
          height: 340,
          child: Row(
            children: [
              // Chart + X axis
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        reverse: true,
                        controller: _pageController,
                        itemCount: daysWithData.length,
                        itemBuilder: (context, index) {
                          final day = daysWithData[index];
                          final spots = widget.glucoseByDate[day] ?? [];
                          final spotToDateTime = <FlSpot, DateTime>{};
                          for (final spot in spots) {
                            final hour = spot.x.floor();
                            final minute = ((spot.x - hour) * 60).round();
                            final dateTime = DateTime(
                                day.year, day.month, day.day, hour, minute);
                            spotToDateTime[spot] = dateTime;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: Column(
                              children: [
                                const SizedBox(height: 7),
                                Expanded(
                                    child: GlucoseChart(
                                        spots: spots,
                                        minY: minY,
                                        maxY: maxYT,
                                        midY: midY,
                                        spotToDateTime: spotToDateTime)),
                                const SizedBox(height: 10),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const _XAxisLabels(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 340, // chartHeight - xAxisHeight
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _RightYAxis(values: [yTicks[2], yTicks[1], yTicks[0]]),
                ),
              ),
            ],
          ),
        ),
        // Hiển thị AVG dưới chart
        const SizedBox(height: 10),
      ],
    );
  }
}

class GlucoseChart extends StatelessWidget {
  final List<FlSpot> spots;
  final double minY;
  final double maxY;
  final double midY;
  final Map<FlSpot, DateTime>? spotToDateTime;

  const GlucoseChart({
    super.key,
    required this.spots,
    required this.minY,
    required this.maxY,
    required this.midY,
    this.spotToDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final sortedSpots = List<FlSpot>.from(spots)
      ..sort((a, b) => a.x.compareTo(b.x));
    return LineChart(
      LineChartData(
        clipData: const FlClipData.none(),
        lineBarsData: [
          LineChartBarData(
            spots: sortedSpots,
            isCurved: false,
            color: primary1,
            barWidth: 1,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 2,
                  color: primary1,
                  strokeWidth: 1,
                  strokeColor: primary1,
                );
              },
            ),
          ),
        ],
        minX: -0.5,
        maxX: 24.5,
        minY: minY,
        maxY: maxY,
        borderData: FlBorderData(
          show: true,
          border: Border(
            top: BorderSide(width: 1, color: grey3),
            right: BorderSide.none,
            bottom: BorderSide(width: 1, color: grey3),
            left: BorderSide.none,
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          verticalInterval: 6,
          horizontalInterval: (maxY - minY) / 2,
          getDrawingHorizontalLine: (value) {
            if (isClose(value, minY) ||
                isClose(value, midY) ||
                isClose(value, maxY)) {
              return FlLine(
                color: grey3,
                strokeWidth: 0.5,
              );
            }
            return const FlLine(strokeWidth: 0);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: grey3,
              strokeWidth: 0.5,
              dashArray: [2, 2],
            );
          },
        ),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: grey.withOpacity(0.5),
                  strokeWidth: 2,
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: primary1,
                      strokeWidth: 2,
                      strokeColor: primary1,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: const Color(0xFFF5F5F7),
            tooltipRoundedRadius: 8,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final value = touchedSpot.y.toInt();
                DateTime? dateTime;
                if (spotToDateTime != null) {
                  try {
                    final entry = spotToDateTime!.entries.firstWhere(
                      (entry) =>
                          (entry.key.x - touchedSpot.x).abs() < 0.01 &&
                          (entry.key.y - touchedSpot.y).abs() < 0.01,
                    );
                    dateTime = entry.value;
                  } catch (e) {
                    dateTime = null;
                  }
                }
                String timeLabel = '';
                if (dateTime != null) {
                  final hour = dateTime.hour.toString().padLeft(2, '0');
                  final minute = dateTime.minute.toString().padLeft(2, '0');
                  final day = dateTime.day.toString().padLeft(2, '0');
                  final month = dateTime.month.toString().padLeft(2, '0');
                  final year = dateTime.year.toString();
                  timeLabel = '$hour:$minute, $day/$month/$year';
                }
                return LineTooltipItem(
                  '$value ',
                  const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  children: [
                    const TextSpan(
                      text: 'mg/dL\n',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: timeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _RightYAxis extends StatelessWidget {
  final List<int> values;
  const _RightYAxis({required this.values});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: values
          .map((v) => Text(
                v.toString(),
                style: TextStyle(
                    fontSize: 12, color: grey3, fontWeight: FontWeight.bold),
              ))
          .toList(),
    );
  }
}

class _XAxisLabels extends StatelessWidget {
  const _XAxisLabels();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('00 AM',
            style: TextStyle(
                fontSize: 12, color: grey3, fontWeight: FontWeight.bold)),
        Text('06 AM',
            style: TextStyle(
                fontSize: 12, color: grey3, fontWeight: FontWeight.bold)),
        Text('12 PM',
            style: TextStyle(
                fontSize: 12, color: grey3, fontWeight: FontWeight.bold)),
        Text('18 PM',
            style: TextStyle(
                fontSize: 12, color: grey3, fontWeight: FontWeight.bold)),
        Text('24 PM',
            style: TextStyle(
                fontSize: 12, color: grey3, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
