# TTK_ThirdLibs

Tora's toolkit - third libraries：以 git submodule 方式托管第三方开源库。

## 1. 仓库内容

| 项目 | 说明 |
|---|---|
| 第三方库 | Boost 1.89.0（tag `boost-1.89.0`，固定 commit `ef7fea3471`） |
| 位置 | `third_party/boost`（`boostorg/boost` 超级项目） |
| 已初始化 | 83 / 170 个嵌套子模块：79 个 `libs/` + 4 个 `tools/` |
| 目标库 | `geometry`、`serialization` 及 75 个已初始化的依赖库 |
| 依赖完整性 | 头文件闭包与 CMake 目标完整（离线校验与 CMake 配置均已通过） |
| 未初始化 | 其余 87 个子模块（77 个 `libs/` + 9 个 `tools/` 等）为空目录，按需补拉 |
| 许可证 | Boost Software License 1.0（`third_party/boost/LICENSE_1_0.txt`） |

## 2. 快速开始

### 2.1. 克隆并拉取依赖

```bash
git clone git@github.com:ToraSpencer/TTK_ThirdLibs.git
cd TTK_ThirdLibs
git submodule update --init third_party/boost

cd third_party/boost
git submodule update --init --force tools/boostdep
python -B tools/boostdep/depinst/depinst.py -g -- "--force" geometry
python -B tools/boostdep/depinst/depinst.py -g -- "--force" serialization
```

克隆后 `third_party/boost` 只有空骨架：<span style="background-color: #40E0D0;">Boost 嵌套子模块的初始化状态不会随仓库同步，必须用上述命令补拉。</span>

### 2.2. 在 CMake 中使用

```cmake
set(BOOST_INCLUDE_LIBRARIES geometry serialization)
add_subdirectory(third_party/boost EXCLUDE_FROM_ALL)

target_link_libraries(your_target PRIVATE Boost::geometry Boost::serialization)
```

`Boost::geometry` 要求 C++14；`Boost::serialization` 是需要编译的库（非 header-only）。依赖闭包已补齐，上述配置的 configure 与编译均已验证通过。

## 3. 注意事项

- <span style="background-color: #40E0D0;">更新 Boost 子模块时始终加 `--force`</span>，否则部分 git 版本会误报 `Unable to find current revision`。
- 不要使用 `git submodule update --init --recursive`：会尝试拉取 Boost 全部 170 个子模块。
- GitHub 访问不稳定时，先按操作说明的「网络不稳定时的处理」配置超时并重试。
- 完整操作（离线校验、状态查看、重试脚本、已知问题、新增第三方库）见 [操作说明.md](操作说明.md)。
