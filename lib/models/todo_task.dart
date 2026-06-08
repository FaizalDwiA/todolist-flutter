import 'package:flutter/material.dart';

/// [TaskPriority] mendefinisikan tingkat urgensi suatu tugas.
/// Setiap prioritas memiliki warna representasi tersendiri.
enum TaskPriority { low, medium, high }

extension TaskPriorityExtension on TaskPriority {
  Color get color {
    switch (this) {
      case TaskPriority.high:
        return const Color(0xFFEF4444); // Merah Terang
      case TaskPriority.medium:
        return const Color(0xFFF59E0B); // Amber/Oranye
      case TaskPriority.low:
        return const Color(0xFF10B981); // Emerald/Hijau
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.high:
        return "Tinggi";
      case TaskPriority.medium:
        return "Sedang";
      case TaskPriority.low:
        return "Rendah";
    }
  }
}

/// [TodoTask] adalah kelas Model Data untuk menyimpan informasi setiap tugas.
class TodoTask {
  String id;
  String title;
  String category;
  TaskPriority priority;
  DateTime? dueDate;
  bool isCompleted;

  TodoTask({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    this.dueDate,
    this.isCompleted = false,
  });

  /// Mengonversi objek [TodoTask] menjadi Map JSON untuk disimpan di SharedPreferences.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'priority': priority.index,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
      };

  /// Membuat objek [TodoTask] dari Map JSON yang dibaca dari SharedPreferences.
  factory TodoTask.fromJson(Map<String, dynamic> json) => TodoTask(
        id: json['id'],
        title: json['title'],
        category: json['category'],
        priority: TaskPriority.values[json['priority']],
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        isCompleted: json['isCompleted'] ?? false,
      );
}
