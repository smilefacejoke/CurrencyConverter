import Foundation

/// 离线缓存：把最近一次成功获取的汇率落到磁盘，无网时读取
struct RateCache: Sendable {
    private let fileURL: URL

    init(filename: String = "cached_exchange_rate.json") {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent(filename)
    }

    func load() -> ExchangeRate? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ExchangeRate.self, from: data)
    }

    func save(_ rate: ExchangeRate) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(rate) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - History cache

    private var historyURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("cached_rate_history.json")
    }

    func loadHistory() -> [RatePoint]? {
        guard let data = try? Data(contentsOf: historyURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([RatePoint].self, from: data)
    }

    func saveHistory(_ points: [RatePoint]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(points) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }

}
