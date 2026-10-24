import Foundation

/// 汇率快照：1 单位 base 货币可兑换 rate 单位 quote 货币
struct ExchangeRate: Codable, Equatable, Sendable {
    let base: Currency
    let quote: Currency
    let rate: Double
    let date: Date
    let fetchedAt: Date

    var inverted: ExchangeRate {
        ExchangeRate(
            base: quote,
            quote: base,
            rate: rate == 0 ? 0 : 1 / rate,
            date: date,
            fetchedAt: fetchedAt
        )
    }

    /// amount 单位 base 货币 → quote 货币
    func convert(_ amount: Double) -> Double {
        amount * rate
    }
}

enum Currency: String, Codable, CaseIterable, Sendable {
    case cny = "CNY"
    case usd = "USD"

    var displayName: String {
        switch self {
        case .cny: return "人民币"
        case .usd: return "美元"
        }
    }

    var symbol: String {
        switch self {
        case .cny: return "¥"
        case .usd: return "$"
        }
    }
}
