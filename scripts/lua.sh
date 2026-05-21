#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

usage() {
    echo "Lua 源码导出"
    echo ""
    echo "用法:"
    echo "  ./lua.sh <AES-KEY> [--paks path/to/paks] [--output path/to/output/scripts]"
    echo "  ./lua.sh --aes-file path/to/aes_key.txt [--paks path/to/paks] [--output path/to/output/scripts]"
    echo "  ./lua.sh --aes-file path/to/aes_key.txt --fix-known-lua"
    echo ""
    echo "默认:"
    echo "  --paks     ./paks"
    echo "  --output   ./output/scripts"
    echo "  --timeout-ms 120000"
    echo "  decompiler: 自动下载/使用 .tools/openjdk + .tools/unluac.jar"
    echo "  默认导出完整 Lua 源码，luac 只作为临时中间文件"
    echo ""
    echo "输出:"
    echo "  lua/             反编译还原的 Lua 源码，按 Common/Core/Data/NewRoco 等目录分类"
    echo ""
    echo "选项:"
    echo "  --decompiler     指定 unluac-cli 或 unluac.jar"
    echo "  --unluac-lib     指定 FModel native unluac 库"
    echo "  --jobs           并发反编译数量，默认 CPU 核数"
    echo "  --timeout-ms     单个 Lua 反编译超时，默认 120000"
    echo "  --contains       只导出路径包含指定文本的 Lua，可重复"
    echo "  --fix-known-lua  只补导 ProtoEnum、BattleAttackPlayer、Utils/Extend"
}

have() {
    command -v "$1" >/dev/null 2>&1
}

ensure_dotnet() {
    if have dotnet; then
        DOTNET_BIN="$(command -v dotnet)"
        info ".NET: $("$DOTNET_BIN" --version)"
        return
    fi

    if [[ -x "$ROOT/.tools/dotnet/dotnet" ]]; then
        DOTNET_BIN="$ROOT/.tools/dotnet/dotnet"
        export DOTNET_ROOT="$ROOT/.tools/dotnet"
        export PATH="$DOTNET_ROOT:$PATH"
        info ".NET: $("$DOTNET_BIN" --version) (local)"
        return
    fi

    warn ".NET SDK not found; trying local install into $ROOT/.tools/dotnet"
    have curl || error "curl not found. Install .NET SDK manually: https://dotnet.microsoft.com/download"

    mkdir -p "$ROOT/.tools/dotnet"
    local installer="$ROOT/.tools/dotnet-install.sh"
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$installer" \
        || error "Failed to download dotnet-install.sh"
    bash "$installer" --channel 10.0 --install-dir "$ROOT/.tools/dotnet" --no-path \
        || error "Failed to install .NET SDK locally"

    DOTNET_BIN="$ROOT/.tools/dotnet/dotnet"
    export DOTNET_ROOT="$ROOT/.tools/dotnet"
    export PATH="$DOTNET_ROOT:$PATH"
    info ".NET installed: $("$DOTNET_BIN" --version)"
}

ensure_java() {
    if [[ -x "$ROOT/.tools/openjdk/bin/java" ]]; then
        JAVA_HOME="$ROOT/.tools/openjdk"
        export JAVA_HOME
        export PATH="$JAVA_HOME/bin:$PATH"
        info "Java: $("$JAVA_HOME/bin/java" -version 2>&1 | head -n 1) (local)"
        return
    fi

    if have java; then
        info "Java: $(java -version 2>&1 | head -n 1)"
        return
    fi

    warn "Java not found; installing local OpenJDK into $ROOT/.tools/openjdk"
    have curl || error "curl not found. Install Java manually or pass --unluac-lib."
    mkdir -p "$ROOT/.tools"

    local os arch adoptium_os adoptium_arch
    os="$(uname -s)"
    arch="$(uname -m)"
    case "$os" in
        Darwin) adoptium_os="mac" ;;
        Linux)  adoptium_os="linux" ;;
        *) error "Unsupported OS for automatic OpenJDK install: $os" ;;
    esac
    case "$arch" in
        arm64|aarch64) adoptium_arch="aarch64" ;;
        x86_64|amd64)  adoptium_arch="x64" ;;
        *) error "Unsupported CPU architecture for automatic OpenJDK install: $arch" ;;
    esac

    local archive url java_bin java_home
    archive="$ROOT/.tools/openjdk21.tar.gz"
    url="https://api.adoptium.net/v3/binary/latest/21/ga/$adoptium_os/$adoptium_arch/jdk/hotspot/normal/eclipse"
    curl -L --fail --retry 3 -o "$archive" "$url" \
        || error "Failed to download OpenJDK"
    tar -xzf "$archive" -C "$ROOT/.tools" \
        || error "Failed to extract OpenJDK"

    java_bin="$(find "$ROOT/.tools" -maxdepth 6 -type f -path "*/bin/java" | head -n 1)"
    [[ -n "$java_bin" ]] || error "OpenJDK extracted but java binary was not found"
    java_home="$(cd "$(dirname "$java_bin")/.." && pwd)"
    ln -sfn "$java_home" "$ROOT/.tools/openjdk"

    JAVA_HOME="$ROOT/.tools/openjdk"
    export JAVA_HOME
    export PATH="$JAVA_HOME/bin:$PATH"
    info "Java installed: $("$JAVA_HOME/bin/java" -version 2>&1 | head -n 1)"
}

ensure_unluac_jar() {
    UNLUAC_JAR="$ROOT/.tools/unluac.jar"
    if [[ -s "$UNLUAC_JAR" ]]; then
        info "unluac.jar: $UNLUAC_JAR"
        return
    fi

    warn "unluac.jar not found; downloading into $UNLUAC_JAR"
    have curl || error "curl not found. Pass --decompiler or --unluac-lib manually."
    mkdir -p "$ROOT/.tools"
    curl -L --fail --retry 3 -o "$UNLUAC_JAR" \
        https://sourceforge.net/projects/unluac/files/latest/download \
        || error "Failed to download unluac.jar"
    info "unluac.jar downloaded: $UNLUAC_JAR"
}

prepare_lua_args() {
    LUA_ARGS=()
    local has_decompiler=0
    local has_unluac_lib=0
    local has_timeout=0
    local fix_known=0
    local decompiler_path=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --decompiler)
                [[ $# -ge 2 ]] || error "--decompiler requires a path"
                has_decompiler=1
                decompiler_path="$2"
                LUA_ARGS+=("$1" "$2")
                shift 2
                ;;
            --unluac-lib)
                [[ $# -ge 2 ]] || error "--unluac-lib requires a path"
                has_unluac_lib=1
                LUA_ARGS+=("$1" "$2")
                shift 2
                ;;
            --timeout-ms)
                [[ $# -ge 2 ]] || error "--timeout-ms requires a value"
                has_timeout=1
                LUA_ARGS+=("$1" "$2")
                shift 2
                ;;
            --fix-known-lua)
                fix_known=1
                shift
                ;;
            *)
                LUA_ARGS+=("$1")
                shift
                ;;
        esac
    done

    if [[ "$has_unluac_lib" -eq 0 ]]; then
        if [[ "$has_decompiler" -eq 0 ]]; then
            ensure_java
            ensure_unluac_jar
            LUA_ARGS+=(--decompiler "$UNLUAC_JAR")
        elif [[ "$decompiler_path" == *.jar ]]; then
            ensure_java
        fi
    fi

    if [[ "$has_timeout" -eq 0 ]]; then
        if [[ "$fix_known" -eq 1 ]]; then
            LUA_ARGS+=(--timeout-ms 300000)
        else
            LUA_ARGS+=(--timeout-ms "${LUA_TIMEOUT_MS:-120000}")
        fi
    fi

    if [[ "$fix_known" -eq 1 ]]; then
        LUA_ARGS+=(
            --jobs 1
            --contains ProtoEnum
            --contains BattleAttackPlayer
            --contains Utils/Extend
        )
    fi
}

if [[ $# -eq 0 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

ensure_dotnet
prepare_lua_args "$@"

"$DOTNET_BIN" restore "$SCRIPT_DIR/extract_paks/ExtractPaks.csproj" /p:SkipNatives=true
"$DOTNET_BIN" run /p:SkipNatives=true --project "$SCRIPT_DIR/extract_paks/ExtractPaks.csproj" -- --extract-lua "${LUA_ARGS[@]}"
