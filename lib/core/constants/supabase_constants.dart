class SupabaseConstants {
  /// URL Proyek Supabase Anda. Dapatkan di Dashboard Supabase -> Project Settings -> API
  static const String supabaseUrl = 'https://cuaobjnnlwdhxqekvyzl.supabase.co';

  /// Anon Public Key Supabase Anda. Dapatkan di Dashboard Supabase -> Project Settings -> API
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN1YW9iam5ubHdkaHhxZWt2eXpsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE3NTA4MjMsImV4cCI6MjEwNzMyNjgyM30.NqRZeSKLqA_3TnU8DDJB62w5V0wdqD2MHgUEkFwtHuk';

  /// Cek apakah Supabase sudah dikonfigurasi dengan URL & Key asli
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        supabaseUrl.startsWith('http') &&
        !supabaseUrl.contains('YOUR_SUPABASE_URL') &&
        !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');
  }
}
