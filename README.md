# orangepi-build-native

**原生 ARM64（aarch64）构建 Orange Pi 镜像的开源补丁集/分支** —— 不需要 x86 主机，不需要 x86_64 交叉工具链。

> 上游：[orangepi-xunlong/orangepi-build](https://github.com/orangepi-xunlong/orangepi-build)（GPL-2.0）
> 本仓库不 fork 整个上游，而是提供 **patch + 一键脚本**，去掉上游里的 x86 假设。

## 已实机验证（2026-10-20）

在 **Orange Pi Zero 4（Allwinner A733，8 核，4GB）** 上，原生 aarch64 构建
**Orange Pi Zero 3W（T736/sun60iw2）** 的 Debian bookworm 镜像成功：

| 阶段 | 结果 |
|---|---|
| U-Boot v2018.05-sun60iw2 | ✅ 原生编译 + 厂商工具打包 boot0/boot_package（vendor x86 工具经 qemu-x86_64） |
| Linux 6.6.98-sun60iw2（Image + modules + dtbs） | ✅ 100% 原生 aarch64 编译，**无 x86 交叉编译器** |
| Debian bookworm rootfs | ✅ debootstrap 原生 |
| 镜像组装 | ✅ 3.2 GiB，MBR 分区起始 LBA 65536，挂载校验通过 |
| 耗时 | 首次全量约 ~1.5h；ccache 热之后完整重建 **17–25 分钟** |

产物：`Orangepizero3w_1.0.2_debian_bookworm_server_linux6.6.98.img`
SHA256 `dfb27109504ef42d8ff2c983c1a161d15e6bd801a9ae2f6b4330d1856c5724b1`

## 上游的 x86 假设 & 本补丁的修复

| # | 上游问题 | 修复 |
|---|---|---|
| 1 | `prepare_host()` 显式拒绝非 x86_64 主机 | 允许 arm64 |
| 2 | arm64 分支仍用 Debian qemu 元包/依赖列表 | 改为 `qemu-user-static` + `libc6-amd64-cross`（给厂商 x86 工具） |
| 3 | 只给 amd64 下载 x86_64 交叉工具链 | arm64 自动 `SKIP_EXTERNAL_TOOLCHAINS=yes`，用系统原生 gcc |
| 4 | U-Boot 源码自带 **x86 版 `scripts/dtc/dtc`**，make 直接复用 → `Exec format error` | 编译前删除，让 make 原生重建（脚本 apply-fixes.sh） |
| 5 | 老 U-Boot 2018 代码在新 gcc 下 `-Werror` 失败 | 编译前把 Makefile 的 `-Werror` 改为 `-Wno-error`（脚本 apply-fixes.sh） |
| 6 | `sun60iw2` 的 `uboot_custom_postprocess()` 写死 `dpkg --print-architecture == amd64` | 放开 arm64（否则 boot0/boot_package 不生成） |
| 7 | chroot 内 `debootstrap` 不在 PATH | 构建前 export PATH（setup-chroot.sh 已处理） |
| 8 | 板子访问 GitHub 不稳 → 源码拉取失败 | 支持 `OFFLINE_WORK=yes`：预先放好 u-boot/kernel 源码后不再联网拉取 |
| 9 | chroot 内 `/dev/loop0p1` 节点缺失 → rootfs 没写进镜像（但打印 "Done building"） | `partprobe` + 等待 + `mknod` 兜底（patch 已含） |

> 说明：厂商 `pack-uboot/tools/*.x86`（dragonseboot、update_boot0 等）是**闭源 x86-64 二进制**，
> ARM 上只能用 `qemu-x86_64-static -L /usr/x86_64-linux-gnu` 运行——这是整个流程**唯一**需要 x86 模拟的部分（几秒钟）。
> 32 位厂商 U-Boot 还需要 `arm-linux-gnueabi-gcc`（Ubuntu arm64 的 apt 包提供，仍是本机原生运行）。

## 用法

### 1) 在 ARM64 机器上准备原生 Ubuntu 20.04 chroot（推荐 focal，兼容 vendor 代码）

```bash
sudo ./scripts/setup-chroot.sh /opt/opi-build/rootfs-focal focal
```

### 2) 拉取上游 + 打补丁

```bash
git clone https://github.com/orangepi-xunlong/orangepi-build.git
cd orangepi-build && git checkout a05b3b4d5fc0dd4eb859f64c8a60f9b2c9e33cb1
patch -p1 < ../orangepi-build-native/patches/native-arm64.patch
../orangepi-build-native/scripts/apply-fixes.sh "$PWD"
```

### 3) 构建（在 chroot 内）

```bash
# 让 chroot 能看到 /dev/loop0p1
sudo mount --bind /proc  rootfs/proc
sudo mount --bind /dev   rootfs/dev
sudo mount --bind /sys   rootfs/sys
sudo mount --bind "$PWD" rootfs/opi
sudo chroot rootfs /bin/bash -lc '
  export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  cd /opi && OFFLINE_WORK=yes ./native-build.sh BOARD=orangepizero3w BRANCH=current RELEASE=bookworm
'
```

`native-build.sh` 等价于：

```bash
./build.sh BOARD=orangepizero3w BRANCH=current BUILD_OPT=image \
  RELEASE=bookworm BUILD_DESKTOP=no BUILD_MINIMAL=no KERNEL_CONFIGURE=no
```

- 首次构建需要联网下载 u-boot/kernel 源码（或提前放好 + `OFFLINE_WORK=yes`）
- 若板子访问 GitHub 困难：在 pad/PC 上开 `ssh -R 7897:127.0.0.1:7897 root@板子`，然后在 chroot 里
  `export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897`

## 目录结构

```
patches/native-arm64.patch     # 4 个上游脚本的修改（general/compilation/debootstrap/sun60iw2.conf）
scripts/apply-fixes.sh         # 处理二进制：pack tools qemu 包装、u-boot Makefile/dtc
scripts/setup-chroot.sh        # 在 ARM 上创建原生 Ubuntu/Debian chroot
native-build.sh                # 一键构建入口
docs/BUILD-LOG.md              # 本次构建的完整问题与验证记录
```

## License

GPL-2.0（与上游一致）。
