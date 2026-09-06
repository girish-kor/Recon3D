import Foundation

protocol FrameBufferManagerProtocol {
    func addFrame(_ frame: Frame) -> Bool
    func getFrame(id: FrameID) -> Frame?
    func getFramesForReconstruction(config: ReconstructionConfig) -> [Frame]
    func clear()
    func handleMemoryWarning(_ level: MemoryWarningLevel)
    var size: Int { get }
    var maxCapacity: Int { get set }
}
