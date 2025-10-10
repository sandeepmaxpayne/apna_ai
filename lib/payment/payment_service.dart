import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:upi_india/upi_india.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  Razorpay? _razorpay;

  void initRazorpay({
    required Function(String) onSuccess,
    required Function(String) onError,
  }) {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS,
            (PaymentSuccessResponse res) => onSuccess(res.paymentId ?? ''));
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR,
            (PaymentFailureResponse res) => onError(res.message ?? 'Error'));
  }

  void disposeRazorpay() => _razorpay?.clear();

  Future<void> startRazorpay({
    required String name,
    required double amount,
    required String email,
  }) async {
    var options = {
      'key': 'rzp_test_xxxxxxxx', // replace with your Razorpay key
      'amount': (amount * 100).toInt(),
      'name': name,
      'description': 'SkillSwap Offer Payment',
      'prefill': {'contact': '', 'email': email},
      'theme': {'color': '#0A657E'}
    };
    _razorpay!.open(options);
  }

  // ---------------- Stripe ---------------
  Future<void> startStripePayment({
    required String amount,
    required String currency,
  }) async {
    // backend should create PaymentIntent; below is demo only
    Stripe.publishableKey = "pk_test_XXXXXXX";
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'SkillSwap',
        style: ThemeMode.light,
        appearance: const PaymentSheetAppearance(),
      ),
    );
    await Stripe.instance.presentPaymentSheet();
  }

  // ---------------- Google Pay (UPI) ---------------
  Future<void> startUpiPayment({
    required double amount,
    required String receiverUpiId,
    required String name,
  }) async {
    UpiIndia upiIndia = UpiIndia();
    await upiIndia.startTransaction(
      app: UpiApp.googlePay,
      receiverUpiId: receiverUpiId,
      receiverName: name,
      transactionRefId: "SS${DateTime.now().millisecondsSinceEpoch}",
      transactionNote: "SkillSwap Premium",
      amount: amount,
    );
  }

  // ---------------- PayPal ----------------
  Future<void> startPayPal({
    required String clientId,
    required String secret,
    required double amount,
    required String currency,
  }) async {
    // Fetch Access Token
    var res = await http.post(
      Uri.parse('https://api-m.sandbox.paypal.com/v1/oauth2/token'),
      headers: {'Accept': 'application/json', 'Accept-Language': 'en_US'},
      body: {'grant_type': 'client_credentials'},
      encoding: Encoding.getByName('utf-8'),
    );
    if (res.statusCode == 200) {
      var data = jsonDecode(res.body);
      debugPrint("PayPal token: ${data['access_token']}");
      // Next step: create order and redirect to approval link (webview)
    }
  }
}
