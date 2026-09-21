import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class AppRepository extends ChangeNotifier {
  final SupabaseClient db;
  AppRepository(this.db);
  Profile? current;
  List<Profile> profiles = [];
  Set<String> shortlisted = {};
  bool loading = false;
  User? get user => db.auth.currentUser;
  bool get isAdmin => current?.role == 'admin';

  Future<void> load() async {
    if (user == null) return;
    loading = true; notifyListeners();
    try {
      final mine = await db.from('profiles').select().eq('id', user!.id).maybeSingle();
      if (mine != null) current = Profile.fromMap(mine);
      final rows = await db.from('profiles').select().eq('status', 'approved').neq('id', user!.id).order('created_at');
      profiles = (rows as List).map((x) => Profile.fromMap(x)).toList();
      final saved = await db.from('shortlists').select('profile_id').eq('user_id', user!.id);
      shortlisted = (saved as List).map((x) => x['profile_id'] as String).toSet();
    } finally { loading = false; notifyListeners(); }
  }

  Future<void> saveProfile(Profile p) async { await db.from('profiles').upsert(p.toMap()); current = p; notifyListeners(); }
  Future<void> toggleShortlist(Profile p) async { if (shortlisted.contains(p.id)) { await db.from('shortlists').delete().match({'user_id': user!.id, 'profile_id': p.id}); shortlisted.remove(p.id); } else { await db.from('shortlists').insert({'user_id': user!.id, 'profile_id': p.id}); shortlisted.add(p.id); } notifyListeners(); }
  Future<void> interest(Profile p) => db.from('interests').upsert({'from_user': user!.id, 'to_user': p.id}, onConflict: 'from_user,to_user');
  Future<void> report(Profile p, String reason) => db.from('reports').insert({'reporter_id': user!.id, 'profile_id': p.id, 'reason': reason});
  Future<void> moderate(Profile p, String status) async { await db.from('profiles').update({'status': status, 'verified': status == 'approved'}).eq('id', p.id); profiles.removeWhere((x) => x.id == p.id); notifyListeners(); }
  List<MatchResult> matches({String city = ''}) { final me = current; if (me == null) return []; return profiles.where((p) => p.gender != me.gender && (city.isEmpty || p.city.toLowerCase().contains(city.toLowerCase()))).map((p) { var score = 40; final reasons = <String>[]; if (p.age >= me.minAge && p.age <= me.maxAge) { score += 20; reasons.add('Age preference'); } if (me.preferredCities.any((c) => c.toLowerCase() == p.city.toLowerCase())) { score += 15; reasons.add('Preferred city'); } if (me.preferredEducation == 'Any' || p.education.isNotEmpty) { score += 10; reasons.add('Education'); } if (me.preferredOccupation == 'Any' || p.occupation.isNotEmpty) { score += 10; reasons.add('Career'); } if (p.subCommunity.toLowerCase() == me.subCommunity.toLowerCase()) { score += 5; reasons.add('Community'); } return MatchResult(p, score.clamp(0, 100), reasons); }).toList()..sort((a, b) => b.score.compareTo(a.score)); }
}
