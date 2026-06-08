import 'package:flutter/material.dart';
import 'package:todolist1/models/todo_task.dart';
import 'package:todolist1/utils/todo_helpers.dart';

class TodoFormBottomSheet extends StatefulWidget {
  final String title;
  final TodoTask? existingTask;
  final Function(String title, String category, TaskPriority priority, DateTime? dueDate) onSave;

  const TodoFormBottomSheet({
    super.key,
    required this.title,
    this.existingTask,
    required this.onSave,
  });

  @override
  State<TodoFormBottomSheet> createState() => _TodoFormBottomSheetState();
}

class _TodoFormBottomSheetState extends State<TodoFormBottomSheet> {
  late final TextEditingController _titleController;
  late String _selectedCategory;
  late TaskPriority _selectedPriority;
  late DateTime? _dueDate;

  final List<String> _categories = ["Kerja", "Pribadi", "Belanja", "Kesehatan", "Lainnya"];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTask?.title ?? '');
    _selectedCategory = widget.existingTask?.category ?? 'Kerja';
    _selectedPriority = widget.existingTask?.priority ?? TaskPriority.medium;
    _dueDate = widget.existingTask?.dueDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Media Query digunakan untuk menghitung jarak padding bawah agar terhindar dari tumpang tindih keyboard virtual.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indikator Garis Geser Atas Bottom Sheet
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Judul Form
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
            ),
            const SizedBox(height: 16),
            
            // 1. INPUT TEXT: Judul Tugas
            TextField(
              controller: _titleController,
              autofocus: true, // Fokus langsung ke input teks saat form dibuka
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nama Tugas Rencana',
                hintText: 'Misal: Belajar Ujian Flutter',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.playlist_add_check_rounded),
              ),
            ),
            const SizedBox(height: 20),
            
            // 2. PILIHAN CHIP: Kategori Tugas
            const Text(
              'Kategori',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((categoryName) {
                  final isSelected = _selectedCategory == categoryName;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = categoryName;
                          });
                        }
                      },
                      selectedColor: Theme.of(context).colorScheme.primary,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            
            // 3. PILIHAN PRIORITAS (Tinggi, Sedang, Rendah)
            const Text(
              'Prioritas Tugas',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            Row(
              children: TaskPriority.values.map((priority) {
                String label;
                Color chipColor;
                switch (priority) {
                  case TaskPriority.high:
                    label = "Tinggi";
                    chipColor = const Color(0xFFEF4444);
                    break;
                  case TaskPriority.medium:
                    label = "Sedang";
                    chipColor = const Color(0xFFF59E0B);
                    break;
                  case TaskPriority.low:
                    label = "Rendah";
                    chipColor = const Color(0xFF10B981);
                    break;
                }

                final isSelected = _selectedPriority == priority;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPriority = priority;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? chipColor : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            
            // 4. PEMILIH TANGGAL (Due Date Picker)
            const Text(
              'Batas Waktu Pengerjaan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (pickedDate != null) {
                  setState(() {
                    _dueDate = pickedDate;
                  });
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_note_rounded, color: Colors.indigo, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _dueDate == null ? 'Pilih Tanggal Jatuh Tempo' : formatDate(_dueDate!),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _dueDate == null ? Colors.grey.shade600 : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _dueDate = null;
                          });
                        },
                        child: Icon(Icons.cancel_rounded, color: Colors.grey.shade400, size: 18),
                      )
                    else
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // 5. TOMBOL AKSI FORM (Batal & Simpan)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_titleController.text.trim().isEmpty) return;
                      widget.onSave(
                        _titleController.text.trim(),
                        _selectedCategory,
                        _selectedPriority,
                        _dueDate,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 1,
                    ),
                    child: const Text('Simpan Tugas', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
