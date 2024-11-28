import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'search_completion_method_channel.dart';

abstract class SearchCompletionPlatform extends PlatformInterface {
  /// Constructs a SearchCompletionPlatform.
  SearchCompletionPlatform() : super(token: _token);

  static final Object _token = Object();

  static SearchCompletionPlatform _instance = MethodChannelSearchCompletion();

  /// The default instance of [SearchCompletionPlatform] to use.
  ///
  /// Defaults to [MethodChannelSearchCompletion].
  static SearchCompletionPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SearchCompletionPlatform] when
  /// they register themselves.
  static set instance(SearchCompletionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
