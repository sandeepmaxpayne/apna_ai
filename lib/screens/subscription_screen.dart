import 'package:apna_ai/models/theme_color.dart';
import 'package:flutter/material.dart';

class SubscriptionDrawer extends StatefulWidget {
  final VoidCallback onClose;
  const SubscriptionDrawer({super.key, required this.onClose});

  @override
  State<SubscriptionDrawer> createState() => _SubscriptionDrawerState();
}

class _SubscriptionDrawerState extends State<SubscriptionDrawer> {
  String _selectedPlan = "pro"; // pro or max
  String _billingCycle = "monthly"; // monthly or yearly

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SizedBox.expand(
          child: Stack(
            children: [
              // ✖️ Close button
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon:
                      const Icon(Icons.close, size: 28, color: Colors.black87),
                  onPressed: widget.onClose,
                ),
              ),

              // 📜 Main Content
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // 🌟 Title
                    const Text(
                      "Select your plan",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Ask once, get trusted answers fast",
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 30),

                    // 🔘 Pro / Max toggle
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton("pro", "Pro"),
                          ),
                          Expanded(
                            child: _buildToggleButton("max", "Max"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ✅ Features List
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _feature("Unlimited file & photo uploads"),
                          _feature("Access to SkillSwap Labs"),
                          _feature("Unlimited AI chat sessions"),
                          _feature("Extended access to image generation"),
                          _feature("Limited access to video generation"),
                          _feature("Access to latest AI models (GPT-5 etc.)"),
                          _feature("Exclusive access to Pro perks & rewards"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 💳 Monthly / Yearly toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBillingOption(
                          "Monthly",
                          "₹1,950.00",
                          "per month",
                          "monthly",
                        ),
                        const SizedBox(width: 12),
                        _buildBillingOption(
                          "Yearly",
                          "₹19,600.00",
                          "₹1,633.33/month",
                          "yearly",
                          badge: "Save ₹3,800.00",
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 🔵 Subscribe Button
                    GestureDetector(
                      onTap: () {
                        // Handle purchase logic here
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Center(
                          child: Text(
                            "Get Pro",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔘 Toggle Button (Pro / Max)
  Widget _buildToggleButton(String value, String label) {
    final bool selected = _selectedPlan == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // 💳 Billing Option (Monthly / Yearly)
  Widget _buildBillingOption(
      String title, String price, String subtitle, String value,
      {String? badge}) {
    final selected = _billingCycle == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _billingCycle = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.primary : Colors.black26,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            children: [
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 6),
              Text(price,
                  style: TextStyle(
                    color: selected ? AppColors.primary : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Feature Row
  Widget _feature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.black87, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
