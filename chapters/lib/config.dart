/// Paste your own values from Supabase → Project Settings → API.
/// The anon key is safe to ship in the app: Row Level Security (see
/// supabase/schema.sql) is what keeps each person's entries private.
class AppConfig {
  static const supabaseUrl = 'https://bjumfvwpcmbgywdgqzaw.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqdW1mdndwY21iZ3l3ZGdxemF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA1ODM4MDAsImV4cCI6MjEwNjE1OTgwMH0.7drMTnhOEKsLRPQZnAZPRz2zXTWJRcqi2nlUnUPl3k0';
}
