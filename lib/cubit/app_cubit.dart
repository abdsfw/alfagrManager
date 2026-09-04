import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart' as sql;
import '../data/database_helper.dart';
import 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(const AppState(isLoading: true));

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> loadInitialData() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    await _reloadData();
  }

  Future<void> _reloadData() async {
    final teacher = await _db.getTeacher();
    final students = await _db.getStudents();
    final workDays = await _db.getWorkDays();
    final attendance = await _db.getAttendance();
    final testSubjects = await _db.getTestSubjects();
    final testDays = await _db.getTestDays();
    final testScores = await _db.getTestScores();
    emit(
      state.copyWith(
        isLoading: false,
        teacher: teacher,
        students: students,
        workDays: workDays,
        attendance: attendance,
        testSubjects: testSubjects,
        testDays: testDays,
        testScores: testScores,
        clearError: true,
      ),
    );
  }

  void changeTab(int index) {
    emit(state.copyWith(currentTabIndex: index));
  }

  Future<void> saveTeacher(String teacherName, String halaqaName) async {
    await _db.upsertTeacher(teacherName, halaqaName);
    await _reloadData();
  }

  Future<void> addStudent(String fullName) async {
    await _db.addStudent(fullName);
    await _reloadData();
  }

  Future<void> updateStudent(int id, String fullName) async {
    await _db.updateStudent(id, fullName);
    await _reloadData();
  }

  Future<void> deleteStudent(int id) async {
    await _db.deleteStudent(id);
    await _reloadData();
  }

  Future<bool> addWorkDay(String dayName, String date) async {
    try {
      await _db.addWorkDay(dayName, date);
      await _reloadData();
      return true;
    } on sql.DatabaseException {
      emit(
        state.copyWith(errorMessage: 'لا يمكن تكرار نفس اليوم مع نفس التاريخ'),
      );
      return false;
    }
  }

  Future<bool> updateWorkDay(int id, String dayName, String date) async {
    try {
      await _db.updateWorkDay(id, dayName, date);
      await _reloadData();
      return true;
    } on sql.DatabaseException {
      emit(
        state.copyWith(errorMessage: 'لا يمكن تكرار نفس اليوم مع نفس التاريخ'),
      );
      return false;
    }
  }

  Future<void> deleteWorkDay(int id) async {
    await _db.deleteWorkDay(id);
    await _reloadData();
  }

  Future<void> saveAttendance({
    required int studentId,
    required int workdayId,
    required String status,
    required int points,
    String? absenceReason,
  }) async {
    await _db.upsertAttendance(
      studentId: studentId,
      workdayId: workdayId,
      status: status,
      points: points,
      absenceReason: absenceReason,
    );
    await _reloadData();
  }

  Future<bool> addTestSubject(String name) async {
    try {
      await _db.addTestSubject(name);
      await _reloadData();
      return true;
    } on sql.DatabaseException {
      emit(state.copyWith(errorMessage: 'المادة موجودة مسبقًا'));
      return false;
    }
  }

  Future<bool> updateTestSubject(int id, String name) async {
    try {
      await _db.updateTestSubject(id, name);
      await _reloadData();
      return true;
    } on sql.DatabaseException {
      emit(state.copyWith(errorMessage: 'لا يمكن تكرار نفس اسم المادة'));
      return false;
    }
  }

  Future<void> deleteTestSubject(int id) async {
    await _db.deleteTestSubject(id);
    await _reloadData();
  }

  Future<bool> addTestDay({
    required int subjectId,
    required String dayName,
    required String date,
  }) async {
    try {
      await _db.addTestDay(subjectId: subjectId, dayName: dayName, date: date);
      await _reloadData();
      return true;
    } on sql.DatabaseException {
      emit(
        state.copyWith(errorMessage: 'يوجد اختبار لنفس المادة في نفس التاريخ'),
      );
      return false;
    }
  }

  Future<bool> updateTestDay({
    required int id,
    required int subjectId,
    required String dayName,
    required String date,
  }) async {
    try {
      await _db.updateTestDay(
        id: id,
        subjectId: subjectId,
        dayName: dayName,
        date: date,
      );
      await _reloadData();
      return true;
    } on sql.DatabaseException {
      emit(
        state.copyWith(errorMessage: 'يوجد اختبار لنفس المادة في نفس التاريخ'),
      );
      return false;
    }
  }

  Future<void> deleteTestDay(int id) async {
    await _db.deleteTestDay(id);
    await _reloadData();
  }

  Future<void> saveTestScore({
    required int studentId,
    required int testDayId,
    required double score,
  }) async {
    await _db.upsertTestScore(
      studentId: studentId,
      testDayId: testDayId,
      score: score,
    );
    await _reloadData();
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
