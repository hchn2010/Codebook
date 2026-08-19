# Codebook

Codebook 是一个 **离线优先、本地加密** 的 Flutter 密码管理 App，第一阶段面向 Android 手机。

## V0.1 已实现

- 创建主密码 / 主密码解锁
- 新增、编辑、删除、搜索密码条目
- 收藏与分类汇总
- 安全随机强密码生成器
- SQLite 本地持久化
- Argon2id 主密码密钥派生
- AES-256-GCM 敏感 Payload 加密
- App 进入后台 30 秒后的自动锁定
- 密码复制后 30 秒自动清理剪贴板
- Flutter analyze / test / Android Debug APK 的 GitHub Actions CI

## 当前加密结构

```text
主密码
  ↓
Argon2id
19 MiB memory / 2 iterations / parallelism 1
  ↓
256-bit Master Key（仅在解锁期间驻留内存）
  ↓
AES-256-GCM
  ↓
SQLite encrypted_payload
```

数据库不会以明文保存条目的 `title / username / password / website / category / notes / favorite`。SQLite 中主要保存每条记录的 AES-GCM 密文 Payload 与非敏感时间戳。

## 技术栈

- Flutter / Dart
- `sqflite`
- `cryptography`
- Argon2id
- AES-256-GCM
- GitHub Actions

## 尚未实现（V0.2 安全增强）

- Android Keystore 密钥包装
- Android BiometricPrompt / 指纹解锁
- Android `FLAG_SECURE` 截图与最近任务预览保护
- 修改主密码后的全库重新加密
- 加密备份导出 / 导入

在这些能力真正接入之前，UI 不会把它们伪装成已启用的安全功能。

## 本地运行

```bash
flutter create --platforms=android --org com.hchn2010.codebook --project-name codebook .
flutter pub get
flutter run
```

## 构建 APK

```bash
flutter build apk --debug
```

GitHub Actions 也会在 CI 成功后生成名为 `codebook-debug-apk` 的构建产物。

## 安全原则

1. 主密码永不直接保存。
2. 用户名、密码、网址、备注等敏感 Payload 统一认证加密。
3. 真实密码、签名密钥、Keystore、环境凭据不得提交到 GitHub。
4. V0.1 不引入云端账号体系，减少攻击面。
5. 当前版本仍处于开发测试阶段，不应在完成安全审计前作为高价值凭据的唯一存储位置。

## 当前阶段

**V0.1 encrypted vault baseline 已完成并通过 CI。** 下一阶段为 Android 系统级安全增强与真机体验测试。
