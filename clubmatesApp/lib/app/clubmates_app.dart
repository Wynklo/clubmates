import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/chat_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/onboarding_screens.dart';
import '../screens/people_screens.dart';
import '../screens/profile_screens.dart';
import '../state/app_model.dart';
import '../theme/theme.dart';
import '../ui/widgets.dart' show TabChrome;

class ClubmatesApp extends StatefulWidget {
  const ClubmatesApp({super.key});

  @override
  State<ClubmatesApp> createState() => _ClubmatesAppState();
}

class _ClubmatesAppState extends State<ClubmatesApp> {
  final _model = AppModel();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _model.refreshOnResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      model: _model,
      child: MaterialApp(
        title: 'ClubMates',
        debugShowCheckedModeBanner: false,
        theme: clubTheme(),
        home: ListenableBuilder(
          listenable: _model,
          builder: (context, _) {
            final screen = _screenFor(_model.route);
            final tab = switch (_model.route) {
              AppRoute.club => AppTab.club,
              AppRoute.invites => AppTab.invites,
              AppRoute.mates => AppTab.mates,
              AppRoute.profile => AppTab.profile,
              _ => null,
            };
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.dark,
              child: tab == null ? screen : TabChrome(tab: tab, child: screen),
            );
          },
        ),
      ),
    );
  }

  Widget _screenFor(AppRoute route) {
    return switch (route) {
      AppRoute.splash => const SplashScreen(),
      AppRoute.phone => const PhoneScreen(),
      AppRoute.otp => const OtpScreen(),
      AppRoute.interest => const InterestScreen(),
      AppRoute.name => const NameScreen(),
      AppRoute.dob => const DobScreen(),
      AppRoute.location => const LocationScreen(),
      AppRoute.nightlife => const NightlifeScreen(),
      AppRoute.about => const AboutScreen(),
      AppRoute.photos => const PhotosScreen(),
      AppRoute.prompts => const PromptsScreen(),
      AppRoute.face => const FaceScreen(),
      AppRoute.verified => const VerifiedScreen(),
      AppRoute.club => const ClubScreen(),
      AppRoute.details => const PersonDetailScreen(kind: AppRoute.details),
      AppRoute.inviteSent => const InviteSentScreen(),
      AppRoute.invites => const InvitesScreen(),
      AppRoute.inviteDetail => const PersonDetailScreen(
        kind: AppRoute.inviteDetail,
      ),
      AppRoute.mates => const MatesScreen(),
      AppRoute.mateProfile => const PersonDetailScreen(
        kind: AppRoute.mateProfile,
      ),
      AppRoute.mateChat => const MateChatScreen(),
      AppRoute.profile => const ProfileScreen(),
      AppRoute.editProfile => const EditProfileScreen(),
      AppRoute.notifications => const NotificationsScreen(),
      AppRoute.nearby => const NearbyScreen(),
      AppRoute.status => const StatusScreen(),
      AppRoute.error => const ErrorScreen(),
    };
  }
}
