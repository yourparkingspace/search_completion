import Flutter
import UIKit
import MapKit
import Combine

public class SearchCompletionPlugin: NSObject, FlutterPlugin {
    private var searchManager: MapKitSearchCompletionManager?
    private var cancellables = Set<AnyCancellable>()
    private var registrar: FlutterPluginRegistrar?

    private lazy var eventSink: FlutterEventSink? = nil

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
          name: "search_completion",
          binaryMessenger: registrar.messenger()
        )
        let instance = SearchCompletionPlugin()
        instance.registrar = registrar
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(
          name: "search_completion_events",
          binaryMessenger: registrar.messenger()
        )
    
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initializeSearchManager()
            result(nil)
        case "updateSearchTerm":
            if let args = call.arguments as? [String: Any],
              let searchTerm = args["searchTerm"] as? String {
                searchManager?.searchTerm = searchTerm
                result(nil)
            }
        case "getCoordinates":
            if let args = call.arguments as? [String: Any],
              let title: String = args["title"] as? String,
              let subtitle: String = args["subtitle"] as? String,
              let searchManager {
                Task {
                    let coordinates: CLLocationCoordinate2D? = await searchManager.returnCoordinatesFromSearchResult(
                      title: title, 
                      subtitle: subtitle
                    )
                    result([
                        "latitude": coordinates?.latitude as? Double,
                        "longitude": coordinates?.longitude as? Double
                    ])
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initializeSearchManager() {
        searchManager = MapKitSearchCompletionManager()
        searchManager?.autoCompletePublisher
            .sink { [weak self] completions in
                let results = completions.map { completion in
                    return [
                        "id": completion.id,
                        "title": completion.title,
                        "subtitle": completion.subtitle
                    ]
                }
                self?.sendSearchResults(results)
            }
            .store(in: &cancellables)
    }
    
    private func sendSearchResults(_ results: [[String: Any]]) {
      eventSink?(results)
    }
}

extension SearchCompletionPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}