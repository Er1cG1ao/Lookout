import Foundation

var checks = 0
func expect(_ condition: @autoclosure () -> Bool, _ name: String) {
    guard condition() else { fatalError("FAILED: \(name)") }
    checks += 1
}

var settings = ProtectionSettings()
settings.baselineYaw = 25
settings.baselinePitch = -8
var policy = AttentionPolicy()
expect(policy.covered, "starts covered until a stable face is acquired")
expect(policy.update(.face(yaw: 25, pitch: -8), at: 0, settings: settings), "does not reveal immediately")
expect(!policy.update(.face(yaw: 25, pitch: -8), at: 0.4, settings: settings), "left camera baseline is neutral")
expect(!policy.update(.face(yaw: 60, pitch: -8), at: 1, settings: settings), "brief turn is tolerated")
expect(!policy.update(.face(yaw: 25, pitch: -8), at: 1.2, settings: settings), "turn interrupted by return")
expect(!policy.update(.face(yaw: 60, pitch: -8), at: 2, settings: settings), "restarts turn dwell")
expect(policy.update(.face(yaw: 60, pitch: -8), at: 2.7, settings: settings), "sustained turn covers")
expect(policy.update(.face(yaw: 50, pitch: -8), at: 3, settings: settings), "hysteresis prevents edge flicker")
expect(policy.update(.face(yaw: 25, pitch: -8), at: 4, settings: settings), "return has dwell")
expect(!policy.update(.face(yaw: 25, pitch: -8), at: 4.4, settings: settings), "return reveals")
expect(!policy.update(.missing, at: 5, settings: settings), "brief missing face is tolerated")
expect(policy.update(.missing, at: 6.3, settings: settings), "leaving seat covers")
_ = policy.update(.face(yaw: 25, pitch: -8), at: 7, settings: settings)
expect(!policy.update(.face(yaw: 25, pitch: -8), at: 7.4, settings: settings), "reacquired face reveals")
expect(policy.update(.unavailable, at: 7.5, settings: settings), "camera failure immediately covers")
policy.reset()
expect(policy.covered, "resume clears old decision and starts covered")

settings.leftLimit = 15
settings.rightLimit = 50
_ = policy.update(.face(yaw: 25, pitch: nil), at: 10, settings: settings)
expect(!policy.update(.face(yaw: 25, pitch: nil), at: 10.4, settings: settings), "yaw-only accepts missing pitch")
_ = policy.update(.face(yaw: 60, pitch: nil), at: 11, settings: settings)
expect(!policy.update(.face(yaw: 60, pitch: nil), at: 12, settings: settings), "right tolerance is independent")
_ = policy.update(.face(yaw: 5, pitch: nil), at: 13, settings: settings)
expect(policy.update(.face(yaw: 5, pitch: nil), at: 14, settings: settings), "left tolerance is independent")

settings.pitchEnabled = true
policy.reset()
_ = policy.update(.face(yaw: 25, pitch: -8), at: 20, settings: settings)
expect(!policy.update(.face(yaw: 25, pitch: -8), at: 20.4, settings: settings), "calibrated pitch accepted")
_ = policy.update(.face(yaw: 25, pitch: 35), at: 21, settings: settings)
expect(policy.update(.face(yaw: 25, pitch: 35), at: 21.7, settings: settings), "pitch deviation covers")
expect(policy.update(.face(yaw: 25, pitch: nil), at: 22, settings: settings), "missing required pitch never reveals")
expect(AttentionPolicy.difference(-179, 179) == 2, "angles wrap correctly")
expect(AttentionPolicy.difference(179, -179) == -2, "reverse angles wrap correctly")
let data = try JSONEncoder().encode(settings)
let decoded = try JSONDecoder().decode(ProtectionSettings.self, from: data)
expect(decoded == settings, "settings round trip")
// Existing saved preferences keep calibration and the old symmetric pitch limit.
var oldJSON = try JSONSerialization.jsonObject(with: data) as! [String: Any]
oldJSON.removeValue(forKey: "pitchUpLimit")
oldJSON.removeValue(forKey: "pitchDownLimit")
oldJSON["pitchLimit"] = 24.0
let legacy = try JSONDecoder().decode(ProtectionSettings.self, from: JSONSerialization.data(withJSONObject: oldJSON))
expect(legacy.upLimit == 24 && legacy.downLimit == 24, "old pitch tolerance migrates to both directions")
expect(legacy.baselineYaw == 25 && legacy.baselinePitch == -8, "legacy calibration survives migration")

settings.upLimit = 15
settings.downLimit = 45
policy.reset()
_ = policy.update(.face(yaw: 25, pitch: -8), at: 30, settings: settings)
expect(!policy.update(.face(yaw: 25, pitch: -8), at: 30.4, settings: settings), "offset pitch remains neutral")
_ = policy.update(.face(yaw: 25, pitch: 22), at: 31, settings: settings)
expect(!policy.update(.face(yaw: 25, pitch: 22), at: 32, settings: settings), "positive pitch uses down limit")
_ = policy.update(.face(yaw: 25, pitch: -28), at: 33, settings: settings)
expect(policy.update(.face(yaw: 25, pitch: -28), at: 33.7, settings: settings), "negative pitch uses up limit")
_ = policy.update(.face(yaw: 25, pitch: -20), at: 34, settings: settings)
expect(policy.update(.face(yaw: 25, pitch: -20), at: 34.5, settings: settings), "vertical hysteresis retains cover")
_ = policy.update(.face(yaw: 25, pitch: -8), at: 35, settings: settings)
expect(!policy.update(.face(yaw: 25, pitch: -8), at: 35.4, settings: settings), "return to calibrated pitch reveals")
_ = policy.update(.face(yaw: 25, pitch: 42), at: 36, settings: settings)
expect(policy.update(.face(yaw: 25, pitch: 42), at: 36.7, settings: settings), "downward excursion triggers independently")
let newData = try JSONEncoder().encode(settings)
let newDecoded = try JSONDecoder().decode(ProtectionSettings.self, from: newData)
expect(newDecoded.upLimit == 15 && newDecoded.downLimit == 45, "asymmetric vertical preferences persist")
print("Passed \(checks) attention-policy checks.")
