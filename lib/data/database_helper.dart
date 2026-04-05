import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sql;

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  sql.Database? _database;

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await sql.getDatabasesPath();
    _database = await sql.openDatabase(
      p.join(dbPath, 'halaqa_manager.db'),
      version: 2,
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
        await db.execute('''
          CREATE TABLE test_subjects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
          )
        ''');
        await db.execute('''
          CREATE TABLE test_days (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject_id INTEGER NOT NULL,
            day_name TEXT NOT NULL,
            date TEXT NOT NULL,
            UNIQUE(subject_id, date),
            FOREIGN KEY(subject_id) REFERENCES test_subjects(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE test_scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL,
            test_day_id INTEGER NOT NULL,
            score REAL NOT NULL DEFAULT 0,
            UNIQUE(student_id, test_day_id),
            FOREIGN KEY(student_id) REFERENCES students(id) ON DELETE CASCADE,
            FOREIGN KEY(test_day_id) REFERENCES test_days(id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS test_subjects (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS test_days (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              subject_id INTEGER NOT NULL,
              day_name TEXT NOT NULL,
              date TEXT NOT NULL,
              UNIQUE(subject_id, date),
              FOREIGN KEY(subject_id) REFERENCES test_subjects(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS test_scores (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              student_id INTEGER NOT NULL,
              test_day_id INTEGER NOT NULL,
              score REAL NOT NULL DEFAULT 0,
              UNIQUE(student_id, test_day_id),
              FOREIGN KEY(student_id) REFERENCES students(id) ON DELETE CASCADE,
              FOREIGN KEY(test_day_id) REFERENCES test_days(id) ON DELETE CASCADE
            )
          ''');
        }
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

  Future<List<Map<String, dynamic>>> getTestSubjects() async {
    final db = await database;
    return db.query('test_subjects', orderBy: 'name ASC');
  }

  Future<void> addTestSubject(String name) async {
    final db = await database;
    await db.insert('test_subjects', {'name': name});
  }

  Future<void> updateTestSubject(int id, String name) async {
    final db = await database;
    await db.update('test_subjects', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTestSubject(int id) async {
    final db = await database;
    await db.delete('test_subjects', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTestDays() async {
    final db = await database;
    return db.rawQuery('''
      SELECT td.id, td.subject_id, td.day_name, td.date, ts.name as subject_name
      FROM test_days td
      INNER JOIN test_subjects ts ON ts.id = td.subject_id
      ORDER BY td.date ASC, td.id ASC
    ''');
  }

  Future<void> addTestDay({
    required int subjectId,
    required String dayName,
    required String date,
  }) async {
    final db = await database;
    await db.insert('test_days', {
      'subject_id': subjectId,
      'day_name': dayName,
      'date': date,
    });
  }

  Future<void> updateTestDay({
    required int id,
    required int subjectId,
    required String dayName,
    required String date,
  }) async {
    final db = await database;
    await db.update(
      'test_days',
      {'subject_id': subjectId, 'day_name': dayName, 'date': date},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTestDay(int id) async {
    final db = await database;
    await db.delete('test_days', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTestScores() async {
    final db = await database;
    return db.query('test_scores');
  }

  Future<void> upsertTestScore({
    required int studentId,
    required int testDayId,
    required double score,
  }) async {
    final db = await database;
    await db.insert(
      'test_scores',
      {'student_id': studentId, 'test_day_id': testDayId, 'score': score},
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }
}
