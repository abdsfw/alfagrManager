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
                Builder(
                  builder: (context) {
                    final attendance = attendanceMap[student['id'] as int];
                    final reason = attendance?['absence_reason'] as String?;
                    return Card(
                      child: ListTile(
                        title: Text(student['full_name'] as String? ?? ''),
                        subtitle: Text(
                          attendance == null
                              ? 'لم يتم الإدخال بعد'
                              : [
                                  '${attendance['status']} / ${attendance['points']}',
                                  if (reason != null &&
                                      reason.trim().isNotEmpty)
                                    'السبب: ${reason.trim()}',
                                ].join('\n'),
                        ),
                        onTap: () => _showAttendanceDialog(
                          context,
                          student: student,
                          workDay: workDay,
                          oldValue: attendance,
                        ),
                      ),
                    );
                  },
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
  final pointsController = TextEditingController(
    text: (oldValue?['points'] ?? _defaultPointsForStatus(status)).toString(),
  );
  final reasonController = TextEditingController(
    text: oldValue?['absence_reason'] as String? ?? '',
  );
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
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
                  DropdownMenuItem(
                    value: 'غائب بعذر',
                    child: Text('غائب بعذر'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    status = value ?? 'حاضر';
                    pointsController.text = _defaultPointsForStatus(
                      status,
                    ).toString();
                  });
                },
              ),
              if (status == 'غائب بعذر') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'سبب الغياب'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'اكتب سبب الغياب';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 10),
              TextFormField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'النقاط'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'هذا الحقل مطلوب';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'أدخل رقمًا صحيحًا';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    ),
  );

  if (saved == true && context.mounted) {
    await context.read<AppCubit>().saveAttendance(
      studentId: student['id'] as int,
      workdayId: workDay['id'] as int,
      status: status,
      points: int.parse(pointsController.text.trim()),
      absenceReason: status == 'غائب بعذر'
          ? reasonController.text.trim()
          : null,
    );
  }

  pointsController.dispose();
  reasonController.dispose();
}

int _defaultPointsForStatus(String status) {
  switch (status) {
    case 'غائب':
      return -5;
    case 'غائب بعذر':
      return 0;
    case 'حاضر':
    default:
      return 5;
  }
}
