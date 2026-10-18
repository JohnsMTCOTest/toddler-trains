import SwiftUI

@available(iOS 16.0, *)
struct ContentView: View {
    @State private var trainOffset: CGFloat = -350
    @State private var isNight: Bool = false
    @State private var balloons: [Balloon] = []
    @State private var trainBouncing: Bool = false
    @State private var puffs: [SmokePuff] = []
    
    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    let smokeTimer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                (isNight ? Color(red: 0.08, green: 0.11, blue: 0.22) : Color(red: 0.53, green: 0.81, blue: 0.98))
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: isNight)
                
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(isNight ? Color.gray.opacity(0.8) : Color.yellow)
                            .frame(width: 80, height: 80)
                            .shadow(color: isNight ? .white.opacity(0.3) : .yellow.opacity(0.6), radius: 15)
                            .overlay(Text(isNight ? "🌙" : "☀️").font(.system(size: 40)))
                            .onTapGesture { isNight.toggle() }
                            .padding(25)
                    }
                    Spacer()
                }
                
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geo.size.height - 130))
                    path.addQuadCurve(
                        to: CGPoint(x: geo.size.width, y: geo.size.height - 130),
                        control: CGPoint(x: geo.size.width / 2, y: geo.size.height - 230)
                    )
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.40, green: 0.75, blue: 0.35))
                
                VStack(spacing: 6) {
                    Rectangle().fill(Color.gray).frame(height: 5)
                    HStack(spacing: 20) {
                        ForEach(0..<Int(geo.size.width / 20) + 5, id: \.self) { _ in
                            Rectangle().fill(Color(red: 0.45, green: 0.25, blue: 0.10)).frame(width: 8, height: 16)
                        }
                    }
                    Rectangle().fill(Color.gray).frame(height: 5)
                }
                .position(x: geo.size.width / 2, y: geo.size.height - 75)
                
                ForEach(puffs) { puff in
                    Circle()
                        .fill(Color.white.opacity(puff.opacity))
                        .frame(width: puff.size, height: puff.size)
                        .position(x: puff.x, y: puff.y)
                }
                
                TrainView()
                    .offset(y: trainBouncing ? -15 : 0)
                    .position(x: trainOffset, y: geo.size.height - 105)
                    .onTapGesture { honkTrain(screenHeight: geo.size.height) }
                
                ForEach(balloons) { balloon in
                    Text("🎈")
                        .font(.system(size: balloon.size))
                        .position(x: balloon.x, y: balloon.y)
                        .opacity(balloon.opacity)
                        .onTapGesture { popBalloon(id: balloon.id) }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in spawnBalloon(at: location) }
            .onReceive(timer) { _ in
                trainOffset += 3.5
                if trainOffset > geo.size.width + 300 { trainOffset = -300 }
                for i in balloons.indices { balloons[i].y -= 2.5 }
                balloons.removeAll { $0.y < -50 || $0.opacity <= 0 }
                for i in puffs.indices {
                    puffs[i].y -= 1.8
                    puffs[i].x -= 1.0
                    puffs[i].size += 0.8
                    puffs[i].opacity -= 0.02
                }
                puffs.removeAll { $0.opacity <= 0 }
            }
            .onReceive(smokeTimer) { _ in
                puffs.append(SmokePuff(x: trainOffset + 50, y: geo.size.height - 150))
            }
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
    }
    
    private func honkTrain(screenHeight: CGFloat) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { trainBouncing = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation { trainBouncing = false }
        }
        for _ in 0..<4 {
            puffs.append(SmokePuff(x: trainOffset + 50 + CGFloat.random(in: -10...10), y: screenHeight - 150, size: 30, opacity: 0.9))
        }
    }
    
    private func spawnBalloon(at location: CGPoint) {
        balloons.append(Balloon(x: location.x, y: location.y))
    }
    
    private func popBalloon(id: UUID) {
        if let index = balloons.firstIndex(where: { $0.id == id }) {
            withAnimation(.easeOut(duration: 0.2)) { balloons[index].opacity = 0 }
        }
    }
}

struct Balloon: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat = CGFloat.random(in: 45...65)
    var opacity: Double = 1.0
}

struct SmokePuff: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat = 16
    var opacity: Double = 0.7
}

struct TrainView: View {
    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8).fill(Color.blue).frame(width: 70, height: 45)
                .overlay(HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white).frame(width: 14, height: 14)
                    RoundedRectangle(cornerRadius: 3).fill(Color.white).frame(width: 14, height: 14)
                })
            
            RoundedRectangle(cornerRadius: 8).fill(Color.orange).frame(width: 70, height: 45)
                .overlay(HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white).frame(width: 14, height: 14)
                    RoundedRectangle(cornerRadius: 3).fill(Color.white).frame(width: 14, height: 14)
                })
            
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 6).fill(Color.red).frame(width: 50, height: 60)
                    .overlay(RoundedRectangle(cornerRadius: 4).fill(Color.white).frame(width: 18, height: 18).offset(y: -10))
                HStack(alignment: .bottom, spacing: 0) {
                    RoundedRectangle(cornerRadius: 5).fill(Color.red).frame(width: 50, height: 40)
                    Triangle().fill(Color.yellow).frame(width: 16, height: 25)
                }
                .overlay(Rectangle().fill(Color.black).frame(width: 10, height: 16).offset(x: 10, y: -28), alignment: .topLeading)
            }
        }
        .overlay(
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    Circle().fill(Color.black).frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                }
            }
            .offset(y: 26)
        )
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
