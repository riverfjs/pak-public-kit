# pak-public-kit

<p>
  <img src="https://img.shields.io/badge/macOS-26.4-white?style=flat&labelColor=000000&color=white" alt="macOS 26.4" />
  <img src="https://img.shields.io/badge/.NET%20SDK-10.0.300-white?style=flat&labelColor=512BD4&color=white" alt=".NET SDK 10.0.300" />
  <img src="https://img.shields.io/badge/uv-0.11.8-white?style=flat&labelColor=000000&color=white" alt="uv 0.11.8" />
  <img src="https://img.shields.io/badge/Node.js-25.8.0-white?style=flat&labelColor=339933&color=white" alt="Node.js 25.8.0" />
  <img src="https://img.shields.io/badge/Python-3.9.6%20fallback-white?style=flat&labelColor=3776AB&color=white" alt="Python 3.9.6 fallback" />
  <img src="https://img.shields.io/badge/unzip-6.00-white?style=flat&labelColor=000000&color=white" alt="unzip 6.00" />
</p>

本项目用于从 PAK 中导出配置数据与图标资源，也可以单独导出 Lua bytecode 与反汇编文本。主流程默认输出目录为 `output`。

## 使用

```bash
./run.sh --aes-file path/to/aes_key.txt \
  --ipa path/to/app.ipa \
  --app path/to/app_container \
  --output path/to/output
```

也可以直接传 64 位十六进制 AES key：

```bash
./run.sh 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef \
  --ipa path/to/app.ipa \
  --app path/to/app_container \
  --output path/to/output
```

或者用 `@` 引用 key 文件：

```bash
./run.sh @path/to/aes_key.txt --ipa path/to/app.ipa --app path/to/app_container
```

如果不传 `--output`，默认输出到当前项目的 `output` 目录。

## Lua

Lua 单独执行，不会重复导出图片和数据。默认读取当前项目的 `paks`，输出到 `output/scripts`。

```bash
./lua.sh --aes-file path/to/aes_key.txt
```

自定义 PAK 目录和输出目录：

```bash
./lua.sh --aes-file path/to/aes_key.txt \
  --paks path/to/paks \
  --output path/to/output/scripts
```

默认只导出战斗、技能、buff 相关 Lua；加 `--all` 会导出全部 Lua。输出中 `luac` 是已解密的标准 Lua 5.4 bytecode，`disasm` 是可读反汇编文本。

## 处理流程

`./run.sh` 执行时会依次完成：

1. 检查 `.NET SDK`、`uv` 或 Python、Node.js、`unzip`。
2. 缺少运行环境时，优先在项目内准备本地环境。
3. 从 `--ipa` 和 `--app` 收集 `.pak`。
4. 解密并解包配置、表数据和图标资源。
5. 生成 `data` JSON，整理 `assets` WebP。
6. 默认清理 `temp` 中间目录。

## 输出结构

```text
path/to/output/
  assets/
    webp/
      pets/
        JL_*.webp
      items/
        *.webp
  data/
    BinData/
      *.json
    tables/
      *.json
    pets/
      *.json
    Pets.json
    items.json
    moves.json
    magic_items.json
    PetSkillIndex.json
    bloodline_index.json
    handbook-rewards.json
    types.json
  scripts/
    luac/
      battle/
        *.luac
    disasm/
      battle/
        *.luasm
```

图片目录：

- `assets/webp/pets`：精灵头像，来自 `System/Common/Icon/Pet1024`。
- `assets/webp/items`：物品、技能、特性、UI 图标等，包含 `SkillIcon`。

## 常用参数

```text
--aes-file path/to/aes_key.txt   从文件读取 AES key
--ipa path/to/app.ipa            从 IPA 收集基础 pak
--app path/to/app_container      从 App 容器收集补丁 pak
--output path/to/output          自定义输出目录
--language zh_CN                 本地化语言，默认 zh_CN
--keep-temp                      保留 temp，方便排查中间产物
```

`./lua.sh` 额外支持：

```text
--paks path/to/paks              指定已有 PAK 目录
--output path/to/output/scripts  指定 Lua 输出根目录
--all                            导出全部 Lua
--bytecode-only                  只写 luac
--disasm-only                    只写 disasm
```

## 环境要求

运行脚本需要：

- `.NET SDK`
- `uv`
- `Node.js`
- `unzip`

缺少环境时的处理方式：

- `.NET SDK` 不存在时，尝试安装到 `.tools/dotnet`。
- `uv` 存在时使用 `uv run python`。
- `uv` 不存在但有 Python 时，使用 `.venv`。
- Node.js 不存在但有 Homebrew 时，尝试 `brew install node`。

## 排错

AES key 必须是 64 位十六进制字符串。key 文件中的换行和空白会被自动清理。

如果输出没有图片，脚本会直接失败。可以加 `--keep-temp` 后检查：

```bash
./run.sh --aes-file path/to/aes_key.txt \
  --ipa path/to/app.ipa \
  --app path/to/app_container \
  --keep-temp
```

然后查看：

```text
temp/assets/webp/pets
temp/assets/webp/items
```

`RAW WARN` 表示少量非关键原始文件被跳过，通常不影响 BinData 和 WebP。asset 解码失败会导致脚本退出。
