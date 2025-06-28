import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/core/utils/values/colors.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/range_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

bool isClose(double a, double b, [double eps = 1]) => (a - b).abs() < eps;

List<double> getA1CYAxisTicks(double maxValue) {
  if (maxValue <= 5.0) {
    return [0.0, 2.5, 5.0];
  } else if (maxValue <= 7.0) {
    return [0.0, 3.5, 7.0];
  } else if (maxValue <= 10.0) {
    return [0.0, 5.0, 10.0];
  } else {
    return [0.0, 5.0, 12.0];
  }
}

class A1CChartWithPaging extends StatefulWidget {
  final Map<DateTime, List<FlSpot>> a1cByDate;
  final DateTime today;

  const A1CChartWithPaging({
    super.key,
    required this.a1cByDate,
    required this.today,
  });

  @override
  State<A1CChartWithPaging> createState() => _A1CChartWithPagingState();
}

class _A1CChartWithPagingState extends State<A1CChartWithPaging> {
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
    final daysWithData = widget.a1cByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    if (daysWithData.isEmpty) {
      return const Center(child: Text('No A1C data available'));
    }
    final day = daysWithData[_currentPage.clamp(0, daysWithData.length - 1)];
    final spots = widget.a1cByDate[day] ?? [];
    if (spots.isEmpty) {
      return const Center(child: Text('No A1C data available'));
    }
    final maxY = spots.isNotEmpty
        ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final yTicks = getA1CYAxisTicks(maxY);
    final minY = 0.0;
    final midY = yTicks[1];
    final maxYT = yTicks[2];

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
            final rangeText =
                '${minValue.toStringAsFixed(2)}–${maxValue.toStringAsFixed(2)}';
            final dateLabel = DateFormat('EEEE, dd MMMM yyyy').format(day);
            return RangeDisplay(
              range: rangeText,
              unit: '%',
              label: 'A1C RANGE',
              dateLabel: dateLabel,
              textColor: textColor,
              grey: grey,
              avg: avgValue,
              avgUnit: '%',
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
                          final spots = widget.a1cByDate[day] ?? [];
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
                                    child: A1CChart(
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

class A1CChart extends StatelessWidget {
  final List<FlSpot> spots;
  final double minY;
  final double maxY;
  final double midY;
  final Map<FlSpot, DateTime>? spotToDateTime;

  const A1CChart({
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
            preventCurveOverShooting: true,
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
                final value = touchedSpot.y.toStringAsFixed(2);
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
                      text: '%\n',
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
  final List<double> values;
  const _RightYAxis({required this.values});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: values
          .map((v) => Text(
                v.toStringAsFixed(1),
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
