import Foundation

class RingBufferFrameManager: FrameBufferManagerProtocol {
    private var buffer: [Frame?]
    private var frameIndexMap: [FrameID: Int] = [:]
    private var writeIndex: Int = 0
    private(set) var size: Int = 0
    private(set) var maxCapacity: Int
    private let lock = NSLock()
    
    init(capacity: Int) {
        self.maxCapacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }
    
    func addFrame(_ frame: Frame) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if size >= maxCapacity {
            // Evict lowest utility
            _ = evictLowestUtility()
        }
        buffer[writeIndex] = frame
        frameIndexMap[frame.id] = writeIndex
        writeIndex = (writeIndex + 1) % maxCapacity
        size = min(size + 1, maxCapacity)
        return true
    }
    
    private func evictLowestUtility() -> Frame? {
        // Find frame with lowest sharpness * coverage factor
        var minUtility = Float.infinity
        var minIndex = -1
        for (idx, frame) in buffer.enumerated() {
            guard let f = frame else { continue }
            let utility = f.metadata.sharpnessScore * (f.coverageContribution != nil ? 1.0 : 0.5)
            if utility < minUtility {
                minUtility = utility
                minIndex = idx
            }
        }
        if minIndex >= 0 {
            let removed = buffer[minIndex]
            buffer[minIndex] = nil
            if let id = removed?.id { frameIndexMap.removeValue(forKey: id) }
            size -= 1
            return removed
        }
        return nil
    }
    
    func getFrame(id: FrameID) -> Frame? {
        lock.lock(); defer { lock.unlock() }
        guard let idx = frameIndexMap[id] else { return nil }
        return buffer[idx]
    }
    
    func getFramesForReconstruction(config: ReconstructionConfig) -> [Frame] {
        lock.lock(); defer { lock.unlock() }
        let valid = buffer.compactMap { $0 }.filter { $0.qualityVerdict == .pass }
        // Group by coverage bin, select top quality
        var binMap: [String: [Frame]] = [:]
        for frame in valid {
            if let contrib = frame.coverageContribution {
                let key = "\(contrib.binIndexAz)-\(contrib.binIndexEl)"
                binMap[key, default: []].append(frame)
            }
        }
        var selected: [Frame] = []
        for (_, frames) in binMap {
            let sorted = frames.sorted { $0.metadata.sharpnessScore > $1.metadata.sharpnessScore }
            let take = min(sorted.count, Int(config.meshDensity.vertexTarget) / 10) // heuristic
            selected.append(contentsOf: sorted.prefix(take))
        }
        if selected.count > Int(config.meshDensity.vertexTarget) {
            selected = Array(selected.shuffled().prefix(Int(config.meshDensity.vertexTarget)))
        }
        return selected
    }
    
    func clear() {
        lock.lock(); defer { lock.unlock() }
        buffer = Array(repeating: nil, count: maxCapacity)
        frameIndexMap.removeAll()
        writeIndex = 0
        size = 0
    }
    
    func handleMemoryWarning(_ level: MemoryWarningLevel) {
        lock.lock(); defer { lock.unlock() }
        if level == .critical {
            maxCapacity = maxCapacity / 2
            while size > maxCapacity {
                _ = evictLowestUtility()
            }
            buffer = buffer.prefix(maxCapacity) + Array(repeating: nil, count: maxCapacity - buffer.count)
        }
    }
}
