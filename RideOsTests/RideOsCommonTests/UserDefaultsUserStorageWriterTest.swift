import Foundation
import RideOsCommon
import RideOsTestHelpers
import XCTest

class UserDefaultsUserStorageWriterTest: XCTestCase {
    struct CodableStruct: Equatable, Codable {
        let int: Int
        let string: String
    }

    private static let key = UserStorageKey<CodableStruct>("a key")

    private var userDefaults: TemporaryUserDefaults!
    private var writerUnderTest: UserDefaultsUserStorageWriter!

    override func setUp() {
        super.setUp()
        userDefaults = TemporaryUserDefaults()
        writerUnderTest = UserDefaultsUserStorageWriter(userDefaults: userDefaults)
    }

    func testWriteCodableWritesTheCorrectObject() {
        let objectToStore = CodableStruct(int: 42, string: "a string")
        writerUnderTest.set(key: UserDefaultsUserStorageWriterTest.key, value: objectToStore)

        XCTAssertEqual(
            try? PropertyListDecoder().decode(
                CodableStruct.self,
                // swiftlint:disable force_cast
                from: userDefaults.value(forKey: UserDefaultsUserStorageWriterTest.key.key) as! Data
                // swiftlint:enable force_cast
            ),
            objectToStore
        )
    }

    func testWriteNilRemovesTheObject() {
        let objectToStore = CodableStruct(int: 42, string: "a string")
        writerUnderTest.set(key: UserDefaultsUserStorageWriterTest.key, value: objectToStore)
        writerUnderTest.set(key: UserDefaultsUserStorageWriterTest.key, value: nil)

        XCTAssertNil(userDefaults.value(forKey: UserDefaultsUserStorageWriterTest.key.key))
    }

    func testWriteStringWritesTheCorrectString() {
        let key = UserStorageKey<String>("key")
        let value = "hello"
        writerUnderTest.set(key: key, value: value)

        XCTAssertEqual(userDefaults.value(forKey: key.key) as? String, value)
    }

    func testWriteNilRemovesString() {
        let key = UserStorageKey<String>("key")
        let value = "hello"
        writerUnderTest.set(key: key, value: value)
        writerUnderTest.set(key: key, value: nil)

        XCTAssertNil(userDefaults.value(forKey: key.key))
    }

    func testWriteIntWritesTheCorrectInt() {
        let key = UserStorageKey<Int>("key")
        let value = 42
        writerUnderTest.set(key: key, value: value)

        XCTAssertEqual(userDefaults.value(forKey: key.key) as? Int, value)
    }

    func testWriteNilRemovesInt() {
        let key = UserStorageKey<Int>("key")
        let value = 42
        writerUnderTest.set(key: key, value: value)
        writerUnderTest.set(key: key, value: nil)

        XCTAssertNil(userDefaults.value(forKey: key.key))
    }

    func testWriteBoolWritesTheCorrectBool() {
        let key = UserStorageKey<Bool>("key")
        let value = true
        writerUnderTest.set(key: key, value: value)

        XCTAssertEqual(userDefaults.value(forKey: key.key) as? Bool, value)
    }

    func testWriteNilRemovesBool() {
        let key = UserStorageKey<Bool>("key")
        let value = true
        writerUnderTest.set(key: key, value: value)
        writerUnderTest.set(key: key, value: nil)

        XCTAssertNil(userDefaults.value(forKey: key.key))
    }
}
