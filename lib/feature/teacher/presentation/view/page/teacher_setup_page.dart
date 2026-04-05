import 'package:alfagr_manager/cubit/app_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherSetupPage extends StatefulWidget {
  const TeacherSetupPage({super.key});

  @override
  State<TeacherSetupPage> createState() => _TeacherSetupPageState();
}

class _TeacherSetupPageState extends State<TeacherSetupPage> {
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
    await context.read<AppCubit>().saveTeacher(
      _teacherController.text.trim(),
      _halaqaController.text.trim(),
    );
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
