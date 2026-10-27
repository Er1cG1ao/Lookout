import Foundation

struct ProtectionSettings: Codable, Equatable {
    var cameraID = ""
    var rotation = 0
    var baselineYaw = 0.0
    var baselinePitch = 0.0
    var leftLimit = 30.0
    var rightLimit = 30.0
    var pitchEnabled = false
    var pitchLimit = 30.0
    // Optional stored fields preserve decoding of 0.1.0 preferences.
    var pitchUpLimit: Double?
    var pitchDownLimit: Double?
    var upLimit: Double {
        get { pitchUpLimit ?? pitchLimit }
        set { pitchUpLimit = newValue }
    }
    var downLimit: Double {
        get { pitchDownLimit ?? pitchLimit }
        set { pitchDownLimit = newValue }
    }
    var awayDelay = 0.6
    var missingDelay = 1.2
    var returnDelay = 0.35
    var blurRadius = 64.0
    var dimming = 0.25
    var calibrated = false
}

enum AttentionInput {
    case face(yaw: Double, pitch: Double?)
    case missing
    case unavailable
}

/// Pure time-based policy; camera and UI share no state with this value type.
struct AttentionPolicy {
    private(set) var covered = true
    private var candidate: String?
    private var candidateSince = 0.0

    mutating func reset() {
        covered = true
        candidate = nil
    }

    mutating func update(_ input: AttentionInput, at now: Double,
                         settings: ProtectionSettings) -> Bool {
        let reason: String
        let delay: Double
        let desired: Bool
        switch input {
        case .unavailable:
            covered = true
            candidate = nil
            return covered
        case .missing:
            reason = "missing"; delay = settings.missingDelay; desired = true
        case let .face(yaw, pitch):
            let relative = Self.difference(yaw, settings.baselineYaw)
            let margin = covered ? 7.0 : 0.0
            let left = max(3, settings.leftLimit - margin)
            let right = max(3, settings.rightLimit - margin)
            // Vision pitch is positive when nodding down (VNObservation.h).
            let vertical = Self.difference(pitch ?? 0, settings.baselinePitch)
            let badPitch = settings.pitchEnabled && (pitch == nil ||
                vertical < -max(3, settings.upLimit - margin) ||
                vertical > max(3, settings.downLimit - margin))
            if relative < -left || relative > right || badPitch {
                reason = "away"; delay = settings.awayDelay; desired = true
            } else {
                reason = "forward"; delay = settings.returnDelay; desired = false
            }
        }
        guard covered != desired else { candidate = nil; return covered }
        if candidate != reason { candidate = reason; candidateSince = now }
        if now - candidateSince >= delay {
            covered = desired
            candidate = nil
        }
        return covered
    }

    static func difference(_ angle: Double, _ reference: Double) -> Double {
        let raw = (angle - reference).truncatingRemainder(dividingBy: 360)
        return raw > 180 ? raw - 360 : (raw < -180 ? raw + 360 : raw)
    }
}
