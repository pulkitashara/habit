import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/datasources/local/hive_service.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../../core/utils/validators.dart';

class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'fitness';
  String _selectedFrequency = 'daily';
  int _targetCount = 1;
  String _selectedColor = '#FF6B6B';
  String _selectedIcon = 'fitness_center';

  final List<Map<String, dynamic>> _categories = [
    {'value': 'fitness', 'label': 'Fitness', 'icon': Icons.fitness_center, 'iconName': 'fitness_center'},
    {'value': 'nutrition', 'label': 'Nutrition', 'icon': Icons.restaurant, 'iconName': 'restaurant'},
    {'value': 'mindfulness', 'label': 'Mindfulness', 'icon': Icons.self_improvement, 'iconName': 'self_improvement'},
    {'value': 'productivity', 'label': 'Productivity', 'icon': Icons.work, 'iconName': 'work'},
    {'value': 'health', 'label': 'Health', 'icon': Icons.health_and_safety, 'iconName': 'health_and_safety'},
  ];

  final List<String> _colors = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
    '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    final habit = Habit(
      id: 'habit_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      targetCount: _targetCount,
      frequency: _selectedFrequency,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      color: _selectedColor,
      icon: _selectedIcon,
      currentStreak: 0,
      longestStreak: 0,
      completionRate: 0.0,
      userId: HiveService.getCurrentUserId() ?? '',
    );

    try {
      await ref.read(habitProvider.notifier).createHabit(habit);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Habit created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create habit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Habit'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Habit Name
              CustomTextField(
                controller: _nameController,
                labelText: 'Habit Name',
                prefixIcon: Icons.label_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description (Optional)',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Category Selection
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category['value'];
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(category['icon'], size: 16),
                        const SizedBox(width: 4),
                        Text(category['label']),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category['value'];
                        _selectedIcon = category['iconName'];
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Target Count
              Text(
                'Daily Target',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _targetCount > 1 ? () {
                      setState(() {
                        _targetCount--;
                      });
                    } : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '$_targetCount',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _targetCount++;
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _targetCount == 1 ? 'time per day' : 'times per day',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Color Selection
              Text(
                'Color',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000),
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Save Button
              habitState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                text: 'Create Habit',
                onPressed: _saveHabit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
