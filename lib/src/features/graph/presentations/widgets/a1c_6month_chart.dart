import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/core/utils/values/colors.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/range_display.dart';

const double lineWidth = 8;

bool isClose(double a, double b, [double eps = 1]) => (a - b).abs() < eps;

String format6MonthRange(List<Map<int, List<double>>> sixMonthsData,
    int currentPage, DateTime sixMonthStartDates) {
  if (sixMonthsData.isEmpty) return 'This 6 months';

  // Lấy dữ liệu của 6 tháng hiện tại
  final sixMonthData = sixMonthsData[currentPage];
  if (sixMonthData.isEmpty) return 'This 6 months';

  // Tìm tháng đầu tiên và cuối cùng có dữ liệu trong 6 tháng
  final months = sixMonthData.keys.toList()..sort();
  if (months.isEmpty) return 'This 6 months';

  // Tính tháng bắt đầu và kết thúc của 6 tháng hiển thị
  final firstMonth = months.first;
  final lastMonth = months.last;

  // Tính tháng và năm dựa trên dữ liệu hiện tại
  final now = DateTime.now();
  final currentMonth = now.month;
  final currentYear = now.year;

  // Tính toán 6 tháng gần nhất
  final startMonth = ((currentMonth - 1) ~/ 6) * 6 + 1;

  // Tính tháng thực tế
  final actualFirstMonth = startMonth + firstMonth;
  final actualLastMonth = startMonth + lastMonth;

  // Tính năm cho từng tháng
  final firstYear = currentYear + (actualFirstMonth > 12 ? 1 : 0);
  final lastYear = currentYear + (actualLastMonth > 12 ? 1 : 0);

  final firstMonthAdjusted =
      actualFirstMonth > 12 ? actualFirstMonth - 12 : actualFirstMonth;
  final lastMonthAdjusted =
      actualLastMonth > 12 ? actualLastMonth - 12 : actualLastMonth;

  // Format: mm/yyyy - mm/yyyy
  final startStr =
      '${firstMonthAdjusted.toString().padLeft(2, '0')}/${firstYear}';
  final endStr = '${lastMonthAdjusted.toString().padLeft(2, '0')}/${lastYear}';

  return '$startStr - $endStr';
}

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

class A1C6MonthChart extends StatefulWidget {
  final List<Map<int, List<double>>> sixMonthsData;
  final List<DateTime> sixMonthStartDates;
  const A1C6MonthChart(
      {Key? key, required this.sixMonthsData, required this.sixMonthStartDates})
      : super(key: key);

  @override
  State<A1C6MonthChart> createState() => _A1C6MonthChartState();
}

class _A1C6MonthChartState extends State<A1C6MonthChart> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initPageController();
  }

  void _initPageController() {
    _pageController =
        PageController(initialPage: widget.sixMonthsData.length - 1);
    _currentPage = widget.sixMonthsData.length - 1;
    _pageController.addListener(_onPageChanged);
  }

  @override
  void didUpdateWidget(covariant A1C6MonthChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sixMonthsData.length != widget.sixMonthsData.length) {
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

  @override
  Widget build(BuildContext context) {
    final sixMonthData = widget.sixMonthsData[_currentPage];
    final allValues = sixMonthData.values.expand((e) => e).toList();
    final rangeText = allValues.isNotEmpty
        ? '${allValues.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)}–${allValues.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}'
        : 'xxx–xxx';
    final avg = allValues.isNotEmpty
        ? allValues.reduce((a, b) => a + b) / allValues.length
        : null;

    final yTicks = getA1CYAxisTicks(
        allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 0);
    final minY = yTicks[0];
    final midY = yTicks[1];
    final maxY = yTicks[2];

    return Column(
      children: [
        RangeDisplay(
          range: rangeText,
          unit: '%',
          label: 'A1C RANGE',
          dateLabel: format6MonthRange(widget.sixMonthsData, _currentPage,
              widget.sixMonthStartDates[_currentPage]),
          textColor: textColor,
          grey: grey,
          avg: avg,
          avgUnit: '%',
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
                        itemCount: widget.sixMonthsData.length,
                        itemBuilder: (context, index) {
                          final sixMonthData = widget.sixMonthsData[index];
                          final List<LineChartBarData> verticalLines = [];

                          for (int monthIndex = 0;
                              monthIndex < 6;
                              monthIndex++) {
                            final values = sixMonthData[monthIndex] ?? [];
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
                                      maxX: 5.5,
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
                                        enabled: false,
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
                    _XAxisLabels(
                        sixMonthsData: widget.sixMonthsData,
                        currentPage: _currentPage),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 340,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _RightYAxis(values: [maxY, midY, minY]),
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
  final List<double> values;
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
                  v.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 12, color: grey3, fontWeight: FontWeight.bold),
                ))
            .toList(),
      ),
    );
  }
}

class _XAxisLabels extends StatelessWidget {
  final List<Map<int, List<double>>> sixMonthsData;
  final int currentPage;

  const _XAxisLabels({required this.sixMonthsData, required this.currentPage});

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
    // Tính toán 6 tháng cho page hiện tại
    final currentMonth = DateTime.now().month - 1; // 0-based
    final startMonth =
        (currentMonth - 5 + (sixMonthsData.length - 1 - currentPage) * 6) % 12;

    final monthLabels = <String>[];
    for (int i = 0; i < 6; i++) {
      final month = (startMonth + i) % 12;
      monthLabels.add(getMonthLabel(month));
    }

    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: monthLabels
            .map((month) => Text(
                  month,
                  style: TextStyle(
                      fontSize: 12, color: grey3, fontWeight: FontWeight.bold),
                ))
            .toList(),
      ),
    );
  }
}
