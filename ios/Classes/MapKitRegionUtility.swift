import UIKit
import MapKit

// MARK: - BoundingBox
struct MapKitBoundingBox {
    let min: CLLocationCoordinate2D
    let max: CLLocationCoordinate2D
    
    init(mapRect: MKMapRect) {
        let bottomLeft = MKMapPoint(x: mapRect.origin.x, y: mapRect.origin.y)
        let topRight = MKMapPoint(x: mapRect.maxX, y: mapRect.maxY)
        
        self.min = bottomLeft.coordinate
        self.max = topRight.coordinate
    }
    
    init(displayRegion: MapKitGeographicRegion) {
        let coordinates = displayRegion.coordinates
        self.min = coordinates.min
        self.max = coordinates.max
    }
}

// MARK: - GeographicRegion
enum MapKitGeographicRegion: String {
    case asia = "25.5886467,-12.2118513,-168.97788,81.9661865"
    case africa = "-25.383911,-47.1313489,63.8085939,37.5359"
    case northAmerica = "-172.66113495,5.4961,-15.51269745,83.6655766261"
    case southAmerica = "-110.0281,-56.1455,-28.650543,17.6606999"
    case antarctica = "-180.0,-85.0511287798,180.0,-60.1086999"
    case europe = "-25.48824365,32.5960451596,74.3555001,73.1927977675"
    case australia = "110.9510339,-54.8337658,159.2872223,-9.1870264"
    case ukAndIreland = "-16.6649026112,47.7502953806,4.3354981542,60.9916781275"

    var mapKitRegionCode: String {
        switch self {
            case .asia: return "AS"
            case .africa: return "AF"
            case .northAmerica: return "NA"
            case .southAmerica: return "SA"
            case .antarctica: return "AQ"
            case .europe: return "EU"
            case .australia: return "AU"
            case .ukAndIreland: return "UKIE"
        }
    }
    
    static func from(mapKitRegionCode: String) -> MapKitGeographicRegion? {
        switch mapKitRegionCode.uppercased() {
            case "AS": return .asia
            case "AF": return .africa
            case "NA": return .northAmerica
            case "SA": return .southAmerica
            case "AQ": return .antarctica
            case "EU": return .europe
            case "AU": return .australia
            case "UKIE": return .ukAndIreland
            default: return nil
        }
    }
    
    var coordinates: (min: CLLocationCoordinate2D, max: CLLocationCoordinate2D) {
        let values = rawValue.components(separatedBy: ",").compactMap { Double($0) }
        return (
            min: CLLocationCoordinate2D(latitude: values[3], longitude: values[2]),
            max: CLLocationCoordinate2D(latitude: values[1], longitude: values[0])
        )
    }
}

// MARK: - RegionUtility
struct MapKitRegionUtility {
    func region(for region: MapKitGeographicRegion) -> MKCoordinateRegion? {
        let coordinates = region.coordinates
        return MKCoordinateRegion(coordinates: [coordinates.min, coordinates.max])
    }
}

// MARK: - MKCoordinateRegion Extension
extension MKCoordinateRegion {
    init?(coordinates: [CLLocationCoordinate2D]) {
        let primeRegion = MKCoordinateRegion.region(
            for: coordinates,
            transform: { $0 },
            inverseTransform: { $0 }
        )
        
        let transformedRegion = MKCoordinateRegion.region(
            for: coordinates,
            transform: Self.transform,
            inverseTransform: Self.inverseTransform
        )
        
        if let a = primeRegion,
        let b = transformedRegion,
        let min = [a, b].min(by: { $0.span.longitudeDelta < $1.span.longitudeDelta }) {
            self = min
        } else if let region = primeRegion ?? transformedRegion {
            self = region
        } else {
            return nil
        }
    }
    
    private static func transform(c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        c.longitude < 0 ? CLLocationCoordinate2DMake(c.latitude, 360 + c.longitude) : c
    }
    
    private static func inverseTransform(c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        c.longitude > 180 ? CLLocationCoordinate2DMake(c.latitude, -360 + c.longitude) : c
    }
    
    private static func mapKitRegion(
        for coordinates: [CLLocationCoordinate2D],
        transform: (CLLocationCoordinate2D) -> CLLocationCoordinate2D,
        inverseTransform: (CLLocationCoordinate2D) -> CLLocationCoordinate2D
    ) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }
        
        if coordinates.count == 1 {
            return MKCoordinateRegion(
                center: coordinates[0],
                span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            )
        }
        
        let transformed = coordinates.map(transform)
        
        guard let minLat = transformed.min(by: { $0.latitude < $1.latitude })?.latitude,
            let maxLat = transformed.max(by: { $0.latitude < $1.latitude })?.latitude,
            let minLon = transformed.min(by: { $0.longitude < $1.longitude })?.longitude,
            let maxLon = transformed.max(by: { $0.longitude < $1.longitude })?.longitude
        else { return nil }
        
        let span = MKCoordinateSpan(
            latitudeDelta: maxLat - minLat,
            longitudeDelta: maxLon - minLon
        )
        
        let center = inverseTransform(
            CLLocationCoordinate2DMake(
                maxLat - span.latitudeDelta / 2,
                maxLon - span.longitudeDelta / 2
            )
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}
