/// Display-safe profile fields. Date of birth never leaves the owner row.
class PublicPerson {
  const PublicPerson({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.bio,
    required this.verified,
    required this.photoUrl,
    this.inviteId,
    this.mateId,
    this.outTonightUntil,
    this.planTonight = '',
    this.interests = const [],
  });

  final String id;
  final String name;
  final int age;
  final String city;
  final String bio;
  final bool verified;
  final String photoUrl;
  final String? inviteId;
  final String? mateId;
  final DateTime? outTonightUntil;
  final String planTonight;
  final List<String> interests;
}

const maxPlanTonight = 120;
const maxInterests = 6;

const planSuggestions = [
  'Dinner, then a bar',
  'Dancing till late',
  'Chill drinks with good music',
  'Rooftop sundowners',
  'Live gig, then food',
  'Open to ideas',
];

const interestOptions = [
  'Drinks',
  'Clubbing',
  'Live Music',
  'Techno',
  'House Music',
  'Hip-hop',
  'Bollywood Nights',
  'Rooftops',
  'Cocktail Bars',
  'Craft Beer',
  'Cafés',
  'Dinner',
  'Late-night Food',
  'Karaoke',
  'Stand-up Comedy',
  'Events',
  'House Parties',
  'Road Trips',
];

String? planIssue(String value) {
  if (value.trim().length > maxPlanTonight) {
    return 'Keep your plan to $maxPlanTonight characters.';
  }
  return null;
}

DateTime? parseTimestamp(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

class OwnPhoto {
  const OwnPhoto({
    required this.id,
    required this.path,
    required this.url,
    required this.order,
    required this.primary,
    required this.moderation,
  });

  final String id;
  final String path;
  final String url;
  final int order;
  final bool primary;
  final String moderation;
}

const maxProfilePhotos = 3;

class ProfilePrompt {
  const ProfilePrompt({required this.prompt, required this.answer});

  factory ProfilePrompt.fromRow(Map<String, dynamic> row) => ProfilePrompt(
    prompt: row['prompt'] as String? ?? '',
    answer: row['answer'] as String? ?? '',
  );

  final String prompt;
  final String answer;
}

const maxProfilePrompts = 3;
const maxPromptAnswer = 200;

const promptOptions = [
  'My ideal night out looks like',
  'A fun fact about me',
  'Two truths and a lie',
  'My go-to drink order',
  'The song that gets me on the dance floor',
  'Best night out I have ever had',
  "I'm known in my group for",
  "Don't leave the club without",
  'My late-night food spot',
  "I'll never say no to",
  'The most spontaneous thing I have done',
  'My weekend usually involves',
];

/// Everything shown on someone else's full profile beyond the card.
class ProfileExtras {
  const ProfileExtras({required this.photos, required this.prompts});

  final List<String> photos;
  final List<ProfilePrompt> prompts;
}

const minHeightCm = 120;
const maxHeightCm = 220;

/// 172 -> 5'8"
String feetLabel(int cm) {
  final totalInches = (cm / 2.54).round();
  return "${totalInches ~/ 12}'${totalInches % 12}\"";
}

class OwnAccount {
  const OwnAccount({
    required this.hasProfile,
    required this.displayName,
    required this.bio,
    required this.city,
    required this.gender,
    required this.heightCm,
    required this.verified,
    required this.dateOfBirth,
    required this.discoverable,
    required this.onboardingCompleted,
    required this.interestedIn,
    this.outTonightUntil,
    this.notifyInvites = true,
    this.notifyMates = true,
    this.notifyNearby = false,
    this.planTonight = '',
    this.interests = const [],
  });

  final bool hasProfile;
  final String displayName;
  final String bio;
  final String city;
  final String? gender;
  final int? heightCm;
  final bool verified;
  final DateTime? dateOfBirth;
  final bool discoverable;
  final bool onboardingCompleted;
  final String? interestedIn;
  final DateTime? outTonightUntil;
  final bool notifyInvites;
  final bool notifyMates;
  final bool notifyNearby;
  final String planTonight;
  final List<String> interests;

  static const empty = OwnAccount(
    hasProfile: false,
    displayName: '',
    bio: '',
    city: '',
    gender: null,
    heightCm: null,
    verified: false,
    dateOfBirth: null,
    discoverable: true,
    onboardingCompleted: false,
    interestedIn: null,
  );
}

class BlockedPerson {
  const BlockedPerson({required this.id, required this.name});

  final String id;
  final String name;
}

const genderLabels = {
  'WOMAN': 'Woman',
  'MAN': 'Man',
  'NON_BINARY': 'Non-binary',
  'PREFER_NOT_TO_SAY': 'Prefer not to say',
};

String? genderCode(String label) {
  for (final entry in genderLabels.entries) {
    if (entry.value == label) return entry.key;
  }
  return null;
}

const interestLabels = {
  'WOMAN': 'Women',
  'MAN': 'Men',
  'NON_BINARY': 'Non-binary',
  'EVERYONE': 'Everyone',
};

String? interestCode(String label) {
  for (final entry in interestLabels.entries) {
    if (entry.value == label) return entry.key;
  }
  return null;
}

String digitsOnly(String value, int max) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= max) return digits;
  return digits.substring(0, max);
}

/// Month, then date, then year. Incomplete fields explain what is still short.
String? dobIssue(String day, String month, String year, {DateTime? today}) {
  if (month.isNotEmpty && month.length != 2) {
    return 'Month needs 2 digits, like 04.';
  }
  if (month.length == 2) {
    final value = int.tryParse(month);
    if (value == null || value < 1 || value > 12) {
      return 'Month must be 01 to 12.';
    }
  }
  if (day.isNotEmpty && day.length != 2) {
    return 'Date needs 2 digits, like 12.';
  }
  if (day.length == 2) {
    final value = int.tryParse(day);
    if (value == null || value < 1 || value > 31) {
      return 'Date must be 01 to 31.';
    }
  }
  if (year.isNotEmpty && year.length != 4) {
    return 'Year needs 4 digits, like 1998.';
  }
  if (day.length != 2 || month.length != 2 || year.length != 4) return null;
  final parsed = parseDob(int.parse(day), int.parse(month), int.parse(year));
  if (parsed == null) return 'That date does not exist.';
  if (!isAtLeast18(parsed, today ?? DateTime.now())) {
    return 'You need to be 18 or older.';
  }
  return null;
}

bool dobIsComplete(String day, String month, String year, {DateTime? today}) {
  return day.length == 2 &&
      month.length == 2 &&
      year.length == 4 &&
      dobIssue(day, month, year, today: today) == null;
}

String? nameIssue(String value, {bool required = false}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return required ? 'Enter your name.' : null;
  if (trimmed.length > 60) return 'Use a name up to 60 characters.';
  if (!RegExp(r"^[A-Za-z][A-Za-z .'\-]{0,59}$").hasMatch(trimmed)) {
    return 'Use letters only.';
  }
  return null;
}

String? phoneIssue(String digits) {
  if (digits.isEmpty) return null;
  if (!RegExp(r'^\d{10}$').hasMatch(digits)) {
    return 'Enter a 10-digit mobile number.';
  }
  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
    return 'Enter a valid Indian mobile number.';
  }
  return null;
}

String? cityIssue(String value, {bool required = false}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return required ? 'Enter a city.' : null;
  if (trimmed.length > 100) return 'City should be 100 characters or less.';
  if (!RegExp(r"^[A-Za-z][A-Za-z .'\-]{0,99}$").hasMatch(trimmed)) {
    return 'Use letters for the city.';
  }
  return null;
}

String? heightIssue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (!RegExp(r'^\d{2,3}$').hasMatch(trimmed)) {
    return 'Height should be in centimetres, like 172.';
  }
  final cm = int.parse(trimmed);
  if (cm < minHeightCm || cm > maxHeightCm) {
    return 'Height should be between $minHeightCm and $maxHeightCm cm.';
  }
  return null;
}

String? bioIssue(String value) {
  if (value.trim().length > 500) return 'Bio should be 500 characters or less.';
  return null;
}

DateTime? parseDob(int day, int month, int year) {
  if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

bool isAtLeast18(DateTime dob, DateTime today) {
  final limit = DateTime(today.year - 18, today.month, today.day);
  return !dob.isAfter(limit);
}

int ageOn(DateTime dob, DateTime today) {
  var age = today.year - dob.year;
  final birthdayPassed =
      today.month > dob.month ||
      (today.month == dob.month && today.day >= dob.day);
  if (!birthdayPassed) age -= 1;
  return age;
}
