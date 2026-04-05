import 'package:alfagr_manager/feature/students/presentation/view/page/students_page.dart';
import 'package:alfagr_manager/feature/tests/presentation/view/page/tests_home_page.dart';
import 'package:alfagr_manager/feature/workdays/presentation/view/page/work_days_page.dart';
import 'package:alfagr_manager/core/theme/app_color.dart';
import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isLandscape
            ? _landscapeLayout(context)
            : _portraitLayout(context),
      ),
    );
  }

  Widget _portraitLayout(BuildContext context) {
    return Column(
      children: [
        _logoWidget(),
        const SizedBox(height: 14),
        _titleWidget(),
        const SizedBox(height: 20),
        _studentsCard(context),
        const SizedBox(height: 14),
        _workdaysCard(context),
        const SizedBox(height: 14),
        _testsCard(context),
      ],
    );
  }

  Widget _landscapeLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _logoWidget(size: 95),
              const SizedBox(height: 12),
              _titleWidget(fontSize: 18, verticalPadding: 14),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _studentsCard(context),
              const SizedBox(height: 12),
              _workdaysCard(context),
              const SizedBox(height: 12),
              _testsCard(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logoWidget({double size = 110}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColor.tWhite,
        shape: BoxShape.circle,
        border: Border.all(color: AppColor.sGoldenWheat2, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      ),
    );
  }

  Widget _titleWidget({double fontSize = 20, double verticalPadding = 18}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColor.pForest2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'لوحة التحكم',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColor.tWhite,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _studentsCard(BuildContext context) {
    return _HomeActionCard(
      title: 'الطلاب',
      subtitle: 'إضافة وتعديل وحذف الطلاب وعرض النقاط',
      icon: Icons.groups_rounded,
      color: AppColor.pForest1,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentsPage()),
        );
      },
    );
  }

  Widget _workdaysCard(BuildContext context) {
    return _HomeActionCard(
      title: 'أيام الدوام',
      subtitle: 'إدارة الأيام وتسجيل الحضور والنقاط',
      icon: Icons.calendar_month_rounded,
      color: AppColor.sGoldenWheat3,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WorkDaysPage()),
        );
      },
    );
  }

  Widget _testsCard(BuildContext context) {
    return _HomeActionCard(
      title: 'الاختبارات',
      subtitle: 'إدارة الاختبارات والدرجات',
      icon: Icons.quiz_rounded,
      color: AppColor.pForest2,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TestsHomePage()),
        );
      },
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.tWhite,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.30)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColor.tCharcoal1,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColor.pForest2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
