# 关于补丁开发支持工具

在本文档中，对为本仓库准备的补丁开发支援工具`patchdev.py`进行说明。`patchdev.py`在`scripts/patchdev.py`中。


## 目的

本工具的主要目的有以下两个。

-允许Git管理正在开发的补丁的源代码
-简化补丁开发中经常使用的操作，例如创建补丁文件


## 功能

本工具提供以下功能。

- 允许在libwebrtc仓库外编辑和管理开发中的源代码
- 将开发中的源代码加入libwebrtc中进行构建
- 制作补丁文件
- 生成JNI用的C/ c++头文件


## 对应平台

本工具在以下环境下运行。

- macOS
- Windows
- Linux


## 补丁开发的流程

パッチ開発の流れは次のようになります。

### プロジェクトを作成する

トップレベルで `patchdev.py init` を実行してプロジェクトを作成します。引数にプラットフォームとプロジェクト名を指定します。

例:

```
python3 scripts/patchdev.py init ios ios-simulcast
```

このコマンドは次の処理を行います:

1. プロジェクト用のディレクトリを作成する
2. パッチを適用せずにビルドを行う


#### プロジェクト用のディレクトリを作成する

 `patchdev` 以下にプロジェクト用のディレクトリ (`ios-simulcast`) が作成されます。このディレクトリには以下のファイルが含まれます。

```
Makefile
README.md
config.json
src/
```

`Makefile`定义了执行`patchdev.py`子命令的目标，可以使用`make`而不直接使用`patchdev.py`来操作。之后的说明使用`make`。

`README.md`是描述项目说明的文件。

`config.json`是关于补丁的设定文件。在下面的章节中进行说明。

`src`是配置要编辑的源代码的目录。复制并编辑这个目录中需要的源代码。不需要直接编辑顶级libwebrtc的源代码(`_source`以下)。

除此之外，还可以通过其他命令来创建`_build`。请不要将`_build`包含在仓库中。


#### 不打补丁就进行构建

创建项目目录后，不用打补丁就可以构建。通过这个构建获取libwebrtc的源代码，进行挂机的执行和构建文件的生成等，为补丁的开发提供必要的环境。
如果不需要构建，请指定`--nobuild`选项。


## 编辑设置文件

编辑`config.json`，并指定要编辑的源代码。下面是一个设置示例:

```
{
    "output": "ios_simulcast.patch",
    "platform": "ios",
    "build_flags": "--debug",
    "sources": [
        "sdk/BUILD.gn",
        "sdk/objc/base/RTCVideoCodecInfo.h",
        "sdk/objc/base/RTCVideoCodecInfo.m",
        "sdk/objc/api/peerconnection/RTCRtpEncodingParameters.h",
        "sdk/objc/api/peerconnection/RTCRtpEncodingParameters.mm",
        "sdk/objc/api/peerconnection/RTCVideoCodecInfo+Private.mm",
        "sdk/objc/api/video_codec/RTCVideoEncoderSimulcast.h",
        "sdk/objc/api/video_codec/RTCVideoEncoderSimulcast.mm",
        "sdk/objc/components/video_codec/RTCVideoEncoderFactorySimulcast.h",
        "sdk/objc/components/video_codec/RTCVideoEncoderFactorySimulcast.mm"
    ],

    # JNI用的设定。没有必要的话请无视。
    "jni_classpaths": ["sdk/android/api"],
    "jni_classes": {
        "org.webrtc.Example": "sdk/android/src/jni/example.h"
    }
}
```

- `output`: 指定补丁文件名。这个文件是用‘make patch’制作的。
- `platform`: 指定平台。这个值用于libwebrtc的源代码路径(`_source`)和构建时的选项(`run.py`)。
- `build_flags`: `run.py` 指定要提交的选项。
- `sources`: 指定要编辑的源代码的路径。
- `jni_classpaths`, `jni_classes`: 是JNI用的设定。后面会讲到。


### 不打补丁就构建(可选)

在libwebrtc的源代码中，有在建立(或取回)时生成的文件。如果你要编辑的源代码是自动生成的文件，那么你需要在不打补丁的情况下构建它。重新下载libwebrtc的仓库时也是一样。

想要在不打补丁的情况下构建，运行`make build-skip-patch`。这个命令根据`config.json`的设置执行`run.py`。但是，用`config.json`指定的补丁无视。


### 复制实体的源代码

编辑好设置文件后，运行' make sync '。`make sync`将配置文件中指定的源代码复制到`src`。以上述`config.json`为例，执行`make sync`后的目录如下所示。

```
└── src
    └── sdk
        ├── BUILD.gn
        └── objc
            ├── api
            │   ├── peerconnection
            │   │   ├── RTCRtpEncodingParameters.h
            │   │   ├── RTCRtpEncodingParameters.mm
            │   │   └── RTCVideoCodecInfo+Private.mm
            │   └── video_codec
            │       ├── RTCVideoEncoderSimulcast.h
            │       └── RTCVideoEncoderSimulcast.mm
            ├── base
            │   ├── RTCVideoCodecInfo.h
            │   └── RTCVideoCodecInfo.m
            └── components
                └── video_codec
                    ├── RTCVideoEncoderFactorySimulcast.h
                    └── RTCVideoEncoderFactorySimulcast.mm
```

添加要编辑的源代码时，请编辑`config.json`，添加源代码路径，然后再次执行`make sync`。`make sync`只复制`src`以下不存在的文件。


#### 生成JNI用的C/ c++头文件(可选)

如果你要为JNI开发补丁，你需要用`javah`生成C/ c++的头文件。编辑`config.json`，描述JNI的设置，执行`make JNI`。`make jni`运行`javah`来生成C/ c++的头文件，并输出`src`以下。
请事先在机器上安装`javah`。libwebrtc的源代码中包含用于构建的第三方工具，但不包含`javah`。

JNI `config.json`的设置示例如下:

```json
{
    "jni_classpaths": [
        "sdk/android/api"
    ],
    "jni_classes": {
        "org.webrtc.SimulcastVideoEncoder": "sdk/android/src/jni/simulcast_video_encoder.h"
    }
}
```

- `jni_classpaths`:指定类路径(`-classpath`选项)列表。指定的类路径将被应用到libwebrtc的源代码目录中。在上述例子中，传递到`javah`的类路径是`../ . ./_sources/sdk/android/api`(的绝对路径)。
- `jni_classes`:配对指定生成头部文件的类和输出文件路径。

在上面的示例设置中，在`make jni`中执行以下命令:

```
javah -classpath TOP/_source/android/webrtc/src/sdk/android/api -o simulcast_video_encoder.h org.webrtc.SimulcastVideoEncoder
```


### 安装补丁

补丁的开发`src`请编辑以下的源代码。

执行`make check`可以检查文件末端是否换行。在构建和补丁的时候会自动检查，但是请在手动检查的时候使用。


### 建造

运行`make build`后，将编辑好的源代码复制到libwebrtc的源代码目录中，然后用`run.py`构建。之后的行为与`run.py`相同。在顶级的`_build`以下输出构建结果。

### 生成补丁文件

运行`make patch`，它会生成一个补丁文件，汇总你编辑的源代码和原始源代码之间的差异。补丁文件在`config.json`的`output`中指定的文件名中`_build`以下输出。例如，在`output`中指定`ios_simulcast.patch`，就会生成`_build/ios_simulcast.patch`。

补丁开发结束后，请将生成的补丁文件复制到顶层`patches`。

另外，编辑的源代码文件的末端如果不是换行的话会出错。请在文件末端添加换行符之后再次执行`make patch`。

### 其他操作

#### 显示差分

执行`make diff`。除了生成补丁文件之外，`make diff`的行为与`make patch`相同。

#### 恢复对原始源代码的更改

执行`make clean`。恢复在运行`make build`时对原始源代码所做的改变。

## サブコマンド

以下は `patchdev.py` の各サブコマンドの詳細な説明です。 `init` 以外は、プロジェクトごとに生成される `Makefile` で実行できます。

### `init`

トップレベルの `patchdev` 以下に新しいプロジェクトを作成します。以下のファイルを生成します:

- `Makefile`: `patchdev.py` のサブコマンドを実行するターゲットを定義してあります。
- `config.json`: パッチに関する設定ファイルです。
- `src/`: このディレクトリにソースコードを配置します。設定ファイルでソースコードを指定して `make sync`を実行すると、オリジナルのファイルがこのディレクトリにコピーされます。


### `sync`

設定ファイルで指定したファイルを`src` にコピーします。ただし、既に `src` に存在するファイルはコピーされません。


### `build`

`src` のソースコードを libwebrtc のソースコードがあるディレクトリにコピーし、 `run.py` を使用してビルドします。設定ファイルで指定されたプラットフォームが対象になります。

`run.py` に渡すコマンドラインオプションを指定するには、渡したいオプションを設定ファイルで `build_flags` に指定します。

`--skip-patch` オプションを指定すると、パッチを適用せずにビルドします。


### `build-skip-patch` (`Makefile` のみ)

パッチを適用せずにビルドします。このコマンドは `Makefile` でのみ実行できます。 `patchdev.py build --skip-patch` と同じです。


### `check`

`src` のファイル終端の改行の有無をチェックします。改行が存在しなければエラーになります。


### `diff`

`src` のソースコードとオリジナルのソースコードとの差分を表示します。ファイル終端の改行の有無もチェックします。


### `patch`

パッチファイルを作成します。すべての差分を 1 つのファイルにまとめます。事前にファイル終端の改行の有無をチェックします。

パッチファイルは `_build` 以下に生成されます。ファイル名は設定ファイルの `output` で指定します。

パッチ開発が終わったら、パッチファイルをトップレベルの `patches` ディレクトリにコピーしてください。


### `clean`

`build` コマンドでオリジナルに加えたすべての変更を元に戻し、 `_build` を削除します。 `src` のファイルに影響はありません。
