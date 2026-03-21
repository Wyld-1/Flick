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
import WatchConnectivity

// Gesture types the app can detect
enum GestureType {
    case none
    case nextTrack      // Flick CCW (left)
    case previousTrack  // Flick CW (right)
    case playPause      // Hold upside-down
}

class MotionManager: NSObject, ObservableObject {
    @Published var mLastGesture: GestureType = .none
    weak var appState: AppStateManager?
    
    private let mMotion = CMMotionManager()
    private var mLastGestureTime: Date = Date()
    private var mUpsideDownStartTime: Date?
    
    // Workout session for background execution
    private let mHealthStore = HKHealthStore()
    private var mWorkoutSession: HKWorkoutSession?
    private var mWorkoutBuilder: HKLiveWorkoutBuilder?
    
    // Gesture detection thresholds
    private let TWIST_THRESHOLD: Double = 2.2
    private let MIN_TWIST_DURATION: TimeInterval = 0.1
    private let UPSIDE_DOWN_THRESHOLD: Double = 0.6
    private let UPSIDE_DOWN_HOLD_TIME: TimeInterval = 1.2
    private let GESTURE_COOLDOWN: TimeInterval = 0.8
    
    private var mTwistStartTime: Date?
    private var mPeakRotationRate: Double = 0.0
    
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
        mHealthStore.requestAuthorization(toShare: typesToShare, read: nil) { success, error in
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
        guard mMotion.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        mMotion.deviceMotionUpdateInterval = 0.05  // 20Hz
        mMotion.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            self.processMotion(data)
        }
    }
    
    func stopMonitoring() {
        mMotion.stopDeviceMotionUpdates()
        endWorkoutSession()
    }
    
    func pauseMonitoring() {
        // Keep workout session alive; stop polling to save battery
        mMotion.stopDeviceMotionUpdates()
    }
    
    func resumeMonitoring() {
        guard mMotion.isDeviceMotionAvailable else { return }
        mMotion.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            self.processMotion(data)
        }
    }
    
    private func startWorkoutSession() {
        #if targetEnvironment(simulator)
        return
        #endif
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .unknown
        
        do {
            mWorkoutSession = try HKWorkoutSession(healthStore: mHealthStore, configuration: configuration)
            mWorkoutBuilder = mWorkoutSession?.associatedWorkoutBuilder()
            mWorkoutSession?.delegate = self
            mWorkoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: mHealthStore,
                workoutConfiguration: configuration
            )
            mWorkoutSession?.startActivity(with: Date())
            mWorkoutBuilder?.beginCollection(withStart: Date()) { _, error in
                if let error = error {
                    print("Error starting workout builder: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error starting workout session: \(error.localizedDescription)")
        }
    }

    private func endWorkoutSession() {
        #if targetEnvironment(simulator)
        return
        #endif
        
        mWorkoutSession?.end()
        mWorkoutBuilder?.endCollection(withEnd: Date()) { success, _ in
            if success {
                self.mWorkoutBuilder?.finishWorkout { _, _ in }
            }
        }
    }
    
    private func processMotion(_ data: CMDeviceMotion) {
        guard Date().timeIntervalSince(mLastGestureTime) > GESTURE_COOLDOWN else { return }
        detectTwist(data)
        detectUpsideDown(data)
    }
    
    private func detectTwist(_ data: CMDeviceMotion) {
        let absRotation = abs(data.rotationRate.z)
        
        if absRotation > mPeakRotationRate { mPeakRotationRate = absRotation }
        
        if absRotation > TWIST_THRESHOLD {
            if mTwistStartTime == nil { mTwistStartTime = Date() }
        } else if let startTime = mTwistStartTime {
            let duration = Date().timeIntervalSince(startTime)
            if duration >= MIN_TWIST_DURATION && mPeakRotationRate > TWIST_THRESHOLD {
                let shouldReverse = (isLeftWrist != (appState?.isFlickDirectionReversed ?? false))
                let direction = mPeakRotationRate > 0
                if shouldReverse {
                    triggerGesture(direction ? .nextTrack : .previousTrack)
                } else {
                    triggerGesture(direction ? .previousTrack : .nextTrack)
                }
            }
            mTwistStartTime = nil
            mPeakRotationRate = 0.0
        }
    }
    
    private func detectUpsideDown(_ data: CMDeviceMotion) {
        if data.gravity.z > UPSIDE_DOWN_THRESHOLD {
            if mUpsideDownStartTime == nil {
                mUpsideDownStartTime = Date()
            } else if let startTime = mUpsideDownStartTime,
                      Date().timeIntervalSince(startTime) >= UPSIDE_DOWN_HOLD_TIME {
                triggerGesture(.playPause)
                mUpsideDownStartTime = nil
            }
        } else {
            mUpsideDownStartTime = nil
        }
    }
    
    private func triggerGesture(_ gesture: GestureType) {
        mLastGesture = gesture
        mLastGestureTime = Date()
        WKInterfaceDevice.current().play(.click)
        
        let command: MediaCommand?
        switch gesture {
        case .nextTrack:     command = .nextTrack
        case .previousTrack: command = .previousTrack
        case .playPause:     command = .playPause
        case .none:          command = nil
        }
        
        if let command = command {
            print("⌚️ Sending \(command.rawValue) (session reachable: \(WCSession.default.isReachable))")
            WatchConnectivityManager.shared.sendMediaCommand(command)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.mLastGesture = .none
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
        DispatchQueue.main.async {
            switch toState {
            case .running, .prepared:
                self.resumeMonitoring()
            case .paused, .ended, .stopped, .notStarted:
                self.mMotion.stopDeviceMotionUpdates()
            @unknown default:
                break
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
        mMotion.stopDeviceMotionUpdates()
    }
}
