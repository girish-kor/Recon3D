import UIKit
import AVFoundation

class CaptureViewController: UIViewController {
    private var orchestrator: ReconstructionOrchestrator!
    private var previewView: CameraPreviewView!
    private var progressView: ProgressView!
    private var captureButton: UIButton!
    private var statusLabel: UILabel!
    private var cancellables: [AnyCancellable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Initialize orchestrator with dependencies (use DI in production)
        let config = ConfigurationLoader.loadConfiguration()
        let caps = SystemCapabilities.current()
        let camera = AVFoundationCameraAdapter()
        let jobStore = InMemoryJobStore() // or SQLite
        let checkpoint = try! FileCheckpointManager(baseDir: FileManager.default.temporaryDirectory)
        let engine = ReconstructionEngineFactory.createEngine(capabilities: caps, jobStore: jobStore, checkpointManager: checkpoint)
        let repo = try! FileSystemRepository(rootDir: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!)
        let export = ExportService()
        let eventBus = EventBus()
        orchestrator = ReconstructionOrchestrator(cameraAdapter: camera, engine: engine, repo: repo,
                                                  exportService: export, eventBus: eventBus, config: config, caps: caps)
        orchestrator.bootstrap()
        subscribeEvents()
        orchestrator.startCaptureSession()
    }
    
    private func setupUI() {
        previewView = CameraPreviewView(frame: view.bounds)
        view.addSubview(previewView)
        statusLabel = UILabel(frame: CGRect(x: 20, y: 40, width: view.bounds.width-40, height: 30))
        statusLabel.textColor = .white
        view.addSubview(statusLabel)
        captureButton = UIButton(type: .system)
        captureButton.setTitle("Stop & Reconstruct", for: .normal)
        captureButton.addTarget(self, action: #selector(stopCapture), for: .touchUpInside)
        captureButton.frame = CGRect(x: view.bounds.midX-80, y: view.bounds.maxY-100, width: 160, height: 60)
        view.addSubview(captureButton)
        progressView = ProgressView(frame: CGRect(x: 20, y: view.bounds.maxY-200, width: view.bounds.width-40, height: 20))
        progressView.isHidden = true
        view.addSubview(progressView)
    }
    
    private func subscribeEvents() {
        // In production use Combine; here we manually subscribe
        let bus = orchestrator.eventBus
        let sub1 = bus.subscribe(FrameCapturedEvent.self) { [weak self] event in
            DispatchQueue.main.async {
                self?.statusLabel.text = "Captured \(event.bufferSize) frames"
            }
        }
        let sub2 = bus.subscribe(ProgressUpdateEvent.self) { [weak self] event in
            DispatchQueue.main.async {
                self?.progressView.progress = event.progress
                self?.statusLabel.text = "\(event.stage): \(Int(event.progress*100))%"
            }
        }
        let sub3 = bus.subscribe(ReconstructionCompletedEvent.self) { [weak self] _ in
            DispatchQueue.main.async {
                self?.progressView.isHidden = true
                self?.statusLabel.text = "Completed!"
                // Navigate to preview
            }
        }
        let sub4 = bus.subscribe(ErrorOccurredEvent.self) { [weak self] event in
            DispatchQueue.main.async {
                self?.statusLabel.text = "Error: \(event.error.message)"
                // Show alert
            }
        }
        cancellables.append(contentsOf: [sub1, sub2, sub3, sub4])
    }
    
    @objc private func stopCapture() {
        orchestrator.stopCaptureAndReconstruct()
        progressView.isHidden = false
        captureButton.isEnabled = false
        statusLabel.text = "Reconstructing..."
    }
}

class InMemoryJobStore: JobStoreProtocol {
    private var jobs: [JobID: ReconstructionJob] = [:]
    private let lock = NSLock()
    func save(_ job: ReconstructionJob) { lock.lock(); jobs[job.id] = job; lock.unlock() }
    func load(_ jobID: JobID) -> ReconstructionJob? { lock.lock(); defer { lock.unlock() }; return jobs[jobID] }
    func update(_ job: ReconstructionJob) { save(job) }
    func findByStatus(_ statuses: [JobStatus]) -> [ReconstructionJob] {
        lock.lock(); defer { lock.unlock() }
        return jobs.values.filter { statuses.contains($0.status) }
    }
}
