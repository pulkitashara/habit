import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/datasources/local/hive_service.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/color_utils.dart';

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

    print('🎨 Creating habit with color: $_selectedColor');

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
          SnackBar(
            content: const Text('Habit created successfully!'),
            backgroundColor: ColorUtils.parseHexColor(_selectedColor),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitProvider);
    final selectedHabitColor = ColorUtils.parseHexColor(_selectedColor);

    return Scaffold(
      // ✅ Allow body to extend behind AppBar
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text('Add New Habit'),
        elevation: 0,
      ),

      body: Container(
        // ✅ Add gradient background with selected habit color
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              selectedHabitColor.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16), // Space after transparent AppBar

                  // ✅ Habit Preview Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: selectedHabitColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(_selectedCategory),
                              color: selectedHabitColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isEmpty
                                      ? 'Your Habit Name'
                                      : _nameController.text,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _nameController.text.isEmpty
                                        ? Colors.grey[500]
                                        : null,
                                  ),
                                ),
                                Text(
                                  _selectedCategory.toUpperCase(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: selectedHabitColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

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
                    onChanged: (value) => setState(() {}), // ✅ Update preview
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category['value'];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? selectedHabitColor
                                : Theme.of(context).dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                          color: isSelected
                              ? selectedHabitColor.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category['value'];
                              _selectedIcon = category['iconName'];
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category['icon'],
                                  size: 18,
                                  color: isSelected
                                      ? selectedHabitColor
                                      : Theme.of(context).iconTheme.color,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category['label'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? selectedHabitColor
                                        : Theme.of(context).textTheme.bodyMedium?.color,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Target Count
                  Text(
                    'Daily Target',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: selectedHabitColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: _targetCount > 1 ? () {
                                setState(() {
                                  _targetCount--;
                                });
                              } : null,
                              icon: const Icon(Icons.remove),
                              color: selectedHabitColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '$_targetCount',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: selectedHabitColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: selectedHabitColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _targetCount++;
                                });
                              },
                              icon: const Icon(Icons.add),
                              color: selectedHabitColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _targetCount == 1 ? 'time per day' : 'times per day',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Color Selection
                  Text(
                    'Color Theme',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _colors.map((color) {
                          final isSelected = _selectedColor == color;
                          final colorValue = ColorUtils.parseHexColor(color);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colorValue,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                    width: 3
                                )
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: colorValue.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                                    : null,
                              ),
                              child: isSelected
                                  ? Icon(
                                Icons.check,
                                color: _getContrastColor(colorValue),
                                size: 24,
                              )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  habitState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                    text: 'Create Habit',
                    onPressed: _saveHabit,
                    backgroundColor: selectedHabitColor,
                    textColor: _getContrastColor(selectedHabitColor),
                  ),

                  const SizedBox(height: 16), // Bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Helper method to get category icon
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return Icons.fitness_center;
      case 'nutrition':
        return Icons.restaurant;
      case 'mindfulness':
        return Icons.self_improvement;
      case 'productivity':
        return Icons.work;
      case 'health':
        return Icons.health_and_safety;
      default:
        return Icons.psychology;
    }
  }

  // ✅ Helper method to get contrasting text color
  Color _getContrastColor(Color color) {
    // Calculate brightness using luminance
    final brightness = color.computeLuminance();
    return brightness > 0.5 ? Colors.black87 : Colors.white;
  }
}
