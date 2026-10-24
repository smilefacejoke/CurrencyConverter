import Foundation

enum RateError: LocalizedError {
    case network(Error)
    case badResponse
    case missingRate

    var errorDescription: String? {
        switch self {
        case .network(let error):
            return "网络请求失败：\(error.localizedDescription)"
        case .badResponse:
            return "汇率服务返回了无法解析的数据"
        case .missingRate:
            return "汇率数据中缺少目标货币"
        }
    }
}

/// 从 Frankfurter（ECB 数据，免费无 key）拉取汇率，失败时回落到本地缓存
struct ExchangeRateService: Sendable {
    private let session: URLSession
    private let cache: RateCache

    init(session: URLSession = .shared, cache: RateCache = RateCache()) {
        self.session = session
        self.cache = cache
    }

    /// 获取 CNY→USD 汇率；网络失败时返回缓存（若存在）
    func fetchCNYToUSD() async throws -> ExchangeRate {
        do {
            let rate = try await request(base: .cny, quote: .usd)
            cache.save(rate)
            return rate
        } catch {
            if let cached = cache.load() {
                return cached
            }
            throw error
        }
    }

    /// 只读缓存，不发网络请求
    func cachedRate() -> ExchangeRate? {
        cache.load()
    }

    // MARK: - Network

    private struct FrankfurterResponse: Decodable {
        let amount: Double
        let base: String
        let date: String
        let rates: [String: Double]
    }

    private func request(base: Currency, quote: Currency) async throws -> ExchangeRate {
        var components = URLComponents(string: "https://api.frankfurter.dev/v1/latest")!
        components.queryItems = [
            URLQueryItem(name: "from", value: base.rawValue),
            URLQueryItem(name: "to", value: quote.rawValue),
        ]
        guard let url = components.url else { throw RateError.badResponse }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw RateError.network(error)
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw RateError.badResponse
        }

        let decoded: FrankfurterResponse
        do {
            decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        } catch {
            throw RateError.badResponse
        }

        guard let value = decoded.rates[quote.rawValue] else {
            throw RateError.missingRate
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let rateDate = formatter.date(from: decoded.date) ?? Date()

        return ExchangeRate(
            base: base,
            quote: quote,
            rate: value / decoded.amount,
            date: rateDate,
            fetchedAt: Date()
        )
    }
}
