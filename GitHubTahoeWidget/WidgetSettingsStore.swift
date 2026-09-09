import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

public struct WidgetSettingsData: Codable {
    public var username: String
    public var token: String
    public var theme: String
    
    public init(username: String, token: String, theme: String) {
        self.username = username
        self.token = token
        self.theme = theme
    }
}

public class WidgetSettingsStore: ObservableObject {
    public static let shared = WidgetSettingsStore()
    
    public static let appGroupId = "group.U5277LWTD3.com.Suryanshsaraf.github-tahoe-widget"
    
    @Published public var username: String = "Suryanshsaraf"
    @Published public var token: String = ""
    @Published public var theme: String = "tahoe-dream"
    @Published public var cachedProfile: GitHubUserProfile? = nil
    
    private var sharedContainerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupId)
    }
    
    private var settingsFileURL: URL? {
        return sharedContainerURL?.appendingPathComponent("settings.json")
    }
    
    private var profileFileURL: URL? {
        return sharedContainerURL?.appendingPathComponent("cached_profile.json")
    }
    
    private var defaults: UserDefaults {
        return UserDefaults(suiteName: Self.appGroupId) ?? UserDefaults.standard
    }
    
    private init() {
        loadSettings()
    }
    
    public func saveSettings(username: String, token: String, theme: String) {
        self.username = username
        self.token = token
        self.theme = theme
        
        // 1. File-based persistence in shared App Group container
        if let fileURL = settingsFileURL {
            let data = WidgetSettingsData(username: username, token: token, theme: theme)
            if let encoded = try? JSONEncoder().encode(data) {
                try? encoded.write(to: fileURL, options: .atomic)
            }
        }
        
        // 2. UserDefaults suite fallback
        defaults.set(username, forKey: "github_username")
        defaults.set(token, forKey: "github_token")
        defaults.set(theme, forKey: "github_theme")
        defaults.synchronize()
        
        // 3. Notify WidgetKit
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "GitHubTahoeWidget")
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    public func loadSettings() {
        // 1. Try reading from shared container file first
        var loadedFromFile = false
        if let fileURL = settingsFileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            if let data = try? Data(contentsOf: fileURL),
               let decoded = try? JSONDecoder().decode(WidgetSettingsData.self, from: data) {
                self.username = decoded.username
                self.token = decoded.token
                self.theme = decoded.theme
                loadedFromFile = true
            }
        }
        
        // 2. Fallback to UserDefaults if file wasn't present
        if !loadedFromFile {
            self.username = defaults.string(forKey: "github_username") ?? "Suryanshsaraf"
            self.token = defaults.string(forKey: "github_token") ?? ""
            self.theme = defaults.string(forKey: "github_theme") ?? "tahoe-dream"
        }
        
        // 3. Load cached profile from shared container file
        var profileLoadedFromFile = false
        if let profileURL = profileFileURL, FileManager.default.fileExists(atPath: profileURL.path) {
            if let data = try? Data(contentsOf: profileURL),
               let profile = try? JSONDecoder().decode(GitHubUserProfile.self, from: data) {
                self.cachedProfile = profile
                profileLoadedFromFile = true
            }
        }
        
        // 4. Fallback to UserDefaults for cached profile
        if !profileLoadedFromFile {
            if let data = defaults.data(forKey: "github_cached_profile"),
               let profile = try? JSONDecoder().decode(GitHubUserProfile.self, from: data) {
                self.cachedProfile = profile
            }
        }
    }
    
    public func cacheProfile(_ profile: GitHubUserProfile) {
        self.cachedProfile = profile
        
        // 1. File-based persistence in shared App Group container
        if let profileURL = profileFileURL {
            if let encoded = try? JSONEncoder().encode(profile) {
                try? encoded.write(to: profileURL, options: .atomic)
            }
        }
        
        // 2. UserDefaults fallback
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: "github_cached_profile")
            defaults.synchronize()
        }
    }
    
    public func clearCache() {
        self.cachedProfile = nil
        if let profileURL = profileFileURL {
            try? FileManager.default.removeItem(at: profileURL)
        }
        defaults.removeObject(forKey: "github_cached_profile")
        defaults.synchronize()
    }
}
