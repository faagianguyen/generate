import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/core/utils/values/colors.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/range_display.dart';

const double lineWidth = 8;

bool isClose(double a, double b, [double eps = 1]) => (a - b).abs() < eps;

String formatYearRange(
    List<Map<int, List<double>>> yearsData, int currentPage) {
  if (yearsData.isEmpty) return 'This year';

  // Chỉ hiển thị năm hiện tại
  final now = DateTime.now();
  final currentYear = now.year;

  return currentYear.toString();
}

class GlucoseYearChart extends StatefulWidget {
  final List<Map<int, List<double>>> yearsData;
  const GlucoseYearChart({Key? key, required this.yearsData}) : super(key: key);

  @override
  State<GlucoseYearChart> createState() => _GlucoseYearChartState();
}

class _GlucoseYearChartState extends State<GlucoseYearChart> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initPageController();
  }

  void _initPageController() {
    _pageController = PageController(initialPage: widget.yearsData.length - 1);
    _currentPage = widget.yearsData.length - 1;
    _pageController.addListener(_onPageChanged);
  }

  @override
  void didUpdateWidget(covariant GlucoseYearChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.yearsData.length != widget.yearsData.length) {
      _pageController.removeListener(_onPageChanged);
      _pageController.dispose();
      _initPageController();
      setState(() {});
    }
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

  List<int> getYAxisTicks(double maxValue) {
    if (maxValue <= 99) return [0, 50, 100];
    if (maxValue <= 199) return [0, 100, 200];
    if (maxValue <= 299) return [0, 150, 300];
    if (maxValue <= 399) return [0, 200, 400];
    return [0, 300, 600];
  }

  String getMonthLabel(int monthIndex) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[monthIndex];
  }

  @override
  Widget build(BuildContext context) {
    final yearData = widget.yearsData[_currentPage];
    final allValues = yearData.values.expand((e) => e).toList();
    final rangeText = allValues.isNotEmpty
        ? '${allValues.reduce((a, b) => a < b ? a : b).toInt()}–${allValues.reduce((a, b) => a > b ? a : b).toInt()}'
        : 'xxx–xxx';
    final avg = allValues.isNotEmpty
        ? allValues.reduce((a, b) => a + b) / allValues.length
        : null;

    final yTicks = getYAxisTicks(
        allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 0);
    final minY = yTicks[0].toDouble();
    final midY = yTicks[1].toDouble();
    final maxY = yTicks[2].toDouble();

    return Column(
      children: [
        RangeDisplay(
          range: rangeText,
          unit: 'mg/dL',
          label: 'RANGE',
          dateLabel: formatYearRange(widget.yearsData, _currentPage),
          textColor: textColor,
          grey: grey,
          avg: avg,
          avgUnit: 'mg/dL',
        ),
        SizedBox(
          width: double.infinity,
          height: 340,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.yearsData.length,
                        itemBuilder: (context, index) {
                          final yearData = widget.yearsData[index];
                          final List<LineChartBarData> verticalLines = [];

                          for (int monthIndex = 0;
                              monthIndex < 12;
                              monthIndex++) {
                            final values = yearData[monthIndex] ?? [];
                            if (values.isNotEmpty) {
                              final minVal =
                                  values.reduce((a, b) => a < b ? a : b);
                              final maxVal =
                                  values.reduce((a, b) => a > b ? a : b);
                              if (!isClose(minVal, maxVal)) {
                                verticalLines.addAll([
                                  // Line dọc
                                  LineChartBarData(
                                    spots: [
                                      FlSpot(monthIndex.toDouble(), minVal),
                                      FlSpot(monthIndex.toDouble(), maxVal),
                                    ],
                                    isCurved: false,
                                    color: primary1,
                                    barWidth: lineWidth,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                  // Dot trên (max)
                                  LineChartBarData(
                                    spots: [
                                      FlSpot(monthIndex.toDouble(), maxVal)
                                    ],
                                    isCurved: false,
                                    color: Colors.transparent,
                                    barWidth: 0,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, _, __, ___) =>
                                          FlDotCirclePainter(
                                        radius: lineWidth / 2,
                                        color: primary1,
                                        strokeWidth: 0,
                                      ),
                                    ),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                  // Dot dưới (min)
                                  LineChartBarData(
                                    spots: [
                                      FlSpot(monthIndex.toDouble(), minVal)
                                    ],
                                    isCurved: false,
                                    color: Colors.transparent,
                                    barWidth: 0,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, _, __, ___) =>
                                          FlDotCirclePainter(
                                        radius: lineWidth / 2,
                                        color: primary1,
                                        strokeWidth: 0,
                                      ),
                                    ),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ]);
                              } else {
                                // Chỉ có 1 giá trị hoặc 2 giá trị trùng nhau
                                verticalLines.add(
                                  LineChartBarData(
                                    spots: [
                                      FlSpot(monthIndex.toDouble(), minVal)
                                    ],
                                    isCurved: false,
                                    color: Colors.transparent,
                                    barWidth: 0,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, _, __, ___) =>
                                          FlDotCirclePainter(
                                        radius: lineWidth / 2,
                                        color: primary1,
                                        strokeWidth: 0,
                                      ),
                                    ),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                );
                              }
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: Column(
                              children: [
                                const SizedBox(height: 7),
                                Expanded(
                                  child: LineChart(
                                    LineChartData(
                                      clipData: const FlClipData.none(),
                                      lineBarsData: verticalLines,
                                      minX: -0.5,
                                      maxX: 11.5,
                                      minY: minY,
                                      maxY: maxY,
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border(
                                          top: BorderSide(
                                              width: 1, color: grey3),
                                          right: BorderSide.none,
                                          bottom: BorderSide(
                                              width: 1, color: grey3),
                                          left: BorderSide.none,
                                        ),
                                      ),
                                      gridData: FlGridData(
                                        show: true,
                                        drawHorizontalLine: true,
                                        drawVerticalLine: true,
                                        verticalInterval: 1,
                                        horizontalInterval: (maxY - minY) / 2,
                                        getDrawingHorizontalLine: (value) {
                                          if (isClose(value, minY) ||
                                              isClose(value, midY) ||
                                              isClose(value, maxY)) {
                                            return FlLine(
                                                color: grey3, strokeWidth: 0.5);
                                          }
                                          return const FlLine(strokeWidth: 0);
                                        },
                                        getDrawingVerticalLine: (value) {
                                          return FlLine(
                                              color: grey3,
                                              strokeWidth: 0.5,
                                              dashArray: [2, 2]);
                                        },
                                      ),
                                      titlesData:
                                          const FlTitlesData(show: false),
                                      lineTouchData: LineTouchData(
                                        enabled: true,
                                        getTouchedSpotIndicator:
                                            (barData, spotIndexes) {
                                          return spotIndexes.map((index) {
                                            return TouchedSpotIndicatorData(
                                              FlLine(
                                                color: grey.withOpacity(0.5),
                                                strokeWidth: 2,
                                              ),
                                              FlDotData(
                                                show: true,
                                                getDotPainter: (spot, percent,
                                                    barData, index) {
                                                  return FlDotCirclePainter(
                                                    radius: lineWidth / 2 + 1,
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
                                          tooltipBgColor:
                                              const Color(0xFFF5F5F7),
                                          tooltipRoundedRadius: 8,
                                          fitInsideHorizontally: true,
                                          fitInsideVertically: true,
                                          getTooltipItems: (touchedSpots) {
                                            if (touchedSpots.isEmpty) return [];
                                            // Lấy tất cả dot cùng x (tháng)
                                            final x = touchedSpots.first.x;
                                            final sameMonthSpots = touchedSpots
                                                .where((s) => s.x == x)
                                                .toList();
                                            final values = sameMonthSpots
                                                .map((s) => s.y.toInt())
                                                .toList()
                                              ..sort();
                                            final monthIdx = x.toInt();

                                            if (values.length == 2 &&
                                                values[0] != values[1]) {
                                              // min-max
                                              return [
                                                LineTooltipItem(
                                                  '${values[0]} – ${values[1]} ',
                                                  const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black),
                                                  children: [
                                                    const TextSpan(
                                                      text: 'mg/dL\n',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Color(0xFF8E8E93),
                                                          fontWeight:
                                                              FontWeight.w400),
                                                    ),
                                                    TextSpan(
                                                      text: getMonthLabel(
                                                          monthIdx),
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Color(0xFF8E8E93),
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ];
                                            } else {
                                              // chỉ 1 dot hoặc 2 dot trùng giá trị
                                              return [
                                                LineTooltipItem(
                                                  '${values[0]} ',
                                                  const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black),
                                                  children: [
                                                    const TextSpan(
                                                      text: 'mg/dL\n',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Color(0xFF8E8E93),
                                                          fontWeight:
                                                              FontWeight.w400),
                                                    ),
                                                    TextSpan(
                                                      text: getMonthLabel(
                                                          monthIdx),
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Color(0xFF8E8E93),
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ];
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
                height: 340,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _RightYAxis(
                      values: [maxY.toInt(), midY.toInt(), minY.toInt()]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _RightYAxis extends StatelessWidget {
  final List<int> values;
  const _RightYAxis({required this.values});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: values
            .map((v) => Text(
                  v.toString(),
                  style: TextStyle(
                      fontSize: 12, color: grey3, fontWeight: FontWeight.bold),
                ))
            .toList(),
      ),
    );
  }
}

class _XAxisLabels extends StatelessWidget {
  const _XAxisLabels();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final month in [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ])
            Text(
              month,
              style: TextStyle(
                  fontSize: 12, color: grey3, fontWeight: FontWeight.bold),
            )
        ],
      ),
    );
  }
}
