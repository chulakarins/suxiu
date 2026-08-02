#if os(iOS)
import SwiftUI

struct DeveloperMockSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppEnvironment.mockScenarioKey)
    private var scenarioRawValue = MockScenario.success.rawValue
    @AppStorage(AppEnvironment.showMockBadgeKey)
    private var showMockBadge = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Mock 场景") {
                    Picker("生成行为", selection: $scenarioRawValue) {
                        ForEach(MockScenario.allCases) { scenario in
                            Text(scenario.displayName).tag(scenario.rawValue)
                        }
                    }
                }

                Section("展示") {
                    Toggle("显示“演示素材”标记", isOn: $showMockBadge)
                }

                Section {
                    Button("恢复演示默认设置") {
                        scenarioRawValue = MockScenario.success.rawValue
                        showMockBadge = true
                    }
                } footer: {
                    Text("比赛演示前建议恢复默认：正常成功、显示演示素材标记。")
                }

                Section {
                    Text("设置会应用到下一次生成，可用于稳定复现慢速、失败、超时和离线状态。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Mock 开发设置")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
#endif
