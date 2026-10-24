import SwiftUI
import Charts

/// 近一周 USD→CNY 紧凑折线图
struct MiniRateChart: View {
    let points: [RatePoint]
    var height: CGFloat = 104

    private var minValue: Double? { points.map(\.usdToCny).min() }
    private var maxValue: Double? { points.map(\.usdToCny).max() }

    /// 刻度步长：0.005，但只画少量主线，避免标签叠在一起
    private let yStep = 0.005
    /// Y 轴最多显示的主刻度数（含上下限）
    private let maxTicks = 6

    private var yDomain: ClosedRange<Double> {
        guard let lo = minValue, let hi = maxValue, lo.isFinite, hi.isFinite else {
            return 6.65...6.70
        }
        // 贴着数据取整到 0.005，上下留半格即可（不要大 padding）
        let start = floor(lo / yStep) * yStep
        let end = ceil(hi / yStep) * yStep
        var lower = start
        var upper = end
        // 至少 4 个小格（0.02），最多约 6 个小格（0.03），防止格子爆炸
        let minSpan = yStep * 4
        let maxSpan = yStep * 6
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

    /// 主刻度：在 0.005 网格上抽稀，保证不超过 maxTicks 条
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
        // 确保上下限一定有标签
        if ticks.first != yDomain.lowerBound {
            ticks.insert((yDomain.lowerBound * 1000).rounded() / 1000, at: 0)
        }
        if ticks.last != yDomain.upperBound {
            ticks.append((yDomain.upperBound * 1000).rounded() / 1000)
        }
        return ticks
    }


    /// 折线头、尾两个日期（用于 X 轴标签）
    private var xEdgeDates: [Date] {
        guard let first = points.first?.date, let last = points.last?.date else { return [] }
        if first == last { return [first] }
        return [first, last]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("近一周 · 1 USD → CNY")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let first = points.first {
                    Text(String(format: "%.3f", first.usdToCny))
                        .font(.caption2.weight(.medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                if let first = points.first, let last = points.last, first != last {
                    Text("→")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(String(format: "%.3f", last.usdToCny))
                        .font(.caption2.weight(.medium).monospacedDigit())
                        .foregroundStyle(.secondary)
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
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    AreaMark(
                        x: .value("日期", p.date),
                        y: .value("汇率", p.usdToCny)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [Color.accentColor.opacity(0.22), Color.accentColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    if let first = points.first {
                        PointMark(
                            x: .value("日期", first.date),
                            y: .value("汇率", first.usdToCny)
                        )
                        .foregroundStyle(Color.accentColor)
                        .symbolSize(24)
                    }

                    if let last = points.last {
                        PointMark(
                            x: .value("日期", last.date),
                            y: .value("汇率", last.usdToCny)
                        )
                        .foregroundStyle(Color.accentColor)
                        .symbolSize(24)
                    }
                }
                .chartXAxis {
                    // 只标折线头尾日期
                    AxisMarks(values: xEdgeDates) { _ in
                        AxisGridLine().foregroundStyle(.clear)
                        AxisTick().foregroundStyle(.clear)
                        AxisValueLabel(format: .dateTime.month(.twoDigits).day(.twoDigits))
                            .font(.caption2.monospacedDigit())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: yTicks) { value in
                        AxisGridLine().foregroundStyle(.quaternary)
                        AxisTick().foregroundStyle(.clear)
                        AxisValueLabel() {
                            if let v = value.as(Double.self) {
                                // 保留三位小数
                                Text(String(format: "%.3f", v))
                                    .font(.caption2.monospacedDigit())
                            }
                        }
                    }
                }
                .chartYScale(
                    domain: yDomain,
                    range: .plotDimension(padding: 8)
                )
                .chartXScale(range: .plotDimension(padding: 12))
                // 裁掉绘图区，防止面积蓝色溢出到卡片外
                .chartPlotStyle { plot in
                    plot
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .frame(height: height)
                .padding(.bottom, 4)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    MiniRateChart(points: [
        RatePoint(date: .now.addingTimeInterval(-86400 * 6), usdToCny: 6.68),
        RatePoint(date: .now.addingTimeInterval(-86400 * 5), usdToCny: 6.67),
        RatePoint(date: .now.addingTimeInterval(-86400 * 4), usdToCny: 6.66),
        RatePoint(date: .now.addingTimeInterval(-86400 * 3), usdToCny: 6.67),
        RatePoint(date: .now.addingTimeInterval(-86400 * 2), usdToCny: 6.67),
        RatePoint(date: .now.addingTimeInterval(-86400), usdToCny: 6.67),
    ])
    .padding()
}
