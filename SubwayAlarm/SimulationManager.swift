import Foundation
import CoreMotion

// MARK: - Simulation Logic
/// 테스트를 위한 더미 데이터 시뮬레이터입니다.
class SimulationManager {
    struct SimulationSegment: Codable {
        let phase: String
        let x: Double
        let y: Double
        let z: Double
        let duration: Double
    }
    
    private var timer: Timer?
    
    /// 시뮬레이션을 시작하고 콜백으로 가속도 데이터를 전달합니다.
    func start(completion: @escaping (CMAcceleration) -> Void, onFinish: @escaping () -> Void) {
        guard let url = Bundle.main.url(forResource: "simulation_data", withExtension: "json") else {
            print("JSON 파일을 찾을 수 없어 기본 데이터를 사용합니다.")
            runFallbackSimulation(completion: completion, onFinish: onFinish)
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let segments = try JSONDecoder().decode([SimulationSegment].self, from: data)
            executeSimulationSegments(segments, completion: completion, onFinish: onFinish)
        } catch {
            print("데이터 로드 실패: \(error)")
            onFinish()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func runFallbackSimulation(completion: @escaping (CMAcceleration) -> Void, onFinish: @escaping () -> Void) {
        let segments = [
            SimulationSegment(phase: "Stopped", x: 0, y: 0, z: -1.0, duration: 2.0),
            SimulationSegment(phase: "Accel", x: 0.4, y: 0.1, z: -1.0, duration: 3.0),
            SimulationSegment(phase: "Cruise", x: 0.2, y: 0.1, z: -1.0, duration: 5.0),
            SimulationSegment(phase: "Decel", x: 0.45, y: 0.05, z: -1.0, duration: 3.0),
            SimulationSegment(phase: "Stopped", x: 0, y: 0, z: -1.0, duration: 2.0)
        ]
        executeSimulationSegments(segments, completion: completion, onFinish: onFinish)
    }
    
    private func executeSimulationSegments(_ segments: [SimulationSegment], completion: @escaping (CMAcceleration) -> Void, onFinish: @escaping () -> Void) {
        var totalTicks: [CMAcceleration] = []
        
        for segment in segments {
            let ticks = Int(segment.duration * 10)
            for _ in 0..<ticks {
                let noiseX = Double.random(in: -0.01...0.01)
                let noiseY = Double.random(in: -0.01...0.01)
                totalTicks.append(CMAcceleration(
                    x: segment.x + noiseX,
                    y: segment.y + noiseY,
                    z: segment.z
                ))
            }
        }
        
        var currentIndex = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            
            if currentIndex >= totalTicks.count {
                timer.invalidate()
                onFinish()
                return
            }
            
            completion(totalTicks[currentIndex])
            currentIndex += 1
        }
    }
}
