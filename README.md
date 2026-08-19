# Codebook

Codebook 是一个 **离线优先、本地加密** 的 Flutter 密码管理 App，第一阶段目标是运行在 Android 手机上。

## V0.1 目标

- 创建主密码并解锁本地密码库
- 新增、编辑、删除、搜索密码条目
- 收藏与分类
- 强密码生成器
- 本地 SQLite 持久化
- 敏感数据加密后再写入数据库
- 自动锁定
- 剪贴板自动清除
- Android 截图保护
- 为生物识别解锁预留能力

## 技术方向

- Flutter / Dart
- SQLite
- Argon2id（主密码派生密钥）
- AES-256-GCM（Vault 数据加密）
- Android Keystore / BiometricPrompt

## 安全原则

1. 主密码永不直接保存。
2. 用户名、密码、网址、备注等敏感 Payload 统一加密。
3. 真实密码、签名密钥、Keystore、环境凭据不得提交到 GitHub。
4. 第一阶段不引入云端账号体系，减少攻击面。

## 当前阶段

V0.1 Flutter UI 与应用骨架构建中。
