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

## Implementation Notes

### Modern Swift Best Practices

- Use Swift's automatic Hashable synthesis where possible instead of manual implementations
- Apply `@frozen` to enums that are part of your app's ABI and won't change
- Centralize related types (like CGPoint, CGSize) in appropriately named extension files
- Use proper file naming conventions based on content (CoreGraphicsExtensions vs CGPointExtensions)
- Document public APIs with proper documentation comments
- Follow Swift API Design Guidelines for clean, consistent code

### VideoEditorViewModel Refactoring

- Added `private(set)` to all published properties
- Introduced proper state modification methods (setIsPlaying, setIsEditingText, etc.)
- Created custom bindings in the view for read-only or computed properties
- Improved error handling with more explicit guard clauses
- Added proper service dependency injection
- Organized code with MARK comments for better readability
- Implemented async/await for cleanDocumentsDirectory operation

... [more items]