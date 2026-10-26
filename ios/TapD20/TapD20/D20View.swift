import SceneKit
import SwiftUI

/// The 3D d20 in SceneKit, ported from the web die in index.html.
/// One die for a normal roll, two for advantage and disadvantage.
@MainActor
final class D20Scene {
    let scene = SCNScene()
    private let root = SCNNode()

    init() {
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 32
        // Width sets the die size; extra height is room for the bounce.
        camera.camera?.projectionDirection = .horizontal
        camera.camera?.zNear = 0.1
        camera.camera?.zFar = 50
        camera.position = SCNVector3(0, 0, 6.2)
        scene.rootNode.addChildNode(camera)

        // Lights as on the web: soft fill, key from top left, tinted rim from bottom right.
        scene.rootNode.addChildNode(light(.ambient, 550, .white, at: nil))
        scene.rootNode.addChildNode(light(.directional, 950, .white, at: SCNVector3(-2.5, 3.5, 5)))
        scene.rootNode.addChildNode(light(.directional, 350, hex(0xc9c0ff), at: SCNVector3(3, -2, 2)))
        scene.lightingEnvironment.contents = Self.studioImage()
        scene.lightingEnvironment.intensity = 0.5

        let geometry = Self.geometry()
        let shadowImage = Self.shadowImage()
        for _ in 0..<2 {
            let holder = SCNNode()
            let body = SCNNode(geometry: geometry)
            body.name = "body"
            body.simdOrientation = D20Geometry.showFace(20)
            let plane = SCNPlane(width: 2.4, height: 0.7)
            plane.firstMaterial?.lightingModel = .constant
            plane.firstMaterial?.diffuse.contents = shadowImage
            plane.firstMaterial?.writesToDepthBuffer = false
            let shadow = SCNNode(geometry: plane)
            shadow.name = "shadow"
            shadow.position = SCNVector3(0, -1.45, -0.5)
            holder.addChildNode(shadow)
            holder.addChildNode(body)
            root.addChildNode(holder)
        }
        scene.rootNode.addChildNode(root)
        layout(count: 1)
    }

    private func body(_ i: Int) -> SCNNode { root.childNodes[i].childNode(withName: "body", recursively: false)! }

    // Changes go through actions: the SCNView only redraws while something animates.

    /// One die in the middle, or two side by side and smaller.
    func layout(count: Int) {
        for (i, holder) in root.childNodes.enumerated() {
            let x: Float = count == 2 ? (i == 0 ? -0.9 : 0.9) : 0
            holder.runAction(.group([
                .move(to: SCNVector3(x, 0, 0), duration: 0.2),
                .scale(to: count == 2 ? 0.74 : 1.3, duration: 0.2),
                .fadeOpacity(to: i < count ? 1 : 0, duration: 0.2),
            ]))
        }
        dim(nil)
    }

    /// Fades the dropped die of an advantage or disadvantage roll.
    /// SceneKit blends in linear color, so 0.1 here looks like 0.35 on the web.
    func dim(_ index: Int?) {
        for i in root.childNodes.indices { body(i).runAction(.fadeOpacity(to: i == index ? 0.1 : 1, duration: 0.2)) }
    }

    /// Gentle bob between rolls, as on the web. Each die starts at rest, so nothing jumps.
    func float(_ on: Bool) {
        for i in root.childNodes.indices {
            let b = body(i)
            b.removeAction(forKey: "float")
            b.simdPosition.y = 0
            guard on else { continue }
            let bob = SCNAction.customAction(duration: 2 * .pi / 1.6) { node, t in
                node.simdPosition.y = sin(Float(t) * 1.6) * 0.03
            }
            // The second die starts later, so the two move out of step.
            b.runAction(.sequence([.wait(duration: Double(i) * 1.3 / 1.6), .repeatForever(bob)]), forKey: "float")
        }
    }

    private nonisolated static let duration = 1.5, lag: Float = 0.12

    /// When each die touches down mid-roll, in seconds from the start, and how hard (0...1).
    /// Solves the hop curve in roll() for its zeros. The landing itself is not included.
    nonisolated static func bounces(dice: Int) -> [(time: Double, strength: Double)] {
        (0..<dice).flatMap { i in
            let phase = Double(Float(i) * lag)
            return [1.0 / 3, 2.0 / 3].map { (tp: Double) -> (time: Double, strength: Double) in
                let t = (tp - phase) / (1 - phase)
                return (t * duration, pow(1 - t, 1.6))
            }
        }
        .sorted { $0.time < $1.time }
    }

    /// Spins and bounces each die onto its value, about 1.5 s. Reduce Motion: a short fade.
    func roll(_ values: [Int], reduceMotion: Bool) async {
        // Set directly, not faded: a fade action would fight the Reduce Motion fade.
        for i in root.childNodes.indices { body(i).removeAllActions(); body(i).opacity = 1 }
        let spins = values.indices.map { i in
            Spin(
                from: body(i).simdOrientation,
                to: D20Geometry.showFace(values[i]),
                axis: simd_normalize(SIMD3<Float>.random(in: -0.5...0.5)),
                turns: Float(Int.random(in: 3...4)),
                phase: Float(i) * Self.lag
            )
        }
        let duration = reduceMotion ? 0.25 : Self.duration
        await root.runAction(.customAction(duration: duration) { root, elapsed in
            let t = Float(min(1, elapsed / duration))
            for (i, s) in spins.enumerated() {
                let holder = root.childNodes[i]
                let body = holder.childNode(withName: "body", recursively: false)!
                if reduceMotion {
                    body.simdOrientation = t < 0.5 ? s.from : s.to
                    body.opacity = CGFloat(abs(1 - 2 * t))
                    continue
                }
                let e = 1 - pow(1 - t, 3)
                body.simdOrientation = simd_quatf(angle: s.turns * 2 * .pi * (1 - e), axis: s.axis) * simd_slerp(s.from, s.to, e)
                // Decaying hops, the second die slightly out of step.
                let tp = min(1, t + s.phase * (1 - t))
                let hop = abs(sin(tp * .pi * 3)) * pow(1 - t, 1.6) * 0.9
                body.simdPosition.y = hop
                let shadow = holder.childNode(withName: "shadow", recursively: false)!
                shadow.simdScale = SIMD3(repeating: 1 - hop * 0.35)
                shadow.opacity = CGFloat(1 - hop * 0.6)
            }
        })
        for (i, s) in spins.enumerated() {
            body(i).simdOrientation = s.to
            body(i).simdPosition.y = 0
            body(i).opacity = 1
        }
        float(!reduceMotion)
    }

    private struct Spin: Sendable {
        let from, to: simd_quatf
        let axis: SIMD3<Float>
        let turns, phase: Float
    }

    private func light(_ type: SCNLight.LightType, _ intensity: CGFloat, _ color: UIColor, at position: SCNVector3?) -> SCNNode {
        let node = SCNNode()
        node.light = SCNLight()
        node.light?.type = type
        node.light?.intensity = intensity
        node.light?.color = color
        if let position {
            node.position = position
            node.look(at: SCNVector3Zero)
        }
        return node
    }

    // MARK: - Geometry and textures

    /// Flat-shaded icosahedron with one material per face.
    private static func geometry() -> SCNGeometry {
        let h = CGFloat(3.0.squareRoot() / 2)
        var vertices: [SCNVector3] = [], normals: [SCNVector3] = [], uvs: [CGPoint] = []
        var elements: [SCNGeometryElement] = [], materials: [SCNMaterial] = []
        for (i, f) in D20Geometry.faces.enumerated() {
            vertices += [f.a, f.b, f.c].map { SCNVector3($0) }
            normals += Array(repeating: SCNVector3(f.normal), count: 3)
            // Apex at the top of the texture, base along the bottom of the triangle.
            uvs += [CGPoint(x: 0.5, y: 0), CGPoint(x: 0, y: h), CGPoint(x: 1, y: h)]
            let n = Int32(i * 3)
            elements.append(SCNGeometryElement(indices: [n, n + 1, n + 2], primitiveType: .triangles))
            let m = SCNMaterial()
            m.lightingModel = .physicallyBased
            m.diffuse.contents = faceImage(f.value)
            m.diffuse.mipFilter = .linear
            m.roughness.contents = 0.32
            m.metalness.contents = 0.08
            materials.append(m)
        }
        let geometry = SCNGeometry(
            sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals), SCNGeometrySource(textureCoordinates: uvs)],
            elements: elements
        )
        geometry.materials = materials
        return geometry
    }

    /// Amethyst face: gradient, inner cut line, numeral in Cinzel, 20 in gold.
    private static func faceImage(_ n: Int) -> UIImage {
        let s: CGFloat = 512, k = s / 256, h = s * 3.0.squareRoot() / 2
        let cy = h * 2 / 3
        return UIGraphicsImageRenderer(size: CGSize(width: s, height: s)).image { r in
            let ctx = r.cgContext
            let gradient = CGGradient(colorsSpace: nil, colors: [hex(0x5a4ca6).cgColor, hex(0x2c2458).cgColor] as CFArray, locations: [0, 1])!
            ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: h), options: [.drawsAfterEndLocation])

            ctx.saveGState()
            ctx.translateBy(x: s / 2, y: cy)
            ctx.scaleBy(x: 0.86, y: 0.86)
            ctx.translateBy(x: -s / 2, y: -cy)
            ctx.addLines(between: [CGPoint(x: s / 2, y: 0), CGPoint(x: 0, y: h), CGPoint(x: s, y: h)])
            ctx.closePath()
            ctx.setStrokeColor(UIColor(red: 200 / 255, green: 190 / 255, blue: 1, alpha: 0.22).cgColor)
            ctx.setLineWidth(3 * k)
            ctx.strokePath()
            ctx.restoreGState()

            let ink = n == 20 ? hex(0xf2cf74) : hex(0xf3eee0)
            ctx.setShadow(offset: CGSize(width: 0, height: 2 * k), blur: 4 * k, color: UIColor(white: 0, alpha: 0.45).cgColor)
            let text = NSAttributedString(string: "\(n)", attributes: [
                .font: UIFont(name: "Cinzel-ExtraBold", size: (n >= 10 ? 76 : 86) * k) ?? .boldSystemFont(ofSize: 76 * k),
                .foregroundColor: ink,
            ])
            let size = text.size()
            text.draw(at: CGPoint(x: (s - size.width) / 2, y: cy + 6 * k - size.height / 2))
            // Bar under 6 and 9 so they can be told apart.
            if n == 6 || n == 9 {
                ink.setFill()
                ctx.fill(CGRect(x: s / 2 - 18 * k, y: cy + 44 * k, width: 36 * k, height: 6 * k))
            }
        }
    }

    private static func shadowImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128)).image { r in
            let gradient = CGGradient(colorsSpace: nil, colors: [UIColor(white: 0, alpha: 0.38).cgColor, UIColor(white: 0, alpha: 0).cgColor] as CFArray, locations: [0, 1])!
            let c = CGPoint(x: 64, y: 64)
            r.cgContext.drawRadialGradient(gradient, startCenter: c, startRadius: 0, endCenter: c, endRadius: 64, options: [])
        }
    }

    /// Soft studio reflections, the same image as the web environment map.
    private static func studioImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 512, height: 256)).image { r in
            let colors = [hex(0xffffff), hex(0x8a8f99), hex(0x1c1f22)].map(\.cgColor) as CFArray
            let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: [0, 0.45, 1])!
            r.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 256), options: [])
            UIColor(white: 1, alpha: 0.9).setFill()
            r.cgContext.fill([CGRect(x: 60, y: 40, width: 90, height: 50), CGRect(x: 300, y: 60, width: 140, height: 30)])
        }
    }
}

private func hex(_ v: Int) -> UIColor {
    UIColor(red: CGFloat(v >> 16 & 0xff) / 255, green: CGFloat(v >> 8 & 0xff) / 255, blue: CGFloat(v & 0xff) / 255, alpha: 1)
}

/// Shows a D20Scene with a clear background. Taps go to the SwiftUI view around it.
struct D20View: UIViewRepresentable {
    let die: D20Scene

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = die.scene
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {}
}
