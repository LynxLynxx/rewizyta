import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Records launched URLs; `fails` makes it throw as Android does without a
/// matching app. Install with `UrlLauncherPlatform.instance = FakeUrlLauncher()`.
class FakeUrlLauncher() extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final List<String> launched = [];
  bool fails = false;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    if (fails) throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
    launched.add(url);
    return true;
  }
}
