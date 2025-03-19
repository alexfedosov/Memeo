# Memeo App Knowledge Base

## Architecture

### MVVM Implementation

The app is being refactored to follow a proper MVVM (Model-View-ViewModel) architecture:

1. **ViewModels**:
   - Should use `@Published private(set) var` for state properties
   - Example: `@Published private(set) var documents: [Document] = []`
   - Services should be injected via initializers
   - ViewModels handle business logic and data transformation

2. **Views**:
   - Should use `@ObservedObject var viewModel: SomeViewModel`
   - Initialize with a viewModel parameter and default value
   - Should not modify ViewModel state directly, but through methods

3. **Models**:
   - Document, Tracker, and Animation are the primary models

### Coordinator and Factory Pattern

The app uses a Coordinator pattern with a ViewModelFactory for better dependency management:

1. **ViewModelFactory Protocol**:
   - Defines methods to create ViewModels: `func makeHomeViewModel() -> HomeViewModel`
   - Concrete implementation manages dependencies: `AppViewModelFactory`
   - Enables testability through dependency injection

2. **AppCoordinator**:
   - Central place for managing navigation and app state
   - Creates ViewModels through the factory
   - Handles app lifecycle and navigation between screens

## Project Structure

The project follows a feature-based organization with domain-driven design principles:

- `/Memeo/Sources/Features/` - Feature modules organized by domain
  - `/Home/` - Home screen implementation
  - `/VideoEditor/` - Video editor implementation
    - `/Timeline/` - Timeline-specific components
- `/Memeo/Sources/Models/` - Model definitions
  - `/Domain/` - Core business domain models
- `/Memeo/Sources/Services/` - Services for data handling
- `/Memeo/Sources/Utils/` - Utility extensions and helpers
- `/Memeo/Sources/CommonComponents/` - Reusable UI components
  - `/Buttons/` - Button components and styles
  - `GradientFactory.swift` - Centralized gradient definitions

## Key Components

### Document
Main model representing a video with trackers and animations.

### Tracker
Represents an overlay on the video with position, style, and animations.

### Animation
Generic animation system for various properties like position, opacity, etc.

## State Management Pattern

When modifying model state in ViewModels, follow this pattern to ensure proper state management:

```swift
// Create a copy of the state
var updatedDocument = document
// Modify the copy
updatedDocument.trackers[index].text = newText
// Replace the entire state with the updated copy
document = updatedDocument
```

This ensures that SwiftUI properly observes the changes and updates the UI accordingly.

## To-Do Items Status

1. ✅ Implement proper MVVM architecture
   - ✅ Refactor HomeViewModel with proper @Published private(set) properties
   - ✅ Update Home.swift to use @ObservedObject instead of @StateObject
   - ✅ Apply MVVM to VideoEditor components

2. ✅ Move ViewModel initialization to a factory/coordinator pattern

3. ✅ Reorganize file structure to better separate features
   - Created Features directory with sub-directories for each feature
   - Moved models to Domain directory for clearer structure
   - Updated file headers to indicate new organization

4. ✅ Create a centralized dependency injection system
   - Created DependencyContainer.swift with register/resolve methods
   - Updated MemeoApp.swift to register all services
   - Updated ViewModelFactory to use the DependencyContainer
   - Removed default parameter values from ViewModel initializers

5. ✅ Consolidate duplicated view components and utilities
   - Created CommonComponents/Buttons directory for button styles
   - Implemented GradientFactory for consistent gradient definitions
   - Created GradientButtonStyle implementing ButtonStyle protocol
   - Added MemeoButton component for standardized buttons
   - Implemented VideoProcessing utility for shared video functions

6. ✅ Replace manually-created Hashable implementations with automatic synthesis
   - Removed redundant `hash(into:)` implementations from Tracker.swift
   - Created proper Hashable extension for CGPoint in CoreGraphicsExtensions.swift
   - Consolidated CGPoint and CGSize extensions in CoreGraphicsExtensions.swift
   - Renamed CGPointExtensions.swift to CoreGraphicsExtensions.swift

7. ✅ Use `@frozen` for enums that won't change
   - Added `@frozen` annotation to TrackerStyle enum
   - Added `@frozen` annotation to TrackerSize enum
   - Added documentation explaining ABI stability reasons

8. ✅ Optimize video processing with hardware acceleration
   - Added VideoToolbox hardware acceleration to FFmpeg commands
   - Implemented multi-strategy encoding with fallback mechanisms
   - Created a robust export pipeline with quality tier fallbacks
   - Added more specific error types for video processing failures

## Implementation Notes

### Modern Swift Best Practices

- Use Swift's automatic Hashable synthesis where possible instead of manual implementations
- Apply `@frozen` to enums that are part of your app's ABI and won't change
- Centralize related types (like CGPoint, CGSize) in appropriately named extension files
- Use proper file naming conventions based on content (CoreGraphicsExtensions vs CGPointExtensions)
- Document public APIs with proper documentation comments
- Follow Swift API Design Guidelines for clean, consistent code
- Use `@MainActor` for all ViewModels and UI-related classes to ensure proper thread safety

### Error Handling and Resource Management

- Use `LocalizedError` protocol for meaningful error messages and better debugging
- Create domain-specific error types with descriptive cases
- Use defer blocks for proper resource cleanup
- Implement resource handles with closures for the AutoCloseable pattern:
  ```swift
  class ResourceHandle<T> {
      private let resource: T
      private let cleanup: (T) -> Void
      
      init(resource: T, cleanup: @escaping (T) -> Void) {
          self.resource = resource
          self.cleanup = cleanup
      }
      
      func get() -> T {
          return resource
      }
      
      deinit {
          cleanup(resource)
      }
  }
  ```
- Safely manage temporary files with proper creation and cleanup protocols
- Create dedicated `Temporary` directories for organized file management 
- Check `Task.isCancelled` in loops and long-running operations to support cancellation
- Use content-based file identification for temporary file management (file prefixes, extensions)
- Implement age-based expiration for temporary resources (24-hour window)

### MainActor Usage

- All ViewModels (HomeViewModel, VideoEditorViewModel, ShareViewModel) are marked with `@MainActor`
- UI-related classes like `TrackersEditorUIView` and `VideoPickerCoordinator` are marked with `@MainActor`
- When using `@MainActor` on a class:
  - Remove redundant `@MainActor` annotations on methods within the class
  - Remove unnecessary `MainActor.run` blocks when already in a MainActor context
  - Replace `DispatchQueue.main.async` calls with direct method calls when in MainActor context
- The MainActor helps prevent thread-safety issues by ensuring UI updates happen on the main thread
- SwiftUI Views automatically run on the MainActor, so direct UI updates from SwiftUI views don't need additional MainActor annotations

### VideoEditorViewModel Refactoring

- Added `private(set)` to all published properties
- Introduced proper state modification methods (setIsPlaying, setIsEditingText, etc.)
- Created custom bindings in the view for read-only or computed properties
- Improved error handling with more explicit guard clauses
- Added proper service dependency injection
- Organized code with MARK comments for better readability
- Implemented async/await for cleanDocumentsDirectory operation

## SwiftUI Modernization

### UIKit to SwiftUI Migration
- Replaced UIKit components with native SwiftUI equivalents:
  - Created `FocusableTextField` using SwiftUI's TextField with FocusState instead of UITextField
  - Implemented `BlurView` and `SimpleBlurView` using SwiftUI's Material and blur modifiers
  - Created `TrackerView` using SwiftUI's Text and overlay modifiers instead of CALayer

## Video Processing Optimization

### Hardware Acceleration with VideoToolbox
- Implemented VideoToolbox hardware acceleration for video encoding:
  - Added `-hwaccel videotoolbox` flag to FFmpeg commands for hardware decoding
  - Used `-c:v h264_videotoolbox` for hardware-accelerated encoding
  - Applied optimized settings with `-preset fast -b:v 2M` for speed/quality balance

### Multi-tiered Export Strategy
- Implemented a fallback system for video export with three tiers:
  1. High-quality export with hardware acceleration (first attempt)
  2. Medium-quality export with hardware acceleration (fallback if high quality fails)
  3. Custom AVAssetWriter/AVAssetReader pipeline (final fallback)
- Added specific error types for better error handling:
  - `VideoExporterError.encodingError` for encoding failures
  - `VideoExporterError.hardwareAccelerationError` for hardware acceleration issues
- Optimized settings in AVAssetWriter configuration:
  - Used H.264 High Profile with hardware acceleration
  - Set appropriate quality parameters for real-time performance
  - Implemented proper video and audio settings for maximum compatibility

### SwiftUI Best Practices
- Used conditional view modifiers with extension method:
  ```swift
  extension View {
      @ViewBuilder
      func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
          if condition {
              transform(self)
          } else {
              self
          }
      }
  }
  
  // Usage
  Text("Hello")
      .if(someCondition) { view in
          view.foregroundColor(.red)
      }
  ```
- Implemented proper ButtonStyle protocol in GradientButtonStyle
- Created static extension methods for common button styles: `.buttonStyle(.gradient)`
- Used environment values for sharing dependencies between views 
- Added proper environment object pattern for ViewModels:
  ```swift
  // Add view extension for convenience
  extension View {
      func withVideoEditorViewModel(_ viewModel: VideoEditorViewModel) -> some View {
          environmentObject(viewModel)
      }
  }
  
  // Usage in parent views
  VideoEditor(onClose: closeAction)
      .environmentObject(viewModel)
      
  // Access in child views
  struct VideoEditor: View {
      @EnvironmentObject private var viewModel: VideoEditorViewModel
      
      // View body
  }
  ```
- Implemented focus management with @FocusState property wrapper

### Semantic Layout Containers
- Replaced nested ZStacks and VStacks with more semantic layout containers:
  - Used `LazyHGrid` and `LazyVGrid` for grid-like layouts:
    ```swift
    LazyHGrid(rows: [GridItem(.fixed(100))], spacing: 0) {
        // Grid items
    }
    ```
  - Replaced custom loading overlays with reusable ViewBuilder functions
  - Used Form for structured settings and information displays:
    ```swift
    Form {
        Section(header: Text("About")) {
            Text("App description...")
        }
        Section(header: Text("Settings")) {
            Toggle("Enable notifications", isOn: $enableNotifications)
        }
    }
    ```
  - Created reusable view components with proper semantics:
    ```swift
    ViewBuilders.emptyState(
        systemName: "video.badge.plus",
        message: "No videos found"
    ) {
        Button("Add Video") { /* action */ }
    }
    ```