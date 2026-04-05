import 'package:alfagr_manager/cubit/app_cubit.dart';
import 'package:alfagr_manager/cubit/app_state.dart';
import 'package:alfagr_manager/feature/home/presentation/view/page/home_tab.dart';
import 'package:alfagr_manager/feature/teacher/presentation/view/page/teacher_info_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final pages = [const TeacherInfoTab(), const HomeTab()];
        return Scaffold(
          body: pages[state.currentTabIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.currentTabIndex,
            onDestinationSelected: (value) => context.read<AppCubit>().changeTab(value),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.person), label: 'بيانات المعلم'),
              NavigationDestination(icon: Icon(Icons.home), label: 'الرئيسية'),
            ],
          ),
        );
      },
    );
  }
}
