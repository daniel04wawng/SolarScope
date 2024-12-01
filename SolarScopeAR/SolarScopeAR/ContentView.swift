import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    var body: some View {
        ARViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        // creates ARView
        let arView = ARView(frame: .zero)

        // loads the .usdz model
        if let modelEntity = try? ModelEntity.load(named: "bunny-3D-heatmap") {
            // scale the model down
            modelEntity.scale = SIMD3<Float>(0.0007, 0.0007, 0.0007) // 0.0008% of original size

            // positions the model right in front of the camera
            modelEntity.position = SIMD3<Float>(0, -0.1, -4.5) // 1.0 cm infront

            // creates anchor for the model
            let anchor = AnchorEntity(plane: .horizontal)
            anchor.addChild(modelEntity)

            // add the anchor to AR scene
            arView.scene.addAnchor(anchor)
        } else {
            print("Failed to load model")
        }

        // configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // update ARView if necessary
    }
}
