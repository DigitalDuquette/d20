import simd

/// Icosahedron face maths, ported from the web die in index.html.
enum D20Geometry {
    struct Face: Sendable {
        /// Corners, counter-clockwise from outside. `a` is the top of the numeral.
        let a, b, c: SIMD3<Float>
        let normal: SIMD3<Float>
        /// From the centroid toward `a`.
        let up: SIMD3<Float>
        var value = 0
    }

    static let radius: Float = 1.15

    static let faces: [Face] = {
        let t = (1 + Float(5).squareRoot()) / 2
        let v: [SIMD3<Float>] = [
            [-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0],
            [0, -1, t], [0, 1, t], [0, -1, -t], [0, 1, -t],
            [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1],
        ].map { simd_normalize($0) * radius }
        let index = [
            0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11,
            1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
            3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9,
            4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1,
        ]
        var faces = stride(from: 0, to: index.count, by: 3).map { i -> Face in
            let a = v[index[i]]
            var b = v[index[i + 1]], c = v[index[i + 2]]
            let centroid = (a + b + c) / 3
            var normal = simd_normalize(simd_cross(b - a, c - a))
            if simd_dot(normal, centroid) < 0 {
                swap(&b, &c)
                normal = -normal
            }
            return Face(a: a, b: b, c: c, normal: normal, up: simd_normalize(a - centroid))
        }

        // Opposite faces add up to 21, like a real d20.
        var next = 1
        for i in faces.indices where faces[i].value == 0 {
            let opposite = faces.indices
                .filter { $0 != i && faces[$0].value == 0 }
                .min { simd_dot(faces[i].normal, faces[$0].normal) < simd_dot(faces[i].normal, faces[$1].normal) }!
            faces[i].value = next
            faces[opposite].value = 21 - next
            next += 1
        }
        return faces
    }()

    /// The slight tilt the web die rests at, so it reads as 3D.
    static let tilt = simd_quatf(angle: -0.2, axis: [1, 0, 0]) * simd_quatf(angle: 0.16, axis: [0, 1, 0])

    /// Orientation that turns the face showing `value` to the camera (+z), numeral upright (+y).
    static func showFace(_ value: Int) -> simd_quatf {
        let f = faces.first { $0.value == value }!
        let right = simd_normalize(simd_cross(f.up, f.normal))
        return tilt * simd_quatf(simd_float3x3(right, f.up, f.normal)).inverse
    }
}
