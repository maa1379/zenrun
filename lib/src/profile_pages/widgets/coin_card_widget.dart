import 'package:flutter/material.dart';

import '../../../core/widgets/Costance.dart';


class CoinCard extends StatelessWidget {
  final String title;
  final String value;
  final String avatarText;
  final Color backgroundColor;
  final Function() onTap;

  const CoinCard({
    super.key,
    required this.title,
    required this.value,
    required this.avatarText,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: backgroundColor,
          ),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  avatarText,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: ColorsHelper.textColor1,
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: ColorsHelper.textColor1,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}