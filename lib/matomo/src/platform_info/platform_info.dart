import 'package:flutter/cupertino.dart';

import '../../src/platform_info/platform_info_interface.dart';
import '../../src/platform_info/platform_info_io.dart'
    if (dart.library.html) '../../src/platform_info/platform_info_web.dart';

class PlatformInfo extends PlatformInfoInterface {
  PlatformInfo._internal();

  static final instance = PlatformInfo._internal();

  PlatformInfoInterface _platformInfo = PlatformInfoImpl();

  @visibleForTesting
  set platformInfo(PlatformInfoInterface platformInfo) {
    _platformInfo = platformInfo;
  }

  @override
  bool get isWeb => _platformInfo.isWeb;

  @override
  bool get isAndroid => _platformInfo.isAndroid;

  @override
  bool get isIOS => _platformInfo.isIOS;

  @override
  bool get isMacOS => _platformInfo.isMacOS;

  @override
  bool get isWindows => _platformInfo.isWindows;

  @override
  bool get isLinux => _platformInfo.isLinux;
}
