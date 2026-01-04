import SwiftUI

struct ContentView: View {
    @StateObject var sensorManager = SensorManager()
    
    var body: some View {
        VStack(spacing: 30) {
            
            // 상태 표시 (가장 중요한 부분!)
            VStack(spacing: 10) {
                Text("현재 상태")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(sensorManager.movementStatus)
                    .font(.system(size: 45, weight: .black))
                    // 상태별 색상 변경
                    .foregroundColor(statusColor)
                
                Text(sensorManager.debugMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // 정거장 카운터
            VStack {
                Text("\(sensorManager.stationCount)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                Text("STATIONS")
                    .font(.caption)
                    .tracking(5)
                    .foregroundColor(.gray)
            }
            
            Divider()
            
            // 데이터 모니터링
            HStack {
                VStack(alignment: .leading) {
                    Text("순수 가속도 (g)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.3f", sensorManager.totalMagnitude))
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
            
            Button("문 열림") { sensorManager.addMarker(label: "DOOR_OPEN") }
            Button("출발") { sensorManager.addMarker(label: "DEPART") }
            Button("정차") { sensorManager.addMarker(label: "STOP") }
            // 제어 버튼
            HStack(spacing: 15) {
                // 녹화 버튼 (START 왼쪽)
                Button(action: {
                    sensorManager.toggleRecording()
                }) {
                    Image(systemName: sensorManager.isRecording ? "stop.circle.fill" : "record.circle")
                        .font(.system(size: 24))
                        .frame(width: 60, height: 60)
                        .background(sensorManager.isRecording ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(radius: 5)
                }
                
                // 시작/정지 버튼
                Button(action: {
                    if sensorManager.movementStatus == "측정 대기" || sensorManager.movementStatus == "측정 중지" {
                        sensorManager.startUpdates()
                    } else {
                        sensorManager.stopUpdates()
                    }
                }) {
                    Text(sensorManager.movementStatus == "측정 대기" || sensorManager.movementStatus == "측정 중지" ? "START" : "STOP")
                        .font(.headline)
                        .frame(width: 120, height: 60)
                        .background(sensorManager.movementStatus == "측정 대기" || sensorManager.movementStatus == "측정 중지" ? Color.green : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(radius: 5)
                }
                
                // 시뮬레이션 버튼
                Button(action: {
                    sensorManager.runSimulation()
                }) {
                    Text("TEST")
                        .font(.headline)
                        .frame(width: 70, height: 60)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(radius: 5)
                }
            }
        }
        .padding()
        // 파일 공유 시트
        .sheet(item: $sensorManager.exportFile) { exportFile in
            ActivityViewController(activityItems: [exportFile.url])
        }
    }
    
    // 상태에 따른 색상 계산
    var statusColor: Color {
        if sensorManager.movementStatus.contains("출발") { return .blue }
        if sensorManager.movementStatus.contains("운행") { return .green }
        if sensorManager.movementStatus.contains("도착") { return .orange }
        if sensorManager.movementStatus.contains("정차") { return .red }
        return .gray
    }
}

// 파일 공유를 위한 UIViewControllerRepresentable
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}