//
//  ContentView.swift
//  CircularTimer
//
//  Created by Afeez Yunus on 29/01/2025.
//

import SwiftUI
import RiveRuntime

struct ContentView: View {
    var riveTimer = Rivetimer()
    @State private var currentValue: Double = 0
    @State private var previousAngle: Double? = nil
    @State var isTimerRunning: Bool = false
    @State private var timer: Timer? = nil
    var body: some View {
        VStack {
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Text(String(Int(currentValue * 60)))
                    Text("MIN")
                    Text("SETUP TIME")
                        .font(.headline)
                        .fontDesign(.monospaced)
                }
                .font(.system(size: 64, weight: .medium, design: .monospaced))
                .padding(.bottom, 64)
                .onChange(of: currentValue) { oldValue, newValue in
                    // Convert to the 0-60 scale and check whole numbers
                    if Int(oldValue * 60) != Int(newValue * 60) {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                }
                Spacer()
            }
                VStack{
                    riveTimer.view()
                }
                .frame(height: 350)
                .onChange(of: isTimerRunning, { oldValue, newValue in
                    riveTimer.setInput("isPlaying?", value: isTimerRunning)
                })
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { gesture in
                            if !isTimerRunning {
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
                                    
                                    // Scale down the sensitivity of the gesture
                                    let newValue = currentValue + (angleDelta / 540) // Changed from 360 to 720 for less sensitivity
                                    currentValue = max(0, min(1, newValue))
                                    
                                    // Ensure the Rive input gets the full range
                                    let riveValue = min(60, currentValue * 60)
                                    riveTimer.setInput("duration", value: riveValue)
                                }
                                
                                previousAngle = degrees
                            }
                        }
                        .onEnded { _ in
                            previousAngle = nil
                        }
                )
                .onTapGesture {
                    if !isTimerRunning {
                        // Start the timer
                        isTimerRunning = true
                        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                            if currentValue > 0 {
                                currentValue -= (0.1 / 60) // Decrease by 0.1 seconds converted to minutes
                                riveTimer.setInput("duration", value: Double(currentValue * 60))
                            } else {
                                // Timer finished
                                isTimerRunning = false
                                currentValue = 0
                                riveTimer.setInput("duration", value: Double(0))
                                timer?.invalidate()
                                timer = nil
                            }
                        }
                    } else {
                        // Stop the timer
                        isTimerRunning = false
                        timer?.invalidate()
                        timer = nil
                    }
                }
           
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
    @Published var duration: Bool = true
    
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
            
            if let timerStage = eventProperties["isPlaying?"] as? Bool {
                duration = timerStage
            }
        }
    }
}
