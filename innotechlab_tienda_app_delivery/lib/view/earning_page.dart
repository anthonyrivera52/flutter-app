import 'package:delivery_app_mvvm/viewmodel/earning_viewmodel.dart';
import 'package:delivery_app_mvvm/widget/earning_chart.dart'; // Make sure this path is correct
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting

class EarningPage extends StatefulWidget {
  const EarningPage({super.key});

  @override
  State<EarningPage> createState() => _EarningPageState();
}

class _EarningPageState extends State<EarningPage> {
  // This date will represent *any* day within the week currently being displayed.
  // It's used to tell the ViewModel which week to fetch.
  DateTime _currentDateInDisplayedWeek = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Fetch earnings for the week that includes today when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<EarningViewModel>(context, listen: false);
      viewModel.fetchEarningsForWeekOf(_currentDateInDisplayedWeek);
    });
  }

  // Helper method to find the Monday of a given week.
  // This is used for UI comparison (e.g., highlighting 'Current Week' button).
  // The actual week calculation should ideally happen within the ViewModel.
  DateTime _findMondayOfWeekForUI(DateTime date) {
    int daysToSubtract = date.weekday - 1; // Monday is 1. If today is Monday (1), subtract 0. If Tuesday (2), subtract 1.
    DateTime monday = date.subtract(Duration(days: daysToSubtract));
    return DateTime(monday.year, monday.month, monday.day); // Normalize to midnight
  }

  DateTime _findSundayOfWeekForUI(DateTime date) {
    DateTime monday = _findMondayOfWeekForUI(date);
    DateTime sunday = monday.add(const Duration(days: 6));
    return DateTime(sunday.year, sunday.month, sunday.day); // Normalize to midnight
  }

  @override
  Widget build(BuildContext context) {
    final earningViewModel = Provider.of<EarningViewModel>(context);

    // Calculate the start/end of the actual current week (today's week) for button highlighting
    DateTime actualCurrentWeekMonday = _findMondayOfWeekForUI(DateTime.now());
    DateTime actualCurrentWeekSunday = _findSundayOfWeekForUI(DateTime.now());

    // Check if the ViewModel's currently displayed week matches the actual current week
    bool isDisplayingCurrentWeek =
        earningViewModel.startDate.isAtSameMomentAs(actualCurrentWeekMonday) &&
        earningViewModel.endDate.isAtSameMomentAs(actualCurrentWeekSunday);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ganancias',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
            color: Colors.white,
          ),
        ],
      ),
      body: earningViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : earningViewModel.errorMessage != null
              ? Center(
                  child: Text(
                    'Error: ${earningViewModel.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => earningViewModel.fetchEarningsForWeekOf(_currentDateInDisplayedWeek),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom Week Navigation Header (Uber-like)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios),
                                onPressed: () {
                                  setState(() {
                                    _currentDateInDisplayedWeek = _currentDateInDisplayedWeek.subtract(const Duration(days: 7));
                                  });
                                  earningViewModel.fetchEarningsForWeekOf(_currentDateInDisplayedWeek);
                                },
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      earningViewModel.getFormattedWeekRange(),
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    // Optional: You can add smaller text here like "Weekly Earnings"
                                    // const Text('Weekly Earnings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios),
                                onPressed: () {
                                  setState(() {
                                    _currentDateInDisplayedWeek = _currentDateInDisplayedWeek.add(const Duration(days: 7));
                                  });
                                  earningViewModel.fetchEarningsForWeekOf(_currentDateInDisplayedWeek);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Total Earnings for the week
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Total Ganancias',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${earningViewModel.getTotalAmount().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Summary Cards (Orders, Online Hours)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryCard(
                                  context, 'Órdenes', earningViewModel.getTotalOrders().toString()),
                              _buildSummaryCard(
                                  context, 'Horas en línea', '${earningViewModel.getTotalOnlineHours()}h'),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // "Current Week" button
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _currentDateInDisplayedWeek = DateTime.now(); // Reset to today
                                });
                                earningViewModel.fetchEarningsForWeekOf(_currentDateInDisplayedWeek);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDisplayingCurrentWeek
                                        ? Theme.of(context).primaryColor // Highlight if current week
                                        : Colors.grey[300],
                                foregroundColor: isDisplayingCurrentWeek
                                        ? Colors.white
                                        : Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Semana Actual'),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Earning Chart
                          const Text(
                            'Ganancias Diarias',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: earningViewModel.dailyEarnings.isNotEmpty
                                ? EarningChart(dailyEarnings: earningViewModel.dailyEarnings)
                                : const Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Center(
                                      child: Text('No hay datos de ganancias para mostrar en el gráfico para esta semana.', textAlign: TextAlign.center),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),

                          // Recent Orders (Daily breakdown)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Detalle por día', // Changed to reflect daily breakdown
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              // You might still want a "See all" for historical data outside the week
                              TextButton(
                                onPressed: () {
                                  // Navigate to a page with all historical orders
                                },
                                child: const Text('Ver historial'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (earningViewModel.earnings.isNotEmpty)
                            ...earningViewModel.earnings.map((earning) {
                              return _buildRecentOrderCard(
                                context,
                                DateFormat('EEEE', 'es_ES').format(DateTime.parse(earning.date.toString())),
                                DateFormat('dd/MM/yyyy').format(DateTime.parse(earning.date.toString())),
                                earning.ordersCount, // Pass as int
                                earning.amount.toStringAsFixed(2),
                              );
                            }).toList()
                          else
                            const Center(child: Text('No hay pedidos recientes en este rango.')),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Renamed orderId to orderCount for clarity as it reflects number of orders
  Widget _buildRecentOrderCard(BuildContext context, String dayOfWeek, String date, int orderCount, String amount) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$dayOfWeek $date',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Órdenes: $orderCount', // Display actual order count
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '+\$$amount',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}