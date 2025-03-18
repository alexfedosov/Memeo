# Memeo App Development Guide

## Project Information
- Swift iOS application for video editing with tracker overlays
- Uses SwiftUI, AVFoundation, and FFmpeg for video processing
- Modern Swift architecture with MVVM pattern

## Code Style & Patterns
- Use MVVM architecture for all views
- State variables should use `@Published private(set)` pattern
- Use modern Swift concurrency with async/await when possible
- Replace older Combine patterns with `AsyncStream` and `Task`
- Use Task groups for managing concurrent tasks
- Always ensure weak references in closures and Task bodies to prevent memory leaks

## Commands
- To build: Xcode build process (Command+B)
- To run: Xcode run button (Command+R)
- To test: TODO - Add test commands when they are established

## Recent Changes
- Replaced Combine `.sink` patterns with modern Swift concurrency using `AsyncStream` and `Task`
- Added proper task cancellation in deinit methods
- Used modern SwiftUI patterns for state management

## Next Tasks
- Use property wrappers more consistently across ViewModels
- Replace custom GradientBorderButton with SwiftUI's native ButtonStyle protocol
- Avoid direct UIKit interop in favor of SwiftUI components where possible