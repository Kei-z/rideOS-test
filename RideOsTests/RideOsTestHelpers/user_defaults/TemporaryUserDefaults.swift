import Foundation
import RideOsCommon

public class TemporaryUserDefaults: UserDefaults {
    // Note: Because our parent class has an init() method that takes no parameteers, calling init() with no paremeters
    // doesn't actually call init(boolValues: stringValues: intValues:) with default parameter values. Thus, we override
    // the parent init() to ensure that it calls init(boolValues: stringValues: intValues:)
    public convenience init() {
        self.init(boolValues: [:])
    }

    public convenience init(boolValues: [UserStorageKey<Bool>: Bool] = [:],
                            stringValues: [UserStorageKey<String>: String] = [:],
                            intValues: [UserStorageKey<Int>: Int] = [:]) {
        self.init(suiteName: "__temporary_user_defaults__")!
        boolValues.forEach { key, value in set(value, forKey: key.key) }
        stringValues.forEach { key, value in set(value, forKey: key.key) }
        intValues.forEach { key, value in set(value, forKey: key.key) }
    }

    public override init?(suiteName suitename: String?) {
        UserDefaults().removePersistentDomain(forName: suitename!)
        super.init(suiteName: suitename)
    }
}
