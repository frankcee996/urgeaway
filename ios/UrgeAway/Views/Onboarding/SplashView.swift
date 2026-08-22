import SwiftUI

/// The signature swoosh, drawn once on cold launch then faded out. Ported
/// from `renderSplashScreen` in flows.js (SVG stroke-dashoffset animation
/// there → SwiftUI `trim`-based stroke animation here).
struct SplashView: View {
    let onDone: () -> Void
    @State private var trim: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            Theme.bg0.ignoresSafeArea()
            SwooshMark()
                .trim(from: 0, to: trim)
                .stroke(LinearGradient(colors: [Theme.cyan, Theme.green], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 150, height: 150)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 2.0)) { trim = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation(.easeInOut(duration: 0.4)) { opacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: onDone)
            }
        }
    }
}

private struct SwooshMark: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.22, y: h * 0.61))
        p.addCurve(to: CGPoint(x: w * 0.78, y: h * 0.37),
                   control1: CGPoint(x: w * 0.32, y: h * 0.33), control2: CGPoint(x: w * 0.55, y: h * 0.74))
        return p
    }
}
