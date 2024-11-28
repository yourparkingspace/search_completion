
import 'search_completion_platform_interface.dart';

class SearchCompletion {
  Future<String?> getPlatformVersion() {
    return SearchCompletionPlatform.instance.getPlatformVersion();
  }
}
