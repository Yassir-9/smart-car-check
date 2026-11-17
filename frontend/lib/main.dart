import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'theme_notifier.dart';
import 'locale_notifier.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();
  runApp(const CarAiApp());
}

/// The app always runs in the light theme, whatever the system or the saved
/// preference says (PR 11 colours are fixed for light screens).
const ThemeMode kForcedThemeMode = ThemeMode.light;

class CarAiApp extends StatefulWidget {
  final Stream<User?>? authStateChanges;

  const CarAiApp({super.key, this.authStateChanges});

  @override
  State<CarAiApp> createState() => _CarAiAppState();
}

class _CarAiAppState extends State<CarAiApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChanged);
    localeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    localeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: Locale(localeNotifier.value),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppUiTheme.light(),
      darkTheme: AppUiTheme.dark(),
      // The unified UI is designed for light screens (dark cards inside).
      // The saved dark-mode flag and the dark theme are kept in the code but
      // not used for now: see [kForcedThemeMode].
      themeMode: kForcedThemeMode,
      builder: (context, child) {
        return Directionality(
          textDirection: localeNotifier.value == 'en'
              ? TextDirection.ltr
              : TextDirection.rtl,
          child: child!,
        );
      },
      home: StreamBuilder<User?>(
        stream:
            widget.authStateChanges ?? FirebaseAuth.instance.userChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            final user = snapshot.data!;
            final hasPhoneProvider = user.providerData.any(
              (provider) => provider.providerId == 'phone',
            );

            final needsEmailVerification =
                user.email != null &&
                user.email!.isNotEmpty &&
                !user.emailVerified &&
                !hasPhoneProvider;

            if (needsEmailVerification) {
              return const EmailVerificationScreen();
            }

            return const OnboardingGate(child: AppShell());
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
