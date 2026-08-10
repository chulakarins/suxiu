import Foundation
import Combine

// 简单的数据模型，兼容iOS 14.0
final class Item: ObservableObject {
    @Published var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
