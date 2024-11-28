import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'search_completion_platform_interface.dart';

/// An implementation of [SearchCompletionPlatform] that uses method channels.
class MethodChannelSearchCompletion extends SearchCompletionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('search_completion');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
