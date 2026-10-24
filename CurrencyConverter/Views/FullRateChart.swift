import SwiftUI
import Charts

/// 近一周 USD→CNY 完整图卡（带统计、日日期轴、更完整刻度）
struct FullRateChart: View {
    let points: [RatePoint]
    var height: CGFloat = 210

    private let yStep = 0.005
    private let maxTicks = 8

    private var minValue: Double? { points.map(\.usdToCny).min() }
    private var maxValue: Double? { points.map(\.usdToCny).max() }

    private var yDomain: ClosedRange<Double> {
        guard let lo = minValue, let hi = maxValue else { return 6.65...6.70 }
        let start = floor(lo / yStep) * yStep
        let end = ceil(hi / yStep) * yStep
        var lower = start
        var upper = end
        let minSpan = yStep * 6
        let maxSpan = yStep * 10
        if upper - lower < minSpan {
            let mid = (lower + upper) / 2
            lower = floor((mid - minSpan / 2) / yStep) * yStep
            upper = lower + minSpan
        }
        if upper - lower > maxSpan {
            let mid = (lower + upper) / 2
            lower = floor((mid - maxSpan / 2) / yStep) * yStep
            upper = lower + maxSpan
        }
        return lower...upper
    }

    private var yTicks: [Double] {
        let span = yDomain.upperBound - yDomain.lowerBound
        let rawCount = Int((span / yStep).rounded()) + 1
        let strideN = max(1, Int(ceil(Double(rawCount) / Double(maxTicks))))
        var ticks: [Double] = []
        var i = 0
        var v = yDomain.lowerBound
        while v <= yDomain.upperBound + 1e-9 {
            if i % strideN == 0 {
                ticks.append((v * 1000).rounded() / 1000)
            }
            v += yStep
            i += 1
        }
        return ticks
    }


    /// X 轴要标出的日期：点少全标，点多抽稀，但始终含头尾
    private var xLabelDates: [Date] {
        let dates = points.map(\.date)
        guard dates.count > 4 else { return dates }
        var result: [Date] = [dates.first!]
        for (i, d) in dates.enumerated() where i % 2 == 1 && i < dates.count - 1 {
            result.append(d)
        }
        result.append(dates.last!)
        return result
    }

    private var firstPoint: RatePoint? { points.first }
    private var lastPoint: RatePoint? { points.last }

    private var changeText: String? {
        guard let a = firstPoint, let b = lastPoint, a.usdToCny > 0 else { return nil }
        let pct = (b.usdToCny - a.usdToCny) / a.usdToCny * 100
        let sign = pct >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, pct)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("美元兑人民币 · 近一周")
                    .font(.subheadline.weight(.semibold))
                Text("1 USD → CNY · 每日中间价")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let a = firstPoint, let b = lastPoint {
                HStack(spacing: 16) {
                    statView(title: "周初", date: a.date, value: a.usdToCny)
                    Divider().frame(height: 28)
                    statView(title: "最新", date: b.date, value: b.usdToCny)
                    Divider().frame(height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("涨跌幅")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let changeText {
                            Text(changeText)
                                .font(.title3.weight(.semibold).monospacedDigit())
                                .foregroundStyle(changeText.hasPrefix("+") ? .green : .red)
                        } else {
                            Text("—")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        Text("较周初")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            if points.isEmpty {
                Text("暂无历史数据")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, minHeight: height)
            } else {
                Chart(points) { p in
                    LineMark(
                        x: .value("日期", p.date),
                        y: .value("汇率", p.usdToCny)
                    )
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

                    AreaMark(
                        x: .value("日期", p.date),
                        yStart: .value("下限", yDomain.lowerBound),
                        yEnd: .value("汇率", p.usdToCny)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.accentColor.opacity(0.20), Color.accentColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    ForEach(points) { p in
                        PointMark(
                            x: .value("日期", p.date),
                            y: .value("汇率", p.usdToCny)
                        )
                        .foregroundStyle(Color.accentColor)
                        .symbolSize(36)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: xLabelDates) { value in
                        AxisGridLine().foregroundStyle(.clear)
                        AxisTick().foregroundStyle(.clear)
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                // 完整日期：10/17 这种两位月日，不截断
                                Text(date, format: .dateTime.month(.twoDigits).day(.twoDigits))
                                    .font(.caption2.monospacedDigit())
                                    .fixedSize()
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: yTicks) { value in
                        AxisGridLine().foregroundStyle(.quaternary)
                        AxisTick().foregroundStyle(.clear)
                        AxisValueLabel() {
                            if let v = value.as(Double.self) {
                                Text(String(format: "%.4f", v))
                                    .font(.caption2.monospacedDigit())
                            }
                        }
                    }
                }
                .chartYScale(
                    domain: yDomain,
                    range: .plotDimension(padding: 10)
                )
                .chartXScale(range: .plotDimension(padding: 22))
                .chartPlotStyle { plot in
                    plot.clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .frame(height: height)
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func statView(title: String, date: Date, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(format: "%.4f", value))
                .font(.title3.weight(.semibold).monospacedDigit())
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            FullRateChart(points: [
                RatePoint(date: .now.addingTimeInterval(-86400 * 6), usdToCny: 6.680),
                RatePoint(date: .now.addingTimeInterval(-86400 * 5), usdToCny: 6.676),
                RatePoint(date: .now.addingTimeInterval(-86400 * 4), usdToCny: 6.670),
                RatePoint(date: .now.addingTimeInterval(-86400 * 3), usdToCny: 6.674),
                RatePoint(date: .now.addingTimeInterval(-86400 * 2), usdToCny: 6.678),
                RatePoint(date: .now.addingTimeInterval(-86400), usdToCny: 6.686),
            ])
        }
        .padding()
    }
}
