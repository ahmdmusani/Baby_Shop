/// Pakistan Standard Time (PKT) is UTC+5 year-round (no daylight saving).
class PakistanTimeGreeting {
  PakistanTimeGreeting._();

  static DateTime nowInPakistan() {
    return DateTime.now().toUtc().add(const Duration(hours: 5));
  }

  /// Returns greeting text with a wave emoji, e.g. "Good Morning 👋".
  static String greetingWithEmoji() {
    final hour = nowInPakistan().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning 👋';
    if (hour >= 12 && hour < 17) return 'Good Afternoon 👋';
    if (hour >= 17 && hour < 21) return 'Good Evening 👋';
    return 'Good Night 🌙';
  }
}
