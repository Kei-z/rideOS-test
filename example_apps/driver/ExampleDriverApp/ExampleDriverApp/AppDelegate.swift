import Lock
import RideOsCommon
import RideOsDriver
import RideOsGoogleMaps
import UIKit

// Add your Google API key here
private let googleApiKey = ""


// Add your user database ID here
private let userDatabaseId = ""

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else {
            fatalError("No window")
        }

        DriverDependencyRegistry.create(driverDependencyFactory: DefaultDriverDependencyFactory(),
                                        mapsDependencyFactory: GoogleMapsDependencyFactory(googleApiKey: googleApiKey))

        window.rootViewController = DriverViewController(
            loginMethods: [.auth0UsernamePassword(userDatabaseId: userDatabaseId)]
        )
        window.makeKeyAndVisible()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return Lock.resumeAuth(url, options: options)
    }
}
