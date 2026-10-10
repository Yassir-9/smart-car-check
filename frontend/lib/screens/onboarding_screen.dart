import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_brand.dart';
import '../theme/app_design_system.dart';
import '../l10n/app_localizations.dart';

class OnboardingGate extends StatefulWidget {
  final Widget child;
  const OnboardingGate({super.key, required this.child});
  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _done;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _done = prefs.getBool('onboarding_v2_done') ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_done == null) {
      return Scaffold(
          body: AppStateView(
              icon: Icons.speed_rounded,
              title: l10n.preparingApp,
              loading: true));
    }
    return _done!
        ? widget.child
        : OnboardingScreen(onDone: () => setState(() => _done = true));
  }
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_v2_done', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (
        Icons.search_rounded,
        l10n.onboardingUnderstandTitle,
        l10n.onboardingUnderstandBody
      ),
      (
        Icons.bluetooth_searching,
        l10n.onboardingConnectTitle,
        l10n.onboardingConnectBody
      ),
      (
        Icons.fact_check_outlined,
        l10n.onboardingChecksTitle,
        l10n.onboardingChecksBody
      ),
      (
        Icons.history_rounded,
        l10n.onboardingHistoryTitle,
        l10n.onboardingHistoryBody
      ),
    ];
    return Scaffold(
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(children: [
          const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(AppBrand.name,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent))),
          Expanded(
              child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (_, index) {
              final item = items[index];
              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                            color: AppSemanticColors.softBackground(
                                context, AppColors.accent),
                            shape: BoxShape.circle),
                        child:
                            Icon(item.$1, size: 56, color: AppColors.accent)),
                    const SizedBox(height: 32),
                    Text(item.$2,
                        style: const TextStyle(
                            fontSize: 25, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(item.$3,
                        style: const TextStyle(
                            fontSize: 15, height: 1.7, color: AppColors.steel),
                        textAlign: TextAlign.center),
                  ]);
            },
          )),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  items.length,
                  (i) => Container(
                      width: i == _page ? 22 : 7,
                      height: 7,
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                          color:
                              i == _page ? AppColors.accent : AppColors.border,
                          borderRadius: BorderRadius.circular(8))))),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _page == items.length - 1
                    ? _finish
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut),
                child: Text(_page == items.length - 1 ? l10n.start : l10n.next),
              )),
        ]),
      )),
    );
  }
}
