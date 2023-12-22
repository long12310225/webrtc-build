# 开发者用文档

## 本地构建

利用`run.py`，可以在本地构建WebRTC。

用以下命令构建

```
python3 run.py build <target>
```

`<target>` 的部分有`windows` や `ubuntu-20.04_x86_64` 等目标名称。

详细情况参考 `python3 run.py --help` 或 `python3 run.py build --help` 。

这样在`_build`以下目录中生成`libwebrtc.a`等库。

第一次执行build命令时，会自动下载WebRTC的源和工具，并在安装补丁后进行构建。

第二次执行build命令时，只进行build。不更新WebRTC源，也不重新执行gn gen。

再详细一点，在没有选项参数的情况下执行build命令时，进行以下操作。

- 如果没有需要的WebRTC源或工具，下载后给WebRTC源打上时雨堂补丁
- 在尚未存在ninja文件的情况下，用gn gen命令生成ninja文件
- 用ninja命令构建

在第二次执行中，WebRTC的源、工具和ninja文件已经存在，所以不进行获取和生成，只进行构建。

手动重写WebRTC源时，只需再次执行build命令即可。

### --webrtc-fetch

如果想从资料库重新获取WebRTC的源`--WebRTC -fetch`自变量。

```
python3 run.py build <target> --webrtc-fetch
```

这样WebRTC的源就变成了' VERSION '文件的' webrtc_commit '中所写的内容，然后在上面打补丁的状态下构建。

要注意的是，包括手动改写的部分和追加的文件在内，全部恢复原样。。

另外也存在丢弃所有已有的源重新获取`--webrtc-fetch-force`自变量。

### --webrtc-gen

同样的，如果想重新执行gn gen命令的话，利用`--webrtc-gen`自变量就可以了。

```
python3 run.py build <target> --webrtc-gen
```

这样一来，在gn gen重新实行的基础上被构建。

另外，现有的构建目录全部废弃重新生成`--webrtc-gen-force`自变量也存在。

### iOS和Android的构建

iOS的`WebRTC.xcframework`， Android的`webrtc.aar `，和其他情况一样可以用build命令生成。

但是`--webrtc-gen `命令无效，总是gn gen被执行。

另外，iOS和Android的`libwebrtc.a`只是想要的状况下，生成`WebRTC.xcframework`和`webrtc.aar`是徒劳的，
这种情况使用`--webrtc-nobuild-ios-framework`或者`--webrtc-nobuild-android-aar`就可以了。

### 目录结构

- 源配置在`_source`以下，构建成果配置在`_build`以下。
- `_source/<target>/` 和 `_build/<target>/` 像这样`_source` 和`_build` 都可以根据目标分类到不同的目录。
- `_build/<target>/<configuration>` 像这样`_build` 是调试构建还是发布构建，被分成不同的目录。

也就是说，默认情况下是这样的。。

```
webrtc-build/
|-- _source/
|   |-- ubuntu-20.04_x86_64/
|   |   |-- depot_tools/...
|   |   `-- webrtc/...
|   `-- android/
|       |-- depot_tools/...
|       `-- webrtc/...
`-- _build/
    |-- ubuntu-20.04_x86_64/
    |   |-- debug/
    |   |   `-- webrtc/...
    |   `-- release/
    |       `-- webrtc/...
    `-- android/
        |-- debug/
        |   `-- webrtc/...
        `-- release/
            `-- webrtc/...
```

另外，可以通过指定以下的选项，将源目录和构建目录变更到任意的场所。。

- `--source-dir`: 源目录
  - 默认是`<run.py的目录>/_source/<target名>`
- `--webrtc-source-dir`: 配置WebRTC源的目录。`--source-dir` 优先设定自己的设定
  - 默认是 `<source-dir>/webrtc`
- `--build-dir`: 构建目录
  - 默认是 `<run.py的目录>/_build/<target名>/<configuration>`
- `--webrtc-build-dir`: 配置WebRTC构建成果的目录。`--build-dir` 优先设定自己的设定。
  - 默认是 `<build-dir>/webrtc`

这些目录能够通过来自当前目录的相对路径来指定。

### 制限

本地构建有以下限制:

- Windows的环境只有 `windows` 才能构建。
- macOS 的环境只有 `macos_x86_64`, `macos_arm64`, `ios` 才能构建 。
- Ubuntu 的 x86_64 环境以下都可以构建。
  - `android`, `raspberry-pi-os_armv*`, `ubuntu-*_armv8` 无论Ubuntu版本，都可以构建ARM环境
  - `ubuntu-18.04_x86_64` 需要 Ubuntu 18.04
  - `ubuntu-20.04_x86_64` 需要 Ubuntu 20.04
- 在非Ubuntu x86 64的环境下无法构建。
- Ubuntu以外的Linux系统无法构建。
