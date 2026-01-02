import Foundation
import CoreMotion
import Combine // 요청하신 대로 추가했습니다!

class SensorManager: ObservableObject {
    
    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    
    // 데이터 저장용 변수들
    @Published var pressure: Double = 0.0
    @Published var accelerationX: Double = 0.0
    @Published var accelerationY: Double = 0.0
    @Published var accelerationZ: Double = 0.0
    
    // 상태 표시
    @Published var movementStatus: String = "판단 중..."
    
    // 로직을 위한 내부 변수들
    private var moveCount = 0      // 움직임이 감지된 횟수 누적
    private var stopCount = 0      // 정지가 감지된 횟수 누적
    private let threshold = 0.15   // 민감도 조절 (0.1 ~ 0.2 사이 추천. 높을수록 둔감해짐)
    private let requiredTicks = 10 // 몇 번 연속으로 감지되어야 상태를 바꿀지 (0.1초 x 10 = 1초)
    
    // 현재 상태를 내부적으로 기억하는 변수
    private var isMoving = false

    func startUpdates() {
        // 1. 기압 측정 (변화 없음)
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { (data, error) in
                guard let data = data else { return }
                DispatchQueue.main.async {
                    self.pressure = data.pressure.doubleValue * 10.0
                }
            }
        }
        
        // 2. 가속도 측정 (필터링 로직 추가됨)
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1 // 0.1초마다 실행
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                guard let data = data else { return }
                
                self.accelerationX = data.acceleration.x
                self.accelerationY = data.acceleration.y
                self.accelerationZ = data.acceleration.z
                
                // 벡터 크기 계산
                let magnitude = sqrt(pow(data.acceleration.x, 2) + 
                                     pow(data.acceleration.y, 2) + 
                                     pow(data.acceleration.z, 2))
                
                // 변화량 계산 (중력가속도 1.0 제거)
                let delta = abs(magnitude - 1.0)
                
                // 판단 로직: 카운터 방식
                if delta > self.threshold {
                    // 흔들림 감지됨!
                    self.moveCount += 1
                    self.stopCount = 0 // 정지 카운트 초기화
                } else {
                    // 조용함!
                    self.stopCount += 1
                    self.moveCount = 0 // 움직임 카운트 초기화
                }
                
                // 상태 결정 (1초 이상 지속될 때만 상태 변경)
                if self.moveCount > self.requiredTicks {
                    self.isMoving = true
                    self.movementStatus = "🚇 이동 중"
                } else if self.stopCount > self.requiredTicks {
                    self.isMoving = false
                    self.movementStatus = "🛑 정차 중"
                }
                
                // (참고) 아직 판단이 안 섰을 때는 기존 상태 유지
            }
        }
    }
    
    func stopUpdates() {
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.stopRelativeAltitudeUpdates()
        }
        if motionManager.isAccelerometerAvailable {
            motionManager.stopAccelerometerUpdates()
        }
        movementStatus = "측정 중지"
        moveCount = 0
        stopCount = 0
    }
}