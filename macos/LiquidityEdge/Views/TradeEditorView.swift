import SwiftUI
import AppKit

struct TradeEditorView: View {
    @Environment(JournalStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: TradeDraft
    @State private var customRule = ""
    @State private var customMarket = ""
    @State private var tags = ""
    @State private var loaded = false
    @State private var quickSetup = ""
    init(record: TradeRecord?) { _draft = State(initialValue: TradeDraft(record: record)) }
    var body: some View {
        @Bindable var draft = draft
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: draft.isNew ? "square.and.pencil" : "slider.horizontal.3")
                    .font(.system(size: 20, weight: .medium)).foregroundStyle(Palette.mint)
                    .frame(width: 46, height: 46).background(Palette.mint.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.text(draft.isNew ? "New execution" : "Edit execution")).font(.system(size: 22, weight: .semibold)).tracking(-0.5)
                    Text(L10n.text("Capture the essentials. Expand the context when it matters.")).font(.system(size: 11)).foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 12)
                Button(L10n.text("Cancel")) { dismiss() }.buttonStyle(EdgeButtonStyle(prominent: false)).keyboardShortcut(.cancelAction)
                Button { draft.record.tags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }; if draft.save(into: store) { dismiss() } } label: {
                    Label(L10n.text("Save trade"), systemImage: "checkmark")
                }.buttonStyle(EdgeButtonStyle()).keyboardShortcut("s", modifiers: .command)
            }.padding(24).background(Palette.panel)
            Rectangle().fill(Palette.muted.opacity(0.12)).frame(height: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    general
                    process
                    expandable("Prices, risk & duration", icon: "dollarsign.circle") { prices }
                    expandable("Market context & liquidity", icon: "globe.europe.africa") { marketContext }
                    expandable("Quarterly Theory · QT", icon: "square.grid.2x2") { qt }
                    expandable("Market Maker Model · MMXM", icon: "waveform.path") { mmxm }
                    expandable("Power of Three · PO3", icon: "arrow.triangle.branch") { po3 }
                    expandable("SSMT & TSMO confirmations", icon: "arrow.triangle.swap") { divergences }
                    expandable("Candle Range Theory · CRT", icon: "chart.bar.xaxis") { crt }
                    expandable("Entry model & confirmations", icon: "scope") { VStack(alignment: .leading, spacing: 18) { option("Entry timeframe", $draft.record.entryTimeframe, ["15M", "5M", "3M", "1M"]); ChipSelection(options: Catalog.confirmations, selection: $draft.record.confirmations) } }
                    expandable("Execution grading", icon: "slider.horizontal.3") { scores }
                    expandable("Emotional journal", icon: "heart.text.square") { emotions }
                    expandable("Trade thesis & review notes", icon: "text.alignleft") { notes }
                    Panel(title: "SCREENSHOTS") { ScreenshotAttachmentEditor(shots: $draft.screenshots) }
                    Panel(title: "Tags") { textInput("Tags, separated by commas", $tags) }
                }.padding(24)
            }
            if let error = draft.error {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Palette.amber)
                    Text(L10n.text(error)).font(.system(size: 12)).textSelection(.enabled)
                    Spacer(minLength: 10)
                    Button(L10n.text("Dismiss")) { draft.error = nil }.buttonStyle(EdgeButtonStyle(prominent: false, compact: true))
                }.padding(.horizontal, 24).padding(.vertical, 14).background(Palette.amber.opacity(0.08))
            }
        }.frame(width: sheetSize.width, height: sheetSize.height).background(Palette.canvas).foregroundStyle(Palette.ink).tint(Palette.mint)
        .onAppear {
            guard !loaded else { return }; loaded = true
            draft.loadAttachments(from: store); tags = draft.record.tags.joined(separator: ", ")
            if draft.isNew { draft.record.riskPercent = store.preferences.defaultRiskPercent; draft.record.riskDollars = store.preferences.accountSize * store.preferences.defaultRiskPercent / 100 }
        }
    }
    private var general: some View {
        @Bindable var draft = draft
        return Panel(title: "01 / THE EXECUTION") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 20, alignment: .top)], alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    fieldLabel("Instrument")
                    TextField(L10n.text("NQ"), text: $draft.record.instrument).textFieldStyle(EdgeTextFieldStyle())
                    Menu(L10n.text("Choose instrument")) {
                        ForEach(store.instruments.filter(\.enabled), id: \.id) { instrument in Button(instrument.symbol) { draft.record.instrument = instrument.symbol } }
                    }.font(.system(size: 10)).foregroundStyle(Palette.muted)
                }
                option("Direction", $draft.record.direction, ["Long", "Short"])
                VStack(alignment: .leading, spacing: 7) {
                    fieldLabel("Entry time")
                    DatePicker(L10n.text("Entry time"), selection: $draft.record.date).datePickerStyle(.field).labelsHidden().controlSize(.large)
                        .frame(maxWidth: .infinity, alignment: .leading).frame(minHeight: 36)
                }
                number("Gross PnL \(store.preferences.currency)", $draft.record.grossPnL)
                optionalNumber("R multiple", $draft.record.rMultiple)
                option("Session", $draft.record.session, store.preferences.sessions)
                VStack(alignment: .leading, spacing: 7) {
                    fieldLabel("Setup")
                    Picker(L10n.text("Setup"), selection: $draft.record.setupID) {
                        Text(L10n.text("Unassigned")).tag(nil as UUID?)
                        ForEach(store.setups, id: \.id) { Text(verbatim: $0.name).tag(Optional($0.id)) }
                    }.labelsHidden().controlSize(.large).frame(maxWidth: .infinity).frame(minHeight: 36)
                        .onChange(of: draft.record.setupID) { _, value in draft.record.setupName = store.setups.first { $0.id == value }?.name ?? "Unassigned" }
                }
                option("Grade", $draft.record.grade, ["A+", "A", "B", "C", "D", "F"])
            }
            if store.setups.isEmpty {
                HStack(alignment: .bottom, spacing: 12) {
                    textInput("Name your first setup", $quickSetup)
                    Button(L10n.text("Create setup")) { createQuickSetup() }.buttonStyle(EdgeButtonStyle(prominent: false))
                }
            }
            Label(L10n.text("Gross PnL is before fees. R is optional and can be entered manually or calculated from net PnL and risk."), systemImage: "info.circle")
                .font(.system(size: 11)).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
        }
    }
    private var process: some View {
        @Bindable var draft = draft
        return Panel(title: "02 / PROCESS BEFORE OUTCOME") {
            Toggle(L10n.text("Fully according to my trading plan"), isOn: $draft.record.followsPlan).toggleStyle(.switch)
            if !draft.record.followsPlan || !draft.record.brokenRules.isEmpty {
                ChipSelection(options: Catalog.rules + store.customRules.map(\.name) + draft.record.brokenRules, selection: $draft.record.brokenRules)
                HStack(alignment: .bottom, spacing: 12) { textInput("Custom broken rule", $customRule); Button(L10n.text("Add")) { let value = customRule.trimmingCharacters(in: .whitespaces); if !value.isEmpty && !draft.record.brokenRules.contains(value) { draft.record.brokenRules.append(value); customRule = "" } }.buttonStyle(EdgeButtonStyle(prominent: false)) }
            }
            HStack(alignment: .center, spacing: 12) { Badge(text: draft.record.classification.rawValue, color: Palette.classification(draft.record.classification)); Text(L10n.text(draft.record.classification.message)).font(.system(size: 11)).foregroundStyle(Palette.muted); Spacer(minLength: 0) }
                .padding(13).frame(maxWidth: .infinity, alignment: .leading).background(Palette.raised.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    private var prices: some View {
        @Bindable var draft = draft
        return VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 16)], spacing: 18) {
                optionalNumber("Entry price", $draft.record.entryPrice); optionalNumber("Stop loss", $draft.record.stopLoss)
                optionalNumber("Take profit", $draft.record.takeProfit); optionalNumber("Exit price", $draft.record.exitPrice)
                optionalNumber("Position size", $draft.record.positionSize); optionalNumber("Risk \(store.preferences.currency)", $draft.record.riskDollars)
                optionalNumber("Risk %", $draft.record.riskPercent); number("Fees", $draft.record.fees)
            }
            HStack { Text(L10n.text("Net: \(Format.money(draft.record.netPnL, currency: store.preferences.currency))")); Text(L10n.text("Planned RR: \(draft.record.plannedRR.map { Format.number($0) } ?? "—")")).foregroundStyle(Palette.muted); Spacer(); Button(L10n.text("Calculate R from net PnL")) { draft.calculateR() }.buttonStyle(EdgeButtonStyle(prominent: false)) }
            HStack { Toggle(L10n.text("Record exit time"), isOn: Binding(get: { draft.record.exitDate != nil }, set: { draft.record.exitDate = $0 ? draft.record.date.addingTimeInterval(1800) : nil })); if draft.record.exitDate != nil { DatePicker(L10n.text("Exit"), selection: Binding(get: { draft.record.exitDate ?? draft.record.date }, set: { draft.record.exitDate = $0 })) }; Spacer() }
        }
    }
    private var marketContext: some View {
        @Bindable var draft = draft
        return VStack(alignment: .leading, spacing: 16) {
            HStack { option("HTF bias", $draft.record.bias, ["Bullish", "Bearish", "Neutral"]); Toggle(L10n.text("HTF alignment"), isOn: $draft.record.htfAligned) }
            Text(L10n.text("Context timeframes")).font(.caption); ChipSelection(options: Catalog.timeframes, selection: $draft.record.contextTimeframes)
            HStack(alignment: .bottom, spacing: 12) { textInput("Draw on liquidity / custom", $draft.record.drawOnLiquidity); Menu(L10n.text("Liquidity reference")) { ForEach(Catalog.liquidity, id: \.self) { value in Button(value) { draft.record.drawOnLiquidity = value } } } }
            Text(L10n.text("Liquidity taken")).font(.caption); ChipSelection(options: Catalog.sweeps, selection: $draft.record.liquidityTaken)
            Toggle(L10n.text("Liquidity sweep valid"), isOn: $draft.record.sweepValid)
        }
    }
    private var qt: some View {
        @Bindable var draft = draft
        return VStack(alignment: .leading, spacing: 16) {
            Toggle(L10n.text("QT enabled"), isOn: $draft.record.qt.enabled)
            if draft.record.qt.enabled {
                HStack { option("Higher timeframe quarter", $draft.record.qt.higherQuarter, ["Q1", "Q2", "Q3", "Q4"]); option("Daily quarter", $draft.record.qt.dailyQuarter, ["Q1", "Q2", "Q3", "Q4"]) }
                HStack { option("90 minute cycle", $draft.record.qt.cycle90, ["Q1", "Q2", "Q3", "Q4"]); option("22.5 minute cycle", $draft.record.qt.cycle22, ["Q1", "Q2", "Q3", "Q4"]) }
                option("QT phase", $draft.record.qt.phase, ["Accumulation", "Manipulation", "Distribution", "Continuation"])
                HStack { Toggle(L10n.text("True open respected"), isOn: $draft.record.qt.trueOpen); Toggle(L10n.text("QT bias aligned"), isOn: $draft.record.qt.aligned); Toggle(L10n.text("QT model valid"), isOn: $draft.record.qt.valid) }
            }
        }
    }
    private var mmxm: some View {
        @Bindable var draft = draft
        return VStack(alignment: .leading, spacing: 16) {
            option("MMXM", $draft.record.mmxm.model, ["None", "Market Maker Buy Model", "Market Maker Sell Model"])
            if draft.record.mmxm.model != "None" {
                HStack { Toggle(L10n.text("Original consolidation"), isOn: $draft.record.mmxm.consolidation); Toggle(L10n.text("Manipulation"), isOn: $draft.record.mmxm.manipulation); Toggle(L10n.text("Displacement"), isOn: $draft.record.mmxm.displacement) }
                HStack { Toggle(L10n.text("Repricing"), isOn: $draft.record.mmxm.repricing); Toggle(L10n.text("Smart money reversal"), isOn: $draft.record.mmxm.reversal); Toggle(L10n.text("Opposing liquidity target"), isOn: $draft.record.mmxm.target) }
                Toggle(L10n.text("MMXM valid"), isOn: $draft.record.mmxm.valid)
            }
        }
    }
    private var po3: some View {
        @Bindable var draft = draft
        return HStack { option("PO3 phase", $draft.record.po3.phase, ["Accumulation", "Manipulation", "Distribution"]); option("Manipulation direction", $draft.record.po3.manipulationDirection, ["Up", "Down"]); Toggle(L10n.text("PO3 valid"), isOn: $draft.record.po3.valid) }
    }
    private var divergences: some View {
        @Bindable var draft = draft
        return VStack(alignment: .leading, spacing: 16) {
            HStack { option("SSMT confirmation", $draft.record.ssmt.confirmation, ["Yes", "No", "Not Required"]); Toggle(L10n.text("Valid SSMT"), isOn: $draft.record.ssmt.valid) }
            option("SSMT type", $draft.record.ssmt.type, ["High divergence", "Low divergence", "Intermarket divergence", "Time-based divergence"])
            ChipSelection(options: ["NQ", "ES", "YM", "DXY", "Gold", "EUR", "GBP"] + draft.record.ssmt.markets, selection: $draft.record.ssmt.markets)
            HStack(alignment: .bottom, spacing: 12) { textInput("Custom reference market", $customMarket); Button(L10n.text("Add market")) { let text = customMarket.trimmingCharacters(in: .whitespaces); if !text.isEmpty { if !draft.record.ssmt.markets.contains(text) { draft.record.ssmt.markets.append(text) }; customMarket = "" } }.buttonStyle(EdgeButtonStyle(prominent: false)) }
            Divider()
            HStack { option("TSMO confirmation", $draft.record.tsmo, ["Yes", "No", "Not Required"]); Toggle(L10n.text("TSMO valid"), isOn: $draft.record.tsmoValid) }
            Text(L10n.text("A confirmation contributes to analytics only when it is both present and valid.")).font(.caption).foregroundStyle(Palette.muted)
        }
    }
    private var crt: some View {
        @Bindable var draft = draft
        return VStack(alignment: .leading, spacing: 16) {
            Toggle(L10n.text("CRT setup"), isOn: $draft.record.crt.enabled)
            if draft.record.crt.enabled {
                HStack { option("CRT timeframe", $draft.record.crt.timeframe, Catalog.timeframes); optionalNumber("Range high", $draft.record.crt.high); optionalNumber("Range low", $draft.record.crt.low) }
                HStack { option("Liquidity taken", $draft.record.crt.liquidityTaken, ["High", "Low"]); Toggle(L10n.text("CRT re-entry"), isOn: $draft.record.crt.reentry); Toggle(L10n.text("CRT confirmed"), isOn: $draft.record.crt.confirmed) }
            }
        }
    }
    private var scores: some View {
        @Bindable var draft = draft
        return VStack(spacing: 12) {
            ScoreSlider(title: "Market read", value: $draft.record.scores.marketRead)
            ScoreSlider(title: "Entry execution", value: $draft.record.scores.entry)
            ScoreSlider(title: "Rule compliance", value: $draft.record.scores.compliance)
            ScoreSlider(title: "Risk management", value: $draft.record.scores.risk)
            ScoreSlider(title: "Trade management", value: $draft.record.scores.management)
            ScoreSlider(title: "Psychology", value: $draft.record.scores.psychology)
            ScoreSlider(title: "Pattern recognition", value: $draft.record.scores.recognition)
            HStack { Text(L10n.text("Overall score")); Spacer(); Text(L10n.text("\(Format.number(draft.record.scores.overall, digits: 0)) / 100")).foregroundStyle(Palette.mint).font(.title3.monospaced()) }
        }
    }
    private var emotions: some View {
        @Bindable var draft = draft
        return VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("BEFORE")).font(.caption.monospaced()).foregroundStyle(Palette.muted)
            ScoreSlider(title: "Confidence", value: $draft.record.emotional.confidence, lower: 1)
            ScoreSlider(title: "Stress", value: $draft.record.emotional.stress, lower: 1)
            ScoreSlider(title: "FOMO", value: $draft.record.emotional.fomo, lower: 1)
            ScoreSlider(title: "Focus", value: $draft.record.emotional.focus, lower: 1)
            Text(L10n.text("AFTER")).font(.caption.monospaced()).foregroundStyle(Palette.muted)
            ScoreSlider(title: "Execution satisfaction", value: $draft.record.emotional.satisfaction, lower: 1)
            Toggle(L10n.text("I would take this trade again"), isOn: $draft.record.emotional.takeAgain)
            ChipSelection(options: Catalog.emotions, selection: $draft.record.emotional.emotions)
        }
    }
    private var notes: some View {
        @Bindable var draft = draft
        return VStack(alignment: .leading, spacing: 16) {
            NoteField(title: "Trade thesis", text: $draft.record.notes.thesis)
            NoteField(title: "Why did I enter?", text: $draft.record.notes.entry)
            NoteField(title: "What confirmed the trade?", text: $draft.record.notes.confirmation)
            NoteField(title: "What invalidated the setup?", text: $draft.record.notes.invalidation)
            NoteField(title: "What did I do correctly?", text: $draft.record.notes.correct)
            NoteField(title: "What did I do incorrectly?", text: $draft.record.notes.incorrect)
            NoteField(title: "What would I do differently?", text: $draft.record.notes.differently)
            NoteField(title: "Key lesson", text: $draft.record.notes.lesson)
        }
    }
    private var sheetSize: CGSize {
        let visible = (NSApp.keyWindow?.screen ?? NSScreen.main)?.visibleFrame.size ?? CGSize(width: 1200, height: 900)
        return CGSize(width: min(980, max(720, visible.width - 96)), height: min(860, max(480, visible.height - 80)))
    }
    private func fieldLabel(_ title: String) -> some View {
        Text(L10n.text(title)).font(.system(size: 11, weight: .medium)).foregroundStyle(Palette.muted)
    }
    private func textInput(_ title: String, _ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) { fieldLabel(title); TextField(L10n.text(title), text: binding).textFieldStyle(EdgeTextFieldStyle()) }
    }
    private func expandable<Content: View>(_ title: String, icon: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        DisclosureGroup { content().padding(.top, 20) } label: {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 14, weight: .medium)).foregroundStyle(Palette.blue).frame(width: 22)
                Text(L10n.text(title)).font(.system(size: 13, weight: .semibold))
            }.padding(.vertical, 3)
        }.editorSection()
    }
    private func option(_ title: String, _ binding: Binding<String>, _ options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            fieldLabel(title)
            Picker(L10n.text(title), selection: binding) {
                ForEach(Array(Set(options + [binding.wrappedValue])).sorted(), id: \.self) { Text(L10n.text($0)).tag($0) }
            }.labelsHidden().controlSize(.large).frame(maxWidth: .infinity).frame(minHeight: 36)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func createQuickSetup() {
        let name = quickSetup.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { draft.error = "Give your setup a name."; return }
        do {
            let setup = Setup(name: name)
            try store.commit { store.context.insert(setup); let book = Playbook(); store.context.insert(book); setup.playbook = book }
            draft.record.setupID = setup.id; draft.record.setupName = name; quickSetup = ""
        } catch { draft.error = error.localizedDescription }
    }
    private func number(_ title: String, _ binding: Binding<Double>) -> some View { VStack(alignment: .leading, spacing: 7) { fieldLabel(title); TextField(L10n.text(title), value: binding, format: .number).textFieldStyle(EdgeTextFieldStyle()).monospacedDigit() } }
    private func optionalNumber(_ title: String, _ binding: Binding<Double?>) -> some View { VStack(alignment: .leading, spacing: 7) { fieldLabel(title); TextField(L10n.text(title), value: binding, format: .number).textFieldStyle(EdgeTextFieldStyle()).monospacedDigit() } }
}
struct NoteField: View {
    var title: String
    @Binding var text: String
    @FocusState private var focused: Bool
    init(title: String, text: Binding<String>) { self.title = title; _text = text }
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(L10n.text(title)).font(.system(size: 11, weight: .medium)).foregroundStyle(Palette.muted)
            TextEditor(text: $text).font(.system(size: 13)).lineSpacing(4).scrollContentBackground(.hidden)
                .padding(11).frame(minHeight: 105).focused($focused)
                .background(Palette.canvas.opacity(0.4), in: RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(focused ? Palette.mint.opacity(0.55) : Palette.muted.opacity(0.15)))
                .accessibilityLabel(L10n.text(title))
        }
    }
}
private extension View {
    func editorSection() -> some View {
        self.font(.system(size: 13)).padding(22).background(Palette.panel, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.muted.opacity(0.12)))
    }
}
