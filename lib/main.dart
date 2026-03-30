import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sql;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ar'),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar')],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      title: 'إدارة الحلقة',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AppGate(),
    );
  }
}

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  sql.Database? _database;

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await sql.getDatabasesPath();
    _database = await sql.openDatabase(
      p.join(dbPath, 'halaqa_manager.db'),
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE teacher (
            id INTEGER PRIMARY KEY CHECK(id = 1),
            teacher_name TEXT NOT NULL,
            halaqa_name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE work_days (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            day_name TEXT NOT NULL,
            date TEXT NOT NULL,
            UNIQUE(day_name, date)
          )
        ''');
        await db.execute('''
          CREATE TABLE attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL,
            workday_id INTEGER NOT NULL,
            status TEXT NOT NULL,
            points INTEGER NOT NULL DEFAULT 0,
            UNIQUE(student_id, workday_id),
            FOREIGN KEY(student_id) REFERENCES students(id) ON DELETE CASCADE,
            FOREIGN KEY(workday_id) REFERENCES work_days(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    return _database!;
  }

  Future<Map<String, dynamic>?> getTeacher() async {
    final db = await database;
    final result = await db.query('teacher', limit: 1);
    return result.isEmpty ? null : result.first;
  }

  Future<void> upsertTeacher(String teacherName, String halaqaName) async {
    final db = await database;
    await db.insert(
      'teacher',
      {'id': 1, 'teacher_name': teacherName, 'halaqa_name': halaqaName},
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    final db = await database;
    return db.query('students', orderBy: 'id ASC');
  }

  Future<void> addStudent(String fullName) async {
    final db = await database;
    await db.insert('students', {'full_name': fullName});
  }

  Future<void> updateStudent(int id, String fullName) async {
    final db = await database;
    await db.update('students', {'full_name': fullName}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteStudent(int id) async {
    final db = await database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getWorkDays() async {
    final db = await database;
    return db.query('work_days', orderBy: 'date ASC, id ASC');
  }

  Future<void> addWorkDay(String dayName, String date) async {
    final db = await database;
    await db.insert('work_days', {'day_name': dayName, 'date': date});
  }

  Future<void> updateWorkDay(int id, String dayName, String date) async {
    final db = await database;
    await db.update(
      'work_days',
      {'day_name': dayName, 'date': date},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteWorkDay(int id) async {
    final db = await database;
    await db.delete('work_days', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAttendance() async {
    final db = await database;
    return db.query('attendance');
  }

  Future<void> upsertAttendance({
    required int studentId,
    required int workdayId,
    required String status,
    required int points,
  }) async {
    final db = await database;
    await db.insert(
      'attendance',
      {
        'student_id': studentId,
        'workday_id': workdayId,
        'status': status,
        'points': points,
      },
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _loading = true;
  bool _hasTeacherData = false;

  @override
  void initState() {
    super.initState();
    _loadTeacher();
  }

  Future<void> _loadTeacher() async {
    final teacher = await DatabaseHelper.instance.getTeacher();
    if (!mounted) return;
    setState(() {
      _hasTeacherData = teacher != null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_hasTeacherData) {
      return TeacherFormPage(onSaved: _loadTeacher);
    }
    return const MainPage();
  }
}

class TeacherFormPage extends StatefulWidget {
  const TeacherFormPage({super.key, required this.onSaved});

  final Future<void> Function() onSaved;

  @override
  State<TeacherFormPage> createState() => _TeacherFormPageState();
}

class _TeacherFormPageState extends State<TeacherFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _teacherController = TextEditingController();
  final _halaqaController = TextEditingController();

  @override
  void dispose() {
    _teacherController.dispose();
    _halaqaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await DatabaseHelper.instance.upsertTeacher(
      _teacherController.text.trim(),
      _halaqaController.text.trim(),
    );
    if (!mounted) return;
    await widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات المعلم')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _teacherController,
                decoration: const InputDecoration(labelText: 'اسم المعلم'),
                validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _halaqaController,
                decoration: const InputDecoration(labelText: 'اسم الحلقة'),
                validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _save, child: const Text('حفظ')),
            ],
          ),
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    final pages = [const TeacherInfoTab(), const HomeTab()];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person), label: 'بيانات المعلم'),
          NavigationDestination(icon: Icon(Icons.home), label: 'الرئيسية'),
        ],
      ),
    );
  }
}

class TeacherInfoTab extends StatefulWidget {
  const TeacherInfoTab({super.key});

  @override
  State<TeacherInfoTab> createState() => _TeacherInfoTabState();
}

class _TeacherInfoTabState extends State<TeacherInfoTab> {
  Future<Map<String, dynamic>?> _teacherFuture = DatabaseHelper.instance.getTeacher();

  Future<void> _refresh() async {
    setState(() {
      _teacherFuture = DatabaseHelper.instance.getTeacher();
    });
  }

  Future<void> _showEditDialog(Map<String, dynamic> teacher) async {
    final nameController = TextEditingController(text: teacher['teacher_name'] as String? ?? '');
    final halaqaController = TextEditingController(text: teacher['halaqa_name'] as String? ?? '');
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل البيانات'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المعلم'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: halaqaController,
                  decoration: const InputDecoration(labelText: 'اسم الحلقة'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context, true);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    if (saved == true) {
      await DatabaseHelper.instance.upsertTeacher(
        nameController.text.trim(),
        halaqaController.text.trim(),
      );
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _teacherFuture,
      builder: (context, snapshot) {
        final teacher = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (teacher == null) {
          return const Center(child: Text('لا توجد بيانات'));
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اسم المعلم: ${teacher['teacher_name']}'),
                  const SizedBox(height: 8),
                  Text('اسم الحلقة: ${teacher['halaqa_name']}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _showEditDialog(teacher),
                    child: const Text('تعديل'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentsPage()));
              },
              child: const Text('الطلاب'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkDaysPage()));
              },
              child: const Text('أيام الدوام'),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  Future<StudentsData> _future = _loadData();

  static Future<StudentsData> _loadData() async {
    final db = DatabaseHelper.instance;
    final students = await db.getStudents();
    final workDays = await db.getWorkDays();
    final attendance = await db.getAttendance();
    return StudentsData(students: students, workDays: workDays, attendance: attendance);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _showStudentDialog({Map<String, dynamic>? student}) async {
    final controller = TextEditingController(text: student?['full_name'] as String? ?? '');
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(student == null ? 'إضافة طالب' : 'تعديل الطالب'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'الاسم الثلاثي للطالب'),
            validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, true);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (saved == true) {
      if (student == null) {
        await DatabaseHelper.instance.addStudent(controller.text.trim());
      } else {
        await DatabaseHelper.instance.updateStudent(student['id'] as int, controller.text.trim());
      }
      await _refresh();
    }
  }

  Future<void> _deleteStudent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الطالب'),
        content: const Text('سيتم حذف الطالب وكل سجلاته، هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteStudent(id);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الطلاب')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentDialog(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<StudentsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null || data.students.isEmpty) {
            return const Center(child: Text('لا يوجد طلاب حتى الآن'));
          }
          return _buildStudentsTable(data);
        },
      ),
    );
  }

  Widget _buildStudentsTable(StudentsData data) {
    final attendanceMap = <String, Map<String, dynamic>>{};
    for (final row in data.attendance) {
      attendanceMap['${row['student_id']}_${row['workday_id']}'] = row;
    }

    const rowHeight = 58.0;
    const dayWidth = 140.0;
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Column(
              children: [
                _headerCell('اسم الطالب', rowHeight),
                for (final student in data.students)
                  _nameCell(student, rowHeight, onEdit: () => _showStudentDialog(student: student), onDelete: () => _deleteStudent(student['id'] as int)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final day in data.workDays)
                        SizedBox(
                          width: dayWidth,
                          height: rowHeight,
                          child: Card(
                            margin: const EdgeInsets.all(2),
                            child: Center(
                              child: Text(
                                '${day['day_name']}\n${day['date']}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (final student in data.students)
                    Row(
                      children: [
                        for (final day in data.workDays)
                          _dayValueCell(
                            attendanceMap['${student['id']}_${day['id']}'],
                            rowHeight,
                            dayWidth,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Column(
              children: [
                _headerCell('مجموع النقاط', rowHeight),
                for (final student in data.students)
                  _totalCell(
                    data.workDays,
                    attendanceMap,
                    student['id'] as int,
                    rowHeight,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double height) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Card(margin: const EdgeInsets.all(2), child: Center(child: Text(title))),
    );
  }

  Widget _nameCell(Map<String, dynamic> student, double height, {required VoidCallback onEdit, required VoidCallback onDelete}) {
    return SizedBox(
      height: height,
      child: Card(
        margin: const EdgeInsets.all(2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  student['full_name'] as String? ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayValueCell(Map<String, dynamic>? value, double height, double width) {
    final status = value?['status'] as String? ?? '-';
    final points = value?['points']?.toString() ?? '-';
    return SizedBox(
      width: width,
      height: height,
      child: Card(
        margin: const EdgeInsets.all(2),
        child: Center(child: Text('$status / $points')),
      ),
    );
  }

  Widget _totalCell(
    List<Map<String, dynamic>> workDays,
    Map<String, Map<String, dynamic>> attendanceMap,
    int studentId,
    double height,
  ) {
    int total = 0;
    for (final day in workDays) {
      final key = '${studentId}_${day['id']}';
      final points = attendanceMap[key]?['points'] as int? ?? 0;
      total += points;
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Card(margin: const EdgeInsets.all(2), child: Center(child: Text(total.toString()))),
    );
  }
}

class StudentsData {
  StudentsData({required this.students, required this.workDays, required this.attendance});

  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> workDays;
  final List<Map<String, dynamic>> attendance;
}

class WorkDaysPage extends StatefulWidget {
  const WorkDaysPage({super.key});

  @override
  State<WorkDaysPage> createState() => _WorkDaysPageState();
}

class _WorkDaysPageState extends State<WorkDaysPage> {
  Future<List<Map<String, dynamic>>> _future = DatabaseHelper.instance.getWorkDays();

  Future<void> _refresh() async {
    setState(() {
      _future = DatabaseHelper.instance.getWorkDays();
    });
  }

  Future<void> _showWorkDayDialog({Map<String, dynamic>? workDay}) async {
    final now = DateTime.now();
    final pickedDate = ValueNotifier<DateTime>(
      workDay == null ? now : _parseDate(workDay['date'] as String),
    );
    final dayController = TextEditingController(
      text: workDay == null ? _arabicWeekday(now) : workDay['day_name'] as String? ?? '',
    );
    final dateController = TextEditingController(
      text: workDay == null ? _dateToText(now) : workDay['date'] as String? ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workDay == null ? 'إضافة يوم دوام' : 'تعديل يوم الدوام'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: dayController,
                    decoration: const InputDecoration(labelText: 'اسم اليوم'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: dateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'التاريخ'),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: pickedDate.value,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('ar'),
                      );
                      if (date != null) {
                        pickedDate.value = date;
                        dateController.text = _dateToText(date);
                        setStateDialog(() {});
                      }
                    },
                    validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, true);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (saved == true) {
      try {
        if (workDay == null) {
          await DatabaseHelper.instance.addWorkDay(dayController.text.trim(), dateController.text.trim());
        } else {
          await DatabaseHelper.instance.updateWorkDay(
            workDay['id'] as int,
            dayController.text.trim(),
            dateController.text.trim(),
          );
        }
        await _refresh();
      } on sql.DatabaseException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن تكرار نفس اليوم مع نفس التاريخ')),
        );
      }
    }
  }

  Future<void> _deleteWorkDay(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف يوم الدوام'),
        content: const Text('سيتم حذف يوم الدوام وكل سجلات الحضور والنقاط المرتبطة به.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteWorkDay(id);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أيام الدوام')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWorkDayDialog(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final workDays = snapshot.data ?? [];
          if (workDays.isEmpty) {
            return const Center(child: Text('لا توجد أيام دوام حتى الآن'));
          }
          return ListView.builder(
            itemCount: workDays.length,
            itemBuilder: (context, index) {
              final day = workDays[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(day['day_name'] as String? ?? ''),
                  subtitle: Text(day['date'] as String? ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkDayDetailsPage(workDay: day),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _showWorkDayDialog(workDay: day);
                      if (value == 'delete') _deleteWorkDay(day['id'] as int);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class WorkDayDetailsPage extends StatefulWidget {
  const WorkDayDetailsPage({super.key, required this.workDay});

  final Map<String, dynamic> workDay;

  @override
  State<WorkDayDetailsPage> createState() => _WorkDayDetailsPageState();
}

class _WorkDayDetailsPageState extends State<WorkDayDetailsPage> {
  late Future<StudentsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<StudentsData> _load() async {
    final students = await DatabaseHelper.instance.getStudents();
    final workDays = [widget.workDay];
    final attendance = await DatabaseHelper.instance.getAttendance();
    return StudentsData(students: students, workDays: workDays, attendance: attendance);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openAttendanceDialog(Map<String, dynamic> student, Map<String, dynamic>? oldValue) async {
    String status = oldValue?['status'] as String? ?? 'حاضر';
    final pointsController = TextEditingController(text: (oldValue?['points'] ?? 0).toString());
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(student['full_name'] as String? ?? ''),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'الحالة'),
                items: const [
                  DropdownMenuItem(value: 'حاضر', child: Text('حاضر')),
                  DropdownMenuItem(value: 'غائب', child: Text('غائب')),
                ],
                onChanged: (value) => status = value ?? 'حاضر',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'النقاط'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
                  if (int.tryParse(value.trim()) == null) return 'أدخل رقمًا صحيحًا';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, true);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await DatabaseHelper.instance.upsertAttendance(
        studentId: student['id'] as int,
        workdayId: widget.workDay['id'] as int,
        status: status,
        points: int.parse(pointsController.text.trim()),
      );
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.workDay['day_name']} - ${widget.workDay['date']}'),
      ),
      body: FutureBuilder<StudentsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null || data.students.isEmpty) {
            return const Center(child: Text('لا يوجد طلاب لإدخال الحضور'));
          }
          final attendanceMap = <int, Map<String, dynamic>>{};
          for (final row in data.attendance) {
            if (row['workday_id'] == widget.workDay['id']) {
              attendanceMap[row['student_id'] as int] = row;
            }
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final student in data.students)
                Card(
                  child: ListTile(
                    title: Text(student['full_name'] as String? ?? ''),
                    subtitle: Text(
                      attendanceMap[student['id']] == null
                          ? 'لم يتم الإدخال بعد'
                          : '${attendanceMap[student['id']]!['status']} / ${attendanceMap[student['id']]!['points']}',
                    ),
                    onTap: () => _openAttendanceDialog(student, attendanceMap[student['id'] as int]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _arabicWeekday(DateTime date) {
  const names = {
    1: 'الاثنين',
    2: 'الثلاثاء',
    3: 'الأربعاء',
    4: 'الخميس',
    5: 'الجمعة',
    6: 'السبت',
    7: 'الأحد',
  };
  return names[date.weekday] ?? 'يوم';
}

String _dateToText(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

DateTime _parseDate(String text) {
  final parts = text.split('/');
  if (parts.length != 3) return DateTime.now();
  final day = int.tryParse(parts[0]) ?? 1;
  final month = int.tryParse(parts[1]) ?? 1;
  final year = int.tryParse(parts[2]) ?? DateTime.now().year;
  return DateTime(year, month, day);
}
