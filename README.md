# FaceIDNativeDemo

Exemplo nativo iOS em SwiftUI usando LocalAuthentication.

## O que acontece
- O app abre bloqueado.
- Após cerca de meio segundo, chama automaticamente o Face ID.
- A política usada é `deviceOwnerAuthenticationWithBiometrics`.
- O exemplo verifica se a biometria disponível é realmente Face ID.
- Se o rosto for reconhecido, abre uma área interna de demonstração.
- A área interna tem um botão para bloquear e testar novamente.

## Como testar em um iPhone
1. Abra `FaceIDNativeDemo.xcodeproj` no Xcode.
2. Selecione o target `FaceIDNativeDemo`.
3. Em Signing & Capabilities, selecione sua conta/time Apple em `Team`.
4. Se necessário, troque o Bundle Identifier para um identificador único.
5. Conecte seu iPhone ao Mac.
6. Escolha o iPhone como destino e execute o projeto.
7. O iPhone precisa estar com Face ID configurado.

## Privacidade
O projeto inclui `NSFaceIDUsageDescription` no Info.plist.

## Observação
Este exemplo protege a interface local do app. Em um produto real com conta de usuário,
tokens/sessões e dados sensíveis também devem ser protegidos e validados no backend.
