import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/core/utils/auto_router_setup/auto_router.gr.dart';
import 'package:flutter_app/src/core/utils/values/colors.dart';

class GraphTopBar extends StatelessWidget {
  final VoidCallback? onSelectPressed;

  const GraphTopBar({
    super.key,
    this.onSelectPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // [Select Button - Không outline]
        Flexible(
          flex: 2,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 32),
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.slider_horizontal_3,
                    size: 18, color: blue203C6F),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Select',
                    style: TextStyle(fontSize: 14, color: blue203C6F),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            onPressed: onSelectPressed,
          ),
        ),
        // [Center Text]
        const Flexible(
          flex: 3,
          child: Text(
            'Glucose',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // [Add Record Button - Không outline]
        Flexible(
          flex: 2,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 32),
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.add, size: 18, color: blue203C6F),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Record',
                    style: TextStyle(fontSize: 14, color: blue203C6F),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            onPressed: () {
              context.router.push(CreateRecordRoute(initialType: 'Glucose'));
            },
          ),
        ),
      ],
    );
  }
}
