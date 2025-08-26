import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../domain/entities/habit_progress.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/theme/colors.dart';

class CalendarWidget extends StatefulWidget {
  final String habitId;
  final List<HabitProgress> progressData;
  final Function(DateTime) onDaySelected;

  const CalendarWidget({
    super.key,
    required this.habitId,
    required this.progressData,
    required this.onDaySelected,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar<HabitProgress>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          calendarFormat: CalendarFormat.month,
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: TextStyle(color: Colors.grey[600]),
            holidayTextStyle: TextStyle(color: Colors.grey[600]),
            defaultTextStyle: const TextStyle(fontSize: 14),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            todayTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 1,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: Theme.of(context).primaryColor,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: Theme.of(context).primaryColor,
            ),
            titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ) ?? const TextStyle(),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final progress = _getProgressForDay(day);
              if (progress != null && progress.isCompleted) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }
              return null;
            },
            markerBuilder: (context, day, events) {
              final progress = _getProgressForDay(day);
              if (progress != null && progress.isCompleted) {
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            widget.onDaySelected(selectedDay);
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const SizedBox(height: 16),
        _buildLegend(),
        if (_selectedDay != null) ...[
          const SizedBox(height: 16),
          _buildSelectedDayInfo(),
        ],
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem(AppColors.success, 'Completed'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.grey, 'Not completed'),
        const Spacer(),
        Text(
          '${_getCompletionRate().toStringAsFixed(1)}% completion rate',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSelectedDayInfo() {
    final progress = _getProgressForDay(_selectedDay!);
    final isToday = DateUtilsHelper.isToday(_selectedDay!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateUtilsHelper.formatDate(_selectedDay!),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (progress != null) ...[
              Row(
                children: [
                  Icon(
                    progress.isCompleted ? Icons.check_circle : Icons.cancel,
                    color: progress.isCompleted ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    progress.isCompleted
                        ? 'Completed (${progress.completed}/${progress.target})'
                        : 'Not completed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (progress.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  'Note: ${progress.notes}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ] else ...[
              Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No data for this day',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<HabitProgress> _getEventsForDay(DateTime day) {
    return widget.progressData.where((progress) {
      return DateUtilsHelper.isSameDay(progress.date, day);
    }).toList();
  }

  HabitProgress? _getProgressForDay(DateTime day) {
    try {
      return widget.progressData.firstWhere((progress) {
        return DateUtilsHelper.isSameDay(progress.date, day);
      });
    } catch (e) {
      return null;
    }
  }

  double _getCompletionRate() {
    if (widget.progressData.isEmpty) return 0.0;

    final completedDays = widget.progressData.where((p) => p.isCompleted).length;
    return (completedDays / widget.progressData.length) * 100;
  }
}
