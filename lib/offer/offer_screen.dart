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
  final List<String> currencies = [
    'USD',
    'EUR',
    'INR',
    'GBP',
    'AUD',
    'CAD',
    'JPY'
  ];

  Duration _remaining = Duration.zero;
  Timer? _timer;
  DateTime? _endTime;

  static const Duration _offerDuration = Duration(hours: 5, minutes: 30);
  static const Duration _resetWindow = Duration(hours: 24);

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
    final proMonthly = currencyData['pro']!.toDouble();
    final unlimitedMonthly = currencyData['unlimited']!.toDouble();

    // Compute displayed prices based on monthly/annual toggle
    String proOldPrice, proNewPrice, proSuffix, proBuyLabel;
    String unOldPrice, unNewPrice, unSuffix, unBuyLabel;

    if (_isMonthly) {
      proOldPrice = _formatPrice(proMonthly * 1.25, symbol);
      proNewPrice = _formatPrice(proMonthly, symbol);
      proSuffix = ' / month';
      proBuyLabel = 'Buy Monthly';

      unOldPrice = _formatPrice(unlimitedMonthly * 1.25, symbol);
      unNewPrice = _formatPrice(unlimitedMonthly, symbol);
      unSuffix = ' / month';
      unBuyLabel = 'Buy Monthly';
    } else {
      final proYearTotal = proMonthly * 10;
      final unYearTotal = unlimitedMonthly * 10;
      final proApproxPerMonth = proYearTotal / 12;
      final unApproxPerMonth = unYearTotal / 12;

      proOldPrice = _formatPrice(proMonthly * 12 * 1.25, symbol);
      proNewPrice = _formatPrice(proYearTotal, symbol);
      proSuffix = ' / year (≈ ${_formatPrice(proApproxPerMonth, symbol)}/mo)';
      proBuyLabel = 'Buy Yearly';

      unOldPrice = _formatPrice(unlimitedMonthly * 12 * 1.25, symbol);
      unNewPrice = _formatPrice(unYearTotal, symbol);
      unSuffix = ' / year (≈ ${_formatPrice(unApproxPerMonth, symbol)}/mo)';
      unBuyLabel = 'Buy Yearly';
    }

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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildOfferCard(
                          title: "HIX AI Unlimited",
                          oldPrice: unOldPrice,
                          newPrice: unNewPrice,
                          suffix: unSuffix,
                          highlightColor: Colors.pinkAccent,
                          buyLabel: unBuyLabel,
                          features: const [
                            "Unlimited access to GPT-5, Gemini 2.5, DeepSeek-R1, Claude 3.5",
                            "Deep Research & AI Video Tools",
                            "Unlimited Chatbot Library, ScholarChat, ChatPDF, Web Chat",
                            "Test newest features, Priority support"
                          ],
                        ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildOfferCard(
                          title: "HIX AI Pro",
                          oldPrice: proOldPrice,
                          newPrice: proNewPrice,
                          suffix: proSuffix,
                          highlightColor: Colors.blueAccent,
                          buyLabel: proBuyLabel,
                          features: const [
                            "Access to GPT-5, Gemini 2.5, DeepSeek-R1, Claude 3.5",
                            "AI Image, Text, and Video Tools",
                            "Chatbot Library, ChatPDF, Web Chat",
                            "Test newest features, Priority support"
                          ],
                        ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text("Secure Payments by PayPal • Cancel Anytime",
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
        const Text("Save up to 50%",
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

  // ---------------- OFFER CARD ----------------
  Widget _buildOfferCard({
    required String title,
    required String oldPrice,
    required String newPrice,
    required String suffix,
    required Color highlightColor,
    required String buyLabel,
    required List<String> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: highlightColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)),
            child: Text("🔥 Flash Sale",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: highlightColor))),
        const SizedBox(height: 12),
        Text(title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: highlightColor)),
        const SizedBox(height: 8),
        Row(children: [
          Text(oldPrice,
              style: const TextStyle(
                  color: Colors.grey, decoration: TextDecoration.lineThrough)),
          const SizedBox(width: 8),
          Text(newPrice,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(suffix,
                  style: const TextStyle(fontSize: 13, color: Colors.black54))),
        ]),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: highlightColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(double.infinity, 45)),
          onPressed: () => _showPaymentOptions(
              context,
              title,
              double.parse(newPrice.replaceAll(RegExp(r'[^0-9.]'), '')),
              _selectedCurrency),
          child: Text(buyLabel, style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.payment, color: Colors.blue),
            label: const Text("Pay with PayPal")),
        const Divider(height: 24),
        const Text("Features:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...features.map((f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(f,
                      style: const TextStyle(fontSize: 14, height: 1.4)))
            ]))),
      ]),
    );
  }

  // ---------------- PAYMENT MODAL ----------------
  void _showPaymentOptions(
      BuildContext context, String plan, double price, String currency) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Choose Payment Method",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildPaymentOption(context, "💜 Razorpay",
                  () => _payWithRazorpay(plan, price, currency)),
              _buildPaymentOption(
                  context, "🟣 Stripe", () => _payWithStripe(price, currency)),
              _buildPaymentOption(
                  context, "🟢 Google Pay (UPI)", () => _payWithGPay(price)),
              _buildPaymentOption(
                  context, "🔵 PayPal", () => _payWithPayPal(price, currency)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(
      BuildContext context, String label, VoidCallback onTap) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  // ---------------- PAYMENT METHODS ----------------
  void _payWithRazorpay(String plan, double price, String currency) {
    _paymentService.initRazorpay(
      onSuccess: (id) => _showSuccess(context, "Razorpay", id),
      onError: (err) => _showError(context, err),
    );
    _paymentService.startRazorpay(
        name: plan, amount: price, email: "user@test.com");
  }

  void _payWithStripe(double price, String currency) async {
    await _paymentService.startStripePayment(
        amount: price.toStringAsFixed(2), currency: currency);
  }

  void _payWithGPay(double price) async {
    await _paymentService.startUpiPayment(
        amount: price, receiverUpiId: "yourupiid@okaxis", name: "SkillSwap");
  }

  void _payWithPayPal(double price, String currency) async {
    await _paymentService.startPayPal(
        clientId: "YOUR_PAYPAL_CLIENT_ID",
        secret: "YOUR_PAYPAL_SECRET",
        amount: price,
        currency: currency);
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
        )));
  }

  void _showError(BuildContext context, String error) {
    Navigator.push(
        context,
        AnimatedPageRoute(
            page: PaymentFailedScreen(
          gateway: "Unknown",
          errorMessage: error,
          onRetry: () => Navigator.pop(context),
        )));
  }
}
