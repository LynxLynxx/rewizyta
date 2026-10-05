/// Keys of the local `app_settings` table, stored in snake_case.
enum AppSettingKey() {
  onboardingDone,
  themeMode,
  contactsImportDone,
}

/// Preferences of this phone. Local only: never synced, so a new phone starts
/// with the defaults.
abstract interface class AppSettingsRepository() {
  Future<String?> read(AppSettingKey key);

  /// The value now and after every change; null while the key is unset.
  Stream<String?> watch(AppSettingKey key);

  /// Stores [value], or removes the key when it is null.
  Future<void> write(AppSettingKey key, String? value);
}
