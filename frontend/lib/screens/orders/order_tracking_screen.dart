import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_button.dart';
import '../main_navigation_screen.dart';
import '../support/customer_care_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  int _getStepIndex(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 0;
      case 'PAID':
      case 'PREPARING':
        return 1;
      case 'READY_FOR_PICKUP':
        return 2;
      case 'COMPLETED':
        return 3;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProv, child) {
        final currentOrder = orderProv.currentActiveOrder ?? order;
        final currentStep = _getStepIndex(currentOrder.status);

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(
            title: const Text('Live Order Status'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Status',
                onPressed: () => orderProv.fetchOrders(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Token Display Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: currentStep == 2 ? AppTheme.successGreen : AppTheme.primaryRed,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (currentStep == 2 ? AppTheme.successGreen : AppTheme.primaryRed).withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ORDER TOKEN NUMBER',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentOrder.tokenNumber,
                            style: TextStyle(
                              color: currentStep == 2 ? AppTheme.successGreen : AppTheme.primaryRedLight,
                              fontWeight: FontWeight.w900,
                              fontSize: 32,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: (currentStep == 2 ? AppTheme.successGreen : AppTheme.primaryRed).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          currentOrder.status.replaceAll('_', ' '),
                          style: TextStyle(
                            color: currentStep == 2 ? AppTheme.successGreen : AppTheme.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Live Order Progress',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Stepper Timeline
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Column(
                    children: [
                      _buildStepTile(
                        stepNumber: 1,
                        title: 'Order Placed & Confirmed',
                        subtitle: 'Payment verified, sent to kitchen',
                        isDone: currentStep >= 0,
                        isActive: currentStep == 0,
                        isLast: false,
                        icon: Icons.check_circle_outline,
                      ),
                      _buildStepTile(
                        stepNumber: 2,
                        title: 'Kitchen Cooking & Preparing',
                        subtitle: 'Chefs are preparing your meal fresh',
                        isDone: currentStep >= 1,
                        isActive: currentStep == 1,
                        isLast: false,
                        icon: Icons.soup_kitchen_outlined,
                      ),
                      _buildStepTile(
                        stepNumber: 3,
                        title: 'Ready for Counter Pickup',
                        subtitle: 'Please proceed to Canteen Counter #2',
                        isDone: currentStep >= 2,
                        isActive: currentStep == 2,
                        isLast: false,
                        icon: Icons.notifications_active_outlined,
                      ),
                      _buildStepTile(
                        stepNumber: 4,
                        title: 'Food Collected',
                        subtitle: 'Enjoy your meal!',
                        isDone: currentStep >= 3,
                        isActive: currentStep == 3,
                        isLast: true,
                        icon: Icons.emoji_emotions_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Demo Helper Card for Assignment Evaluation
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.touch_app, color: AppTheme.accentGold, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Demo State Simulator (For Viva / Demo)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => orderProv.markOrderCompleted(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: const BorderSide(color: AppTheme.accentGold),
                              ),
                              child: const Text('Mark Collected', style: TextStyle(color: AppTheme.accentGold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerCareScreen(initialToken: currentOrder.tokenNumber),
                        ),
                      );
                    },
                    icon: const Icon(Icons.support_agent_rounded, color: AppTheme.accentGold, size: 18),
                    label: const Text('NEED HELP WITH THIS ORDER?', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.accentGold, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'BACK TO HOME SCREEN',
                    isOutlined: true,
                    icon: Icons.home_rounded,
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepTile({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    required bool isLast,
    required IconData icon,
  }) {
    Color stepColor;
    if (isDone) {
      stepColor = AppTheme.successGreen;
    } else if (isActive) {
      stepColor = AppTheme.primaryRed;
    } else {
      stepColor = AppTheme.borderDark;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppTheme.successGreen.withOpacity(0.2) : AppTheme.cardElevated,
                border: Border.all(color: stepColor, width: 2),
              ),
              child: Icon(
                icon,
                color: isDone ? AppTheme.successGreen : (isActive ? AppTheme.primaryRed : AppTheme.textMuted),
                size: 18,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone ? AppTheme.successGreen : AppTheme.borderDark,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDone || isActive ? Colors.white : AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
