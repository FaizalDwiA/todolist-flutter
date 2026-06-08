import 'package:flutter/material.dart';

/// Mengembalikan ikon representatif untuk setiap kategori tugas.
IconData getCategoryIcon(String category) {
  switch (category) {
    case "Kerja":
      return Icons.work_outline;
    case "Pribadi":
      return Icons.person_outline;
    case "Belanja":
      return Icons.shopping_bag_outlined;
    case "Kesehatan":
      return Icons.favorite_border;
    default:
      return Icons.bookmark_border;
  }
}

/// Memformat objek [DateTime] ke format tanggal string Bahasa Indonesia yang ringkas.
String formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final targetDate = DateTime(date.year, date.month, date.day);

  if (targetDate == today) {
    return "Hari ini";
  } else if (targetDate == tomorrow) {
    return "Besok";
  }

  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  return "${date.day} ${months[date.month - 1]} ${date.year}";
}
