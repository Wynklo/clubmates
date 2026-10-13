import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/clubmates_repository.dart';
import '../data/records.dart';
export '../data/records.dart'
    show
        bioIssue,
        cityIssue,
        dobIsComplete,
        dobIssue,
        heightIssue,
        interestCode,
        interestLabels,
        maxProfilePhotos,
        nameIssue,
        OwnPhoto,
        phoneIssue;
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
  identity,
  face,
  verified,
  club,
  details,
  inviteSent,
  likes,
  inviteDetail,
  mates,
  mateProfile,
  mateChat,
  profile,
  editProfile,
  settings,
  notifications,
  nearby,
  status,
  error,
}

enum AppTab { club, likes, mates, profile }

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
    this.minutesAgo,
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
  final int? minutesAgo;
  final double? distanceKm;

  bool get recentlyActive => minutesAgo != null && minutesAgo! <= 20;
}

String? recentActivity(int? minutesAgo) {
  if (minutesAgo == null || minutesAgo > 20) return null;
  if (minutesAgo <= 1) return 'Active now';
  return 'Active ${minutesAgo}m ago';
}

class ChatLine {
  const ChatLine(this.text, {this.mine = true});

  final String text;
  final bool mine;
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
  minutesAgo: 4,
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
  minutesAgo: 12,
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
  minutesAgo: 40,
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
  minutesAgo: 6,
  distanceKm: 4,
);

const nightPhoto = 'assets/photos/night.jpg';
const ownPhoto = 'assets/photos/meera_alt.jpg';

const nightlifeOptions = [
  'Drinks',
  'Clubs',
  'Cafés',
  'Dinner',
  'Live Music',
  'Rooftops',
  'Late-night Food',
  'Road Trips',
  'House Parties',
  'Events',
];

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
  List<String> interests = ['Drinks', 'Live Music', 'Dinner'];
  String sex = 'Woman';
  String lookingFor = '';
  String? _interestedIn;
  bool _hasGender = false;
  bool _hasCity = false;
  bool _onboardingComplete = false;
  String idType = 'Aadhaar';
  bool uploaded = false;
  bool discoverable = true;
  bool locationOn = false;
  bool nearbyOnly = true;
  AppRoute nearbyBack = AppRoute.profile;
  bool notifyInvites = true;
  bool notifyMates = true;
  bool notifyNearby = false;
  bool showLikes = true;
  bool showMates = true;
  int profiles = 0;
  List<OwnPhoto> ownPhotos = [];
  List<BlockedPerson> blocked = [];
  Person? opened;
  final List<Person> _candidates = [];
  final List<Person> _incoming = [];
  final List<Person> _mateRows = [];
  final Map<String, List<ChatLine>> _chats = {};

  AppTab get tab => switch (route) {
    AppRoute.likes || AppRoute.inviteDetail => AppTab.likes,
    AppRoute.mates || AppRoute.mateProfile || AppRoute.mateChat => AppTab.mates,
    AppRoute.profile ||
    AppRoute.editProfile ||
    AppRoute.settings ||
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

  List<Person> get incoming => live ? _incoming : (showLikes ? [aria] : []);

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
    route = next;
    errorMessage = null;
    notifyListeners();
  }

  void goTab(AppTab next) {
    _lensFrom = switch (tab) {
      AppTab.club => 0,
      AppTab.likes => 1,
      AppTab.mates => 2,
      AppTab.profile => 3,
    };
    route = switch (next) {
      AppTab.club => AppRoute.club,
      AppTab.likes => AppRoute.likes,
      AppTab.mates => AppRoute.mates,
      AppTab.profile => AppRoute.profile,
    };
    notifyListeners();
  }

  int _lensFrom = 0;

  int get lensFrom => _lensFrom;

  Future<void> start() async {
    if (!live || !_api.hasSession) {
      go(AppRoute.phone);
      return;
    }
    final ok = await _guard(_resume);
    if (!ok && route == AppRoute.splash) go(AppRoute.error);
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

  bool get testLogin => live && _devPassword.isNotEmpty;

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
    await _guard(() async {
      await _api.sendOtp('+91$phone');
      if (!resend) go(AppRoute.otp);
    });
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
      if (!ok) {
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
    final ok = await _guard(() async {
      await _api.verifyOtp('+91$phone', otp.join());
      await _resume();
    });
    if (!ok) {
      otpError = true;
      notifyListeners();
    }
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
    interests = interests.contains(item)
        ? interests.where((interest) => interest != item).toList()
        : [...interests, item];
    notifyListeners();
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

  void setIdType(String value) {
    idType = value;
    notifyListeners();
  }

  void markUploaded() {
    uploaded = true;
    notifyListeners();
  }

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

  void keepExploring() {
    if (!live) profiles += 1;
    go(AppRoute.club);
  }

  void openPerson(Person person, AppRoute next) {
    opened = person;
    go(next);
  }

  void openChat() {
    if (opened == null) return;
    go(AppRoute.mateChat);
  }

  List<ChatLine> chatForOpened() {
    final person = opened;
    if (person == null) return const [];
    return _chats[_chatKey(person)] ?? const [];
  }

  void sendChat(String text) {
    final trimmed = text.trim();
    final person = opened;
    if (trimmed.isEmpty || person == null) return;
    final key = _chatKey(person);
    _chats[key] = [...?_chats[key], ChatLine(trimmed)];
    notifyListeners();
  }

  void exploreClubsTogether() {
    sendChat('Shared a plan: Explore clubs together');
  }

  void shareNearbyDrinks() {
    sendChat('Shared a plan: Find drinks nearby');
  }

  void setNotify({bool? invites, bool? mates, bool? nearby}) {
    if (invites != null) notifyInvites = invites;
    if (mates != null) notifyMates = mates;
    if (nearby != null) notifyNearby = nearby;
    notifyListeners();
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

  String _chatKey(Person person) {
    return person.id.isEmpty ? person.name : person.id;
  }

  Future<void> passInvite() async {
    if (!live) {
      showLikes = false;
      go(AppRoute.likes);
      return;
    }
    final inviteId = opened?.inviteId;
    if (inviteId == null) return;
    await _guard(() async {
      await _api.respond(inviteId, accept: false);
      await _loadPeople();
      go(AppRoute.likes);
    });
  }

  Future<void> acceptInvite() async {
    if (!live) {
      showLikes = false;
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

  Future<void> saveEdits({
    required String nextName,
    required String nextBio,
    required String nextCity,
  }) async {
    final nameError = nameIssue(nextName, required: true);
    final cityError = cityIssue(nextCity, required: true);
    final aboutError = bioIssue(nextBio);
    final stature = heightIssue(height);
    final issue = nameError ?? cityError ?? aboutError ?? stature;
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
    await _openNextStep();
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
      go(AppRoute.photos);
      return;
    }
    await _loadPeople();
    go(AppRoute.club);
  }

  Future<void> _loadPeople() async {
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
    blocked = await _api.blocks();
    ownPhotos = await _api.loadOwnPhotos();
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
    if (account.interestedIn != null) {
      lookingFor = interestLabels[account.interestedIn] ?? lookingFor;
    }
    if (account.displayName.isNotEmpty) name = account.displayName;
    bio = account.bio;
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
    final preview = person.bio.trim().isEmpty
        ? 'Out tonight.'
        : person.bio.trim();
    return Person(
      id: person.id,
      name: person.name,
      age: person.age,
      location: person.city,
      tonight: preview,
      usually: '',
      interests: const [],
      photo: person.photoUrl,
      preview: preview,
      verified: person.verified,
      inviteId: person.inviteId,
      mateId: person.mateId,
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
    _dob = null;
    _hasProfile = false;
    _hasPrivate = false;
    _hasGender = false;
    _hasCity = false;
    _onboardingComplete = false;
    _interestedIn = null;
    _verified = false;
    ownPhotos = [];
    blocked = [];
    opened = null;
    _candidates.clear();
    _incoming.clear();
    _mateRows.clear();
    _chats.clear();
    _locationSavedAt = null;
    locationOn = false;
    errorMessage = null;
  }

  String _message(Object error) {
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
