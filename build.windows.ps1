$ErrorActionPreference = 'Stop'

$SCRIPT_DIR = (Resolve-Path ".").Path

$VERSION_FILE = Join-Path (Resolve-Path ".").Path "VERSION"
Get-Content $VERSION_FILE | Foreach-Object{
  $var = $_.Split('=')
  New-Variable -Name $var[0] -Value $var[1]
}

$PACKAGE_NAME = "windows"
$SOURCE_DIR = Join-Path (Resolve-Path ".").Path "_source\$PACKAGE_NAME"
$BUILD_DIR = Join-Path (Resolve-Path ".").Path "_build\$PACKAGE_NAME"
$PACKAGE_DIR = Join-Path (Resolve-Path ".").Path "_package\$PACKAGE_NAME"

if (!(Test-Path $BUILD_DIR)) {
  mkdir $BUILD_DIR
}

if (!(Test-Path $BUILD_DIR\vswhere.exe)) {
  Invoke-WebRequest -Uri "https://github.com/microsoft/vswhere/releases/download/2.8.4/vswhere.exe" -OutFile $BUILD_DIR\vswhere.exe
}

# https://github.com/microsoft/vswhere/wiki/Find-VC
Push-Location $BUILD_DIR
  $path = .\vswhere.exe -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
Pop-Location
if ($path) {
  $path = Join-Path $path 'Common7\Tools\vsdevcmd.bat'
  if (Test-Path $path) {
    cmd /s /c """$path"" $args && set" | Where-Object { $_ -match '(\w+)=(.*)' } | ForEach-Object {
      $null = New-Item -force -path "Env:\$($Matches[1])" -value $Matches[2]
    }
  }
}

# 代理设置
set http_proxy=10.2.110.233:26001
set https_proxy=10.2.110.233:26001

# WebRTC源码下载目录
$WEBRTC_DIR = "E:\webrtc\webrtc_src"

# WebRTC编译输出目录
$WEBRTC_BUILD_DIR = "E:\webrtc\webrtc_build"

# WebRTC环境变量
$Env:GYP_MSVS_VERSION = "2019"
$Env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"
$Env:PYTHONIOENCODING = "utf-8"

if (!(Test-Path $SOURCE_DIR)) {#判断目录是否存在，不存在则创建
  New-Item -ItemType Directory -Path $SOURCE_DIR
}

# depot_tools
if (!(Test-Path $SOURCE_DIR\depot_tools)) {#判断depot_tools目录是否存在，不存在则git克隆 
  Push-Location $SOURCE_DIR
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
  Pop-Location
} else {
  Push-Location $SOURCE_DIR\depot_tools
    git fetch #获取远程仓库的最新更改
    git checkout -f origin/HEAD #强制更新本地工作树以匹配远程仓库的HEAD分支，强制覆盖任何未提交的本地更改
  Pop-Location
}

$Env:PATH = "$SOURCE_DIR\depot_tools;$Env:PATH"
# Choco 删除
$Env:PATH = $Env:Path.Replace("C:\ProgramData\Chocolatey\bin;", "");

# WebRTC 源码拉取
if (!(Test-Path $WEBRTC_DIR)) {
  mkdir $WEBRTC_DIR
}
if (!(Test-Path $WEBRTC_DIR\src)) {
  Push-Location $WEBRTC_DIR
    gclient
    fetch webrtc
  Pop-Location
} else {
  Push-Location $WEBRTC_DIR\src
    git clean -xdf
    git reset --hard
    Push-Location build
      git reset --hard
    Pop-Location
    Push-Location third_party
      git reset --hard
    Pop-Location
    git fetch
  Pop-Location
}

if (!(Test-Path $WEBRTC_BUILD_DIR)) {
  mkdir $WEBRTC_BUILD_DIR
}
Push-Location $WEBRTC_DIR\src
  git checkout -f "$WEBRTC_COMMIT"
  git clean -xdf
  gclient sync

  # 打补丁
  git apply -p2 --ignore-space-change --ignore-whitespace --whitespace=nowarn $SCRIPT_DIR\patches\4k.patch
  git apply -p1 --ignore-space-change --ignore-whitespace --whitespace=nowarn $SCRIPT_DIR\patches\windows_add_deps.patch

  # WebRTC 编译
  gn gen $WEBRTC_BUILD_DIR\debug --args='is_debug=true rtc_include_tests=false rtc_use_h264=false is_component_build=false use_rtti=true use_custom_libcxx=false'
  ninja -C "$WEBRTC_BUILD_DIR\debug"

  gn gen $WEBRTC_BUILD_DIR\release --args='is_debug=false rtc_include_tests=false rtc_use_h264=false is_component_build=false use_rtti=true use_custom_libcxx=false'
  ninja -C "$WEBRTC_BUILD_DIR\release"
Pop-Location

foreach ($build in @("debug", "release")) {
  ninja -C "$WEBRTC_BUILD_DIR\$build"
}

# 生成许可证文件
Push-Location $WEBRTC_DIR\src
  python tools_webrtc\libs\generate_licenses.py --target :webrtc "$WEBRTC_BUILD_DIR\" "$WEBRTC_BUILD_DIR\debug" "$WEBRTC_BUILD_DIR\release"
Pop-Location


# WebRTC 打包
if (Test-Path $BUILD_DIR\package) {
  Remove-Item -Force -Recurse -Path $BUILD_DIR\package
}
mkdir $BUILD_DIR\package
mkdir $BUILD_DIR\package\webrtc
# WebRTC头文件抽取
robocopy "$WEBRTC_DIR\src" "$BUILD_DIR\package\webrtc\include" *.h *.hpp /S /NP /NFL /NDL

# webrtc.lib 复制
foreach ($build in @("debug", "release")) {
  mkdir $BUILD_DIR\package\webrtc\$build
  Copy-Item $WEBRTC_BUILD_DIR\$build\obj\webrtc.lib $BUILD_DIR\package\webrtc\$build\
}

# 复制许可证
Copy-Item "$WEBRTC_BUILD_DIR\LICENSE.md" "$BUILD_DIR\package\webrtc\NOTICE"

# WebRTC 写入版本信息
Copy-Item $VERSION_FILE $BUILD_DIR\package\webrtc\VERSIONS
Push-Location $WEBRTC_DIR\src
  Write-Output "WEBRTC_SRC_COMMIT=$(git rev-parse HEAD)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
  Write-Output "WEBRTC_SRC_URL=$(git remote get-url origin)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
Pop-Location
Push-Location $WEBRTC_DIR\src\build
  Write-Output "WEBRTC_SRC_BUILD_COMMIT=$(git rev-parse HEAD)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
  Write-Output "WEBRTC_SRC_BUILD_URL=$(git remote get-url origin)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
Pop-Location
Push-Location $WEBRTC_DIR\src\buildtools
  Write-Output "WEBRTC_SRC_BUILDTOOLS_COMMIT=$(git rev-parse HEAD)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
  Write-Output "WEBRTC_SRC_BUILDTOOLS_URL=$(git remote get-url origin)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
Pop-Location
Push-Location $WEBRTC_DIR\src\buildtools\third_party\libc++\trunk
  
  Write-Output "WEBRTC_SRC_BUILDTOOLS_THIRD_PARTY_LIBCXX_TRUNK=$(git rev-parse HEAD)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8

  Write-Output "WEBRTC_SRC_BUILDTOOLS_THIRD_PARTY_LIBCXX_TRUNK_COMMIT=$(git rev-parse HEAD)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
  Write-Output "WEBRTC_SRC_BUILDTOOLS_THIRD_PARTY_LIBCXX_TRUNK_URL=$(git remote get-url origin)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
Pop-Location
Push-Location $WEBRTC_DIR\src\buildtools\third_party\libc++abi\trunk
  
  Write-Output "WEBRTC_SRC_BUILDTOOLS_THIRD_PARTY_LIBCXXABI_TRUNK=$(git rev-parse HEAD)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8

  Write-Output "WEBRTC_SRC_BUILDTOOLS_THIRD_PARTY_LIBCXXABI_TRUNK_COMMIT=$(git rev-parse HEAD)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
  Write-Output "WEBRTC_SRC_BUILDTOOLS_THIRD_PARTY_LIBCXXABI_TRUNK_URL=$(git remote get-url origin)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
Pop-Location
Push-Location $WEBRTC_DIR\src\buildtools\third_party\libunwind\trunk
 
  Write-Output "WEBRTC_SRC_BUILDTOOLS_THIRD_PARTY_LIBUNWIND_TRUNK=$(git rev-parse HEAD)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8

  Write-Output "WEBRTC_SRC_BUILDTOOLS_THIRD_PARTY_LIBUNWIND_TRUNK_COMMIT=$(git rev-parse HEAD)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
  Write-Output "WEBRTC_SRC_BUILDTOOLS_THIRD_PARTY_LIBUNWIND_TRUNK_URL=$(git remote get-url origin)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
Pop-Location
Push-Location $WEBRTC_DIR\src\third_party
  Write-Output "WEBRTC_SRC_THIRD_PARTY_COMMIT=$(git rev-parse HEAD)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
  Write-Output "WEBRTC_SRC_THIRD_PARTY_URL=$(git remote get-url origin)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
Pop-Location
Push-Location $WEBRTC_DIR\src\tools
  Write-Output "WEBRTC_SRC_TOOLS_COMMIT=$(git rev-parse HEAD)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
  Write-Output "WEBRTC_SRC_TOOLS_URL=$(git remote get-url origin)" | Add-Content $BUILD_DIR\package\webrtc\VERSIONS -Encoding UTF8
Pop-Location

# 生成 webrtc.zip
if (!(Test-Path $PACKAGE_DIR)) {
  mkdir $PACKAGE_DIR
}
if (Test-Path $PACKAGE_DIR\webrtc.zip) {
  Remove-Item -Force -Path $PACKAGE_DIR\webrtc.zip
}
Push-Location $BUILD_DIR\package
  Compress-Archive -DestinationPath $PACKAGE_DIR\webrtc.zip -Path webrtc -Force
Pop-Location
