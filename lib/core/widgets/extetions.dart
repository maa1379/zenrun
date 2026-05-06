

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}


extension DateTimeFormatter on DateTime {
  String formatToText() {
    final year = this.year;
    final month = _twoDigits(this.month);
    final day = _twoDigits(this.day);
    final hour = _twoDigits(this.hour);
    final minute = _twoDigits(this.minute);

    return '$year/$month/$day  $hour:$minute';
  }

  String formatToTextOnlyDate() {
    final year = this.year;
    final month = _twoDigits(this.month);
    final day = _twoDigits(this.day);

    return '$year/$month/$day';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}


extension ListUpdate<T> on List<T> {
  List<T> update(int pos, T t) {
    List<T> list = [];
    list.add(t);
    replaceRange(pos, pos + 1, list);
    return this;
  }
}


extension JsonListParser on dynamic {
  List<T> toListModel<T>(T Function(Map<String, dynamic> json) fromJson) {
    if (this == null || this is! List) {
      return <T>[];
    }
    return (this as List)
        .where((e) => e != null)
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }
}