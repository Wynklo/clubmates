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
