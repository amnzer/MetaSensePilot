import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_theme.dart';

class BiomarkerValue {
  final String label;
  final double value;
  final String unit;
  final Color? color;

  const BiomarkerValue({
    required this.label,
    required this.value,
    required this.unit,
    this.color,
  });
}

class FoodItem {
  final String name;
  final String servingSize;
  final double carbs;
  final double protein;
  final double fat;
  final double calories;

  const FoodItem({
    required this.name,
    required this.servingSize,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.calories,
  });
}

class TimeGroupedEntry {
  final DateTime time;
  final List<FoodItem> foods;
  final List<BiomarkerValue> biomarkers;

  const TimeGroupedEntry({
    required this.time,
    required this.foods,
    this.biomarkers = const [],
  });

  double get totalCarbs => foods.fold(0.0, (sum, food) => sum + food.carbs);
  double get totalProtein => foods.fold(0.0, (sum, food) => sum + food.protein);
  double get totalFat => foods.fold(0.0, (sum, food) => sum + food.fat);
  double get totalCalories => foods.fold(0.0, (sum, food) => sum + food.calories);
}

class TimeGroupedEntryCard extends StatelessWidget {
  final TimeGroupedEntry entry;
  final Function(FoodItem food, DateTime time)? onEditFood;

  const TimeGroupedEntryCard({
    super.key,
    required this.entry,
    this.onEditFood,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time header
            _buildTimeHeader(context),
            const SizedBox(height: 16),
            
            // Biomarkers section (if any)
            if (entry.biomarkers.isNotEmpty) ...[
              _buildBiomarkersSection(context),
              const SizedBox(height: 16),
            ],
            
            // Food items list
            if (entry.foods.isNotEmpty) ...[
              _buildFoodItemsSection(context),
              const SizedBox(height: 12),
              
              // Total macros summary
              _buildMacroSummary(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        DateFormat('h:mm a').format(entry.time),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildBiomarkersSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biomarkers',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: entry.biomarkers.map((biomarker) {
              return _buildBiomarkerChip(context, biomarker);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBiomarkerChip(BuildContext context, BiomarkerValue biomarker) {
    final color = biomarker.color ?? AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            biomarker.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${biomarker.value.toStringAsFixed(biomarker.unit == 'mg/dL' ? 0 : 1)} ${biomarker.unit}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Food Items',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
        ),
        const SizedBox(height: 8),
        ...entry.foods.asMap().entries.map((foodEntry) {
          final index = foodEntry.key;
          final food = foodEntry.value;
          final isLast = index == entry.foods.length - 1;
          
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: _buildFoodItem(context, food, entry.time),
          );
        }),
      ],
    );
  }

  Widget _buildFoodItem(BuildContext context, FoodItem food, DateTime time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Food name and serving
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                food.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (food.servingSize.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  food.servingSize,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ],
            ],
          ),
        ),
        // Macros chips
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMacroChip('C', food.carbs, Colors.orange),
            const SizedBox(width: 4),
            _buildMacroChip('P', food.protein, Colors.blue),
            const SizedBox(width: 4),
            _buildMacroChip('F', food.fat, Colors.green),
          ],
        ),
        // Calories
        const SizedBox(width: 8),
        Text(
          '${food.calories.toStringAsFixed(0)} cal',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
        ),
        if (onEditFood != null) ...[
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: () => onEditFood!(food, time),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Edit',
          ),
        ],
      ],
    );
  }

  Widget _buildMacroChip(String label, double value, Color color) {
    if (value == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)}g',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMacroSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', entry.totalCalories.toStringAsFixed(0), 'cal'),
          _buildSummaryItem('Carbs', entry.totalCarbs.toStringAsFixed(1), 'g'),
          _buildSummaryItem('Protein', entry.totalProtein.toStringAsFixed(1), 'g'),
          _buildSummaryItem('Fat', entry.totalFat.toStringAsFixed(1), 'g'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          '$label ($unit)',
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

List<TimeGroupedEntry> groupFoodsByTimeWithTimestamps({
  required List<({FoodItem food, DateTime timestamp})> foodEntries,
  List<({BiomarkerValue biomarker, DateTime timestamp})> biomarkerEntries = const [],
  int timeWindowMinutes = 15,
}) {
  if (foodEntries.isEmpty) return [];

  final sortedFoods = [...foodEntries]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final sortedBiomarkers = [...biomarkerEntries]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  final Map<DateTime, List<FoodItem>> foodGroups = {};
  final Map<DateTime, List<BiomarkerValue>> biomarkerGroups = {};

  for (final entry in sortedFoods) {
    final windowStart = _getTimeWindowStart(entry.timestamp, timeWindowMinutes);
    foodGroups.putIfAbsent(windowStart, () => []).add(entry.food);
  }

  for (final entry in sortedBiomarkers) {
    final windowStart = _getTimeWindowStart(entry.timestamp, timeWindowMinutes);
    biomarkerGroups.putIfAbsent(windowStart, () => []).add(entry.biomarker);
  }

  final List<TimeGroupedEntry> result = [];
  for (final windowStart in foodGroups.keys.toList()..sort()) {
    result.add(TimeGroupedEntry(
      time: windowStart,
      foods: foodGroups[windowStart]!,
      biomarkers: biomarkerGroups[windowStart] ?? [],
    ));
  }

  return result;
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

