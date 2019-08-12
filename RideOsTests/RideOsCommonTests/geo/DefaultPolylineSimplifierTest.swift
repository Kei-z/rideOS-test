import CoreLocation
import Foundation
import RideOsCommon
import SwiftSimplify
import XCTest

class DefaultPolylineSimplifierTest: XCTestCase {
    private static let toleranceDegrees: Float = 0.0001

    private var polylineSimplifierUnderTest: DefaultPolylineSimplifier!

    override func setUp() {
        super.setUp()

        polylineSimplifierUnderTest = DefaultPolylineSimplifier(
            toleranceDegrees: DefaultPolylineSimplifierTest.toleranceDegrees
        )

        assertNil(polylineSimplifierUnderTest, after: { self.polylineSimplifierUnderTest = nil })
    }

    func testSimplifyProducesTheSameResultsAsCallingSwiftSimplifyDirectly() {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 37.8021999, longitude: -122.4181229),
            CLLocationCoordinate2D(latitude: 37.8022062, longitude: -122.4181136),
            CLLocationCoordinate2D(latitude: 37.8022102, longitude: -122.4181037),
            CLLocationCoordinate2D(latitude: 37.802213, longitude: -122.4180923),
            CLLocationCoordinate2D(latitude: 37.8022151, longitude: -122.4180807),
            CLLocationCoordinate2D(latitude: 37.8022175, longitude: -122.4180519),
            CLLocationCoordinate2D(latitude: 37.8022187, longitude: -122.4180225),
            CLLocationCoordinate2D(latitude: 37.8022186, longitude: -122.4179869),
            CLLocationCoordinate2D(latitude: 37.8021394, longitude: -122.4179709),
            CLLocationCoordinate2D(latitude: 37.8017176, longitude: -122.4178859),
            CLLocationCoordinate2D(latitude: 37.801285, longitude: -122.4177988),
            CLLocationCoordinate2D(latitude: 37.8014107, longitude: -122.4167735),
            CLLocationCoordinate2D(latitude: 37.8014871, longitude: -122.4161503),
            CLLocationCoordinate2D(latitude: 37.8024197, longitude: -122.4163381),
            CLLocationCoordinate2D(latitude: 37.80226454704793, longitude: -122.41754476037858),
        ]

        XCTAssertEqual(polylineSimplifierUnderTest.simplify(polyline: coordinates),
                       SwiftSimplify.simplify(coordinates, tolerance: DefaultPolylineSimplifierTest.toleranceDegrees))
    }
}
