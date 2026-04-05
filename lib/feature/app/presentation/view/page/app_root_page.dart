import 'package:alfagr_manager/cubit/app_cubit.dart';
import 'package:alfagr_manager/cubit/app_state.dart';
import 'package:alfagr_manager/feature/home/presentation/view/page/main_shell_page.dart';
import 'package:alfagr_manager/feature/teacher/presentation/view/page/teacher_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppRootPage extends StatelessWidget {
  const AppRootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
          context.read<AppCubit>().clearError();
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (state.teacher == null) {
          return const TeacherSetupPage();
        }
        return const MainShellPage();
      },
    );
  }
}
