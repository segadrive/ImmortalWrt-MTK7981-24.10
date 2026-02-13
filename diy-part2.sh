#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
sed -i 's/192.168.6.1/192.168.1.1/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/360T7/g' package/base-files/files/bin/config_generate
#!/bin/bash
cd openwrt

# 启用 BBRv3 核心配置（6.1内核原生支持）
./scripts/config -e CONFIG_KERNEL_TCP_CONG_ADVANCED
./scripts/config -e CONFIG_KERNEL_TCP_CONG_BBR3
# 设置 BBRv3 为默认拥塞控制算法
./scripts/config --set-str CONFIG_KERNEL_DEFAULT_TCP_CONG "bbr3"

# 优化 360T7 性能（可选）
./scripts/config -e CONFIG_KERNEL_CPU_FREQ_GOV_PERFORMANCE
./scripts/config -e CONFIG_KERNEL_NET_SCH_CAQ
./scripts/config -e CONFIG_KERNEL_NET_SCH_HTB

# 更新配置
make defconfig
