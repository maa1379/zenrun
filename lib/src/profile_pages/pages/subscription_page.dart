import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:toln/toln.dart';
import 'package:zenrun/core/widgets/Costance.dart';
import 'package:zenrun/core/widgets/custom_sacffold.dart';
import 'package:zenrun/core/widgets/dialog_view.dart';
import 'package:zenrun/src/profile_pages/providers/profile_provider.dart';
import 'package:zenrun/src/profile_pages/providers/subscription_provider.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int? _selectedMonths;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadSettings();
      context.read<ProfileProvider>().getProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "Subscription",
      body: Consumer2<SubscriptionProvider, ProfileProvider>(
        builder: (context, sub, profile, _) {
          if (sub.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasActive = profile.profile?.hasActiveSubscription ?? false;
          final expireDate = profile.profile?.expireEshterak;

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            children: [
              // Status banner
              _buildStatusBanner(hasActive, expireDate),
              Gap(2.h),
              Text(
                "Choose a Plan".toLn(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorsHelper.black,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(1.h),
              Text(
                "Subscribe to access all premium products and content.".toLn(),
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              Gap(2.h),
              // Plan cards
              _PlanCard(
                months: 1,
                label: "1 Month",
                price: sub.priceForMonths(1),
                isSelected: _selectedMonths == 1,
                onTap: () => setState(() => _selectedMonths = 1),
              ),
              Gap(1.h),
              _PlanCard(
                months: 3,
                label: "3 Months",
                price: sub.priceForMonths(3),
                badge: "Save 10%",
                isSelected: _selectedMonths == 3,
                onTap: () => setState(() => _selectedMonths = 3),
              ),
              Gap(1.h),
              _PlanCard(
                months: 6,
                label: "6 Months",
                price: sub.priceForMonths(6),
                badge: "Save 20%",
                isSelected: _selectedMonths == 6,
                onTap: () => setState(() => _selectedMonths = 6),
              ),
              Gap(1.h),
              _PlanCard(
                months: 12,
                label: "12 Months",
                price: sub.priceForMonths(12),
                badge: "Best Value",
                isSelected: _selectedMonths == 12,
                onTap: () => setState(() => _selectedMonths = 12),
              ),
              Gap(3.h),
              if (_selectedMonths != null) ...[
                // Payment buttons
                _buildPaymentButtons(sub, profile),
              ] else
                Center(
                  child: Text(
                    "Select a plan to continue".toLn(),
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              Gap(4.h),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(bool hasActive, DateTime? expireDate) {
    return Container(
      width: 100.w,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasActive
            ? ColorsHelper.btn1.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: UiHelper.borderRadius16,
        border: Border.all(
          color: hasActive ? ColorsHelper.btn1 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        spacing: 10,
        children: [
          Icon(
            hasActive ? Icons.verified : Icons.lock_outline,
            color: hasActive ? ColorsHelper.btn1 : Colors.grey,
            size: 28,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActive ? "Active Subscription" : "No Active Subscription",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: hasActive ? ColorsHelper.btn1 : Colors.grey,
                  ),
                ),
                if (hasActive && expireDate != null)
                  Text(
                    "Expires: ${expireDate.year}-${expireDate.month.toString().padLeft(2, '0')}-${expireDate.day.toString().padLeft(2, '0')}",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (!hasActive)
                  Text(
                    "Subscribe to unlock premium content",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildPaymentButtons(
    SubscriptionProvider sub,
    ProfileProvider profile,
  ) {
    final price = sub.priceForMonths(_selectedMonths!);
    return Column(
      children: [
        Container(
          width: 100.w,
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: UiHelper.borderRadius16,
            boxShadow: UiHelper.shadow1,
          ),
          child: Column(
            children: [
              Text(
                "Total: \$$price".toLn(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorsHelper.black,
                ),
              ),
              Gap(12),
              // Google Pay / Apple Pay
              UiHelper.buttonMain2(
                () {
                  DialogView.showDanger(
                    context,
                    "Confirm Subscription",
                    "$_selectedMonths month plan for \$$price",
                    () async {
                      await sub.purchaseWithStripe(
                        context,
                        profile,
                        _selectedMonths!,
                      );
                      await profile.getProfile();
                      setState(() => _selectedMonths = null);
                    },
                  );
                },
                "Pay with Google / Apple Pay",
                width: 90.w,
                height: 5.h,
                fontSize: 14,
              ),
              Gap(10),
              // Wallet pay
              UiHelper.buttonMain2(
                () {
                  final walletBal = profile.profile?.wallet ?? 0;
                  DialogView.showDanger(
                    context,
                    "Pay with Wallet",
                    "Wallet balance: \$$walletBal\nSubscription: \$$price",
                    () async {
                      await sub.purchaseWithWallet(
                        context,
                        profile,
                        _selectedMonths!,
                      );
                      await profile.getProfile();
                      setState(() => _selectedMonths = null);
                    },
                  );
                },
                "Pay with Wallet",
                width: 90.w,
                height: 5.h,
                fontSize: 14,
              ),
            ],
          ),
        ),
      ],
    ).animate().slideY(begin: 0.2, duration: 300.ms);
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.months,
    required this.label,
    required this.price,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  final int months;
  final String label;
  final int price;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsHelper.btn1.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: UiHelper.borderRadius16,
          border: Border.all(
            color: isSelected ? ColorsHelper.btn1 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? UiHelper.shadow2 : UiHelper.shadow1,
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? ColorsHelper.btn1 : Colors.transparent,
                border: Border.all(
                  color: isSelected ? ColorsHelper.btn1 : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AutoSizeText(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorsHelper.black,
                        ),
                        maxFontSize: 18,
                        minFontSize: 12,
                      ),
                      if (badge != null) ...[
                        Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ColorsHelper.btn2,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (price > 0)
                    Text(
                      "\$$price / ${months == 1 ? 'month' : '$months months'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            AutoSizeText(
              "\$$price",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? ColorsHelper.btn1 : ColorsHelper.black,
              ),
              maxFontSize: 22,
              minFontSize: 14,
            ),
          ],
        ),
      ),
    );
  }
}
