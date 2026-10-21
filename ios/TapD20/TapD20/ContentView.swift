import SwiftUI

// Placeholder roll screen. The dice engine, 3D die and layout come in #7 to #10.
struct ContentView: View {
    @State private var roll = 20

    var body: some View {
        VStack(spacing: 16) {
            Text("\(roll)")
                .font(.custom("Cinzel-ExtraBold", size: 160))
                .contentTransition(.numericText())
            Text("Tap to roll")
                .font(.custom("FigtreeLight-Regular", size: 17))
                .foregroundStyle(Color(.muted))
        }
        .foregroundStyle(Color(.foreground))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.background))
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
