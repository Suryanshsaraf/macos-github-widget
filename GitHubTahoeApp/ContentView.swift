import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

public struct ContentView: View {
    @StateObject private var store = WidgetSettingsStore.shared
    @State private var usernameInput: String = ""
    @State private var tokenInput: String = ""
    @State private var selectedTheme: String = "tahoe-dream"
    @State private var isTestingConnection: Bool = false
    @State private var statusMessage: String = ""
    @State private var isErrorStatus: Bool = false
    
    private let networkService = GitHubNetworkService()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Animated Liquid Blobs in background
            LiquidBlobsView(theme: selectedTheme)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Frosted Glass Content Panel
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "square.grid.3x3.topleft.filled")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.tahoeCyan, .tahoePurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .tahoeCyan.opacity(0.5), radius: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GitHub Tahoe")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Liquid Glass macOS Widget Configurator")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(.bottom, 5)
                
                // Form Container (Frosted Sub-card)
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("GitHub Username")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        TextField("Enter username", text: $usernameInput)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Personal Access Token (PAT)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        SecureField("ghp_yourTokenHere...", text: $tokenInput)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .foregroundColor(.white)
                        Text("Provide a token to track private contribution metrics and PR reviews.")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Widget Theme Color")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        Picker("", selection: $selectedTheme) {
                            Text("Tahoe Dream").tag("tahoe-dream")
                            Text("Aurora Glass").tag("aurora-glass")
                            Text("Sunset Glow").tag("sunset-glow")
                            Text("Graphite Matte").tag("graphite-matte")
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                // Status message & action buttons
                HStack {
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(isErrorStatus ? .red : .tahoeCyan)
                            .shadow(color: isErrorStatus ? .clear : .tahoeCyan.opacity(0.3), radius: 5)
                            .padding(.horizontal, 4)
                            .transition(.opacity)
                    }
                    Spacer()
                    
                    Button(action: testConnection) {
                        HStack(spacing: 8) {
                            if isTestingConnection {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Test Connection")
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(usernameInput.isEmpty || isTestingConnection)
                    
                    Button(action: saveAndApply) {
                        Text("Save & Apply")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [.tahoeCyan, .tahoePurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(8)
                            .shadow(color: .tahoeCyan.opacity(0.4), radius: 8)
                    }
                    .buttonStyle(.plain)
                    .disabled(usernameInput.isEmpty)
                }
                
                // Live cached profile preview
                if let profile = store.cachedProfile {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 12) {
                        if !profile.avatarUrl.isEmpty, let url = URL(string: profile.avatarUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())
                            } placeholder: {
                                Circle().fill(Color.white.opacity(0.1)).frame(width: 44, height: 44)
                            }
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("@\(profile.username) • \(profile.authenticated ? "🔒 Private" : "🌐 Public")")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(profile.totalContributions) Contributions")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("Streak: \(profile.currentStreak) days 🔥")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
            .padding(24)
        }
        .frame(width: 540, height: 460)
        .liquidGlassBacking() // Add frosted glass container backing
        .onAppear {
            usernameInput = store.username
            tokenInput = store.token
            selectedTheme = store.theme
        }
    }
    
    private func saveAndApply() {
        store.saveSettings(username: usernameInput, token: tokenInput, theme: selectedTheme)
        statusMessage = "Settings saved! Syncing widget..."
        isErrorStatus = false
        
        Task {
            do {
                let tokenOpt = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : tokenInput
                let profile = try await networkService.fetchUserProfile(username: usernameInput, token: tokenOpt)
                await MainActor.run {
                    store.cacheProfile(profile)
                    statusMessage = "Synced & applied to widget!"
                    isErrorStatus = false
                    #if canImport(WidgetKit)
                    WidgetCenter.shared.reloadTimelines(ofKind: "GitHubTahoeWidget")
                    WidgetCenter.shared.reloadAllTimelines()
                    #endif
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Settings applied!"
                    isErrorStatus = false
                }
            }
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        statusMessage = "Connecting to GitHub..."
        isErrorStatus = false
        
        Task {
            do {
                let tokenOpt = tokenInput.isEmpty ? nil : tokenInput
                let profile = try await networkService.fetchUserProfile(username: usernameInput, token: tokenOpt)
                
                await MainActor.run {
                    store.cacheProfile(profile)
                    statusMessage = "Connected successfully!"
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Error: \(error.localizedDescription)"
                    isErrorStatus = true
                    isTestingConnection = false
                }
            }
        }
    }
}
