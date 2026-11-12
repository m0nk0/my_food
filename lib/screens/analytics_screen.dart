import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as db; 
import '../providers/diary_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Map<String, dynamic>> _weekData = [];
  bool _isLoading = true;
  double _avgCalories = 0;
  double _totalWater = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final diary = Provider.of<DiaryProvider>(context, listen: false);
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final entries = await (diary.db.select(diary.db.diaryEntries)
            ..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay)))
          .get();
      final calories = entries.fold(0.0, (sum, item) => sum + item.calories);

      final waterEntries = await (diary.db.select(diary.db.waterEntries)
            ..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay)))
            .get();
      final water = waterEntries.fold(0.0, (sum, item) => sum + item.amountMl);

      data.add({
        'date': date,
        'calories': calories,
        'water': water,
      });
      
      _totalWater += water;
    }

    final totalCalories = data.fold(0.0, (sum, item) => sum + (item['calories'] as double));
    _avgCalories = totalCalories / 7;

    setState(() {
      _weekData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final maxCalories = _weekData.fold(2000.0, (max, item) => (item['calories'] as double) > max ? item['calories'] : max);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Аналитика', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Среднее ккал',
                    value: _avgCalories.toStringAsFixed(0),
                    color: Colors.green,
                    icon: Icons.local_fire_department,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Вода за неделю',
                    value: '${(_totalWater / 1000).toStringAsFixed(1)} л',
                    color: Colors.blue,
                    icon: Icons.water_drop,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Text('Калории за неделю', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 310, // Увеличили высоту, чтобы убрать переполнение
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20), 
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Stack(
                children: [
                  // Сетка
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      return const Divider(color: Color(0xFFEAEAEA), thickness: 1, height: 1);
                    }),
                  ),
                  // Столбики
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _weekData.map<Widget>((day) {
                      final calories = day['calories'] as double;
                      final date = day['date'] as DateTime;
                      final isToday = date.day == DateTime.now().day && 
                                      date.month == DateTime.now().month && 
                                      date.year == DateTime.now().year;
                      
                      final barHeight = (calories / maxCalories).clamp(0.0, 1.0) * 200;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            calories.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 11, 
                              color: isToday ? Colors.green.shade700 : Colors.grey, 
                              fontWeight: isToday ? FontWeight.w900 : FontWeight.normal
                            ),
                          ),
                          const SizedBox(height: 6),
                          Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: 32,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              Container(
                                width: 32,
                                height: barHeight < 4 ? 4 : barHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: isToday 
                                      ? [Colors.green.shade400, Colors.green.shade600]
                                      : [Colors.green.shade100, Colors.green.shade200],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('E', 'ru_RU').format(date),
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                              color: isToday ? Colors.black : Colors.grey
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}