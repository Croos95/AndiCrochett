import 'package:flutter/material.dart';
import 'package:andicrochett/core/constants/colors.dart';
import 'package:andicrochett/core/constants/sizes.dart';
import 'package:andicrochett/core/config/env.dart';

class DashboardFooter extends StatelessWidget {
  const DashboardFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Sizes.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '© 2026 ${Env.appName}',
            style: const TextStyle(
              color: AppColors.texto,
              fontSize: Sizes.fontSizeSm,
            ),
          ),
          Text(
            'v${Env.appVersion}',
            style: const TextStyle(
              color: AppColors.texto,
              fontSize: Sizes.fontSizeSm,
            ),
          ),
        ],
      ),
    );
  }
}
