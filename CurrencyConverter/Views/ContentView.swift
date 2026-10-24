import SwiftUI

struct ContentView: View {
    @State private var model = ConverterViewModel()
    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    calculationRateBanner
                    amountCard
                    resultCard
                    FullRateChart(points: model.history)
                    rateFooter
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("人民币美元转换")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await model.refresh() }
                    } label: {
                        if model.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(model.isLoading)
                }
            }
            .task {
                model.loadOnAppear()
                amountFocused = true
            }
            .refreshable { await model.refresh() }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("实时汇率 · 离线可用")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if model.isOfflineFallback {
                Label("当前为离线缓存汇率", systemImage: "wifi.slash")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.12), in: Capsule())
            }
            if let error = model.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var calculationRateBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("计算汇率")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let calc = model.calculationRateDisplay {
                    Text("1 USD = \(calc) CNY")
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                } else {
                    Text("1 USD = — CNY")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text("向下取整")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.12), in: Capsule())
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("输入金额")
                    .font(.headline)
                Spacer()
                Text(model.sourceCurrency.displayName + model.sourceCurrency.symbol)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Text(model.sourceCurrency.symbol)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                TextField("0", text: $model.amountText)
                    // decimalPad 在模拟器 + 硬件键盘下经常收不到按键
                    .keyboardType(.numbersAndPunctuation)
                    .textContentType(.none)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .focused($amountFocused)

                Button {
                    model.swap()
                    amountFocused = false
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("交换币种")
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("换算结果")
                    .font(.headline)
                Spacer()
                Text(model.targetCurrency.displayName + model.targetCurrency.symbol)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(model.targetCurrency.symbol)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.tint)
                if let value = model.convertedAmount {
                    Text(ConverterViewModel.formatOutput(value))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.snappy, value: value)
                } else {
                    Text("—")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var rateFooter: some View {
        // 固定显示 1 USD = ? CNY，不随换算方向变化
        let usd = model.usdToCny
        return VStack(spacing: 10) {
            if let usd, usd.rate > 0 {
                Text("真实汇率 1 USD = \(String(format: "%.4f", usd.rate)) CNY")
                    .font(.callout.weight(.medium))

                Text("汇率日期：\(usd.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("更新于：\(usd.fetchedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("下拉或点击刷新获取汇率")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
