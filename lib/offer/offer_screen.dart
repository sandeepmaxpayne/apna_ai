import 'dart:async';

import 'package:apna_ai/animation/animated_page_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../payment/payment_failed.dart';
import '../payment/payment_service.dart';
import '../payment/payment_success.dart';

class OfferPage extends StatefulWidget {
  const OfferPage({super.key});

  @override
  State<OfferPage> createState() => _OfferPageState();
}

class _OfferPageState extends State<OfferPage> {
  String _selectedCurrency = 'USD';
  bool _isMonthly = true;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  DateTime? _endTime;

  static const Duration _offerDuration = Duration(hours: 5, minutes: 30);
  static const Duration _resetWindow = Duration(hours: 24);

  final List<String> currencies = [
    'USD',
    'EUR',
    'INR',
    'GBP',
    'AUD',
    'CAD',
    'JPY'
  ];

  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _initTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _paymentService.disposeRazorpay();
    super.dispose();
  }

  // ---------------- TIMER ----------------
  Future<void> _initTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('offer_end_time');
    DateTime end;

    if (saved == null) {
      end = DateTime.now().add(_offerDuration);
      await prefs.setInt('offer_end_time', end.millisecondsSinceEpoch);
    } else {
      end = DateTime.fromMillisecondsSinceEpoch(saved);
      if (DateTime.now().isAfter(end.add(_resetWindow))) {
        end = DateTime.now().add(_offerDuration);
        await prefs.setInt('offer_end_time', end.millisecondsSinceEpoch);
      }
    }

    _endTime = end;
    _updateRemaining(end);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      final now = DateTime.now();
      if (_endTime == null) _endTime = now.add(_offerDuration);
      if (_endTime!.isAfter(now)) {
        _updateRemaining(_endTime!);
      } else {
        final expiredSince = now.difference(_endTime!);
        if (expiredSince < _resetWindow) {
          _endTime = _endTime!.add(_resetWindow);
        } else {
          _endTime = now.add(_offerDuration);
        }
        await prefs.setInt('offer_end_time', _endTime!.millisecondsSinceEpoch);
        _updateRemaining(_endTime!);
      }
    });
  }

  void _updateRemaining(DateTime endTime) {
    final now = DateTime.now();
    setState(() => _remaining =
        endTime.isAfter(now) ? endTime.difference(now) : Duration.zero);
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  // ---------------- PRICES ----------------
  Map<String, Map<String, num>> get priceMap => {
        'USD': {'pro': 19.99, 'unlimited': 29.99},
        'EUR': {'pro': 18.49, 'unlimited': 27.99},
        'INR': {'pro': 1499, 'unlimited': 2299},
        'GBP': {'pro': 15.99, 'unlimited': 24.99},
        'AUD': {'pro': 29.99, 'unlimited': 44.99},
        'CAD': {'pro': 27.99, 'unlimited': 42.49},
        'JPY': {'pro': 2999, 'unlimited': 4499},
      };

  String _currencySymbol(String code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'INR':
        return '₹';
      case 'GBP':
        return '£';
      case 'AUD':
        return 'A\$';
      case 'CAD':
        return 'C\$';
      case 'JPY':
        return '¥';
      default:
        return code;
    }
  }

  String _formatPrice(num value, String symbol) {
    final v = value.toDouble();
    final formatted =
        v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
    return '$symbol$formatted';
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final currencyData = priceMap[_selectedCurrency]!;
    final symbol = _currencySymbol(_selectedCurrency);
    final pro = currencyData['pro']!.toDouble();
    final unlimited = currencyData['unlimited']!.toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F0FF), Color(0xFFFFFFFF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("⚡ Flash Sale!",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text(
                      _remaining.inSeconds > 0
                          ? "Ends in ${_formatTime(_remaining)}"
                          : "Offer Ended!",
                      style: TextStyle(
                          color: _remaining.inSeconds > 0
                              ? Colors.redAccent
                              : Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ).animate().fadeIn(duration: 800.ms),
                    const SizedBox(height: 6),
                    Text("Save up to 50% — renewed daily!",
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 15)),
                    const SizedBox(height: 12),
                    _buildTopControls(),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildOfferRow(symbol, pro, unlimited),
                  const SizedBox(height: 30),
                  const Text("Secure Payments • Cancel Anytime",
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- TOP CONTROLS ----------------
  Widget _buildTopControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Currency dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrency,
              items: currencies
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCurrency = val!),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Monthly / Annual toggle
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300)),
          child: Row(children: [
            _buildToggle("Monthly", _isMonthly),
            _buildToggle("Annually", !_isMonthly)
          ]),
        ),
        const SizedBox(width: 8),
        const Text("Save 50%",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildToggle(String text, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _isMonthly = (text == "Monthly")),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: active ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(30)),
        child: Text(text,
            style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ---------------- OFFER CARDS ----------------
  Widget _buildOfferRow(String symbol, double pro, double unlimited) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildOfferCard(
            title: "HIX AI Unlimited",
            price: _isMonthly ? unlimited : unlimited * 10,
            highlightColor: Colors.pinkAccent,
            plan: "Unlimited",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildOfferCard(
            title: "HIX AI Pro",
            price: _isMonthly ? pro : pro * 10,
            highlightColor: Colors.blueAccent,
            plan: "Pro",
          ),
        ),
      ],
    );
  }

  Widget _buildOfferCard({
    required String title,
    required double price,
    required Color highlightColor,
    required String plan,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("🔥 Flash Sale",
            style:
                TextStyle(fontWeight: FontWeight.bold, color: highlightColor)),
        const SizedBox(height: 12),
        Text(title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: highlightColor)),
        const SizedBox(height: 8),
        Text(
          "${_currencySymbol(_selectedCurrency)}${price.toStringAsFixed(2)}"
          "${_isMonthly ? '/mo' : '/yr'}",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: highlightColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(double.infinity, 45)),
          onPressed: () =>
              _showPaymentOptions(context, plan, price, _selectedCurrency),
          child: Text("Buy ${_isMonthly ? 'Monthly' : 'Yearly'}",
              style: const TextStyle(color: Colors.white)),
        ),
      ]),
    );
  }

  // ---------------- PAYMENT LOGIC ----------------
  void _showPaymentOptions(
      BuildContext context, String plan, double price, String currency) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              // 💜 Razorpay
              ListTile(
                title: const Text("💜 Razorpay"),
                onTap: () {
                  Navigator.pop(context);
                  _payWithRazorpay(plan, price);
                },
              ),

              // 🟣 Stripe
              ListTile(
                title: const Text("🟣 Stripe"),
                onTap: () async {
                  Navigator.pop(context);
                  await _paymentService.startStripePayment(
                    planName: plan,
                    amount: price.toStringAsFixed(2),
                    context: context,
                  );
                },
              ),

              // 🟢 UPI / Google Pay
              ListTile(
                title: const Text("🟢 Google Pay / UPI"),
                onTap: () async {
                  Navigator.pop(context);
                  await _paymentService.startUPIPayment(
                    name: plan,
                    upiId: 'yourupiid@okaxis',
                    amount: price.toStringAsFixed(2),
                  );
                },
              ),

              // 🧪 Test Mode
              ListTile(
                title: const Text("🧪 Test Payment"),
                onTap: () async {
                  Navigator.pop(context);
                  await _paymentService.startTestPayment(
                    context: context,
                    planName: plan,
                    amount: price.toStringAsFixed(2),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _payWithRazorpay(String plan, double price) {
    _paymentService.initRazorpay(
      onSuccess: () => _showSuccess(context, "Razorpay", "1234567890"),
      onFailure: () => _showError(context, "Payment failed"),
    );

    _paymentService.startRazorpayPayment(
      amount: price,
      email: "user@test.com",
      planName: plan,
    );
  }

  void _showSuccess(BuildContext context, String gateway, String id) {
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: PaymentSuccessScreen(
          gateway: gateway,
          transactionId: id,
          amount: 0.0,
          currency: _selectedCurrency,
          onContinue: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String error) {
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: PaymentFailedScreen(
          gateway: "Unknown",
          errorMessage: error,
          onRetry: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
