import Lock
import UIKit
import RideOsCommon
import RideOsGoogleMaps
import RideOsRider

// Add your Google API key here
private let googleApiKey = ""


// Add your user database ID here
private let userDatabaseId = ""

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else {
            fatalError("No window")
        }

        RiderDependencyRegistry.create(riderDependencyFactory: DefaultRiderDependencyFactory(),
                                       mapsDependencyFactory: GoogleMapsDependencyFactory(googleApiKey: googleApiKey))

        window.rootViewController = RiderViewController(
            developerSettingsFormViewControllerFactory: { userStorageReader, userStorageWriter in
                CommonDeveloperSettingsFormViewController(
                    userStorageReader: userStorageReader,
                    userStorageWriter: userStorageWriter,
                    fleetSelectionViewModel: DefaultFleetSelectionViewModel()
                )
            },
            loginMethods: [.auth0UsernamePassword(userDatabaseId: userDatabaseId)]
        )

        window.makeKeyAndVisible()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return Lock.resumeAuth(url, options: options)
    }
}
