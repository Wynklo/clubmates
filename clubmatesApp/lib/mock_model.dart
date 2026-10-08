import 'package:flutter/widgets.dart';

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
    required this.name,
    required this.age,
    required this.location,
    required this.tonight,
    required this.usually,
    required this.interests,
    required this.photo,
    required this.preview,
  });

  final String name;
  final int age;
  final String location;
  final String tonight;
  final String usually;
  final List<String> interests;
  final String photo;
  final String preview;
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
  AppRoute route = AppRoute.splash;
  String phone = '';
  List<String> otp = List.filled(6, '');
  bool otpError = false;
  String name = '';
  String location = 'Bengaluru';
  List<String> interests = ['Drinks', 'Live Music', 'Dinner'];
  String sex = 'Woman';
  String idType = 'Aadhaar';
  bool uploaded = false;
  bool showLikes = true;
  bool showMates = true;
  int profiles = 0;

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

  MockPerson get clubPerson => profiles == 0 ? meera : kabir;

  String get displayName => name.trim().isEmpty ? 'Aanya' : name.trim();

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

  void verifyOtp() {
    if (otp.join() == '000000') {
      otpError = true;
      notifyListeners();
      return;
    }
    go(AppRoute.name);
  }

  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setLocation(String value) {
    location = value;
    notifyListeners();
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

  void setIdType(String value) {
    idType = value;
    notifyListeners();
  }

  void markUploaded() {
    uploaded = true;
    notifyListeners();
  }

  void passClub() {
    profiles += 1;
    notifyListeners();
  }

  void refreshClub() {
    profiles = 0;
    notifyListeners();
  }

  void keepExploring() {
    profiles += 1;
    go(AppRoute.club);
  }

  void passInvite() {
    showLikes = false;
    go(AppRoute.likes);
  }

  void acceptInvite() {
    showLikes = false;
    showMates = true;
    go(AppRoute.mates);
  }

  void removeMate() {
    showMates = false;
    go(AppRoute.mates);
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
