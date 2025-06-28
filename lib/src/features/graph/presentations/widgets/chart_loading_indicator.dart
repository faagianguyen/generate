import 'package:flutter/cupertino.dart';

class ChartLoadingIndicator extends StatelessWidget {
  const ChartLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 840,
      child: Center(
        child: CupertinoActivityIndicator(radius: 16),
      ),
    );
  }
}
