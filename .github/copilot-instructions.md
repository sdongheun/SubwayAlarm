# SubwayAlarm 프로젝트 가이드 (AI Agent용)

이 문서는 SubwayAlarm 프로젝트의 아키텍처, 핵심 로직, 코딩 컨벤션을 정의합니다. AI 에이전트는 이 가이드를 준수하여 코드를 작성해야 합니다.

## 🏗 아키텍처 및 디자인 패턴 (Architecture)

- **프레임워크**: SwiftUI (iOS)
- **패턴**: MVVM 스타일 (View - ObservableObject)
  - **View**: `ContentView.swift`는 오직 UI 렌더링과 사용자 입력만 처리합니다.
  - **Logic**: `SensorManager.swift`가 모든 비즈니스 로직과 센서 데이터를 관리합니다.
- **데이터 흐름**:
  - `SensorManager`는 `ObservableObject`를 채택하며, `@Published` 프로퍼티로 상태를 방출합니다.
  - View는 `@StateObject`를 통해 이를 구독하고 UI를 업데이트합니다.

## 🧩 핵심 컴포넌트 및 로직 (Core Logic)

### SensorManager (`SensorManager.swift`)

- **역할**: 가속도(Accelerometer) 및 기압(Altimeter) 센서 제어.
- **이동/정차 판단 알고리즘**:
  1. **벡터 크기 계산**: X, Y, Z 가속도의 벡터 합(`sqrt(x^2 + y^2 + z^2)`)을 구합니다.
  2. **중력 보정**: 벡터 크기에서 중력가속도(1.0)를 뺀 절대값(`delta`)을 사용합니다.
  3. **노이즈 필터링 (Counter System)**:
     - `delta`가 임계값(`threshold`, 기본 0.15)을 넘으면 `moveCount` 증가.
     - 넘지 않으면 `stopCount` 증가.
     - 특정 횟수(`requiredTicks`, 기본 10회/1초) 이상 연속될 때만 상태(`movementStatus`)를 변경합니다.
- **주의사항**: 센서 업데이트 주기는 배터리 효율과 반응 속도 균형을 위해 `0.1초`로 설정되어 있습니다.

## 📝 코딩 컨벤션 (Conventions)

- **언어**: Swift 5+
- **주석 (Comments)**:
  - **반드시 한국어로 작성합니다.**
  - 단순한 코드 번역이 아닌, **"왜(Why)"** 이렇게 구현했는지 로직의 의도를 설명합니다.
- **UI/Logic 분리**:
  - `View` 내부에서 `CoreMotion`을 직접 import하거나 사용하지 마십시오.
  - 모든 센서 데이터는 `SensorManager`를 통해서만 접근합니다.

## 🚀 개발 및 디버깅 워크플로우 (Workflow)

- **하드웨어 의존성**: `CoreMotion`은 시뮬레이터에서 완벽하게 동작하지 않을 수 있습니다. 가능한 실기기 테스트를 권장합니다.
- **디버깅**: `ContentView`에 구현된 대시보드를 통해 실시간 `acceleration` 및 `pressure` 값을 모니터링하며 임계값(`threshold`)을 튜닝합니다.

## ⚠️ 주요 주의사항 (Critical)

1. **배터리 최적화**: 감지가 필요 없을 때는 반드시 `stopUpdates()`를 호출하여 센서를 꺼야 합니다.
2. **상태 떨림 방지**: 센서 값은 매우 민감하므로, 즉각적인 상태 변경보다는 카운터 기반의 지연 확정 방식을 유지해야 합니다.

## 🤖 채팅 에이전트 지시사항 (Persona)

- **목표**: 지하철 승차알림 앱 개발 (위치/API 의존성 없이 기압/가속도 기반).
- **핵심 가치**: 역에서 역으로 이동했음을 정확히 인지하여 사용자에게 더 나은 결과 제공.
- **역할**:
  - Swift/iOS 최적화 코드 제공하되 주니어 개발자 눈높이에 맞는 코드 작성.
  - 객체지향적으로 코드 작성.
  - 주니어 개발자 눈높이에 맞춘 친절하고 상세한 설명.
  - 모르는 개념은 비유를 들어 설명.
