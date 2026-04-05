class AppState {
  const AppState({
    this.isLoading = false,
    this.currentTabIndex = 1,
    this.teacher,
    this.students = const [],
    this.workDays = const [],
    this.attendance = const [],
    this.testSubjects = const [],
    this.testDays = const [],
    this.testScores = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final int currentTabIndex;
  final Map<String, dynamic>? teacher;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> workDays;
  final List<Map<String, dynamic>> attendance;
  final List<Map<String, dynamic>> testSubjects;
  final List<Map<String, dynamic>> testDays;
  final List<Map<String, dynamic>> testScores;
  final String? errorMessage;

  AppState copyWith({
    bool? isLoading,
    int? currentTabIndex,
    Map<String, dynamic>? teacher,
    bool clearTeacher = false,
    List<Map<String, dynamic>>? students,
    List<Map<String, dynamic>>? workDays,
    List<Map<String, dynamic>>? attendance,
    List<Map<String, dynamic>>? testSubjects,
    List<Map<String, dynamic>>? testDays,
    List<Map<String, dynamic>>? testScores,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      teacher: clearTeacher ? null : (teacher ?? this.teacher),
      students: students ?? this.students,
      workDays: workDays ?? this.workDays,
      attendance: attendance ?? this.attendance,
      testSubjects: testSubjects ?? this.testSubjects,
      testDays: testDays ?? this.testDays,
      testScores: testScores ?? this.testScores,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
