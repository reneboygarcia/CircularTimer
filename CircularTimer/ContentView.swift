//
//  ContentView.swift
//  CircularTimer
//
//  Created by Afeez Yunus on 29/01/2025.
//

import SwiftUI
import RiveRuntime

struct ContentView: View {
    @StateObject var riveTimer = Rivetimer()
    @State private var currentValue: Double = 0
    @State private var previousAngle: Double? = nil
    var body: some View {
        VStack {
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Text(String(Int(currentValue * 60)))
                        .animation(.easeInOut(duration: 0.1))
                        .contentTransition(.numericText())
                    Text("MIN")
                    Text("SETUP TIME")
                        .font(.headline)
                }
                    .font(.system(size: 64, weight: .bold, design: .default))
                    .padding(.bottom, 64)
                Spacer()
            }
            VStack{
                riveTimer.view()
            }
            .frame(height: 350)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let center = CGPoint(x: 150, y: 150)
                        let vector = CGVector(
                            dx: gesture.location.x - center.x,
                            dy: gesture.location.y - center.y
                        )
                        
                        let angleInRadians = atan2(vector.dy, vector.dx)
                        var degrees = (angleInRadians * 180 / .pi + 90)
                        if degrees < 0 { degrees += 360 }
                        
                        // Handle direction and constraints
                        if let previousAngle = previousAngle {
                            var angleDelta = degrees - previousAngle
                            
                            // Handle crossing the 0/360 boundary
                            if angleDelta > 180 {
                                angleDelta -= 360
                            } else if angleDelta < -180 {
                                angleDelta += 360
                            }
                            
                            angleDelta = -angleDelta
                            
                            let newValue = currentValue + (angleDelta / 360)
                            currentValue = max(0, min(1, newValue))
                            
                            print(currentValue)
                        }
                        
                        previousAngle = degrees
                        riveTimer.setInput("duration", value: Double(currentValue * 60))
                        
                    }
                    .onEnded { _ in
                        previousAngle = nil
                    }
            )
        }
        .padding()
        
        .background(Color("bg"))
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}


class Rivetimer: RiveViewModel {
    @Published var duration: Int = 0
    
    init() {
        super.init(fileName: "timer", stateMachineName: "main")
    }
    
    func view() -> some View {
        super.view()
        
    }
    // Subscribe to Rive events
    @objc func onRiveEventReceived(onRiveEvent riveEvent: RiveEvent) {
        if let generalEvent = riveEvent as? RiveGeneralEvent {
            let eventProperties = generalEvent.properties()
            
            if let timerStage = eventProperties["timer"] as? Int {
                duration = timerStage
            }
        }
    }
}
