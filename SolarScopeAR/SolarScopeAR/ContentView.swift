import SwiftUI
import RealityKit
import ARKit
import Charts

// Energy data model
struct EnergyData: Identifiable {
    let id = UUID()
    let time: String
    let energyOutput: Double
    let costSavings: Double
}

// ContentView
struct ContentView: View {
    @State private var energyOutput: Double = 0.0
    @State private var costSavings: Double = 0.0
    @State private var timestamp: String = "00:00:00"
    @State private var showGraph: Bool = false
    @State private var energyData: [EnergyData] = [] // Stores the last 5 data points
    @State private var graphOffset: CGSize = .zero
    @State private var graphScale: CGFloat = 1.0
    @State private var animateText = false

    var body: some View {
        ZStack {
            // ARView for AR content
            ARViewContainer(energyOutput: $energyOutput, costSavings: $costSavings, buildingName: .constant("bunny"))
                .edgesIgnoringSafeArea(.all)

            // Overlay UI
            VStack {
                // Top overlay
                HStack {
                    Text("\(energyOutput, specifier: "%.2f") kWh")
                        .font(.headline)
                        .padding()
                        .background(Color(red: 0.62, green: 0.83, blue: 0.64).opacity(0.8))
                        .cornerRadius(20)
                        .padding(.leading)

                    Spacer()

                    Text("\(timestamp)")
                        .font(.headline)
                        .padding()
                        .background(Color(red: 0.62, green: 0.83, blue: 0.64).opacity(0.8))
                        .cornerRadius(20)
                        .padding(.trailing)
                }
                .padding(.top)

                Spacer()
                
                Text("$\(costSavings, specifier: "%.2f")")
                    .font(.system(size: 50, weight: .bold)) // Larger text with bold weight
                    .foregroundColor(Color(red: 0.62, green: 0.83, blue: 0.64)) // Pastel green color
                    .opacity(animateText ? 1 : 0) // Fade animation
                    .scaleEffect(animateText ? 1 : 0.5) // Scale animation
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                            animateText.toggle()
                        }
                    }

                // Icon row
                HStack(spacing: 40) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.62, green: 0.83, blue: 0.64).opacity(0.8))
                            .frame(width: 70, height: 70)
                        Image("user (1)")
                            .resizable()
                            .frame(width: 50, height: 50)
                    }
                    .onTapGesture {
                        withAnimation {
                            showGraph.toggle()
                        }
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.62, green: 0.83, blue: 0.64).opacity(0.8))
                            .frame(width: 70, height: 70)
                        Image("cam (1)")
                            .resizable()
                            .frame(width: 50, height: 50)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.62, green: 0.83, blue: 0.64).opacity(0.8))
                            .frame(width: 70, height: 70)
                        Image("ruler (1)")
                            .resizable()
                            .frame(width: 50, height: 50)
                    }
                }
                .padding(.bottom)
            }

            // Resizable and draggable graph
            if showGraph {
                ResizableDraggableGraph(data: energyData, graphOffset: $graphOffset, graphScale: $graphScale)
            }
        }
        .onAppear(perform: startFetchingData)
    }

    func startFetchingData() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            fetchData()
        }
    }

    func fetchData() {
        guard let url = URL(string: "https://8291-129-100-255-27.ngrok-free.app/output.txt") else {
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    parseCSVLineAndUpdateGraph(text: text)
                }
            } else if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
            }
        }
        task.resume()
    }

    func parseCSVLineAndUpdateGraph(text: String) {
        let components = text.split(separator: ",")
        if components.count == 3 {
            let time = String(components[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            if let energy = Double(components[1].trimmingCharacters(in: .whitespacesAndNewlines)),
               let cost = Double(components[2].trimmingCharacters(in: .whitespacesAndNewlines)),
               energy > 50000 { // Apply threshold for energy
                timestamp = time
                energyOutput = energy
                costSavings = cost // Update cost savings dynamically

                // Add new data point
                energyData.append(EnergyData(time: time, energyOutput: energy, costSavings: cost))

                // Keep only the last 5 data points
                if energyData.count > 5 {
                    energyData.removeFirst()
                }
            }
        }
    }
}

// Graph with gestures
struct ResizableDraggableGraph: View {
    let data: [EnergyData]
    @Binding var graphOffset: CGSize
    @Binding var graphScale: CGFloat

    var body: some View {
        Chart(data) {
            LineMark(
                x: .value("Time", $0.time),
                y: .value("Energy Output", $0.energyOutput)
            )
            .symbol(Circle()) // Optional: Add points on the line
            .foregroundStyle(Color(red: 0.62, green: 0.83, blue: 0.64)) // Pastel green
            .lineStyle(StrokeStyle(lineWidth: 4)) // Line thickness
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .foregroundColor(.black)
                            .font(.caption)
                    }
                }
                AxisTick()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue))")
                            .foregroundColor(.black)
                            .font(.caption)
                    }
                }
                AxisTick()
            }
        }
        .chartYScale(domain: 50000...((data.map { $0.energyOutput }.max() ?? 50000) + 10000)) // Start at 50k, extend dynamically
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .offset(graphOffset)
        .scaleEffect(graphScale)
        .gesture(
            DragGesture()
                .onChanged { value in
                    graphOffset = value.translation
                }
        )
        .gesture(
            MagnificationGesture()
                .onChanged { scale in
                    graphScale = scale
                }
        )
    }
}

// AR Container
struct ARViewContainer: UIViewRepresentable {
    @Binding var energyOutput: Double
    @Binding var costSavings: Double
    @Binding var buildingName: String

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

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

    func updateUIView(_ uiView: ARView, context: Context) {}
}
