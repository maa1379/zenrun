import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/custom_sacffold.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/home_pages/pages/quiz_detail_page.dart';
import 'package:zenrun/src/home_pages/providers/quiz_provider.dart';

import '../../../generated/assets.dart';
import 'package:toln/toln.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  @override
  void initState() {
    super.initState();
    // Fetch data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().getAllQuizList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "Quiz",
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (!provider.loading) {
            return UiHelper.showLoading();
          }
          return RefreshIndicator(
            onRefresh: () async {
              await provider.getAllQuizList();
            },
            child: (provider.quizList.isEmpty)
                ? Center(child: Text("No Quiz Available".toLn()))
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 10),
              itemCount: provider.quizList.length,
              itemBuilder: (context, index) {
                final item = provider.quizList[index];
                final isFinished = provider.userQuizList.any(
                        (element) => element.quizId == item.id && element.isFinish == true);

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: UiHelper.shadow1,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _handleQuizTap(provider, item, isFinished),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Quiz ${index + 1}".toLn(),
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                if(isFinished)
                                  const Icon(Icons.check_circle, color: Colors.white, size: 20)
                              ],
                            ),
                            const Gap(15),
                            Row(
                              children: [
                                Image.asset(Assets.imagesCoin, width: 24),
                                const Gap(8),
                                Text(
                                  "${item.coin} Coins".toLn(),
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isFinished ? "Finished" : "Start",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleQuizTap(QuizProvider provider, var item, bool isFinished) async {
    if (isFinished) {
      ViewHelper.showWarningDialog(context, "You have already taken this quiz");
    } else {
      provider.answerList.clear();
      provider.currentPage = 0;
      await provider.startQuiz(item.id.toString());
      // Ensure question list for this quiz is loaded in provider before navigating
      provider.questionList.clear();
      provider.questionList.addAll(item.questionList);

      await context.toCallBack(QuizDetailPage(quiz: item));
      provider.getAllQuizList();
    }
  }
}