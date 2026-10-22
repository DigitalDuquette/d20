import SwiftUI

// Roll screen from the Roll and Advantage wireframes.
struct ContentView: View {
    @AppStorage("d20.mode") private var mode = RollMode.normal
    @AppStorage("d20.mod") private var modifier = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var die = D20Scene()
    @State private var rolling = false
    @State private var result: RollResult?
    @State private var history: [Entry] = []

    private struct Entry: Identifiable {
        let id = UUID()
        let result: RollResult
    }

    private var spec: RollSpec { RollSpec(modifier: modifier, mode: mode) }

    var body: some View {
        VStack(spacing: 20) {
            topBar
            dice
            resultText
            controls
            historyList
            Spacer(minLength: 0)
            bottomBar
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .foregroundStyle(Color(.foreground))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.background))
        .onAppear { die.layout(count: spec.diceToRoll) }
        .onChange(of: spec.diceToRoll) { die.layout(count: spec.diceToRoll) }
    }

    // shortcut: these four buttons have no action until #16, #20, #23 and #24.
    private var topBar: some View {
        HStack {
            circleButton("clock", "History")
            Spacer()
            Text("d20").font(.custom("FigtreeLight-SemiBold", size: 17))
            Spacer()
            circleButton("slider.horizontal.3", "Settings")
        }
        .padding(.top, 8)
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            barButton {
                Image(systemName: "hexagon")
                    .overlay(Image(systemName: "triangle").font(.system(size: 8, weight: .bold)))
                Text("d20")
                Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold))
            }
            .accessibilityLabel("Dice: d20")
            barButton {
                Image(systemName: "bookmark")
                Text("Saved")
            }
        }
    }

    private func circleButton(_ icon: String, _ label: String) -> some View {
        Button {} label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 44, height: 44)
                .background(Color(.chip), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func barButton(@ViewBuilder _ label: () -> some View) -> some View {
        Button {} label: {
            HStack(spacing: 10, content: label)
                .font(.custom("FigtreeLight-SemiBold", size: 17))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color(.chip), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var dice: some View {
        Button(action: roll) {
            D20View(die: die)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 280)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .layoutPriority(-1)
        .accessibilityLabel(mode == .advantage ? "Roll with advantage" : mode == .disadvantage ? "Roll with disadvantage" : "Roll the d20")
    }

    private var resultText: some View {
        VStack(spacing: 8) {
            Text(result.map { "\($0.total)" } ?? "20")
                .font(.custom("Cinzel-ExtraBold", size: 104))
                .contentTransition(.numericText())
                .foregroundStyle(tint(result) ?? Color(.foreground))
            Text(label)
                .font(.custom("FigtreeLight-SemiBold", size: 15))
                .foregroundStyle(tint(result) ?? Color(.muted))
        }
        .opacity(rolling ? 0.3 : 1)
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
            .disabled(rolling)

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
            ForEach(Array(history.enumerated()), id: \.element.id) { i, entry in
                let r = entry.result
                Text("\(r.total)")
                    .font(i < 3 ? .custom("Cinzel-ExtraBold", size: [30, 23, 18][i]) : .custom("FigtreeLight-SemiBold", size: 13))
                    .foregroundStyle(tint(r) ?? (i < 2 ? Color(.foreground) : Color(.muted)))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Last rolls: " + history.map { "\($0.result.total)" }.joined(separator: ", "))
    }

    private func roll() {
        guard !rolling else { return }
        rolling = true
        // The engine picks the values first; the die only shows them.
        let r = Dice.roll(spec)
        Task {
            await die.roll(r.values, reduceMotion: reduceMotion)
            die.dim(r.droppedIndex)
            withAnimation {
                rolling = false
                result = r
                history.insert(Entry(result: r), at: 0)
                // shortcut: keeps the last 4 in memory, the history screen (#23) stores more.
                history = Array(history.prefix(4))
            }
        }
    }

    private func step(_ by: Int) {
        modifier = min(20, max(-20, modifier + by))
    }

    private func tint(_ r: RollResult?) -> Color? {
        r?.isNatural20 == true ? Color(.crit) : r?.isNatural1 == true ? Color(.fumble) : nil
    }
}

#Preview {
    ContentView()
}
