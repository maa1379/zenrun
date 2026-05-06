import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/custom_sacffold.dart';
import 'package:zenrun/core/widgets/dialog_view.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/api_models_repo/models/fasl_model.dart';
import 'package:zenrun/src/api_models_repo/models/task_model.dart';
import 'package:zenrun/src/home_pages/pages/task_detail_page.dart';
import 'package:zenrun/src/home_pages/providers/task_provider.dart';
import 'package:zenrun/src/profile_pages/providers/coin_provider.dart';

import '../../../generated/assets.dart';
import '../../profile_pages/providers/profile_provider.dart';

class MissionPage extends StatefulWidget {
  const MissionPage({
    super.key,
    required this.taskList,
    required this.title,
    required this.faslModel,
  });

  final List<TaskModel> taskList;
  final String title;
  final FaslModel faslModel;

  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TaskProvider>().sortTaskList(widget.taskList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: widget.title,
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          if (provider.state == ViewState.Loading) {
            return Center(child: UiHelper.showLoading());
          }
          if (provider.state == ViewState.Error) {
            return Center(child: Text("Failed to load tasks".toLn()));
          }

          // فیلتر کردن تسک‌ها (مثلاً مخفی کردن تسک‌های منقضی شده)
          final List<TaskModel> activeTasks = widget.taskList.where((task) {
            return !provider.isTaskExpired(task);
          }).toList();

          if (activeTasks.isEmpty) {
            return Center(
              child: Text("No active tasks available right now.".toLn(),
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: activeTasks.length,
            itemBuilder: (context, index) {
              final task = activeTasks[index];
              final isCompleted = provider.isTaskCompleted(task.id.toString());
              final isUnlocked = provider.canDoTaskInFasl(fasl: widget.faslModel, currentTask: task);
              final isLast = index == activeTasks.length - 1;

              return _buildTimelineItem(task, isCompleted, isUnlocked, isLast, provider);
            },
          ).animate().fadeIn(duration: 400.ms);
        },
      ),
    );
  }

  Widget _buildTimelineItem(TaskModel task, bool isCompleted, bool isUnlocked, bool isLast, TaskProvider provider) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // بخش خط و دایره (تایم‌لاین)
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green
                        : (isUnlocked ? ColorsHelper.btn1 : Colors.grey.shade300),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)
                    ]
                ),
                child: Icon(
                  isCompleted ? Icons.check : (isUnlocked ? Icons.play_arrow : Icons.lock),
                  size: 16,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    color: isCompleted ? Colors.green.shade300 : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const Gap(15),
          // بخش کارت تسک
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: GestureDetector(
                onTap: isUnlocked || isCompleted ? () => _onTaskTapped(context, provider, task, isCompleted) : null,
                child: Opacity(
                  opacity: isUnlocked || isCompleted ? 1.0 : 0.6,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                task.title ?? "Unknown Task",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            _buildTaskStatusBadge(isCompleted, isUnlocked, task),
                          ],
                        ),
                        const Gap(12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if ((task.coin ?? 0) > 0) _buildCoinChip(Assets.imagesCoin, "${task.coin}", Colors.amber),
                            if ((task.rCoin ?? 0) > 0) _buildCoinChip(Assets.imagesCoin, "${task.rCoin} R", Colors.blue),
                            if ((task.zCoin ?? 0) > 0) _buildCoinChip(Assets.imagesCoin, "${task.zCoin} Z", Colors.purple),
                            if ((task.sCoin ?? 0) > 0) _buildCoinChip(Assets.imagesCoin, "${task.sCoin} S", Colors.green),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusBadge(bool isCompleted, bool isUnlocked, TaskModel task) {
    final bool isFree = task.priceCoin == "0" || task.priceWallet == "0";

    Color bgColor;
    String text;

    if (isCompleted) {
      bgColor = Colors.green.shade100;
      text = "Done";
    } else if (!isUnlocked) {
      bgColor = Colors.grey.shade200;
      text = "Locked";
    } else if (!isFree) {
      bgColor = Colors.orange.shade100;
      text = "Buy";
    } else {
      bgColor = Colors.blue.shade100;
      text = "Go";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isCompleted ? Colors.green.shade700 : (isUnlocked ? Colors.blue.shade700 : Colors.grey.shade700),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCoinChip(String assetPath, String amount, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: 16, height: 16),
          const Gap(4),
          Text(amount.seRagham(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.shade700)),
        ],
      ),
    );
  }

  void _onTaskTapped(BuildContext context, TaskProvider provider, TaskModel task, bool isCompleted) async {
    final bool isFree = task.priceCoin == "0" || task.priceWallet == "0";

    if (isFree || isCompleted) {
      await context.toCallBack(TaskDetailPage(data: task, isComplete: isCompleted));
      await provider.refreshUserTasks();
    } else {
      _showFinalizePurchaseModal(int.parse(task.priceWallet ?? "0"), int.parse(task.priceCoin ?? "0"), task, provider);
    }
  }

  void _showFinalizePurchaseModal(int walletPrice, int coinPrice, TaskModel e, TaskProvider provider) {
    // منطق خرید مشابه قبل، اما با پاس دادن مستقیم provider برای اطمینان از آپدیت
    showModalBottomSheet(
      showDragHandle: true,
      backgroundColor: Colors.white,
      context: context,
      builder: (ctx) {
        return Container(
          height: 25.h,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Text("Purchase Task", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Gap(20),
              UiHelper.buttonMain2(() async {
                // لاجیک خرید با کیف پول (همانند کد خودتان)
                // پس از موفقیت:
                Navigator.pop(ctx);
                await context.toCallBack(TaskDetailPage(data: e, isComplete: false));
                await provider.refreshUserTasks();
              }, "Pay with Wallet ($walletPrice\$)", width: double.infinity, color: ColorsHelper.btn2),
              const Gap(10),
              UiHelper.buttonMain2(() async {
                // لاجیک خرید با سکه
                Navigator.pop(ctx);
                await context.toCallBack(TaskDetailPage(data: e, isComplete: false));
                await provider.refreshUserTasks();
              }, "Pay with Coins ($coinPrice)", width: double.infinity, color: Colors.orange),
            ],
          ),
        );
      },
    );
  }
}