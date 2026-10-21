import SwiftUI

// Placeholder roll screen. The dice engine, 3D die and layout come in #7 to #10.
struct ContentView: View {
    @State private var roll = 20

    var body: some View {
        VStack(spacing: 16) {
            Text("\(roll)")
                .font(.system(size: 160, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            Text("Tap to roll")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation { roll = Int.random(in: 1...20) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rolled \(roll)")
        .accessibilityHint("Double tap to roll a d20")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ContentView()
}
