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
  String _selectedCardBiomarker = 'Glucose';

  final List<String> _metricOptions = ['Glucose', 'pH', 'K', 'Na'];
  final List<String> _rangeOptions = ['Day', 'Week', 'Month'];

  // sensor data: sensor1=Glucose, sensor2=pH, sensor3=K, sensor4=Na
  List<Map<String, dynamic>> _sensorData = [];
  double? _latestGlucose;
  double? _latestPH;
  double? _latestK;
  double? _latestNa;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> data;
      switch (_selectedRange) {
        case 'Day':
          data = await DBUtils.getTodaySensorData();
          break;
        case 'Week':
          data = await DBUtils.getSensorDataInRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          );
          break;
        case 'Month':
          data = await DBUtils.getSensorDataInRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          );
          break;
        default:
          data = await DBUtils.getTodaySensorData();
      }
      if (!mounted) return;
      setState(() {
        _sensorData = data;
        // latest values per biomarker (from most recent reading in loaded range)
        if (data.isNotEmpty) {
          final latest = data.last;
          _latestGlucose = latest['sensor1'] != null ? (latest['sensor1'] as num).toDouble() : null;
          _latestPH = latest['sensor2'] != null ? (latest['sensor2'] as num).toDouble() : null;
          _latestK = latest['sensor3'] != null ? (latest['sensor3'] as num).toDouble() : null;
          _latestNa = latest['sensor4'] != null ? (latest['sensor4'] as num).toDouble() : null;
        } else {
          _latestGlucose = null;
          _latestPH = null;
          _latestK = null;
          _latestNa = null;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _sensorData = [];
          _latestGlucose = null;
          _latestPH = null;
          _latestK = null;
          _latestNa = null;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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

String _getSensorColumnForMetric(String metric) {
  switch (metric) {
    case 'Glucose': return 'sensor1';
    case 'pH': return 'sensor2';
    case 'K': return 'sensor3';
    case 'Na': return 'sensor4';
    default: return 'sensor1';
  }
}

String _getUnitForMetric(String metric) {
  switch (metric) {
    case 'Glucose': return 'mg/dL';
    case 'pH': return 'pH';
    case 'K':
    case 'Na': return 'mmol/L';
    default: return '';
  }
}

Widget _buildGlucoseKetoneChart() {
  final String sensorColumn = _getSensorColumnForMetric(_selectedMetric);
  final String yAxisLabel = _getUnitForMetric(_selectedMetric);
  final bool isGlucose = _selectedMetric == 'Glucose';
  final bool isPH = _selectedMetric == 'pH';

  List<FlSpot> chartData = [];
  DateTime? baseTimestamp;
  
  if (_sensorData.isNotEmpty) {
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
  
  // dummy data when none
  if (chartData.isEmpty) {
    if (isGlucose) {
      chartData = [const FlSpot(0, 85), const FlSpot(1, 90), const FlSpot(2, 80), const FlSpot(3, 95)];
    } else if (isPH) {
      chartData = [const FlSpot(0, 7.2), const FlSpot(1, 7.3), const FlSpot(2, 7.25), const FlSpot(3, 7.4)];
    } else {
      chartData = [const FlSpot(0, 4.0), const FlSpot(1, 4.2), const FlSpot(2, 3.9), const FlSpot(3, 4.1)];
    }
  }
  baseTimestamp ??= DateTime.now();
  const double dotSize = 4.5;

  double yMin = chartData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
  double yMax = chartData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
  double yRange = yMax - yMin;
  if (yRange == 0) {
    if (isGlucose) yRange = 20;
    else if (isPH) yRange = 0.5;
    else yRange = 0.5;
  }
  yMin = (yMin - yRange * 0.1).clamp(0.0, double.infinity);
  yMax = yMax + yRange * 0.1;

  double yRangeWithPadding = yMax - yMin;
  double yInterval = yRangeWithPadding / 4;
  if (isGlucose) {
    if (yInterval < 5) yInterval = 5;
    else if (yInterval < 10) yInterval = 10;
    else yInterval = (yInterval / 10).ceilToDouble() * 10;
  } else if (isPH) {
    if (yInterval < 0.1) yInterval = 0.1;
    else if (yInterval < 0.2) yInterval = 0.2;
    else yInterval = (yInterval * 2).ceilToDouble() / 2;
  } else {
    if (yInterval < 0.1) yInterval = 0.1;
    else if (yInterval < 0.2) yInterval = 0.2;
    else yInterval = (yInterval * 2).ceilToDouble() / 2;
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
                  if (value == null) return;
                  setState(() {
                    _selectedRange = value;
                  });
                  _loadData();
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
                          isGlucose ? value.toInt().toString() : value.toStringAsFixed(1),
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
                        final label = _selectedRange == 'Day'
                            ? _formatChartTime(displayTime)
                            : _formatChartDate(displayTime);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 10),
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
                            '${isGlucose ? touchedSpot.y.toInt() : touchedSpot.y.toStringAsFixed(1)} $yAxisLabel',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        final displayTime = baseTimestamp.add(
                          Duration(minutes: (touchedSpot.x * 60).round()),
                        );
                        final timeStr = _selectedRange == 'Day'
                            ? _formatChartTime(displayTime)
                            : _formatChartDate(displayTime);
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

  double? _getLatestForBiomarker(String biomarker) {
    switch (biomarker) {
      case 'Glucose': return _latestGlucose;
      case 'pH': return _latestPH;
      case 'K': return _latestK;
      case 'Na': return _latestNa;
      default: return _latestGlucose;
    }
  }

  double _getFallbackForBiomarker(String biomarker) {
    switch (biomarker) {
      case 'Glucose': return 85.0;
      case 'pH': return 7.35;
      case 'K': return 4.0;
      case 'Na': return 140.0;
      default: return 85.0;
    }
  }

  Widget _buildGkiCard() {
    final value = _getLatestForBiomarker(_selectedCardBiomarker) ?? _getFallbackForBiomarker(_selectedCardBiomarker);
    final unit = _getUnitForMetric(_selectedCardBiomarker);
    final isGlucose = _selectedCardBiomarker == 'Glucose';

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
                  'Current level',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedCardBiomarker,
                  items: _metricOptions
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCardBiomarker = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isGlucose ? value.toInt().toString() : value.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unit,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
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

  String _formatChartDate(DateTime timestamp) {
    final m = timestamp.month.toString().padLeft(2, '0');
    final d = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$m/$d $displayHour:$minute$period';
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
