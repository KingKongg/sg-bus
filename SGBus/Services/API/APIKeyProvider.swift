import Foundation

enum APIKeyProvider {
    static var ltaAPIKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["LTA_API_KEY"] as? String,
              !key.isEmpty else {
            fatalError("Missing LTA_API_KEY in Secrets.plist")
        }
        return key
    }
}
