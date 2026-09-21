import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class AppRepository extends ChangeNotifier {
  final SupabaseClient db;
  AppRepository(this.db);
  static const photoBucket = 'profile-photos';
  Profile? current;
  List<Profile> profiles = [];
  List<Profile> pendingProfiles = [];
  Set<String> shortlisted = {};
  bool loading = false;
  User? get user => db.auth.currentUser;
  bool get isAdmin => current?.role == 'admin';

  Future<void> load() async {
    if (user == null) { current = null; profiles = []; pendingProfiles = []; return; }
    loading = true; notifyListeners();
    try {
      final mine = await db.from('profiles').select().eq('id', user!.id).maybeSingle();
      if (mine != null) current = await _profileWithSignedPhotos(mine);
      final approved = await db.from('profiles').select().eq('status', 'approved').neq('id', user!.id).order('created_at');
      profiles = await _profilesWithSignedPhotos(approved);
      if (isAdmin) {
        final pending = await db.from('profiles').select().eq('status', 'pending').order('created_at');
        pendingProfiles = await _profilesWithSignedPhotos(pending);
      } else { pendingProfiles = []; }
      final saved = await db.from('shortlists').select('profile_id').eq('user_id', user!.id);
      shortlisted = (saved as List).map((x) => x['profile_id'] as String).toSet();
    } finally { loading = false; notifyListeners(); }
  }

  Future<List<Profile>> _profilesWithSignedPhotos(dynamic rows) async => Future.wait((rows as List).map((row) => _profileWithSignedPhotos(row as Map<String, dynamic>)));
  Future<Profile> _profileWithSignedPhotos(Map<String, dynamic> row) async {
    final profile = Profile.fromMap(row);
    profile.photos = await Future.wait(profile.photos.map((path) async {
      if (path.startsWith('http')) return path;
      try { return await db.storage.from(photoBucket).createSignedUrl(path, 3600); } catch (_) { return ''; }
    }).where((url) => url.isNotEmpty));
    return profile;
  }

  Future<void> saveProfile(Profile p) async { await db.from('profiles').upsert(p.toMap()); current = p; notifyListeners(); }
  Future<void> toggleShortlist(Profile p) async { if (user == null) return; if (shortlisted.contains(p.id)) { await db.from('shortlists').delete().match({'user_id': user!.id, 'profile_id': p.id}); shortlisted.remove(p.id); } else { await db.from('shortlists').insert({'user_id': user!.id, 'profile_id': p.id}); shortlisted.add(p.id); } notifyListeners(); }
  Future<void> interest(Profile p) => db.from('interests').upsert({'from_user': user!.id, 'to_user': p.id}, onConflict: 'from_user,to_user');
  Future<void> report(Profile p, String reason) => db.from('reports').insert({'reporter_id': user!.id, 'profile_id': p.id, 'reason': reason});

  Future<String> uploadPhoto(Uint8List bytes, String extension) async {
    final uid = user!.id;
    final path = '$uid/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await db.storage.from(photoBucket).uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: false, contentType: 'image/*'));
    final stored = [...?current?.photos.where((x) => !x.startsWith('http')), path];
    await db.from('profiles').update({'photos': stored}).eq('id', uid);
    await load();
    return path;
  }

  Future<void> deletePhoto(String path) async {
    final uid = user!.id;
    await db.storage.from(photoBucket).remove([path]);
    final remaining = [...?current?.photos.where((x) => x != path && !x.startsWith('http'))];
    await db.from('profiles').update({'photos': remaining}).eq('id', uid);
    await load();
  }

  Future<void> moderate(Profile p, String status) async {
    if (!isAdmin) return;
    await db.from('profiles').update({'status': status, 'verified': status == 'approved'}).eq('id', p.id);
    pendingProfiles.removeWhere((x) => x.id == p.id);
    if (status == 'approved') profiles.add(p);
    notifyListeners();
  }

  List<MatchResult> matches({String city = ''}) { final me = current; if (me == null) return []; return profiles.where((p) => p.gender != me.gender && (city.isEmpty || p.city.toLowerCase().contains(city.toLowerCase()))).map((p) { var score = 40; final reasons = <String>[]; if (p.age >= me.minAge && p.age <= me.maxAge) { score += 20; reasons.add('Age preference'); } if (me.preferredCities.any((c) => c.toLowerCase() == p.city.toLowerCase())) { score += 15; reasons.add('Preferred city'); } if (me.preferredEducation == 'Any' || p.education.isNotEmpty) { score += 10; reasons.add('Education'); } if (me.preferredOccupation == 'Any' || p.occupation.isNotEmpty) { score += 10; reasons.add('Career'); } if (p.subCommunity.toLowerCase() == me.subCommunity.toLowerCase()) { score += 5; reasons.add('Community'); } return MatchResult(p, score.clamp(0, 100), reasons); }).toList()..sort((a, b) => b.score.compareTo(a.score)); }
}
