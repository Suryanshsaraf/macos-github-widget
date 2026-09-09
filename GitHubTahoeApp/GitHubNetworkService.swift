import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case parsingError(String)
}

public class GitHubNetworkService {
    private let userAgent = "github-tahoe-widget/1.0"
    private let session: URLSession
    
    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 8.0
        configuration.timeoutIntervalForResource = 12.0
        self.session = URLSession(configuration: configuration)
    }
    
    // Fetch profile data based on token availability
    public func fetchUserProfile(username: String, token: String?) async throws -> GitHubUserProfile {
        if let token = token, !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return try await fetchAuthenticatedProfile(username: username, token: token)
        } else {
            return try await fetchPublicProfile(username: username)
        }
    }
    
    // --- PRIVATE/AUTHENTICATED MODE (GraphQL) ---
    private func fetchAuthenticatedProfile(username: String, token: String) async throws -> GitHubUserProfile {
        guard let url = URL(string: "https://api.github.com/graphql") else {
            throw NetworkError.invalidURL
        }
        
        let query = """
        {
          user(login: \"\(username)\") {
            name
            avatarUrl
            bio
            followers {
              totalCount
            }
            repositories(first: 100, ownerAffiliations: OWNER) {
              nodes {
                stargazerCount
              }
            }
            contributionsCollection {
              contributionCalendar {
                totalContributions
                weeks {
                  contributionDays {
                    contributionCount
                    date
                  }
                }
              }
            }
          }
          incomingReviews: search(query: \"type:pr state:open review-requested:\(username)\", type: ISSUE, first: 5) {
            nodes {
              ... on PullRequest {
                title
                url
                createdAt
                repository {
                  nameWithOwner
                }
                author {
                  login
                }
              }
            }
          }
          outgoingPRs: search(query: \"type:pr state:open author:\(username)\", type: ISSUE, first: 5) {
            nodes {
              ... on PullRequest {
                title
                url
                createdAt
                repository {
                  nameWithOwner
                }
              }
            }
          }
        }
        """
        
        let graphqlQuery: [String: Any] = [
            "query": query
        ]
        
        guard let postData = try? JSONSerialization.data(withJSONObject: graphqlQuery) else {
            throw NetworkError.parsingError("Failed to serialize GraphQL query")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = postData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? ""
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, message: errorMsg)
        }
        
        // Parse GraphQL Response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataDict = json["data"] as? [String: Any] else {
            throw NetworkError.parsingError("Invalid GraphQL response JSON")
        }
        
        if let errors = json["errors"] as? [[String: Any]], let firstError = errors.first {
            let msg = firstError["message"] as? String ?? "GraphQL Error"
            throw NetworkError.httpError(statusCode: 400, message: msg)
        }
        
        guard let userDict = dataDict["user"] as? [String: Any] else {
            throw NetworkError.httpError(statusCode: 404, message: "User not found")
        }
        
        let name = userDict["name"] as? String ?? username
        let avatarUrl = userDict["avatarUrl"] as? String ?? ""
        let bio = userDict["bio"] as? String
        
        let followersDict = userDict["followers"] as? [String: Any] ?? [:]
        let followers = followersDict["totalCount"] as? Int ?? 0
        
        let reposDict = userDict["repositories"] as? [String: Any] ?? [:]
        let repoNodes = reposDict["nodes"] as? [[String: Any]] ?? []
        let stars = repoNodes.reduce(0) { $0 + ($1["stargazerCount"] as? Int ?? 0) }
        
        let contributionsCollection = userDict["contributionsCollection"] as? [String: Any] ?? [:]
        let calendar = contributionsCollection["contributionCalendar"] as? [String: Any] ?? [:]
        let totalContributions = calendar["totalContributions"] as? Int ?? 0
        
        var days: [GitHubContributionDay] = []
        if let weeks = calendar["weeks"] as? [[String: Any]] {
            for week in weeks {
                if let contributionDays = week["contributionDays"] as? [[String: Any]] {
                    for day in contributionDays {
                        let date = day["date"] as? String ?? ""
                        let count = day["contributionCount"] as? Int ?? 0
                        // Map count to standard levels 0-4
                        let level = count == 0 ? 0 : count <= 2 ? 1 : count <= 5 ? 2 : count <= 8 ? 3 : 4
                        days.append(GitHubContributionDay(date: date, count: count, level: level))
                    }
                }
            }
        }
        
        // Calculate streaks
        let streaks = calculateStreaks(days: days)
        
        // Parse Pull Requests
        var incomingPRs: [GitHubPullRequest] = []
        if let incomingDict = dataDict["incomingReviews"] as? [String: Any],
           let nodes = incomingDict["nodes"] as? [[String: Any]] {
            for node in nodes {
                let title = node["title"] as? String ?? ""
                let prUrl = node["url"] as? String ?? ""
                let createdAt = node["createdAt"] as? String ?? ""
                let repoDict = node["repository"] as? [String: Any] ?? [:]
                let repo = repoDict["nameWithOwner"] as? String ?? ""
                let authorDict = node["author"] as? [String: Any] ?? [:]
                let author = authorDict["login"] as? String ?? ""
                
                incomingPRs.append(GitHubPullRequest(title: title, url: prUrl, repo: repo, author: author, createdAt: createdAt))
            }
        }
        
        var outgoingPRs: [GitHubPullRequest] = []
        if let outgoingDict = dataDict["outgoingPRs"] as? [String: Any],
           let nodes = outgoingDict["nodes"] as? [[String: Any]] {
            for node in nodes {
                let title = node["title"] as? String ?? ""
                let prUrl = node["url"] as? String ?? ""
                let createdAt = node["createdAt"] as? String ?? ""
                let repoDict = node["repository"] as? [String: Any] ?? [:]
                let repo = repoDict["nameWithOwner"] as? String ?? ""
                
                outgoingPRs.append(GitHubPullRequest(title: title, url: prUrl, repo: repo, author: nil, createdAt: createdAt))
            }
        }
        
        return GitHubUserProfile(
            username: username,
            name: name,
            avatarUrl: avatarUrl,
            bio: bio,
            followers: followers,
            stars: stars,
            totalContributions: totalContributions,
            currentStreak: streaks.current,
            longestStreak: streaks.longest,
            contributions: days,
            incomingPRs: incomingPRs,
            outgoingPRs: outgoingPRs,
            authenticated: true
        )
    }
    
    // --- PUBLIC MODE (REST + HTML Scraping) ---
    private func fetchPublicProfile(username: String) async throws -> GitHubUserProfile {
        var name = username
        var avatarUrl = "https://github.com/\(username).png"
        var bio: String? = nil
        var followers = 0
        var stars = 0
        
        // 1. Fetch REST Profile (best effort, graceful fallback on rate limits)
        if let profileUrl = URL(string: "https://api.github.com/users/\(username)") {
            var profileRequest = URLRequest(url: profileUrl)
            profileRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            if let (profileData, profileResponse) = try? await session.data(for: profileRequest),
               let profileHttpResponse = profileResponse as? HTTPURLResponse, profileHttpResponse.statusCode == 200,
               let profileJson = try? JSONSerialization.jsonObject(with: profileData) as? [String: Any] {
                name = profileJson["name"] as? String ?? username
                avatarUrl = profileJson["avatar_url"] as? String ?? avatarUrl
                bio = profileJson["bio"] as? String
                followers = profileJson["followers"] as? Int ?? 0
            }
        }
        
        // 2. Fetch Stars count from Repos (best effort)
        if let reposUrl = URL(string: "https://api.github.com/users/\(username)/repos?per_page=100") {
            var reposRequest = URLRequest(url: reposUrl)
            reposRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            if let (reposData, reposResponse) = try? await session.data(for: reposRequest),
               let reposHttpResponse = reposResponse as? HTTPURLResponse, reposHttpResponse.statusCode == 200,
               let reposJson = try? JSONSerialization.jsonObject(with: reposData) as? [[String: Any]] {
                stars = reposJson.reduce(0) { $0 + ($1["stargazers_count"] as? Int ?? 0) }
            }
        }
        
        // 3. Scrape Contributions HTML (core requirement)
        guard let contribsUrl = URL(string: "https://github.com/users/\(username)/contributions") else {
            throw NetworkError.invalidURL
        }
        
        var contribsRequest = URLRequest(url: contribsUrl)
        contribsRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let (contribsData, _) = try await session.data(for: contribsRequest)
        guard let html = String(data: contribsData, encoding: .utf8) else {
            throw NetworkError.parsingError("Failed to encode HTML contributions")
        }
        
        // Parse HTML using Regex
        let days = parseContributions(html: html)
        var totalContributions = days.reduce(0) { $0 + $1.count } // Fallback
        
        // Parse exact total contributions from HTML heading
        let headingPattern = "([\\d,]+)\\s+contributions\\s+in\\s+the\\s+last\\s+year"
        if let regex = try? NSRegularExpression(pattern: headingPattern, options: [.caseInsensitive]) {
            let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, options: [], range: nsRange),
               let countRange = Range(match.range(at: 1), in: html) {
                let cleanStr = html[countRange].replacingOccurrences(of: ",", with: "")
                if let parsedCount = Int(cleanStr) {
                    totalContributions = parsedCount
                }
            }
        }
        
        let streaks = calculateStreaks(days: days)
        
        return GitHubUserProfile(
            username: username,
            name: name,
            avatarUrl: avatarUrl,
            bio: bio,
            followers: followers,
            stars: stars,
            totalContributions: totalContributions,
            currentStreak: streaks.current,
            longestStreak: streaks.longest,
            contributions: days,
            incomingPRs: [],
            outgoingPRs: [],
            authenticated: false
        )
    }
    
    // Parse HTML table cells/rects
    private func parseContributions(html: String) -> [GitHubContributionDay] {
        var days: [GitHubContributionDay] = []
        
        // Regex patterns for <td> and <rect> elements
        let patterns = [
            "<td[^>]+data-date=\"(\\d{4}-\\d{2}-\\d{2})\"[^>]+data-level=\"(\\d)\"",
            "<rect[^>]+data-date=\"(\\d{4}-\\d{2}-\\d{2})\"[^>]+data-level=\"(\\d)\""
        ]
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            let matches = regex.matches(in: html, options: [], range: range)
            
            for match in matches {
                if match.numberOfRanges >= 3,
                   let dateRange = Range(match.range(at: 1), in: html),
                   let levelRange = Range(match.range(at: 2), in: html) {
                    let date = String(html[dateRange])
                    let level = Int(html[levelRange]) ?? 0
                    let count = level == 0 ? 0 : level == 1 ? 1 : level == 2 ? 3 : level == 3 ? 6 : 12
                    days.append(GitHubContributionDay(date: date, count: count, level: level))
                }
            }
            
            if !days.isEmpty { break } // Stop if we parsed successfully using the first pattern
        }
        
        return days.sorted { $0.date < $1.date }
    }
    
    // Streak calculations in Swift
    private func calculateStreaks(days: [GitHubContributionDay]) -> (current: Int, longest: Int) {
        let sortedDays = days.sorted { $0.date < $1.date }
        if sortedDays.isEmpty { return (0, 0) }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var current = 0
        var longest = 0
        var temp = 0
        
        let todayStr = dateFormatter.string(from: Date())
        let yesterdayStr = dateFormatter.string(from: Date(timeIntervalSinceNow: -86400))
        
        var hasContributedRecent = false
        
        for day in sortedDays {
            if day.count > 0 {
                temp += 1
                if temp > longest {
                    longest = temp
                }
                if day.date == todayStr || day.date == yesterdayStr {
                    hasContributedRecent = true
                }
            } else {
                temp = 0
            }
        }
        
        if hasContributedRecent {
            var i = sortedDays.count - 1
            while i >= 0 && sortedDays[i].date > todayStr {
                i -= 1
            }
            
            if i >= 0 && (sortedDays[i].date == todayStr || sortedDays[i].date == yesterdayStr) {
                while i >= 0 {
                    if sortedDays[i].count > 0 {
                        current += 1
                    } else if sortedDays[i].date != todayStr {
                        break
                    }
                    i -= 1
                }
            }
        }
        
        return (current, longest)
    }
}

// Swift concurrency helper compatibility for older macOS versions if needed
extension URLSession {
    @available(macOS, deprecated: 12.0, message: "Use native Swift concurrency URLSession methods instead")
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: URLError(.unknown))
                }
            }
            task.resume()
        }
    }
}
