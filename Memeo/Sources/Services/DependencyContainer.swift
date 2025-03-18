import Foundation

final class DependencyContainer {
    static let shared = DependencyContainer()
    private var services: [String: Any] = [:]
    
    func register<T>(_ service: T) {
        services[String(describing: T.self)] = service
    }
    
    func resolve<T>() -> T {
        guard let service = services[String(describing: T.self)] as? T else {
            fatalError("Service \(T.self) not registered")
        }
        return service
    }
}