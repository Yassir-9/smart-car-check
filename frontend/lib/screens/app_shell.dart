import 'package:flutter/material.dart';
import '../config/app_brand.dart';
import '../theme/app_design_system.dart';
import 'cars_screen.dart';
import 'diagnosis_wizard_screen.dart';
import 'history_screen.dart';
import 'home_v2_screen.dart';
import 'settings_screen.dart';
import '../l10n/app_localizations.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  Widget _screen() => switch (_index) {
        1 => const DiagnosisWizardScreen(embedded: true),
        2 => const CarsScreen(embedded: true),
        3 => const HistoryScreen(embedded: true),
        _ => const HomeV2Screen(embedded: true),
      };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final l10n = AppLocalizations.of(context);
          final destinations = [
            (Icons.home_outlined, Icons.home_rounded, l10n.navHome),
            (
              Icons.car_repair_outlined,
              Icons.car_repair_rounded,
              l10n.navDiagnosis
            ),
            (
              Icons.directions_car_outlined,
              Icons.directions_car_rounded,
              l10n.navCars
            ),
            (Icons.history_outlined, Icons.history_rounded, l10n.navHistory),
          ];
          final desktop = constraints.maxWidth >= 900;
          final content = KeyedSubtree(key: ValueKey(_index), child: _screen());
          if (desktop) {
            return Scaffold(
              body: Row(children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  extended: constraints.maxWidth >= 1180,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: constraints.maxWidth >= 1180
                        ? const Text(AppBrand.name,
                            style: TextStyle(fontWeight: FontWeight.w900))
                        : const Icon(Icons.speed_rounded,
                            color: AppColors.accent),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IconButton(
                          tooltip: l10n.settings,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen())),
                          icon: const Icon(Icons.settings_outlined),
                        ),
                      ),
                    ),
                  ),
                  destinations: [
                    for (final item in destinations)
                      NavigationRailDestination(
                          icon: Icon(item.$1),
                          selectedIcon: Icon(item.$2),
                          label: Text(item.$3)),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ]),
            );
          }
          return Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                      icon: Icon(item.$1),
                      selectedIcon: Icon(item.$2),
                      label: item.$3),
              ],
            ),
          );
        },
      );
}
