import 'dart:io';
import 'package:alfagr_manager/cubit/app_cubit.dart';
import 'package:alfagr_manager/cubit/app_state.dart';
import 'package:alfagr_manager/core/theme/app_color.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TestsHomePage extends StatelessWidget {
  const TestsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الاختبارات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _btn(
              context,
              title: 'مواد الاختبار',
              subtitle: 'إضافة المواد وتعديلها وحذفها',
              icon: Icons.menu_book_rounded,
              color: AppColor.pForest1,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestSubjectsPage()),
              ),
            ),
            const SizedBox(height: 12),
            _btn(
              context,
              title: 'أيام الاختبار',
              subtitle: 'تحديد اليوم والمادة لكل اختبار',
              icon: Icons.event_note_rounded,
              color: AppColor.sGoldenWheat3,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestDaysPage()),
              ),
            ),
            const SizedBox(height: 12),
            _btn(
              context,
              title: 'عرض نتائج الاختبارات',
              subtitle: 'جدول الدرجات مع التصدير إلى PDF وExcel',
              icon: Icons.table_chart_rounded,
              color: AppColor.pForest2,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestsResultsPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColor.tWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColor.tCharcoal2,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColor.tCharcoal1,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColor.pForest2),
            ],
          ),
        ),
      ),
    );
  }
}

class TestSubjectsPage extends StatelessWidget {
  const TestSubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مواد الاختبار')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubjectDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          if (state.testSubjects.isEmpty) return const Center(child: Text('لا توجد مواد حتى الآن'));
          return ListView.builder(
            itemCount: state.testSubjects.length,
            itemBuilder: (_, i) {
              final item = state.testSubjects[i];
              return Card(
                child: ListTile(
                  title: Text(item['name'] as String? ?? ''),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') _showSubjectDialog(context, subject: item);
                      if (v == 'delete') context.read<AppCubit>().deleteTestSubject(item['id'] as int);
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

Future<void> _showSubjectDialog(BuildContext context, {Map<String, dynamic>? subject}) async {
  final c = TextEditingController(text: subject?['name'] as String? ?? '');
  final key = GlobalKey<FormState>();
  final ok = await showDialog<bool>(
    context: context,
    useSafeArea: true,
    builder: (d) {
      final bottomInset = MediaQuery.of(d).viewInsets.bottom;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: Theme.of(d).cardColor,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: key,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subject == null ? 'إضافة مادة' : 'تعديل المادة',
                          style: Theme.of(d).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: c,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(labelText: 'اسم المادة'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(d, false),
                              child: const Text('إلغاء'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                if (!key.currentState!.validate()) return;
                                Navigator.pop(d, true);
                              },
                              child: const Text('حفظ'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  if (ok != true || !context.mounted) return;
  if (subject == null) {
    await context.read<AppCubit>().addTestSubject(c.text.trim());
  } else {
    await context.read<AppCubit>().updateTestSubject(subject['id'] as int, c.text.trim());
  }
}

class TestDaysPage extends StatelessWidget {
  const TestDaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أيام الاختبار')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTestDayDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          if (state.testDays.isEmpty) return const Center(child: Text('لا توجد أيام اختبار حتى الآن'));
          final days = [...state.testDays]..sort((a, b) => _parseDate(b['date'] as String).compareTo(_parseDate(a['date'] as String)));
          return ListView.builder(
            itemCount: days.length,
            itemBuilder: (_, i) {
              final day = days[i];
              return Card(
                child: ListTile(
                  title: Text('${day['subject_name']} - ${day['day_name']}'),
                  subtitle: Text(day['date'] as String? ?? ''),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TestDayEntryPage(testDay: day)),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _showTestDayDialog(context, day: day);
                      if (v == 'delete') context.read<AppCubit>().deleteTestDay(day['id'] as int);
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

Future<void> _showTestDayDialog(BuildContext context, {Map<String, dynamic>? day}) async {
  final state = context.read<AppCubit>().state;
  if (state.testSubjects.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف مادة اختبار أولاً')));
    return;
  }
  int subjectId = day?['subject_id'] as int? ?? state.testSubjects.first['id'] as int;
  final now = DateTime.now();
  DateTime picked = day == null ? now : _parseDate(day['date'] as String);
  final dateC = TextEditingController(text: _dateToText(picked));
  final key = GlobalKey<FormState>();

  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (d, setD) => AlertDialog(
        title: Text(day == null ? 'إضافة يوم اختبار' : 'تعديل يوم الاختبار'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: subjectId,
                decoration: const InputDecoration(labelText: 'المادة'),
                items: [
                  for (final s in state.testSubjects)
                    DropdownMenuItem<int>(
                      value: s['id'] as int,
                      child: Text(s['name'] as String),
                    ),
                ],
                onChanged: (v) => subjectId = v ?? subjectId,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: dateC,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'التاريخ'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: d,
                    initialDate: picked,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    locale: const Locale('ar'),
                  );
                  if (date != null) {
                    picked = date;
                    dateC.text = _dateToText(date);
                    setD(() {});
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حفظ')),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  final dayName = _arabicWeekday(picked);
  if (day == null) {
    await context.read<AppCubit>().addTestDay(subjectId: subjectId, dayName: dayName, date: _dateToText(picked));
  } else {
    await context.read<AppCubit>().updateTestDay(
      id: day['id'] as int,
      subjectId: subjectId,
      dayName: dayName,
      date: _dateToText(picked),
    );
  }
}

class TestDayEntryPage extends StatelessWidget {
  const TestDayEntryPage({super.key, required this.testDay});
  final Map<String, dynamic> testDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${testDay['subject_name']} - ${testDay['date']}')),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          if (state.students.isEmpty) return const Center(child: Text('لا يوجد طلاب'));
          final map = <int, Map<String, dynamic>>{};
          for (final s in state.testScores) {
            if (s['test_day_id'] == testDay['id']) {
              map[s['student_id'] as int] = s;
            }
          }
          return ListView(
            children: [
              for (final st in state.students)
                Card(
                  child: ListTile(
                    title: Text(st['full_name'] as String? ?? ''),
                    subtitle: Text(map[st['id']] == null ? 'لا توجد علامة' : 'العلامة: ${map[st['id']]!['score']}'),
                    onTap: () => _showScoreDialog(context, student: st, testDay: testDay, old: map[st['id'] as int]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _showScoreDialog(
  BuildContext context, {
  required Map<String, dynamic> student,
  required Map<String, dynamic> testDay,
  Map<String, dynamic>? old,
}) async {
  final c = TextEditingController(text: (old?['score'] ?? '').toString());
  final key = GlobalKey<FormState>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(student['full_name'] as String? ?? ''),
      content: Form(
        key: key,
        child: TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'العلامة'),
          validator: (v) => double.tryParse((v ?? '').trim()) == null ? 'أدخل رقمًا صحيحًا' : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            if (!key.currentState!.validate()) return;
            Navigator.pop(d, true);
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await context.read<AppCubit>().saveTestScore(
    studentId: student['id'] as int,
    testDayId: testDay['id'] as int,
    score: double.parse(c.text.trim()),
  );
}

class TestsResultsPage extends StatefulWidget {
  const TestsResultsPage({super.key});

  @override
  State<TestsResultsPage> createState() => _TestsResultsPageState();
}

class _TestsResultsPageState extends State<TestsResultsPage> {
  bool _pdfLoading = false;
  bool _excelLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نتائج الاختبارات')),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          if (state.students.isEmpty || state.testDays.isEmpty) {
            return const Center(child: Text('لا توجد بيانات كافية للعرض'));
          }
          final sortedDays = [...state.testDays]
            ..sort((a, b) => _parseDate(b['date'] as String? ?? '').compareTo(_parseDate(a['date'] as String? ?? '')));
          final scoreMap = <String, Map<String, dynamic>>{};
          for (final row in state.testScores) {
            scoreMap['${row['student_id']}_${row['test_day_id']}'] = row;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _pdfLoading ? null : () => _exportTestsPdf(state, sortedDays, scoreMap),
                        icon: _pdfLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.picture_as_pdf),
                        label: Text(_pdfLoading ? 'جاري إنشاء PDF...' : 'تصدير PDF'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _excelLoading ? null : () => _exportTestsExcel(state, sortedDays, scoreMap),
                        icon: _excelLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.table_chart),
                        label: Text(_excelLoading ? 'جاري إنشاء Excel...' : 'تصدير Excel'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150,
                        child: Column(
                          children: [
                            _headerCell('اسم الطالب'),
                            for (final st in state.students) _nameCell(st['full_name'] as String? ?? ''),
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
                                  for (final d in sortedDays)
                                    SizedBox(
                                      width: 150,
                                      child: _headerCell('${d['subject_name']}\n${d['date']}'),
                                    ),
                                ],
                              ),
                              for (final st in state.students)
                                Row(
                                  children: [
                                    for (final d in sortedDays)
                                      SizedBox(
                                        width: 150,
                                        child: _valueCell(
                                          (scoreMap['${st['id']}_${d['id']}']?['score'] ?? '-').toString(),
                                        ),
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
            ],
          );
        },
      ),
    );
  }

  Widget _headerCell(String t) => Card(margin: const EdgeInsets.all(2), child: SizedBox(height: 58, child: Center(child: Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)))));
  Widget _nameCell(String t) => Card(margin: const EdgeInsets.all(2), child: SizedBox(height: 52, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Align(alignment: Alignment.centerRight, child: Text(t, overflow: TextOverflow.ellipsis)))));
  Widget _valueCell(String t) => Card(margin: const EdgeInsets.all(2), child: SizedBox(height: 52, child: Center(child: Text(t))));

  Future<void> _exportTestsPdf(AppState state, List<Map<String, dynamic>> days, Map<String, Map<String, dynamic>> scoreMap) async {
    setState(() => _pdfLoading = true);
    try {
      final fontData = await rootBundle.load('assets/fonts/cairo/Cairo-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/cairo/Cairo-Bold.ttf');
      final pdf = pw.Document();
      final ttf = pw.Font.ttf(fontData);
      final bttf = pw.Font.ttf(boldData);

      final headers = <String>['اسم الطالب', ...days.map((d) => '${d['subject_name']}\n${d['date']}')];
      final rows = <List<String>>[];
      for (final st in state.students) {
        rows.add([
          st['full_name'] as String? ?? '',
          ...days.map((d) => (scoreMap['${st['id']}_${d['id']}']?['score'] ?? '-').toString()),
        ]);
      }
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: ttf, bold: bttf),
          build: (_) => [
            pw.Text('نتائج الاختبارات', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.Text('اسم الأستاذ: ${state.teacher?['teacher_name'] ?? '-'}'),
            pw.Text('اسم الحلقة: ${state.teacher?['halaqa_name'] ?? '-'}'),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(headers: headers, data: rows, headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/نتائج_الاختبارات_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(path).writeAsBytes(await pdf.save());
      final result = await OpenFilex.open(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.type == ResultType.done ? 'تم فتح ملف PDF' : 'تعذر فتح ملف PDF')));
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  Future<void> _exportTestsExcel(AppState state, List<Map<String, dynamic>> days, Map<String, Map<String, dynamic>> scoreMap) async {
    setState(() => _excelLoading = true);
    try {
      final excel = ex.Excel.createExcel();
      final sheet = excel['النتائج'];
      sheet.appendRow([
        ex.TextCellValue('اسم الأستاذ'),
        ex.TextCellValue((state.teacher?['teacher_name'] ?? '-').toString()),
        ex.TextCellValue('اسم الحلقة'),
        ex.TextCellValue((state.teacher?['halaqa_name'] ?? '-').toString()),
      ]);
      sheet.appendRow([ex.TextCellValue('')]);
      sheet.appendRow([
        ex.TextCellValue('اسم الطالب'),
        ...days.map((d) => ex.TextCellValue('${d['subject_name']} ${d['date']}')),
      ]);
      for (final st in state.students) {
        sheet.appendRow([
          ex.TextCellValue(st['full_name'] as String? ?? ''),
          ...days.map((d) => ex.TextCellValue((scoreMap['${st['id']}_${d['id']}']?['score'] ?? '-').toString())),
        ]);
      }
      final bytes = excel.encode();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/نتائج_الاختبارات_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      await File(path).writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.type == ResultType.done ? 'تم فتح ملف Excel' : 'تعذر فتح ملف Excel')));
    } finally {
      if (mounted) setState(() => _excelLoading = false);
    }
  }
}

String _arabicWeekday(DateTime date) {
  const names = {1: 'الاثنين', 2: 'الثلاثاء', 3: 'الأربعاء', 4: 'الخميس', 5: 'الجمعة', 6: 'السبت', 7: 'الأحد'};
  return names[date.weekday] ?? 'يوم';
}

String _dateToText(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

DateTime _parseDate(String text) {
  final p = text.split('/');
  if (p.length != 3) return DateTime(2000);
  return DateTime(int.tryParse(p[2]) ?? 2000, int.tryParse(p[1]) ?? 1, int.tryParse(p[0]) ?? 1);
}
