import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/core/utils/values/colors.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/range_display.dart';

const double lineWidth = 8;

bool isClose(double a, double b, [double eps = 1]) => (a - b).abs() < eps;

String formatWeekRange(List<Map<int, List<double>>> weeksData, int currentPage,
    DateTime weekStartDate) {
  if (weeksData.isEmpty) return 'This week';

  // Ngày bắt đầu tuần là thứ 2
  final displayStart = weekStartDate;
  // Ngày kết thúc tuần là Chủ nhật
  final displayEnd = weekStartDate.add(const Duration(days: 6));

  // Format: dd/mm - dd/mm/yyyy
  final startStr =
      '${displayStart.day.toString().padLeft(2, '0')}/${displayStart.month.toString().padLeft(2, '0')}';
  final endStr =
      '${displayEnd.day.toString().padLeft(2, '0')}/${displayEnd.month.toString().padLeft(2, '0')}/${displayEnd.year}';

  return '$startStr - $endStr';
}

class GlucoseWeekChart extends StatefulWidget {
  final List<Map<int, List<double>>> weeksData;
  final List<DateTime> weekStartDates;
  const GlucoseWeekChart(
      {Key? key, required this.weeksData, required this.weekStartDates})
      : super(key: key);

  @override
  State<GlucoseWeekChart> createState() => _GlucoseWeekChartState();
}

class _GlucoseWeekChartState extends State<GlucoseWeekChart> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initPageController();
  }

  void _initPageController() {
    _pageController = PageController(initialPage: widget.weeksData.length - 1);
    _currentPage = widget.weeksData.length - 1;
    _pageController.addListener(_onPageChanged);
  }

  @override
  void didUpdateWidget(covariant GlucoseWeekChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeksData.length != widget.weeksData.length) {
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

  String getWeekdayLabel(int weekdayIndex) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekdayIndex];
  }

  @override
  Widget build(BuildContext context) {
    final weekData = widget.weeksData[_currentPage];
    final allValues = weekData.values.expand((e) => e).toList();
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
          dateLabel: formatWeekRange(widget.weeksData, _currentPage,
              widget.weekStartDates[_currentPage]),
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
                        itemCount: widget.weeksData.length,
                        itemBuilder: (context, index) {
                          final weekData = widget.weeksData[index];
                          final List<LineChartBarData> verticalLines = [];

                          for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
                            final values = weekData[dayIndex] ?? [];
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
                                      FlSpot(dayIndex.toDouble(), minVal),
                                      FlSpot(dayIndex.toDouble(), maxVal),
                                    ],
                                    isCurved: false,
                                    color: primary1,
                                    barWidth: lineWidth,
                                    dotData: FlDotData(show: false),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                  // Dot max
                                  LineChartBarData(
                                    spots: [
                                      FlSpot(dayIndex.toDouble(), maxVal)
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
                                  // Dot min
                                  LineChartBarData(
                                    spots: [
                                      FlSpot(dayIndex.toDouble(), minVal)
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
                                // Trường hợp min == max → chỉ vẽ 1 dot
                                verticalLines.add(
                                  LineChartBarData(
                                    spots: [
                                      FlSpot(dayIndex.toDouble(), minVal)
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
                                      maxX: 6.5,
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
                                            dashArray: [2, 2],
                                          );
                                        },
                                      ),
                                      titlesData:
                                          const FlTitlesData(show: false),
                                      lineTouchData:
                                          LineTouchData(enabled: false),
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
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
            Text(
              day,
              style: TextStyle(
                  fontSize: 12, color: grey3, fontWeight: FontWeight.bold),
            )
        ],
      ),
    );
  }
}
