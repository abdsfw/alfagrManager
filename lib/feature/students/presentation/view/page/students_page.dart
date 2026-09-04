import 'dart:io';
import 'package:alfagr_manager/cubit/app_cubit.dart';
import 'package:alfagr_manager/cubit/app_state.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isExportingPdf = false;
  bool _isExportingExcel = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('الطلاب')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          if (state.students.isEmpty) {
            return const Center(child: Text('لا يوجد طلاب حتى الآن'));
          }
          final filteredStudents = state.students.where((student) {
            final name = (student['full_name'] as String? ?? '').toLowerCase();
            return name.contains(_searchQuery.toLowerCase());
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.trim()),
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم الطالب',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isExportingPdf
                            ? null
                            : () => _exportPdf(state, filteredStudents),
                        icon: _isExportingPdf
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf),
                        label: Text(
                          _isExportingPdf ? 'جاري إنشاء PDF...' : 'تصدير PDF',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isExportingExcel
                            ? null
                            : () => _exportExcel(state),
                        icon: _isExportingExcel
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.table_chart),
                        label: Text(
                          _isExportingExcel
                              ? 'جاري إنشاء Excel...'
                              : 'تصدير Excel',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredStudents.isEmpty
                    ? const Center(child: Text('لا توجد نتائج مطابقة'))
                    : _buildStudentsTable(context, state, filteredStudents),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportPdf(
    AppState state,
    List<Map<String, dynamic>> students,
  ) async {
    if (_isExportingPdf) return;
    setState(() => _isExportingPdf = true);
    try {
      final teacherName = state.teacher?['teacher_name'] as String? ?? '-';
      final halaqaName = state.teacher?['halaqa_name'] as String? ?? '-';
      final sortedWorkDays = [...state.workDays]
        ..sort(
          (a, b) => _parseDate(
            a['date'] as String? ?? '',
          ).compareTo(_parseDate(b['date'] as String? ?? '')),
        );

      final attendanceMap = <String, Map<String, dynamic>>{};
      for (final row in state.attendance) {
        attendanceMap['${row['student_id']}_${row['workday_id']}'] = row;
      }

      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final day in sortedWorkDays) {
        final date = _parseDate(day['date'] as String? ?? '');
        final key = '${date.year}-${date.month}';
        grouped.putIfAbsent(key, () => []).add(day);
      }

      final keys = grouped.keys.toList()
        ..sort((a, b) {
          final aa = a.split('-');
          final bb = b.split('-');
          final aDate = DateTime(int.parse(aa[0]), int.parse(aa[1]));
          final bDate = DateTime(int.parse(bb[0]), int.parse(bb[1]));
          return aDate.compareTo(bDate);
        });

      final monthPairs = <List<String>>[];
      for (int i = 0; i < keys.length; i += 2) {
        monthPairs.add(
          keys.sublist(i, i + 2 > keys.length ? keys.length : i + 2),
        );
      }

      final fontData = await rootBundle.load(
        'assets/fonts/cairo/Cairo-Regular.ttf',
      );
      final boldFontData = await rootBundle.load(
        'assets/fonts/cairo/Cairo-Bold.ttf',
      );
      final ttf = pw.Font.ttf(fontData);
      final boldTtf = pw.Font.ttf(boldFontData);

      final pdf = pw.Document();
      if (monthPairs.isEmpty) {
        monthPairs.add([]);
      }

      for (final pair in monthPairs) {
        final daysForPage = <Map<String, dynamic>>[];
        for (final key in pair) {
          daysForPage.addAll(grouped[key] ?? []);
        }

        final headers = <String>['اسم الطالب'];
        for (final day in daysForPage) {
          headers.add('${day['day_name']}\n${day['date']}');
        }
        headers.add('مجموع النقاط');

        final dataRows = <List<String>>[];
        for (final student in students) {
          final row = <String>[student['full_name'] as String? ?? ''];
          int total = 0;
          for (final day in daysForPage) {
            final value = attendanceMap['${student['id']}_${day['id']}'];
            final status = value?['status'] as String? ?? '-';
            final points = value?['points'] as int? ?? 0;
            total += points;
            row.add('$status / $points');
          }
          row.add(total.toString());
          dataRows.add(row);
        }

        pdf.addPage(
          pw.MultiPage(
            theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
            pageFormat: PdfPageFormat.a4.landscape,
            textDirection: pw.TextDirection.rtl,
            build: (context) => [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'كشف الطلاب',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('اسم الأستاذ: $teacherName'),
                    pw.Text('اسم الحلقة: $halaqaName'),
                    pw.Text(
                      'الفترة: ${pair.isEmpty ? 'بدون بيانات' : pair.join(' + ')}',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              if (headers.length > 1)
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  data: dataRows,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellAlignment: pw.Alignment.center,
                )
              else
                pw.Text('لا توجد أيام دوام لعرضها'),
            ],
          ),
        );
      }

      final outputDir = await getTemporaryDirectory();
      final path =
          '${outputDir.path}/كشف_الطلاب_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      final openResult = await OpenFilex.open(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            openResult.type == ResultType.done
                ? 'تم فتح ملف PDF، يمكنك الآن حفظه أو مشاركته'
                : 'تعذر فتح ملف PDF تلقائيًا',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء إنشاء PDF: $e')));
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _exportExcel(AppState state) async {
    if (_isExportingExcel) return;
    setState(() => _isExportingExcel = true);
    try {
      final teacherName = state.teacher?['teacher_name'] as String? ?? '-';
      final halaqaName = state.teacher?['halaqa_name'] as String? ?? '-';
      final sortedWorkDays = [...state.workDays]
        ..sort(
          (a, b) => _parseDate(
            a['date'] as String? ?? '',
          ).compareTo(_parseDate(b['date'] as String? ?? '')),
        );

      final attendanceMap = <String, Map<String, dynamic>>{};
      for (final row in state.attendance) {
        attendanceMap['${row['student_id']}_${row['workday_id']}'] = row;
      }

      final excel = ex.Excel.createExcel();
      final sheet = excel['الطلاب'];
      sheet.appendRow([
        ex.TextCellValue('اسم الأستاذ'),
        ex.TextCellValue(teacherName),
        ex.TextCellValue('اسم الحلقة'),
        ex.TextCellValue(halaqaName),
      ]);
      sheet.appendRow([ex.TextCellValue('')]);

      final header = <ex.CellValue>[ex.TextCellValue('اسم الطالب')];
      for (final day in sortedWorkDays) {
        header.add(ex.TextCellValue('${day['day_name']} ${day['date']}'));
      }
      header.add(ex.TextCellValue('مجموع النقاط'));
      sheet.appendRow(header);

      for (final student in state.students) {
        final row = <ex.CellValue>[
          ex.TextCellValue(student['full_name'] as String? ?? ''),
        ];
        int total = 0;
        for (final day in sortedWorkDays) {
          final value = attendanceMap['${student['id']}_${day['id']}'];
          final status = value?['status'] as String? ?? '-';
          final points = value?['points'] as int? ?? 0;
          total += points;
          row.add(ex.TextCellValue('$status / $points'));
        }
        row.add(ex.IntCellValue(total));
        sheet.appendRow(row);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('تعذر إنشاء ملف Excel');

      final outputDir = await getTemporaryDirectory();
      final path =
          '${outputDir.path}/كشف_الطلاب_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      final openResult = await OpenFilex.open(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            openResult.type == ResultType.done
                ? 'تم فتح ملف Excel، يمكنك الآن حفظه أو مشاركته'
                : 'تعذر فتح ملف Excel تلقائيًا',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء إنشاء Excel: $e')));
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  Widget _buildStudentsTable(
    BuildContext context,
    AppState state,
    List<Map<String, dynamic>> students,
  ) {
    final sortedWorkDays = [...state.workDays]
      ..sort((a, b) {
        final dateA = _parseDate(a['date'] as String? ?? '');
        final dateB = _parseDate(b['date'] as String? ?? '');
        final compareDate = dateB.compareTo(dateA);
        if (compareDate != 0) return compareDate;
        final idA = a['id'] as int? ?? 0;
        final idB = b['id'] as int? ?? 0;
        return idB.compareTo(idA);
      });

    final attendanceMap = <String, Map<String, dynamic>>{};
    for (final row in state.attendance) {
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
                for (final student in students)
                  _nameCell(
                    student,
                    rowHeight,
                    onEdit: () => _showStudentDialog(context, student: student),
                    onDelete: () =>
                        _deleteStudent(context, student['id'] as int),
                  ),
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
                      for (final day in sortedWorkDays)
                        SizedBox(
                          width: dayWidth,
                          height: rowHeight,
                          child: Card(
                            margin: const EdgeInsets.all(2),
                            color: _monthColumnColor(
                              _extractMonthFromDate(
                                day['date'] as String? ?? '',
                              ),
                            ).withValues(alpha: 0.32),
                            child: Center(
                              child: Text(
                                '${day['day_name']}\n${day['date']}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (final student in students)
                    Row(
                      children: [
                        for (final day in sortedWorkDays)
                          _dayValueCell(
                            attendanceMap['${student['id']}_${day['id']}'],
                            rowHeight,
                            dayWidth,
                            _monthColumnColor(
                              _extractMonthFromDate(
                                day['date'] as String? ?? '',
                              ),
                            ).withValues(alpha: 0.18),
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
                for (final student in students)
                  _totalCell(
                    sortedWorkDays,
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
}

Future<void> _showStudentDialog(
  BuildContext context, {
  Map<String, dynamic>? student,
}) async {
  final controller = TextEditingController(
    text: student?['full_name'] as String? ?? '',
  );
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<bool>(
    context: context,
    useSafeArea: true,
    builder: (dialogContext) {
      final bottomInset = MediaQuery.of(dialogContext).viewInsets.bottom;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: Theme.of(dialogContext).cardColor,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          student == null ? 'إضافة طالب' : 'تعديل الطالب',
                          style: Theme.of(dialogContext).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'الاسم الثلاثي للطالب',
                          ),
                          textInputAction: TextInputAction.done,
                          autofocus: true,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'هذا الحقل مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('إلغاء'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) return;
                                Navigator.pop(dialogContext, true);
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

  if (saved != true || !context.mounted) return;
  if (student == null) {
    await context.read<AppCubit>().addStudent(controller.text.trim());
  } else {
    await context.read<AppCubit>().updateStudent(
      student['id'] as int,
      controller.text.trim(),
    );
  }
}

Future<void> _deleteStudent(BuildContext context, int id) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('حذف الطالب'),
      content: const Text('سيتم حذف الطالب وكل سجلاته، هل أنت متأكد؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('حذف'),
        ),
      ],
    ),
  );
  if (confirm == true && context.mounted) {
    await context.read<AppCubit>().deleteStudent(id);
  }
}

Widget _headerCell(String title, double height) {
  return SizedBox(
    height: height,
    width: double.infinity,
    child: Card(
      margin: const EdgeInsets.all(2),
      child: Center(child: Text(title)),
    ),
  );
}

Widget _nameCell(
  Map<String, dynamic> student,
  double height, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return SizedBox(
    // height: height,
    child: Card(
      margin: const EdgeInsets.all(2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                student['full_name'] as String? ?? '',
                // overflow: TextOverflow.ellipsis,
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

Widget _dayValueCell(
  Map<String, dynamic>? value,
  double height,
  double width,
  Color backgroundColor,
) {
  final status = value?['status'] as String? ?? '-';
  final points = value?['points']?.toString() ?? '-';
  return SizedBox(
    width: width,
    height: height,
    child: Card(
      margin: const EdgeInsets.all(2),
      color: backgroundColor,
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
    child: Card(
      margin: const EdgeInsets.all(2),
      child: Center(child: Text(total.toString())),
    ),
  );
}

int _extractMonthFromDate(String text) {
  final parts = text.split('/');
  if (parts.length != 3) return 1;
  return int.tryParse(parts[1]) ?? 1;
}

Color _monthColumnColor(int month) {
  const monthColors = [
    Color(0xFFB7D8FF),
    Color(0xFFC6E6C3),
    Color(0xFFFFE2B8),
    Color(0xFFFFD1CC),
    Color(0xFFE2D4FF),
    Color(0xFFFFE7A8),
  ];
  final safeMonth = month < 1 ? 1 : month;
  return monthColors[(safeMonth - 1) % monthColors.length];
}

DateTime _parseDate(String text) {
  final parts = text.split('/');
  if (parts.length != 3) return DateTime(2000);
  final day = int.tryParse(parts[0]) ?? 1;
  final month = int.tryParse(parts[1]) ?? 1;
  final year = int.tryParse(parts[2]) ?? 2000;
  return DateTime(year, month, day);
}
