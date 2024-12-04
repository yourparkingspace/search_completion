# search_completion

Wraps MapKit's MKLocalSearchCompletion for iOS and Google Places API autocomplete for Android.

## Getting Started

Add to your pubspec.yaml:

```
search_completion:
    git:
      url: https://github.com/yourparkingspace/search_completion.git
      ref: main
```

Required Android dependencies in build files:

```
dependencies {
    implementation "com.google.android.libraries.places:places:3.1.0"
    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.6.4"
}

```

Required Android permissions in manifest:

```
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.yourparkingspace.search_completion">
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>

```

## Dart implementation

```
class DefaultSearchCompletionDataSource {
  static const MethodChannel _channel = MethodChannel('search_completion');
  static const EventChannel _eventChannel =
      EventChannel('search_completion_events');

  final _searchResultsController =
      StreamController<List<AutoCompleteSearchResult>>.broadcast();
  Stream<List<AutoCompleteSearchResult>> get searchResults =>
      _searchResultsController.stream;

  DefaultSearchCompletionDataSource() {
    _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      final List<AutoCompleteSearchResult> results = (event as List)
          .map(
            (e) =>
                AutoCompleteSearchResult.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList();
      _searchResultsController.add(results);
    });
  }

  Future<void> initialize({String? androidApiKey}) async {
    if (Platform.isAndroid) {
      if (androidApiKey == null) {
        throw Exception('Android API key is required for Google Places');
      }
      await _channel.invokeMethod('initialize', {'apiKey': androidApiKey});
    } else {
      await _channel.invokeMethod('initialize');
    }
  }

  Future<void> updateSearchTerm(String searchTerm) async {
    await _channel.invokeMethod('updateSearchTerm', {
      'searchTerm': searchTerm,
    });
  }

  Future<Coordinates?> getCoordinates(AutoCompleteSearchResult result) async {
    final response = await _channel.invokeMethod('getCoordinates', {
      'title': result.title,
      'subtitle': result.subtitle,
    });

    if (response == null) return null;

    return Coordinates(
      latitude: response['latitude'],
      longitude: response['longitude'],
    );
  }
}

```

## Example usage

```
import 'package:flutter/material.dart';
import 'package:marketplace_flutter/features/search/domain/entities/auto_complete_search_result.dart';
import 'package:marketplace_flutter/features/search/data/default_search_completion_data_source.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final DefaultSearchCompletionDataSource _searchDataSource = DefaultSearchCompletionDataSource();
  List<AutoCompleteSearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initializeSearch();
    _searchDataSource.searchResults.listen((results) {
      setState(() {
        _searchResults = results;
      });
    });
  }

  Future<void> _initializeSearch() async {
    try {
      await _searchDataSource.initialize(androidApiKey: 'YOUR_ANDROID_API_KEY');
    } catch (e) {
      print('Error initializing search: $e');
    }
  }

  Future<void> _updateSearchTerm(String searchTerm) async {
    try {
      await _searchDataSource.updateSearchTerm(searchTerm);
    } catch (e) {
      print('Error updating search term: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _updateSearchTerm(value);
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  title: Text(result.title),
                  subtitle: Text(result.subtitle),
                  onTap: () async {
                    final coordinates = await _searchDataSource.getCoordinates(result);
                    if (coordinates != null) {
                      print('Coordinates: ${coordinates.latitude}, ${coordinates.longitude}');
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AutoCompleteSearchResult {
  final String id;
  final String title;
  final String subtitle;

  AutoCompleteSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  factory AutoCompleteSearchResult.fromMap(Map<String, dynamic> map) {
    return AutoCompleteSearchResult(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
    );
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({
    required this.latitude,
    required this.longitude,
  });
}


```

