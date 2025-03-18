# Codebase Improvement Task Template

## Overview

This template provides a structured approach for implementing todo items from the improvement roadmap. Follow this process for any task, adapting the specific requirements to match the current task's needs.

## General Process

### 1. Preparation
- Identify the next unfinished task from todo.txt
- Understand the purpose and expected outcomes 
- Review existing code related to the task
- Create a feature branch with descriptive name

### 2. Implementation
- Start with a minimal change to establish the pattern
- Follow iterative development with atomic, focused commits
- Test changes frequently to catch issues early
- Update related components as needed
- Document new patterns in knowledge.md

### 3. Quality Assurance
- Ensure code meets Swift 6 compatibility requirements
- Validate changes against modern Swift best practices
- Fix any warnings or potential issues
- Run tests if available

### 4. Documentation & Completion
- Update knowledge.md with learnings and new patterns
- Mark completed tasks in todo.txt
- Create a detailed pull request
- Record any follow-up tasks for future improvement

## Task-Specific Patterns

### MVVM Architecture Implementation
- Use `@Published private(set) var` for all state properties
- Create explicit methods for state changes
- Follow immutable copy-modify-replace pattern:
  ```swift
  var updatedModel = model
  updatedModel.property = newValue
  model = updatedModel
  ```
- Ensure View only observes ViewModel, never modifies it directly

### Actor Isolation & Concurrency
- Mark appropriate classes with `@MainActor`
- Create bridge classes for delegates that cross actor boundaries
- Use weak references to prevent retain cycles
- Handle MainActor dispatch properly for UI updates
- Store delegates as properties to prevent premature deallocation

### Dependency Injection
- Inject services through initializers
- Use protocols to define service interfaces
- Create factory classes/methods for complex object creation
- Implement proper DI container if needed

### UI Improvements
- Follow SwiftUI best practices
- Create reusable components
- Use proper view modifiers
- Implement accessibility support
- Handle different device sizes appropriately

### Service Layer Enhancements
- Use modern async/await APIs
- Implement proper error handling
- Create clear service boundaries
- Apply appropriate design patterns
- Add proper documentation

## Success Criteria

- Code follows the established architectural patterns
- No warnings or errors with Swift 6
- Clean separation of concerns
- Clear and consistent naming conventions
- Documentation reflects the changes made
- Task is properly marked as completed in todo.txt
- Commits are created on a separate branch from main
