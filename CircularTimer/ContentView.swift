//
//  ContentView.swift
//  CircularTimer
//
//  Created by Afeez Yunus on 29/01/2025.
//

import SwiftUI
import RiveRuntime

struct ContentView: View {
    var riveTimer = RiveViewModel(fileName: "timer", stateMachineName: "main")
    @State private var currentValue: Double = 0
    @State private var previousAngle: Double? = nil
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            HStack{
                Spacer()
                Text("Hello, world!")
                Spacer()
            }
            Spacer()
            riveTimer.view()
                .frame( height: 320)
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

