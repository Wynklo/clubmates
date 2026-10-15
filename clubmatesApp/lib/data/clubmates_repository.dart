import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'records.dart';

class ClubmatesRepository {
  SupabaseClient get _db => Supabase.instance.client;

  bool get hasSession => _db.auth.currentSession != null;

  String get _uid {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const AuthException('Authentication required');
    return id;
  }

  Future<void> sendOtp(String e164) {
    return _db.auth.signInWithOtp(phone: e164);
  }

  Future<void> verifyOtp(String e164, String token) {
    return _db.auth.verifyOTP(phone: e164, token: token, type: OtpType.sms);
  }

  /// Test sign-in for any Indian mobile until SMS is enabled.
  /// The code is always 111111. At most five new numbers can register.
  /// Pass the shared test password with --dart-define=DEV_LOGIN_PASSWORD=...
  Future<void> signInTestPhone(String phone) async {
    const password = String.fromEnvironment('DEV_LOGIN_PASSWORD');
    if (password.isEmpty) {
      throw const AuthException('Phone sign-in is not available yet.');
    }
    final email = '$phone@clubmates.dev';
    try {
      await _db.auth.signInWithPassword(email: email, password: password);
      return;
    } on AuthException {
      // A new number has no account yet.
    }
    final slots = await _db.rpc('test_phone_slots');
    if (slots is num && slots <= 0) {
      throw const AuthException(
        'Only 5 test numbers can register. Sign in with one you already used.',
      );
    }
    final created = await _db.auth.signUp(email: email, password: password);
    if (created.session != null) return;
    await _db.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _db.auth.signOut();

  /// Removes the signed-in account. Photo files go through the Storage API
  /// first. The database function then deletes the auth user, and the profile
  /// rows cascade from that.
  Future<void> deleteAccount() async {
    final rows = await _db
        .from('profile_photos')
        .select('storage_path')
        .eq('user_id', _uid);
    final paths = <String>{
      for (final row in rows)
        if (row['storage_path'] is String) row['storage_path'] as String,
    };
    try {
      final listed = await _db.storage.from('profile-photos').list(path: _uid);
      for (final file in listed) {
        if (file.name.isEmpty) continue;
        paths.add('$_uid/${file.name}');
      }
    } on StorageException {
      // A person with no uploaded folder still has database rows to remove.
    }
    if (paths.isNotEmpty) {
      await _db.storage.from('profile-photos').remove(paths.toList());
    }
    await _db.rpc('delete_own_account');
  }

  Future<OwnAccount> loadAccount() async {
    final uid = _uid;
    final profile = await _db
        .from('profiles')
        .select(
          'display_name, bio, city, gender, height_cm, is_verified, out_tonight_until',
        )
        .eq('id', uid)
        .maybeSingle();
    final private = await _db
        .from('user_private')
        .select(
          'date_of_birth, discoverable, onboarding_completed, interested_in',
        )
        .eq('user_id', uid)
        .maybeSingle();
    if (profile == null) return OwnAccount.empty;
    return OwnAccount(
      hasProfile: true,
      displayName: profile['display_name'] as String? ?? '',
      bio: profile['bio'] as String? ?? '',
      city: profile['city'] as String? ?? '',
      gender: profile['gender'] as String?,
      heightCm: (profile['height_cm'] as num?)?.toInt(),
      verified: profile['is_verified'] == true,
      dateOfBirth: private == null
          ? null
          : DateTime.parse(private['date_of_birth'] as String),
      discoverable: private == null || private['discoverable'] != false,
      onboardingCompleted: private?['onboarding_completed'] == true,
      interestedIn: private?['interested_in'] as String?,
      outTonightUntil: parseTimestamp(profile['out_tonight_until']),
    );
  }

  Future<void> createProfile(String displayName) {
    return _db.from('profiles').insert({
      'id': _uid,
      'display_name': displayName,
      'is_verified': false,
      'account_status': 'ACTIVE',
    });
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? city,
    String? gender,
    int? heightCm,
    bool clearBio = false,
  }) {
    final fields = <String, dynamic>{
      'display_name': ?displayName,
      if (clearBio || bio != null) 'bio': bio,
      'city': ?city,
      'gender': ?gender,
      'height_cm': ?heightCm,
    };
    return _db.from('profiles').update(fields).eq('id', _uid);
  }

  Future<void> saveLocation({
    required double latitude,
    required double longitude,
  }) {
    return _db
        .from('profiles')
        .update({
          'latitude': latitude,
          'longitude': longitude,
          'location_updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', _uid);
  }

  Future<void> setOutTonight(DateTime? until) {
    return _db
        .from('profiles')
        .update({'out_tonight_until': until?.toUtc().toIso8601String()})
        .eq('id', _uid);
  }

  Future<void> createPrivate(DateTime dob, {String? interestedIn}) {
    final iso = _isoDate(dob);
    return _db.from('user_private').insert({
      'user_id': _uid,
      'date_of_birth': iso,
      'interested_in': ?interestedIn,
    });
  }

  Future<void> updatePrivate({
    DateTime? dob,
    bool? discoverable,
    bool? onboardingCompleted,
    String? interestedIn,
  }) {
    final iso = dob == null ? null : _isoDate(dob);
    return _db
        .from('user_private')
        .update({
          'date_of_birth': ?iso,
          'discoverable': ?discoverable,
          'onboarding_completed': ?onboardingCompleted,
          'interested_in': ?interestedIn,
        })
        .eq('user_id', _uid);
  }

  Future<List<OwnPhoto>> loadOwnPhotos() async {
    final rows = await _db
        .from('profile_photos')
        .select(
          'id, storage_path, display_order, is_primary, moderation_status',
        )
        .eq('user_id', _uid)
        .order('display_order');
    final photos = <OwnPhoto>[];
    for (final row in rows) {
      final path = row['storage_path'] as String;
      photos.add(
        OwnPhoto(
          id: row['id'] as String,
          path: path,
          url: await _signedUrl(path),
          order: (row['display_order'] as num).toInt(),
          primary: row['is_primary'] == true,
          moderation: row['moderation_status'] as String? ?? 'PENDING',
        ),
      );
    }
    return photos;
  }

  Future<void> uploadPhoto(Uint8List bytes) async {
    final existing = await _db
        .from('profile_photos')
        .select('display_order')
        .eq('user_id', _uid);
    if (existing.length >= maxProfilePhotos) {
      throw const AuthException('You can add up to 3 photos.');
    }
    final used = existing
        .map((row) => (row['display_order'] as num).toInt())
        .toSet();
    var order = 1;
    while (used.contains(order)) {
      order += 1;
    }
    final path = '$_uid/${DateTime.now().microsecondsSinceEpoch}.jpg';
    await _db.storage
        .from('profile-photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    await _db.from('profile_photos').insert({
      'user_id': _uid,
      'storage_path': path,
      'display_order': order,
      'is_primary': existing.isEmpty,
      'moderation_status': 'PENDING',
    });
  }

  Future<void> deletePhoto(OwnPhoto photo) async {
    await _db.from('profile_photos').delete().eq('id', photo.id);
    await _db.storage.from('profile-photos').remove([photo.path]);
    if (!photo.primary) return;
    final rest = await _db
        .from('profile_photos')
        .select('id')
        .eq('user_id', _uid)
        .order('display_order')
        .limit(1);
    if (rest.isEmpty) return;
    await _db
        .from('profile_photos')
        .update({'is_primary': true})
        .eq('id', rest.first['id']);
  }

  Future<void> makePrimary(OwnPhoto photo) async {
    await _db
        .from('profile_photos')
        .update({'is_primary': false})
        .eq('user_id', _uid)
        .eq('is_primary', true);
    await _db
        .from('profile_photos')
        .update({'is_primary': true})
        .eq('id', photo.id);
  }

  Future<List<PublicPerson>> discover() async {
    final rows = await _db.rpc(
      'get_discovery_candidates',
      params: {'p_limit': 500},
    );
    return _peopleFromRows(rows as List<dynamic>);
  }

  Future<void> pass(String targetId) {
    return _db
        .from('passes')
        .upsert(
          {'user_id': _uid, 'target_user_id': targetId},
          onConflict: 'user_id,target_user_id',
          ignoreDuplicates: true,
        );
  }

  Future<void> invite(String targetId) {
    return _db.rpc(
      'create_invite',
      params: {'p_receiver_id': targetId, 'p_message': null},
    );
  }

  Future<void> respond(String inviteId, {required bool accept}) {
    return _db.rpc(
      'respond_to_invite',
      params: {'p_invite_id': inviteId, 'p_accept': accept},
    );
  }

  Future<List<PublicPerson>> incomingInvites() async {
    final invites = await _db
        .from('invites')
        .select('id, sender_id')
        .eq('receiver_id', _uid)
        .eq('status', 'PENDING')
        .order('created_at');
    final ids = [for (final row in invites) row['sender_id'] as String];
    final people = await _peopleByIds(ids);
    return [
      for (final row in invites)
        if (people[row['sender_id']] != null)
          _copy(
            people[row['sender_id'] as String]!,
            inviteId: row['id'] as String,
          ),
    ];
  }

  Future<List<PublicPerson>> mates() async {
    final uid = _uid;
    final rows = await _db
        .from('mates')
        .select('id, user_one_id, user_two_id')
        .eq('status', 'ACTIVE')
        .or('user_one_id.eq.$uid,user_two_id.eq.$uid');
    final ids = [
      for (final row in rows)
        row['user_one_id'] == uid
            ? row['user_two_id'] as String
            : row['user_one_id'] as String,
    ];
    final people = await _peopleByIds(ids);
    return [
      for (final row in rows)
        if (people[_other(row, uid)] != null)
          _copy(people[_other(row, uid)]!, mateId: row['id'] as String),
    ];
  }

  Future<void> endMate(String mateId) {
    return _db.rpc('end_mate', params: {'p_mate_id': mateId});
  }

  Future<void> block(String userId) {
    return _db.from('user_blocks').insert({
      'blocker_id': _uid,
      'blocked_id': userId,
    });
  }

  Future<List<BlockedPerson>> blocks() async {
    final rows = await _db
        .from('user_blocks')
        .select('blocked_id')
        .eq('blocker_id', _uid);
    final ids = [for (final row in rows) row['blocked_id'] as String];
    if (ids.isEmpty) return const [];
    final profiles = await _db
        .from('profiles')
        .select('id, display_name')
        .inFilter('id', ids);
    return [
      for (final row in profiles)
        BlockedPerson(
          id: row['id'] as String,
          name: row['display_name'] as String? ?? 'Member',
        ),
    ];
  }

  Future<void> unblock(String userId) {
    return _db
        .from('user_blocks')
        .delete()
        .eq('blocker_id', _uid)
        .eq('blocked_id', userId);
  }

  Future<List<PublicPerson>> _peopleFromRows(List<dynamic> rows) async {
    final typed = [
      for (final row in rows) Map<String, dynamic>.from(row as Map),
    ];
    final ids = [for (final row in typed) row['id'] as String];
    final photos = await _primaryPhotos(ids);
    return [
      for (final row in typed)
        PublicPerson(
          id: row['id'] as String,
          name: row['display_name'] as String? ?? 'Member',
          age: (row['age'] as num?)?.toInt() ?? 0,
          city: row['city'] as String? ?? '',
          bio: row['bio'] as String? ?? '',
          verified: row['is_verified'] == true,
          photoUrl: photos[row['id']] ?? '',
          outTonightUntil: parseTimestamp(row['out_tonight_until']),
        ),
    ];
  }

  Future<Map<String, PublicPerson>> _peopleByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _db.rpc('public_profile_cards', params: {'p_ids': ids});
    final people = await _peopleFromRows(rows as List<dynamic>);
    return {for (final person in people) person.id: person};
  }

  Future<Map<String, String>> _primaryPhotos(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _db
        .from('profile_photos')
        .select('user_id, storage_path, is_primary, display_order')
        .inFilter('user_id', ids)
        .eq('moderation_status', 'APPROVED')
        .order('display_order');
    final chosen = <String, String>{};
    for (final row in rows) {
      final userId = row['user_id'] as String;
      final path = row['storage_path'] as String;
      if (!chosen.containsKey(userId) || row['is_primary'] == true) {
        chosen[userId] = path;
      }
    }
    final urls = <String, String>{};
    for (final entry in chosen.entries) {
      urls[entry.key] = await _signedUrl(entry.value);
    }
    return urls;
  }

  Future<String> _signedUrl(String path) {
    return _db.storage.from('profile-photos').createSignedUrl(path, 60 * 60);
  }

  PublicPerson _copy(PublicPerson person, {String? inviteId, String? mateId}) {
    return PublicPerson(
      id: person.id,
      name: person.name,
      age: person.age,
      city: person.city,
      bio: person.bio,
      verified: person.verified,
      photoUrl: person.photoUrl,
      inviteId: inviteId ?? person.inviteId,
      mateId: mateId ?? person.mateId,
      outTonightUntil: person.outTonightUntil,
    );
  }

  String _other(Map<String, dynamic> row, String uid) {
    return row['user_one_id'] == uid
        ? row['user_two_id'] as String
        : row['user_one_id'] as String;
  }

  String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
