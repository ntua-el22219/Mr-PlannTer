import 'package:flutter/material.dart';
import 'package:app_mr_plannter/data/recurrence_helper.dart';

class RecurrencePickerDialog extends StatefulWidget {
  final String initialRule;

  const RecurrencePickerDialog({Key? key, this.initialRule = ''})
    : super(key: key);

  @override
  State<RecurrencePickerDialog> createState() => _RecurrencePickerDialogState();
}

class _RecurrencePickerDialogState extends State<RecurrencePickerDialog> {
  late String _frequency;
  String _customBaseFrequency = 'DAILY';
  late int _interval;
  late List<String> _selectedDays;
  late String _endType;
  late String _endDate;
  late String _endCount;

  late TextEditingController _intervalController;

  final List<String> _frequencyOptions = [
    'NONE',
    'DAILY',
    'WEEKLY',
    'BIWEEKLY',
    'MONTHLY',
    'YEARLY',
    'CUSTOM',
  ];

  final Map<String, String> _frequencyLabels = {
    'NONE': 'Does not repeat',
    'DAILY': 'Daily',
    'WEEKLY': 'Weekly',
    'BIWEEKLY': 'Every 2 weeks',
    'MONTHLY': 'Monthly',
    'YEARLY': 'Yearly',
    'CUSTOM': 'Custom',
  };

  final List<String> _weekDays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
  final Map<String, String> _weekDayLabels = {
    'MO': 'Monday',
    'TU': 'Tuesday',
    'WE': 'Wednesday',
    'TH': 'Thursday',
    'FR': 'Friday',
    'SA': 'Saturday',
    'SU': 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    final parsed = RecurrenceHelper.parseRule(widget.initialRule);
    _frequency = parsed['frequency'];
    _interval = parsed['interval'];
    _selectedDays = List.from(parsed['byDay']);
    _endType = parsed['endType'];
    _endDate = parsed['endDate'];
    _endCount = parsed['endCount'];
    _intervalController = TextEditingController(text: _interval.toString());

    // If editing a custom rule, try to infer the base frequency
    if (_frequency == 'CUSTOM') {
      // Try to get the real freq from the RRULE string
      final freq = parsed['customBaseFrequency'] ?? 'DAILY';
      _customBaseFrequency = freq;
    } else if (_frequency == 'DAILY' || _frequency == 'WEEKLY' || _frequency == 'MONTHLY' || _frequency == 'YEARLY') {
      _customBaseFrequency = _frequency;
    }
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate.isNotEmpty
          ? DateTime.parse(_endDate)
          : DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _endDate = date.toIso8601String().split('T')[0]; // Format as YYYY-MM-DD
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFE082),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Recurrence',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Frequency dropdown
                Text(
                  'Repeat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  ),
                  child: DropdownButton<String>(
                    value: _frequency,
                    isExpanded: true,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: _frequencyOptions.map((freq) {
                      return DropdownMenuItem(
                        value: freq,
                        child: Text(_frequencyLabels[freq] ?? freq),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _frequency = value ?? 'NONE';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Interval for custom repeat only
                if (_frequency == 'CUSTOM')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repeat every',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black26),
                              ),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                controller: _intervalController,
                                onChanged: (value) {
                                  setState(() {
                                    _interval = int.tryParse(value) ?? 1;
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(10),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black26),
                              ),
                              child: DropdownButton<String>(
                                value: _customBaseFrequency,
                                isExpanded: true,
                                underline: const SizedBox(),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                items: ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'].map((freq) {
                                  return DropdownMenuItem(
                                    value: freq,
                                    child: Text(_frequencyLabels[freq] ?? freq),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    if (value != null) _customBaseFrequency = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Days of week for weekly
                if (_frequency == 'WEEKLY' || _frequency == 'BIWEEKLY' || (_frequency == 'CUSTOM'))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repeat on',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _weekDays.map((day) {
                          final isSelected = _selectedDays.contains(day);
                          return FilterChip(
                            label: Text(day),
                            selected: isSelected,
                            backgroundColor: Colors.white,
                            selectedColor: Colors.blue.shade100,
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.blue.shade900
                                  : Colors.black,
                              width: isSelected ? 2 : 1,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDays.add(day);
                                } else {
                                  _selectedDays.remove(day);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // End condition
                if (_frequency != 'NONE')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRadioOption('Never', 'never', () {
                        setState(() {
                          _endType = 'never';
                        });
                      }),
                      _buildRadioOption('On date', 'onDate', () {
                        setState(() {
                          _endType = 'onDate';
                        });
                      }),
                      if (_endType == 'onDate')
                        Padding(
                          padding: const EdgeInsets.only(left: 28, bottom: 8),
                          child: GestureDetector(
                            onTap: _pickEndDate,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _endDate.isEmpty
                                        ? 'Select date'
                                        : _formatDate(_endDate),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      _buildRadioOption('After occurrences', 'afterCount', () {
                        setState(() {
                          _endType = 'afterCount';
                        });
                      }),
                      if (_endType == 'afterCount')
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black),
                            ),
                            child: TextField(
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                text: _endCount,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _endCount = value;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Number',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(10),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Validation: Weekly/Biweekly must have at least one day selected
                        if ((_frequency == 'WEEKLY' ||
                                _frequency == 'BIWEEKLY') &&
                            _selectedDays.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select at least one day of the week',
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        // If custom, use the selected base frequency for RRULE
                        final rule = RecurrenceHelper.buildRule(
                          frequency: _frequency == 'CUSTOM' ? _customBaseFrequency : _frequency,
                          interval: _interval,
                          byDay: _selectedDays,
                          endType: _endType,
                          endDate: _endDate,
                          endCount: _endCount,
                        );
                        Navigator.pop(context, rule);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Colors.blue.shade900,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _endType,
              onChanged: (_) => onTap(),
              activeColor: Colors.blue.shade900,
            ),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getIntervalLabel() {
    switch (_frequency) {
      case 'DAILY':
        return 'day(s)';
      case 'WEEKLY':
        return 'week(s)';
      case 'MONTHLY':
        return 'month(s)';
      case 'YEARLY':
        return 'year(s)';
      default:
        return '';
    }
  }
}
