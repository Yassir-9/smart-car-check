import 'dart:convert';

class MaintenanceReminder {
  final String id;
  final String title;
  final DateTime dueDate;
  final String? notes;
  final bool isDone;

  MaintenanceReminder({
    required this.id,
    required this.title,
    required this.dueDate,
    this.notes,
    this.isDone = false,
  });

  MaintenanceReminder copyWith({
    String? title,
    DateTime? dueDate,
    String? notes,
    bool? isDone,
  }) {
    return MaintenanceReminder(
      id: id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dueDate': dueDate.toIso8601String(),
        'notes': notes,
        'isDone': isDone,
      };

  factory MaintenanceReminder.fromJson(Map<String, dynamic> json) {
    return MaintenanceReminder(
      id: json['id'] as String,
      title: json['title'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      notes: json['notes'] as String?,
      isDone: json['isDone'] as bool? ?? false,
    );
  }

  static String encodeList(List<MaintenanceReminder> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<MaintenanceReminder> decodeList(String jsonStr) {
    final List<dynamic> data = jsonDecode(jsonStr) as List<dynamic>;
    return data
        .map((e) => MaintenanceReminder.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
