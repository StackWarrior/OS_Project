import 'package:flutter/foundation.dart';

class ShellController extends ChangeNotifier {
  int index = 0;
  String? pendingCoursesSearch;
  String? pendingCategory;

  void goToTab(int i, {String? coursesSearch, String? category}) {
    index = i;
    pendingCoursesSearch = coursesSearch ?? pendingCoursesSearch;
    pendingCategory = category ?? pendingCategory;
    notifyListeners();
  }

  void consumeCoursesSearch(void Function(String q) fn) {
    final q = pendingCoursesSearch;
    pendingCoursesSearch = null;
    if (q != null && q.isNotEmpty) {
      fn(q);
    }
  }

  void consumePendingCategory(void Function(String c) fn) {
    final c = pendingCategory;
    pendingCategory = null;
    if (c != null && c.isNotEmpty) {
      fn(c);
    }
  }
}
