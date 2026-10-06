# Codespace复核（2026-10-06，Asia/Shanghai）

环境：`shiny-space-sniffle-g4qq5wvp6v9g2vrrg`，工作目录`/workspaces/stablecoin-lab-2026`，源码HEAD `210d9ff`，Forge `1.8.3`。通过用户授权的OpenCLI操作真实Chrome里的Codespace终端；没有重新部署、签名或发送链上交易。

## 实际测试与截图

- `make test`：exit 0，7 passed / 0 failed。
- `make exercise`：exit 0，18 passed / 0 failed；Forge将两个invariant性质合并计为一个suite测试。
- Ex6：两个性质均PASS，256 runs、128000 calls、0 reverts；deposit 64036次、redeem 63964次，两者discards均为0。
- [全绿截图](codespace-all-green-2026-10-06.png)展示真实运行日志经过grep过滤的PASS与最终统计，附源码版本、工具版本及UTC时间；没有改写测试结果。
- [不变量截图](codespace-invariants-2026-10-06.png)展示同次日志中完整的Ex6性质、调用分布和统计。
- [Vault Etherscan截图](vault-etherscan-verified-2026-10-06.png)在同一页面显示完整地址与Source Code Verified / Exact Match。编译器0.8.24、optimizer 200 runs、EVM cancun。

## .env检查

实际`.env`保留在Codespace中，没有复制到本地或显示其值。使用静态Perl脚本读取字段；没有source或执行配置。输出只含变量名、存在性、格式及Git状态。

| 检查 | 结果 |
|---|---|
| PRIVATE_KEY | 有值，64位十六进制，非全零占位符；未输出其值 |
| SEPOLIA_RPC_URL | 有值，HTTPS URL；未输出完整URL |
| ETHERSCAN_API_KEY | 有值；未登录服务测试有效性或输出其值 |
| Git tracked / ignored | 未跟踪，已忽略 |
| 文件权限 | 原0666，已收紧为0600；配置内容未改 |

随后以这些实际字段为匹配目标，扫描Codespace中的792个普通文件（含ignored的out/cache，排除`.env`本体、`.git`及符号链接）与全部本地refs可达的695个历史blobs。解析成功、Git读取成功、读错误0、扫描exit 0。私钥按去掉0x后的完整hex忽略大小写匹配；API key和完整RPC URL按字面匹配，秘密始终仅在内存中，不进入子进程参数。

结果：历史匹配0；当前文件仅1处匹配完整RPC URL，位于`cache/Deploy.s.sol/11155111/run-latest.json`，该文件已被Git忽略。未发现实际PRIVATE_KEY或ETHERSCAN_API_KEY在其他扫描文件/历史blobs中的副本。此结果不证明其他未知、拆分或编码凭据不存在；不涵盖未保存编辑缓冲区、shell历史、不可达objects或其他远端refs。

[脱敏检查截图](codespace-env-audit-2026-10-06.png)只展示上述元信息及扫描结果，没有显示`.env`内容。退出码`RPC_CACHE_GIT_IGNORED=0`代表Git忽略检查成功。

最终提交ZIP必须同时排除`.env`与`cache/`，也排除`.git/`、`out/`、`broadcast/`及链快照。当前未制作ZIP，不能将Git忽略状态代替最终压缩包检查。

截图已由另一位验证代理逐张复核测试结果、地址与明文秘密；临时审计脚本/输出清理，用户启动的Codespace保持运行。远端业务源码未改，本地审阅文档和注释改动尚未推送到远端。
