import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/themes/app_theme.dart';
import '../../../../core/constants/database_lib.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../widgets/educational_tip_widget.dart';

@RoutePage()
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String _selectedMetric = 'Glucose';
  String _selectedRange = 'Day';

  final List<String> _metricOptions = ['Glucose', 'Ketones'];
  final List<String> _rangeOptions = ['Day', 'Week', 'Month'];

  // sensor data
  List<Map<String, dynamic>> _sensorData = [];
  double? _latestGlucose;
  double? _latestKetones;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await DBUtils.getTodaySensorData();
      setState(() {
        _sensorData = data;
        
        // get latest values for GKI
        if (data.isNotEmpty) {
          final latest = data.last; 
          _latestGlucose = latest['sensor1'] != null ? (latest['sensor1'] as num).toDouble() : null;
          _latestKetones = latest['sensor2'] != null ? (latest['sensor2'] as num).toDouble() : null;
        } else {
          // reset to null when no data so fallback values are used
          _latestGlucose = null;
          _latestKetones = null;
        }
      });
    } catch (e) {
      // empty data if error
      print('Error loading data: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show more options
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildWelcomeSection(),
              const EducationalTipWidget(),
              const SizedBox(height: 8),
              _buildGlucoseKetoneChart(),
              _buildGkiCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              _navigateToIndex(index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondaryColor,
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.dashboard_outlined, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.dashboard, size: 22),
                ),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.download_outlined, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.download, size: 22),
                ),
                label: 'Export',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.settings_outlined, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(Icons.settings, size: 22),
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildGlucoseKetoneChart() {
  final bool isGlucose = _selectedMetric == 'Glucose';
  final String yAxisLabel = isGlucose ? 'mg/dL' : 'mmol/L';

  List<FlSpot> chartData = [];
  DateTime? baseTimestamp;
  
  if (_sensorData.isNotEmpty) {
    final sensorColumn = isGlucose ? 'sensor1' : 'sensor2';
    final timestamps = _sensorData
        .map((row) => row['timestamp'])
        .whereType<int>()
        .toList();
    if (timestamps.isNotEmpty) {
      baseTimestamp = DateTime.fromMillisecondsSinceEpoch(
        timestamps.reduce((a, b) => a < b ? a : b),
      );
    }
    
    chartData = _sensorData.map((row) {
      final value = row[sensorColumn];
      final tsMillis = row['timestamp'] as int?;
      
      if (value != null && tsMillis != null && baseTimestamp != null) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(tsMillis);
        final hoursSinceBase =
            timestamp.difference(baseTimestamp).inMilliseconds / 3600000.0;
        return FlSpot(hoursSinceBase, (value as num).toDouble());
      }
      return null;
    }).whereType<FlSpot>().where((spot) => spot.y > 0).toList();
  }
  
  // if we dont have data use dummy data
  if (chartData.isEmpty) {
    chartData = isGlucose
        ? [const FlSpot(0, 85), const FlSpot(1, 90), const FlSpot(2, 80), const FlSpot(3, 95)]
        : [const FlSpot(0, 1.2), const FlSpot(1, 1.1), const FlSpot(2, 1.4), const FlSpot(3, 1.0)];
  }
  baseTimestamp ??= DateTime.now();
  const double dotSize = 4.5;


  double yMin = chartData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
  double yMax = chartData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
  
 
  double yRange = yMax - yMin;
  if (yRange == 0) yRange = isGlucose ? 20 : 0.5; 
  yMin = (yMin - yRange * 0.1).clamp(0, double.infinity);
  yMax = yMax + yRange * 0.1;
  
  
  double yRangeWithPadding = yMax - yMin;
  double yInterval = yRangeWithPadding / 4; 
  if (isGlucose) {
    
    if (yInterval < 5) {
      yInterval = 5;
    } else if (yInterval < 10) {
      yInterval = 10;
    } else {
      yInterval = (yInterval / 10).ceilToDouble() * 10;
    }
  } else {
    
    if (yInterval < 0.1) {
      yInterval = 0.1;
    } else if (yInterval < 0.2) {
      yInterval = 0.2;
    } else if (yInterval < 0.5) {
      yInterval = 0.5;
    } else {
      yInterval = (yInterval * 2).ceilToDouble() / 2;
    }
  }

  
  double xMin = chartData.map((spot) => spot.x).reduce((a, b) => a < b ? a : b);
  double xMax = chartData.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);
  
  
  double xRange = xMax - xMin;
  if (xRange == 0) xRange = 3; 
  xMin = (xMin - xRange * 0.1).clamp(0, double.infinity);
  xMax = xMax + xRange * 0.1;
  
  
  double xRangeWithPadding = xMax - xMin;
  double xInterval = xRangeWithPadding / 4;
  if (xInterval <= 2) {
    xInterval = 2;
  } else if (xInterval <= 3) {
    xInterval = 3;
  } else if (xInterval <= 4) {
    xInterval = 4;
  } else if (xInterval <= 6) {
    xInterval = 6;
  } else {
    xInterval = (xInterval / 6).ceilToDouble() * 6; 
  }

  return Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
     
          Text(
            "Daily Tracker",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              DropdownButton<String>(
                value: _selectedMetric,
                items: _metricOptions
                    .map((metric) => DropdownMenuItem(
                          value: metric,
                          child: Text(metric),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMetric = value!;
                  });
                },
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedRange,
                items: _rangeOptions
                    .map((range) => DropdownMenuItem(
                          value: range,
                          child: Text(range),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRange = value!;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: xMin,
                maxX: xMax,
                minY: yMin,
                maxY: yMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,

                   
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: dotSize,
                          color: AppTheme.primaryColor,
                          strokeWidth: 1.2,
                          strokeColor: Colors.white,
                        ),
                    ),
                  ),
                ],

              
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(yAxisLabel),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        
                        const double epsilon = 0.001;
                        if (value < yMin || value > yMax || 
                            (value - yMin).abs() < epsilon || 
                            (value - yMax).abs() < epsilon) {
                          return const Text('');
                        }
                        return Text(
                          isGlucose 
                            ? value.toInt().toString()
                            : value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("Time"),
                    axisNameSize: 22,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
          
                        const double epsilon = 0.1;
                        if (value < xMin - epsilon || value > xMax + epsilon) {
                          return const SizedBox.shrink();
                        }
                      
                        if (baseTimestamp == null) {
                          return const SizedBox.shrink();
                        }
                        
                        final displayTime = baseTimestamp.add(
                          Duration(
                            minutes: (value * 60).round(),
                          ),
                        );
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _formatChartTime(displayTime),
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),

                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
        
                        if (baseTimestamp == null) {
                          return LineTooltipItem(
                            '${touchedSpot.y.toStringAsFixed(isGlucose ? 0 : 1)} $yAxisLabel',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        
                        final displayTime = baseTimestamp.add(
                          Duration(
                            minutes: (touchedSpot.x * 60).round(),
                          ),
                        );
                        
                        final timeStr = _formatChartTime(displayTime);
                        final valueStr = isGlucose 
                            ? touchedSpot.y.toInt().toString()
                            : touchedSpot.y.toStringAsFixed(1);
                        
                        return LineTooltipItem(
                          '$timeStr\n$valueStr $yAxisLabel',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                    tooltipBgColor: AppTheme.primaryColor.withOpacity(0.9),
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  touchSpotThreshold: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}



  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning, John!',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How are you feeling today?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildWelcomeMetric(
                  icon: Icons.local_fire_department,
                  title: 'Streak',
                  value: '12 days',
                  subtitle: 'In ketosis',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWelcomeMetric(
                  icon: Icons.trending_up,
                  title: 'Progress',
                  value: '85%',
                  subtitle: 'Goal achieved',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMetric({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGkiCard() {
    // use dummy data if we dont have data
    final glucose = _latestGlucose ?? 85.0;
    final ketones = _latestKetones ?? 1.2;
    final gki = (ketones > 0) ? glucose / (ketones * 18.0) : 0.0;

    Color getGkiColor() {
      if (gki <= 3.0) return AppTheme.optimalColor;
      if (gki <= 6.0) return AppTheme.therapeuticColor;
      if (gki <= 9.0) return AppTheme.cautionColor;
      return AppTheme.criticalColor;
    }

    String getGkiStatus() {
      if (gki <= 3.0) return 'Optimal';
      if (gki <= 6.0) return 'Therapeutic';
      if (gki <= 9.0) return 'Moderate';
      return 'High';
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Glucose-Ketone Index',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    // TODO: Show GKI information
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: getGkiColor(), width: 8),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      gki.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: getGkiColor(),
                          ),
                    ),
                    Text(
                      getGkiStatus(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: getGkiColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildGkiMetric(
                    icon: Icons.water_drop,
                    label: 'Glucose',
                    value: '${glucose.toStringAsFixed(0)} mg/dL',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGkiMetric(
                    icon: Icons.science,
                    label: 'Ketones',
                    value: '${ketones.toStringAsFixed(1)} mmol/L',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGkiMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  String _formatChartTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _navigateToIndex(int index) {
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        context.router.pushNamed('/food-diary');
        break;
      case 2:
        context.router.pushNamed('/settings');
        break;
    }
  }
}
