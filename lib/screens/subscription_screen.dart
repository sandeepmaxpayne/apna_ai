import 'package:flutter/material.dart';

class SubscriptionDrawer extends StatelessWidget {
  final VoidCallback onClose;
  const SubscriptionDrawer({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ClipPath(
        clipper: OvalDrawerClipper(),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    "Choose Your Plan",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Free Tier
                  _buildPlanButton(
                    title: "Free Tier",
                    subtitle: "Basic features with limited access",
                    color: Colors.greenAccent,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Free plan selected")),
                      );
                      onClose();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pro Tier
                  _buildPlanButton(
                    title: "Pro Tier",
                    subtitle: "Unlock advanced features",
                    color: Colors.blueAccent,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Pro plan selected")),
                      );
                      onClose();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Max Tier
                  _buildPlanButton(
                    title: "Max Tier",
                    subtitle: "Unlimited access with premium features",
                    color: Colors.deepOrange,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Max plan selected")),
                      );
                      onClose();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanButton({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class OvalDrawerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width - 80, 0);
    path.quadraticBezierTo(
        size.width, size.height / 2, size.width - 80, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
