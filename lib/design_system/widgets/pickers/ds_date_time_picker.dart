import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../inputs/ds_text_field.dart';

/// Date picker field wrapper.
class DsDatePicker extends StatefulWidget {
  const DsDatePicker({
    super.key,
    required this.onDateSelected,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.label,
    this.hint,
  });

  final ValueChanged<DateTime> onDateSelected;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? label;
  final String? hint;

  @override
  State<DsDatePicker> createState() => _DsDatePickerState();
}

class _DsDatePickerState extends State<DsDatePicker> {
  final _controller = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? widget.initialDate ?? now,
      firstDate: widget.firstDate ?? DateTime(2000),
      lastDate: widget.lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  secondary: AppColors.secondary,
                ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.xlAll,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _controller.text = DateFormat.yMMMd().format(date);
      });
      widget.onDateSelected(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DsTextField(
      controller: _controller,
      label: widget.label ?? 'Date',
      hint: widget.hint ?? 'Select date',
      prefixIcon: Icons.calendar_today_outlined,
      readOnly: true,
      suffixIcon: IconButton(
        icon: Icon(Icons.date_range_rounded),
        onPressed: _pickDate,
      ),
      onSubmitted: (_) => _pickDate(),
    );
  }
}

/// Time picker field wrapper.
class DsTimePicker extends StatefulWidget {
  const DsTimePicker({
    super.key,
    required this.onTimeSelected,
    this.initialTime,
    this.label,
    this.hint,
  });

  final ValueChanged<TimeOfDay> onTimeSelected;
  final TimeOfDay? initialTime;
  final String? label;
  final String? hint;

  @override
  State<DsTimePicker> createState() => _DsTimePickerState();
}

class _DsTimePickerState extends State<DsTimePicker> {
  final _controller = TextEditingController();
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? widget.initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  secondary: AppColors.secondary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
        _controller.text = time.format(context);
      });
      widget.onTimeSelected(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DsTextField(
      controller: _controller,
      label: widget.label ?? 'Time',
      hint: widget.hint ?? 'Select time',
      prefixIcon: Icons.access_time_rounded,
      readOnly: true,
      suffixIcon: IconButton(
        icon: Icon(Icons.schedule_rounded),
        onPressed: _pickTime,
      ),
    );
  }
}
