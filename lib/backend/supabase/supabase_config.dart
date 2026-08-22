import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://irisxsklwelqakeloerg.supabase.co',
);

const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlyaXN4c2tsd2VscWFrZWxvZXJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYyMDcxODcsImV4cCI6MjEwMTc4MzE4N30.IfqSNlGjKfud-lW9qigoAE1U3A2VjhKhDExrbIJmSzs',
);

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
