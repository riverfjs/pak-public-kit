# pak-public-kit

<p>
  <img src="https://img.shields.io/badge/macOS-26.4-white?style=flat&labelColor=000000&color=white" alt="macOS 26.4" />
  <img src="https://img.shields.io/badge/.NET%20SDK-10.0.300-white?style=flat&labelColor=512BD4&color=white" alt=".NET SDK 10.0.300" />
  <img src="https://img.shields.io/badge/uv-0.11.8-white?style=flat&labelColor=000000&color=white" alt="uv 0.11.8" />
  <img src="https://img.shields.io/badge/Node.js-25.8.0-white?style=flat&labelColor=339933&color=white" alt="Node.js 25.8.0" />
  <img src="https://img.shields.io/badge/Python-3.9.6%20fallback-white?style=flat&labelColor=3776AB&color=white" alt="Python 3.9.6 fallback" />
  <img src="https://img.shields.io/badge/unzip-6.00-white?style=flat&labelColor=000000&color=white" alt="unzip 6.00" />
</p>

本项目用于从 PAK 中导出配置数据、图标资源和反编译后的 Lua 源码。主流程默认输出目录为 `output`。

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

如果没有传 `--decompiler` 或 `--unluac-lib`，脚本会自动准备本地工具：

- OpenJDK: `.tools/openjdk`
- unluac.jar: `.tools/unluac.jar`

若只需要补导历史上容易失败的 Lua 文件，可执行：

```bash
./lua.sh --aes-file path/to/aes_key.txt --fix-known-lua
```

默认导出完整 Lua 源码，写入 `output/scripts/lua`。`luac` 只作为反编译临时中间文件，不保留；不再生成 `luasm`。

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
      Game/
        NewRoco/
          Modules/
            System/
              Common/
                Icon/
                  HeadIcon/
                    3001.webp
                  BigHeadIcon256/
                    3001.webp
                  Pet1024/
                    JL_*.webp
                  Pet256/
                    JL_*.webp
                  BagItem/
                    *.webp
              BattleUI/
                Raw/
                  Atlas/
                    SkillIcon/
                      ...
  data/
    BinData/
      *.json
    tables/
      *.json
    pets/
      *.json
    Pets.json
    PetAssetIndex.json
    items.json
    moves.json
    SkillIconIndex.json
    magic_items.json
    PetSkillIndex.json
    bloodline_index.json
    handbook-rewards.json
    types.json
  scripts/
    lua/
      Common/
      Core/
      Data/
      NewRoco/
      *.lua
```


## 常用参数

```text
--aes-file path/to/aes_key.txt   从文件读取 AES key
--ipa path/to/app.ipa            从 IPA 收集基础 pak
--app path/to/app_container      从 App 容器收集补丁 pak
--output path/to/output          自定义输出目录
--language dir                   本地化语言目录；不传时从 BinLocalize 实际目录自动选择
--keep-temp                      保留 temp，方便排查中间产物
```

导出会优先读取 `BinLocalize` 下实际存在的本地化目录；当前 NRC 包通常是 `dev_CN`。如果手动传入的语言目录不存在，导出会回退到可用目录，否则物品和技能描述会是空值。

精灵图片不要按 ID 暴力拼路径，优先从 `data/PetAssetIndex.json` 或单个 `data/pets/<id>.json` 的 `assets.preview`、`assets.head.normal`、`assets.portrait` 读取。`assets` 只写入已实际导出的 WebP 路径，特殊形态会尽量使用配置图标、图鉴插图或 BigHeadIcon 中可用的一张作为 `preview`。

技能图片同理，优先从 `data/SkillIconIndex.json` 或 `moves.json` 的 `assets.preferred` 读取；若 `BattleUI/Raw/Atlas/SkillIcon/<icon>.webp` 不存在，会自动回退到 `Common/Icon/SkillBase/<icon>_png.webp`。

`./lua.sh` 额外支持：

```text
--paks path/to/paks              指定已有 PAK 目录
--output path/to/output/scripts  指定 Lua 输出根目录
--decompiler path                指定 unluac-cli 或 unluac.jar
--unluac-lib path                指定 FModel native unluac 库
--jobs n                         并发反编译数量，默认 CPU 核数
--timeout-ms n                   单个 Lua 反编译超时，默认 120000
--contains text                  只导出路径包含指定文本的 Lua，可重复
--fix-known-lua                  只补导 ProtoEnum、BattleAttackPlayer、Utils/Extend
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
temp/assets/webp/Game/NewRoco/Modules/System/Common/Icon
temp/assets/webp/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas
temp/assets/webp/Game/NewRoco/Modules/System/Activity
temp/assets/webp/Game/NewRoco/Modules/Activity
temp/assets/webp/Game/NewRoco/Modules/**/Raw
temp/assets/webp/Game/NewRoco/Modules/**/RawRes
```

`RAW WARN` 表示少量非关键原始文件被跳过，通常不影响 BinData 和 WebP。asset 解码失败会导致脚本退出。
