import Foundation
import RideOsCommon
import RideOsTestHelpers
import XCTest

class UserDefaultsUserStorageReaderTest: ReactiveTestCase {
    struct CodableStruct: Equatable, Codable {
        let int: Int
        let string: String
    }

    private static let key = UserStorageKey<CodableStruct>("a key")

    private var userDefaults: TemporaryUserDefaults!
    private var readerUnderTest: UserDefaultsUserStorageReader!

    override func setUp() {
        super.setUp()
        userDefaults = TemporaryUserDefaults()
        readerUnderTest = UserDefaultsUserStorageReader(userDefaults: userDefaults)
    }

    func testGetCodableReturnsTheStoredCodableObject() {
        let storedObject = CodableStruct(int: 42, string: "a string")
        userDefaults.set(try? PropertyListEncoder().encode(storedObject),
                         forKey: UserDefaultsUserStorageReaderTest.key.key)

        XCTAssertEqual(readerUnderTest.get(UserDefaultsUserStorageReaderTest.key), storedObject)
    }

    func testObservingKeyReturnsExpectedEvents() {
        let storedObject = CodableStruct(int: 42, string: "a string")

        let recorder = scheduler.record(readerUnderTest.observe(UserDefaultsUserStorageReaderTest.key))
        scheduler.scheduleAt(1) {
            self.userDefaults.set(try? PropertyListEncoder().encode(storedObject),
                                  forKey: UserDefaultsUserStorageReaderTest.key.key)
        }
        scheduler.start()

        XCTAssertEqual(recorder.events, [.next(0, nil), .next(1, storedObject)])
    }

    func testGetStringReturnsTheStoredString() {
        let key = UserStorageKey<String>("key")
        let value = "hello"
        userDefaults.set(value, forKey: key.key)

        XCTAssertEqual(readerUnderTest.get(key), value)
    }

    func testGetNonExistentStringReturnsNil() {
        XCTAssertNil(readerUnderTest.get(UserStorageKey<String>("key")))
    }

    func testObservingStringReturnsExpectedEvents() {
        let key = UserStorageKey<String>("key")
        let value = "hello"

        let recorder = scheduler.record(readerUnderTest.observe(key))
        scheduler.scheduleAt(1) {
            self.userDefaults.set(value, forKey: key.key)
        }
        scheduler.start()

        XCTAssertEqual(recorder.events, [.next(0, nil), .next(1, value)])
    }

    func testGetIntReturnsTheStoredInt() {
        let key = UserStorageKey<Int>("key")
        let value = 42
        userDefaults.set(value, forKey: key.key)

        XCTAssertEqual(readerUnderTest.get(key), value)
    }

    func testGetNonExistentIntReturnsNil() {
        XCTAssertNil(readerUnderTest.get(UserStorageKey<Int>("key")))
    }

    func testObservingIntReturnsExpectedEvents() {
        let key = UserStorageKey<Int>("key")
        let value = 42

        let recorder = scheduler.record(readerUnderTest.observe(key))
        scheduler.scheduleAt(1) {
            self.userDefaults.set(value, forKey: key.key)
        }
        scheduler.start()

        XCTAssertEqual(recorder.events, [.next(0, nil), .next(1, value)])
    }

    func testGetBoolReturnsTheStoredBool() {
        let key = UserStorageKey<Bool>("key")
        let value = true
        userDefaults.set(value, forKey: key.key)

        XCTAssertEqual(readerUnderTest.get(key), value)
    }

    func testGetNonExistentBoolReturnsNil() {
        XCTAssertNil(readerUnderTest.get(UserStorageKey<Bool>("key")))
    }

    func testObservingBoolReturnsExpectedEvents() {
        let key = UserStorageKey<Bool>("key")
        let value = true

        let recorder = scheduler.record(readerUnderTest.observe(key))
        scheduler.scheduleAt(1) {
            self.userDefaults.set(value, forKey: key.key)
        }
        scheduler.start()

        XCTAssertEqual(recorder.events, [.next(0, nil), .next(1, value)])
    }
}
