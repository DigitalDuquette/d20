import simd
import Testing
@testable import TapD20

struct D20GeometryTests {
    let faces = D20Geometry.faces

    @Test func everyValueOnce() {
        #expect(faces.map(\.value).sorted() == Array(1...20))
    }

    @Test func oppositeFacesAddTo21() {
        for f in faces {
            let opposite = faces.min { simd_dot(f.normal, $0.normal) < simd_dot(f.normal, $1.normal) }!
            #expect(simd_dot(f.normal, opposite.normal) < -0.999)
            #expect(f.value + opposite.value == 21)
        }
    }

    @Test(arguments: 1...20)
    func showFaceTurnsTheNumberUprightToTheCamera(value: Int) {
        let f = faces.first { $0.value == value }!
        let q = D20Geometry.showFace(value)
        let toCamera = D20Geometry.tilt.act([0, 0, 1])
        let upright = D20Geometry.tilt.act([0, 1, 0])
        #expect(simd_distance(q.act(f.normal), toCamera) < 1e-4)
        #expect(simd_distance(q.act(f.up), upright) < 1e-4)
    }

    @Test(arguments: [1, 2])
    func bouncesLandOnTheHopCurve(dice: Int) {
        let b = D20Scene.bounces(dice: dice)
        #expect(b.count == dice * 2)
        #expect(b.map(\.time) == b.map(\.time).sorted())
        for (i, phase) in [0.0, Double(Float(0.12))].prefix(dice).enumerated() {
            let mine = b.filter { abs(sin(($0.time / 1.5 + phase * (1 - $0.time / 1.5)) * .pi * 3)) < 1e-9 }
            #expect(mine.count >= 2, "die \(i)")
        }
        #expect(b.allSatisfy { $0.time > 0 && $0.time < 1.5 && $0.strength > 0 && $0.strength < 1 })
    }
}
