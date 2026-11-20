# la-go-2024 公网测试服（公开外壳仓）

本仓库**只包含 GitHub Actions workflow 和脚本**，不含服务端二进制，也不含任何从游戏客户端
提取的数据。服务端和管理平台静态资源由 workflow 在运行时从**私有仓的 GitHub Release**
下载；运行时状态也写回私有仓的 `test-state` 分支。

## 一次性配置

### 1. 私有仓上传 release 资产

在私有仓（默认 `luo1227/la-go-2024`）运行主仓库的 `go run ./cmd/deploy`，得到：

- `build/deploy-release/la-server`
- `build/deploy-release/admin-web.tar.gz`
- `build/deploy-release/SHA256SUMS`

把它们作为一个 release（tag 默认 `deploy-latest`）的资产上传。

也可以在私有仓加一个本地 workflow，用 `go run ./cmd/deploy` 后 `gh release upload` 自动发布。

### 2. 创建 PAT 并配置 secret

需要一个**能读取私有仓 release**的令牌：

- fine-grained PAT：仅授权私有仓，`Contents: Read-only`。
- classic PAT：`repo` 作用域。

然后在本仓库：

```text
Settings → Secrets and variables → Actions
  Secret  PRIVATE_REPO_TOKEN = <上面生成的 PAT>
  Variable PRIVATE_REPO      = <私有仓 full name，默认 luo1227/la-go-2024>（可选）
  Variable RELEASE_TAG       = <release tag，默认 deploy-latest>（可选）
```

## 运行

Actions → 公网测试服 → Run workflow：

| 输入 | 说明 |
|---|---|
| `duration_minutes` | 会话时长，默认 350；job 上限 355 |
| `gm_token` | GM 管理口令，留空自动生成随机口令 |
| `enable_ssh` | 开启 tmate SSH 调试（默认关闭，仅触发人可登录） |
| `bore_server` | 默认 `bore.pub` |

运行后在该次 run 的 **Summary** 读取 `http://bore.pub:<端口>`、管理平台地址和 GM 口令。

## 客户端

启动器「设置 → 服务端地址」填 `http://bore.pub:<端口>`，登录账号、选角色、启动客户端。
桥接仍由本机启动器的 Frida helper 完成。

## 安全与限制

- 服务端只监听 runner 本地 127.0.0.1，公网流量经 bore.pub 中继，无 TLS。
- `/api/platform/*` 无鉴权；`/gm/api/*` 由 `gm_token` 保护。
- 端口每次 run 随机变化；run 结束后 runner 销毁。
- 只用于测试，不要放敏感数据。
