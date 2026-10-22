import Foundation

enum RollMode: String, CaseIterable, Sendable {
    case disadvantage, normal, advantage
}

struct RollSpec: Equatable, Sendable {
    var sides = 20
    var count = 1
    var modifier = 0
    var mode = RollMode.normal

    // Advantage and disadvantage only apply to one d20.
    var keepsOne: Bool { sides == 20 && count == 1 && mode != .normal }
    var diceToRoll: Int { keepsOne ? 2 : count }
}

struct RollResult: Equatable {
    let spec: RollSpec
    let values: [Int]
    let droppedIndex: Int?
    let total: Int
    // The kept d20 face, judged before the modifier. Nil unless the spec is one d20.
    let natural: Int?
    let breakdown: String

    var isNatural20: Bool { natural == 20 }
    var isNatural1: Bool { natural == 1 }
}

enum Dice {
    static func roll(_ spec: RollSpec) -> RollResult {
        var generator = SystemRandomNumberGenerator()
        return roll(spec, using: &generator)
    }

    static func roll<G: RandomNumberGenerator>(_ spec: RollSpec, using generator: inout G) -> RollResult {
        let values = (0..<spec.diceToRoll).map { _ in Int.random(in: 1...spec.sides, using: &generator) }
        return resolve(spec, values: values)
    }

    /// Builds the result from die values. Pure, so tests can pass fixed values.
    static func resolve(_ spec: RollSpec, values: [Int]) -> RollResult {
        precondition(values.count == spec.diceToRoll, "expected \(spec.diceToRoll) values")
        var dropped: Int?
        var sum = values.reduce(0, +)
        var detail = ""
        if spec.keepsOne {
            // A tie keeps the first die, as the web app does.
            let keepSecond = spec.mode == .advantage ? values[1] > values[0] : values[1] < values[0]
            let kept = keepSecond ? 1 : 0
            dropped = 1 - kept
            sum = values[kept]
            detail = "\(sum) (\(values[1 - kept]) dropped)"
        }
        if spec.modifier != 0 && spec.count == 1 {
            let sign = spec.modifier < 0 ? "\u{2212}" : "+"
            detail = "\(detail.isEmpty ? "\(sum)" : detail) \(sign) \(abs(spec.modifier))"
        }
        // shortcut: multi-dice breakdown ("29 on 8d6 + 3") is left empty until #17.
        return RollResult(
            spec: spec,
            values: values,
            droppedIndex: dropped,
            total: sum + spec.modifier,
            natural: spec.sides == 20 && spec.count == 1 ? sum : nil,
            breakdown: detail
        )
    }

    /// Modifier as shown on the stepper: "+3", "−2" with a real minus sign.
    static func signed(_ n: Int) -> String {
        (n < 0 ? "\u{2212}" : "+") + String(abs(n))
    }
}
