//
// MotionManager.swift
// Flick
//
// Created by Liam Lefohn on 1/27/26.
//
// Reads sensors, detects gestures - runs as workout session for background execution

import Foundation
import CoreMotion
import Combine
import HealthKit
import WatchKit

// Gesture types the app can detect
enum GestureType {
    case none
    case nextTrack      // Flick CCW (left)
    case previousTrack  // Flick CW (right)
    case playPause      // Hold upside-down
}

class MotionManager: NSObject, ObservableObject {
    @Published var lastGesture: GestureType = .none
    weak var appState: AppStateManager?
    
    private let motion = CMMotionManager()
    private var lastGestureTime: Date = Date()
    private var upsideDownStartTime: Date?
    
    // Workout session for background execution
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    // Tunable thresholds
    private let TWIST_THRESHOLD: Double = 2.5               // rad/s
    private let UPSIDE_DOWN_THRESHOLD: Double = 0.7         // Gravity force ratio
    private let UPSIDE_DOWN_HOLD_TIME: TimeInterval = 1.5   // Seconds
    private let GESTURE_COOLDOWN: TimeInterval = 0.8        // Seconds
    
    var isLeftWrist: Bool = true
    
    override init() {
        super.init()
        // Authorization requested from WelcomeView
    }
    
    deinit {
        endWorkoutSession()
    }
    
    func requestHealthKitAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToShare: Set = [HKObjectType.workoutType()]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: nil) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(success)
            }
        }
    }
    
    func startMonitoring() {
        startWorkoutSession()
        
        guard motion.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motion.deviceMotionUpdateInterval = 0.05  // 20Hz
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            self.processMotion(data)
        }
    }
    
    func stopMonitoring() {
        motion.stopDeviceMotionUpdates()
        endWorkoutSession()
    }
    
    func pauseMonitoring() {
        motion.stopDeviceMotionUpdates()
        // Keep workout session alive but stop motion updates to save battery
    }
    
    func resumeMonitoring() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            self.processMotion(data)
        }
    }
    
    private func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("Error starting workout builder: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error starting workout session: \(error.localizedDescription)")
        }
    }
    
    private func endWorkoutSession() {
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { success, error in
            if success {
                self.workoutBuilder?.finishWorkout { workout, error in
                    // Workout finished
                }
            }
        }
    }
    
    private func processMotion(_ data: CMDeviceMotion) {
        guard Date().timeIntervalSince(lastGestureTime) > GESTURE_COOLDOWN else {
            return
        }
        
        detectTwist(data)
        detectUpsideDown(data)
    }
    
    private func detectTwist(_ data: CMDeviceMotion) {
        let rotationRate = data.rotationRate.z
        
        if abs(rotationRate) > TWIST_THRESHOLD {
            let shouldReverse = (isLeftWrist != (appState?.isFlickDirectionReversed ?? false))
            
            if shouldReverse {
                if rotationRate > 0 {
                    triggerGesture(.nextTrack)
                } else {
                    triggerGesture(.previousTrack)
                }
            } else {
                if rotationRate > 0 {
                    triggerGesture(.previousTrack)
                } else {
                    triggerGesture(.nextTrack)
                }
            }
        }
    }
    
    private func detectUpsideDown(_ data: CMDeviceMotion) {
        let gravity = data.gravity.z
        
        if gravity > UPSIDE_DOWN_THRESHOLD {
            if upsideDownStartTime == nil {
                upsideDownStartTime = Date()
            } else if let startTime = upsideDownStartTime,
                      Date().timeIntervalSince(startTime) >= UPSIDE_DOWN_HOLD_TIME {
                triggerGesture(.playPause)
                upsideDownStartTime = nil
            }
        } else {
            upsideDownStartTime = nil
        }
    }
    
    private func triggerGesture(_ gesture: GestureType) {
        // 1. Update Local State
        lastGesture = gesture
        lastGestureTime = Date()
        
        // 2. Local Haptic Feedback (So you know the watch felt it)
        WKInterfaceDevice.current().play(.click)
        
        // 3. Map gesture to command and SEND IT 🚀
        var commandToSend: MediaCommand?
        
        switch gesture {
        case .nextTrack:
            commandToSend = .nextTrack
        case .previousTrack:
            commandToSend = .previousTrack
        case .playPause:
            commandToSend = .playPause
        case .none:
            commandToSend = nil
        }
        
        // Actually sends to iPhone
        if let command = commandToSend {
            print("⌚️ Gesture detected: \(gesture). Sending to iPhone...")
            WatchConnectivityManager.shared.sendMediaCommand(command)
        }
        
        // 4. Reset state after cooldown
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.lastGesture = .none
        }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension MotionManager: HKWorkoutSessionDelegate {
    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        // Handle state changes if needed
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
}
