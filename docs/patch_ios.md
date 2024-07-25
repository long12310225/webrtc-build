# 关于面向iOS的补丁

## 内容

- 抑制连接时对麦克风的分配请求。

- 添加了显式地初始化麦克风的API。
  安装补丁后麦克风不会自动初始化。

- ``AVAudioSession`` 的初始化时所设置的类别 从``AVAudioSessionCategoryPlayAndRecord`` 改为``AVAudioSessionCategoryAmbient`` 。


## 贴片后的使用方法

- 如果使用麦克风函数 ``RTCAudioSession.initializeInput(completionHandler:)`` 进行初始化。
  - 该方法是在麦克风被使用之前异步等待，必要时初始化。如果没有麦克风的使用许可，就要求用户进行分配。
  - 为每个连接执行。连接结束后，麦克风回到初始化前的状态。
  - 在实行前 ``RTCAudioSessionConfiguration.webRTCConfiguration.category`` 设置麦克风可用的类别。 ``AVAudioSessionCategoryPlayAndRecord``等
- 如果不使用麦克风，就不必在``Info.plist``中记载麦克风的用途。


## `RTCAudioSession` 关于摇滚

对补丁进行变更时要注意锁定`RTCAudioSession`的时机。
在执行中，如果用configureWebRTCSession`等方法变更`RTCAudioSession`的设定时，需要进行锁定。
锁定通过`lockForConfiguration`进行，通过`unlockForConfiguration`解除。
例如，为了适当地锁定并执行‘configureWebRTCSession’，将前后像下面这样‘lockForConfiguration’用`unlockForConfiguration`围起来:

```
[session lockForConfiguration];
bool success = [session configureWebRTCSession:nil];
[session unlockForConfiguration];
```

`lockForConfiguration`在补丁实现时用递归锁实现，现在用互斥锁(mutex)实现。
应该注意的是，在多个地方(包括其他线程)锁定的情况下，其他地方的执行会停止，直到第一个锁被解除为止。

补丁中追加` - [rtcaudiosession s t a r t voiceprocessingaudiounit:] `是` rtcaudiosession `为了设定的变更进行摇滚。
`startVoiceProcessingAudioUnit:` 在 `VoiceProcessingAudioUnit::Initialize()` (`sdk/objc/native/src/audio/voice_processing_audio_unit.mm`) 被调用。
`VoiceProcessingAudioUnit::Initialize()` 从以下几个地方被称为:

- `AudioDeviceIOS::InitPlayOrRecord()` (`sdk/objc/native/src/audio/audio_device_ios.mm`)
- `AudioDeviceIOS::HandleSampleRateChange()` (`sdk/objc/native/src/audio/audio_device_ios.mm`)
- `AudioDeviceIOS::UpdateAudioUnit()` (`sdk/objc/native/src/audio/audio_device_ios.mm`)

`AudioDeviceIOS::InitPlayOrRecord()` はロックした状態で `VoiceProcessingAudioUnit::Initialize()` を呼んでいるが、 `AudioDeviceIOS::HandleSampleRateChange()` は呼び出し元をたどってもロックされていない (と思われる) 。

另外 `AudioDeviceIOS::UpdateAudioUnit()` 也没有被套牢
在 `ConfigureAudioSession()`方法中调用 `ConfigureAudioSession()` 内でロックしている (`-[RTCAudioSession configureWebRTCSession:]` を呼んでいる) ので、もしこの時点でロックされていればデッドロックするはず。
したがって、この直後で呼ばれる `VoiceProcessingAudioUnit::Initialize()` はロックせずに呼ばれていることになる。

もしその実装が正しいのであれば、 `VoiceProcessingAudioUnit::Initialize()` の呼び出しはロック不要であり、 `AudioDeviceIOS::InitPlayOrRecord()` で行うロックは意味がない。
そこで、パッチでは `AudioDeviceIOS::InitPlayOrRecord()` 内で `VoiceProcessingAudioUnit::Initialize()` を呼ぶ前にロックを解除している。
次に該当のパッチを示す:

```
--- a/sdk/objc/native/src/audio/audio_device_ios.mm
+++ b/sdk/objc/native/src/audio/audio_device_ios.mm
@@ -913,8 +913,14 @@ bool AudioDeviceIOS::InitPlayOrRecord() {
       audio_unit_.reset();
       return false;
     }
+    // NOTE(enm10k): lockForConfiguration の実装が recursive lock から non-recursive lock に変更されたタイミングで、
+    // この関数内の lock と、 audio_unit_->Initialize 内で実行される startVoiceProcessingAudioUnit が取得しようとするロックが競合するようになった
+    // パッチ前の処理はロックの粒度を大きめに取っているが、以降の SetupAudioBuffersForActiveAudioSession や audio_unit_->Initialize は lock を必要としていないため、
+    // ここで unlockForConfiguration するように修正する
+    [session unlockForConfiguration];
     SetupAudioBuffersForActiveAudioSession();
     audio_unit_->Initialize(playout_parameters_.sample_rate());
+    return true;
   }
```
