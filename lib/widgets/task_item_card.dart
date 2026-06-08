import 'package:flutter/material.dart';
import 'package:todolist1/models/todo_task.dart';
import 'package:todolist1/utils/todo_helpers.dart';

class TaskItemCard extends StatelessWidget {
  final TodoTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskItemCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id), // Kunci unik wajib untuk setiap Dismissible
      direction: DismissDirection.endToStart, // Geser ke kiri untuk menghapus
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], // Gradasi warna merah cerah ke merah gelap
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Hapus Tugas',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
      onDismissed: (direction) {
        onDelete();
      },
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Indikator Warna Prioritas di Sisi Paling Kiri Kartu
                Container(
                  width: 6,
                  color: task.priority.color,
                ),
                
                // 2. Konten Utama Kartu Tugas
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                    child: Row(
                      children: [
                        // Tombol Centang Kustom yang Interaktif
                        IconButton(
                          onPressed: onToggle,
                          icon: Icon(
                            task.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: task.isCompleted
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Detail Teks Judul dan Kategori
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: task.isCompleted ? Colors.grey.shade500 : const Color(0xFF1E293B),
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough // Teks dicoret jika sudah selesai
                                      : TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Badge Kategori dengan Ikon Kustom
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          getCategoryIcon(task.category),
                                          size: 11,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.category,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  
                                  // Batas Tanggal Jatuh Tempo (jika ada)
                                  if (task.dueDate != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 11,
                                          color: task.dueDate!.isBefore(DateTime.now()) && !task.isCompleted
                                              ? Colors.red.shade400 // Merah jika melewati batas tanggal (telat)
                                              : Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          formatDate(task.dueDate!),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: task.dueDate!.isBefore(DateTime.now()) && !task.isCompleted
                                                ? Colors.red.shade400
                                                : Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Tombol Aksi Tambahan (Edit & Hapus Cepat)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_note_rounded, color: Colors.grey.shade400, size: 22),
                              onPressed: onEdit,
                              tooltip: 'Edit Tugas',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
