import Foundation

class EventBus: EventBusProtocol {
    private var handlers: [String: [(UUID, (Any) -> Void)]] = [:]
    private let lock = NSLock()
    
    func publish(_ event: Any) {
        let typeName = String(describing: type(of: event))
        lock.lock()
        let handlersCopy = handlers[typeName] ?? []
        lock.unlock()
        for (_, handler) in handlersCopy {
            handler(event)
        }
    }
    
    func subscribe<T>(_ type: T.Type, handler: @escaping (T) -> Void) -> AnyCancellable {
        let typeName = String(describing: type)
        let id = UUID()
        lock.lock()
        var list = handlers[typeName] ?? []
        list.append((id, { obj in if let t = obj as? T { handler(t) } }))
        handlers[typeName] = list
        lock.unlock()
        return id
    }
    
    func unsubscribe(id: AnyCancellable, type: Any.Type) {
        let typeName = String(describing: type)
        lock.lock()
        handlers[typeName] = handlers[typeName]?.filter { $0.0 != id }
        lock.unlock()
    }
}
