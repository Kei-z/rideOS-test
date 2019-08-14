import Lock
import UIKit
import RideOsCommon
import RideOsGoogleMaps
import RideOsRider

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private static var googleApiKey: String {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleAPIKey") as? String else {
            fatalError("GoogleAPIKey must be set in Info.plist")
        }
        return apiKey
    }

    private static var userDatabaseId: String {
        guard let path = Bundle.main.path(forResource: "Auth0", ofType: "plist"),
            let values = NSDictionary(contentsOfFile: path) as? [String: Any],
            let userDatabaseId = values["UserDatabaseId"] as? String else {
                fatalError("UserDatabaseId must be set in Auth0.plist")
        }
        return userDatabaseId
    }

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else {
            fatalError("No window")
        }

        RiderDependencyRegistry.create(
            riderDependencyFactory: DefaultRiderDependencyFactory(),
            mapsDependencyFactory: GoogleMapsDependencyFactory(googleApiKey: AppDelegate.googleApiKey)
        )

        window.rootViewController = RiderViewController(
            developerSettingsFormViewControllerFactory: { userStorageReader, userStorageWriter in
                CommonDeveloperSettingsFormViewController(
                    userStorageReader: userStorageReader,
                    userStorageWriter: userStorageWriter,
                    fleetSelectionViewModel: DefaultFleetSelectionViewModel()
                )
            },
            loginMethods: [.auth0UsernamePassword(userDatabaseId: AppDelegate.userDatabaseId)]
        )

        window.makeKeyAndVisible()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return Lock.resumeAuth(url, options: options)
    }
}
