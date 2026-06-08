import 'package:flutter/material.dart';
import 'package:todolist1/screens/todo_list_screen.dart';

void main() {
  runApp(const MyApp());
}

/// [MyApp] adalah root widget dari aplikasi Anda.
/// Widget ini bersifat stateless karena pengaturan tema dan navigasi utama tidak berubah secara dinamis di sini.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Premium Todo List',
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug di pojok kanan atas
      theme: ThemeData(
        useMaterial3: true, // Menggunakan desain Material 3 yang modern
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Warna dasar Indigo modern
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF14B8A6), // Warna Teal untuk aksen
          surface: const Color(0xFFF8FAFC), // Latar belakang abu-abu sangat terang (Slate 50)
        ),
        fontFamily: 'Roboto', // Menggunakan font sistem standar yang bersih
      ),
      home: const TodoListScreen(),
    );
  }
}
