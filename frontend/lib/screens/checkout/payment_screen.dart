import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_button.dart';
import '../orders/order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'UPI'; // UPI, WALLET, CARD, CASH
  String _selectedUpiApp = 'Google Pay';
  final TextEditingController _upiIdController = TextEditingController(text: 'student@okhdfcbank');
  final TextEditingController _cardNumberController = TextEditingController(text: '4532 •••• •••• 8821');
  bool _isProcessing = false;

  @override
  void dispose() {
    _upiIdController.dispose();
    _cardNumberController.dispose();
    super.dispose();
  }

  void _processPayment() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_selectedMethod == 'WALLET' && (auth.user?.walletBalance ?? 0) < cart.grandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient Canteen Wallet balance! Top up or choose UPI.'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // If UPI, show mock 4-digit PIN dialog
    if (_selectedMethod == 'UPI') {
      final pinEntered = await _showMockUpiPinDialog();
      if (!pinEntered) {
        setState(() => _isProcessing = false);
        return;
      }
    }

    // Place order
    final order = await orderProv.placeOrder(
      cartItems: cart.items,
      paymentMethod: _selectedMethod,
      specialNotes: cart.orderNotes,
    );

    if (order != null) {
      // Process payment
      final success = await orderProv.payForOrder(
        orderId: order.id,
        paymentMethod: _selectedMethod,
        amount: order.totalAmount,
        upiId: _selectedMethod == 'UPI' ? _upiIdController.text : null,
      );

      setState(() => _isProcessing = false);

      if (success && mounted) {
        cart.clearCart();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(order: orderProv.currentActiveOrder ?? order),
          ),
        );
      }
    } else {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to place order. Please try again.'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  Future<bool> _showMockUpiPinDialog() async {
    String enteredPin = '';
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  backgroundColor: AppTheme.cardDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: [
                      const Icon(Icons.security, color: AppTheme.primaryRed, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Enter 4-Digit UPI PIN',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Demo UPI Simulator (Enter any 4 digits, e.g. 1234)',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          bool filled = index < enteredPin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? AppTheme.primaryRed : Colors.transparent,
                              border: Border.all(color: AppTheme.primaryRed, width: 2),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      // Keypad
                      SizedBox(
                        width: 220,
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 3,
                          childAspectRatio: 1.4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            ...List.generate(9, (index) {
                              return InkWell(
                                onTap: () {
                                  if (enteredPin.length < 4) {
                                    setDialogState(() => enteredPin += '${index + 1}');
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardElevated,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            InkWell(
                              onTap: () {
                                Navigator.of(ctx).pop(false);
                              },
                              child: const Center(
                                child: Icon(Icons.close, color: AppTheme.textMuted),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (enteredPin.length < 4) {
                                  setDialogState(() => enteredPin += '0');
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.cardElevated,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    '0',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (enteredPin.isNotEmpty) {
                                  setDialogState(() => enteredPin = enteredPin.substring(0, enteredPin.length - 1));
                                }
                              },
                              child: const Center(
                                child: Icon(Icons.backspace_outlined, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                    ElevatedButton(
                      onPressed: enteredPin.length == 4 ? () => Navigator.of(ctx).pop(true) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text('SUBMIT PIN'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Mock Payment Gateway'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Summary Badge
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.cardDark, AppTheme.cardElevated],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Payable Amount',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${cart.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.primaryRedLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryRed),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: AppTheme.primaryRed, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'DEMO GATEWAY',
                          style: TextStyle(color: AppTheme.primaryRed, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Select Payment Option',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 14),

            // Option 1: Instant UPI Apps
            _buildPaymentOptionCard(
              id: 'UPI',
              title: 'Instant UPI (Google Pay, PhonePe, Paytm)',
              subtitle: 'Fastest payment simulation with mock PIN',
              icon: Icons.qr_code_2_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: ['Google Pay', 'PhonePe', 'Paytm'].map((app) {
                      bool isAppSel = _selectedUpiApp == app;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(app),
                          selected: isAppSel,
                          selectedColor: AppTheme.primaryRed,
                          backgroundColor: AppTheme.cardElevated,
                          labelStyle: TextStyle(
                            color: isAppSel ? Colors.white : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setState(() => _selectedUpiApp = app),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _upiIdController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'student@upi',
                      prefixIcon: Icon(Icons.alternate_email, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Option 2: Student Meal Card / Wallet
            _buildPaymentOptionCard(
              id: 'WALLET',
              title: 'Student Canteen Wallet / Meal Card',
              subtitle: 'Available Balance: ₹${(auth.user?.walletBalance ?? 500).toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet_rounded,
              child: ((auth.user?.walletBalance ?? 0) < cart.grandTotal)
                  ? const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        '⚠️ Balance low for this order.',
                        style: TextStyle(color: AppTheme.primaryRedLight, fontSize: 12),
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        '✓ One-click debit from college account',
                        style: TextStyle(color: AppTheme.successGreen, fontSize: 12),
                      ),
                    ),
            ),
            const SizedBox(height: 14),

            // Option 3: Credit/Debit Card
            _buildPaymentOptionCard(
              id: 'CARD',
              title: 'Credit / Debit Card Simulator',
              subtitle: 'Visa, MasterCard, RuPay',
              icon: Icons.credit_card_rounded,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextField(
                  controller: _cardNumberController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.credit_card, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Option 4: Cash on Counter
            _buildPaymentOptionCard(
              id: 'CASH',
              title: 'Pay at Canteen Counter',
              subtitle: 'Pay cash directly when picking up your token',
              icon: Icons.payments_outlined,
            ),
            const SizedBox(height: 30),

            // Submit Payment Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'PAY ₹${cart.grandTotal.toStringAsFixed(0)} & CONFIRM',
                isLoading: _isProcessing,
                icon: Icons.lock_outline,
                onPressed: _processPayment,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? child,
  }) {
    final isSelected = _selectedMethod == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : AppTheme.borderDark,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryRed.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryRed.withOpacity(0.2) : AppTheme.cardElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppTheme.primaryRed : AppTheme.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Radio<String>(
                  value: id,
                  groupValue: _selectedMethod,
                  activeColor: AppTheme.primaryRed,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMethod = val);
                  },
                ),
              ],
            ),
            if (isSelected && child != null) child,
          ],
        ),
      ),
    );
  }
}
