
import 'package:delivery_app_mvvm/viewmodel/earning_viewmodel.dart';
import 'package:delivery_app_mvvm/widget/earning_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EarningPage extends StatefulWidget {
  const EarningPage({super.key});

  @override
  State<EarningPage> createState() => _EarningPageState();
}

class _EarningPageState extends State<EarningPage> {
  @override
  void initState() {
    super.initState();
    // Fetch initial earnings data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<EarningViewModel>(context, listen: false);
      viewModel.setDateRangeToLast7Days(); // Default to last 7 days
    });
  }

  @override
  Widget build(BuildContext context) {
    final earningViewModel = Provider.of<EarningViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganancias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
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
                  onRefresh: () => earningViewModel.fetchEarnings(
                      earningViewModel.startDate, earningViewModel.endDate),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            earningViewModel.getFormattedDateRange(),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${earningViewModel.getTotalAmount().toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryCard(
                                  context, 'Orders', earningViewModel.getTotalOrders().toString()),
                              _buildSummaryCard(
                                  context, 'Online', '${earningViewModel.getTotalOnlineHours()}h ${earningViewModel.getTotalOnlineHours() % 1 * 60 ~/ 1}m'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => earningViewModel.setDateRangeToLast7Days(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        earningViewModel.startDate.difference(earningViewModel.endDate).inDays == -6
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[300],
                                    foregroundColor:
                                        earningViewModel.startDate.difference(earningViewModel.endDate).inDays == -6
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  child: const Text('Day'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => earningViewModel.setDateRangeToLast30Days(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        earningViewModel.startDate.difference(earningViewModel.endDate).inDays == -29
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[300],
                                    foregroundColor:
                                        earningViewModel.startDate.difference(earningViewModel.endDate).inDays == -29
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  child: const Text('Month'),
                                ),
                              ),
                              // You can add a "Year" button if needed
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Earning Chart
                          if (earningViewModel.dailyEarnings.isNotEmpty)
                            EarningChart(dailyEarnings: earningViewModel.dailyEarnings)
                          else
                            const Center(child: Text('No hay datos de ganancias para mostrar en el gráfico.')),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent orders',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to all orders page
                                },
                                child: const Text('See all'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // List of recent orders (using dummy data for now)
                          _buildRecentOrderCard(context, 'Saturday', '17/06/2023', '#123', '31.23'),
                          _buildRecentOrderCard(context, 'Monday', '19/06/2023', '#567', '61.23'),
                          _buildRecentOrderCard(context, 'Tuesday', '20/06/2023', '#890', '25.00'),
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
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrderCard(BuildContext context, String dayOfWeek, String date, String orderId, String amount) {
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
                  'Order $orderId',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '+\$$amount',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            // You can add more details like delivery address, item count, etc.
          ],
        ),
      ),
    );
  }
}