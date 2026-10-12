import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/food_item.dart';
import 'package:frontend/models/order.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/cart_provider.dart';
import 'package:frontend/providers/menu_provider.dart';
import 'package:frontend/providers/order_provider.dart';
import 'package:frontend/screens/auth/auth_screen.dart';
import 'package:frontend/screens/cart/cart_screen.dart';
import 'package:frontend/screens/checkout/payment_screen.dart';
import 'package:frontend/screens/food_detail/food_detail_screen.dart';
import 'package:frontend/screens/home/home_screen.dart';
import 'package:frontend/screens/orders/order_success_screen.dart';
import 'package:frontend/screens/orders/order_tracking_screen.dart';
import 'package:frontend/screens/profile/profile_screen.dart';

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

Widget createTestApp(Widget child, {CartProvider? cart, OrderProvider? order, required GlobalKey boundaryKey}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => MenuProvider()),
      ChangeNotifierProvider(create: (_) => cart ?? CartProvider()),
      ChangeNotifierProvider(create: (_) => order ?? OrderProvider()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: RepaintBoundary(
        key: boundaryKey,
        child: child,
      ),
    ),
  );
}

Future<void> saveScreenshot(GlobalKey key, String filename) async {
  final outputDir = Directory('../screenshots');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final Uint8List pngBytes = byteData!.buffer.asUint8List();

  final file = File('../screenshots/$filename');
  await file.writeAsBytes(pngBytes);
  debugPrint('Saved screenshot: ../screenshots/$filename');
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Capture Screen: 01_auth_login', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 2, 915 * 2);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();
    await tester.pumpWidget(createTestApp(const AuthScreen(), boundaryKey: key));
    await tester.pump(const Duration(milliseconds: 200));
    await saveScreenshot(key, '01_auth_login.png');
  });

  testWidgets('Capture Screen: 02_home_menu', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 2, 915 * 2);
    tester.view.devicePixelRatio = 2.0;

    final cart = CartProvider();
    final item1 = FoodItem(
      id: 1,
      name: 'Masala Dosa with Chutneys',
      category: 'Breakfast',
      price: 60.0,
      isVeg: true,
      isAvailable: true,
      description: 'Crispy golden crepe filled with spiced potato masala, served with 2 chutneys and sambar.',
      rating: 4.8,
      prepTimeMinutes: 8,
      imageUrl: '',
      calories: 320,
    );
    cart.addItem(item1, quantity: 2);

    final key = GlobalKey();
    await tester.pumpWidget(createTestApp(const HomeScreen(), cart: cart, boundaryKey: key));
    await tester.pump(const Duration(milliseconds: 200));
    await saveScreenshot(key, '02_home_menu.png');
  });

  testWidgets('Capture Screen: 03_food_detail', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 2, 915 * 2);
    tester.view.devicePixelRatio = 2.0;

    final item = FoodItem(
      id: 4,
      name: 'Paneer Butter Masala Meal Combo',
      category: 'Lunch',
      price: 130.0,
      isVeg: true,
      isAvailable: true,
      description: 'Rich creamy paneer butter masala, 2 butter rotis, jeera rice, salad and gulab jamun.',
      rating: 4.9,
      prepTimeMinutes: 12,
      imageUrl: '',
      calories: 650,
    );

    final key = GlobalKey();
    await tester.pumpWidget(createTestApp(FoodDetailScreen(item: item), boundaryKey: key));
    await tester.pump(const Duration(milliseconds: 200));
    await saveScreenshot(key, '03_food_detail.png');
  });

  testWidgets('Capture Screen: 04_cart_summary', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 2, 915 * 2);
    tester.view.devicePixelRatio = 2.0;

    final cart = CartProvider();
    final item1 = FoodItem(
      id: 1,
      name: 'Masala Dosa with Chutneys',
      category: 'Breakfast',
      price: 60.0,
      isVeg: true,
      isAvailable: true,
      description: 'Crispy golden crepe',
      rating: 4.8,
      prepTimeMinutes: 8,
      imageUrl: '',
      calories: 320,
    );
    final item2 = FoodItem(
      id: 8,
      name: 'Special Filter Coffee',
      category: 'Beverages',
      price: 25.0,
      isVeg: true,
      isAvailable: true,
      description: 'Hot filter coffee',
      rating: 4.9,
      prepTimeMinutes: 3,
      imageUrl: '',
      calories: 90,
    );
    cart.addItem(item1, quantity: 2);
    cart.addItem(item2, quantity: 1);
    cart.applyCoupon('CANTEEN20');

    final key = GlobalKey();
    await tester.pumpWidget(createTestApp(const CartScreen(), cart: cart, boundaryKey: key));
    await tester.pump(const Duration(milliseconds: 200));
    await saveScreenshot(key, '04_cart_summary.png');
  });

  testWidgets('Capture Screen: 05_mock_payment', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 2, 915 * 2);
    tester.view.devicePixelRatio = 2.0;

    final cart = CartProvider();
    final item1 = FoodItem(
      id: 1,
      name: 'Masala Dosa with Chutneys',
      category: 'Breakfast',
      price: 60.0,
      isVeg: true,
      isAvailable: true,
      description: 'Crispy golden crepe',
      rating: 4.8,
      prepTimeMinutes: 8,
      imageUrl: '',
      calories: 320,
    );
    cart.addItem(item1, quantity: 2);

    final key = GlobalKey();
    await tester.pumpWidget(createTestApp(const PaymentScreen(), cart: cart, boundaryKey: key));
    await tester.pump(const Duration(milliseconds: 200));
    await saveScreenshot(key, '05_mock_payment.png');
  });

  testWidgets('Capture Screen: 06_order_confirmation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 2, 915 * 2);
    tester.view.devicePixelRatio = 2.0;

    final order = OrderModel(
      id: 1024,
      userId: 1,
      tokenNumber: '#C-248',
      subtotal: 145.0,
      tax: 7.25,
      packagingFee: 10.0,
      discount: 21.75,
      totalAmount: 140.50,
      status: 'PAID',
      paymentMethod: 'UPI (Google Pay)',
      paymentStatus: 'PAID',
      specialNotes: 'Less spicy please',
      items: [
        OrderItemModel(
          id: 1,
          orderId: 1024,
          foodItemId: 1,
          foodName: 'Masala Dosa with Chutneys',
          quantity: 2,
          unitPrice: 60.0,
          totalPrice: 120.0,
        ),
        OrderItemModel(
          id: 2,
          orderId: 1024,
          foodItemId: 8,
          foodName: 'Special Filter Coffee',
          quantity: 1,
          unitPrice: 25.0,
          totalPrice: 25.0,
        ),
      ],
      createdAt: DateTime.now(),
    );

    final key = GlobalKey();
    await tester.pumpWidget(createTestApp(OrderSuccessScreen(order: order), boundaryKey: key));
    await tester.pump(const Duration(milliseconds: 200));
    await saveScreenshot(key, '06_order_confirmation.png');
  });

  testWidgets('Capture Screen: 07_order_tracking', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 2, 915 * 2);
    tester.view.devicePixelRatio = 2.0;

    final order = OrderModel(
      id: 1024,
      userId: 1,
      tokenNumber: '#C-248',
      subtotal: 145.0,
      tax: 7.25,
      packagingFee: 10.0,
      discount: 21.75,
      totalAmount: 140.50,
      status: 'PREPARING',
      paymentMethod: 'UPI',
      paymentStatus: 'PAID',
      specialNotes: '',
      items: [],
      createdAt: DateTime.now(),
    );

    final key = GlobalKey();
    await tester.pumpWidget(createTestApp(OrderTrackingScreen(order: order), boundaryKey: key));
    await tester.pump(const Duration(milliseconds: 200));
    await saveScreenshot(key, '07_order_tracking.png');
  });

  testWidgets('Capture Screen: 08_student_profile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 2, 915 * 2);
    tester.view.devicePixelRatio = 2.0;

    final key = GlobalKey();
    await tester.pumpWidget(createTestApp(const ProfileScreen(), boundaryKey: key));
    await tester.pump(const Duration(milliseconds: 200));
    await saveScreenshot(key, '08_student_profile.png');
  });
}
