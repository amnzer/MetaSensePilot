import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/themes/app_theme.dart';

class EducationalTipWidget extends StatefulWidget {
  const EducationalTipWidget({super.key});

  @override
  State<EducationalTipWidget> createState() => _EducationalTipWidgetState();
}

class _EducationalTipWidgetState extends State<EducationalTipWidget> {
  late String _currentTip;
  final Random _random = Random();

  static const List<String> _educationalTips = [
  'Consistency matters more than perfection. Small daily habits shape biomarker trends.',
  'Try logging your data at similar times each day to make patterns easier to see.',
  'Hydration influences many biomarkers. A glass of water can go a long way.',
  'Trends are more meaningful than single readings.',
  'A short walk after meals can help support steadier glucose levels.',
  'High stress can affect glucose. Slow breathing can help calm your system.',
  'Quality sleep is one of the strongest regulators of metabolism.',
  'Look for patterns rather than reacting to one reading.',
  'Eating slowly can help improve how your body processes meals.',
  'Balanced meals often support more stable glucose and energy levels.',
  'Lactate rises during harder exercise. This can be part of productive effort.',
  'Regular meal timing supports more predictable energy.',
  'Short naps can help regulate hunger and stress hormones.',
  'Notice how you feel, not just what the numbers are.',
  'Gentle movement after eating can aid digestion and glucose stability.',
  'Protein can help support steady energy across the day.',
  'Everyone has a different personal baseline. Learn yours.',
  'Morning light exposure helps regulate your body’s daily rhythm.',
  'Slow deep breathing can shift your body into a calmer state.',
  'Fiber slows digestion and helps stabilize glucose response.',
  'Drinking water with meals can support digestion and hydration.',
  'Sleep supports recovery and metabolic balance.',
  'Notes about meals or stress can help you understand your data better.',
  'Check how certain foods feel a few hours later, not just right away.',
  'Progress often comes from small repeated choices.',
  'Evening routines can support better sleep and next day stability.',
  'Balanced fat, carb, and protein intake supports steadier metabolism.',
  'Ketone levels can rise during fasting, sleep, or exercise.',
  'The body keeps pH within a narrow range. Large swings are less common.',
  'Lactate is a fuel, not just a waste product. It supports energy production.',
  'Avoid comparing your data to someone else. Every body is different.',
  'Walking after eating is a powerful simple habit.',
  'Eating slowly supports steadier glucose responses.',
  'Whole foods generally support steadier energy than highly processed foods.',
  'Stress is a metabolic input just like food or exercise.',
  'Blue light late at night can make sleep less restorative.',
  'Fiber supports gut health and metabolic stability.',
  'Consistent routines improve data clarity.',
  'Light stretching can help reduce tension and aid recovery.',
  'Your body uses water to transport nutrients and regulate temperature.',
  'Meal notes help reveal your unique patterns.',
  'Sleep quality influences appetite signals the next day.',
  'Notice which foods keep you satisfied longest.',
  'Metabolic health is about flexibility, not rigidity.',
  'You do not need perfect control. Aim for steady improvement.',
  'Emotional stress affects physical markers.',
  'Whole grains break down more slowly than refined grains.',
  'Nasal breathing can support calmer physiology.',
  'A stable morning makes the rest of the day smoother.',
  'Sunlight early in the day supports circadian rhythm.',
  'Regular movement, even light movement, supports metabolism.',
  'Protein early in the day can support steady energy and satiety.',
  'Take your time with meals. Digestion starts with being calm.',
  'Your body gives you signals. Listening helps you respond well.',
  'One glucose rise does not define health. Patterns matter.',
  'Small nutritional adjustments often shift trends more than extreme diets.',
  'Short breaks during the day can reduce stress buildup.',
  'Learning your personal triggers leads to more confident decisions.',
  'Overnight readings provide insight into recovery and stress.',
  'Keeping caffeine earlier in the day can improve sleep quality.',
  'Moderate exercise supports metabolic flexibility.',
  'Ketones rise as your body shifts fuel sources.',
  'Hydrate consistently, not just when thirsty.',
  'Eating right before bed may affect sleep for some people.',
  'Aim for nourishment instead of restriction.',
  'Fresh air and gentle movement support mental clarity and energy.',
  'A calm nervous system helps stabilize metabolism.',
  'Try introducing new foods one at a time to learn your responses.',
  'Meals with natural color usually include more micronutrients.',
  'You do not need to track forever to learn useful patterns.',
  'Notice how your body feels during and after exercise.',
  'Nighttime routines influence next-day metabolism.',
  'Steady glucose can support clearer thinking.',
  'Biomarkers respond to sleep, stress, movement, and meals together.',
  'Rest is part of growth and adaptation.',
  'Some people benefit from snacks, others from longer meal gaps. Data can help you learn.',
  'Consistent routines reveal clearer patterns.',
  'You can always reset with your next choice.',
  'Light stretching before sleep can support relaxation.',
  'It is normal for glucose to rise briefly after waking.',
  'Whole fruit digests differently than fruit juice because of fiber.',
  'Temporary lactate rise during exercise shows effort, not a problem.',
  'Focus on progress, not perfection.',
  'Food is both fuel and enjoyment. Mindful eating supports balance.',
  'Eating until satisfied, not stuffed, supports comfortable digestion.',
  'Rest days support muscle and metabolic recovery.',
  'Noticing portion sizes can help stabilize energy levels.',
  'Active days may require more hydration.',
  'Metabolic trends are easier to see over weeks rather than days.',
  'Avoid labeling foods as good or bad. Notice how they affect you.',
  'Mindfulness around meals can reduce stress-driven glucose spikes.',
  'Lower stress supports steadier biomarker levels.',
  'Daily walks add up to meaningful metabolic benefits.',
  'Pairing protein with carbs can slow glucose spikes.',
  'Track how your sleep length influences your data.',
  'Personal data builds personal awareness.',
  'Curiosity helps you learn from your data without judgment.',
  'Progress usually comes from small repeated actions.',
];


  @override
  void initState() {
    super.initState();
    _currentTip = _getRandomTip();
  }

  String _getRandomTip() {
    if (_educationalTips.isEmpty) {
      return 'Welcome to MetaSense Pilot!';
    }
    return _educationalTips[_random.nextInt(_educationalTips.length)];
  }

  void _refreshTip() {
    setState(() {
      _currentTip = _getRandomTip();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_educationalTips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: AppTheme.primaryColor.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: _refreshTip,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Did You Know?',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentTip,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              height: 1.4,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  color: AppTheme.textSecondaryColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _refreshTip,
                  tooltip: 'Get another tip',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

