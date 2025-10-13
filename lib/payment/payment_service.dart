import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  Razorpay? _razorpay;

  // ==================== INIT & DISPOSE ====================

  void initRazorpay({
    required VoidCallback onSuccess,
    required VoidCallback onFailure,
  }) {
    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse response) => onSuccess());
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse response) => onFailure());
  }

  void disposeRazorpay() {
    _razorpay?.clear();
  }

  // ==================== STRIPE PAYMENT ====================

  Future<void> startStripePayment({
    required String planName,
    required String amount,
    required BuildContext context,
  }) async {
    try {
      // Step 1: Create PaymentIntent on your backend
      final response = await http.post(
        Uri.parse("https://your-backend.com/create-payment-intent"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": amount,
          "currency": "inr",
          "plan": planName,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['clientSecret'] == null)
        throw Exception('Invalid payment intent');

      // Step 2: Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: data['clientSecret'],
          merchantDisplayName: 'Apna AI',
        ),
      );

      // Step 3: Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Payment Successful via Stripe")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Stripe Payment Failed: $e")),
      );
    }
  }

  // ==================== RAZORPAY PAYMENT ====================

  void startRazorpayPayment({
    required String planName,
    required double amount,
    required String email,
  }) {
    var options = {
      'key': 'rzp_test_yourKeyHere',
      'amount': (amount * 100).toInt(),
      'name': 'Apna AI',
      'description': planName,
      'prefill': {'contact': '', 'email': email},
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // ==================== PAYPAL PAYMENT ====================

  Future<void> startPayPalPayment({
    required String amount,
    required String currency,
  }) async {
    final url = Uri.parse(
        "https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_xclick&business=youremail@example.com&currency_code=$currency&amount=$amount");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ==================== GOOGLE PAY ====================

  Future<void> startGooglePay({
    required String amount,
    required BuildContext context,
  }) async {
    final gpayUrl =
        'upi://pay?pa=yourupi@okaxis&pn=ApnaAI&am=$amount&cu=INR&tn=GooglePay%20Subscription';
    if (await canLaunchUrl(Uri.parse(gpayUrl))) {
      await launchUrl(Uri.parse(gpayUrl), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Pay not available")),
      );
    }
  }

  // ==================== APPLE PAY ====================
/*
  Future<void> startApplePay({
    required String amount,
    required BuildContext context,
  }) async {
    try {
      await Stripe.instance.presentApplePay(
        params: ApplePayPresentParams(
          cartItems: [
            ApplePayCartSummaryItem(label: 'Apna AI Subscription', amount: amount)
          ],
          country: 'IN',
          currency: 'INR',
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Apple Pay failed: $e")),
      );
    }
  }
*/
  // ==================== UPI PAYMENT ====================

  Future<void> startUPIPayment({
    required String upiId,
    required String name,
    required String amount,
    String note = "Subscription Payment",
  }) async {
    final url = "upi://pay?pa=$upiId&pn=$name&am=$amount&cu=INR&tn=$note";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  // ==================== TEST PAYMENT ====================

  Future<void> startTestPayment({
    required BuildContext context,
    String planName = "Pro Plan",
    String amount = "0.00",
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate network delay

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "🧪 Test payment completed for $planName (Amount: ₹$amount)",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Here you can call your local success handler or callback:
    // PaymentSuccessHandler().onPaymentSuccess(planName);
  }
}
