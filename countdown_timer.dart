import 'dart:ui';

class CountdownTimer {
  final String id;
  final String title;
  final DateTime targetDate;
  final Color color;

  CountdownTimer({
    required this.id,
    required this.title,
    required this.targetDate,
    required this.color,
  });

  factory CountdownTimer.fromJson(Map<String, dynamic> json) {
    return CountdownTimer(
      id: json['id'],
      title: json['title'],
      targetDate: DateTime.parse(json['targetDate']),
      color: Color(json['color']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetDate': targetDate.toIso8601String(),
      'color': color.value,
    };
  }
}