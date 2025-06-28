import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/core/utils/values/colors.dart';
import 'package:flutter_app/src/core/utils/glucose_calculator.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/graph_top_bar.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/glucose_chart.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/a1c_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/src/core/providers/health_record_provider.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/nodata_chart_background.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/glucose_week_chart.dart';
import 'package:flutter_app/src/core/entities/health_record.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/a1c_week_chart.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/glucose_month_chart.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/a1c_month_chart.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/glucose_6month_chart.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/a1c_6month_chart.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/glucose_year_chart.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/a1c_year_chart.dart';
import 'package:flutter_app/src/features/graph/presentations/widgets/chart_loading_indicator.dart';

class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child; // Hide scrollbar
  }
}

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  int _selectedSegment = 0; // Default to Day
  String? _selectedTag;
  String? _selectedType;
  final ScrollController _scrollController = ScrollController();

  Map<int, Widget> _buildSegmentOptions() {
    return {
      0: const SizedBox(width: 50, child: Center(child: Text('D'))),
      1: const SizedBox(width: 50, child: Center(child: Text('W'))),
      2: const SizedBox(width: 50, child: Center(child: Text('M'))),
      3: const SizedBox(width: 50, child: Center(child: Text('6M'))),
      4: const SizedBox(width: 50, child: Center(child: Text('Y'))),
    };
  }

  int _getDaysForSegment(int segment) {
    switch (segment) {
      case 0:
        return 1;
      case 1:
        return 7;
      case 2:
        return 30;
      case 3:
        return 90;
      case 4:
        return 365;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: primary1,
        middle: Container(
          color: primary1,
          child: GraphTopBar(
            onSelectPressed: () => _showFilterModal(context),
          ),
        ),
        automaticBackgroundVisibility: false,
      ),
      child: ScrollConfiguration(
        behavior: NoScrollbarBehavior(),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding:
              const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 15),
          child: Column(
            children: [
              selectDays(),
              const SizedBox(height: 10),
              if (_selectedType == 'Weight') ...[
                const NoDataChartBackground(),
                const SizedBox(height: 20),
                const NoDataChartBackground(),
              ] else ...[
                if (_selectedSegment == 0) ...[
                Consumer<HealthRecordProvider>(
                  builder: (context, provider, _) {
                      // Lọc records theo tag/type
                      final filteredRecords = filterRecords(
                              provider.records, _selectedTag, _selectedType)
                        .where((record) => record.maybeWhen(
                            glucose: (id, g, t, d, n) => true,
                            orElse: () => false))
                        .toList();

                    // Gom nhóm theo ngày và chuyển thành FlSpot
                    final Map<DateTime, List<FlSpot>> glucoseByDate = {};
                      for (final record in filteredRecords) {
                      final date = record.date ?? DateTime.now();
                      final day = DateTime(date.year, date.month, date.day);
                      final x = date.hour + date.minute / 60.0;
                      final y = record.maybeWhen(
                          glucose: (id, g, t, d, n) => g, orElse: () => 0.0);

                      glucoseByDate
                          .putIfAbsent(day, () => [])
                          .add(FlSpot(x, y));
                    }

                    // Sắp xếp ngày tăng dần (mới nhất cuối cùng)
                    final days = glucoseByDate.keys.toList()..sort();

                    if (days.isEmpty) {
                        return const NoDataChartBackground();
                    }

                    return GlucoseChartWithPaging(
                        today: days.last,
                      glucoseByDate: glucoseByDate,
                    );
                  },
                ),
              const SizedBox(height: 10),
                Consumer<HealthRecordProvider>(
                  builder: (context, provider, _) {
                      // Lọc records theo tag/type
                      final filteredRecords = filterRecords(
                              provider.records, _selectedTag, _selectedType)
                        .where((record) => record.maybeWhen(
                            glucose: (id, g, t, d, n) => true,
                            orElse: () => false))
                        .toList();

                      if (filteredRecords.isEmpty) {
                        return const NoDataChartBackground();
                    }

                    // Gom nhóm glucose theo ngày
                    final Map<DateTime, List<double>> glucoseByDate = {};
                      for (final record in filteredRecords) {
                      final date = record.date ?? DateTime.now();
                      final day = DateTime(date.year, date.month, date.day);
                      final glucose = record.maybeWhen(
                          glucose: (id, g, t, d, n) => g, orElse: () => 0.0);

                      glucoseByDate.putIfAbsent(day, () => []).add(glucose);
                    }

                    // Sắp xếp ngày tăng dần
                    final days = glucoseByDate.keys.toList()..sort();

                    return FutureBuilder<Map<DateTime, List<FlSpot>>>(
                      future: _calculateA1CData(glucoseByDate, days),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                            return const ChartLoadingIndicator();
                        }

                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const NoDataChartBackground();
                        }

                        final a1cByDate = snapshot.data!;
                        return A1CChartWithPaging(
                          today: days.last,
                          a1cByDate: a1cByDate,
                        );
                      },
                    );
                  },
                ),
                ],
                if (_selectedSegment == 1) ...[
                  Consumer<HealthRecordProvider>(
                    builder: (context, provider, _) {
                      // Lọc records theo tag/type
                      final filteredRecords = filterRecords(
                              provider.records, _selectedTag, _selectedType)
                          .where((record) => record.maybeWhen(
                              glucose: (id, g, t, d, n) => true,
                              orElse: () => false))
                          .toList();
                      final weeksData = groupRecordsByWeek(filteredRecords);
                      final weekStartDates = getWeekStartDates(filteredRecords);

                      if (weeksData.isEmpty || weekStartDates.isEmpty) {
                        return const NoDataChartBackground();
                      }

                      return Column(
                        children: [
                          GlucoseWeekChart(
                            weeksData: weeksData,
                            weekStartDates: weekStartDates,
                          ),
                          const SizedBox(height: 20),
                          Consumer<HealthRecordProvider>(
                            builder: (context, provider, _) {
                              // Lọc records theo tag/type
                              final filteredRecords = filterRecords(
                                      provider.records,
                                      _selectedTag,
                                      _selectedType)
                                  .where((record) => record.maybeWhen(
                                      glucose: (id, g, t, d, n) => true,
                                      orElse: () => false))
                                  .toList();

                              if (filteredRecords.isEmpty) {
                                return const NoDataChartBackground();
                              }

                              // Gom nhóm glucose theo ngày
                              final Map<DateTime, List<double>> glucoseByDate =
                                  {};
                              for (final record in filteredRecords) {
                                final date = record.date ?? DateTime.now();
                                final day =
                                    DateTime(date.year, date.month, date.day);
                                final glucose = record.maybeWhen(
                                    glucose: (id, g, t, d, n) => g,
                                    orElse: () => 0.0);

                                glucoseByDate
                                    .putIfAbsent(day, () => [])
                                    .add(glucose);
                              }

                              // Sắp xếp ngày tăng dần
                              final days = glucoseByDate.keys.toList()..sort();

                              return FutureBuilder<Map<DateTime, List<FlSpot>>>(
                                future: _calculateA1CData(glucoseByDate, days),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const ChartLoadingIndicator();
                                  }

                                  if (snapshot.hasError ||
                                      !snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const NoDataChartBackground();
                                  }

                                  final a1cByDate = snapshot.data!;
                                  // Chuyển đổi A1C data sang format week
                                  final a1cWeeksData =
                                      _convertA1CToWeekFormat(a1cByDate, days);
                                  return A1CWeekChart(
                                    weeksData: a1cWeeksData,
                                    weekStartDates: weekStartDates,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
                if (_selectedSegment == 2) ...[
                  Consumer<HealthRecordProvider>(
                    builder: (context, provider, _) {
                      // Lọc records theo tag/type
                      final filteredRecords = filterRecords(
                              provider.records, _selectedTag, _selectedType)
                          .where((record) => record.maybeWhen(
                              glucose: (id, g, t, d, n) => true,
                              orElse: () => false))
                          .toList();
                      final monthsData = groupRecordsByMonth(filteredRecords);
                      final monthStartDates =
                          getMonthStartDates(filteredRecords);
                      if (monthsData.isEmpty || monthStartDates.isEmpty) {
                        return const NoDataChartBackground();
                      }
                      return Column(
                        children: [
                          GlucoseMonthChart(
                              monthsData: monthsData,
                              monthStartDates: monthStartDates),
                          const SizedBox(height: 20),
                          Consumer<HealthRecordProvider>(
                            builder: (context, provider, _) {
                              // Lọc records theo tag/type
                              final filteredRecords = filterRecords(
                                      provider.records,
                                      _selectedTag,
                                      _selectedType)
                                  .where((record) => record.maybeWhen(
                                      glucose: (id, g, t, d, n) => true,
                                      orElse: () => false))
                                  .toList();

                              if (filteredRecords.isEmpty) {
                                return const NoDataChartBackground();
                              }

                              // Gom nhóm glucose theo ngày
                              final Map<DateTime, List<double>> glucoseByDate =
                                  {};
                              for (final record in filteredRecords) {
                                final date = record.date ?? DateTime.now();
                                final day =
                                    DateTime(date.year, date.month, date.day);
                                final glucose = record.maybeWhen(
                                    glucose: (id, g, t, d, n) => g,
                                    orElse: () => 0.0);

                                glucoseByDate
                                    .putIfAbsent(day, () => [])
                                    .add(glucose);
                              }

                              // Sắp xếp ngày tăng dần
                              final days = glucoseByDate.keys.toList()..sort();

                              return FutureBuilder<Map<DateTime, List<FlSpot>>>(
                                future: _calculateA1CData(glucoseByDate, days),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const ChartLoadingIndicator();
                                  }

                                  if (snapshot.hasError ||
                                      !snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const NoDataChartBackground();
                                  }

                                  final a1cByDate = snapshot.data!;
                                  // Chuyển đổi A1C data sang format month
                                  final a1cMonthsData =
                                      _convertA1CToMonthFormat(a1cByDate, days);
                                  return A1CMonthChart(
                                      monthsData: a1cMonthsData,
                                      monthStartDates: monthStartDates);
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
                if (_selectedSegment == 3) ...[
                  Consumer<HealthRecordProvider>(
                    builder: (context, provider, _) {
                      // Lọc records theo tag/type
                      final filteredRecords = filterRecords(
                              provider.records, _selectedTag, _selectedType)
                          .where((record) => record.maybeWhen(
                              glucose: (id, g, t, d, n) => true,
                              orElse: () => false))
                          .toList();
                      final sixMonthsData =
                          groupRecordsBy6Months(filteredRecords);
                      final sixMonthStartDates =
                          getSixMonthStartDates(filteredRecords);
                      if (sixMonthsData.isEmpty || sixMonthStartDates.isEmpty) {
                        return const NoDataChartBackground();
                      }
                      return Column(
                        children: [
                          Glucose6MonthChart(
                              sixMonthsData: sixMonthsData,
                              sixMonthStartDates: sixMonthStartDates),
                          const SizedBox(height: 20),
                          Consumer<HealthRecordProvider>(
                            builder: (context, provider, _) {
                              // Lọc records theo tag/type
                              final filteredRecords = filterRecords(
                                      provider.records,
                                      _selectedTag,
                                      _selectedType)
                                  .where((record) => record.maybeWhen(
                                      glucose: (id, g, t, d, n) => true,
                                      orElse: () => false))
                                  .toList();

                              if (filteredRecords.isEmpty) {
                                return const NoDataChartBackground();
                              }

                              // Gom nhóm glucose theo ngày
                              final Map<DateTime, List<double>> glucoseByDate =
                                  {};
                              for (final record in filteredRecords) {
                                final date = record.date ?? DateTime.now();
                                final day =
                                    DateTime(date.year, date.month, date.day);
                                final glucose = record.maybeWhen(
                                    glucose: (id, g, t, d, n) => g,
                                    orElse: () => 0.0);

                                glucoseByDate
                                    .putIfAbsent(day, () => [])
                                    .add(glucose);
                              }

                              // Sắp xếp ngày tăng dần
                              final days = glucoseByDate.keys.toList()..sort();

                              return FutureBuilder<Map<DateTime, List<FlSpot>>>(
                                future: _calculateA1CData(glucoseByDate, days),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const ChartLoadingIndicator();
                                  }

                                  if (snapshot.hasError ||
                                      !snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const NoDataChartBackground();
                                  }

                                  final a1cByDate = snapshot.data!;
                                  // Chuyển đổi A1C data sang format 6 months
                                  final a1cSixMonthsData =
                                      _convertA1CTo6MonthsFormat(
                                          a1cByDate, days);
                                  return A1C6MonthChart(
                                      sixMonthsData: a1cSixMonthsData,
                                      sixMonthStartDates: sixMonthStartDates);
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
                if (_selectedSegment == 4) ...[
                  Consumer<HealthRecordProvider>(
                    builder: (context, provider, _) {
                      // Lọc records theo tag/type
                      final filteredRecords = filterRecords(
                              provider.records, _selectedTag, _selectedType)
                          .where((record) => record.maybeWhen(
                              glucose: (id, g, t, d, n) => true,
                              orElse: () => false))
                          .toList();
                      final yearsData = groupRecordsByYear(filteredRecords);
                      if (yearsData.isEmpty) {
                        return const NoDataChartBackground();
                      }
                      return Column(
                        children: [
                          GlucoseYearChart(yearsData: yearsData),
                          const SizedBox(height: 20),
                          Consumer<HealthRecordProvider>(
                            builder: (context, provider, _) {
                              // Lọc records theo tag/type
                              final filteredRecords = filterRecords(
                                      provider.records,
                                      _selectedTag,
                                      _selectedType)
                                  .where((record) => record.maybeWhen(
                                      glucose: (id, g, t, d, n) => true,
                                      orElse: () => false))
                                  .toList();

                              if (filteredRecords.isEmpty) {
                                return const NoDataChartBackground();
                              }

                              // Gom nhóm glucose theo ngày
                              final Map<DateTime, List<double>> glucoseByDate =
                                  {};
                              for (final record in filteredRecords) {
                                final date = record.date ?? DateTime.now();
                                final day =
                                    DateTime(date.year, date.month, date.day);
                                final glucose = record.maybeWhen(
                                    glucose: (id, g, t, d, n) => g,
                                    orElse: () => 0.0);

                                glucoseByDate
                                    .putIfAbsent(day, () => [])
                                    .add(glucose);
                              }

                              // Sắp xếp ngày tăng dần
                              final days = glucoseByDate.keys.toList()..sort();

                              return FutureBuilder<Map<DateTime, List<FlSpot>>>(
                                future: _calculateA1CData(glucoseByDate, days),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const ChartLoadingIndicator();
                                  }

                                  if (snapshot.hasError ||
                                      !snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const NoDataChartBackground();
                                  }

                                  final a1cByDate = snapshot.data!;
                                  // Chuyển đổi A1C data sang format year
                                  final a1cYearsData =
                                      _convertA1CToYearFormat(a1cByDate, days);
                                  return A1CYearChart(yearsData: a1cYearsData);
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Hiển thị thanh chọn khoảng thời gian (Ngày, Tuần, Tháng, 6 tháng, Năm)
  // Display the time range segmented control (Day, Week, Month, 6 Months, Year)
  Center selectDays() {
    return Center(
      child: CupertinoSlidingSegmentedControl<int>(
        children: _buildSegmentOptions(),
        groupValue: _selectedSegment,
        onValueChanged: (int? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedSegment = newValue;
            });
          }
        },
      ),
    );
  }

  Future<Map<DateTime, List<FlSpot>>> _calculateA1CData(
      Map<DateTime, List<double>> glucoseByDate, List<DateTime> days) async {
    final a1cByDate = <DateTime, List<FlSpot>>{};
    List<double> cumulativeGlucose = [];

    for (final day in days) {
      final dayGlucose = glucoseByDate[day] ?? [];

      List<FlSpot> a1cSpots = [];

      for (int i = 0; i < dayGlucose.length; i++) {
        // Thêm glucose value vào cumulative
        cumulativeGlucose.add(dayGlucose[i]);

        // Tính A1C cho cumulative glucose đến thời điểm này
        final a1c =
            await GlucoseCalculator.calculateEstimatedA1C(cumulativeGlucose);

        // Tạo FlSpot với x là thời gian trong ngày, y là A1C
        final x =
            (i < dayGlucose.length - 1) ? (i * 24.0 / dayGlucose.length) : 24.0;
        a1cSpots.add(FlSpot(x, a1c));
      }

      a1cByDate[day] = a1cSpots;
    }

    return a1cByDate;
  }

  List<Map<int, List<double>>> groupRecordsByWeek(List<HealthRecord> records) {
    // Sắp xếp tăng dần
    records.sort((a, b) =>
        (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    // Map từ weekStartDate -> weekday -> List<glucose>
    final Map<DateTime, Map<int, List<double>>> weekMap = {};

    for (final record in records) {
      if (record.date == null) continue;

      final date = record.date!;
      final glucose = record.maybeWhen(
        glucose: (id, g, t, d, n) => g,
        orElse: () => null,
      );
      if (glucose == null) continue;

      // Lấy thứ trong tuần: Mon = 0, ..., Sun = 6
      final weekday = date.weekday - 1;

      // Tìm ngày bắt đầu tuần (thứ 2)
      final weekStart = DateTime(
        date.year,
        date.month,
        date.day - weekday,
      );

      weekMap.putIfAbsent(weekStart, () => {});
      weekMap[weekStart]!.putIfAbsent(weekday, () => []);
      weekMap[weekStart]![weekday]!.add(glucose);
    }

    // Sắp xếp theo thời gian
    final sortedWeeks = weekMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Trả về List<Map<int, List<double>>> để dùng trong chart
    return sortedWeeks.map((e) => e.value).toList();
  }

  List<DateTime> getWeekStartDates(List<HealthRecord> records) {
    // Sắp xếp tăng dần
    records.sort((a, b) =>
        (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    final Set<DateTime> weekStartDates = {};

    for (final record in records) {
      if (record.date == null) continue;

      final date = record.date!;

      // Lấy thứ trong tuần: Mon = 0, ..., Sun = 6
      final weekday = date.weekday - 1;

      // Tìm ngày bắt đầu tuần (thứ 2)
      final weekStart = DateTime(
        date.year,
        date.month,
        date.day - weekday,
      );

      weekStartDates.add(weekStart);
    }

    // Sắp xếp theo thời gian
    final sortedWeekStarts = weekStartDates.toList()..sort();
    return sortedWeekStarts;
  }

  List<Map<int, List<double>>> _convertA1CToWeekFormat(
      Map<DateTime, List<FlSpot>> a1cByDate, List<DateTime> days) {
    // Map từ weekStartDate -> weekday -> List<a1c>
    final Map<DateTime, Map<int, List<double>>> weekMap = {};

    for (final day in days) {
      final a1cSpots = a1cByDate[day] ?? [];
      if (a1cSpots.isEmpty) continue;

      // Lấy thứ trong tuần: Mon = 0, ..., Sun = 6
      final weekday = day.weekday - 1;

      // Tìm ngày bắt đầu tuần (thứ 2)
      final weekStart = DateTime(
        day.year,
        day.month,
        day.day - weekday,
      );

      weekMap.putIfAbsent(weekStart, () => {});
      weekMap[weekStart]!.putIfAbsent(weekday, () => []);

      // Thêm tất cả A1C values cho ngày này
      for (final spot in a1cSpots) {
        weekMap[weekStart]![weekday]!.add(spot.y);
      }
    }

    // Sắp xếp theo thời gian
    final sortedWeeks = weekMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Trả về List<Map<int, List<double>>> để dùng trong chart
    return sortedWeeks.map((e) => e.value).toList();
  }

  List<Map<int, List<double>>> groupRecordsByMonth(List<HealthRecord> records) {
    // Sắp xếp tăng dần
    records.sort((a, b) =>
        (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    // Map từ monthStartDate -> dayOfMonth -> List<glucose>
    final Map<DateTime, Map<int, List<double>>> monthMap = {};

    for (final record in records) {
      if (record.date == null) continue;

      final date = record.date!;
      final glucose = record.maybeWhen(
        glucose: (id, g, t, d, n) => g,
        orElse: () => null,
      );
      if (glucose == null) continue;

      // Lấy ngày trong tháng (0-30)
      final dayOfMonth = date.day - 1;

      // Tìm ngày bắt đầu tháng
      final monthStart = DateTime(date.year, date.month, 1);

      monthMap.putIfAbsent(monthStart, () => {});
      monthMap[monthStart]!.putIfAbsent(dayOfMonth, () => []);
      monthMap[monthStart]![dayOfMonth]!.add(glucose);
    }

    // Sắp xếp theo thời gian
    final sortedMonths = monthMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Trả về List<Map<int, List<double>>> để dùng trong chart
    return sortedMonths.map((e) => e.value).toList();
  }

  List<Map<int, List<double>>> _convertA1CToMonthFormat(
      Map<DateTime, List<FlSpot>> a1cByDate, List<DateTime> days) {
    // Map từ monthStartDate -> dayOfMonth -> List<a1c>
    final Map<DateTime, Map<int, List<double>>> monthMap = {};

    for (final day in days) {
      final a1cSpots = a1cByDate[day] ?? [];
      if (a1cSpots.isEmpty) continue;

      // Lấy ngày trong tháng (0-30)
      final dayOfMonth = day.day - 1;

      // Tìm ngày bắt đầu tháng
      final monthStart = DateTime(day.year, day.month, 1);

      monthMap.putIfAbsent(monthStart, () => {});
      monthMap[monthStart]!.putIfAbsent(dayOfMonth, () => []);

      // Thêm tất cả A1C values cho ngày này
      for (final spot in a1cSpots) {
        monthMap[monthStart]![dayOfMonth]!.add(spot.y);
      }
    }

    // Sắp xếp theo thời gian
    final sortedMonths = monthMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Trả về List<Map<int, List<double>>> để dùng trong chart
    return sortedMonths.map((e) => e.value).toList();
  }

  List<Map<int, List<double>>> groupRecordsBy6Months(
      List<HealthRecord> records) {
    // Sắp xếp tăng dần
    records.sort((a, b) =>
        (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    // Map từ sixMonthStartDate -> monthIndex -> List<glucose>
    final Map<DateTime, Map<int, List<double>>> sixMonthMap = {};

    for (final record in records) {
      if (record.date == null) continue;

      final date = record.date!;
      final glucose = record.maybeWhen(
        glucose: (id, g, t, d, n) => g,
        orElse: () => null,
      );
      if (glucose == null) continue;

      // Tìm ngày bắt đầu của 6 tháng (6 tháng gần nhất)
      final currentMonth = date.month;
      final currentYear = date.year;

      // Tính toán 6 tháng gần nhất
      final sixMonthStart = _getSixMonthStart(currentYear, currentMonth);

      // Tính monthIndex trong 6 tháng (0-5)
      final monthIndex = _getMonthIndexIn6Months(date);

      sixMonthMap.putIfAbsent(sixMonthStart, () => {});
      sixMonthMap[sixMonthStart]!.putIfAbsent(monthIndex, () => []);
      sixMonthMap[sixMonthStart]![monthIndex]!.add(glucose);
    }

    // Sắp xếp theo thời gian
    final sortedSixMonths = sixMonthMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Trả về List<Map<int, List<double>>> để dùng trong chart
    return sortedSixMonths.map((e) => e.value).toList();
  }

  DateTime _getSixMonthStart(int year, int month) {
    // Tính toán ngày bắt đầu của 6 tháng gần nhất
    // Ví dụ: tháng 6 -> bắt đầu từ tháng 1
    // Ví dụ: tháng 9 -> bắt đầu từ tháng 4
    final startMonth = ((month - 1) ~/ 6) * 6 + 1;
    return DateTime(year, startMonth, 1);
  }

  int _getMonthIndexIn6Months(DateTime date) {
    // Tính monthIndex trong 6 tháng (0-5)
    final month = date.month;
    final startMonth = ((month - 1) ~/ 6) * 6 + 1;
    return month - startMonth;
  }

  List<Map<int, List<double>>> _convertA1CTo6MonthsFormat(
      Map<DateTime, List<FlSpot>> a1cByDate, List<DateTime> days) {
    // Map từ sixMonthStartDate -> monthIndex -> List<a1c>
    final Map<DateTime, Map<int, List<double>>> sixMonthMap = {};

    for (final day in days) {
      final a1cSpots = a1cByDate[day] ?? [];
      if (a1cSpots.isEmpty) continue;

      // Tìm ngày bắt đầu của 6 tháng
      final sixMonthStart = _getSixMonthStart(day.year, day.month);

      // Tính monthIndex trong 6 tháng (0-5)
      final monthIndex = _getMonthIndexIn6Months(day);

      sixMonthMap.putIfAbsent(sixMonthStart, () => {});
      sixMonthMap[sixMonthStart]!.putIfAbsent(monthIndex, () => []);

      // Thêm tất cả A1C values cho tháng này
      for (final spot in a1cSpots) {
        sixMonthMap[sixMonthStart]![monthIndex]!.add(spot.y);
      }
    }

    // Sắp xếp theo thời gian
    final sortedSixMonths = sixMonthMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Trả về List<Map<int, List<double>>> để dùng trong chart
    return sortedSixMonths.map((e) => e.value).toList();
  }

  List<Map<int, List<double>>> groupRecordsByYear(List<HealthRecord> records) {
    // Sắp xếp tăng dần
    records.sort((a, b) =>
        (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    // Map từ yearStartDate -> monthIndex -> List<glucose>
    final Map<DateTime, Map<int, List<double>>> yearMap = {};

    for (final record in records) {
      if (record.date == null) continue;

      final date = record.date!;
      final glucose = record.maybeWhen(
        glucose: (id, g, t, d, n) => g,
        orElse: () => null,
      );
      if (glucose == null) continue;

      // Lấy ngày bắt đầu năm
      final yearStart = DateTime(date.year, 1, 1);

      yearMap.putIfAbsent(yearStart, () => {});
      yearMap[yearStart]!.putIfAbsent(date.month - 1, () => []);
      yearMap[yearStart]![date.month - 1]!.add(glucose);
    }

    // Sắp xếp theo thời gian
    final sortedYears = yearMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Trả về List<Map<int, List<double>>> để dùng trong chart
    return sortedYears.map((e) => e.value).toList();
  }

  List<Map<int, List<double>>> _convertA1CToYearFormat(
      Map<DateTime, List<FlSpot>> a1cByDate, List<DateTime> days) {
    // Map từ yearStartDate -> monthIndex -> List<a1c>
    final Map<DateTime, Map<int, List<double>>> yearMap = {};

    for (final day in days) {
      final a1cSpots = a1cByDate[day] ?? [];
      if (a1cSpots.isEmpty) continue;

      // Lấy ngày bắt đầu năm
      final yearStart = DateTime(day.year, 1, 1);

      yearMap.putIfAbsent(yearStart, () => {});
      yearMap[yearStart]!.putIfAbsent(day.month - 1, () => []);

      // Thêm tất cả A1C values cho tháng này
      for (final spot in a1cSpots) {
        yearMap[yearStart]![day.month - 1]!.add(spot.y);
      }
    }

    // Sắp xếp theo thời gian
    final sortedYears = yearMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Trả về List<Map<int, List<double>>> để dùng trong chart
    return sortedYears.map((e) => e.value).toList();
  }

  List<DateTime> getMonthStartDates(List<HealthRecord> records) {
    // Sắp xếp tăng dần
    records.sort((a, b) =>
        (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    final Set<DateTime> monthStartDates = {};

    for (final record in records) {
      if (record.date == null) continue;

      final date = record.date!;

      // Lấy ngày bắt đầu tháng
      final monthStart = DateTime(date.year, date.month, 1);

      monthStartDates.add(monthStart);
    }

    // Sắp xếp theo thời gian
    final sortedMonthStarts = monthStartDates.toList()..sort();
    return sortedMonthStarts;
  }

  List<DateTime> getSixMonthStartDates(List<HealthRecord> records) {
    // Sắp xếp tăng dần
    records.sort((a, b) =>
        (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    final Set<DateTime> sixMonthStartDates = {};

    for (final record in records) {
      if (record.date == null) continue;

      final date = record.date!;
      // Tìm ngày bắt đầu của 6 tháng (6 tháng gần nhất)
      final currentMonth = date.month;
      final currentYear = date.year;
      final sixMonthStart = _getSixMonthStart(currentYear, currentMonth);
      sixMonthStartDates.add(sixMonthStart);
    }

    // Sắp xếp theo thời gian
    final sortedSixMonthStarts = sixMonthStartDates.toList()..sort();
    return sortedSixMonthStarts;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context) {
    int selectedTab = 0; // 0 = Tag, 1 = Type

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStatePopup) => CupertinoPopupSurface(
          isSurfacePainted: true,
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Close",
                            style: TextStyle(
                                color: primary6, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Done",
                            style: TextStyle(
                                color: primary6, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab Control
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: selectedTab,
                      children: {
                        0: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Text('Tags',
                              style: TextStyle(fontSize: 15)),
                        ),
                        1: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Text('Types',
                              style: TextStyle(fontSize: 15)),
                        ),
                      },
                      onValueChanged: (value) {
                        if (value != null) {
                          setStatePopup(() {
                            selectedTab = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Content
                Expanded(
                  child: selectedTab == 0
                      ? _buildTagList(context, (tag) {
                          setState(() {
                            _selectedTag = tag == 'All Tags' ? null : tag;
                          });
                          Navigator.pop(context);
                        })
                      : _buildTypeList(context, (type) {
                          setState(() {
                            _selectedType = type == 'All Types' ? null : type;
                          });
                          Navigator.pop(context);
                        }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagList(BuildContext context, Function(String) onTagSelected) {
    return Consumer<HealthRecordProvider>(
      builder: (context, provider, child) {
        final allTags = provider.records.expand((r) => r.tags).toSet().toList()
          ..sort();
        allTags.insert(0, 'All Tags');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: allTags.length,
            itemBuilder: (context, index) {
              final tag = allTags[index];
              final isSelected = _selectedTag == tag ||
                  (_selectedTag == null && tag == 'All Tags');
              return GestureDetector(
                onTap: () => onTagSelected(tag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected ? primary1 : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: isSelected
                          ? CupertinoColors.white
                          : CupertinoColors.label,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTypeList(BuildContext context, Function(String) onTypeSelected) {
    return Consumer<HealthRecordProvider>(
      builder: (context, provider, child) {
        final recordTypes = provider.records
            .map((record) => record.when(
                  glucose: (id, glucose, tags, date, note) => 'Glucose',
                  weight: (id, weight, tags, date, note) => 'Weight',
                  bloodPressure: (id, sys, dia, hr, tags, date, note) =>
                      'Blood Pressure',
                  insulin: (id, units, name, tags, date, note) => 'Insulin',
                  medication: (id, name, time, tags, date, note) =>
                      'Medications',
                  carbs: (id, carbs, food, fat, protein, tags, date, note) =>
                      'Carbs',
                  temperature: (id, temp, tags, date, note) => 'Temperature',
                  a1c: (id, a1c, tags, date, note) => 'A1C',
                  exercise: (id, type, duration, tags, date, note) =>
                      'Exercise',
                  oxygen: (id, oxy, hr, tags, date, note) => 'Oxygen',
                  note: (id, tags, date, note) => 'Notes',
                  ketones: (id, ketones, tags, date, note) => 'Ketones',
                ))
            .where((type) => type.isNotEmpty)
            .toSet()
            .toList();
        recordTypes.sort();
        recordTypes.insert(0, 'All Types');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: recordTypes.length,
            itemBuilder: (context, index) {
              final type = recordTypes[index];
              final isSelected = _selectedType == type ||
                  (_selectedType == null && type == 'All Types');
              return GestureDetector(
                onTap: () => onTypeSelected(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected ? primary1 : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected
                          ? CupertinoColors.white
                          : CupertinoColors.label,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Hàm filter records theo tag và type
  List<HealthRecord> filterRecords(
      List<HealthRecord> records, String? tag, String? type) {
    var filtered = records;
    if (tag != null) {
      filtered = filtered.where((r) => r.tags.contains(tag)).toList();
    }
    if (type != null) {
      filtered = filtered.where((record) {
        return record.when(
          glucose: (id, glucose, tags, date, note) => type == 'Glucose',
          weight: (id, weight, tags, date, note) => type == 'Weight',
          bloodPressure: (id, sys, dia, hr, tags, date, note) =>
              type == 'Blood Pressure',
          insulin: (id, units, name, tags, date, note) => type == 'Insulin',
          medication: (id, name, time, tags, date, note) =>
              type == 'Medications',
          carbs: (id, carbs, food, fat, protein, tags, date, note) =>
              type == 'Carbs',
          temperature: (id, temp, tags, date, note) => type == 'Temperature',
          a1c: (id, a1c, tags, date, note) => type == 'A1C',
          exercise: (id, type, duration, tags, date, note) =>
              type == 'Exercise',
          oxygen: (id, oxy, hr, tags, date, note) => type == 'Oxygen',
          note: (id, tags, date, note) => type == 'Notes',
          ketones: (id, ketones, tags, date, note) => type == 'Ketones',
        );
      }).toList();
    }
    return filtered;
  }

  List<FlSpot> getChartData(List<HealthRecord> records) {
    final days = _getDaysForSegment(_selectedSegment);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final startDate = todayStart.subtract(Duration(days: days - 1));

    // Dùng hàm filter mới
    var filteredRecords =
        filterRecords(records, _selectedTag, _selectedType).where((record) {
      final date = record.date ?? DateTime.now();
      return !date.isBefore(startDate) &&
          date.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    filteredRecords.sort((a, b) =>
        (a.date ?? DateTime.now()).compareTo(b.date ?? DateTime.now()));

    if (days == 1) {
      // 1 DAY: Trục X là giờ trong ngày (0.0 -> 24.0)
      return filteredRecords.map((record) {
        final date = record.date ?? DateTime.now();
        final x = date.hour + date.minute / 60.0;
        final y =
            record.maybeWhen(glucose: (id, g, t, d, n) => g, orElse: () => 0.0);
        return FlSpot(x, y);
      }).toList();
    } else if (days == 7 || days == 14) {
      // 7, 14 DAY: Group by day and get MAX
      final Map<int, List<double>> dailyData = {};

      for (final record in filteredRecords) {
        final date = record.date ?? DateTime.now();
        final dayIndex = date.difference(startDate).inDays;

        if (dayIndex >= 0 && dayIndex < days) {
          final glucoseValue = record.maybeWhen(
              glucose: (id, g, t, d, n) => g, orElse: () => null);

          if (glucoseValue != null) {
            if (dailyData.containsKey(dayIndex)) {
              dailyData[dayIndex]!.add(glucoseValue);
            } else {
              dailyData[dayIndex] = [glucoseValue];
            }
          }
        }
      }

      // Convert to FlSpot with average values
      return dailyData.entries.map((entry) {
        final day = entry.key;
        final values = entry.value;
        final maxY = values.reduce((a, b) => a > b ? a : b);
        return FlSpot(day.toDouble(), maxY);
      }).toList()
        ..sort((a, b) => a.x.compareTo(b.x)); // Sort by day
    } else if (days == 30 || days == 90) {
      // 30, 90 DAY: Gom nhóm theo tuần và lấy giá trị cao nhất
      final Map<int, List<double>> weeklyData = {};

      for (final record in filteredRecords) {
        final date = record.date ?? DateTime.now();
        final weekNumber = (date.difference(startDate).inDays / 7).floor();
        final glucoseValue = record.maybeWhen(
            glucose: (id, g, t, d, n) => g, orElse: () => null);

        if (glucoseValue != null) {
          if (weeklyData.containsKey(weekNumber)) {
            weeklyData[weekNumber]!.add(glucoseValue);
          } else {
            weeklyData[weekNumber] = [glucoseValue];
          }
        }
      }

      // Chuyển đổi thành FlSpot với giá trị trung bình
      return weeklyData.entries.map((entry) {
        final week = entry.key;
        final values = entry.value;
        final maxY = values.reduce((a, b) => a > b ? a : b);
        return FlSpot(week.toDouble(), maxY);
      }).toList()
        ..sort((a, b) => a.x.compareTo(b.x)); // Sắp xếp lại theo tuần
    } else {
      // 365 days: gom nhóm theo tháng, index từ 0 (Jan) đến 11 (Dec)
      final Map<int, List<double>> monthlyData = {};
      for (final record in records) {
        final date = record.date;
        if (date != null) {
          final monthIndex = date.month - 1; // 0 = Jan, 11 = Dec
          final glucoseValue = record.maybeWhen(
              glucose: (id, g, t, d, n) => g, orElse: () => null);
          if (glucoseValue != null) {
            monthlyData.putIfAbsent(monthIndex, () => []).add(glucoseValue);
          }
        }
      }
      return monthlyData.entries.map((entry) {
        final month = entry.key;
        final values = entry.value;
        final maxY = values.reduce((a, b) => a > b ? a : b);
        return FlSpot(month.toDouble(), maxY);
      }).toList()
        ..sort((a, b) => a.x.compareTo(b.x));
    }
  }
}
