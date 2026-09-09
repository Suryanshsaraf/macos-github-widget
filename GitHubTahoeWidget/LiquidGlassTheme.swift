import SwiftUI

public extension Color {
    static let tahoeCyan = Color(red: 0.0, green: 0.9, blue: 1.0)
    static let tahoePurple = Color(red: 0.58, green: 0.2, blue: 0.92)
    static let tahoePink = Color(red: 1.0, green: 0.0, blue: 0.5)
    
    static func colorForLevel(_ level: Int, theme: String) -> Color {
        if level == 0 {
            return Color(red: 22/255, green: 27/255, blue: 34/255) // #161b22
        }
        
        switch theme {
        case "aurora-glass":
            switch level {
            case 1: return Color(red: 11/255, green: 60/255, blue: 93/255)
            case 2: return Color(red: 50/255, green: 140/255, blue: 193/255)
            case 3: return Color(red: 152/255, green: 215/255, blue: 194/255)
            default: return Color(red: 0/255, green: 240/255, blue: 255/255)
            }
        case "sunset-glow":
            switch level {
            case 1: return Color(red: 74/255, green: 28/255, blue: 28/255)
            case 2: return Color(red: 189/255, green: 64/255, blue: 36/255)
            case 3: return Color(red: 250/255, green: 129/255, blue: 47/255)
            default: return Color(red: 255/255, green: 171/255, blue: 118/255)
            }
        case "graphite-matte":
            switch level {
            case 1: return Color(red: 48/255, green: 54/255, blue: 61/255) // #30363d
            case 2: return Color(red: 110/255, green: 118/255, blue: 129/255) // #6e7681
            case 3: return Color(red: 177/255, green: 186/255, blue: 196/255) // #b1bac4
            default: return Color(red: 240/255, green: 246/255, blue: 252/255) // #f0f6fc
            }
        default: // tahoe-dream (Standard GitHub Greens)
            switch level {
            case 1: return Color(red: 14/255, green: 68/255, blue: 41/255) // #0e4429
            case 2: return Color(red: 0/255, green: 109/255, blue: 50/255) // #006d32
            case 3: return Color(red: 38/255, green: 166/255, blue: 65/255) // #26a641
            default: return Color(red: 57/255, green: 211/255, blue: 83/255) // #39d353
            }
        }
    }
}


// Liquid Glass Backing Card Modifier
public struct LiquidGlassModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            )
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 30, x: 0, y: 20)
    }
}

public extension View {
    func liquidGlassBacking() -> some View {
        self.modifier(LiquidGlassModifier())
    }
}

// Drifting Liquid Blob Background (Matches CSS drift keyframes)
public struct LiquidBlobsView: View {
    @State private var animate = false
    let theme: String
    
    public init(theme: String) {
        self.theme = theme
    }
    
    private var blobColors: (Color, Color, Color) {
        switch theme {
        case "aurora-glass":
            return (Color.green, Color.cyan, Color.blue)
        case "sunset-glow":
            return (Color.orange, Color.red, Color.tahoePink)
        case "graphite-matte":
            return (Color.gray, Color.white, Color.black)
        default:
            return (Color.tahoeCyan, Color.tahoePink, Color.tahoePurple)
        }
    }
    
    public var body: some View {
        ZStack {
            // Blob 1 (Cyan/Green/Orange)
            Circle()
                .fill(RadialGradient(colors: [blobColors.0.opacity(0.4), blobColors.0.opacity(0)], center: .center, startRadius: 0, endRadius: 120))
                .frame(width: 250, height: 250)
                .offset(x: animate ? 60 : -40, y: animate ? -50 : 30)
            
            // Blob 2 (Pink/Red/White)
            Circle()
                .fill(RadialGradient(colors: [blobColors.1.opacity(0.35), blobColors.1.opacity(0)], center: .center, startRadius: 0, endRadius: 100))
                .frame(width: 220, height: 220)
                .offset(x: animate ? -40 : 50, y: animate ? 60 : -40)
            
            // Blob 3 (Purple/Blue/Black)
            Circle()
                .fill(RadialGradient(colors: [blobColors.2.opacity(0.3), blobColors.2.opacity(0)], center: .center, startRadius: 0, endRadius: 150))
                .frame(width: 300, height: 300)
                .offset(x: animate ? 30 : -20, y: animate ? 20 : 50)
        }
        .blur(radius: 40)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 25)
                .repeatForever(autoreverses: true)
            ) {
                animate.toggle()
            }
        }
    }
}
