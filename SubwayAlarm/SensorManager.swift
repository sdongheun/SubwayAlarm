import Foundation
import CoreMotion
import Combine
import UIKit

// NOTE: MotionDetector.swift와 SimulationManager.swift 파일이 프로젝트에 추가되어 있어야 합니다.

// MARK: - 3. Sensor Manager (ViewModel Layer)
class SensorManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter() // 기압계 추가
    private let motionDetector = SubwayMotionDetector()
    private let simulationManager = SimulationManager()
    
    @Published var accelerationX: Double = 0.0
    @Published var accelerationY: Double = 0.0
    @Published var accelerationZ: Double = 0.0
    @Published var totalMagnitude: Double = 0.0
    @Published var currentPressure: Double = 0.0 // 현재 기압
    
    @Published var movementStatus: String = "측정 대기"
    @Published var stationCount: Int = 0
    @Published var debugMessage: String = "준비 완료"
    
    // 녹화 관련
    @Published var isRecording: Bool = false
    @Published var exportFile: ExportFile? = nil // 공유를 위한 파일 래퍼
    private var recordedData: [SensorData] = []
    
    struct SensorData: Codable {
        let timestamp: String
        let pressure: Double
        let x: Double
        let y: Double
        let z: Double
        let status: String
    }
    
    struct ExportFile: Identifiable {
        let id = UUID()
        let url: URL
    }
    
    private var isUpdating = false

    // MARK: - Public Methods
    func startUpdates() {
        guard !isUpdating else { return }
        isUpdating = true
        movementStatus = "준비 중..."
        debugMessage = "센서 안정화 중..."
        startAccelerometer()
        startAltimeter() // 기압계 시작
    }
    
    func stopUpdates() {
        isUpdating = false
        motionManager.stopAccelerometerUpdates()
        stopAltimeter() // 기압계 중지
        simulationManager.stop()
        movementStatus = "측정 중지"
        debugMessage = "측정이 종료되었습니다."
        motionDetector.reset()
        
        if isRecording {
            stopRecording()
        }
    }

    // 수동으로 특정 이벤트를 기록하는 함수
func addMarker(label: String) {
    guard isRecording else { return }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    let timestamp = formatter.string(from: Date())
    
    // status에 내가 적은 라벨(예: "MARKER_DOOR_OPEN")을 넣어서 저장
    let data = SensorData(
        timestamp: timestamp,
        pressure: self.currentPressure,
        x: 0, // 마커니까 0으로 처리해도 무방
        y: 0,
        z: 0,
        status: "🚩MARKER: \(label)" 
    )
    recordedData.append(data)
    debugMessage = "마커 저장됨: \(label)"
}
    
    // 녹화 제어
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        recordedData.removeAll()
        debugMessage = "🔴 데이터 녹화 시작"
        // 센서가 꺼져있다면 켭니다.
        if !isUpdating {
            startUpdates()
        }
    }
    
    private func stopRecording() {
        isRecording = false
        debugMessage = "💾 데이터 파일 생성 중..."
        saveDataToFile()
    }
    
    private func saveDataToFile() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(recordedData)
            
            // 임시 파일 경로 생성 (타임스탬프 포함)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let fileName = "SubwayData_\(dateFormatter.string(from: Date())).json"
            
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            // 파일 쓰기
            try jsonData.write(to: fileURL)
            
            // UI 업데이트 (공유 시트 표시 트리거)
            DispatchQueue.main.async {
                self.exportFile = ExportFile(url: fileURL)
                self.debugMessage = "✅ 파일 준비 완료"
            }
        } catch {
            debugMessage = "❌ 파일 저장 실패: \(error.localizedDescription)"
        }
    }
    
    func runSimulation() {
        guard !isUpdating else { return }
        isUpdating = true
        movementStatus = "시뮬레이션 시작"
        debugMessage = "더미 데이터를 로드합니다..."
        
        motionManager.stopAccelerometerUpdates()
        stopAltimeter()
        
        simulationManager.start(completion: { [weak self] data in
            self?.processAccelerationData(data)
        }, onFinish: { [weak self] in
            self?.stopUpdates()
        })
    }
    
    // MARK: - Private Methods
    private func startAccelerometer() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            self.processAccelerationData(data.acceleration)
        }
    }
    
    private func startAltimeter() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            self.currentPressure = data.pressure.doubleValue * 10.0 // hPa 단위
        }
    }
    
    private func stopAltimeter() {
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.stopRelativeAltitudeUpdates()
        }
    }
    
    /// 실제 센서 데이터와 시뮬레이션 데이터 모두 이곳에서 처리됩니다.
    private func processAccelerationData(_ acceleration: CMAcceleration) {
        self.accelerationX = acceleration.x
        self.accelerationY = acceleration.y
        self.accelerationZ = acceleration.z
        
        // 벡터 크기 계산 (디버깅용)
        let magnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
        self.totalMagnitude = abs(magnitude - 1.0)
        
        // 로직 처리
        let newState = self.motionDetector.process(acceleration: acceleration)
        self.updateUI(with: newState)
        
        // 녹화 중이면 데이터 저장
        if isRecording {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            let timestamp = formatter.string(from: Date())
            
            let data = SensorData(
                timestamp: timestamp,
                pressure: self.currentPressure,
                x: acceleration.x,
                y: acceleration.y,
                z: acceleration.z,
                status: self.movementStatus
            )
            recordedData.append(data)
        }
    }
    
    private func updateUI(with state: SubwayMotionState) {
        switch state {
        case .stopped:
            if movementStatus != "🛑 정차" {
                if movementStatus.contains("도착") || movementStatus.contains("운행") {
                    stationCount += 1
                }
                movementStatus = "🛑 정차"
                debugMessage = "역에 정차했습니다."
            }
        case .accelerating:
            movementStatus = "🚀 출발 (가속)"
            debugMessage = "다음 역을 향해 출발합니다."
        case .cruising:
            movementStatus = "🚃 운행 중 (등속)"
            debugMessage = "일정한 속도로 이동 중입니다."
        case .decelerating:
            movementStatus = "⚠️ 도착 (감속)"
            debugMessage = "곧 역에 도착합니다."
        case .unknown:
            movementStatus = "판단 중..."
            debugMessage = "데이터 분석 중..."
        }
    }
}
