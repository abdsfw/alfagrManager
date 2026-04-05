import 'package:alfagr_manager/cubit/app_cubit.dart';
import 'package:alfagr_manager/cubit/app_state.dart';
import 'package:alfagr_manager/feature/workdays/presentation/view/page/work_day_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkDaysPage extends StatefulWidget {
  const WorkDaysPage({super.key});

  @override
  State<WorkDaysPage> createState() => _WorkDaysPageState();
}

class _WorkDaysPageState extends State<WorkDaysPage> {
  String _selectedDayFilter = 'الكل';
  String _selectedYearFilter = 'الكل';
  String _selectedMonthFilter = 'الكل';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أيام الدوام')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWorkDayDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          if (state.workDays.isEmpty) {
            return const Center(child: Text('لا توجد أيام دوام حتى الآن'));
          }
          final dayFilterOptions = <String>{
            'الكل',
            ...state.workDays.map((day) => day['day_name'] as String? ?? '').where((e) => e.isNotEmpty),
          }.toList();
          final yearFilterOptions = <String>{
            'الكل',
            ...state.workDays.map((day) {
              final date = _parseDate(day['date'] as String? ?? '');
              return date.year.toString();
            }),
          }.toList()
            ..sort((a, b) {
              if (a == 'الكل') return -1;
              if (b == 'الكل') return 1;
              return a.compareTo(b);
            });
          final monthFilterOptions = <String>{
            'الكل',
            ...state.workDays.map((day) {
              final date = _parseDate(day['date'] as String? ?? '');
              return date.month.toString();
            }),
          }.toList()
            ..sort((a, b) {
              if (a == 'الكل') return -1;
              if (b == 'الكل') return 1;
              return int.parse(a).compareTo(int.parse(b));
            });
          if (!dayFilterOptions.contains(_selectedDayFilter)) {
            _selectedDayFilter = 'الكل';
          }
          if (!yearFilterOptions.contains(_selectedYearFilter)) {
            _selectedYearFilter = 'الكل';
          }
          if (!monthFilterOptions.contains(_selectedMonthFilter)) {
            _selectedMonthFilter = 'الكل';
          }
          final filteredDays = state.workDays.where((day) {
            final parsedDate = _parseDate(day['date'] as String? ?? '');
            final matchesYear = _selectedYearFilter == 'الكل' || parsedDate.year.toString() == _selectedYearFilter;
            final matchesMonth = _selectedMonthFilter == 'الكل' || parsedDate.month.toString() == _selectedMonthFilter;
            final matchesDay = _selectedDayFilter == 'الكل' || (day['day_name'] as String? ?? '') == _selectedDayFilter;
            return matchesYear && matchesMonth && matchesDay;
          }).toList()
            ..sort((a, b) {
              final dateA = _parseDate(a['date'] as String? ?? '');
              final dateB = _parseDate(b['date'] as String? ?? '');
              final compareDate = dateB.compareTo(dateA);
              if (compareDate != 0) return compareDate;
              final idA = a['id'] as int? ?? 0;
              final idB = b['id'] as int? ?? 0;
              return idB.compareTo(idA);
            });
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedYearFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'السنة',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: [
                          for (final item in yearFilterOptions)
                            DropdownMenuItem<String>(
                              value: item,
                              child: Text(item, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedYearFilter = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedMonthFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'الشهر',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: [
                          for (final item in monthFilterOptions)
                            DropdownMenuItem<String>(
                              value: item,
                              child: Text(item, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedMonthFilter = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedDayFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'اليوم',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: [
                          for (final item in dayFilterOptions)
                            DropdownMenuItem<String>(
                              value: item,
                              child: Text(item, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedDayFilter = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredDays.isEmpty
                    ? const Center(child: Text('لا توجد نتائج مطابقة'))
                    : ListView.builder(
                        itemCount: filteredDays.length,
                        itemBuilder: (context, index) {
                          final day = filteredDays[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(day['day_name'] as String? ?? ''),
                              subtitle: Text(day['date'] as String? ?? ''),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => WorkDayDetailsPage(workDay: day)),
                                );
                              },
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') _showWorkDayDialog(context, workDay: day);
                                  if (value == 'delete') _deleteWorkDay(context, day['id'] as int);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _showWorkDayDialog(BuildContext context, {Map<String, dynamic>? workDay}) async {
  final now = DateTime.now();
  final pickedDate = ValueNotifier<DateTime>(
    workDay == null ? now : _parseDate(workDay['date'] as String),
  );
  final dateController = TextEditingController(
    text: workDay == null ? _dateToText(now) : workDay['date'] as String? ?? '',
  );
  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(workDay == null ? 'إضافة يوم دوام' : 'تعديل يوم الدوام'),
      content: StatefulBuilder(
        builder: (innerContext, setStateDialog) => Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'التاريخ'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: innerContext,
                    initialDate: pickedDate.value,
                    firstDate: DateTime(2000),
                    lastDate: now,
                    locale: const Locale('ar'),
                  );
                  if (date != null) {
                    pickedDate.value = date;
                    dateController.text = _dateToText(date);
                    setStateDialog(() {});
                  }
                },
                validator: (value) => value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null,
              ),
            ],
          ),
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

  if (saved != true || !context.mounted) return;
  final selectedDate = pickedDate.value;
  final today = DateTime(now.year, now.month, now.day);
  final pickedOnlyDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  if (pickedOnlyDate.isAfter(today)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لا يمكن إضافة يوم دوام بتاريخ مستقبلي')),
    );
    return;
  }
  final dayName = _arabicWeekday(selectedDate);
  final dateText = _dateToText(selectedDate);
  if (workDay == null) {
    await context.read<AppCubit>().addWorkDay(dayName, dateText);
  } else {
    await context.read<AppCubit>().updateWorkDay(
      workDay['id'] as int,
      dayName,
      dateText,
    );
  }
}

Future<void> _deleteWorkDay(BuildContext context, int id) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('حذف يوم الدوام'),
      content: const Text('سيتم حذف يوم الدوام وكل سجلات الحضور والنقاط المرتبطة به.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حذف')),
      ],
    ),
  );
  if (confirm == true && context.mounted) {
    await context.read<AppCubit>().deleteWorkDay(id);
  }
}

String _arabicWeekday(DateTime date) {
  const names = {
    1: 'الاثنين',
    2: 'الثلاثاء',
    3: 'الأربعاء',
    4: 'الخميس',
    5: 'الجمعة',
    6: 'السبت',
    7: 'الأحد',
  };
  return names[date.weekday] ?? 'يوم';
}

String _dateToText(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

DateTime _parseDate(String text) {
  final parts = text.split('/');
  if (parts.length != 3) return DateTime.now();
  final day = int.tryParse(parts[0]) ?? 1;
  final month = int.tryParse(parts[1]) ?? 1;
  final year = int.tryParse(parts[2]) ?? DateTime.now().year;
  return DateTime(year, month, day);
}
