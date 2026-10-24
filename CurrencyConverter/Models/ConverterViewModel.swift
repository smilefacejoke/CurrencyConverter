import Foundation
import Observation

@MainActor
@Observable
final class ConverterViewModel {
    var amountText: String = "100"
    var isUSDToCNY: Bool = false
    var rate: ExchangeRate?
    var isLoading: Bool = false
    var errorMessage: String?
    var isOfflineFallback: Bool = false

    private let service = ExchangeRateService()

    var sourceCurrency: Currency { isUSDToCNY ? .usd : .cny }
    var targetCurrency: Currency { isUSDToCNY ? .cny : .usd }

    var amountValue: Double {
        Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    /// 固定方向：1 USD = ? CNY（不随换算方向切换）
    var usdToCny: ExchangeRate? {
        guard let rate else { return nil }
        return rate.base == .usd && rate.quote == .cny ? rate : rate.inverted
    }

    /// 计算汇率：1 USD = ? CNY，保留 1 位小数，最后一位向下取整
    var calculationRate: Double? {
        guard let usd = usdToCny, usd.rate > 0 else { return nil }
        return (usd.rate * 10).rounded(.down) / 10
    }

    var calculationRateDisplay: String? {
        guard let calc = calculationRate else { return nil }
        return String(format: "%.1f", calc)
    }

    /// 金额换算统一使用计算汇率（而非实时精确汇率）
    var convertedAmount: Double? {
        guard let calc = calculationRate, calc > 0 else { return nil }
        if isUSDToCNY {
            return amountValue * calc
        } else {
            return amountValue / calc
        }
    }

    /// 当前换算方向下的计算汇率（展示用）
    var displayRate: ExchangeRate {
        guard let calc = calculationRate else {
            return ExchangeRate(base: sourceCurrency, quote: targetCurrency, rate: 0, date: Date(), fetchedAt: Date())
        }
        let value = isUSDToCNY ? calc : (1 / calc)
        return ExchangeRate(base: sourceCurrency, quote: targetCurrency, rate: value, date: Date(), fetchedAt: Date())
    }

    func loadOnAppear() {
        if let cached = service.cachedRate() {
            rate = cached
            isOfflineFallback = true
        }
        Task { await refresh() }
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched = try await service.fetchCNYToUSD()
            rate = fetched
            isOfflineFallback = false
        } catch {
            if rate == nil {
                errorMessage = error.localizedDescription
            } else {
                // 已有缓存时静默保持离线数据，仅标记
                isOfflineFallback = true
            }
        }
    }

    func swap() {
        isUSDToCNY.toggle()
        if let amount = convertedAmount {
            amountText = Self.formatInput(amount)
        }
    }

    static func formatInput(_ value: Double) -> String {
        if value == value.rounded() && abs(value) < 1e15 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }

    static func formatOutput(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
