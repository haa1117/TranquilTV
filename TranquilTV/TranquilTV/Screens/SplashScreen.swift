import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var opacity = 0.0

    var body: some View {
        if isActive {
            HomeScreen()
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x1A1A2E), Color(hex: 0x0A0A0A)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Image("app_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                        .shadow(color: Color(hex: 0x00BCD4).opacity(0.4), radius: 40)

                    VStack(spacing: 10) {
                        Text("Tranquil")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(2)

                        Text("Meditate, Sleep & Relax")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(.easeIn(duration: 0.8)) {
                    opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview { SplashScreen() }
