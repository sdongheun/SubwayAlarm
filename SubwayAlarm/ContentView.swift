import SwiftUI

struct ContentView: View {
    @StateObject var sensorManager = SensorManager()
    
    var body: some View {
        VStack(spacing: 30) {
            
            // 상태 표시 (가장 중요한 부분!)
            VStack {
                Text(sensorManager.movementStatus)
                    .font(.system(size: 50, weight: .black))
                    // 이동 중이면 파란색, 정차 중이면 빨간색
                    .foregroundColor(sensorManager.movementStatus.contains("이동") ? .blue : .red)
            }
            .padding()
            
            Divider()
            
            // 데이터 모니터링
            HStack {
                VStack(alignment: .leading) {
                    Text("기압 (hPa)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f", sensorManager.pressure))
                        .font(.title2)
                        .bold()
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("가속도 X")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f", sensorManager.accelerationX))
                        .font(.title2)
                        .bold()
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // 제어 버튼
            Button(action: {
                // 버튼 하나로 시작/정지 토글
                if sensorManager.movementStatus == "측정 중지" {
                    sensorManager.startUpdates()
                } else {
                    sensorManager.stopUpdates()
                }
            }) {
                Text(sensorManager.movementStatus == "측정 중지" ? "START" : "STOP")
                    .font(.headline)
                    .frame(width: 200, height: 60)
                    .background(sensorManager.movementStatus == "측정 중지" ? Color.green : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(30)
                    .shadow(radius: 5)
            }
        }
        .padding()
    }
}