import 'package:flutter/material.dart';

import 'mock_model.dart';
import 'screens/discover_screen.dart';
import 'screens/onboarding_screens.dart';
import 'screens/people_screens.dart';
import 'screens/profile_screens.dart';
import 'theme.dart';

class ClubmatesApp extends StatefulWidget {
  const ClubmatesApp({super.key});

  @override
  State<ClubmatesApp> createState() => _ClubmatesAppState();
}

class _ClubmatesAppState extends State<ClubmatesApp> {
  final _model = MockModel();

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MockScope(
      model: _model,
      child: MaterialApp(
        title: 'Clubmates',
        debugShowCheckedModeBanner: false,
        theme: clubTheme(),
        home: ListenableBuilder(
          listenable: _model,
          builder: (context, _) {
            return switch (_model.route) {
              AppRoute.splash => const SplashScreen(),
              AppRoute.phone => const PhoneScreen(),
              AppRoute.otp => const OtpScreen(),
              AppRoute.name => const NameScreen(),
              AppRoute.dob => const DobScreen(),
              AppRoute.location => const LocationScreen(),
              AppRoute.nightlife => const NightlifeScreen(),
              AppRoute.about => const AboutScreen(),
              AppRoute.photos => const PhotosScreen(),
              AppRoute.identity => const IdentityScreen(),
              AppRoute.face => const FaceScreen(),
              AppRoute.verified => const VerifiedScreen(),
              AppRoute.club => const ClubScreen(),
              AppRoute.details => const PersonDetailScreen(
                kind: AppRoute.details,
              ),
              AppRoute.inviteSent => const InviteSentScreen(),
              AppRoute.likes => const LikesScreen(),
              AppRoute.inviteDetail => const PersonDetailScreen(
                kind: AppRoute.inviteDetail,
              ),
              AppRoute.mates => const MatesScreen(),
              AppRoute.mateProfile => const PersonDetailScreen(
                kind: AppRoute.mateProfile,
              ),
              AppRoute.profile => const ProfileScreen(),
              AppRoute.editProfile => const EditProfileScreen(),
              AppRoute.settings => const SettingsScreen(),
              AppRoute.status => const StatusScreen(),
              AppRoute.error => const ErrorScreen(),
            };
          },
        ),
      ),
    );
  }
}
