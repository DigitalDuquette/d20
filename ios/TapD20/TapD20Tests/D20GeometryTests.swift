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
}
