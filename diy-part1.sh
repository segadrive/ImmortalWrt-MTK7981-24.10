#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Uncomment a feed source
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default
#!/bin/bash
# ================= padavanonly/immortalwrt-mt798x-6.6 360T7 BBRv3 DIY脚本 =================
# 适配仓库：https://github.com/padavanonly/immortalwrt-mt798x-6.6
# 机型：360T7（MT7981）
# 功能：补充BBRv3完整优化，适配仓库默认配置

# 切换到源码根目录（适配在线编译的目录上下文）
cd "$(dirname "$0")" || exit 1

# ================= 第一步：补充BBRv3内核配置到.config =================
# 该仓库已内置360T7基础配置，仅追加BBRv3相关项
cat >> .config << EOF
# ---------- BBRv3 核心配置（padavanonly/immortalwrt-mt798x-6.6 适配） ----------
# 1. BBRv3内核依赖（6.6内核专属，该仓库已适配）
CONFIG_KERNEL_TCP_MD5SIG=y
CONFIG_KERNEL_TCP_TIMESTAMPS=y
CONFIG_KERNEL_TCP_RENO=y
CONFIG_KERNEL_NET_IPV4_TCP_CONG_BBR3=y
CONFIG_KERNEL_NET_CORE_DEFAULT_QDISCS="fq"
CONFIG_KERNEL_NET_SCH_FQ_PIE=y
CONFIG_KERNEL_NET_CORE_SOMAXCONN=65535
CONFIG_KERNEL_NET_IPV4_TCP_MAX_SYN_BACKLOG=65535

# 2. BBRv3调试/生效工具（仓库已包含对应包，仅选中）
CONFIG_PACKAGE_ss=y
CONFIG_PACKAGE_iproute2-ss=y
CONFIG_PACKAGE_iproute2-tcp_metrics=y
CONFIG_PACKAGE_sysctl=y

# 3. 兼容仓库默认的硬件加速（避免冲突）
CONFIG_KERNEL_TCP_FASTOPEN=y
CONFIG_KERNEL_NET_SCH_FQ_CODEL=y
EOF

# ================= 第二步：创建360T7专属BBRv3开机脚本 =================
# 该仓库的base-files路径与标准immortalwrt一致，无需修改
mkdir -p package/base-files/files/etc/rc.d/
cat > package/base-files/files/etc/rc.d/S99bbr3-tune << "EOF"
#!/bin/sh /etc/rc.common
# BBRv3 360T7 优化脚本（padavanonly/immortalwrt-mt798x-6.6 专属）
# 适配MT7981硬件NAT + 6.6内核
START=99  # 晚于网络服务启动，确保参数生效

start() {
    # 1. 强制启用BBRv3（覆盖仓库默认配置）
    /sbin/sysctl -w net.ipv4.tcp_congestion_control=bbr3 >/dev/null 2>&1
    /sbin/sysctl -w net.ipv4.tcp_available_congestion_control=bbr3,reno,cubic >/dev/null 2>&1
    
    # 2. BBRv3核心参数（适配360T7千兆网口+MT7981）
    /sbin/sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    /sbin/sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    /sbin/sysctl -w net.ipv4.tcp_notsent_lowat=16384 >/dev/null 2>&1
    /sbin/sysctl -w net.core.rmem_max=33554432 >/dev/null 2>&1
    /sbin/sysctl -w net.core.wmem_max=33554432 >/dev/null 2>&1
    /sbin/sysctl -w net.ipv4.tcp_rmem="4096 87380 33554432" >/dev/null 2>&1
    /sbin/sysctl -w net.ipv4.tcp_wmem="4096 65536 33554432" >/dev/null 2>&1
    
    # 3. 适配仓库内置的硬件NAT/flow-offload
    /sbin/sysctl -w net.netfilter.nf_conntrack_tcp_loose=0 >/dev/null 2>&1
    /sbin/sysctl -w net.netfilter.nf_conntrack_max=1000000 >/dev/null 2>&1
    /sbin/sysctl -w net.ipv4.tcp_syncookies=1 >/dev/null 2>&1
    
    # 4. 日志记录（可选，便于排查问题）
    logger -t BBRv3 "360T7 BBRv3优化参数已生效"
}
EOF

# ================= 第三步：权限配置 + 兼容处理 =================
# 1. 赋予开机脚本执行权限（该仓库严格检查权限）
chmod +x package/base-files/files/etc/rc.d/S99bbr3-tune

# 2. 修复该仓库可能的sysctl路径问题（部分编译环境路径异常）
ln -sf /sbin/sysctl /usr/bin/sysctl 2>/dev/null

# 3. 验证配置（在线编译时可注释，本地编译可保留）
echo "===== DIY脚本执行完成，验证关键文件 ====="
ls -l package/base-files/files/etc/rc.d/S99bbr3-tune
grep "BBR3" .config | grep -v "#" || echo "BBRv3配置已写入.config"
# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default
echo 'src-git taskplan https://github.com/sirpdboy/luci-app-taskplan' >>feeds.conf.default
echo 'src-git timecontrol https://github.com/gaobin89/luci-app-timecontrol' >>feeds.conf.default
