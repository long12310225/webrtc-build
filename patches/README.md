# パッチ解説

## 4k.patch


## add_dep_zlib.patch


## android_fixsegv.patch


## android_onremovetrack.patch


## android_simulcast.patch


## android_webrtc_version.patch


## ios_bitcode.patch

M95からiOSビルド時に `-gdwarf-aranges` ビルドオプションが追加された。
この `-gdwarf-aranges` はiOSでbitcodeを生成するためのビルドオプション `-fembed-bitcode` と両立できない。
M94以前を用いたSora iOS SDKではbitcode出力設定をONにした状態でのビルドを行えるため、従来の設定を踏襲するためにパッチを当てている。

問題の原因となる本家の変更: https://chromium-review.googlesource.com/c/chromium/src/+/3092732
本家に対してパッチ送信済み: https://chromium-review.googlesource.com/c/chromium/src/+/3223221

以下のいずれかの条件下にて本パッチは削除できます

1. パッチが本家に取り込まれる
2. 1.以外の方法で `-gdwarf-aranges` と `-fembed-bitcode` が両立できるように本家で対応される
3. SDK提供時にbitcode出力が不要と判断される

## ios_manual_audio_input.patch


## ios_simulcast.patch


## macos_av1.patch


## macos_h264_encoder.patch


## macos_screen_capture.patch


## macos_simulcast.patch


## nacl_armv6_2.patch


## ubuntu_nolibcxx.patch


## windows_add_deps.patch


## ssl_verify_callback_with_native_handle.patch

WebRTC は Let's Encrypt のルート証明書を入れていないため、検証コールバックで検証する必要がある。
しかし WebRTC の検証コールバックから渡される `BoringSSLCertificate` には、検証に失敗した証明書だけが渡され、証明書チェーンが一切含まれていないため、正しく検証ができない。
なので BoringSSL のネイティブハンドル `SSL*` を `BoringSSLCertificate` に含めるようにする。

WebRTC は Let's Encrypt を含めていないので、Let's Encrypt の検証がうまくできないという点から本家に取り込んでもらうのは難しいと思われる。
証明書チェーンが利用できない、という話を起点にすれば取り込んでもらえるかもしれない。
ただし `SSL*` を渡すのは `OpenSSLCertificate` との兼ね合いを考えると筋が悪いので、本家用のパッチを書くのであれば清書する必要がある。
