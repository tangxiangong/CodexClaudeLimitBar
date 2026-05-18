import Combine
import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var status: SMAppService.Status
    @Published private(set) var errorMessage: String?
    private let launchAgent = LaunchAgentLoginItemController()

    init() {
        status = SMAppService.mainApp.status
    }

    var isEnabled: Bool {
        if status == .notFound {
            return launchAgent.isRegistered
        }

        return status == .enabled || status == .requiresApproval
    }

    var isAvailable: Bool {
        status != .notFound || launchAgent.isAvailable
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
            if !launchAgent.isAvailable {
                return "当前运行方式不支持注册登录项"
            }

            if launchAgent.isRegistered {
                return "已使用本机 LaunchAgent 开机自启动"
            }

            return "未签名应用将使用本机 LaunchAgent 自启动"
        @unknown default:
            return "系统返回了未知的登录项状态"
        }
    }

    func refresh() {
        status = SMAppService.mainApp.status
    }

    func setEnabled(_ isEnabled: Bool) {
        do {
            if status == .notFound {
                if isEnabled {
                    try launchAgent.register()
                } else {
                    try launchAgent.unregister()
                }
            } else if isEnabled {
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
