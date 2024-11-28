import 'package:flutter_test/flutter_test.dart';
import 'package:search_completion/search_completion.dart';
import 'package:search_completion/search_completion_platform_interface.dart';
import 'package:search_completion/search_completion_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSearchCompletionPlatform
    with MockPlatformInterfaceMixin
    implements SearchCompletionPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SearchCompletionPlatform initialPlatform = SearchCompletionPlatform.instance;

  test('$MethodChannelSearchCompletion is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSearchCompletion>());
  });

  test('getPlatformVersion', () async {
    SearchCompletion searchCompletionPlugin = SearchCompletion();
    MockSearchCompletionPlatform fakePlatform = MockSearchCompletionPlatform();
    SearchCompletionPlatform.instance = fakePlatform;

    expect(await searchCompletionPlugin.getPlatformVersion(), '42');
  });
}
