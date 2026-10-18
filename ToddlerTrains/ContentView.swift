import SwiftUI
import AVFoundation

// MARK: - Audio & Speech Manager
final class SoundManager: ObservableObject {
    static let shared = SoundManager()
    private let speechSynth = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.3 // Toddler-friendly cheerful voice
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynth.speak(utterance)
    }

    func playChug() {
        // Synthesize a quick playful sound or haptic
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func playPop() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func playHorn() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        speak("Choo Choo!")
    }
}

// MARK: - Models
enum TrainType: String, CaseIterable, Identifiable {
    case steam = "Steam Engine"
    case bullet = "Bullet Train"
    case freight = "Diesel Freight"

    var id: String { rawValue }
}

enum EnvironmentTheme: String, CaseIterable, Identifiable {
    case sunny = "Sunny Day"
    case night = "Starry Night"
    case snowy = "Snowy Hills"
    case desert = "Desert Canyon"

    var id: String { rawValue }

    var skyColors: [Color] {
        switch self {
        case .sunny: return [Color(red: 0.50, green: 0.82, blue: 0.98), Color(red: 0.70, green: 0.91, blue: 1.0)]
        case .night: return [Color(red: 0.05, green: 0.08, blue: 0.22), Color(red: 0.12, green: 0.16, blue: 0.38)]
        case .snowy: return [Color(red: 0.72, green: 0.84, blue: 0.92), Color(red: 0.88, green: 0.94, blue: 0.98)]
        case .desert: return [Color(red: 0.98, green: 0.76, blue: 0.54), Color(red: 1.0, green: 0.88, blue: 0.70)]
        }
    }

    var hillColor: Color {
        switch self {
        case .sunny: return Color(red: 0.36, green: 0.72, blue: 0.22)
        case .night: return Color(red: 0.15, green: 0.30, blue: 0.15)
        case .snowy: return Color(red: 0.92, green: 0.96, blue: 0.99)
        case .desert: return Color(red: 0.86, green: 0.55, blue: 0.30)
        }
    }
}

enum TrackMode: String, CaseIterable, Identifiable {
    case straight = "Straight"
    case wavy = "Hilly"
    case loop = "Circle"

    var id: String { rawValue }
}

struct FloatingItem: Identifiable {
    let id = UUID()
    var isBubble: Bool
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var speed: CGFloat
    var swayOffset: CGFloat = 0
}

struct PopEffect: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let text: String
    let color: Color
}

// MARK: - Main ContentView
struct ContentView: View {
    @StateObject private var sound = SoundManager.shared

    // Train State
    @State private var trainType: TrainType = .steam
    @State private var environment: EnvironmentTheme = .sunny
    @State private var trackMode: TrackMode = .straight
    @State private var carColors: [Color] = [.blue, .orange, .purple]
    @State private var trainPosition: CGFloat = -200
    @State private var circleAngle: Double = 0
    @State private var steamPuffs: [CGPoint] = []

    // Learning / Floating Items State
    @State private var items: [FloatingItem] = []
    @State private var popEffects: [PopEffect] = []
    @State private var currentStepIndex: Int = 0 // 0..25 is A-Z, 26..45 is 1-20

    private let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }
    private let numbers = (1...20).map { String($0) }

    var currentDisplaySymbol: String {
        if currentStepIndex < alphabet.count {
            return alphabet[currentStepIndex]
        } else {
            return numbers[currentStepIndex - alphabet.count]
        }
    }

    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Background Sky
                LinearGradient(colors: environment.skyColors, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                // Sun / Moon / Stars
                if environment == .night {
                    nightSkyDecorations(in: geo)
                } else {
                    daySunDecoration(in: geo)
                }

                // Hills and Ground
                if trackMode != .loop {
                    hillsView(width: w, height: h)
                }

                // Tracks & Train
                trackAndTrainLayer(width: w, height: h)

                // Floating Balloons & Bubbles
                ForEach(items) { item in
                    FloatingItemView(item: item)
                        .position(x: item.x + sin(item.swayOffset) * 15, y: item.y)
                        .onTapGesture {
                            popItem(item)
                        }
                }

                // Pop Text Effects (revealing ABC / 123)
                ForEach(popEffects) { effect in
                    Text(effect.text)
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundColor(effect.color)
                        .shadow(color: .white, radius: 4)
                        .position(x: effect.x, y: effect.y)
                        .transition(.scale.combined(with: .opacity))
                }

                // Controls Overlay (Kid friendly, large colorful buttons)
                controlsOverlay(width: w)
            }
            .onAppear {
                spawnInitialItems(width: w, height: h)
            }
            .onReceive(timer) { _ in
                updateGameTick(width: w, height: h)
            }
        }
    }

    // MARK: - Subviews & Layers

    private func daySunDecoration(in geo: GeometryProxy) -> some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 80, height: 80)
            .shadow(color: .orange.opacity(0.6), radius: 25)
            .position(x: geo.size.width - 70, y: 80)
    }

    private func nightSkyDecorations(in geo: GeometryProxy) -> some View {
        ZStack {
            // Crescent Moon
            Circle()
                .fill(Color(white: 0.95))
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .fill(environment.skyColors[0])
                        .frame(width: 50, height: 50)
                        .offset(x: -12, y: -8)
                )
                .position(x: geo.size.width - 70, y: 80)

            // Random sparkling stars
            ForEach(0..<15, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 4, height: 4)
                    .position(x: CGFloat((i * 67) % Int(geo.size.width)), y: CGFloat((i * 43) % Int(geo.size.height / 2)))
            }
        }
    }

    private func hillsView(width: CGFloat, height: CGFloat) -> some View {
        VStack {
            Spacer()
            ZStack(alignment: .bottom) {
                // Background rolling hill
                Ellipse()
                    .fill(environment.hillColor.opacity(0.7))
                    .frame(width: width * 1.5, height: height * 0.4)
                    .offset(x: -width * 0.2, y: height * 0.1)

                // Foreground hill
                Ellipse()
                    .fill(environment.hillColor)
                    .frame(width: width * 1.8, height: height * 0.35)
                    .offset(x: width * 0.1, y: height * 0.12)
            }
            .frame(height: height * 0.35)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func trackAndTrainLayer(width: CGFloat, height: CGFloat) -> some View {
        if trackMode == .loop {
            // Circular Track
            let radius = min(width, height) * 0.32
            let center = CGPoint(x: width / 2, y: height / 2 + 20)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.8), style: StrokeStyle(lineWidth: 18, dash: [10, 10]))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                // The looping train
                trainCompositionView()
                    .rotationEffect(.degrees(circleAngle + 90))
                    .position(
                        x: center.x + radius * cos(circleAngle * .pi / 180),
                        y: center.y + radius * sin(circleAngle * .pi / 180)
                    )
            }
        } else {
            // Linear & Hilly Tracks
            let trackY = height * 0.80

            ZStack {
                // Rails
                Path { p in
                    p.move(to: CGPoint(x: 0, y: trackY))
                    p.addLine(to: CGPoint(x: width, y: trackY))
                    p.move(to: CGPoint(x: 0, y: trackY + 12))
                    p.addLine(to: CGPoint(x: width, y: trackY + 12))
                }
                .stroke(Color.gray, lineWidth: 4)

                // Sleepers/Ties
                HStack(spacing: 20) {
                    ForEach(0..<Int(width / 20) + 1, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.brown)
                            .frame(width: 8, height: 22)
                    }
                }
                .position(x: width / 2, y: trackY + 6)

                // Steam puffs
                ForEach(steamPuffs.indices, id: \.self) { idx in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 25, height: 25)
                        .position(steamPuffs[idx])
                }

                // Train
                trainCompositionView()
                    .position(x: trainPosition, y: trackY - 20)
            }
        }
    }

    private func trainCompositionView() -> some View {
        HStack(spacing: 4) {
            // Passenger / Cargo Cars
            ForEach(0..<carColors.count, id: \.self) { idx in
                TrainCarView(color: carColors[idx], type: trainType)
                    .onTapGesture {
                        cycleCarColor(at: idx)
                    }
            }

            // Locomotive Engine
            LocomotiveView(type: trainType)
                .onTapGesture {
                    sound.playHorn()
                    puffSteam()
                }
        }
    }

    private func controlsOverlay(width: CGFloat) -> some View {
        VStack {
            HStack(spacing: 12) {
                // Environment Switcher
                Button {
                    cycleEnvironment()
                } label: {
                    Label(environment.rawValue, systemImage: "mountain.2.fill")
                        .font(.system(size: 14, weight: .bold))
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                }

                // Track Mode Switcher
                Button {
                    cycleTrackMode()
                } label: {
                    Label(trackMode.rawValue, systemImage: "road.lanes")
                        .font(.system(size: 14, weight: .bold))
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                }

                // Train Type Switcher
                Button {
                    cycleTrainType()
                } label: {
                    Label(trainType.rawValue, systemImage: "tram.fill")
                        .font(.system(size: 14, weight: .bold))
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                }

                Spacer()

                // Add/Remove Car Buttons
                HStack(spacing: 6) {
                    Button(action: removeCar) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red)
                    }
                    .disabled(carColors.count <= 1)

                    Button(action: addCar) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.green)
                    }
                    .disabled(carColors.count >= 7)
                }
                .padding(6)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.horizontal)
            .padding(.top, 10)

            Spacer()
        }
    }

    // MARK: - Game Loops & Interactions

    private func updateGameTick(width: CGFloat, height: CGFloat) {
        // Move Train
        if trackMode == .loop {
            circleAngle = (circleAngle + 1.2).truncatingRemainder(dividingBy: 360)
        } else {
            let totalTrainLength = CGFloat(carColors.count + 1) * 75
            if trainPosition > width + totalTrainLength {
                trainPosition = -totalTrainLength
            } else {
                trainPosition += 2.5
            }
        }

        // Float balloons and bubbles
        for i in items.indices {
            items[i].y -= items[i].speed
            items[i].swayOffset += 0.05
        }

        // Remove off-screen items & replace them
        items.removeAll { $0.y < -50 }
        if items.count < 9 {
            spawnItem(width: width, height: height)
        }

        // Dissolve steam puffs
        for i in steamPuffs.indices {
            steamPuffs[i].y -= 1.5
            steamPuffs[i].x -= 0.5
        }
        if steamPuffs.count > 10 {
            steamPuffs.removeFirst()
        }
    }

    private func spawnInitialItems(width: CGFloat, height: CGFloat) {
        items.removeAll()
        for _ in 0..<8 {
            spawnItem(width: width, height: height, randomY: true)
        }
    }

    private func spawnItem(width: CGFloat, height: CGFloat, randomY: Bool = false) {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .yellow]
        let isBubble = Bool.random()
        let newItem = FloatingItem(
            isBubble: isBubble,
            x: CGFloat.random(in: 40...(width - 40)),
            y: randomY ? CGFloat.random(in: 100...(height * 0.7)) : height + 50,
            size: isBubble ? CGFloat.random(in: 45...65) : CGFloat.random(in: 60...80),
            color: colors.randomElement() ?? .red,
            speed: CGFloat.random(in: 1.2...2.6)
        )
        items.append(newItem)
    }

    private func popItem(_ item: FloatingItem) {
        sound.playPop()

        // Spoken letter / number progression
        let revealedSymbol = currentDisplaySymbol
        sound.speak(revealedSymbol)

        // Advance to next step
        let totalSteps = alphabet.count + numbers.count
        currentStepIndex = (currentStepIndex + 1) % totalSteps

        // Pop Animation Effect
        let effect = PopEffect(x: item.x, y: item.y, text: revealedSymbol, color: item.color)
        popEffects.append(effect)
        items.removeAll { $0.id == item.id }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            popEffects.removeAll { $0.id == effect.id }
        }
    }

    private func puffSteam() {
        if trackMode != .loop {
            steamPuffs.append(CGPoint(x: trainPosition + 25, y: (UIScreen.main.bounds.height * 0.8) - 55))
        }
    }

    private func addCar() {
        let palette: [Color] = [.blue, .green, .orange, .purple, .pink, .yellow, .cyan]
        carColors.append(palette.randomElement() ?? .blue)
        sound.playChug()
    }

    private func removeCar() {
        if !carColors.isEmpty {
            carColors.removeLast()
            sound.playChug()
        }
    }

    private func cycleCarColor(at index: Int) {
        let palette: [Color] = [.blue, .green, .orange, .purple, .pink, .yellow, .cyan, .red]
        if let current = palette.firstIndex(of: carColors[index]) {
            carColors[index] = palette[(current + 1) % palette.count]
        } else {
            carColors[index] = .green
        }
        sound.playPop()
    }

    private func cycleEnvironment() {
        let all = EnvironmentTheme.allCases
        if let idx = all.firstIndex(of: environment) {
            environment = all[(idx + 1) % all.count]
        }
    }

    private func cycleTrackMode() {
        let all = TrackMode.allCases
        if let idx = all.firstIndex(of: trackMode) {
            trackMode = all[(idx + 1) % all.count]
        }
    }

    private func cycleTrainType() {
        let all = TrainType.allCases
        if let idx = all.firstIndex(of: trainType) {
            trainType = all[(idx + 1) % all.count]
        }
    }
}

// MARK: - Individual Component Views

struct FloatingItemView: View {
    let item: FloatingItem

    var body: some View {
        if item.isBubble {
            // Soap bubble with specular highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.8), item.color.opacity(0.3), item.color.opacity(0.6)],
                        center: .topLeading,
                        startRadius: 5,
                        endRadius: item.size
                    )
                )
                .frame(width: item.size, height: item.size)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                )
        } else {
            // Balloon with tied knot and string
            VStack(spacing: 0) {
                Capsule()
                    .fill(item.color.gradient)
                    .frame(width: item.size * 0.85, height: item.size)
                    .shadow(color: item.color.opacity(0.4), radius: 4, x: 2, y: 3)

                // Knot
                Triangle()
                    .fill(item.color)
                    .frame(width: 8, height: 6)

                // String
                Path { p in
                    p.move(to: .zero)
                    p.addQuadCurve(to: CGPoint(x: 2, y: 22), control: CGPoint(x: 8, y: 11))
                }
                .stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                .frame(width: 10, height: 22)
            }
        }
    }
}

struct LocomotiveView: View {
    let type: TrainType

    var body: some View {
        ZStack(alignment: .bottom) {
            switch type {
            case .steam:
                // Classic Red Steam Engine
                VStack(spacing: 0) {
                    HStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 10, height: 16) // Smokestack
                        Spacer()
                    }
                    .frame(width: 60)

                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 38, height: 32)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red)
                            .frame(width: 30, height: 42)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 14, height: 14)
                            )
                    }
                }

            case .bullet:
                // Aerodynamic Shinkansen style
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .frame(width: 72, height: 36)
                    .overlay(
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: 25, height: 12)
                        }
                    )

            case .freight:
                // Heavy yellow diesel locomotive
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange)
                    .frame(width: 70, height: 38)
                    .overlay(
                        VStack {
                            Rectangle()
                                .fill(Color.black)
                                .frame(height: 6)
                            Spacer()
                        }
                    )
            }

            // Wheels
            HStack(spacing: 12) {
                Circle().fill(Color.black).frame(width: 16, height: 16)
                Circle().fill(Color.black).frame(width: 16, height: 16)
                Circle().fill(Color.black).frame(width: 16, height: 16)
            }
            .offset(y: 8)
        }
    }
}

struct TrainCarView: View {
    let color: Color
    let type: TrainType

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 55, height: 32)
                .overlay(
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                    }
                )

            // Wheels
            HStack(spacing: 16) {
                Circle().fill(Color.black).frame(width: 14, height: 14)
                Circle().fill(Color.black).frame(width: 14, height: 14)
            }
            .offset(y: 7)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
