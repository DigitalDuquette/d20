import SwiftUI

// Roll screen from the Roll and Advantage wireframes. The flat die stands in
// until the 3D die (#8). History, settings, dice picker and Saved come later.
struct ContentView: View {
    @AppStorage("d20.mode") private var mode = RollMode.normal
    @AppStorage("d20.mod") private var modifier = 0
    @State private var result: RollResult?
    @State private var history: [RollResult] = []

    private var spec: RollSpec { RollSpec(modifier: modifier, mode: mode) }

    var body: some View {
        VStack(spacing: 20) {
            Text("d20")
                .font(.custom("FigtreeLight-SemiBold", size: 17))
                .padding(.top, 8)

            dice
            resultText
            controls
            historyList
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .foregroundStyle(Color(.foreground))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.background))
    }

    private var dice: some View {
        // Show the last roll if it matches the current mode, else blank faces.
        let shown = result.flatMap { $0.values.count == spec.diceToRoll ? $0 : nil }
        let values = shown?.values ?? Array(repeating: 20, count: spec.diceToRoll)
        return Button(action: roll) {
            HStack(spacing: 24) {
                ForEach(values.indices, id: \.self) { i in
                    D20Face(value: values[i])
                        .opacity(shown?.droppedIndex == i ? 0.35 : 1)
                }
            }
            .frame(height: 250)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode == .advantage ? "Roll with advantage" : mode == .disadvantage ? "Roll with disadvantage" : "Roll the d20")
    }

    private var resultText: some View {
        VStack(spacing: 8) {
            Text(result.map { "\($0.total)" } ?? "20")
                .font(.custom("Cinzel-ExtraBold", size: 104))
                .contentTransition(.numericText())
                .foregroundStyle(tint(result) ?? Color(.foreground))
            Text(label)
                .font(.custom("FigtreeLight-SemiBold", size: 13))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundStyle(tint(result) ?? Color(.muted))
        }
        .accessibilityElement(children: .combine)
    }

    private var label: String {
        guard let result else { return "Tap the die to roll" }
        let nat = result.isNatural20 ? "Natural 20" : result.isNatural1 ? "Natural 1" : ""
        let text = [nat, result.breakdown].filter { !$0.isEmpty }.joined(separator: " · ")
        return text.isEmpty ? "Tap to roll again" : text
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Picker("Roll mode", selection: $mode) {
                Text("Disadv").tag(RollMode.disadvantage)
                Text("Normal").tag(RollMode.normal)
                Text("Adv").tag(RollMode.advantage)
            }
            .pickerStyle(.segmented)

            HStack {
                Button { step(-1) } label: { Image(systemName: "minus") }
                Text(Dice.signed(modifier))
                    .font(.custom("FigtreeLight-SemiBold", size: 17))
                    .monospacedDigit()
                    .frame(minWidth: 40)
                Button { step(1) } label: { Image(systemName: "plus") }
            }
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(Color(.chip), in: RoundedRectangle(cornerRadius: 9))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Modifier")
            .accessibilityValue(Dice.signed(modifier))
            .accessibilityAdjustableAction { $0 == .increment ? step(1) : step(-1) }
        }
    }

    private var historyList: some View {
        VStack(spacing: 4) {
            ForEach(Array(history.enumerated()), id: \.offset) { i, r in
                Text("\(r.total)")
                    .font(i < 3 ? .custom("Cinzel-ExtraBold", size: [30, 23, 18][i]) : .custom("FigtreeLight-SemiBold", size: 13))
                    .foregroundStyle(tint(r) ?? (i < 2 ? Color(.foreground) : Color(.muted)))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Last rolls: " + history.map { "\($0.total)" }.joined(separator: ", "))
    }

    private func roll() {
        let r = Dice.roll(spec)
        withAnimation {
            result = r
            history.insert(r, at: 0)
            // shortcut: keeps the last 4 in memory, the history screen (#23) stores more.
            history = Array(history.prefix(4))
        }
    }

    private func step(_ by: Int) {
        modifier = min(20, max(-20, modifier + by))
    }

    private func tint(_ r: RollResult?) -> Color? {
        r?.isNatural20 == true ? Color(.crit) : r?.isNatural1 == true ? Color(.fumble) : nil
    }
}

/// Flat d20 seen face-on, as in the wireframes.
struct D20Face: View {
    let value: Int

    var body: some View {
        ZStack {
            D20Shape(part: .body).fill(Color(red: 0x2c / 255, green: 0x24 / 255, blue: 0x58 / 255))
            D20Shape(part: .face).fill(Color(red: 0x4d / 255, green: 0x40 / 255, blue: 0x8f / 255))
            D20Shape(part: .edges).stroke(Color(red: 0x7b / 255, green: 0x6c / 255, blue: 0xc9 / 255), lineWidth: 1.5)
            GeometryReader { g in
                Text("\(value)")
                    .font(.custom("Cinzel-ExtraBold", size: g.size.height * 0.15))
                    .foregroundStyle(value == 20 ? Color(red: 0xf2 / 255, green: 0xcf / 255, blue: 0x74 / 255) : Color(red: 0xf3 / 255, green: 0xee / 255, blue: 0xe0 / 255))
                    .position(x: g.size.width / 2, y: g.size.height * 0.53)
            }
        }
        .aspectRatio(0.866, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

struct D20Shape: Shape {
    enum Part { case body, face, edges }
    let part: Part

    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        let outer = [p(0.5, 0), p(1, 0.25), p(1, 0.75), p(0.5, 1), p(0, 0.75), p(0, 0.25)]
        let inner = [p(0.5, 0.242), p(0.802, 0.683), p(0.198, 0.683)]
        var path = Path()
        switch part {
        case .body:
            path.addLines(outer)
            path.closeSubpath()
        case .face:
            path.addLines(inner)
            path.closeSubpath()
        case .edges:
            path.addLines(outer)
            path.closeSubpath()
            path.addLines(inner)
            path.closeSubpath()
            // Outer corner to inner corner: top, upper sides, lower sides, bottom.
            for (o, i) in [(0, 0), (1, 0), (5, 0), (1, 1), (2, 1), (3, 1), (5, 2), (4, 2), (3, 2)] {
                path.move(to: outer[o])
                path.addLine(to: inner[i])
            }
        }
        return path
    }
}

#Preview {
    ContentView()
}
