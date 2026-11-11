# TTK_ThirdLibs

Tora's toolkit - third libraries：以 git submodule 方式托管第三方开源库。

## 1. 仓库内容

| 项目 | 说明 |
|---|---|
| Boost | 1.89.0（tag `boost-1.89.0`，固定 commit `ef7fea3471`），位于 `third_party/boost/boost1.89.0`（`boostorg/boost` 超级项目） |
| Boost 初始化 | 170 / 170 个嵌套子模块全部初始化（浅克隆 `--depth 1`）；安装脚本需要完整头文件 |
| Eigen | 3.4.0（tag `3.4.0`，固定 commit `3147391d94`），位于 `third_party/eigen/eigen3.4.0`（GitLab `libeigen/eigen` 官方仓库）；header-only，无嵌套子模块 |
| OpenMesh | 7.0（tag `OpenMesh-7.0`，固定 commit `d1fdd45c`），位于 `third_party/openmesh/openmesh7.0`；官方 Git 服务器不可达，使用 GitLab.com 镜像，内容已与官方 7.0 发行包逐文件校验一致 |
| GTest | 1.5.0（tag `release-1.5.0`，固定 commit `c9d6f5e0`），位于 `third_party/gtest/gtest1.5.0`；上游 CMake 无 install 规则且强制 `/MT`，仓库内提供包装工程 `third_party/gtest/CMakeLists.txt` |
| 许可证 | Boost Software License 1.0；Eigen 主要为 MPL2；OpenMesh 为 3-clause BSD；GTest 为 3-clause BSD |

目录约定：`third_party/<库名>/<库名><版本>/`，版本目录本身就是 submodule 路径。目录名仅用于识别版本，权威版本仍由 gitlink 钉死。

## 2. 快速开始

### 2.1. 克隆并拉取依赖

```bash
git clone git@github.com:ToraSpencer/TTK_ThirdLibs.git
cd TTK_ThirdLibs
git submodule update --init third_party/boost/boost1.89.0
git submodule update --init third_party/eigen/eigen3.4.0
git submodule update --init third_party/openmesh/openmesh7.0
git submodule update --init third_party/gtest/gtest1.5.0

cd third_party/boost/boost1.89.0
git submodule update --init --recursive --depth 1 --jobs 8
```

克隆后 `third_party/boost/boost1.89.0` 只有空骨架：<span style="background-color: #40E0D0;">Boost 嵌套子模块的初始化状态不会随仓库同步，必须用上面的命令补拉。</span>推荐一次拉取全部 170 个子模块（浅克隆）；只做嵌入式使用时，也可以只拉 `geometry` + `serialization` 的依赖闭包，见[操作说明 §2.3](操作说明.md#23-只拉取依赖闭包可选)。Eigen、OpenMesh 与 GTest 都没有嵌套子模块，执行 `git submodule update --init` 后即可直接使用。

### 2.2. 在 CMake 中使用

```cmake
# Boost
set(BOOST_INCLUDE_LIBRARIES geometry serialization)
add_subdirectory(third_party/boost/boost1.89.0 EXCLUDE_FROM_ALL)
target_link_libraries(your_target PRIVATE Boost::geometry Boost::serialization)

# Eigen（可选：跳过其自带测试与文档的配置）
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(EIGEN_BUILD_DOC OFF CACHE BOOL "" FORCE)
add_subdirectory(third_party/eigen/eigen3.4.0 EXCLUDE_FROM_ALL)
target_link_libraries(your_target PRIVATE Eigen3::Eigen)

# OpenMesh（7.0 嵌入式用法：include 与编译定义需手动传播）
set(BUILD_APPS OFF CACHE BOOL "" FORCE)
add_subdirectory(third_party/openmesh/openmesh7.0 EXCLUDE_FROM_ALL)
target_compile_definitions(your_target PRIVATE _USE_MATH_DEFINES NOMINMAX _CRT_SECURE_NO_WARNINGS)
target_include_directories(your_target PRIVATE ${OPENMESH_INCLUDE_DIR})
target_link_libraries(your_target PRIVATE ${OPENMESH_LIBRARIES})

# GTest（third_party/gtest 是包装工程：1.5.0 上游 CMake 无 install 且强制 /MT）
add_subdirectory(third_party/gtest EXCLUDE_FROM_ALL)
target_link_libraries(your_target PRIVATE gtest_main)
```

`Boost::geometry` 要求 C++14；`Boost::serialization` 是需要编译的库（非 header-only）。Eigen 3.4 支持 C++03 及以上，推荐 C++14；`Eigen3::Eigen` 是 INTERFACE 目标，只传播 include 路径，不产生链接产物。OpenMesh 7.0 是需要编译的库（`OpenMeshCore` / `OpenMeshTools`），推荐 C++14；嵌入式模式下它不会传播 include 目录和 `_USE_MATH_DEFINES` / `NOMINMAX`，需按上面的写法手动补齐。GTest 1.5.0 为 C++98 静态库，`gtest_main` 已提供 `main()`。以上配置与示例编译均已验证通过（MSVC 2022）。

### 2.3. 预编译与安装

每个库提供一对安装脚本，把 Release / Debug 的 64 位静态库与头文件安装到仓库根的 `install/` 与 `debug_install/`：

| 库 | 脚本（Release / Debug） | 产物 |
|---|---|---|
| Boost 1.89.0 | `third_party/boost/build_release1.89.0.bat` / `build_debug1.89.0.bat` | `include/` + `libs/`（全部可编译静态库 + CMake 配置） |
| Eigen 3.4.0 | `third_party/eigen/build_release3.4.0.bat` / `build_debug3.4.0.bat` | `include/` + 空的 `libs/`（header-only） |
| OpenMesh 7.0 | `third_party/openmesh/build_release7.0.bat` / `build_debug7.0.bat` | `include/` + `libs/`（`OpenMeshCore`、`OpenMeshTools`） |
| GTest 1.5.0 | `third_party/gtest/build_release1.5.0.bat` / `build_debug1.5.0.bat` | `include/` + `libs/`（`gtest`、`gtest_main`） |

仓库根目录另有 `build_all_release.bat` / `build_all_debug.bat`，按上表顺序调用四个库的对应脚本：单个库失败不会中断其余库，全部结束后汇总结果，有失败时以非零退出码返回。

前置条件：CMake 在 `PATH` 中、安装 Visual Studio 2022、Boost 的全部嵌套子模块已初始化。输出统一为 x64 静态库。产物布局、CMake 用法与限制见 [操作说明.md §10](操作说明.md#10-预编译与安装脚本)。

## 3. 注意事项

- <span style="background-color: #40E0D0;">Eigen 官方仓库在 GitLab（`gitlab.com/libeigen/eigen`）。</span>GitHub 上的 `eigen-mirror/eigen` 属第三方镜像，本仓库不作为依赖源。
- <span style="background-color: #40E0D0;">OpenMesh 7.0 的官方 Git 服务器（RWTH GitLab）当前网络不可达，submodule 指向已校验的 GitLab.com 镜像。</span>镜像 tag 与官方 7.0 发行包逐文件一致；若镜像失效，可切换到同 commit 的其它镜像（见操作说明）。
- OpenMesh 7.0 无法用 win32 线程模型的 MinGW 编译（`mostream.hh` 依赖 `std::mutex`），请使用 MSVC 或 posix 线程版 MinGW。
- <span style="background-color: #40E0D0;">GTest 1.5.0 上游 CMake 没有 install 规则，并把 `/MD` 改写成 `/MT`。</span>本仓库用 `third_party/gtest/CMakeLists.txt` 包装其源码，保持 `/MD` 动态 CRT 并安装为静态库；链接时按配置选择 `install/gtest` 或 `debug_install/gtest`。
- 更新 Boost 子模块时始终加 `--force`，否则部分 git 版本会误报 `Unable to find current revision`。
- 拉取 Boost 子模块时使用 `--recursive --depth 1`：完整头文件需要全部 170 个子模块，浅克隆足够构建。
- 升级库版本时需同步重命名版本目录，并更新 `.gitmodules` 的 path/section 与 gitlink（见操作说明 §1.1.4）。
- GitHub 访问不稳定时，先按操作说明的「网络不稳定时的处理」配置超时并重试；GitLab 源不受 GitHub 的 `insteadOf` 改写影响。
- 完整操作（离线校验、状态查看、重试脚本、已知问题、新增第三方库、Eigen / OpenMesh / GTest 说明）见 [操作说明.md](操作说明.md)。
