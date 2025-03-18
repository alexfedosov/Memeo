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

- `/Memeo/Sources/Home/` - Home screen implementation
- `/Memeo/Sources/VideoEditor/` - Video editor implementation
- `/Memeo/Sources/Models/` - Model definitions
- `/Memeo/Sources/Services/` - Services for data handling
- `/Memeo/Sources/Utils/` - Utility extensions and helpers
- `/Memeo/Sources/CommonComponents/` - Reusable UI components

## Key Components

### Document
Main model representing a video with trackers and animations.

### Tracker
Represents an overlay on the video with position, style, and animations.

### Animation
Generic animation system for various properties like position, opacity, etc.

## To-Do Items Status

1. ✅ Implement proper MVVM architecture
   - ✅ Refactor HomeViewModel with proper @Published private(set) properties
   - ✅ Update Home.swift to use @ObservedObject instead of @StateObject
   - [ ] Apply MVVM to VideoEditor components

2. [ ] Move ViewModel initialization to a factory/coordinator pattern

3. [ ] Reorganize file structure to better separate features

4. [ ] Create a centralized dependency injection system

5. [ ] Consolidate duplicated view components and utilities

... [more items]