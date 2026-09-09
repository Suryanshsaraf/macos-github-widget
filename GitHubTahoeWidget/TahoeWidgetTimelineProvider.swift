import WidgetKit
import SwiftUI

public struct TahoeWidgetEntry: TimelineEntry {
    public let date: Date
    public let profile: GitHubUserProfile?
    public let theme: String
    
    public init(date: Date, profile: GitHubUserProfile?, theme: String) {
        self.date = date
        self.profile = profile
        self.theme = theme
    }
}

public struct TahoeWidgetTimelineProvider: TimelineProvider {
    public typealias Entry = TahoeWidgetEntry
    
    private let networkService = GitHubNetworkService()
    
    public init() {}
    
    // Placeholder shown in the Widget Gallery preview
    public func placeholder(in context: Context) -> TahoeWidgetEntry {
        let dummyDays = (0..<140).map { i in
            GitHubContributionDay(
                date: "2026-01-\(String(format: "%02d", i % 28 + 1))",
                count: Int.random(in: 0...10),
                level: Int.random(in: 0...4)
            )
        }
        
        let dummyProfile = GitHubUserProfile(
            username: "Suryanshsaraf",
            name: "Suryansh Saraf",
            avatarUrl: "",
            bio: "AI systems builder",
            followers: 124,
            stars: 84,
            totalContributions: 1066,
            currentStreak: 6,
            longestStreak: 12,
            contributions: dummyDays,
            incomingPRs: [],
            outgoingPRs: [],
            authenticated: false
        )
        return TahoeWidgetEntry(date: Date(), profile: dummyProfile, theme: "tahoe-dream")
    }
    
    // Quick preview snapshot
    public func getSnapshot(in context: Context, completion: @escaping (TahoeWidgetEntry) -> ()) {
        WidgetSettingsStore.shared.loadSettings()
        let entry = TahoeWidgetEntry(
            date: Date(),
            profile: WidgetSettingsStore.shared.cachedProfile,
            theme: WidgetSettingsStore.shared.theme
        )
        completion(entry)
    }
    
    // Core timeline generation
    public func getTimeline(in context: Context, completion: @escaping (Timeline<TahoeWidgetEntry>) -> ()) {
        WidgetSettingsStore.shared.loadSettings()
        
        let username = WidgetSettingsStore.shared.username
        let token = WidgetSettingsStore.shared.token
        let theme = WidgetSettingsStore.shared.theme
        let cached = WidgetSettingsStore.shared.cachedProfile
        
        let nextUpdate = Date(timeIntervalSinceNow: 15 * 60) // Update in 15 minutes
        
        // If username is default or empty, return immediately with empty profile
        if username.isEmpty || username == "octocat" {
            let entry = TahoeWidgetEntry(date: Date(), profile: nil, theme: theme)
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
            return
        }
        
        Task {
            // Use withTaskGroup with strict 5-second timeout to prevent WidgetKit watchdog kills
            let fetchedProfile: GitHubUserProfile? = await withTaskGroup(of: GitHubUserProfile?.self) { group in
                group.addTask {
                    do {
                        let tokenOpt = token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : token
                        return try await self.networkService.fetchUserProfile(username: username, token: tokenOpt)
                    } catch {
                        return nil
                    }
                }
                
                group.addTask {
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds timeout
                    return nil
                }
                
                for await result in group {
                    if let result = result {
                        group.cancelAll()
                        return result
                    }
                }
                return nil
            }
            
            let finalProfile: GitHubUserProfile?
            if let fresh = fetchedProfile {
                WidgetSettingsStore.shared.cacheProfile(fresh)
                finalProfile = fresh
            } else {
                finalProfile = cached ?? WidgetSettingsStore.shared.cachedProfile
            }
            
            let entry = TahoeWidgetEntry(date: Date(), profile: finalProfile, theme: theme)
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }
}
