import Foundation

/// Non-secret Spotify app credentials for the App Remote flow.
///
/// Only the **Client ID** and **redirect URI** belong in the app. The App Remote
/// authorization we use (`SPTAppRemote.authorizeAndPlayURI`) lets the Spotify app
/// itself broker the login and hand back an access token via the redirect URI — so
/// there is **no client secret here on purpose**. The secret is only needed for a
/// server-side Web API token-swap backend, which RinkDJ does not run.
enum SpotifyConfig {
    /// From the Spotify Developer Dashboard app "RinkDJ".
    static let clientID = "5e8ec3550c3a480791729bdbebf84ad8"

    /// Must exactly match a Redirect URI registered in the dashboard, and the URL
    /// scheme (`nu.ronnqvist.rinkdj`) must be declared in Info.plist's CFBundleURLTypes.
    static let redirectURI = URL(string: "nu.ronnqvist.rinkdj://spotify-login-callback")!
}
