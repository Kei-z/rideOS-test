import RideOsHereMaps
import XCTest

class RideOsHereMapsTests: XCTestCase {
    private var interactorUnderTest: HereLocationAutocompleteInteractor!

    override func setUp() {
        interactorUnderTest = HereLocationAutocompleteInteractor()
    }

    func testSecondaryTextFromNilReturnsEmptyString() {
        XCTAssertEqual(HereLocationAutocompleteInteractor.secondaryTextFrom(vicinityDescription: nil), "")
    }

    func testSecondaryTextFromEmptyStringReturnsEmptyString() {
        XCTAssertEqual(HereLocationAutocompleteInteractor.secondaryTextFrom(vicinityDescription: ""), "")
    }

    func testSecondaryTextFromSingleLineStringReturnsThatString() {
        XCTAssertEqual(HereLocationAutocompleteInteractor.secondaryTextFrom(vicinityDescription: "hello"), "hello")
    }

    func testSecondaryTextFromMultiLineStringReturnsTheLastLine() {
        XCTAssertEqual(HereLocationAutocompleteInteractor.secondaryTextFrom(vicinityDescription: "hello<br/>goodbye"),
                       "goodbye")
    }
}
