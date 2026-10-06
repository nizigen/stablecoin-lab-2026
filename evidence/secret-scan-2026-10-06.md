# 仓库秘密信息检查（2026-10-06，Asia/Shanghai）

后续已直接检查用户启动的Codespace：`.env`确实含配置私钥和API key，已忽略且未跟踪；权限从0666收紧到0600。实际凭据在其他792个文件及695个可达历史blobs中没有私钥/API key副本，只有ignored部署cache包含完整RPC URL。结果与限制见[Codespace补充报告](codespace-review-2026-10-06.md)。下文原扫描范围是本地克隆，不能将“未发现真实密钥”理解成远端`.env`没有密钥。

## 结论

在本次检查范围内，没有发现用户实际部署用的私钥、非公开助记词、GitHub/API 访问令牌或 Etherscan API key 明文。发现的私钥字面量均为公开 Anvil 开发账户测试密钥；`.env.example` 的私钥字段是全零占位符。本报告不包含任何密钥值或助记词文本。

这表示本次检查未发现泄漏，不能证明不存在任何未知格式或编码的秘密。

## 范围与方法

- 当前仓库全部 913 个普通文件，包含隐藏文件、未跟踪及 ignored 的 `out/`、`cache/`。其中 890 个文本文件按 UTF-8 检查，23 个二进制文件单独列为限制。
- `.git/config` 检查远程 URL 中是否嵌入认证信息，未发现。
- `git rev-list --all --objects` 覆盖本地全部 4 个 refs 可达的 709 个不同历史 blobs：686 个文本、23 个二进制。重复 blob 只检查一次。
- 检查私钥/API key/secret/token/mnemonic 赋值、独立 64 位十六进制串、常见 GitHub/OpenAI/AWS token 和私钥 PEM 标记；历史提交消息也检查了 64 位十六进制候选，未发现。
- 所有候选输出只包含文件位置、类型和分类，未输出秘密候选值。对 64 位十六进制候选结合赋值上下文、JSON 字段和第三方测试用途进行区分。
- 没有读取仓库之外的用户 `.env` 或其他私钥文件。

## 候选分类

| 位置 | 分类 |
|---|---|
| `Makefile:4`、`Makefile:6`（当前及历史） | 公开 Anvil 开发账户密钥，用于本地实验；不是用户 Sepolia 部署钱包私钥 |
| `.env.example:3`（当前及历史） | 全零私钥占位符，不是可用私钥 |
| `lib/forge-std/test/StdCheats.t.sol:230,234` | 第三方 fixture，公开 Anvil 助记词及测试密钥 |
| `lib/openzeppelin-contracts/lib/forge-std/test/StdCheats.t.sol:156,160` | 同类第三方公开 Anvil fixture |
| `out/Vm.sol/Vm.json`、`VmSafe.json` 及 `cache/coverage/artifacts/Vm.sol/` 对应文件 | Solidity metadata 中的源文件 keccak256 / 内容寻址 URL；不是私钥 |
| `evidence/verification-2026-10-05.txt:3` | Foundry 工具校验 SHA256；不是私钥 |
| `lib/forge-std/test/fixtures/broadcast.log.json`、`config.toml` | 交易哈希及编码数字测试数据 |
| `lib/forge-std/test/StdUtils.t.sol`、OpenZeppelin 合约与测试中的其他候选 | CREATE2 salt/initcodeHash、常量、存储槽、错误编码、断言或签名消息测试数据 |

## 截图检查

已重新逐张目视检查以下 4 张提交截图：

- `evidence/ex3-unbacked-mint.png`
- `evidence/ex4-five-tests.png`
- `evidence/ex5-ten-tests.png`
- `evidence/sepolia-verification-record.png`

未见真实私钥或 API key 明文。命令中的私钥/API key 使用环境变量名称；交易哈希、地址及 ABI 构造参数属于公开链上数据。此结论来自视觉检查，不能用“PNG 文本扫描无匹配”代替。

## 限制

- 不涵盖远程未抓取 refs、GitHub 已删除内容、不可达 Git objects、其他电脑或 Codespaces 文件、用户 shell 历史。
- 本地 `.git` 原始数据库没有作为普通文件重复扫描；通过所有本地 refs 可达历史 blobs 检查。其他 Git 元数据仅检查了 config。
- 未对第三方 bundled PDF、教学图片做视觉审查；其他二进制内容不作为 UTF-8 文本解读。本次目视范围为上述四张学生证据截图。
- 未验证任意十六进制值能否控制一个钱包，未登录外部服务测试凭据；通过已知公开测试密钥与代码上下文分类。
- 未执行完整 BIP39 字典枚举或任意格式的高熵检测；无关键字的助记词、拆分/编码/加密凭据可能逃过模式匹配。
- 报告对应检查时的文件快照；之后的新文件或修改需要重新检查。
