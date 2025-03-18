import SwiftUI

// MARK: - Generic View Builders

/// A collection of reusable ViewBuilder functions for creating common UI patterns
struct ViewBuilders {
    
    /// Creates a standard loading overlay with text and a progress indicator
    /// - Parameter text: The text to display in the loading overlay
    /// - Returns: A view containing a blur effect with loading indicator
    @ViewBuilder
    static func loadingOverlay(text: String) -> some View {
        ZStack {
            VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterialDark))
                .ignoresSafeArea()
            HStack {
                Text(text).font(.title3)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding(.leading)
            }
            .padding()
        }
    }
    
    /// Creates a conditional view that shows different content based on state
    /// - Parameters:
    ///   - condition: The condition to evaluate
    ///   - trueContent: The content to show when condition is true
    ///   - falseContent: The content to show when condition is false
    /// - Returns: Either the trueContent or falseContent based on condition
    @ViewBuilder
    static func conditional<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        @ViewBuilder trueContent: () -> TrueContent,
        @ViewBuilder falseContent: () -> FalseContent
    ) -> some View {
        if condition {
            trueContent()
        } else {
            falseContent()
        }
    }
    
    /// Creates a bordered container with standard styling
    /// - Parameters:
    ///   - title: Optional title for the container
    ///   - content: The content to display inside the container
    /// - Returns: A styled container view
    @ViewBuilder
    static func borderedContainer<Content: View>(
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .padding(.leading)
            }
            
            content()
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    /// Creates an empty state placeholder with an icon and message
    /// - Parameters:
    ///   - systemName: SF Symbol name for the icon
    ///   - message: The message to display
    ///   - action: Optional action button to show
    /// - Returns: A styled empty state view
    @ViewBuilder
    static func emptyState<ActionContent: View>(
        systemName: String,
        message: String,
        @ViewBuilder action: () -> ActionContent = { EmptyView() }
    ) -> some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: systemName)
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.7))
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal)
            
            action()
            
            Spacer()
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a conditional modifier based on condition
    /// - Parameters:
    ///   - condition: Boolean condition to check
    ///   - transform: The transform to apply if condition is true
    /// - Returns: Modified view if condition is true, otherwise original view
    @ViewBuilder
    func conditionalModifier<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Adds a standard loading overlay with custom text if the condition is true
    /// - Parameters:
    ///   - isLoading: Whether to show the loading overlay
    ///   - text: The text to display in the loading overlay
    /// - Returns: Modified view with loading overlay if isLoading is true
    @ViewBuilder
    func loadingOverlay(isLoading: Bool, text: String = "Loading...") -> some View {
        ZStack {
            self
            
            if isLoading {
                ViewBuilders.loadingOverlay(text: text)
            }
        }
    }
}