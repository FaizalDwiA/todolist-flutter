import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// [TaskPriority] mendefinisikan tingkat urgensi suatu tugas.
/// Setiap prioritas memiliki warna representasi tersendiri.
enum TaskPriority { low, medium, high }

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

/// [TodoListScreen] adalah halaman utama aplikasi yang bertipe [StatefulWidget].
/// Kita menggunakan StatefulWidget karena aplikasi perlu memperbarui UI secara dinamis
/// saat pengguna menambah, mencentang, menyaring, atau menghapus tugas.
class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  // --- STATE VARIABLES ---
  List<TodoTask> _tasks = []; // Daftar utama semua tugas
  List<TodoTask> _filteredTasks = []; // Daftar tugas yang telah disaring (filter/pencarian)
  bool _isLoading = true; // Status loading saat membaca data dari SharedPreferences

  // Variabel untuk Pencarian & Filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "Semua";
  String _selectedStatus = "Semua"; // Pilihan: "Semua", "Aktif" (Belum Selesai), "Selesai"

  // Kategori default yang tersedia di aplikasi
  final List<String> _categories = ["Semua", "Kerja", "Pribadi", "Belanja", "Kesehatan", "Lainnya"];

  @override
  void initState() {
    super.initState();
    _loadTasksFromStorage(); // Muat data tugas saat halaman pertama kali dibuat
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- PERSISTENCE METHODS (Fungsi Penyimpanan Lokal) ---

  /// Memuat daftar tugas dari SharedPreferences.
  /// Jika data kosong, kita akan mengisinya dengan beberapa tugas bawaan (seed data) agar UI tidak kosong.
  Future<void> _loadTasksFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tasksJson = prefs.getString('todo_tasks');

      if (tasksJson != null) {
        final List<dynamic> decodedList = jsonDecode(tasksJson);
        setState(() {
          _tasks = decodedList.map((item) => TodoTask.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        // Seed data jika aplikasi pertama kali dibuka
        setState(() {
          _tasks = [
            TodoTask(
              id: '1',
              title: 'Selesaikan laporan proyek Flutter',
              category: 'Kerja',
              priority: TaskPriority.high,
              dueDate: DateTime.now().add(const Duration(days: 1)),
              isCompleted: false,
            ),
            TodoTask(
              id: '2',
              title: 'Membeli bahan makanan mingguan',
              category: 'Belanja',
              priority: TaskPriority.medium,
              dueDate: DateTime.now(),
              isCompleted: true,
            ),
            TodoTask(
              id: '3',
              title: 'Olahraga sore (Jogging 30 menit)',
              category: 'Kesehatan',
              priority: TaskPriority.low,
              dueDate: DateTime.now(),
              isCompleted: false,
            ),
          ];
          _isLoading = false;
        });
        _saveTasksToStorage(); // Langsung simpan seed data ke storage
      }
      _applyFilters(); // Terapkan pencarian dan penyaringan
    } catch (e) {
      // Fallback jika terjadi error pada SharedPreferences (misal masalah platform/symlink di Windows)
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error loading tasks: $e");
    }
  }

  /// Menyimpan daftar tugas saat ini ke SharedPreferences dalam format JSON String.
  Future<void> _saveTasksToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedList = jsonEncode(_tasks.map((task) => task.toJson()).toList());
      await prefs.setString('todo_tasks', encodedList);
    } catch (e) {
      debugPrint("Error saving tasks: $e");
    }
  }

  // --- CORE LOGIC METHODS (CRUD & Filter) ---

  /// Menerapkan filter kategori, status tugas, dan query pencarian secara dinamis.
  void _applyFilters() {
    setState(() {
      _filteredTasks = _tasks.where((task) {
        // 1. Filter berdasarkan Pencarian Judul
        final matchesSearch = task.title.toLowerCase().contains(_searchQuery.toLowerCase());

        // 2. Filter berdasarkan Kategori
        final matchesCategory = _selectedCategory == "Semua" || task.category == _selectedCategory;

        // 3. Filter berdasarkan Status Penyelesaian
        bool matchesStatus = true;
        if (_selectedStatus == "Aktif") {
          matchesStatus = !task.isCompleted;
        } else if (_selectedStatus == "Selesai") {
          matchesStatus = task.isCompleted;
        }

        return matchesSearch && matchesCategory && matchesStatus;
      }).toList();

      // Urutkan tugas: Tugas yang belum selesai di atas, lalu urutkan berdasarkan prioritas (Tinggi -> Rendah)
      _filteredTasks.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.priority.index.compareTo(a.priority.index);
      });
    });
  }

  /// Menambahkan tugas baru ke dalam daftar.
  void _addNewTask(TodoTask task) {
    setState(() {
      _tasks.add(task);
    });
    _saveTasksToStorage();
    _applyFilters();
    
    // Tampilkan pemberitahuan kecil (SnackBar) di bagian bawah layar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tugas "${task.title}" berhasil ditambahkan!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  /// Mengubah status penyelesaian tugas (Centang / Belum Centang).
  void _toggleTaskCompletion(String id) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task.id == id);
      if (taskIndex != -1) {
        _tasks[taskIndex].isCompleted = !_tasks[taskIndex].isCompleted;
      }
    });
    _saveTasksToStorage();
    _applyFilters();
  }

  /// Mengedit tugas yang sudah ada.
  void _editTask(String id, String newTitle, String newCategory, TaskPriority newPriority, DateTime? newDueDate) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task.id == id);
      if (taskIndex != -1) {
        _tasks[taskIndex].title = newTitle;
        _tasks[taskIndex].category = newCategory;
        _tasks[taskIndex].priority = newPriority;
        _tasks[taskIndex].dueDate = newDueDate;
      }
    });
    _saveTasksToStorage();
    _applyFilters();
  }

  /// Menghapus tugas dari daftar.
  void _deleteTask(String id, String taskTitle) {
    TodoTask? removedTask;
    int? removedIndex;

    setState(() {
      removedIndex = _tasks.indexWhere((task) => task.id == id);
      if (removedIndex != -1) {
        removedTask = _tasks.removeAt(removedIndex!);
      }
    });
    _saveTasksToStorage();
    _applyFilters();

    // Berikan opsi 'Urungkan' (Undo) jika pengguna tidak sengaja menghapus tugas
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tugas "$taskTitle" dihapus'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'BATALKAN',
          textColor: Colors.amber,
          onPressed: () {
            if (removedTask != null && removedIndex != null) {
              setState(() {
                _tasks.insert(removedIndex!, removedTask!);
              });
              _saveTasksToStorage();
              _applyFilters();
            }
          },
        ),
      ),
    );
  }

  // --- UI HELPER METHODS ---

  /// Mengembalikan warna penanda berdasarkan tingkat prioritas tugas.
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFEF4444); // Merah Terang
      case TaskPriority.medium:
        return const Color(0xFFF59E0B); // Amber/Oranye
      case TaskPriority.low:
        return const Color(0xFF10B981); // Emerald/Hijau
    }
  }

  /// Mengembalikan ikon representatif untuk setiap kategori tugas.
  IconData _getCategoryIcon(String category) {
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
  String _formatDate(DateTime date) {
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

  // --- WIDGET BUILD PARTS (Komponen Antarmuka) ---

  @override
  Widget build(BuildContext context) {
    // Menghitung statistik progres tugas saat ini
    final int totalCount = _tasks.length;
    final int completedCount = _tasks.where((t) => t.isCompleted).length;
    final double completionProgress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Tampilkan loading spinner jika sedang membaca storage
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 1. BAGIAN HEADER GRADASI & STATISTIK (DASHBOARD)
                    _buildHeaderSection(completedCount, totalCount, completionProgress),

                    // 2. KOTAK PENCARIAN & FILTER KATEGORI
                    _buildSearchAndFilters(),

                    // 3. TAB FILTER STATUS TUGAS (Semua, Aktif, Selesai)
                    _buildStatusTabs(completedCount, totalCount),

                    // 4. DAFTAR TUGAS UTAMA (LIST VIEW)
                    _filteredTasks.isEmpty
                        ? _buildEmptyState() // Tampilkan gambar/ikon kosong jika tidak ada tugas yang cocok
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = _filteredTasks[index];
                              return _buildTaskItemCard(task);
                            },
                          ),
                  ],
                ),
              ),
            ),
      // Tombol Terapung (Floating Action Button) untuk menambah tugas baru
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskBottomSheet(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'Tugas Baru',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  /// Membuat bagian Header Premium dengan gradasi warna ungu/indigo dan ringkasan statistik.
  Widget _buildHeaderSection(int completed, int total, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            const Color(0xFF4F46E5), // Indigo tua
            const Color(0xFF7C3AED), // Ungu medium
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Halo, Selamat Datang! 👋',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rencana Hari Ini',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // Tanggal hari ini di header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(DateTime.now()),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // KARTU STATISTIK PROGRES JALUR PENYELESAIAN TUGAS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Penyelesaian Tugas',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      total > 0 ? '$completed dari $total selesai' : 'Belum ada tugas',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress Bar Linear yang Mulus
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0
                          ? Theme.of(context).colorScheme.secondary // Jika 100%, gunakan warna Teal segar
                          : const Color(0xFFFCD34D), // Jika sedang berjalan, gunakan warna Amber hangat
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  progress == 1.0
                      ? 'Luar biasa! Semua tugas terselesaikan. 🎉'
                      : total > 0
                          ? 'Tetap semangat! Selesaikan sisa tugas Anda.'
                          : 'Mulai dengan menambahkan tugas baru di bawah.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Membuat kolom pencarian dan filter kategori horizontal
  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        children: [
          // A. Kolom Pencarian dengan Shadow Lembut
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Cari tugas Anda...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                          _applyFilters();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // B. Chips Kategori Horisontal (Scrollable)
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final categoryName = _categories[index];
                final isSelected = _selectedCategory == categoryName;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      categoryName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategory = categoryName;
                      });
                      _applyFilters();
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : Colors.grey.shade200,
                      ),
                    ),
                    elevation: isSelected ? 2 : 0,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Membuat tab filter status tugas (Semua, Aktif, Selesai)
  Widget _buildStatusTabs(int completed, int total) {
    final activeCount = total - completed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildStatusButton("Semua", total),
            _buildStatusButton("Aktif", activeCount),
            _buildStatusButton("Selesai", completed),
          ],
        ),
      ),
    );
  }

  /// Tombol pilihan status individual di dalam baris tab status
  Widget _buildStatusButton(String statusName, int count) {
    final isSelected = _selectedStatus == statusName;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = statusName;
          });
          _applyFilters();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                statusName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menampilkan status kosong jika tidak ada data tugas
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.check_circle_outline_rounded,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'Tugas tidak ditemukan' : 'Belum ada tugas',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Coba ubah kata kunci pencarian Anda atau bersihkan kolom teks.'
                : 'Semua rencana Anda bersih! Tambahkan tugas dengan mengetuk tombol di bawah.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
          ),
        ],
      ),
    );
  }

  /// Membuat Kartu Item Tugas Individual dengan Swipe-to-Delete (Menggunakan widget [Dismissible])
  Widget _buildTaskItemCard(TodoTask task) {
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
        _deleteTask(task.id, task.title);
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
                  color: _getPriorityColor(task.priority),
                ),
                
                // 2. Konten Utama Kartu Tugas
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                    child: Row(
                      children: [
                        // Tombol Centang Kustom yang Interaktif
                        IconButton(
                          onPressed: () => _toggleTaskCompletion(task.id),
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
                                          _getCategoryIcon(task.category),
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
                                          _formatDate(task.dueDate!),
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
                              onPressed: () => _showEditTaskBottomSheet(context, task),
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

  // --- FORM BOTTOM SHEETS (Panel Input Tambah & Edit Tugas) ---

  /// Membuka panel geser (BottomSheet) untuk menambahkan tugas baru.
  void _showAddTaskBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    String tempCategory = "Kerja";
    TaskPriority tempPriority = TaskPriority.medium;
    DateTime? tempDueDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Membuat BottomSheet bisa digeser lebih tinggi saat keyboard muncul
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return _buildBottomSheetForm(
              context: context,
              title: "Buat Tugas Baru",
              titleController: titleController,
              selectedCategory: tempCategory,
              selectedPriority: tempPriority,
              dueDate: tempDueDate,
              onCategoryChanged: (cat) => setModalState(() => tempCategory = cat),
              onPriorityChanged: (prio) => setModalState(() => tempPriority = prio),
              onDatePicked: (date) => setModalState(() => tempDueDate = date),
              onSave: () {
                if (titleController.text.trim().isEmpty) return;
                
                final newTask = TodoTask(
                  id: DateTime.now().millisecondsSinceEpoch.toString(), // ID unik menggunakan timestamp
                  title: titleController.text.trim(),
                  category: tempCategory,
                  priority: tempPriority,
                  dueDate: tempDueDate,
                );
                
                _addNewTask(newTask);
                Navigator.pop(context); // Tutup BottomSheet
              },
            );
          },
        );
      },
    );
  }

  /// Membuka panel geser (BottomSheet) untuk mengedit tugas yang sudah ada.
  void _showEditTaskBottomSheet(BuildContext context, TodoTask existingTask) {
    final titleController = TextEditingController(text: existingTask.title);
    String tempCategory = existingTask.category;
    TaskPriority tempPriority = existingTask.priority;
    DateTime? tempDueDate = existingTask.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return _buildBottomSheetForm(
              context: context,
              title: "Edit Rencana Tugas",
              titleController: titleController,
              selectedCategory: tempCategory,
              selectedPriority: tempPriority,
              dueDate: tempDueDate,
              onCategoryChanged: (cat) => setModalState(() => tempCategory = cat),
              onPriorityChanged: (prio) => setModalState(() => tempPriority = prio),
              onDatePicked: (date) => setModalState(() => tempDueDate = date),
              onSave: () {
                if (titleController.text.trim().isEmpty) return;
                
                _editTask(
                  existingTask.id,
                  titleController.text.trim(),
                  tempCategory,
                  tempPriority,
                  tempDueDate,
                );
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tugas berhasil diperbarui!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Widget Template Form Bottom Sheet yang digeneralisasi untuk Tambah dan Edit.
  Widget _buildBottomSheetForm({
    required BuildContext context,
    required String title,
    required TextEditingController titleController,
    required String selectedCategory,
    required TaskPriority selectedPriority,
    required DateTime? dueDate,
    required Function(String) onCategoryChanged,
    required Function(TaskPriority) onPriorityChanged,
    required Function(DateTime?) onDatePicked,
    required VoidCallback onSave,
  }) {
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
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
            ),
            const SizedBox(height: 16),
            
            // 1. INPUT TEXT: Judul Tugas
            TextField(
              controller: titleController,
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
                children: _categories.where((cat) => cat != "Semua").map((categoryName) {
                  final isSelected = selectedCategory == categoryName;
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
                        if (selected) onCategoryChanged(categoryName);
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

                final isSelected = selectedPriority == priority;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => onPriorityChanged(priority),
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
                  initialDate: dueDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                onDatePicked(pickedDate);
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
                          dueDate == null ? 'Pilih Tanggal Jatuh Tempo' : _formatDate(dueDate),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: dueDate == null ? Colors.grey.shade600 : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    if (dueDate != null)
                      GestureDetector(
                        onTap: () => onDatePicked(null),
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
                    onPressed: onSave,
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
