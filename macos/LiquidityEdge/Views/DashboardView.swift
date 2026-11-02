import SwiftUI

struct DashboardView: View {
    @Environment(JournalStore.self) private var store
    var openTrade: (TradeRecord) -> Void
    var newTrade: () -> Void
    var openDemo: (() -> Void)? = nil
    @State private var period = "ALL TIME"
    @State private var curveMode = CurveMode.dollars
    private var trades: [TradeRecord] {
        let c = store.preferences.calendar
        let component: Calendar.Component? = period == "TODAY" ? .day : period == "THIS WEEK" ? .weekOfYear : period == "THIS MONTH" ? .month : nil
        guard let component, let interval = c.dateInterval(of: component, for: Date()) else { return store.trades }
        return store.trades.filter { $0.date >= interval.start && $0.date < interval.end }
    }
    var body: some View {
        let data = trades, p = AnalyticsEngine.performance(data), curve = AnalyticsEngine.curve(data)
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .bottom, spacing: 24) { header; Spacer(minLength: 0); periodPicker }
                    VStack(alignment: .leading, spacing: 20) { header; periodPicker }
                }
                summaryMetrics(p, empty: data.isEmpty)
                if store.trades.isEmpty { welcome }
                else if data.isEmpty {
                    Panel { EmptyJournal(title: "Bu dönemde işlem yok", subtitle: "Diğer dönemlerdeki kayıtlarınızı görmek için zaman aralığını değiştirin.", actionTitle: "Tüm zamanı göster", action: { period = "ALL TIME" }) }
                } else {
                    disciplineBanner(p, data: data)
                    DashboardChartCard(title: "Sermaye gelişimi", subtitle: "Kapanan işlemler · Komisyon ve masraflar sonrası", symbol: "chart.xyaxis.line", accent: Palette.mint, prominent: true) {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .bottom, spacing: 24) { curveSummary(p); Spacer(minLength: 16); curveControls }
                            VStack(alignment: .leading, spacing: 20) { curveSummary(p); curveControls }
                        }
                        EquityChart(points: curve, mode: curveMode, accountSize: store.preferences.accountSize, height: 280, presentation: .dashboard)
                        HStack(spacing: 0) {
                            chartFootnote("Başlangıç bakiyesi", value: Format.money(store.preferences.accountSize, currency: store.preferences.currency), symbol: "circle.dotted")
                            Spacer(minLength: 18)
                            Rectangle().fill(Palette.muted.opacity(0.14)).frame(width: 1, height: 25)
                            Spacer(minLength: 18)
                            chartFootnote("İşlem sayısı", value: p.count.description, symbol: "list.bullet.rectangle")
                            Spacer(minLength: 18)
                            Rectangle().fill(Palette.muted.opacity(0.14)).frame(width: 1, height: 25)
                            Spacer(minLength: 18)
                            chartFootnote("Görüntülenen dönem", value: L10n.text(period), symbol: "calendar")
                        }.padding(.horizontal, 16).padding(.vertical, 14).background(Palette.canvas.opacity(0.42), in: RoundedRectangle(cornerRadius: 11))
                    }
                    HStack(alignment: .top, spacing: 16) {
                        Panel(title: "EXECUTION QUALITY") {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(Format.number(p.executionScore, digits: 0)).font(.system(size: 43, weight: .semibold, design: .rounded)).tracking(-1.5).monospacedDigit()
                                Text(L10n.text("/ 100")).font(.system(size: 13)).foregroundStyle(Palette.muted)
                                Spacer()
                                Image(systemName: "scope").font(.system(size: 31, weight: .light)).foregroundStyle(Palette.mint.opacity(0.75))
                            }
                            ProgressView(value: p.executionScore, total: 100).tint(Palette.mint).accessibilityLabel(L10n.text("EXECUTION QUALITY"))
                            HStack { Text(L10n.text("A+ setup win rate")); Spacer(); Text(p.aPlusWinRate.map(Format.percent) ?? "—").monospacedDigit().fontWeight(.semibold) }.font(.system(size: 11)).foregroundStyle(Palette.muted)
                        }
                        Panel(title: "PROCESS / OUTCOME") {
                            VStack(spacing: 12) {
                                ForEach([Classification.validWinner, .validLoser, .invalidWinner, .invalidLoser], id: \.self) { type in
                                    let count = data.filter { $0.classification == type }.count
                                    HStack(spacing: 10) {
                                        RoundedRectangle(cornerRadius: 2).fill(Palette.classification(type)).frame(width: 4, height: 16)
                                        Text(L10n.text(type.rawValue)).font(.system(size: 11))
                                        Spacer()
                                        Text(count.description).font(.system(size: 12, weight: .semibold, design: .monospaced)).monospacedDigit()
                                        Text(Format.percent(Double(count) / Double(data.count) * 100)).font(.system(size: 10)).monospacedDigit().foregroundStyle(Palette.muted).frame(width: 48, alignment: .trailing)
                                    }.accessibilityElement(children: .combine)
                                }
                            }
                        }
                    }
                    DashboardChartCard(title: "Zamanlama haritası", subtitle: "Gün ve saate göre ortalama R", symbol: "square.grid.3x3", accent: Palette.blue) {
                        PerformanceHeatmap(trades: data, calendar: store.preferences.calendar)
                    }
                    HStack(alignment: .top, spacing: 16) {
                        DashboardChartCard(title: "Birikimli R", subtitle: "Risk birimiyle performans", symbol: "chart.line.uptrend.xyaxis", accent: Palette.mint) {
                            companionSummary(p.rCount > 0 ? Format.r(p.totalR) : "—", caption: "Toplam R", color: p.rCount > 0 ? Palette.outcome(p.totalR) : Palette.muted)
                            EquityChart(points: curve, mode: .r, height: 190, presentation: .dashboard)
                        }
                        DashboardChartCard(title: "Sermaye gerilemesi", subtitle: "Zirveden uzaklaşma", symbol: "chart.line.downtrend.xyaxis", accent: Palette.red) {
                            companionSummary(Format.money(p.maxDrawdown, currency: store.preferences.currency), caption: "Maksimum gerileme", color: Palette.red)
                            EquityChart(points: curve, mode: .drawdown, height: 190, presentation: .dashboard)
                        }
                    }
                    DashboardChartCard(title: "Hareketli kazanma oranı", subtitle: "Son 20 işlem · İlk 20 işlemde mevcut örneklem", symbol: "percent", accent: Palette.blue) {
                        HStack(alignment: .firstTextBaseline) {
                            companionSummary(curve.last.map { Format.percent($0.rollingWinRate) } ?? "—", caption: "Son pencere", color: Palette.blue)
                            Spacer()
                            Label("20 işlemlik pencere", systemImage: "line.3.horizontal.decrease").font(.system(size: 10, weight: .medium)).foregroundStyle(Palette.muted)
                        }
                        EquityChart(points: Array(curve.dropFirst()), mode: .rolling, height: 180, presentation: .dashboard)
                    }
                    Panel(title: "RECENT EXECUTIONS", subtitle: "PROCESS > OUTCOME") { TradeRows(trades: Array(data.prefix(6)), openTrade: openTrade) }
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeading("Performansın ayrıntıları", subtitle: "Her ölçüm, seçili dönemdeki kayıtlarınızdan hesaplanır.")
                        MetricsGrid(performance: p, currency: store.preferences.currency)
                    }.padding(.top, 6)
                }
                HStack(spacing: 7) {
                    Image(systemName: "lock.shield").foregroundStyle(Palette.mint)
                    Text(store.isDemo ? "Örnek veriler gösteriliyor · Kalıcı günlüğünüz ayrı tutulur" : "Yerel günlük · Verileriniz bu Mac’te saklanır")
                    Spacer()
                    Text(Format.date(Date(), calendar: store.preferences.calendar))
                }.font(.system(size: 10)).foregroundStyle(Palette.muted).padding(.top, 3)
            }.pagePadding()
        }.scrollIndicators(.automatic)
    }
    private var header: some View {
        PageHeader(eyebrow: "Performance overview", title: "Process is the edge.", subtitle: "Professional Trading Performance Journal")
    }
    private var periodPicker: some View {
        SegmentedTabs(options: ["TODAY", "THIS WEEK", "THIS MONTH", "ALL TIME"], selection: $period, title: { $0 }).accessibilityLabel(L10n.text("Dashboard period"))
    }
    private var curvePicker: some View {
        SegmentedTabs(options: [CurveMode.dollars, .r, .percent], selection: $curveMode, title: { $0.rawValue }).accessibilityLabel(L10n.text("Equity curve unit"))
    }
    private var curveControls: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("GÖSTERİM BİRİMİ").font(.system(size: 9, weight: .semibold)).tracking(1.1).foregroundStyle(Palette.muted)
            curvePicker
        }
    }
    private func curveSummary(_ p: Performance) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(curveMode == .r ? "TOPLAM R" : curveMode == .percent ? "NET GETİRİ" : "NET SONUÇ").font(.system(size: 9, weight: .semibold)).tracking(1.3).foregroundStyle(Palette.muted)
            Text(curveMode == .r ? (p.rCount > 0 ? Format.r(p.totalR) : "—") : curveMode == .percent ? Format.percent(p.netPnL / max(store.preferences.accountSize, 0.01) * 100) : Format.money(p.netPnL, currency: store.preferences.currency))
                .font(.system(size: 37, weight: .semibold, design: .rounded)).tracking(-1.3).monospacedDigit().foregroundStyle(curveMode == .r && p.rCount == 0 ? Palette.muted : Palette.outcome(curveMode == .r ? p.totalR : p.netPnL)).lineLimit(1).minimumScaleFactor(0.65)
        }
    }
    private func companionSummary(_ value: String, caption: String, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(verbatim: value).font(.system(size: 25, weight: .semibold, design: .rounded)).tracking(-0.6).monospacedDigit().foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.7)
            Text(caption).font(.system(size: 10)).foregroundStyle(Palette.muted).lineLimit(1)
        }.accessibilityElement(children: .combine)
    }
    private func chartFootnote(_ title: String, value: String, symbol: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: symbol).font(.system(size: 13, weight: .regular)).foregroundStyle(Palette.muted.opacity(0.8))
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 9)).foregroundStyle(Palette.muted)
                Text(verbatim: value).font(.system(size: 11, weight: .semibold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            }
        }.accessibilityElement(children: .combine)
    }
    private func summaryMetrics(_ p: Performance, empty: Bool) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
            MetricCard(title: "Net PnL", value: empty ? "—" : Format.money(p.netPnL, currency: store.preferences.currency), footnote: "After commissions & fees", color: empty ? Palette.ink : Palette.outcome(p.netPnL))
            MetricCard(title: "Total R", value: empty || p.rCount == 0 ? "—" : Format.r(p.totalR), footnote: "\(p.rCount) trades with recorded R", color: empty || p.rCount == 0 ? Palette.ink : Palette.outcome(p.totalR))
            MetricCard(title: "Win rate", value: empty ? "—" : Format.percent(p.winRate), footnote: "\(p.wins) wins / \(p.count) trades")
            MetricCard(title: "Expectancy", value: empty ? "—" : Format.r(p.averageR), footnote: "Expected R per recorded trade", color: empty ? Palette.ink : Palette.outcome(p.averageR ?? 0))
        }
    }
    private func disciplineBanner(_ p: Performance, data: [TradeRecord]) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.shield").font(.system(size: 24, weight: .light)).foregroundStyle(Palette.mint).frame(width: 40, height: 40).background(Palette.mint.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.text("Discipline before dollars.")).font(.system(size: 12, weight: .semibold))
                Text(L10n.text("\(data.filter(\.compliant).count) of \(data.count) trades respected your plan. Review the exceptions.")).font(.system(size: 11)).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Badge(text: "\(Format.percent(p.compliance)) COMPLIANCE", color: p.compliance >= 80 ? Palette.mint : Palette.amber)
        }.padding(16).background(Palette.mint.opacity(0.035), in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.mint.opacity(0.15)))
    }
    private var welcome: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 25) {
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Badge(text: "GÜNLÜĞÜNÜZE HOŞ GELDİNİZ", color: Palette.mint)
                        Text("Her işlemden\ndaha fazlasını öğrenin.").font(.system(size: 34, weight: .semibold)).tracking(-1.2).fixedSize(horizontal: false, vertical: true)
                        Text("İşlemlerinizi, stratejinizi ve kararlarınızı tek bir yerde inceleyin. İlk kaydınızla birlikte performans grafikleriniz oluşmaya başlar.").font(.system(size: 13)).foregroundStyle(Palette.muted).lineSpacing(4).fixedSize(horizontal: false, vertical: true).frame(maxWidth: 530, alignment: .leading)
                    }
                    Spacer(minLength: 0)
                    ZStack {
                        RoundedRectangle(cornerRadius: 25).fill(Palette.mint.opacity(0.055)).frame(width: 118, height: 118)
                        RoundedRectangle(cornerRadius: 25).strokeBorder(Palette.mint.opacity(0.15)).frame(width: 118, height: 118)
                        Image(systemName: "chart.xyaxis.line").font(.system(size: 47, weight: .ultraLight)).foregroundStyle(Palette.mint)
                    }.padding(.top, 19).accessibilityHidden(true)
                }
                HStack(spacing: 11) {
                    Button(action: newTrade) { Label("İlk işlemini kaydet", systemImage: "plus") }.buttonStyle(EdgeButtonStyle())
                    if let openDemo { Button(action: openDemo) { Label("Örnek günlüğü keşfet", systemImage: "sparkles") }.buttonStyle(EdgeButtonStyle(prominent: false)) }
                    Spacer()
                    Text("⌘N").font(.system(size: 11, design: .monospaced)).foregroundStyle(Palette.muted)
                }
                Rectangle().fill(Palette.muted.opacity(0.13)).frame(height: 1)
                HStack(spacing: 9) {
                    Image(systemName: "internaldrive.fill").foregroundStyle(Palette.mint)
                    Text("Veriler bu bilgisayarda kalır. Kayıtlarınızı siz silmedikçe uygulama silmez.").foregroundStyle(Palette.muted)
                }.font(.system(size: 11)).fixedSize(horizontal: false, vertical: true)
            }.padding(30).frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [Palette.panel, Palette.mint.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Palette.mint.opacity(0.16)))
            sectionHeading("Daha bilinçli bir işlem rutini", subtitle: "Kayıtlarınız arttıkça günlüğünüz daha fazla şey anlatır.")
            HStack(alignment: .top, spacing: 14) {
                onboardingCard("01", symbol: "square.and.pencil", title: "İşlemi kaydet", subtitle: "Giriş, risk, strateji ve grafiklerinizi bir araya getirin.")
                onboardingCard("02", symbol: "checkmark.shield", title: "Süreci değerlendir", subtitle: "Kurallara uyumu ve karar kalitesini sonuçtan ayrı izleyin.")
                onboardingCard("03", symbol: "chart.bar.xaxis", title: "Avantajını gör", subtitle: "Sermaye, R ve seans analizleriyle güçlü yönlerinizi keşfedin.")
            }
        }
    }
    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) { Text(title).font(.system(size: 18, weight: .semibold)).tracking(-0.4); Text(subtitle).font(.system(size: 11)).foregroundStyle(Palette.muted) }
    }
    private func onboardingCard(_ number: String, symbol: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Image(systemName: symbol).font(.system(size: 18, weight: .light)).foregroundStyle(Palette.mint); Spacer(); Text(number).font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.muted.opacity(0.6)) }
            VStack(alignment: .leading, spacing: 8) { Text(title).font(.system(size: 12, weight: .semibold)); Text(subtitle).font(.system(size: 11)).foregroundStyle(Palette.muted).lineSpacing(3).fixedSize(horizontal: false, vertical: true) }
        }.padding(20).frame(maxWidth: .infinity, minHeight: 145, alignment: .topLeading).background(Palette.panel, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.muted.opacity(0.12)))
    }
}
private struct DashboardChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    let accent: Color
    var prominent = false
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 21) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 15, weight: .medium)).foregroundStyle(accent)
                    .frame(width: 35, height: 35).background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.system(size: prominent ? 15 : 13, weight: .semibold)).tracking(-0.2)
                    Text(subtitle).font(.system(size: 10)).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            Rectangle().fill(Palette.muted.opacity(0.1)).frame(height: 1)
            content
        }.padding(prominent ? 24 : 22).frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18).fill(Palette.panel)
                RoundedRectangle(cornerRadius: 18).fill(LinearGradient(colors: [accent.opacity(prominent ? 0.045 : 0.025), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Palette.muted.opacity(0.13)))
            .shadow(color: .black.opacity(0.04), radius: 15, x: 0, y: 6)
    }
}
struct MetricsGrid: View {
    var performance: Performance
    var currency: String
    var body: some View {
        let p = performance
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
            MetricCard(title: "Profit factor", value: Format.factor(p))
            MetricCard(title: "Expectancy / trade", value: Format.money(p.expectancy, currency: currency))
            MetricCard(title: "Average winner", value: Format.money(p.averageWinner, currency: currency), color: Palette.outcome(p.averageWinner))
            MetricCard(title: "Average loser", value: Format.money(p.averageLoser, currency: currency), color: Palette.outcome(p.averageLoser))
            MetricCard(title: "Average R", value: Format.r(p.averageR))
            MetricCard(title: "Best trade", value: Format.money(p.bestTrade, currency: currency))
            MetricCard(title: "Worst trade", value: Format.money(p.worstTrade, currency: currency))
            MetricCard(title: "Max drawdown", value: Format.money(p.maxDrawdown, currency: currency))
            MetricCard(title: "Current win streak", value: p.currentWinStreak.description)
            MetricCard(title: "Current loss streak", value: p.currentLossStreak.description)
            MetricCard(title: "Rule compliance", value: Format.percent(p.compliance))
            MetricCard(title: "Total trades", value: p.count.description)
            MetricCard(title: "Loss rate", value: Format.percent(p.lossRate))
            MetricCard(title: "Recovery factor", value: p.recoveryFactor.map { Format.number($0) } ?? "—")
            MetricCard(title: "Realized payoff ratio", value: p.payoffRatio.map { Format.number($0) } ?? "—")
            MetricCard(title: "Average duration", value: p.averageDuration.map { Format.number($0 / 60, digits: 0) + " dk" } ?? "—")
        }
    }
}
