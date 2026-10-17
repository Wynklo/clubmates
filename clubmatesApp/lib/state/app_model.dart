import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, PhoneAuthCredential;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart' show Geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/chat_records.dart';
import '../data/clubmates_repository.dart';
import '../data/firebase_setup.dart';
import '../data/records.dart';
import 'chat_controller.dart';
export '../data/chat_records.dart'
    show ChatMessage, MateThread, SendState, reportReasons;
export 'chat_controller.dart' show ChatController;
export '../data/records.dart'
    show
        bioIssue,
        cityIssue,
        dobIsComplete,
        dobIssue,
        feetLabel,
        heightIssue,
        interestCode,
        interestLabels,
        interestOptions,
        maxInterests,
        maxPlanTonight,
        planIssue,
        planSuggestions,
        maxHeightCm,
        maxProfilePhotos,
        maxProfilePrompts,
        maxPromptAnswer,
        minHeightCm,
        nameIssue,
        OwnPhoto,
        phoneIssue,
        ProfileExtras,
        ProfilePrompt,
        promptOptions;
import '../data/supabase_config.dart';

enum AppRoute {
  splash,
  phone,
  otp,
  interest,
  name,
  dob,
  location,
  nightlife,
  about,
  photos,
  prompts,
  face,
  verified,
  club,
  details,
  inviteSent,
  invites,
  inviteDetail,
  mates,
  mateProfile,
  mateChat,
  profile,
  editProfile,
  notifications,
  nearby,
  status,
  error,
}

enum AppTab { club, invites, mates, profile }

class Person {
  const Person({
    this.id = '',
    required this.name,
    required this.age,
    required this.location,
    required this.tonight,
    required this.usually,
    required this.interests,
    required this.photo,
    required this.preview,
    this.verified = true,
    this.inviteId,
    this.mateId,
    this.outTonightUntil,
    this.distanceKm,
  });

  final String id;
  final String name;
  final int age;
  final String location;
  final String tonight;
  final String usually;
  final List<String> interests;
  final String photo;
  final String preview;
  final bool verified;
  final String? inviteId;
  final String? mateId;
  final DateTime? outTonightUntil;
  final double? distanceKm;
}

bool isOutTonight(DateTime? until) =>
    until != null && until.isAfter(DateTime.now());

String? tonightStatus(DateTime? until) =>
    isOutTonight(until) ? 'Out tonight' : null;

/// The next 4 AM local time, when a night out is treated as over.
DateTime endOfNight([DateTime? from]) {
  final now = from ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 4);
  return now.isBefore(today)
      ? today
      : DateTime(now.year, now.month, now.day + 1, 4);
}

const meera = Person(
  name: 'Meera',
  age: 27,
  location: 'Indiranagar',
  tonight: 'Dinner, then a bar in Indiranagar.',
  usually: 'Low-key drinks, live music and good food.',
  interests: ['Drinks', 'Food', 'Live Music'],
  photo: 'assets/photos/meera.jpg',
  preview: 'Dinner, then a bar in Indiranagar.',
  distanceKm: 3,
);

const kabir = Person(
  name: 'Kabir',
  age: 29,
  location: 'Koramangala',
  tonight: 'Live music and a late dinner.',
  usually: 'Low-key drinks, live music and good food.',
  interests: ['Drinks', 'Food', 'Live Music'],
  photo: 'assets/photos/kabir.jpg',
  preview: 'Live music and a late dinner.',
  distanceKm: 8,
);

const aria = Person(
  name: 'Aria',
  age: 26,
  location: 'Bandra',
  tonight: 'Drinks and dinner somewhere in Bandra.',
  usually: 'Good food, live sets and unhurried evenings.',
  interests: ['Drinks', 'Dinner', 'Live Music'],
  photo: 'assets/photos/aria.jpg',
  preview: 'Drinks, dinner, live music',
  distanceKm: 18,
);

const riya = Person(
  name: 'Riya',
  age: 25,
  location: 'Koregaon Park',
  tonight: 'Rooftop drinks after 8.',
  usually: 'Low-key drinks, live music and good food.',
  interests: ['Drinks', 'Food', 'Live Music'],
  photo: 'assets/photos/riya.jpg',
  preview: 'Tonight: rooftop drinks',
  distanceKm: 4,
);

const nightPhoto = 'assets/photos/night.jpg';
const ownPhoto = 'assets/photos/meera_alt.jpg';

const cityOptions = ['Bengaluru', 'Mumbai', 'Delhi', 'Pune', 'Hyderabad'];

const sexOptions = ['Woman', 'Man', 'Non-binary', 'Prefer not to say'];

/// Screen state for the phone app. Live reads and writes go through
/// [ClubmatesRepository]. Sample people stay on this phone when Supabase
/// is not configured.
class AppModel extends ChangeNotifier {
  AppModel({ClubmatesRepository? repository, ImagePicker? picker})
    : _api = repository ?? ClubmatesRepository(),
      _picker = picker ?? ImagePicker(),
      live = SupabaseConfig.isConfigured;

  final ClubmatesRepository _api;
  final ImagePicker _picker;

  final bool live;
  bool busy = false;
  String? errorMessage;
  bool _hasProfile = false;
  bool _hasPrivate = false;
  bool _verified = false;
  DateTime? _dob;

  AppRoute route = AppRoute.splash;
  static const _devPassword = String.fromEnvironment('DEV_LOGIN_PASSWORD');

  String phone = '';
  List<String> otp = List.filled(6, '');
  bool otpError = false;
  String name = '';
  String day = '';
  String month = '';
  String year = '';
  String location = 'Bengaluru';
  String bio = '';
  String height = '';
  List<String> interests = [];
  String planTonight = '';
  String sex = 'Woman';
  String lookingFor = '';
  String? _interestedIn;
  bool _hasGender = false;
  bool _hasCity = false;
  bool _onboardingComplete = false;
  bool discoverable = true;
  DateTime? outTonightUntil;
  bool locationOn = false;
  bool nearbyOnly = true;
  AppRoute nearbyBack = AppRoute.profile;
  bool notifyInvites = true;
  bool notifyMates = true;
  bool notifyNearby = false;
  bool showInvites = true;
  bool showMates = true;
  int profiles = 0;
  List<OwnPhoto> ownPhotos = [];
  List<ProfilePrompt> prompts = [];
  List<BlockedPerson> blocked = [];
  Person? opened;
  final List<Person> _candidates = [];
  final List<Person> _incoming = [];
  final List<Person> _mateRows = [];
  Map<String, MateThread> threads = {};
  ChatController? chat;
  RealtimeChannel? _inbox;
  Timer? _threadsSoon;

  int get unreadMessages =>
      threads.values.fold(0, (sum, thread) => sum + thread.unread);

  MateThread? threadFor(Person person) =>
      person.mateId == null ? null : threads[person.mateId];

  AppTab get tab => switch (route) {
    AppRoute.invites || AppRoute.inviteDetail => AppTab.invites,
    AppRoute.mates || AppRoute.mateProfile || AppRoute.mateChat => AppTab.mates,
    AppRoute.profile ||
    AppRoute.editProfile ||
    AppRoute.notifications ||
    AppRoute.nearby ||
    AppRoute.status ||
    AppRoute.error => AppTab.profile,
    _ => AppTab.club,
  };

  Person? get clubPerson {
    final people = clubPeople;
    if (people.isEmpty) return null;
    return people.first;
  }

  List<Person> get clubPeople {
    final source = live ? _candidates : _offlineClub();
    if (!live) {
      if (profiles >= source.length) return const [];
      return source.skip(profiles).toList();
    }
    return source;
  }

  List<Person> get incoming => live ? _incoming : (showInvites ? [aria] : []);

  List<Person> get mateList => live ? _mateRows : (showMates ? [riya] : []);

  bool get isVerified => live ? _verified : true;

  String get displayName => name.trim().isEmpty ? 'Aanya' : name.trim();

  String get ageLabel {
    if (!live) return '27';
    if (_dob == null) return '';
    return '${ageOn(_dob!, DateTime.now())}';
  }

  String get avatar {
    for (final photo in ownPhotos) {
      if (photo.primary && photo.url.isNotEmpty) return photo.url;
    }
    if (ownPhotos.isNotEmpty && ownPhotos.first.url.isNotEmpty) {
      return ownPhotos.first.url;
    }
    return live ? '' : ownPhoto;
  }

  Person personFor(AppRoute kind) {
    final current = opened;
    if (current != null) return current;
    return switch (kind) {
      AppRoute.inviteDetail => aria,
      AppRoute.mateProfile => riya,
      _ => meera,
    };
  }

  void go(AppRoute next) {
    if (next != AppRoute.mateChat) _closeChat();
    route = next;
    errorMessage = null;
    notifyListeners();
  }

  void goTab(AppTab next) {
    _closeChat();
    route = switch (next) {
      AppTab.club => AppRoute.club,
      AppTab.invites => AppRoute.invites,
      AppTab.mates => AppRoute.mates,
      AppTab.profile => AppRoute.profile,
    };
    notifyListeners();
  }

  Future<void> start() async {
    if (!live || !_api.hasSession) {
      go(AppRoute.phone);
      return;
    }
    final ok = await _guard(_resume);
    if (!ok && route == AppRoute.splash) go(AppRoute.error);
    if (!ok) return;
    await _registerPush();
    if (_pushSupported) {
      final opened = await FirebaseMessaging.instance.getInitialMessage();
      if (opened != null) {
        await _openFromPush(opened);
        return;
      }
      if (!_trayReady) return;
      final launch = await _tray.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        await _openRoute(launch!.notificationResponse?.payload);
      }
    }
  }

  String? _verificationId;
  int? _resendToken;
  String? _pushToken;
  StreamSubscription<String>? _tokenRefresh;
  bool _pushListening = false;
  final _tray = FlutterLocalNotificationsPlugin();
  bool _trayReady = false;
  int _trayId = 0;

  // Must match default_notification_channel_id in AndroidManifest.xml so
  // pushes shown by Android while the app is closed use the same channel.
  static const _alerts = AndroidNotificationChannel(
    'clubmates_alerts',
    'Invites and mates',
    description: 'New invites and accepted invites.',
    importance: Importance.high,
  );

  @override
  void dispose() {
    _tokenRefresh?.cancel();
    super.dispose();
  }

  bool get _pushSupported =>
      FirebaseSetup.ready && (Platform.isAndroid || Platform.isIOS);

  String get _pushPlatform => Platform.isIOS ? 'ios' : 'android';

  // The notify Edge Function sends through FCM HTTP v1 to registration
  // tokens, so the token calls are kept until it moves to installation IDs.

  Future<void> _registerPush() async {
    if (!live || !_pushSupported || !_api.hasSession) return;
    final messaging = FirebaseMessaging.instance;
    try {
      final permission = await messaging.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;
      await _setupTray();
      if (Platform.isIOS && !await _apnsReady(messaging)) return;
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token == null) return;
      _pushToken = token;
      await _api.saveDeviceToken(token, _pushPlatform);
      // ignore: deprecated_member_use
      _tokenRefresh ??= messaging.onTokenRefresh.listen((next) async {
        if (!_api.hasSession) return;
        _pushToken = next;
        try {
          await _api.saveDeviceToken(next, _pushPlatform);
        } catch (error) {
          debugPrint('Push token refresh failed: $error');
        }
      });
      if (!_pushListening) {
        _pushListening = true;
        FirebaseMessaging.onMessageOpenedApp.listen(_openFromPush);
        FirebaseMessaging.onMessage.listen((message) {
          final mateId = message.data['mate_id'];
          if (message.data['route'] == 'chat') {
            _refreshThreadsSoon();
            final reading =
                route == AppRoute.mateChat && chat?.mateId == mateId;
            if (!reading) _showInTray(message);
            return;
          }
          refreshPeople();
          _showInTray(message);
        });
      }
    } catch (error) {
      debugPrint('Push setup failed: $error');
    }
  }

  /// iOS hands Firebase the APNs token a moment after permission is granted;
  /// asking for the FCM token before then throws.
  Future<bool> _apnsReady(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 10; attempt++) {
      if (await messaging.getAPNSToken() != null) return true;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    debugPrint('APNs token unavailable; iOS push stays off.');
    return false;
  }

  /// Stops pushes to this phone before the session ends.
  Future<void> _unregisterPush() async {
    if (!_pushSupported) return;
    final messaging = FirebaseMessaging.instance;
    await _tokenRefresh?.cancel();
    _tokenRefresh = null;
    try {
      // ignore: deprecated_member_use
      final token = _pushToken ?? await messaging.getToken();
      if (token != null && _api.hasSession) {
        await _api.removeDeviceToken(token);
      }
    } catch (error) {
      debugPrint('Push token removal failed: $error');
    }
    try {
      // ignore: deprecated_member_use
      await messaging.deleteToken();
    } catch (error) {
      debugPrint('Push token delete failed: $error');
    }
    _pushToken = null;
  }

  Future<void> _setupTray() async {
    if (_trayReady) return;
    await _tray.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _openRoute(response.payload),
    );
    await _tray
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_alerts);
    _trayReady = true;
  }

  /// Android and iOS leave pushes out of the notification bar while the app
  /// is open, so they are posted here instead (skipped for the open chat).
  Future<void> _showInTray(RemoteMessage message) async {
    final notification = message.notification;
    if (!_trayReady || notification == null) return;
    final mateId = message.data['mate_id'];
    final chatPush = message.data['route'] == 'chat' && mateId != null;
    try {
      await _tray.show(
        id: chatPush ? mateId.hashCode : _trayId++,
        title: notification.title,
        body: notification.body,
        payload: _pushTarget(message),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _alerts.id,
            _alerts.name,
            channelDescription: _alerts.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
            color: const Color(0xFF994EA8),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (error) {
      debugPrint('Push display failed: $error');
    }
  }

  Future<void> _openFromPush(RemoteMessage message) =>
      _openRoute(_pushTarget(message));

  String? _pushTarget(RemoteMessage message) {
    final route = message.data['route'];
    final mateId = message.data['mate_id'];
    return route == 'chat' && mateId != null ? 'chat:$mateId' : route;
  }

  Future<void> _openRoute(String? route) async {
    if (!live || !_api.hasSession || !_onboardingComplete) return;
    if (route != null && route.startsWith('chat:')) {
      final mateId = route.substring(5);
      await refreshPeople();
      final person = _mateRows.where((p) => p.mateId == mateId).firstOrNull;
      if (person == null) {
        go(AppRoute.mates);
        return;
      }
      opened = person;
      openChat();
      return;
    }
    final target = switch (route) {
      'invites' || 'likes' => AppRoute.invites,
      'mates' => AppRoute.mates,
      _ => AppRoute.club,
    };
    await refreshPeople();
    go(target);
  }

  Future<void> retry() async {
    if (!live || !_api.hasSession) {
      go(AppRoute.phone);
      return;
    }
    final ok = await _guard(_resume);
    if (!ok) go(AppRoute.error);
  }

  void setPhone(String value) {
    phone = digitsOnly(value, 10);
    errorMessage = phoneIssue(phone);
    notifyListeners();
  }

  void setOtp(int index, String value) {
    final next = [...otp];
    next[index] = value.isEmpty ? '' : value.substring(value.length - 1);
    otp = next;
    otpError = false;
    notifyListeners();
  }

  /// The fixed-code developer login. kDebugMode is false in release builds,
  /// so a build people can install always uses real SMS codes.
  bool get testLogin => live && kDebugMode && _devPassword.isNotEmpty;

  Future<void> sendCode({bool resend = false}) async {
    final issue = phoneIssue(phone);
    if (issue != null || phone.length != 10) {
      errorMessage = issue ?? 'Enter a 10-digit mobile number.';
      notifyListeners();
      return;
    }
    if (!live) {
      go(AppRoute.otp);
      return;
    }
    if (testLogin) {
      otp = List.filled(6, '1');
      otpError = false;
      errorMessage = null;
      if (!resend) go(AppRoute.otp);
      notifyListeners();
      return;
    }
    if (!FirebaseSetup.ready) {
      errorMessage = 'Phone sign-in is not available yet.';
      notifyListeners();
      return;
    }
    await _guard(() async {
      final sent = await _api.requestPhoneCode(
        '+91$phone',
        resendToken: resend ? _resendToken : null,
        onAutoVerified: _signInAutomatically,
      );
      final instant = sent.instant;
      if (instant != null) {
        await _api.signInWithPhoneCredential(instant);
        await _resume();
        await _registerPush();
        return;
      }
      _verificationId = sent.verificationId;
      _resendToken = sent.resendToken ?? _resendToken;
      otp = List.filled(6, '');
      otpError = false;
      if (!resend) go(AppRoute.otp);
    });
  }

  Future<void> _signInAutomatically(PhoneAuthCredential credential) async {
    final ok = await _guard(() async {
      await _api.signInWithPhoneCredential(credential);
      await _resume();
    });
    if (ok) await _registerPush();
  }

  Future<void> verifyOtp() async {
    if (testLogin) {
      if (otp.join() != '111111') {
        otpError = true;
        errorMessage = null;
        notifyListeners();
        return;
      }
      final ok = await _guard(() async {
        await _api.signInTestPhone(phone);
        await _resume();
      });
      if (ok) {
        await _registerPush();
      } else {
        otpError = true;
        notifyListeners();
      }
      return;
    }
    if (!live) {
      if (otp.join() == '000000') {
        otpError = true;
        notifyListeners();
        return;
      }
      go(AppRoute.interest);
      return;
    }
    final verificationId = _verificationId;
    if (verificationId == null) {
      errorMessage = 'Request a new code and try again.';
      notifyListeners();
      return;
    }
    final ok = await _guard(() async {
      await _api.verifyPhoneCode(verificationId, otp.join());
      await _resume();
    });
    if (ok) {
      _verificationId = null;
      await _registerPush();
      return;
    }
    if (errorMessage == wrongCodeMessage) {
      errorMessage = null;
      otpError = true;
    }
    notifyListeners();
  }

  void setName(String value) {
    name = value;
    errorMessage = nameIssue(value);
    notifyListeners();
  }

  Future<void> saveName() async {
    final issue = nameIssue(name, required: true);
    if (issue != null) {
      errorMessage = issue;
      notifyListeners();
      return;
    }
    final trimmed = name.trim();
    if (!live) {
      go(AppRoute.dob);
      return;
    }
    await _guard(() async {
      if (_hasProfile) {
        await _api.updateProfile(displayName: trimmed);
      } else {
        await _api.createProfile(trimmed);
        _hasProfile = true;
      }
      name = trimmed;
      go(AppRoute.dob);
    });
  }

  void setDobPart({String? nextDay, String? nextMonth, String? nextYear}) {
    if (nextDay != null) day = digitsOnly(nextDay, 2);
    if (nextMonth != null) month = digitsOnly(nextMonth, 2);
    if (nextYear != null) year = digitsOnly(nextYear, 4);
    errorMessage = dobIssue(day, month, year);
    notifyListeners();
  }

  bool get dobReady => dobIsComplete(day, month, year);

  Future<void> saveDob() async {
    final issue = dobIssue(day, month, year);
    if (issue != null) {
      errorMessage = issue;
      notifyListeners();
      return;
    }
    final dob = parseDob(int.parse(day), int.parse(month), int.parse(year))!;
    if (!live) {
      _dob = dob;
      go(AppRoute.location);
      return;
    }
    await _guard(() async {
      if (_hasPrivate) {
        await _api.updatePrivate(dob: dob);
      } else {
        await _api.createPrivate(dob, interestedIn: _interestedIn);
        _hasPrivate = true;
      }
      _dob = dob;
      go(AppRoute.location);
    });
  }

  void setLocation(String value) {
    location = value;
    errorMessage = cityIssue(value);
    notifyListeners();
  }

  Future<void> saveCity() async {
    final issue = cityIssue(location, required: true);
    if (issue != null) {
      errorMessage = issue;
      notifyListeners();
      return;
    }
    final city = location.trim();
    if (!live) {
      _hasCity = true;
      go(AppRoute.nightlife);
      return;
    }
    await _guard(() async {
      await _api.updateProfile(city: city);
      location = city;
      _hasCity = true;
      go(AppRoute.nightlife);
    });
  }

  void toggleInterest(String item) {
    if (interests.contains(item)) {
      interests = interests.where((interest) => interest != item).toList();
    } else if (interests.length < maxInterests) {
      interests = [...interests, item];
    }
    notifyListeners();
  }

  void setPlanTonight(String value) {
    planTonight = value;
    errorMessage = planIssue(value);
    notifyListeners();
  }

  /// Saves the plan and interests on their own, from the Profile tab.
  Future<bool> saveNightlife({
    required String plan,
    required List<String> picked,
  }) async {
    final issue = planIssue(plan);
    if (issue != null) {
      errorMessage = issue;
      notifyListeners();
      return false;
    }
    final previous = (planTonight, interests);
    planTonight = plan.trim();
    interests = picked.take(maxInterests).toList();
    notifyListeners();
    if (!live) return true;
    final saved = await _guard(
      () =>
          _api.updateNightlife(planTonight: planTonight, interests: interests),
    );
    if (!saved) {
      planTonight = previous.$1;
      interests = previous.$2;
      notifyListeners();
    }
    return saved;
  }

  void setSex(String value) {
    sex = value;
    notifyListeners();
  }

  void setLookingFor(String value) {
    lookingFor = value;
    _interestedIn = interestCode(value);
    errorMessage = null;
    notifyListeners();
  }

  Future<void> saveInterest() async {
    final code = interestCode(lookingFor);
    if (code == null) {
      errorMessage = 'Choose who you want to meet.';
      notifyListeners();
      return;
    }
    _interestedIn = code;
    if (!live) {
      await _openNextStep();
      return;
    }
    await _guard(() async {
      if (_hasPrivate) await _api.updatePrivate(interestedIn: code);
      await _openNextStep();
    });
  }

  void setHeight(String value) {
    height = digitsOnly(value, 3);
    errorMessage = heightIssue(height);
    notifyListeners();
  }

  void setBio(String value) {
    bio = value;
    errorMessage = bioIssue(value);
    notifyListeners();
  }

  Future<void> saveAbout() async {
    final code = genderCode(sex);
    final typed = height.trim();
    if (heightIssue(typed) != null) {
      errorMessage = heightIssue(typed);
      notifyListeners();
      return;
    }
    final cm = typed.isEmpty ? null : int.parse(typed);
    if (!live) {
      _hasGender = code != null;
      go(AppRoute.photos);
      return;
    }
    await _guard(() async {
      await _api.updateProfile(gender: code, heightCm: cm);
      await _api.updateNightlife(
        planTonight: planTonight,
        interests: interests,
      );
      _hasGender = code != null;
      go(AppRoute.photos);
    });
  }

  Future<void> pickPhoto({required bool camera}) async {
    if (ownPhotos.length >= maxProfilePhotos) {
      errorMessage = 'You can add up to 3 photos.';
      notifyListeners();
      return;
    }
    try {
      final file = await _picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      if (!live) {
        ownPhotos = [
          ...ownPhotos,
          OwnPhoto(
            id: 'local-${DateTime.now().microsecondsSinceEpoch}',
            path: file.path,
            url: file.path,
            order: ownPhotos.length + 1,
            primary: ownPhotos.isEmpty,
            moderation: 'LOCAL',
          ),
        ];
        errorMessage = null;
        notifyListeners();
        return;
      }
      final bytes = await file.readAsBytes();
      await _guard(() async {
        await _api.uploadPhoto(bytes);
        ownPhotos = await _api.loadOwnPhotos();
      });
    } on PlatformException catch (error) {
      errorMessage = switch (error.code) {
        'camera_access_denied' || 'camera_access_restricted' =>
          'Allow camera access to take a photo. You can turn it on in Settings.',
        'photo_access_denied' || 'photo_access_restricted' =>
          'Allow photo access to add a picture. You can turn it on in Settings.',
        _ => error.message ?? 'Could not open your photos.',
      };
      notifyListeners();
    } catch (error) {
      errorMessage = _message(error);
      notifyListeners();
    }
  }

  Future<void> removePhoto(OwnPhoto photo) async {
    if (!live) {
      final next = ownPhotos.where((item) => item.id != photo.id).toList();
      ownPhotos = [
        for (var i = 0; i < next.length; i++)
          OwnPhoto(
            id: next[i].id,
            path: next[i].path,
            url: next[i].url,
            order: i + 1,
            primary: photo.primary ? i == 0 : next[i].primary,
            moderation: next[i].moderation,
          ),
      ];
      notifyListeners();
      return;
    }
    await _guard(() async {
      await _api.deletePhoto(photo);
      ownPhotos = await _api.loadOwnPhotos();
    });
  }

  Future<void> makePrimary(OwnPhoto photo) async {
    if (photo.primary) return;
    if (!live) {
      ownPhotos = [
        for (final item in ownPhotos)
          OwnPhoto(
            id: item.id,
            path: item.path,
            url: item.url,
            order: item.order,
            primary: item.id == photo.id,
            moderation: item.moderation,
          ),
      ];
      notifyListeners();
      return;
    }
    await _guard(() async {
      await _api.makePrimary(photo);
      ownPhotos = await _api.loadOwnPhotos();
    });
  }

  void setPrompt(int index, ProfilePrompt prompt) {
    final next = [...prompts];
    if (index < next.length) {
      next[index] = prompt;
    } else if (next.length < maxProfilePrompts) {
      next.add(prompt);
    }
    prompts = next;
    notifyListeners();
  }

  void removePrompt(int index) {
    if (index >= prompts.length) return;
    prompts = [...prompts]..removeAt(index);
    notifyListeners();
  }

  /// Saves prompts. From onboarding it moves on to the face step.
  Future<void> savePrompts({bool onboarding = false}) async {
    if (!live) {
      if (onboarding) go(AppRoute.face);
      notifyListeners();
      return;
    }
    await _guard(() async {
      await _api.saveOwnPrompts(prompts);
      prompts = await _api.loadOwnPrompts();
      if (onboarding) go(AppRoute.face);
    });
  }

  final Map<String, ProfileExtras> _extras = {};
  final Set<String> _extrasLoading = {};

  /// Photos and prompts for a full profile; loads them the first time.
  ProfileExtras? extrasFor(Person person) {
    if (!live || person.id.isEmpty) return null;
    final cached = _extras[person.id];
    if (cached != null || _extrasLoading.contains(person.id)) return cached;
    _extrasLoading.add(person.id);
    _api
        .profileExtras(person.id)
        .then((extras) {
          _extras[person.id] = extras;
          notifyListeners();
        })
        .catchError((Object error) {
          debugPrint('Profile extras failed: $error');
        })
        .whenComplete(() => _extrasLoading.remove(person.id));
    return null;
  }

  /// Fills the city from the phone's location and saves the point too.
  Future<void> useCurrentLocation() async {
    if (_locating) return;
    _locating = true;
    errorMessage = null;
    notifyListeners();
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        errorMessage = 'Allow location in Settings, or pick a city below.';
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        errorMessage = 'Turn on Location Services, or pick a city below.';
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final places = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final city = places
          .map(
            (place) => [place.locality, place.subAdministrativeArea]
                .whereType<String>()
                .firstWhere((name) => name.trim().isNotEmpty, orElse: () => ''),
          )
          .firstWhere((name) => name.isNotEmpty, orElse: () => '');
      if (city.isEmpty) {
        errorMessage = 'Could not find your city. Pick one below.';
        return;
      }
      location = city;
      errorMessage = cityIssue(city, required: true);
      locationOn = true;
      if (live && _api.hasSession) {
        await _api.saveLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _locationSavedAt = DateTime.now();
      }
    } catch (error) {
      debugPrint('Current location failed: $error');
      errorMessage = 'Could not get your location. Pick a city below.';
    } finally {
      _locating = false;
      notifyListeners();
    }
  }

  bool _locating = false;
  bool get locating => _locating;

  Future<void> enterApp() async {
    if (!live) {
      go(AppRoute.club);
      return;
    }
    await _guard(() async {
      await _api.updatePrivate(onboardingCompleted: true);
      _onboardingComplete = true;
      await _loadPeople();
      go(AppRoute.club);
    });
  }

  Future<void> passClub() async {
    final person = clubPerson;
    if (!live) {
      profiles += 1;
      notifyListeners();
      return;
    }
    if (person == null) return;
    if (person.id.isEmpty) {
      _removeVisible(person);
      notifyListeners();
      return;
    }
    await _guard(() async {
      await _api.pass(person.id);
      _removeVisible(person);
    });
  }

  Future<void> inviteClub() async {
    final person = clubPerson;
    if (!live) {
      go(AppRoute.inviteSent);
      return;
    }
    if (person == null) return;
    if (person.id.isEmpty) {
      _removeVisible(person);
      go(AppRoute.inviteSent);
      return;
    }
    await _guard(() async {
      await _api.invite(person.id);
      _removeVisible(person);
      go(AppRoute.inviteSent);
    });
  }

  Future<void> refreshClub() async {
    if (!live) {
      profiles = 0;
      notifyListeners();
      return;
    }
    await _guard(_loadPeople);
  }

  Future<void> refreshPeople() async {
    if (!live) return;
    try {
      await _loadPeople();
      errorMessage = null;
    } catch (error) {
      debugPrint('Clubmates save failed: $error');
      errorMessage = _message(error);
    }
    notifyListeners();
  }

  /// Picks up invites and mates that arrived while the app was in the
  /// background, so the tab badges are current.
  Future<void> refreshOnResume() async {
    if (!live || !_api.hasSession || !_onboardingComplete) return;
    try {
      await _loadPeople();
      notifyListeners();
    } catch (error) {
      debugPrint('Resume refresh failed: $error');
    }
  }

  void keepExploring() {
    if (!live) profiles += 1;
    go(AppRoute.club);
  }

  void openPerson(Person person, AppRoute next) {
    opened = person;
    go(next);
  }

  void openChat() {
    final person = opened;
    if (person == null) return;
    final mateId = person.mateId ?? (live ? null : 'sample-${person.name}');
    if (mateId == null) return;
    if (chat?.mateId != mateId) {
      _closeChat();
      chat = ChatController(
        api: live ? _api : null,
        mateId: mateId,
        myId: live ? (_api.userId ?? '') : 'me',
        onActivity: _refreshThreadsSoon,
      )..start();
    }
    go(AppRoute.mateChat);
  }

  void _closeChat() {
    final open = chat;
    if (open == null) return;
    chat = null;
    open.dispose();
    _refreshThreadsSoon();
  }

  /// Files a report. With [block], the person is also blocked, which ends
  /// the mate connection and closes the chat.
  Future<bool> report(
    Person person, {
    required String reason,
    String? details,
    String? messageId,
    bool block = false,
  }) async {
    if (!live || person.id.isEmpty) return true;
    final ok = await _guard(() async {
      await _api.report(
        person.id,
        reason: reason,
        details: details,
        messageId: messageId,
        block: block,
      );
      if (block) {
        _candidates.removeWhere((item) => item.id == person.id);
        _incoming.removeWhere((item) => item.id == person.id);
        _mateRows.removeWhere((item) => item.id == person.id);
        if (person.mateId != null) threads.remove(person.mateId);
        blocked = await _api.blocks();
      }
    });
    if (ok && block) go(AppRoute.mates);
    return ok;
  }

  void _startInbox() {
    final uid = _api.userId;
    if (_inbox != null || uid == null) return;
    _inbox = _api.messageChanges(
      'inbox:$uid',
      onChange: (_) => _refreshThreadsSoon(),
    )..subscribe();
  }

  void _stopInbox() {
    final inbox = _inbox;
    _inbox = null;
    _threadsSoon?.cancel();
    if (inbox != null) _api.closeChannel(inbox);
  }

  void _refreshThreadsSoon() {
    if (!live || !_api.hasSession) return;
    _threadsSoon?.cancel();
    _threadsSoon = Timer(const Duration(milliseconds: 400), () async {
      try {
        threads = await _api.mateThreads();
        notifyListeners();
      } catch (error) {
        debugPrint('Thread refresh failed: $error');
      }
    });
  }

  Future<void> setNotify({bool? invites, bool? mates, bool? nearby}) async {
    final (oldInvites, oldMates, oldNearby) = (
      notifyInvites,
      notifyMates,
      notifyNearby,
    );
    if (invites != null) notifyInvites = invites;
    if (mates != null) notifyMates = mates;
    if (nearby != null) notifyNearby = nearby;
    notifyListeners();
    if (!live || !_hasPrivate) return;
    final saved = await _guard(
      () => _api.updatePrivate(
        notifyInvites: invites,
        notifyMates: mates,
        notifyNearby: nearby,
      ),
    );
    if (!saved) {
      notifyInvites = oldInvites;
      notifyMates = oldMates;
      notifyNearby = oldNearby;
      notifyListeners();
    }
  }

  void chooseNearby() {
    nearbyOnly = true;
    errorMessage = null;
    notifyListeners();
  }

  void openNearby({AppRoute back = AppRoute.profile}) {
    nearbyBack = back;
    go(AppRoute.nearby);
  }

  bool _savingLocation = false;
  DateTime? _locationSavedAt;

  Future<void> allowLocation() {
    return captureLocation(interactive: true);
  }

  /// Asks for location from the Club screen and writes the point to the
  /// signed-in profile. Other people do not receive the coordinates.
  Future<void> captureLocation({bool interactive = false}) async {
    if (!live || _savingLocation) return;
    if (!interactive &&
        _locationSavedAt != null &&
        DateTime.now().difference(_locationSavedAt!) <
            const Duration(minutes: 10)) {
      return;
    }
    _savingLocation = true;
    if (interactive) {
      busy = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      locationOn =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (!locationOn) {
        if (interactive) {
          errorMessage = 'Location stays off until you allow it in Settings.';
        }
        return;
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        locationOn = false;
        if (interactive) {
          errorMessage = 'Turn on Location Services to save where you are.';
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await _api.saveLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _locationSavedAt = DateTime.now();
      locationOn = true;
      if (interactive) errorMessage = null;
    } catch (_) {
      if (interactive) errorMessage = 'Location could not be saved.';
    } finally {
      _savingLocation = false;
      if (interactive) busy = false;
      notifyListeners();
    }
  }

  List<Person> _offlineClub() {
    return const [meera, kabir, aria, riya];
  }

  void _removeVisible(Person person) {
    final index = _candidates.indexWhere(
      (item) => item.id == person.id && item.name == person.name,
    );
    if (index >= 0) _candidates.removeAt(index);
  }

  Future<void> passInvite() async {
    if (!live) {
      showInvites = false;
      go(AppRoute.invites);
      return;
    }
    final inviteId = opened?.inviteId;
    if (inviteId == null) return;
    await _guard(() async {
      await _api.respond(inviteId, accept: false);
      await _loadPeople();
      go(AppRoute.invites);
    });
  }

  Future<void> acceptInvite() async {
    if (!live) {
      showInvites = false;
      showMates = true;
      go(AppRoute.mates);
      return;
    }
    final inviteId = opened?.inviteId;
    if (inviteId == null) return;
    await _guard(() async {
      await _api.respond(inviteId, accept: true);
      await _loadPeople();
      go(AppRoute.mates);
    });
  }

  Future<void> removeMate() async {
    if (!live) {
      showMates = false;
      go(AppRoute.mates);
      return;
    }
    final mateId = opened?.mateId;
    if (mateId == null) return;
    await _guard(() async {
      await _api.endMate(mateId);
      await _loadPeople();
      go(AppRoute.mates);
    });
  }

  Future<void> blockOpened() async {
    final person = opened;
    if (!live || person == null || person.id.isEmpty) return;
    await _guard(() async {
      await _api.block(person.id);
      _candidates.removeWhere((item) => item.id == person.id);
      _incoming.removeWhere((item) => item.id == person.id);
      _mateRows.removeWhere((item) => item.id == person.id);
      go(AppRoute.club);
    });
  }

  Future<void> unblock(String userId) async {
    if (!live) return;
    await _guard(() async {
      await _api.unblock(userId);
      blocked = await _api.blocks();
    });
  }

  Future<void> setDiscoverable(bool value) async {
    discoverable = value;
    notifyListeners();
    if (!live) return;
    await _guard(() => _api.updatePrivate(discoverable: value));
  }

  bool get outTonight => isOutTonight(outTonightUntil);

  /// Without [forDuration], the status lasts until [endOfNight].
  Future<void> setOutTonight({required bool on, Duration? forDuration}) async {
    final previous = outTonightUntil;
    final until = !on
        ? null
        : forDuration == null
        ? endOfNight()
        : DateTime.now().add(forDuration);
    outTonightUntil = until;
    notifyListeners();
    if (!live) return;
    final saved = await _guard(() => _api.setOutTonight(until));
    if (!saved) {
      outTonightUntil = previous;
      notifyListeners();
    }
  }

  Future<void> saveEdits({
    required String nextName,
    required String nextBio,
    required String nextCity,
  }) async {
    final nameError = nameIssue(nextName, required: true);
    final cityError = cityIssue(nextCity, required: true);
    final aboutError = bioIssue(nextBio);
    final stature = heightIssue(height);
    final plan = planIssue(planTonight);
    final issue = nameError ?? cityError ?? aboutError ?? stature ?? plan;
    if (issue != null) {
      errorMessage = issue;
      notifyListeners();
      return;
    }
    final trimmedName = nextName.trim();
    final trimmedCity = nextCity.trim();
    final trimmedBio = nextBio.trim();
    if (!live) {
      name = trimmedName;
      location = trimmedCity.isEmpty ? location : trimmedCity;
      bio = trimmedBio;
      _interestedIn = interestCode(lookingFor) ?? _interestedIn;
      go(AppRoute.profile);
      return;
    }
    await _guard(() async {
      await _api.updateProfile(
        displayName: trimmedName,
        bio: trimmedBio.isEmpty ? null : trimmedBio,
        clearBio: true,
        city: trimmedCity,
        gender: genderCode(sex),
        heightCm: height.trim().isEmpty ? null : int.parse(height.trim()),
      );
      await _api.updateNightlife(
        planTonight: planTonight,
        interests: interests,
      );
      planTonight = planTonight.trim();
      await _api.saveOwnPrompts(prompts);
      prompts = await _api.loadOwnPrompts();
      final chosen = interestCode(lookingFor);
      if (_hasPrivate && chosen != null) {
        await _api.updatePrivate(interestedIn: chosen);
        _interestedIn = chosen;
      }
      name = trimmedName;
      location = trimmedCity;
      bio = trimmedBio;
      _hasCity = trimmedCity.isNotEmpty;
      await _loadPeople();
      go(AppRoute.profile);
    });
  }

  Future<void> signOut() async {
    if (live) {
      await _unregisterPush();
      await _guard(_api.signOut);
    }
    _resetLocal();
    go(AppRoute.phone);
  }

  Future<void> deleteAccount() async {
    if (!live) {
      _resetLocal();
      go(AppRoute.phone);
      return;
    }
    await _unregisterPush();
    final removed = await _guard(() async {
      await _api.deleteAccount();
      try {
        await _api.signOut();
      } catch (_) {
        // The auth user is already gone, so ending the session can fail.
      }
    });
    if (!removed) return;
    _resetLocal();
    go(AppRoute.phone);
  }

  Future<bool> _guard(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      debugPrint('Clubmates save failed: $error');
      errorMessage = _message(error);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _resume() async {
    var account = await _api.loadAccount();
    if (!account.hasProfile) {
      await _api.createProfile('New');
      account = await _api.loadAccount();
    }
    _applyAccount(account);
    ownPhotos = account.hasProfile ? await _api.loadOwnPhotos() : [];
    prompts = account.hasProfile ? await _loadPromptsSafely() : [];
    await _openNextStep();
  }

  Future<List<ProfilePrompt>> _loadPromptsSafely() async {
    try {
      return await _api.loadOwnPrompts();
    } catch (error) {
      debugPrint('Prompts failed: $error');
      return prompts;
    }
  }

  Future<void> _openNextStep() async {
    if (_interestedIn == null) {
      go(AppRoute.interest);
      return;
    }
    if (!_hasProfile) {
      go(AppRoute.name);
      return;
    }
    if (_dob == null) {
      go(AppRoute.dob);
      return;
    }
    if (!_hasCity) {
      go(AppRoute.location);
      return;
    }
    if (!_hasGender) {
      go(AppRoute.about);
      return;
    }
    if (!_onboardingComplete) {
      go(ownPhotos.isEmpty ? AppRoute.photos : AppRoute.prompts);
      return;
    }
    await _loadPeople();
    go(AppRoute.club);
  }

  Future<void> _loadPeople() async {
    _extras.clear();
    final discovered = await _api.discover();
    final invites = await _api.incomingInvites();
    final mates = await _api.mates();
    _candidates
      ..clear()
      ..addAll(discovered.map(_card));
    _incoming
      ..clear()
      ..addAll(invites.map(_card));
    _mateRows
      ..clear()
      ..addAll(mates.map(_card));
    try {
      threads = await _api.mateThreads();
      _startInbox();
    } catch (error) {
      debugPrint('Chat threads failed: $error');
    }
    blocked = await _api.blocks();
    ownPhotos = await _api.loadOwnPhotos();
    prompts = await _loadPromptsSafely();
  }

  void _applyAccount(OwnAccount account) {
    _hasProfile = account.hasProfile;
    _hasPrivate = account.dateOfBirth != null;
    _hasGender = account.gender != null;
    _hasCity = account.city.trim().isNotEmpty;
    _onboardingComplete = account.onboardingCompleted;
    _interestedIn = account.interestedIn ?? _interestedIn;
    _verified = account.verified;
    _dob = account.dateOfBirth;
    discoverable = account.discoverable;
    outTonightUntil = account.outTonightUntil;
    notifyInvites = account.notifyInvites;
    notifyMates = account.notifyMates;
    notifyNearby = account.notifyNearby;
    if (account.interestedIn != null) {
      lookingFor = interestLabels[account.interestedIn] ?? lookingFor;
    }
    if (account.displayName.isNotEmpty) name = account.displayName;
    bio = account.bio;
    planTonight = account.planTonight;
    interests = account.interests;
    if (account.city.isNotEmpty) location = account.city;
    sex = genderLabels[account.gender] ?? sex;
    height = account.heightCm?.toString() ?? height;
    if (account.dateOfBirth != null) {
      day = account.dateOfBirth!.day.toString().padLeft(2, '0');
      month = account.dateOfBirth!.month.toString().padLeft(2, '0');
      year = account.dateOfBirth!.year.toString();
    }
  }

  Person _card(PublicPerson person) {
    final plan = person.planTonight.trim();
    final preview = plan.isNotEmpty
        ? plan
        : person.bio.trim().isEmpty
        ? 'No plans shared yet.'
        : person.bio.trim();
    return Person(
      id: person.id,
      name: person.name,
      age: person.age,
      location: person.city,
      tonight: plan.isEmpty ? 'No plans shared yet.' : plan,
      usually: '',
      interests: person.interests,
      photo: person.photoUrl,
      preview: preview,
      verified: person.verified,
      inviteId: person.inviteId,
      mateId: person.mateId,
      outTonightUntil: person.outTonightUntil,
    );
  }

  void _resetLocal() {
    phone = '';
    otp = List.filled(6, '');
    otpError = false;
    name = '';
    day = '';
    month = '';
    year = '';
    location = 'Bengaluru';
    lookingFor = '';
    bio = '';
    height = '';
    planTonight = '';
    interests = [];
    _dob = null;
    _hasProfile = false;
    _hasPrivate = false;
    _hasGender = false;
    _hasCity = false;
    _onboardingComplete = false;
    _interestedIn = null;
    _verified = false;
    ownPhotos = [];
    prompts = [];
    _extras.clear();
    blocked = [];
    opened = null;
    _candidates.clear();
    _incoming.clear();
    _mateRows.clear();
    _closeChat();
    _stopInbox();
    threads = {};
    _locationSavedAt = null;
    locationOn = false;
    outTonightUntil = null;
    notifyInvites = true;
    notifyMates = true;
    notifyNearby = false;
    _verificationId = null;
    _resendToken = null;
    errorMessage = null;
  }

  String _message(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-verification-code' ||
        'invalid-verification-id' ||
        'session-expired' ||
        'code-expired' => wrongCodeMessage,
        'invalid-phone-number' => 'Enter a valid 10-digit mobile number.',
        'too-many-requests' ||
        'quota-exceeded' => 'Too many tries. Wait a while and try again.',
        'network-request-failed' => 'No connection. Check your internet.',
        'operation-not-allowed' => 'Phone sign-in is not available yet.',
        _ => 'Could not send the code. Try again.',
      };
    }
    if (error is FunctionException) {
      final details = error.details;
      final text = details is Map ? details['error'] : null;
      return text is String ? text : 'Sign-in failed. Try again.';
    }
    if (error is AuthException) return error.message;
    if (error is PostgrestException) return error.message;
    if (error is StorageException) return error.message;
    return 'Something went wrong. Try again.';
  }
}

class AppScope extends InheritedNotifier<AppModel> {
  const AppScope({super.key, required AppModel model, required super.child})
    : super(notifier: model);

  static AppModel watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  }

  static AppModel read(BuildContext context) {
    return context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
  }
}
