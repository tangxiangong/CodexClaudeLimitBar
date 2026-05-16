import Combine
import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var status: SMAppService.Status
    @Published private(set) var errorMessage: String?

    init() {
        status = SMAppService.mainApp.status
    }

    var isEnabled: Bool {
        status == .enabled || status == .requiresApproval
    }

    var isAvailable: Bool {
        status != .notFound
    }

    var detailText: String {
        if let errorMessage {
            return errorMessage
        }

        switch status {
        case .enabled:
            return "登录 macOS 后自动打开菜单栏监控"
        case .notRegistered:
            return "关闭后需要手动启动应用"
        case .requiresApproval:
            return "需要在系统设置的登录项中允许"
        case .notFound:
            return "当前运行方式不支持注册登录项"
        @unknown default:
            return "系统返回了未知的登录项状态"
        }
    }

    func refresh() {
        status = SMAppService.mainApp.status
    }

    func setEnabled(_ isEnabled: Bool) {
        do {
            if isEnabled {
                if status == .notRegistered {
                    try SMAppService.mainApp.register()
                }
            } else if status != .notRegistered {
                try SMAppService.mainApp.unregister()
            }

            errorMessage = nil
        } catch {
            errorMessage = "无法更新开机自启动：\(error.localizedDescription)"
        }

        refresh()
    }
}
