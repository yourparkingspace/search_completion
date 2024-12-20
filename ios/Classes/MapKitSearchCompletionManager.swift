import Combine
import os.log
import MapKit

protocol SearchCompletionManagerProtocol {
    var searchTerm: String { get set }
    var autoCompletePublisher: AnyPublisher<[any AutoCompletedSearchResult], Never> { get }
    func returnCoordinatesFromSearchResult(title: String?, subtitle: String?) async -> CLLocationCoordinate2D? 
}

protocol AutoCompletedSearchResult: Hashable {
    var id: String { get }
    var title: String { get }
    var subtitle: String { get }
}

final class MapKitSearchCompletionManager: NSObject, SearchCompletionManagerProtocol {
    
    var autoCompletePublisher: AnyPublisher<[any AutoCompletedSearchResult], Never>
    
    var searchTerm: String {
        didSet {
            searchCompleter.queryFragment = searchTerm
        }
    }
    
    private let searchCompleter: MKLocalSearchCompleter
    private let autoCompleteSubject = PassthroughSubject<[any AutoCompletedSearchResult], Never>()
    private var autoCompleteResults: [MKLocalSearchCompletion] = []
    private var region: MKCoordinateRegion?

    init(
        region: MKCoordinateRegion? = nil,
        searchCompleter: MKLocalSearchCompleter = MKLocalSearchCompleter()
    ) {
        self.autoCompletePublisher = autoCompleteSubject.eraseToAnyPublisher()
        self.region = region
        self.searchCompleter = searchCompleter
        self.searchCompleter.resultTypes = [.address, .pointOfInterest]
        self.searchTerm = ""
        super.init()
        
        self.searchCompleter.delegate = self
        os_log("Search completion manager initialized with region: %@", log: .default, type: .debug, String(describing: region))
    }
    
    func returnCoordinatesFromSearchResult(title: String?, subtitle: String?) async -> CLLocationCoordinate2D?  {
        do {
            let searchRequest = MKLocalSearch.Request()
            if let region {
                searchRequest.region = region
            }
            searchRequest.naturalLanguageQuery = "\(title ?? "") \(subtitle ?? "")"
            let search = MKLocalSearch(request: searchRequest)
            let result = try await search.start()
            return result.mapItems.first?.placemark.coordinate
        } catch {
            return nil
        }
    }
}

extension MapKitSearchCompletionManager: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        autoCompleteResults = completer.results
        autoCompleteSubject.send(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        autoCompleteResults = []
        autoCompleteSubject.send([])
    }
}

extension MKLocalSearchCompletion: AutoCompletedSearchResult {
    var id: String {
        UUID().uuidString
    }
}
