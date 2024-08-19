# PortRedirectScript
PortRedirectScript 是一个用于管理 IPv4 和 IPv6 网络端口重定向规则的 Bash 脚本。它支持单个端口、端口范围和多个端口的 TCP 和 UDP 重定向。通过简洁的菜单界面，用户可以轻松添加、查看和删除规则，适合高效管理端口。

## 功能

- 添加端口重定向规则（支持 TCP 和 UDP）
- 删除现有的重定向规则
- 查看当前的重定向规则
- 支持单个端口、端口范围和多个端口的重定向
- 兼容 IPv4 和 IPv6

## 安装

### 从 GitHub 拉取和运行

你可以使用以下命令直接从 GitHub 拉取并运行脚本：

```bash
curl -sS -O https://raw.githubusercontent.com/Freeze7y/PortRedirectScript/main/PortRedirectScript/PortRedirectScript.sh && chmod +x PortRedirectScript.sh && sudo ./PortRedirectScript.sh
```

### 手动安装

1. 确保你已安装 `iptables` 和 `ip6tables`。
2. 克隆项目到本地：
   ```bash
   git clone https://github.com/Freeze7y/PortRedirectScript.git
   ```
3. 进入项目目录：
   ```bash
   cd PortRedirectScript
   ```
4. 给予脚本执行权限：
   ```bash
   chmod +x PortRedirectScript.sh
   ```
5. 运行脚本：
   ```bash
   sudo ./PortRedirectScript.sh
   ```

## 使用

1. 运行脚本后，根据菜单选项选择操作，例如添加、查看或删除端口重定向规则。
2. 提示输入端口范围或单个端口，并指定目标端口。

## 示例

- 添加 TCP 端口 80 和 443 的重定向到目标端口 8080：
  ```bash
  sudo ./PortRedirectScript.sh
  ```
  然后选择添加端口重定向规则 (TCP)，输入端口 `80,443` 和目标端口 `8080`。

- 删除规则：
  选择删除指定规则，输入要删除的规则编号。

## 许可证

此项目使用 MIT 许可证。有关详细信息，请参阅 [LICENSE](LICENSE) 文件。

### 感谢你右上角的star🌟
[![Stargazers over time](https://starchart.cc/Freeze7y/PortRedirectScript.svg?variant=adaptive)](https://starchart.cc/Freeze7y/PortRedirectScript)

## 贡献
欢迎任何形式的贡献！请提出 [问题](https://github.com/Freeze7y/PortRedirectScript/issues) 或提交 [拉取请求](https://github.com/Freeze7y/PortRedirectScript/pulls)。
请根据实际需要添加你的电子邮件地址或其他联系方式。如果有其他需要调整的部分，请告知我！
