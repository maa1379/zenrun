import 'package:flutter/material.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/src/api_models_repo/models/quiz_model.dart';

import '../../../core/network/DataState.dart';
import '../../api_models_repo/api_service.dart';

class QuizProvider extends ChangeNotifier {
  bool loading = false;
  void update() => notifyListeners();
  List<QuizModel> quizList = [];
  List<UserQuizModel> userQuizList = [];
  List<QuestionModel> questionList = [];
  List<AnswerData> answerList = [];

  PageController pageController = PageController(initialPage: 0);
  int currentPage = 0;

  Future<void> getAllQuizList() async {
    loading = false;
    // notifyListeners(); // Avoid unnecessary rebuilds if handled in UI

    final res = await ApiService.instance.getQuizList();
    if (res is DataSuccess) {
      await getUserQuizList();
      currentPage = 0;
      answerList.clear();
      quizList.clear();
      quizList.addAll(res.data ?? []);

      // Load questions for all quizzes to be ready
      // Consider lazy loading if the list is huge, but for now this is fine based on existing structure
      for (var item in quizList) {
        item.questionList = await getQuestionList(item.id.toString());
      }
      loading = true;
      update();
    } else {
      // Handle error state
      loading = true;
      update();
    }
  }

  Future<void> getUserQuizList() async {
    final res = await ApiService.instance.getUserQuizList();
    if (res is DataSuccess) {
      userQuizList.clear();
      userQuizList.addAll(res.data ?? []);
    }
  }

  Future<List<QuestionModel>> getQuestionList(String id) async {
    final res = await ApiService.instance.getQuestionList(id);
    if (res is DataSuccess) {
      // We return the list to attach it to the specific quiz model
      // Clearing the global questionList here might be risky if multiple quizzes load at once
      // but for the detail page, we usually set it there.
      return res.data ?? [];
    } else {
      return [];
    }
  }

  Future<void> setAnswer() async {
    ViewHelper.showLoading();
    for (var i in answerList) {
      await ApiService.instance.setAnswer(
        questionId: i.questionId,
        quizId: i.quizId,
        gozineEntekhabi: i.gozineEntekhabi,
      );
    }
    ViewHelper.dismissLoading();
  }

  Future<void> startQuiz(String quizId) async {
    ViewHelper.showLoading();
    // Reset page controller for new quiz
    if(pageController.hasClients) pageController.jumpToPage(0);
    currentPage = 0;

    // Fetch specific questions for this quiz again to be sure (and populate provider.questionList for the UI)
    final questions = await getQuestionList(quizId);
    questionList.clear();
    questionList.addAll(questions);

    final res = await ApiService.instance.startQuiz(quizId: quizId);
    ViewHelper.dismissLoading();
  }

  Future<void> finishQuiz(String quizId) async {
    ViewHelper.showLoading();
    final res = await ApiService.instance.finishQuiz(quizId: quizId);
    ViewHelper.dismissLoading();
  }
}