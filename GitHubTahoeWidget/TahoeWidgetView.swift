import WidgetKit
import SwiftUI

// Core Entry View representing the widget UI (Sleek GitHub Dark Mode Style)
public struct TahoeWidgetEntryView : View {
    var entry: TahoeWidgetTimelineProvider.Entry
    
    @Environment(\.widgetFamily) var family
    
    public init(entry: TahoeWidgetTimelineProvider.Entry) {
        self.entry = entry
    }
    
    public var body: some View {
        ZStack {
            if let profile = entry.profile {
                VStack(spacing: 0) {
                    switch family {
                    case .systemSmall:
                        renderSmallWidget(profile: profile)
                    case .systemMedium:
                        renderMediumWidget(profile: profile)
                    default: // systemLarge
                        renderLargeWidget(profile: profile)
                    }
                }
            } else {
                // Setup / Welcome Screen
                VStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3.topleft.filled")
                        .foregroundColor(.green)
                        .font(.title)
                    Text("GitHub Contributions")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Please open the configurator app to save your username.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(red: 125/255, green: 133/255, blue: 144/255))
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(14)
    }
    
    // --- 1. SMALL WIDGET LAYOUT (Sleek Mini Graph) ---
    private func renderSmallWidget(profile: GitHubUserProfile) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            VStack(alignment: .leading, spacing: 1) {
                Text("@\(profile.username)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Text("\(formatNumber(profile.totalContributions)) in last year")
                    .font(.system(size: 9))
                    .foregroundColor(Color(red: 125/255, green: 133/255, blue: 144/255))
            }
            
            Spacer()
            
            // 7x16 Grid for Small Widget
            let weeksToShow = 16
            let daysToShow = weeksToShow * 7
            let recentDays = Array(profile.contributions.suffix(daysToShow))
            
            HStack(spacing: 1.3) {
                ForEach(0..<weeksToShow, id: \.self) { weekIdx in
                    let startIndex = weekIdx * 7
                    VStack(spacing: 1.3) {
                        ForEach(0..<7, id: \.self) { dayIdx in
                            let index = startIndex + dayIdx
                            if index < recentDays.count {
                                let day = recentDays[index]
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.colorForLevel(day.level, theme: entry.theme))
                                    .frame(width: 5.0, height: 5.0)
                            } else {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.colorForLevel(0, theme: entry.theme))
                                    .frame(width: 5.0, height: 5.0)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
            
            // Streak
            HStack {
                Text("Streak: \(profile.currentStreak) days")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("🔥")
                    .font(.system(size: 10))
            }
        }
    }
    
    // --- 2. MEDIUM WIDGET LAYOUT (Official GitHub Grid View) ---
    private func renderMediumWidget(profile: GitHubUserProfile) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            Text("\(formatNumber(profile.totalContributions)) contributions in the last year")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 230/255, green: 237/255, blue: 243/255)) // #e6edf3
                .padding(.leading, 24)
                .padding(.top, 2)
            
            // Month labels on top
            let weeksToShow = 53
            let daysToShow = weeksToShow * 7
            let recentDays = Array(profile.contributions.suffix(daysToShow))
            
            renderMonthLabels(recentDays: recentDays)
                .padding(.leading, 24)
            
            // Day Labels & Grid
            HStack(alignment: .top, spacing: 6) {
                // Day Labels Mon, Wed, Fri
                VStack(alignment: .leading, spacing: 1.2) {
                    Text("")
                        .font(.system(size: 8))
                        .frame(height: 4.0) // Space for Sunday
                    Text("Mon")
                        .font(.system(size: 8))
                        .foregroundColor(Color(red: 125/255, green: 133/255, blue: 144/255))
                        .frame(height: 4.0)
                    Text("")
                        .font(.system(size: 8))
                        .frame(height: 4.0) // Space for Tuesday
                    Text("Wed")
                        .font(.system(size: 8))
                        .foregroundColor(Color(red: 125/255, green: 133/255, blue: 144/255))
                        .frame(height: 4.0)
                    Text("")
                        .font(.system(size: 8))
                        .frame(height: 4.0) // Space for Thursday
                    Text("Fri")
                        .font(.system(size: 8))
                        .foregroundColor(Color(red: 125/255, green: 133/255, blue: 144/255))
                        .frame(height: 4.0)
                }
                .frame(width: 18, alignment: .leading)
                
                // 53 Weeks Grid
                HStack(spacing: 1.2) {
                    ForEach(0..<weeksToShow, id: \.self) { weekIdx in
                        let startIndex = weekIdx * 7
                        VStack(spacing: 1.2) {
                            ForEach(0..<7, id: \.self) { dayIdx in
                                let index = startIndex + dayIdx
                                if index < recentDays.count {
                                    let day = recentDays[index]
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.colorForLevel(day.level, theme: entry.theme))
                                        .frame(width: 4.0, height: 4.0)
                                } else {
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.colorForLevel(0, theme: entry.theme))
                                        .frame(width: 4.0, height: 4.0)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer(minLength: 4)
            
            // Footer
            HStack {
                Text("Learn how we count contributions")
                    .font(.system(size: 8))
                    .foregroundColor(Color(red: 125/255, green: 133/255, blue: 144/255))
                
                Spacer()
                
                HStack(spacing: 2) {
                    Text("Less")
                        .font(.system(size: 8))
                        .foregroundColor(Color(red: 125/255, green: 133/255, blue: 144/255))
                    ForEach(0...4, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.colorForLevel(level, theme: entry.theme))
                            .frame(width: 4.0, height: 4.0)
                    }
                    Text("More")
                        .font(.system(size: 8))
                        .foregroundColor(Color(red: 125/255, green: 133/255, blue: 144/255))
                }
            }
            .padding(.leading, 24)
        }
    }
    
    // --- 3. LARGE WIDGET LAYOUT (Full Sleek Dashboard) ---
    private func renderLargeWidget(profile: GitHubUserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Profile Info
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("@\(profile.username)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 125/255, green: 133/255, blue: 144/255))
                }
                
                Spacer()
                
                // Stars & Followers
                HStack(spacing: 8) {
                    Text("⭐ \(profile.stars)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(4)
                    
                    Text("Followers: \(profile.followers)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(4)
                }
            }
            
            // Full Grid
            renderMediumWidget(profile: profile)
            
            Divider()
                .background(Color(red: 48/255, green: 54/255, blue: 61/255))
            
            // Active PRs list
            if !profile.outgoingPRs.isEmpty || !profile.incomingPRs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Pull Requests")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    
                    let combinedPRs = Array(profile.outgoingPRs.prefix(2)) + Array(profile.incomingPRs.prefix(2))
                    ForEach(combinedPRs, id: \.self) { pr in
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(pr.title)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text(pr.author != nil ? "Incoming Review • \(pr.repo)" : "Authored PR • \(pr.repo)")
                                    .font(.system(size: 8))
                                    .foregroundColor(Color(red: 125/255, green: 133/255, blue: 144/255))
                            }
                            Spacer()
                            Image(systemName: "arrow.up.forward.square.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // --- LAYOUT HELPERS ---
    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
    
    private func getMonthName(for dateStr: String) -> String {
        let parts = dateStr.components(separatedBy: "-")
        guard parts.count >= 2, let monthInt = Int(parts[1]) else { return "" }
        let months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        if monthInt >= 1 && monthInt <= 12 {
            return months[monthInt]
        }
        return ""
    }
    
    struct MonthLabelItem: Identifiable {
        let id: Int
        let name: String
        let offset: CGFloat
    }

    private func getMonthPositions(recentDays: [GitHubContributionDay]) -> [MonthLabelItem] {
        var positions: [(name: String, offset: CGFloat)] = []
        var lastMonth = ""
        let colWidth: CGFloat = 5.2 // cellSize (4.0) + cellSpacing (1.2)
        
        for weekIdx in 0..<53 {
            let startIndex = weekIdx * 7
            guard startIndex < recentDays.count else { continue }
            let dateStr = recentDays[startIndex].date
            let monthName = getMonthName(for: dateStr)
            
            if monthName != lastMonth && !monthName.isEmpty {
                positions.append((name: monthName, offset: CGFloat(weekIdx) * colWidth))
                lastMonth = monthName
            }
        }
        
        // Prevent overlapping
        var filtered: [MonthLabelItem] = []
        var lastOffset: CGFloat = -100
        for (idx, pos) in positions.enumerated() {
            if pos.offset - lastOffset > 18 {
                filtered.append(MonthLabelItem(id: idx, name: pos.name, offset: pos.offset))
                lastOffset = pos.offset
            }
        }
        return filtered
    }
    
    private func renderMonthLabels(recentDays: [GitHubContributionDay]) -> some View {
        let positions = getMonthPositions(recentDays: recentDays)
        return ZStack(alignment: .leading) {
            Color.clear.frame(height: 10)
            ForEach(positions) { pos in
                Text(pos.name)
                    .font(.system(size: 8))
                    .foregroundColor(Color(red: 125/255, green: 133/255, blue: 144/255))
                    .offset(x: pos.offset)
            }
        }
    }
}

// Widget Configuration entry point
@main
public struct TahoeWidget: Widget {
    let kind: String = "GitHubTahoeWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TahoeWidgetTimelineProvider()) { entry in
            TahoeWidgetEntryView(entry: entry)
                .containerBackground(Color(red: 13/255, green: 17/255, blue: 23/255), for: .widget) // GitHub Dark Mode #0d1117
        }
        .configurationDisplayName("GitHub Contributions Widget")
        .description("Display your GitHub contributions calendar and active pull requests on your desktop.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
