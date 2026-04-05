import 'package:alfagr_manager/cubit/app_cubit.dart';
import 'package:alfagr_manager/cubit/app_state.dart';
import 'package:alfagr_manager/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherInfoTab extends StatelessWidget {
  const TeacherInfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final teacher = state.teacher;
        if (teacher == null) return const Center(child: Text('لا توجد بيانات'));

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                          color: AppColor.pForest1,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: AppColor.tWhite, size: 42),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'بيانات الأستاذ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColor.pForest3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _infoTile(
                        title: 'اسم المعلم',
                        value: teacher['teacher_name'] as String? ?? '',
                      ),
                      const SizedBox(height: 10),
                      _infoTile(
                        title: 'اسم الحلقة',
                        value: teacher['halaqa_name'] as String? ?? '',
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showEditTeacherDialog(context, teacher),
                          icon: const Icon(Icons.edit),
                          label: const Text('تعديل البيانات'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _infoTile({required String title, required String value}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColor.sGoldenWheat1,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColor.sGoldenWheat2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColor.pForest2,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColor.tCharcoal2,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}

Future<void> _showEditTeacherDialog(BuildContext context, Map<String, dynamic> teacher) async {
  final nameController = TextEditingController(text: teacher['teacher_name'] as String? ?? '');
  final halaqaController = TextEditingController(text: teacher['halaqa_name'] as String? ?? '');
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
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
    await context.read<AppCubit>().saveTeacher(
      nameController.text.trim(),
      halaqaController.text.trim(),
    );
  }
}
