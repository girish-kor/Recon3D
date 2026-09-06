# Recon3D Architecture Overview

This document describes the high‑level architecture of Recon3D, focusing on module boundaries, data flow, and extension points.

## Modules

### Domain Layer

- **Models**: Immutable value objects and entities (Frame, Mesh, ModelAsset, etc.).
- **Protocols**: Interfaces for all infrastructure adapters and services.
- **ValueObjects**: Helper types like CoverageMap, CameraPose.

### Application Layer

- **ReconstructionOrchestrator**: Central state machine and supervisor. Handles session lifecycle, capture, reconstruction, and error recovery.
- **ConfigurationLoader**: Loads and merges local/remote configuration.
- **UseCases**: Encapsulate user‑initiated actions (e.g., ExportModel).

### Infrastructure Layer

- **CameraAdapter**: Concrete implementation using AVFoundation (and optional ARKit).
- **ReconstructionEngine**: Concrete implementation using ARKit/LiDAR or OpenCV.
- **PersistenceRepository**: File‑based storage with atomic writes.
- **ExportService**: Pluggable exporters for USDZ, OBJ, etc.
- **FrameBufferManager**: Ring buffer with LRU eviction.
- **CheckpointManager**: Serialises job state to disk.
- **EventBus**: Simple pub‑sub for decoupled notifications.

### Presentation Layer

- **ViewControllers**: UI screens (Capture, Preview, Export).
- **ViewModels**: Transform domain events into view state.
- **Views**: Custom UI components (CameraPreview, Progress).

## Data Flow

1. **Camera**: Frames arrive via delegate → `CameraAdapter` wraps them as `Frame` objects.
2. **Quality & Coverage**: `Orchestrator` evaluates each frame, updates `CoverageMap`, and adds to `FrameBufferManager`.
3. **Reconstruction**: User triggers stop → `Orchestrator` selects best frames, creates a `ReconstructionJob`, and submits to `ReconstructionEngine`.
4. **Engine**: Runs pipeline stages, with periodic checkpoints. Emits progress events via `EventBus`.
5. **Completion**: Engine produces `ModelAsset`; `Orchestrator` saves it via `PersistenceRepository` and notifies UI.
6. **Export**: User selects format → `ExportService` converts asset and provides file URL.

## Extension Points

- **ReconstructionEngineProtocol**: Add new engines (e.g., cloud‑based) by implementing this protocol.
- **ExporterStrategy**: Add new export formats by conforming to the exporter interface.
- **CameraAdapterProtocol**: Swap camera implementation for different platforms (Android, Web).
- **Configuration**: All parameters are externalised; no code changes needed for tuning.

## State Machine (Orchestrator)

The `ReconstructionOrchestrator` follows this state machine:

- `idle` → `capturing` (start capture)
- `capturing` → `paused` (pause) → `capturing` (resume)
- `capturing` → `processing` (stop & reconstruct)
- `processing` → `completed` (success) or `error` (failure)
- `error` → `capturing` (retry with more frames) or `processing` (retry same frames)
- `processing` → `idle` (cancel)
- Any state → `error` on unrecoverable failure.

All transitions are guarded by invariants and logged.

## Error Recovery

Each error is classified as:

- **Retryable**: The system can automatically retry (e.g., feature match failure).
- **User‑recoverable**: Requires user action (e.g., free space, add frames).
- **Fatal**: Cannot proceed; fallback to preview/pointcloud.

Checkpoints are saved every 30 seconds (configurable) to allow resumption after app termination.

## Performance Considerations

- Frame buffer uses reference counting and memory pools.
- Reconstruction stages stream intermediate data to disk to avoid memory pressure.
- GPU/CPU workloads are balanced; thermal monitoring degrades quality when needed.
- Background processing uses `Task` with cooperative cancellation.

---

For detailed implementation notes, refer to the source code and inline documentation.
