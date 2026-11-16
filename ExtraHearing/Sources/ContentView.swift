import SwiftUI

struct ContentView: View {
    @StateObject private var audio = AudioEngineManager()
    
    // Hex colors
    private let bgTop = Color(hex: "0b1520")
    private let bgMid = Color(hex: "070d14")
    private let bgBottom = Color(hex: "03060a")
    private let micActiveColor = Color(hex: "FF3B30")
    private let micMutedColor = Color(hex: "34C759")
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [bgTop, bgMid, bgBottom]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Top Bar with EQ and MIC Buttons
                HStack {
                    // EQ Button
                    Button(action: {
                        audio.toggleEQ()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.vertical.3")
                            Text("EQ")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(audio.isEQEnabled ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                        .foregroundColor(audio.isEQEnabled ? .white : .gray)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(audio.isEQEnabled ? Color.cyan.opacity(0.6) : Color.clear, lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                    
                    // Center Title / Brand
                    Text("Super Hearing")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // MIC Button (Red when hearing active, Green when muted locally)
                    Button(action: {
                        audio.toggleLocalMute()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: audio.isLocalMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                            Text("MIC")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(audio.isLocalMuted ? micMutedColor.opacity(0.2) : micActiveColor.opacity(0.2))
                        .foregroundColor(audio.isLocalMuted ? micMutedColor : micActiveColor)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(audio.isLocalMuted ? micMutedColor : micActiveColor, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Mic Badge with Glow Effect
                ZStack {
                    if audio.isRunning && !audio.isLocalMuted {
                        Circle()
                            .fill(micActiveColor.opacity(0.25))
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)
                        
                        Circle()
                            .stroke(micActiveColor.opacity(0.5), lineWidth: 2)
                            .frame(width: 110, height: 110)
                            .scaleEffect(audio.isRunning ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: audio.isRunning)
                    }
                    
                    Circle()
                        .fill(audio.isRunning ? (audio.isLocalMuted ? micMutedColor : micActiveColor) : Color.white.opacity(0.08))
                        .frame(width: 84, height: 84)
                        .shadow(color: audio.isRunning ? (audio.isLocalMuted ? micMutedColor : micActiveColor).opacity(0.6) : .clear, radius: 15)
                    
                    Image(systemName: audio.isLocalMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Big Amplification Percentage Display
                VStack(spacing: 6) {
                    Text("\(Int(audio.amplification * 100))%")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                    
                    Text("مستوى التضخيم الفائق")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                // Slider
                VStack(spacing: 12) {
                    Slider(value: $audio.amplification, in: 0.0...1.0, step: 0.01)
                        .accentColor(audio.isLocalMuted ? micMutedColor : micActiveColor)
                    
                    HStack {
                        Text("0%")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("50%")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("100% (+24dB)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Main Play/Stop Button
                Button(action: {
                    audio.toggleEngine()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: audio.isRunning ? "stop.fill" : "play.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text(audio.isRunning ? "إيقاف الاستماع" : "بدء الاستماع المباشر")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        audio.isRunning
                        ? LinearGradient(colors: [Color(hex: "FF3B30"), Color(hex: "D70015")], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color(hex: "0A84FF"), Color(hex: "0066CC")], startPoint: .top, endPoint: .bottom)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(29)
                    .shadow(color: (audio.isRunning ? Color(hex: "FF3B30") : Color(hex: "0A84FF")).opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
    }
}

// Extension to support Hex colors in SwiftUI
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
