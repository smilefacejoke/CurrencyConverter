import Foundation

/// 近 N 天 1 USD = ? CNY 的一个点
struct RatePoint: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let date: Date
    let usdToCny: Double

    init(date: Date, usdToCny: Double) {
        self.id = UUID()
        self.date = date
        self.usdToCny = usdToCny
    }
}

struct RateHistory: Codable, Equatable, Sendable {
    let points: [RatePoint]
    let fetchedAt: Date

    /// 用于缓存的可编码点（id 由解码侧重建）
    struct StoredPoint: Codable {
        let date: Date
        let usdToCny: Double
    }
}
