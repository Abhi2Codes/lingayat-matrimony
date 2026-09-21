import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'repository.dart';
import 'screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || key.isEmpty) {
    runApp(const _ConfigError());
    return;
  }
  await Supabase.initialize(url: url, anonKey: key);
  runApp(const LingayatMatrimonyApp());
}

class LingayatMatrimonyApp extends StatefulWidget { const LingayatMatrimonyApp({super.key}); @override State<LingayatMatrimonyApp> createState() => _AppState(); }
class _AppState extends State<LingayatMatrimonyApp> { late final AppRepository repo; AppThemeConfig theme = const AppThemeConfig(); @override void initState() { super.initState(); repo = AppRepository(Supabase.instance.client); repo.db.auth.onAuthStateChange.listen((_) => repo.load()); repo.load(); } @override Widget build(BuildContext context) => AnimatedBuilder(animation: repo, builder: (_, __) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Lingayat Matrimony', theme: theme.data, home: AuthGate(repo: repo, theme: theme, onTheme: (v) => setState(() => theme = v)))); }
class _ConfigError extends StatelessWidget { const _ConfigError(); @override Widget build(BuildContext context) => const MaterialApp(home: Scaffold(body: Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Missing SUPABASE_URL or SUPABASE_ANON_KEY. Run with --dart-define values; see README.md.'))))); }
