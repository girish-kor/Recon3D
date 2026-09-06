import Foundation

func encodeCodable<T: Codable>(_ value: T) -> Data? {
    try? JSONEncoder().encode(value)
}
func decodeCodable<T: Codable>(_ type: T.Type, from data: Data) -> T? {
    try? JSONDecoder().decode(type, from: data)
}
