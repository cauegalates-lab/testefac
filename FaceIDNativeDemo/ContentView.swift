import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @State private var unlocked = false
    @State private var authenticating = false
    @State private var message = "Olhe para o iPhone para desbloquear"
    @State private var showRetry = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if unlocked {
                HomeView(lockAction: lockApp)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                lockScreen
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: unlocked)
        .task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await authenticate()
        }
    }

    private var lockScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            FaceIDIcon()
                .frame(width: 108, height: 108)
                .padding(.bottom, 30)

            Text("Acesso protegido")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text(message)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .padding(.horizontal, 34)

            if authenticating {
                ProgressView()
                    .controlSize(.large)
                    .padding(.top, 30)
            }

            if showRetry && !authenticating {
                Button {
                    Task { await authenticate() }
                } label: {
                    Label("Tentar Face ID novamente", systemImage: "faceid")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                }
                .padding(.top, 30)
                .padding(.horizontal, 24)
            }

            Spacer()

            Text("Face ID é processado pelo próprio iPhone.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 26)
        }
    }

    @MainActor
    private func authenticate() async {
        guard !authenticating else { return }

        authenticating = true
        showRetry = false
        message = "Verificando Face ID…"

        let context = LAContext()
        context.localizedCancelTitle = "Cancelar"

        var error: NSError?
        let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics

        guard context.canEvaluatePolicy(policy, error: &error) else {
            authenticating = false
            message = "O Face ID não está disponível ou não está configurado neste iPhone."
            showRetry = true
            return
        }

        guard context.biometryType == .faceID else {
            authenticating = false
            message = "Este exemplo foi configurado especificamente para Face ID."
            showRetry = true
            return
        }

        do {
            let success = try await context.evaluatePolicy(
                policy,
                localizedReason: "Use o Face ID para acessar a área protegida."
            )

            authenticating = false

            if success {
                message = "Acesso liberado"
                unlocked = true
            } else {
                message = "Não foi possível confirmar sua identidade."
                showRetry = true
            }
        } catch {
            authenticating = false
            message = readableMessage(for: error)
            showRetry = true
        }
    }

    private func readableMessage(for error: Error) -> String {
        let nsError = error as NSError

        if nsError.domain == LAError.errorDomain,
           let code = LAError.Code(rawValue: nsError.code) {
            switch code {
            case .userCancel, .systemCancel, .appCancel:
                return "Autenticação cancelada."
            case .biometryLockout:
                return "Face ID temporariamente bloqueado. Desbloqueie o iPhone e tente novamente."
            case .biometryNotEnrolled:
                return "Configure o Face ID nos Ajustes do iPhone antes de testar."
            case .biometryNotAvailable:
                return "Face ID não está disponível neste aparelho."
            case .authenticationFailed:
                return "Rosto não reconhecido. Tente novamente."
            default:
                return "Não foi possível usar o Face ID."
            }
        }

        return "Não foi possível usar o Face ID."
    }

    private func lockApp() {
        unlocked = false
        message = "Olhe para o iPhone para desbloquear"
        showRetry = false

        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            await authenticate()
        }
    }
}

private struct FaceIDIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.07))

            Image(systemName: "faceid")
                .font(.system(size: 58, weight: .light))
                .foregroundStyle(.white)
        }
    }
}

private struct HomeView: View {
    let lockAction: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Bom dia")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 16, weight: .medium))

                        Text("Área liberada")
                            .font(.system(size: 32, weight: .bold, design: .rounded))

                        HStack(spacing: 7) {
                            Image(systemName: "checkmark.shield.fill")
                            Text("Identidade confirmada com Face ID")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.green)
                    }

                    VStack(spacing: 0) {
                        DemoRow(
                            icon: "person.crop.circle",
                            title: "Meu perfil",
                            subtitle: "Dados da sua conta"
                        )

                        Divider().padding(.leading, 58)

                        DemoRow(
                            icon: "doc.text",
                            title: "Conteúdo privado",
                            subtitle: "Informações liberadas após o Face ID"
                        )

                        Divider().padding(.leading, 58)

                        DemoRow(
                            icon: "lock.shield",
                            title: "Segurança",
                            subtitle: "Acesso protegido pelo aparelho"
                        )
                    }
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Conteúdo de teste")
                            .font(.system(size: 18, weight: .semibold))

                        Text("Esta tela representa o conteúdo que só aparece depois que o iPhone confirma o rosto do usuário. Aqui você pode colocar painel, dados, documentos, treinos ou qualquer outra área privada do aplicativo.")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button(action: lockAction) {
                        Label("Bloquear e testar novamente", systemImage: "lock.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .foregroundStyle(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                }
                .padding(20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: lockAction) {
                        Image(systemName: "lock")
                    }
                    .accessibilityLabel("Bloquear")
                }
            }
        }
    }
}

private struct DemoRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 30)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .frame(height: 74)
    }
}

#Preview {
    ContentView()
}
