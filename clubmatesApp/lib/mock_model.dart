import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/clubmates_repository.dart';
import 'data/records.dart';
import 'data/supabase_config.dart';

enum AppRoute {
  splash,
  phone,
  otp,
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
  profile,
  editProfile,
  settings,
  status,
  error,
}

enum AppTab { club, likes, mates, profile }

class MockPerson {
  const MockPerson({
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
}

const meera = MockPerson(
  name: 'Meera',
  age: 27,
  location: 'Indiranagar',
  tonight: 'Dinner, then a bar in Indiranagar.',
  usually: 'Low-key drinks, live music and good food.',
  interests: ['Drinks', 'Food', 'Live Music'],
  photo: 'assets/photos/meera.jpg',
  preview: 'Dinner, then a bar in Indiranagar.',
);

const kabir = MockPerson(
  name: 'Kabir',
  age: 29,
  location: 'Koramangala',
  tonight: 'Live music and a late dinner.',
  usually: 'Low-key drinks, live music and good food.',
  interests: ['Drinks', 'Food', 'Live Music'],
  photo: 'assets/photos/kabir.jpg',
  preview: 'Live music and a late dinner.',
);

const aria = MockPerson(
  name: 'Aria',
  age: 26,
  location: 'Bandra',
  tonight: 'Drinks and dinner somewhere in Bandra.',
  usually: 'Good food, live sets and unhurried evenings.',
  interests: ['Drinks', 'Dinner', 'Live Music'],
  photo: 'assets/photos/aria.jpg',
  preview: 'Drinks, dinner, live music',
);

const riya = MockPerson(
  name: 'Riya',
  age: 25,
  location: 'Koregaon Park',
  tonight: 'Rooftop drinks after 8.',
  usually: 'Low-key drinks, live music and good food.',
  interests: ['Drinks', 'Food', 'Live Music'],
  photo: 'assets/photos/riya.jpg',
  preview: 'Tonight: rooftop drinks',
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

class MockModel extends ChangeNotifier {
  MockModel({ClubmatesRepository? repository, ImagePicker? picker})
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
  String phone = kDebugMode ? '9999999999' : '';
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
  String idType = 'Aadhaar';
  bool uploaded = false;
  bool discoverable = true;
  bool showLikes = true;
  bool showMates = true;
  int profiles = 0;
  List<OwnPhoto> ownPhotos = [];
  List<BlockedPerson> blocked = [];
  MockPerson? opened;
  final List<MockPerson> _candidates = [];
  final List<MockPerson> _incoming = [];
  final List<MockPerson> _mateRows = [];

  AppTab get tab => switch (route) {
    AppRoute.likes || AppRoute.inviteDetail => AppTab.likes,
    AppRoute.mates || AppRoute.mateProfile => AppTab.mates,
    AppRoute.profile ||
    AppRoute.editProfile ||
    AppRoute.settings ||
    AppRoute.status ||
    AppRoute.error => AppTab.profile,
    _ => AppTab.club,
  };

  MockPerson? get clubPerson {
    if (!live) {
      if (profiles > 1) return null;
      return profiles == 0 ? meera : kabir;
    }
    if (_candidates.isEmpty) return null;
    return _candidates.first;
  }

  List<MockPerson> get incoming => live ? _incoming : (showLikes ? [aria] : []);

  List<MockPerson> get mateList => live ? _mateRows : (showMates ? [riya] : []);

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

  MockPerson personFor(AppRoute kind) {
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
    notifyListeners();
  }

  void goTab(AppTab next) {
    route = switch (next) {
      AppTab.club => AppRoute.club,
      AppTab.likes => AppRoute.likes,
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
    final digits = value.replaceAll(RegExp(r'\D'), '');
    phone = digits.length > 10 ? digits.substring(0, 10) : digits;
    notifyListeners();
  }

  void setOtp(int index, String value) {
    final next = [...otp];
    next[index] = value.isEmpty ? '' : value.substring(value.length - 1);
    otp = next;
    otpError = false;
    notifyListeners();
  }

  bool get _devPhone => live && kDebugMode && phone == '9999999999';

  Future<void> sendCode({bool resend = false}) async {
    if (!live) {
      go(AppRoute.otp);
      return;
    }
    if (_devPhone) {
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
    if (_devPhone) {
      if (otp.join() != '111111') {
        otpError = true;
        errorMessage = null;
        notifyListeners();
        return;
      }
      final ok = await _guard(() async {
        await _api.signInDevPhone();
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
      go(AppRoute.name);
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
    notifyListeners();
  }

  Future<void> saveName() async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 60) {
      errorMessage = 'Use a name up to 60 characters.';
      notifyListeners();
      return;
    }
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
    if (nextDay != null) day = nextDay;
    if (nextMonth != null) month = nextMonth;
    if (nextYear != null) year = nextYear;
    notifyListeners();
  }

  bool get dobReady => day.isNotEmpty && month.isNotEmpty && year.length == 4;

  Future<void> saveDob() async {
    final dob = parseDob(
      int.tryParse(day) ?? 0,
      int.tryParse(month) ?? 0,
      int.tryParse(year) ?? 0,
    );
    if (dob == null) {
      errorMessage = 'Enter a real date.';
      notifyListeners();
      return;
    }
    if (!isAtLeast18(dob, DateTime.now())) {
      errorMessage = 'You need to be 18 or older.';
      notifyListeners();
      return;
    }
    if (!live) {
      _dob = dob;
      go(AppRoute.location);
      return;
    }
    await _guard(() async {
      if (_hasPrivate) {
        await _api.updatePrivate(dob: dob);
      } else {
        await _api.createPrivate(dob);
        _hasPrivate = true;
      }
      _dob = dob;
      go(AppRoute.location);
    });
  }

  void setLocation(String value) {
    location = value;
    notifyListeners();
  }

  Future<void> saveCity() async {
    final city = location.trim();
    if (city.isEmpty || city.length > 100) {
      errorMessage = 'Enter a city.';
      notifyListeners();
      return;
    }
    if (!live) {
      go(AppRoute.nightlife);
      return;
    }
    await _guard(() async {
      await _api.updateProfile(city: city);
      location = city;
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

  void setHeight(String value) {
    height = value;
    notifyListeners();
  }

  void setBio(String value) {
    bio = value;
    notifyListeners();
  }

  Future<void> saveAbout() async {
    final code = genderCode(sex);
    int? cm;
    final typed = height.trim();
    if (typed.isNotEmpty) {
      cm = int.tryParse(typed);
      if (cm == null || cm < 100 || cm > 250) {
        errorMessage = 'Height should be between 100 and 250 cm.';
        notifyListeners();
        return;
      }
    }
    if (!live) {
      go(AppRoute.photos);
      return;
    }
    await _guard(() async {
      await _api.updateProfile(gender: code, heightCm: cm);
      go(AppRoute.photos);
    });
  }

  Future<void> pickPhoto({required bool camera}) async {
    if (!live) return;
    try {
      final file = await _picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await _guard(() async {
        await _api.uploadPhoto(bytes);
        ownPhotos = await _api.loadOwnPhotos();
      });
    } catch (error) {
      errorMessage = _message(error);
      notifyListeners();
    }
  }

  Future<void> removePhoto(OwnPhoto photo) async {
    if (!live) return;
    await _guard(() async {
      await _api.deletePhoto(photo);
      ownPhotos = await _api.loadOwnPhotos();
    });
  }

  Future<void> makePrimary(OwnPhoto photo) async {
    if (!live || photo.primary) return;
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
    await _guard(() async {
      await _api.pass(person.id);
      if (_candidates.isNotEmpty) _candidates.removeAt(0);
    });
  }

  Future<void> inviteClub() async {
    final person = clubPerson;
    if (!live) {
      go(AppRoute.inviteSent);
      return;
    }
    if (person == null) return;
    await _guard(() async {
      await _api.invite(person.id);
      if (_candidates.isNotEmpty) _candidates.removeAt(0);
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

  void openPerson(MockPerson person, AppRoute next) {
    opened = person;
    go(next);
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
    final trimmedName = nextName.trim();
    final trimmedCity = nextCity.trim();
    final trimmedBio = nextBio.trim();
    if (trimmedName.isEmpty || trimmedName.length > 60) {
      errorMessage = 'Use a name up to 60 characters.';
      notifyListeners();
      return;
    }
    if (trimmedBio.length > 500) {
      errorMessage = 'Bio should be 500 characters or less.';
      notifyListeners();
      return;
    }
    if (!live) {
      name = trimmedName;
      location = trimmedCity.isEmpty ? location : trimmedCity;
      bio = trimmedBio;
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
      );
      name = trimmedName;
      location = trimmedCity;
      bio = trimmedBio;
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

  Future<bool> _guard(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      errorMessage = _message(error);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _resume() async {
    final account = await _api.loadAccount();
    _applyAccount(account);
    ownPhotos = account.hasProfile ? await _api.loadOwnPhotos() : [];
    if (!account.hasProfile) {
      go(AppRoute.name);
      return;
    }
    if (account.dateOfBirth == null) {
      go(AppRoute.dob);
      return;
    }
    if (account.city.trim().isEmpty) {
      go(AppRoute.location);
      return;
    }
    if (account.gender == null) {
      go(AppRoute.about);
      return;
    }
    if (!account.onboardingCompleted) {
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
    _verified = account.verified;
    _dob = account.dateOfBirth;
    discoverable = account.discoverable;
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

  MockPerson _card(PublicPerson person) {
    final preview = person.bio.trim().isEmpty
        ? 'Out tonight.'
        : person.bio.trim();
    return MockPerson(
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
    bio = '';
    height = '';
    _dob = null;
    _hasProfile = false;
    _hasPrivate = false;
    _verified = false;
    ownPhotos = [];
    blocked = [];
    opened = null;
    _candidates.clear();
    _incoming.clear();
    _mateRows.clear();
    errorMessage = null;
  }

  String _message(Object error) {
    if (error is AuthException) return error.message;
    if (error is PostgrestException) return error.message;
    if (error is StorageException) return error.message;
    return 'Something went wrong. Try again.';
  }
}

class MockScope extends InheritedNotifier<MockModel> {
  const MockScope({super.key, required MockModel model, required super.child})
    : super(notifier: model);

  static MockModel watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MockScope>()!.notifier!;
  }

  static MockModel read(BuildContext context) {
    return context.getInheritedWidgetOfExactType<MockScope>()!.notifier!;
  }
}
