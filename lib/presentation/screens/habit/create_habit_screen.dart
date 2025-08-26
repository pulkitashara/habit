import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../../domain/entities/habit.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/validators.dart';

class CreateHabitScreen extends ConsumerStatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  ConsumerState<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends ConsumerState<CreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();

  String _selectedCategory = 'fitness';
  String _selectedFrequency = 'daily';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Fitness', 'value': 'fitness', 'color': AppColors.fitness, 'icon': Icons.fitness_center},
    {'name': 'Nutrition', 'value': 'nutrition', 'color': AppColors.nutrition, 'icon': Icons.restaurant},
    {'name': 'Mindfulness', 'value': 'mindfulness', 'color': AppColors.mindfulness, 'icon': Icons.self_improvement},
    {'name': 'Productivity', 'value': 'productivity', 'color': AppColors.productivity, 'icon': Icons.work},
    {'name': 'Social', 'value': 'social', 'color': AppColors.social, 'icon': Icons.people},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Habit'),
        backgroundColor: _getSelectedCategoryColor().withValues(alpha: 0.1),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Habit Name
              CustomTextField(
                controller: _nameController,
                labelText: 'Habit Name',
                prefixIcon: Icons.psychology,
                validator: Validators.habitName,
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description (Optional)',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Category Selection
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['value'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? category['color'].withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? category['color']
                              : Colors.grey.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category['icon'],
                            color: isSelected ? category['color'] : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category['name'],
                            style: TextStyle(
                              color: isSelected ? category['color'] : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Target and Frequency
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _targetController,
                      labelText: 'Target Count',
                      prefixIcon: Icons.flag,
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.positiveInteger(value, 'Target count'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedFrequency = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Preview Card
              Card(
                color: _getSelectedCategoryColor().withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getSelectedCategoryColor().withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getSelectedCategoryIcon(),
                              color: _getSelectedCategoryColor(),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isEmpty
                                      ? 'Habit Name'
                                      : _nameController.text,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _selectedCategory.toUpperCase(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _getSelectedCategoryColor(),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_descriptionController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _descriptionController.text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Target: ${_targetController.text.isEmpty ? "1" : _targetController.text} times $_selectedFrequency',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: habitState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomButton(
            text: 'Create Habit',
            onPressed: _createHabit,
            backgroundColor: _getSelectedCategoryColor(),
          ),
        ),
      ),
    );
  }

  Color _getSelectedCategoryColor() {
    final category = _categories.firstWhere(
          (cat) => cat['value'] == _selectedCategory,
      orElse: () => _categories.first,
    );
    return category['color'];
  }

  IconData _getSelectedCategoryIcon() {
    final category = _categories.firstWhere(
          (cat) => cat['value'] == _selectedCategory,
      orElse: () => _categories.first,
    );
    return category['icon'];
  }

  Future<void> _createHabit() async {
    if (!_formKey.currentState!.validate()) return;

    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      targetCount: int.tryParse(_targetController.text) ?? 1,
      frequency: _selectedFrequency,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      color: '#${_getSelectedCategoryColor().value.toRadixString(16).padLeft(8, '0').substring(2)}',
      icon: _getSelectedCategoryIcon().toString(),
    );

    await ref.read(habitProvider.notifier).createHabit(habit);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${habit.name} created successfully!'),
          backgroundColor: _getSelectedCategoryColor(),
        ),
      );
      context.pop();
    }
  }
}
