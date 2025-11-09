import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_theme.dart';
import '../widgets/macro_bars_widget.dart';
import '../widgets/time_grouped_entry_card.dart';

@RoutePage()
class FoodDiaryPage extends StatefulWidget {
  const FoodDiaryPage({super.key});

  @override
  State<FoodDiaryPage> createState() => _FoodDiaryPageState();
}

class _FoodDiaryPageState extends State<FoodDiaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  // TO DO: change sample data to actual data thru state management or api
  final double _carbsLimit = 20.0; 
  final double _proteinGoal = 100.0; 
  final double _fatGoal = 150.0; 

  // TO DO: food entries with timestamps to be replaced with actual data
  List<({FoodItem food, DateTime timestamp})> _foodEntries = [
    (
      food: const FoodItem(
        name: 'Avocado',
        carbs: 4.0,
        protein: 2.0,
        fat: 15.0,
        calories: 160,
        servingSize: '1 medium',
      ),
      timestamp: DateTime.now().copyWith(hour: 8, minute: 30, second: 0),
    ),
    (
      food: const FoodItem(
        name: 'Eggs (2 large)',
        carbs: 1.0,
        protein: 12.0,
        fat: 10.0,
        calories: 140,
        servingSize: '2 large',
      ),
      timestamp: DateTime.now().copyWith(hour: 8, minute: 35, second: 0),
    ),
    (
      food: const FoodItem(
        name: 'Chicken Breast',
        carbs: 0.0,
        protein: 54.0,
        fat: 3.0,
        calories: 231,
        servingSize: '200g',
      ),
      timestamp: DateTime.now().copyWith(hour: 12, minute: 30, second: 0),
    ),
    (
      food: const FoodItem(
        name: 'Olive Oil',
        carbs: 0.0,
        protein: 0.0,
        fat: 14.0,
        calories: 120,
        servingSize: '1 tbsp',
      ),
      timestamp: DateTime.now().copyWith(hour: 12, minute: 32, second: 0),
    ),
    (
      food: const FoodItem(
        name: 'Spinach Salad',
        carbs: 3.0,
        protein: 3.0,
        fat: 0.0,
        calories: 23,
        servingSize: '2 cups',
      ),
      timestamp: DateTime.now().copyWith(hour: 12, minute: 35, second: 0),
    ),
    (
      food: const FoodItem(
        name: 'Almonds',
        carbs: 6.0,
        protein: 14.0,
        fat: 37.0,
        calories: 413,
        servingSize: '30g',
      ),
      timestamp: DateTime.now().copyWith(hour: 15, minute: 0, second: 0),
    ),
    (
      food: const FoodItem(
        name: 'Salmon',
        carbs: 0.0,
        protein: 25.0,
        fat: 12.0,
        calories: 208,
        servingSize: '150g',
      ),
      timestamp: DateTime.now().copyWith(hour: 19, minute: 0, second: 0),
    ),
    (
      food: const FoodItem(
        name: 'Broccoli',
        carbs: 6.0,
        protein: 3.0,
        fat: 0.0,
        calories: 34,
        servingSize: '1 cup',
      ),
      timestamp: DateTime.now().copyWith(hour: 19, minute: 5, second: 0),
    ),
  ];

  // TO DO: biomarker entries with timestamps to be replaced with actual data
  final List<({BiomarkerValue biomarker, DateTime timestamp})> _biomarkerEntries = [
    (
      biomarker: const BiomarkerValue(
        label: 'Glucose',
        value: 85.0,
        unit: 'mg/dL',
        color: Colors.orange,
      ),
      timestamp: DateTime.now().copyWith(hour: 8, minute: 30, second: 0),
    ),
    (
      biomarker: const BiomarkerValue(
        label: 'Ketones',
        value: 1.2,
        unit: 'mmol/L',
        color: Colors.purple,
      ),
      timestamp: DateTime.now().copyWith(hour: 8, minute: 30, second: 0),
    ),
    (
      biomarker: const BiomarkerValue(
        label: 'Glucose',
        value: 95.0,
        unit: 'mg/dL',
        color: Colors.orange,
      ),
      timestamp: DateTime.now().copyWith(hour: 12, minute: 30, second: 0),
    ),
    (
      biomarker: const BiomarkerValue(
        label: 'Ketones',
        value: 1.1,
        unit: 'mmol/L',
        color: Colors.purple,
      ),
      timestamp: DateTime.now().copyWith(hour: 12, minute: 32, second: 0),
    ),
  ];

  // Get grouped entries by time
  List<TimeGroupedEntry> get _groupedEntries {
    return groupFoodsByTimeWithTimestamps(
      foodEntries: _foodEntries,
      biomarkerEntries: _biomarkerEntries,
      timeWindowMinutes: 15,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _searchFood(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTodayTab(), _buildHistoryTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addFood(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayTab() {
    final totalCarbs = _groupedEntries.fold(0.0, (sum, entry) => sum + entry.totalCarbs);
    final totalProtein = _groupedEntries.fold(0.0, (sum, entry) => sum + entry.totalProtein);
    final totalFat = _groupedEntries.fold(0.0, (sum, entry) => sum + entry.totalFat);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDateSelector(),
          MacroBarsWidget(
            carbsGrams: totalCarbs,
            proteinGrams: totalProtein,
            fatGrams: totalFat,
            carbsLimit: _carbsLimit,
            proteinGoal: _proteinGoal,
            fatGoal: _fatGoal,
          ),
          _buildMacroSummary(),
          _buildQuickAddSection(),
          _buildTimelineHeader(),
          _buildTimeGroupedEntries(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'History View',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming soon! View your historical food data and trends.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(
            _formatDate(_selectedDate),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (_isToday(_selectedDate))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMacroSummary() {
    final totalCalories = _groupedEntries.fold(0.0, (sum, entry) => sum + entry.totalCalories);
    final totalCarbs = _groupedEntries.fold(0.0, (sum, entry) => sum + entry.totalCarbs);
    final netCarbs = totalCarbs - 8.0; // Assuming 8g fiber

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMacroSummaryItem(
            'Calories',
            totalCalories.toStringAsFixed(0),
            'kcal',
          ),
          _buildMacroSummaryItem('Net Carbs', netCarbs.toStringAsFixed(1), 'g'),
          _buildMacroSummaryItem('Fiber', '8.0', 'g'),
        ],
      ),
    );
  }

  Widget _buildMacroSummaryItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          unit,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildQuickAddSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _addFoodAtTime(DateTime.now()),
              icon: const Icon(Icons.add),
              label: const Text('Add Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _addFoodAtCustomTime(),
              icon: const Icon(Icons.schedule),
              label: const Text('Custom Time'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Food Timeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          Text(
            '${_foodEntries.length} entries',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeGroupedEntries() {
    final groupedEntries = _groupedEntries;

    if (groupedEntries.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No food logged today',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add Now" to log your first meal',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: groupedEntries.map((entry) {
        return TimeGroupedEntryCard(
          entry: entry,
          onEditFood: (food, time) => _editFoodItem(food, time),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _searchFood() {
    // TODO: Implement food search
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Food search coming soon!'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  void _addFood() {
    // TODO: Implement add food functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add food functionality coming soon!'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  void _addFoodAtTime(DateTime time) {
    // TODO: Implement add food at specific time
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Add food at ${DateFormat('h:mm a').format(time)} coming soon!',
        ),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  Future<void> _addFoodAtCustomTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      final DateTime customDateTime = DateTime.now().copyWith(
        hour: time.hour,
        minute: time.minute,
        second: 0,
      );
      _addFoodAtTime(customDateTime);
    }
  }

  Future<void> _editFoodItem(FoodItem food, DateTime time) async {
    final result = await showDialog<FoodItem>(
      context: context,
      builder: (context) => _EditFoodItemDialog(
        initialFood: food,
        initialTime: time,
      ),
    );

    if (result != null) {
      setState(() {
        // can change time window
        final timeWindowMinutes = 15;
        final windowStart = _getTimeWindowStart(time, timeWindowMinutes);
        
        final index = _foodEntries.indexWhere(
          (entry) {
            final entryWindowStart = _getTimeWindowStart(entry.timestamp, timeWindowMinutes);
            return entry.food.name == food.name &&
                   entry.food.carbs == food.carbs &&
                   entry.food.protein == food.protein &&
                   entry.food.fat == food.fat &&
                   entry.food.calories == food.calories &&
                   entryWindowStart == windowStart;
          },
        );
        
        if (index != -1) {
          _foodEntries[index] = (food: result, timestamp: _foodEntries[index].timestamp);
        }
      });
    }
  }

  DateTime _getTimeWindowStart(DateTime timestamp, int windowMinutes) {
    final minutes = timestamp.minute;
    final windowStartMinute = (minutes ~/ windowMinutes) * windowMinutes;
    return DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      timestamp.hour,
      windowStartMinute,
      0,
    );
  }
}

class _EditFoodItemDialog extends StatefulWidget {
  final FoodItem initialFood;
  final DateTime initialTime;

  const _EditFoodItemDialog({
    required this.initialFood,
    required this.initialTime,
  });

  @override
  State<_EditFoodItemDialog> createState() => _EditFoodItemDialogState();
}

class _EditFoodItemDialogState extends State<_EditFoodItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _servingSizeController;
  late TextEditingController _carbsController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _caloriesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFood.name);
    _servingSizeController = TextEditingController(text: widget.initialFood.servingSize);
    _carbsController = TextEditingController(text: widget.initialFood.carbs.toStringAsFixed(1));
    _proteinController = TextEditingController(text: widget.initialFood.protein.toStringAsFixed(1));
    _fatController = TextEditingController(text: widget.initialFood.fat.toStringAsFixed(1));
    _caloriesController = TextEditingController(text: widget.initialFood.calories.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingSizeController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food name is required')),
      );
      return;
    }

    final carbs = double.tryParse(_carbsController.text) ?? 0.0;
    final protein = double.tryParse(_proteinController.text) ?? 0.0;
    final fat = double.tryParse(_fatController.text) ?? 0.0;
    final calories = double.tryParse(_caloriesController.text) ?? 0.0;

    final updatedFood = FoodItem(
      name: name,
      servingSize: _servingSizeController.text.trim(),
      carbs: carbs,
      protein: protein,
      fat: fat,
      calories: calories,
    );

    Navigator.of(context).pop(updatedFood);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Food Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _servingSizeController,
              decoration: const InputDecoration(
                labelText: 'Serving Size',
                border: OutlineInputBorder(),
                hintText: 'e.g., 1 cup, 100g',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    decoration: const InputDecoration(
                      labelText: 'Carbs (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    decoration: const InputDecoration(
                      labelText: 'Protein (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    decoration: const InputDecoration(
                      labelText: 'Fat (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _caloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
