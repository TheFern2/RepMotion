import RepMotionCore

enum SyntheticSamples {

    static func flat(count: Int, startTime: Double = 0) -> [MotionSample] {
        (0..<count).map { i in
            MotionSample(timestamp: startTime + Double(i) * 0.02, ax: 0, ay: 0, az: 0)
        }
    }

    static func repPulse(startTime: Double, axis: Axis = .y, magnitude: Double = 4.0) -> [MotionSample] {
        let shape = [0.3, 0.8, magnitude, 0.8, 0.3, 0.0, 0.0, 0.0]
        return shape.enumerated().map { i, value in
            let t = startTime + Double(i) * 0.02
            switch axis {
            case .x: return MotionSample(timestamp: t, ax: value, ay: 0, az: 0)
            case .y: return MotionSample(timestamp: t, ax: 0, ay: value, az: 0)
            case .z: return MotionSample(timestamp: t, ax: 0, ay: 0, az: value)
            }
        }
    }

    static func session(repCount: Int, warmupSeconds: Double = 5.0) -> [MotionSample] {
        let warmupSamples = Int(warmupSeconds * 50)
        var samples = flat(count: warmupSamples)
        let gapSamples = 100 // 2s between reps at 50Hz — keeps the 100-sample stats window mostly flat

        for _ in 0..<repCount {
            let lastTime = samples.last?.timestamp ?? 0
            samples += flat(count: gapSamples, startTime: lastTime + 0.02)
            let pulseStart = samples.last!.timestamp + 0.02
            samples += repPulse(startTime: pulseStart)
        }

        let lastTime = samples.last?.timestamp ?? 0
        samples += flat(count: 50, startTime: lastTime + 0.02)
        return samples
    }

    static func magnitudeSamples(ax: Double, count: Int = 5) -> [MotionSample] {
        (0..<count).map { i in
            MotionSample(timestamp: Double(i) * 0.02, ax: ax, ay: 0, az: 0)
        }
    }

    enum Axis {
        case x, y, z
    }
}
