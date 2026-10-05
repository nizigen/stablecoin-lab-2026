# Assignment Two 核对报告

核对日期：2026-10-05（Asia/Shanghai）。仓库：nizigen/stablecoin-lab-2026；源码基线提交 `210d9ff57b14b8d0894c2ef179b8bbb8a3ff5a86`。

结论：必做练习已实现且本次全部验收通过，Ex3 原始截图已恢复，讨论题与架构图齐全。满分仍不能保证：Vault 的 Etherscan 源码验证缺最终证据，覆盖率与格式还有可加强项。当前是审核完成状态，尚未制作或提交 Moodle 最终 ZIP。

## 权威要求与逐项证据

评分依据是 `Y26-7810(SH)-assign2.pdf`，而不是 README 中旧的 bonus 标签。截止时间：2026-10-16 23:55。

| 评分项 | 权重 | 核对结果 | 证据 / 剩余问题 |
|---|---:|---|---|
| Ex0 环境与核心测试 | 40% 类别内 | 通过 | doctor 6 passed、core 7 passed，exit 0 |
| Ex2 两项测试 | 同上 | 通过 | supply 增量与 6/18 小数陷阱均有真实断言 |
| Ex3 无抵押增发截图 | 同上 | 满足 | [原图](evidence/ex3-unbacked-mint.png)：供应 1001000000000、抵押 1000000000，1001:1 |
| Ex4 五项测试 | 同上 | 通过 | 未授权 mint、暂停 transfer/redeem、攻击者不能 burn、Vault 可以 burn 均验证 |
| Ex5 四项实现 | 同上 | 通过 | /1e20 换算、150% mint/redeem 限制、低于120%清算、10%奖励及 cap；10项测试通过 |
| Ex6 handler 与两项不变量 | 同上 | 通过 | 256 runs、128000 calls、0 reverts；deposit 64098、redeem 63902；两个性质均 PASS |
| 三合约 Sepolia 部署与源码验证 | 20% | 部署存在；验证证据不完整 | 三地址均有链上 runtime bytecode；历史截图确认前两份 already verified，Vault 只截到开始验证 |
| A–D 讨论题及 E 表 | 25% | 已修正并独立复核 | 每题150个空白分隔英文词，每组300；E五函数名准确，最可能攻击场景已答 |
| 命名、说明及架构图 | 15% | 架构图齐全；样式可加强 | README Mermaid 已有；fmt 检查发现6份已有格式差异，部分教学注释仍保留 TODO 描述 |
| Ex1 warm-up | 不计分 | 已有 deposit 记录，redeem 未记录 | PDF明确不计分，不应当作满分阻碍 |
| Ex7 challenge | 选做、不计分 | 通过 | 2 passed，直接捐赠1单位破坏会计假设 |

## 本次实际执行的验证

使用官方 Foundry v1.8.4 Windows 包，SHA256 与官方发布值一致，Solc 0.8.24。Windows 未安装 make，因此实际运行 doctor 脚本与 Makefile 内完全相同的 forge 命令，不能写成直接运行过 make。

```text
bash scripts/doctor.sh                                               exit 0; 6 passed
forge test --no-match-path 'test/{challenges,exercises}/*' -vv          exit 0; 7 passed
forge test --match-path 'test/exercises/*.t.sol' -vv                   exit 0; 18 passed
forge test --match-path 'test/challenges/Unstoppable.t.sol' -vv         exit 0; 2 passed
forge coverage --report summary                                      exit 0; 27 passed
git diff --check                                                      exit 0
forge fmt --check                                                    exit 1; existing format differences
```

Foundry v1.8.4将同一套件的两个 Ex6 不变量合并计为1个 test，所以练习汇总18并不是缺少一个断言。完整原始输出：[verification-2026-10-05.txt](evidence/verification-2026-10-05.txt)。

覆盖率诊断报告：行82.79%、语句78.39%、分支36.59%、函数85.11%。统计包括部署脚本和handler；Foundry也打印了 coverage anchor warnings，因此此报告只能作为诊断，不能声称所有维度可靠达到80%。可加强真正未覆盖的 revert 与边界情形，尤其：零地址/零金额、超额提款、120%清算边界、清算人余额不足和失败后的状态回滚。PDF未给出覆盖率具体阈值。

## 文档修正

- A1明确当前Vault不可升级；赎回时Vault调用stable，stable中的caller是Vault。拟议改法使用用户授权与burnFrom(user,amount)，额度和余额分别检查。
- C2明确当前无需sUSD approval；请求超过储备会在burn之前回滚。实验只有1000 USDC储备，一次赎回一百万失败，赎回1000可清空储备。
- B1明确普通转账端点检查覆盖transfer与transferFrom；B2区分赎回承诺和银行结算开放时间。
- PDF写“groups A–D, 150–300 words each”，仓库写每题150–300。本次每题150、每组300，同时满足两种空白分词解读。
- README将正式足额抵押性质写为 `totalCollateral >= totalSupply`；普通闭环保持等式，直接捐赠可产生超额抵押。链上余额充足本身不保证市场价格或赎回可用。

## Sepolia 状态与提交文本

| 合约 | 地址 / 源码页面 | 本次链上检查 |
|---|---|---|
| MockUSDC | [0x5e84CDb0C3656F5F510D1c7a48C4dBD679711fC5](https://sepolia.etherscan.io/address/0x5e84CDb0C3656F5F510D1c7a48C4dBD679711fC5#code) | runtime bytecode 1915 bytes |
| SimpleStablecoin | [0xE719617236fe799c32d58c87969f22c40CaCB74A](https://sepolia.etherscan.io/address/0xE719617236fe799c32d58c87969f22c40CaCB74A#code) | runtime bytecode 3569 bytes |
| Vault | [0xea7C998f2412c626331BC1d94D8EE433c7f99d29](https://sepolia.etherscan.io/address/0xea7C998f2412c626331BC1d94D8EE433c7f99d29#code) | runtime bytecode 1835 bytes |

2026-10-05通过公开 Sepolia RPC读取代码，仅证明部署存在，不证明源码已验证或与本地每项设置一致。Etherscan网页本次被Cloudflare拦截。历史[验证截图](evidence/sepolia-verification-record.png)证明MockUSDC和SimpleStablecoin已经验证，但未包含Vault结果。不要为了核实验证重新部署。

可在原部署环境用既有API配置查询/补做Vault验证；不需要发送新的部署交易：

```bash
forge verify-contract 0xea7C998f2412c626331BC1d94D8EE433c7f99d29 src/Vault.sol:Vault \
  --chain sepolia \
  --compiler-version v0.8.24+commit.e11b9ed9 \
  --num-of-optimizations 200 \
  --constructor-args $(cast abi-encode 'constructor(address,address)' \
    0x5e84CDb0C3656F5F510D1c7a48C4dBD679711fC5 \
    0xE719617236fe799c32d58c87969f22c40CaCB74A) \
  --etherscan-api-key "$ETHERSCAN_API_KEY" --watch
```

原部署时的compiler/EVM/optimizer设置必须一致。获得“already verified”或成功结果后，保存完整输出/截图；Moodle地址文本见 [MOODLE_LINKS.md](MOODLE_LINKS.md)。

## 满分前剩余动作

1. 确认Vault源码已在Etherscan验证，保留最终证据。前两个合约的验证记录不能替代Vault的最终验证记录。
2. 可进一步提高错误路径与边界覆盖，并处理提交源码的格式/失真教学注释；这是40%和15%类别的质量加强项，不是官方验收失败。
3. 最终ZIP从项目根目录打包，保留lib/、evidence/、STUDENT-QUESTIONS.md与README.md。排除.env及其他真实凭证、.git、out/、cache/、broadcast/、本地链快照；最终对实际ZIP再查秘密与缺件。本次未制作ZIP，不能把“gitignore已配置”当作ZIP安全验证。
4. Moodle上传ZIP，并在文本框粘贴三个地址和Etherscan链接。README的仓库链接清单是通用lab说明，PDF指定ZIP优先。

本次改动仅限文档和恢复证据，没有改业务合约或验收测试，没有重新部署，没有推送远端。Codespace恢复Shutdown；本次验证无需保留远程运行环境。
