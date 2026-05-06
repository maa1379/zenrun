import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/dialog_view.dart';
import 'package:zenrun/core/widgets/nav_helper.dart';
import 'package:zenrun/src/api_models_repo/models/quiz_model.dart';
import 'package:zenrun/src/home_pages/providers/quiz_provider.dart';
import 'package:zenrun/src/profile_pages/providers/coin_provider.dart';

import '../../../generated/assets.dart';
import 'package:toln/toln.dart';

class QuizDetailPage extends StatefulWidget {
  const QuizDetailPage({super.key, required this.quiz});

  final QuizModel quiz;
  @override
  State<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBtn(),
      appBar: UiHelper.appBar("Quiz"),
      extendBody: true,
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (!provider.loading) {
            return UiHelper.showLoading();
          }
          return PageView.builder(
            controller: provider.pageController,
            itemCount: widget.quiz.questionList.length,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (value) {
              provider.currentPage = value;
              provider.update();
            },
            itemBuilder: (context, index) {
              final item = widget.quiz.questionList[index];
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(Assets.imagesImg4),
                    fit: BoxFit.cover,
                  ),
                ),
                height: 100.h,
                width: 100.w,
                child: ListView(
                  children: [
                    const Gap(20),
                    Container(
                      width: 100.w,
                      margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.5.w,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: ColorsHelper.btn2),
                        borderRadius: UiHelper.borderRadius16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              "question ${index + 1}:  ${item.soal!}".toLn(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(20),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: item.qList.map((element) {
                        return Container(
                          width: 45.w,
                          margin: EdgeInsets.symmetric(
                            horizontal: 2.5.w,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: element.isSelected
                                ? ColorsHelper.btn2.withOpacity(0.4)
                                : Colors.transparent,
                            borderRadius: UiHelper.borderRadius16,
                            border: Border.all(
                              color: ColorsHelper.btn2,
                              width: 0.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: UiHelper.borderRadius16,
                            child: InkWell(
                              borderRadius: UiHelper.borderRadius16,
                              onTap: () async {
                                for (var i in item.qList) {
                                  i.isSelected = false;
                                }
                                element.isSelected = true;
                                item.isSelected = true;
                                provider.update();
                                if (provider.answerList.isNotEmpty &&
                                    provider.answerList.any(
                                      (e) => e.questionId == item.id.toString(),
                                    )) {
                                  provider.answerList.removeLast();
                                }
                                provider.answerList.add(
                                  AnswerData(
                                    gozineEntekhabi: element.q,
                                    questionId: item.id.toString(),
                                    quizId: item.quizId.toString(),
                                    isTrue: item.gozineTrue == element.q,
                                  ),
                                );
                                provider.update();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    element.q,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBtn() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 50),
      child: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (!provider.loading) {
            return const SizedBox.shrink();
          }

          return UiHelper.buttonMain2(
            () async {
              if (widget.quiz.questionList[provider.currentPage].isSelected == false) {
                ViewHelper.showErrorDialog(context, text: "Choose an answer");
              } else if (provider.questionList.indexOf(
                    provider.questionList[provider.questionList.length - 1],
                  ) ==
                  provider.currentPage) {
                int trueCount = provider.answerList
                    .where((element) => element.isTrue)
                    .length;
                DialogView.showTypeDialog(
                  this.context,
                  (trueCount >= int.parse(widget.quiz.passingScore ?? "0"))
                      ?"By doing this, you will earn (${widget.quiz.rCoin.toString()} R coins) , (${widget.quiz.zCoin.toString()} Z coins) (${widget.quiz.sCoin.toString()} S coins) (${widget.quiz.coin.toString()} coins)"
                    : "Unfortunately, you couldn't at least give the correct answer.",
                  (trueCount >= int.parse(widget.quiz.passingScore ?? "0"))
                      ? DialogType.success
                      : DialogType.error,
                  () async {
                    await provider.setAnswer();
                    await provider.finishQuiz(widget.quiz.id.toString());
                    if (trueCount >=
                        int.parse(widget.quiz.passingScore ?? "0")) {
                      await this.context.read<CoinProvider>().setAddCoin(
                            widget.quiz.coin.toString(),
                            widget.quiz.rCoin.toString(),
                            widget.quiz.zCoin.toString(),
                            widget.quiz.sCoin.toString(),
                          );
                      this.context.pop();
                    }
                    ViewHelper.showSuccessDialog(
                      this.context,
                      "Successfully completed",
                    );
                  },
                );
              } else {
                provider.pageController.nextPage(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.linear,
                );
              }
            },

            provider.questionList.indexOf(
                      provider.questionList[provider.questionList.length - 1],
                    ) ==
                    provider.currentPage
                ? "Completion"
                : "Next",
            fontSize: 18,
            height: 5.h,
            width: 100.w,
          );
        },
      ),
    );
  }
}
