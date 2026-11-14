#!/usr/bin/env bash
# 《幻想乡》GPT 独立样板：阿里云只读验证入口（不部署、不改线上服务）
# 运行：bash prototypes/gpt_zero_home/tests/server_verify.sh
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
GODOT="${GODOT_BIN:-}"
if [[ -z "$GODOT" ]]; then
  GODOT="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$GODOT" ]]; then
  echo "[ERROR] 找不到 Godot。请先设置 GODOT_BIN=/path/to/Godot_v4.6.3-stable_linux.x86_64" >&2
  exit 2
fi

OUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fantasia-gpt-home.XXXXXXXX")"
TEST_PROJECT="$OUT_DIR/project"
mkdir -p "$TEST_PROJECT"
cp -a "$PROJECT_DIR/." "$TEST_PROJECT/"
# 不用仓库已有截图覆盖真正的本次运行结果
rm -f "$TEST_PROJECT"/preview-*.png

echo "[INFO] Godot: $("$GODOT" --version)"
echo "[INFO] 临时测试目录：$OUT_DIR"
echo "[INFO] 仅处理独立样板副本：$TEST_PROJECT"
echo "[1/3] 项目资源导入 + 脚本解析"
"$GODOT" --headless --path "$TEST_PROJECT" --editor --import --quit 2>&1 | tee "$OUT_DIR/import.log"
if grep -E "SCRIPT ERROR|Parse Error|Failed loading resource|ERROR:.*[Ss]cript" "$OUT_DIR/import.log"; then
  echo "[FAIL] 导入或脚本解析错误" >&2
  exit 1
fi

echo "[2/3] 双端布局和上午/黄昏交互检查"
"$GODOT" --headless --path "$TEST_PROJECT" --script res://tests/smoke.gd 2>&1 | tee "$OUT_DIR/smoke.log"
if ! grep -q "SMOKE_OK" "$OUT_DIR/smoke.log"; then
  echo "[FAIL] 未发现 SMOKE_OK 标记" >&2
  exit 1
fi

echo "[3/3] xvfb 实际渲染截图"
if ! command -v xvfb-run >/dev/null 2>&1; then
  echo "[WARN] xvfb-run 不存在：跳过实际截图。编译通过不代表显示与触摸已验收。" | tee "$OUT_DIR/capture.log"
  echo "[INFO] 验证日志：$OUT_DIR"
  exit 0
fi
xvfb-run -a -s "-screen 0 1280x960x24" \
  "$GODOT" --path "$TEST_PROJECT" --rendering-driver opengl3 \
  --script res://tests/capture.gd 2>&1 | tee "$OUT_DIR/capture.log"
for image in preview-morning.png preview-dusk.png preview-phone-landscape.png preview-phone-portrait.png; do
  if [[ ! -s "$TEST_PROJECT/$image" ]]; then
    echo "[FAIL] 缺少截图 $image" >&2
    exit 1
  fi
done
if ! grep -q 'image=(390, 844)' "$OUT_DIR/capture.log"; then
  echo "[FAIL] 竖屏没有以 390x844 真实视口渲染" >&2
  exit 1
fi
if ! grep -q 'image=(853, 384)' "$OUT_DIR/capture.log"; then
  echo "[FAIL] 横屏没有以 853x384 真实视口渲染" >&2
  exit 1
fi

echo "[PASS] Godot 无界面脚本与不同视口截图检查完成。"
echo "[INFO] 截图：$TEST_PROJECT/preview-*.png"
echo "[INFO] 日志：$OUT_DIR/{import,smoke,capture}.log"
echo "[INFO] 仅保存在全新 /tmp 测试目录；没有部署、打开服务端口或修改生产项目。"
