import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    @State private var latestData: String = "Fetching data..."
    @State private var energyOutput: Double = 0.0
    @State private var costSavings: Double = 0.0
    @State private var buildingName: String = "Unknown"
    
    var body: some View {
           VStack {
               Text("Building Energy Analysis")
                   .font(.largeTitle)
                   .padding()

               ARViewContainer(energyOutput: $energyOutput, costSavings: $costSavings, buildingName: $buildingName)
                   .edgesIgnoringSafeArea(.all)
                   .frame(height: 500)

               Text(latestData)
                   .font(.body)
                   .multilineTextAlignment(.center)
                   .padding()

               Spacer()
           }
           .onAppear(perform: startFetchingData)
       }
    func startFetchingData() {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                fetchData()
            }
        }
        
    func fetchData() {
        guard let url = URL(string: "https://1d66-129-100-255-27.ngrok-free.app/output.txt") else {
            latestData = "Invalid URL"
            return
        }
        
        // Create a URLRequest to include the header
        var request = URLRequest(url: url)
        request.addValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    latestData = "Error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data, let text = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    latestData = "No data or invalid encoding received"
                }
                return
            }
            
            // Update the latestData variable with the plain text content
            DispatchQueue.main.async {
                latestData = text
            }
        }
        task.resume()
    }

    }

struct ARViewContainer: UIViewRepresentable {
    @Binding var energyOutput: Double
    @Binding var costSavings: Double
    @Binding var buildingName: String
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Example model name (adjust as needed)
        if let modelEntity = try? ModelEntity.load(named: "bunny-3D-heatmap") {
            modelEntity.scale = SIMD3<Float>(0.0007, 0.0007, 0.0007)
            modelEntity.position = SIMD3<Float>(0, -0.1, -4.5)
            
            let anchor = AnchorEntity(plane: .horizontal)
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
        } else {
            print("Failed to load model")
        }
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
            // update ARView if necessary
        }
}
