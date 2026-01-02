import Foundation
import CoreMotion

// MARK: - 1. Motion State Definition
/// 지하철의 4단계 운행 상태를 정의합니다.
enum SubwayMotionState {
    case stopped        // 정차 (완전 정지)
    case accelerating   // 출발 (가속)
    case cruising       // 운행 중 (등속/진동)
    case decelerating   // 도착 (감속)
    case unknown        // 초기 상태
}

// MARK: - 2. Motion Detector (Logic Layer)
/// 가속도 패턴을 분석하여 4단계 상태를 판단하는 로직입니다.
class SubwayMotionDetector {
    // 임계값 설정 (단위: g)
    // 지하철/경전철의 실제 가속도는 약 0.8~1.0 m/s² (0.08~0.1g) 수준입니다.
    // 손떨림이나 미세한 움직임을 거르기 위해 임계값을 상향 조정했습니다.
    private let stopThreshold = 0.02       // 0.02g 이하: 완전 정지 (센서 노이즈 고려)
    private let accelThreshold = 0.08      // 0.08g 이상: 유의미한 가속 (손떨림 필터링)
    private let walkingThreshold = 0.4     // 0.4g 이상: 걷기/취급 부주의 (무시)
    
    // 상태 유지를 위한 카운터 설정 (0.1초 단위)
    // 지하철의 가속/감속은 수 초간 지속되므로, 짧은 움직임은 무시합니다.
    private let requiredTicks = 15         // 1.5초 이상 지속되어야 상태 변경 인정
    
    private var stateCount = 0
    private var lastPotentialState: SubwayMotionState = .unknown
    
    // 현재 확정된 상태
    private(set) var currentState: SubwayMotionState = .unknown
    
    /// 가속도 데이터를 받아 다음 상태를 결정합니다.
    func process(acceleration: CMAcceleration) -> SubwayMotionState {
        // 1. 벡터 크기 계산
        let magnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
        let delta = abs(magnitude - 1.0) // 중력 제외한 순수 힘
        
        // 2. 순간 상태 판단
        var instantState: SubwayMotionState = .unknown
        
        if delta > walkingThreshold {
            // 걷거나 폰을 흔드는 등 과도한 움직임은 상태 변경을 보류하고 현 상태 유지
            return currentState
        } else if delta > accelThreshold {
            // 유의미한 힘이 작용 중 (가속 또는 감속)
            if currentState == .stopped || currentState == .unknown {
                instantState = .accelerating
            } else if currentState == .cruising || currentState == .accelerating {
                instantState = .decelerating
            } else {
                instantState = .accelerating
            }
        } else if delta > stopThreshold {
            // 약한 힘(진동)이 작용 중 -> 등속 주행
            // 0.02g ~ 0.08g 사이의 값은 주행 중 진동으로 간주
            instantState = .cruising
        } else {
            // 0.02g 이하 -> 정차
            instantState = .stopped
        }
        
        // 3. 상태 안정화 (Debouncing)
        if instantState == lastPotentialState {
            stateCount += 1
        } else {
            stateCount = 0
            lastPotentialState = instantState
        }
        
        if stateCount > requiredTicks {
            let previousState = currentState
            
            switch (currentState, instantState) {
            case (.stopped, .accelerating): currentState = .accelerating
            case (.accelerating, .cruising): currentState = .cruising
            case (.cruising, .decelerating): currentState = .decelerating
            case (.decelerating, .stopped): currentState = .stopped
            
            // 예외 처리: 부드러운 운행
            case (.cruising, .stopped): currentState = .stopped
            case (.accelerating, .stopped): currentState = .stopped
            case (.unknown, _): currentState = instantState
                
            default:
                // 감속하다가 다시 속도를 내는 경우 허용
                if currentState == .decelerating && instantState == .cruising {
                     currentState = .cruising
                }
                break
            }
            
            if previousState != currentState {
                stateCount = 0
            }
        }
        
        return currentState
    }
    
    func reset() {
        stateCount = 0
        currentState = .unknown
        lastPotentialState = .unknown
    }
}
