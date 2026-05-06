import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/widgets/Costance.dart';
import 'package:toln/toln.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  TextEditingController amount = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsHelper.white,
      appBar: UiHelper.appBar("Transaction List"),
      body: SizedBox(
        height: 100.h,
        width: 100.w,
        child: ListView.separated(
          itemCount: 15,
          separatorBuilder: (context, index) {
            return Divider(color: ColorsHelper.btn1);
          },
          itemBuilder: (context, index) {
            return SizedBox(
              height: 6.h,
              width: 100.w,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Column(
                  spacing: 10,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Charge my wallet".toLn(),
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Amount:".toLn(),
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        Text(
                          "\$50".toLn(),
                          style:
                              TextStyle(color: ColorsHelper.blue, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
