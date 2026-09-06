# Recon3D – Production-Grade 3D Reconstruction for iOS

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![CI](https://github.com/yourusername/Recon3D/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/Recon3D/actions/workflows/ci.yml)

**Recon3D** is a native iOS application that captures a real‑world physical object through the device camera and reconstructs it into a high‑quality 3D model. It is built with a modular, production‑grade architecture, supporting real‑time capture, frame quality evaluation, coverage validation, and a fully configurable reconstruction pipeline (on‑device ARKit/LiDAR or fallback SfM). The project follows clean architecture principles, dependency injection, and extensive error recovery – ready for enterprise deployment.

## Features

- **Camera capture** with automatic focus, exposure, and motion/blur rejection.
- **Frame quality validation** (sharpness, motion, exposure, contrast).
- **Coverage mapping** (azimuth/elevation bins) to ensure full object coverage.
- **Frame buffering** with intelligent eviction (LRU + quality utility).
- **Reconstruction engine** (ARKit + LiDAR or OpenCV SfM) with checkpointing and pause/resume.
- **Post‑processing pipeline**: hole filling, denoising, smoothing, decimation, normal/UV generation, texture reconstruction, material estimation.
- **Model persistence** (local file system with atomic writes and metadata).
- **Export** to USDZ, OBJ, glTF, STL, PLY (extensible).
- **Complete error handling** with retry, user‑recoverable actions, and partial‑job recovery.
- **Thermal/battery/disk‑space awareness** and adaptive resource management.
- **Event‑driven** progress and state updates.

## Architecture

The project is organised into clean layers:

- **Domain**: Core models and protocols (no external dependencies).
- **Application**: Orchestration, configuration, use cases.
- **Infrastructure**: Concrete implementations of adapters, engines, repositories, exporters, checkpointing.
- **Presentation**: UIKit view controllers, views, view models.
- **Services**: Platform diagnostics (memory, thermal, battery).

Key design patterns:

- **Dependency Inversion** – high‑level modules depend on abstractions.
- **Strategy** – replaceable reconstruction engines (ARKit, OpenCV, cloud).
- **Adapter** – platform‑specific camera abstraction.
- **Repository** – persistence abstraction.
- **State Machine** – orchestrated session lifecycle.
- **Observer/Event** – decoupled progress and error propagation.
- **Command/Job** – cancellable background processing.

![Architecture Diagram](docs/architecture.png) _(placeholder – see docs folder)_

## Requirements

- Xcode 15.0+
- iOS 16.0+
- Swift 5.9
- Device with A12 Bionic or later (for ARKit/LiDAR features; fallback works on older devices)

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/yourusername/Recon3D.git
cd Recon3D
```

### Open in Xcode

```bash
open Recon3D.xcodeproj
```

### Build and Run

Select a simulator or physical device and press `⌘R`. The app will request camera and storage permissions – grant them to start capturing.

### Running Tests

```bash
xcodebuild test -scheme Recon3D -destination 'platform=iOS Simulator,name=iPhone 14'
```

Or use the Test navigator in Xcode.

## Configuration

The app is fully configurable via `config.plist` (defaults) and remote overrides. Key settings:

- Capture: resolution, FPS, quality thresholds, coverage requirements.
- Reconstruction: mesh density, texture resolution, feature detectors, depth method.
- System: memory limits, thermal throttle thresholds, checkpoint intervals.

See `Recon3D/Application/Configuration/ConfigurationLoader.swift` for loading logic.

## Project Structure

```
Recon3D/
├── Domain/                 # Models & Protocols
│   ├── Models/
│   ├── Protocols/
│   └── ValueObjects/
├── Application/            # Orchestration, Configuration, UseCases
├── Infrastructure/         # Adapters, Engines, Repositories, Services
│   ├── Camera/
│   ├── Reconstruction/
│   ├── Persistence/
│   ├── Export/
│   ├── FrameBuffer/
│   ├── Checkpoint/
│   └── Event/
├── Presentation/           # ViewControllers, Views, ViewModels
├── Services/               # Diagnostics, Platform monitors
├── Utils/                  # Extensions, Helpers
└── Resources/              # Assets, Config, Localization
```

## Extending the System

- **Add a new reconstruction engine**: Implement `ReconstructionEngineProtocol` and register via `ReconstructionEngineFactory`.
- **Support a new export format**: Implement `ExporterStrategy` and add to `ExportService`.
- **Change camera backend**: Implement `CameraAdapterProtocol` (e.g., for Android/Web).
- **Use cloud processing**: Implement a cloud‑based `ReconstructionEngineProtocol` without modifying domain logic.

## Error Recovery & Resilience

The system is built to handle:

- Permission denials (prompts user).
- Insufficient storage/thermal/battery (adaptive degradation).
- Tracking loss (pause & resume).
- Reconstruction failures (retry with more frames or different config).
- App termination (resume from checkpoint).
- Corrupted intermediate data (fallback to previous checkpoint).

All recoverable errors are propagated to the UI with clear user actions.

## Contributing

We welcome contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow

1. Fork the repository.
2. Create a feature branch.
3. Make changes with tests.
4. Submit a pull request.

## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- ARKit and RealityKit for on‑device reconstruction.
- OpenCV (optional) for feature‑based SfM.
- The iOS community for excellent frameworks and tools.

---

**Built with ❤️ by [Your Name/Team]** – For any questions, open an issue or contact [email@example.com](mailto:email@example.com).
