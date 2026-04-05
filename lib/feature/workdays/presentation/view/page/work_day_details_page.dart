import 'package:alfagr_manager/cubit/app_cubit.dart';
import 'package:alfagr_manager/cubit/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkDayDetailsPage extends StatelessWidget {
  const WorkDayDetailsPage({super.key, required this.workDay});

  final Map<String, dynamic> workDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${workDay['day_name']} - ${workDay['date']}'),
      ),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          if (state.students.isEmpty) {
            return const Center(child: Text('لا يوجد طلاب لإدخال الحضور'));
          }

          final attendanceMap = <int, Map<String, dynamic>>{};
          for (final row in state.attendance) {
            if (row['workday_id'] == workDay['id']) {
              attendanceMap[row['student_id'] as int] = row;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final student in state.students)
                Card(
                  child: ListTile(
                    title: Text(student['full_name'] as String? ?? ''),
                    subtitle: Text(
                      attendanceMap[student['id']] == null
                          ? 'لم يتم الإدخال بعد'
                          : '${attendanceMap[student['id']]!['status']} / ${attendanceMap[student['id']]!['points']}',
                    ),
                    onTap: () => _showAttendanceDialog(
                      context,
                      student: student,
                      workDay: workDay,
                      oldValue: attendanceMap[student['id'] as int],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _showAttendanceDialog(
  BuildContext context, {
  required Map<String, dynamic> student,
  required Map<String, dynamic> workDay,
  Map<String, dynamic>? oldValue,
}) async {
  String status = oldValue?['status'] as String? ?? 'حاضر';
  final pointsController = TextEditingController(text: (oldValue?['points'] ?? 0).toString());
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
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
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(dialogContext, true);
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );

  if (saved == true && context.mounted) {
    await context.read<AppCubit>().saveAttendance(
      studentId: student['id'] as int,
      workdayId: workDay['id'] as int,
      status: status,
      points: int.parse(pointsController.text.trim()),
    );
  }
}
