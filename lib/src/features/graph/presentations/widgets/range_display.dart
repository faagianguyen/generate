import 'package:flutter/material.dart';

/// Widget hiển thị phạm vi đo đường huyết (range, đơn vị, nhãn, ngày)
/// Display widget for blood glucose range (range, unit, label, date)
class RangeDisplay extends StatelessWidget {
  /// Giá trị phạm vi (ví dụ: 180–721)
  /// Range value (e.g. 180–721)
  final String range;

  /// Đơn vị đo (ví dụ: mg/dL)
  /// Unit (e.g. mg/dL)
  final String unit;

  /// Nhãn tiêu đề (ví dụ: RANGE)
  /// Label (e.g. RANGE)
  final String label;

  /// Nhãn ngày (ví dụ: Today, Hôm nay)
  /// Date label (e.g. Today)
  final String dateLabel;

  /// Màu chữ chính
  /// Main text color
  final Color textColor;

  /// Màu chữ phụ/xám
  /// Grey text color
  final Color grey;

  /// Giá trị trung bình (ví dụ: 350 mg/dL)
  /// Average value (e.g. 350 mg/dL)
  final double? avg;

  /// Đơn vị cho giá trị trung bình (mặc định sẽ dùng unit nếu không set)
  /// Unit for average value (defaults to unit if not set)
  final String? avgUnit;

  const RangeDisplay({
    super.key,
    this.range = "~~~",
    this.unit = "mg/dL",
    this.label = "RANGE",
    this.dateLabel = "~~~",
    required this.textColor,
    required this.grey,
    this.avg,
    this.avgUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Nhãn tiêu đề / Label
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: grey,
          ),
        ),
        // Giá trị phạm vi và đơn vị / Range value and unit
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              range,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                fontSize: 16,
                color: grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (avg != null) ...[
              const SizedBox(width: 8),
              Text(
                '(Avg: ${avg!.toStringAsFixed(2)} ${avgUnit ?? unit})',
                style: TextStyle(
                  fontSize: 16,
                  color: grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        // Nhãn ngày / Date label
        Text(
          dateLabel,
          style: TextStyle(
            fontSize: 14,
            color: grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
