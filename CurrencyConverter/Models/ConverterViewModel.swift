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

    var convertedAmount: Double? {
        guard let rate else { return nil }
        let pair = displayRate
        return amountValue * pair.rate
    }

    /// 当前方向下的 1 单位汇率
    var displayRate: ExchangeRate {
        guard let rate else {
            return ExchangeRate(base: sourceCurrency, quote: targetCurrency, rate: 0, date: Date(), fetchedAt: Date())
        }
        if rate.base == sourceCurrency && rate.quote == targetCurrency {
            return rate
        }
        return rate.inverted
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
