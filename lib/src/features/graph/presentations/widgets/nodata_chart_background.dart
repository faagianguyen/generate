import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/core/utils/values/colors.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/range_display.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

const _yTicks = [0, 50, 100];
const _minY = 0.0;
const _midY = 50.0;
const _maxY = 100.0;
const _chartHeight = 340.0;

bool isClose(double a, double b, [double eps = 1]) => (a - b).abs() < eps;

class NoDataChartBackground extends StatelessWidget {
  const NoDataChartBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final day = DateTime.now();
    final rangeText = 'xxx–xxx';
    final dateLabel = DateFormat('EEEE, dd MMMM yyyy').format(day);
    return Column(
      children: [
        RangeDisplay(
          range: rangeText,
          unit: 'mg/dL',
          label: 'RANGE',
          dateLabel: dateLabel,
          textColor: textColor,
          grey: grey,
          avg: null,
        ),
        SizedBox(
          width: double.infinity,
          height: _chartHeight,
          child: Row(
            children: [
              // Chart + X axis
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          const NoDataLineChart(),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  color: Colors.white.withOpacity(0.6),
                                  child: const Text(
                                    'No data available',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const NoDataXAxisLabels(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: _chartHeight, // chartHeight - xAxisHeight
                child: Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: NoDataYAxis(
                      values: [_maxY.toInt(), _midY.toInt(), _minY.toInt()]),
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

class NoDataLineChart extends StatelessWidget {
  const NoDataLineChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 0),
      child: Column(
        children: [
          const SizedBox(height: 7),
          Expanded(
            child: LineChart(
              LineChartData(
                clipData: const FlClipData.none(),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(-0.5, _midY),
                      FlSpot(24.5, _midY),
                    ],
                    isCurved: false,
                    barWidth: 0.5,
                    color: grey3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                minX: -0.5,
                maxX: 24.5,
                minY: _minY,
                maxY: _maxY,
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
                  horizontalInterval: (_maxY - _minY) / 2,
                  getDrawingHorizontalLine: (value) {
                    if (isClose(value, _midY)) {
                      return FlLine(
                        color: grey3,
                        strokeWidth: 1,
                      );
                    } else if (isClose(value, _minY) || isClose(value, _maxY)) {
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
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class NoDataYAxis extends StatelessWidget {
  final List<int> values;
  const NoDataYAxis({required this.values, Key? key}) : super(key: key);

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

class NoDataXAxisLabels extends StatelessWidget {
  const NoDataXAxisLabels({Key? key}) : super(key: key);

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
 