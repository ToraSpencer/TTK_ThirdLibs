# TTK_ThirdLibs

Tora's toolkit - third libraries：以 git submodule 方式托管第三方开源库。

## 1. 仓库内容

| 项目 | 说明 |
|---|---|
| Boost | 1.89.0（tag `boost-1.89.0`，固定 commit `ef7fea3471`），位于 `third_party/boost/boost1.89.0`（`boostorg/boost` 超级项目） |
| Boost 初始化 | 83 / 170 个嵌套子模块：79 个 `libs/` + 4 个 `tools/`；目标库 `geometry`、`serialization` 及 75 个依赖库；头文件闭包与 CMake 目标完整（离线校验与 CMake 配置均已通过） |
| Boost 未初始化 | 其余 87 个子模块（77 个 `libs/` + 9 个 `tools/` 等）为空目录，按需补拉 |
| Eigen | 3.4.0（tag `3.4.0`，固定 commit `3147391d94`），位于 `third_party/eigen/eigen3.4.0`（GitLab `libeigen/eigen` 官方仓库）；header-only，无嵌套子模块 |
| OpenMesh | 7.0（tag `OpenMesh-7.0`，固定 commit `d1fdd45c`），位于 `third_party/openmesh/openmesh7.0`；官方 Git 服务器不可达，使用 GitLab.com 镜像，内容已与官方 7.0 发行包逐文件校验一致 |
| 许可证 | Boost Software License 1.0；Eigen 主要为 MPL2；OpenMesh 为 3-clause BSD |

目录约定：`third_party/<库名>/<库名><版本>/`，版本目录本身就是 submodule 路径。目录名仅用于识别版本，权威版本仍由 gitlink 钉死。

## 2. 快速开始

### 2.1. 克隆并拉取依赖

```bash
git clone git@github.com:ToraSpencer/TTK_ThirdLibs.git
cd TTK_ThirdLibs
git submodule update --init third_party/boost/boost1.89.0
git submodule update --init third_party/eigen/eigen3.4.0
git submodule update --init third_party/openmesh/openmesh7.0

cd third_party/boost/boost1.89.0
git submodule update --init --force tools/boostdep
python -B tools/boostdep/depinst/depinst.py -g -- "--force" geometry
python -B tools/boostdep/depinst/depinst.py -g -- "--force" serialization
```

克隆后 `third_party/boost/boost1.89.0` 只有空骨架：<span style="background-color: #40E0D0;">Boost 嵌套子模块的初始化状态不会随仓库同步，必须用上述命令补拉。</span>Eigen 与 OpenMesh 都没有嵌套子模块，执行 `git submodule update --init` 后即可直接使用。

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
```

`Boost::geometry` 要求 C++14；`Boost::serialization` 是需要编译的库（非 header-only）。Eigen 3.4 支持 C++03 及以上，推荐 C++14；`Eigen3::Eigen` 是 INTERFACE 目标，只传播 include 路径，不产生链接产物。OpenMesh 7.0 是需要编译的库（`OpenMeshCore` / `OpenMeshTools`），推荐 C++14；嵌入式模式下它不会传播 include 目录和 `_USE_MATH_DEFINES` / `NOMINMAX`，需按上面的写法手动补齐。以上配置与示例编译均已验证通过（OpenMesh 使用 MSVC 2022）。

## 3. 注意事项

- <span style="background-color: #40E0D0;">Eigen 官方仓库在 GitLab（`gitlab.com/libeigen/eigen`）。</span>GitHub 上的 `eigen-mirror/eigen` 属第三方镜像，本仓库不作为依赖源。
- <span style="background-color: #40E0D0;">OpenMesh 7.0 的官方 Git 服务器（RWTH GitLab）当前网络不可达，submodule 指向已校验的 GitLab.com 镜像。</span>镜像 tag 与官方 7.0 发行包逐文件一致；若镜像失效，可切换到同 commit 的其它镜像（见操作说明）。
- OpenMesh 7.0 无法用 win32 线程模型的 MinGW 编译（`mostream.hh` 依赖 `std::mutex`），请使用 MSVC 或 posix 线程版 MinGW。
- 更新 Boost 子模块时始终加 `--force`，否则部分 git 版本会误报 `Unable to find current revision`。
- 不要使用 `git submodule update --init --recursive`：会尝试拉取 Boost 全部 170 个子模块。
- 升级库版本时需同步重命名版本目录，并更新 `.gitmodules` 的 path/section 与 gitlink（见操作说明 §1.1.4）。
- GitHub 访问不稳定时，先按操作说明的「网络不稳定时的处理」配置超时并重试；GitLab 源不受 GitHub 的 `insteadOf` 改写影响。
- 完整操作（离线校验、状态查看、重试脚本、已知问题、新增第三方库、Eigen / OpenMesh 说明）见 [操作说明.md](操作说明.md)。
