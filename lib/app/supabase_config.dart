/// The helpyy Supabase project.
///
/// The publishable key is meant to ship inside the app. What each user can
/// reach is decided by row level security in supabase/migrations, not by
/// keeping this key secret. Never put the secret or service role key here.
abstract final class SupabaseConfig {
  static const url = 'https://qzvccbqmrtyhupgejjta.supabase.co';
  static const publishableKey =
      'sb_publishable_pcux4hl_XvHb1HAg0XCUZg_PPSqXsT1';
}
