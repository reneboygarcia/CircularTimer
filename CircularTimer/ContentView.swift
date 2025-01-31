//
//  ContentView.swift
//  CircularTimer
//
//  Created by Afeez Yunus on 29/01/2025.
//  Remix by eby
//

import RiveRuntime
import SwiftUI
import AVFoundation

struct ContentView: View {
  var riveTimer = Rivetimer()
  @State private var totalSeconds: Double = 0
  @State private var previousAngle: Double? = nil
  @State private var isTimerRunning: Bool = false
  @State private var timer: Timer? = nil
  @State private var lastUpdateTime: Date = Date()
  @State private var isAdjusting: Bool = false
  @State private var accumulatedDelta: Double = 0

  // Constants for timer configuration
  private let maxMinutes: Double = 60
  private let dialSensitivity: Double = 0.4  // Decrease this value for more sensitive rotation
  private let updateThreshold: TimeInterval = 0.03  // Decrease this value for smoother performance
  private let snapThreshold: Double = 0.1  // Increase this value for more responsive snapping
  private let minuteThreshold: Double = 0.8  // Decrease this value for more precise minute tracking

  init() {
    // Initialize audio player with the timer completion sound
    // Removed audio player initialization
  }

  private var timeString: String {
    let minutes = Int(totalSeconds) / 60
    let seconds = Int(totalSeconds) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  // Computed property to get current minutes
  private var currentMinutes: Int {
    Int(totalSeconds) / 60
  }

  var body: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        VStack {
          Text(timeString)
            .monospacedDigit()
          Text("REVERSE TIME TIMER")
            .font(.headline)
            .fontDesign(.monospaced)
          Text("Remix by eby")
            .font(.caption)
            .fontDesign(.monospaced)
          HStack(spacing: 4) {
            Image(systemName: "arrow.counterclockwise.circle.fill")
            Text("Rotate to set time")
          }
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.top, 8)
        }
        .font(.system(size: 64, weight: .medium, design: .monospaced))
        .padding(.bottom, 64)
        .onChange(of: totalSeconds) { oldValue, newValue in
          let oldMinutes = Int(oldValue) / 60
          let newMinutes = Int(newValue) / 60
          if oldMinutes != newMinutes {
            provideTactileFeedback()
          }
        }
        Spacer()
      }

      VStack {
        riveTimer.view()
      }
      .frame(height: 350)
      .onChange(of: isTimerRunning) { _, _ in
        riveTimer.setInput("isPlaying?", value: isTimerRunning)
      }
      .gesture(createTimerGesture())
      .onTapGesture(perform: handleTimerTap)
    }
    .padding()
    .background(Color("bg"))
    .preferredColorScheme(.light)
  }

  private func provideTactileFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
  }

  private func createTimerGesture() -> some Gesture {
    DragGesture(minimumDistance: 1)
      .onChanged { gesture in
        handleDragGesture(gesture)
      }
      .onEnded { _ in
        previousAngle = nil
        isAdjusting = false
        accumulatedDelta = 0
      }
  }

  private func handleDragGesture(_ gesture: DragGesture.Value) {
    guard !isTimerRunning else { return }

    let now = Date()
    guard now.timeIntervalSince(lastUpdateTime) >= updateThreshold else { return }

    let center = CGPoint(x: 150, y: 150)
    let vector = CGVector(
      dx: gesture.location.x - center.x,
      dy: gesture.location.y - center.y
    )

    let angleInRadians = atan2(vector.dy, vector.dx)
    var degrees = (angleInRadians * 180 / .pi + 90)
    if degrees < 0 { degrees += 360 }

    if let previousAngle = previousAngle {
      var angleDelta = degrees - previousAngle

      // Handle crossing the 0/360 boundary
      if angleDelta > 180 {
        angleDelta -= 360
      } else if angleDelta < -180 {
        angleDelta += 360
      }

      angleDelta = -angleDelta
      accumulatedDelta += angleDelta * dialSensitivity

      // Check if we've accumulated enough movement for a minute change
      if abs(accumulatedDelta) >= minuteThreshold {
        let minutesToAdd = Int(accumulatedDelta / minuteThreshold)
        let currentMinutes = totalSeconds / 60
        let newMinutes = max(0, min(maxMinutes, currentMinutes + Double(minutesToAdd)))

        withAnimation(.easeOut(duration: 0.1)) {
          totalSeconds = newMinutes * 60
          riveTimer.setInput("duration", value: newMinutes)
        }

        // Reset accumulated delta, keeping any remainder
        accumulatedDelta -= Double(minutesToAdd) * minuteThreshold
      }
    }

    previousAngle = degrees
    lastUpdateTime = now
    isAdjusting = true
  }

  private func handleTimerTap() {
    if !isTimerRunning {
      startTimer()
    } else {
      stopTimer()
    }
  }

  private func startTimer() {
    guard totalSeconds > 0 else { return }

    isTimerRunning = true
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      if totalSeconds > 0 {
        totalSeconds -= 1
        let normalizedValue = Double(currentMinutes)
        riveTimer.setInput("duration", value: normalizedValue)
      } else {
        SoundManager.shared.playTimerEndSound()
        stopTimer()
      }
    }
  }

  private func stopTimer() {
    isTimerRunning = false
    timer?.invalidate()
    timer = nil

    if totalSeconds <= 0 {
      totalSeconds = 0
      riveTimer.setInput("duration", value: Double(0))
    }
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
