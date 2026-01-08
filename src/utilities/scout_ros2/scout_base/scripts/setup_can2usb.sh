#!/usr/bin/env bash
set -euo pipefail

# --------------------------
# 可根据需要修改的参数
# --------------------------
BITRATE=500000
CAN_IFACE=can0
KMOD=gs_usb
UDEV_RULE_FILE="/etc/udev/rules.d/80-${CAN_IFACE}-auto-up.rules"

# --------------------------
# 基础检查：必须用 root 运行
# --------------------------
if [[ "$EUID" -ne 0 ]]; then
  echo "请用 root 运行本脚本，例如："
  echo "  sudo $0"
  exit 1
fi

# 找到 ip 命令的绝对路径，保证 udev 能找到
IP_PATH="$(command -v ip || true)"
if [[ -z "${IP_PATH}" ]]; then
  echo "错误：找不到 ip 命令，请确认已安装 iproute2。"
  exit 1
fi

echo "使用 ip 命令路径：${IP_PATH}"
echo "CAN 接口：${CAN_IFACE}，比特率：${BITRATE}"
echo "内核模块：${KMOD}"
echo "udev 规则文件：${UDEV_RULE_FILE}"
echo

# --------------------------
# 1. 加载 gs_usb 内核模块（当前会话）
# --------------------------
echo "[1/4] 加载内核模块 ${KMOD} ..."
modprobe "${KMOD}" || echo "警告：modprobe ${KMOD} 失败，请检查内核是否支持该模块。"

# 如需确保每次开机都加载模块，可以取消下面两行的注释：
# echo "${KMOD}" > "/etc/modules-load.d/${KMOD}.conf"
# echo "已写入 /etc/modules-load.d/${KMOD}.conf，开机会自动加载 ${KMOD}"

# --------------------------
# 2. 立刻尝试 bring up can0（方便用户测试）
# --------------------------
echo "[2/4] 尝试立刻拉起 ${CAN_IFACE}（如果当前已经存在）..."
if ip link show "${CAN_IFACE}" >/dev/null 2>&1; then
  ip link set "${CAN_IFACE}" down || true
  ip link set "${CAN_IFACE}" up type can bitrate "${BITRATE}" || true
  echo "当前会话中 ${CAN_IFACE} 已尝试设置为 UP。"
else
  echo "当前系统中还没有 ${CAN_IFACE}（可能 USB-CAN 尚未插入 / 识别），跳过即时配置。"
fi

# --------------------------
# 3. 安装 can-utils（如果没装的话也没关系，反正是一次性操作）
# --------------------------
echo "[3/4] 安装 can-utils（如果已安装会自动跳过）..."
apt-get update -y || true
apt-get install -y can-utils || true

# --------------------------
# 4. 创建 udev 规则：can0 出现时自动 up
# --------------------------
echo "[4/4] 写入 udev 规则，使 ${CAN_IFACE} 每次出现时自动设置为 UP ..."

cat > "${UDEV_RULE_FILE}" <<EOF
# Auto bring up ${CAN_IFACE} with bitrate ${BITRATE} when USB-CAN appears
ACTION=="add", SUBSYSTEM=="net", KERNEL=="${CAN_IFACE}", RUN+="${IP_PATH} link set ${CAN_IFACE} up type can bitrate ${BITRATE}"
EOF

echo "已写入 udev 规则：${UDEV_RULE_FILE}"
cat "${UDEV_RULE_FILE}"
echo

# 重新加载 udev 规则
echo "重新加载 udev 规则..."
udevadm control --reload-rules

# 如果 ${CAN_IFACE} 已经存在，则模拟一次 add 事件，立刻生效
if [[ -e "/sys/class/net/${CAN_IFACE}" ]]; then
  echo "检测到当前已有 ${CAN_IFACE}，触发一次 udev add 事件以立即应用规则..."
  udevadm trigger --action=add "/sys/class/net/${CAN_IFACE}"
else
  echo "当前尚无 /sys/class/net/${CAN_IFACE}。"
  echo "之后只要插入 USB-CAN 或开机识别到 ${CAN_IFACE}，udev 就会自动将其设置为 UP。"
fi

echo
echo "全部完成。以后每次插入 USB-CAN 或开机识别到 ${CAN_IFACE} 时，会自动执行："
echo "  ${IP_PATH} link set ${CAN_IFACE} up type can bitrate ${BITRATE}"
echo

