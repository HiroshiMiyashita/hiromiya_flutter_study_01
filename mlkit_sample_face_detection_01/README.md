# GoogleのMLKitを使用した顔認識アプリケーション

GoogleのMLKitを使用した顔認識のAndrodiアプリケーション.

カメラで撮影した写真やギャラリーの写真に対して顔認識を行い、顔の部分を短径で囲むアプリケーション.

## 開発環境の設定

1. fultter 2.10.3 をインストール.

    fvmをインストールし,flutterのバージョンを切り替える仕組みを開発では使用している.
    
2. キーストアの設定

    1. キーストアを作成し、`android/app/release.jsk` というファイル名で保存.

    2. 以下の内容を記述したキーストアのプロパティ用ファイルを`android/app/keystore.properties`というファイルで保存.

    ```proerties
    keyAlias=キーエイリアス名
    keyPassword=キーエイリアスのパスワード
    storeFile=キーストアのファイル名
    storePassword=キーストアのパスワード
    ```
    
    3. `android/app/build.gradle`ファイルで上記のキーストア、キーストアのプロパティファイルを使用するように設定.

        - キーストアのプロパティファイルを定義

            設定箇所は直下.

            ```properties
            def keystorePropertiesFile = rootProject.file("app/keystore.properties")
            ```

        - releaseビルドの署名設定で上記のキーストアのプロパティを使用するように設定.

            設定箇所は `android.signingConfigs.release`

            ```properties
            if (keystorePropertiesFile.exists()) {
                def keystoreProperties = new Properties()
                keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
            ```
            
        - releaseビルドでreleaseビルドの署名設定を使うように設定.

            設定箇所は `android.buildTypes.release`

            ```properties
            resValue "string", "app_name", "Smile Detection"
            signingConfig signingConfigs.release
            ```
            
            上記では`resValue`でアプリ名称も指定している.
            
3. google_ml_kit(拡張パッケージ)で顔認識、画像ラベリング、バーコードスキャンを使用できるようにするための設定.

    1. google_ml_kitが対応しているバージョンのAndroidにターゲットを変更.

        `android/app/build.gradle`を以下のように変更.
        
        設定箇所は `android.defaultConfig`

        ```gradle
        minSdkVersion 21
        targetSdkVersion 32
        ```
        
        このバージョンは、AndroidのSDKバージョンを示しており、今後のgoogle_ml_kitのバージョンによって変わる可能性がある.

    2. `android/app/src/main/AndroidManifest.xml`に以下追加.
    
        設定箇所は `<manifest><application>` 直下.

        ```xml
        <meta-data
            android:name="com.google.mlkit.vision.DEPENDENCIES"
            android:value="ica,face,ocr" />
        ```

        | 名前 | 機能 |
        |:---|:---|
        | ica | Image Labeling |
        | ocr | Barcode Scanning |
        | face | Face Detection |

5.  android/app/build.gradleのその他の設定

    1. `android`に以下の設定を追加.

        ```gradle
        packagingOptions {
            exclude 'META-INF/DEPENDENCIES'
            exclude 'META-INF/LICENSE'
            exclude 'META-INF/LICENSE.txt'
            exclude 'META-INF/license.txt'
            exclude 'META-INF/NOTICE'
            exclude 'META-INF/NOTICE.txt'
            exclude 'META-INF/notice.txt'
            exclude 'META-INF/ASL2.0'
            exclude("META-INF/*.kotlin_module")
        }
        ```
        
    2. debugビルドでアプリケーションID(Androidパッケージ名?)を変更しないように設定.

        以下をコメントアウト.

        設定箇所 `android.buildTypes.debug`

        ```gradle
        // applicationIdSuffix ".debug"
        ```
## ビルド方法

### リリース用apkのビルド

1. 以下のコマンドを実行

    ```sh
    flutter build apk --release
    ```

2. リリースビルドができていることを確認

    `build/app/outputs/flutter-sdk/app.apk`
    
    この名前は、build.gradleの設定で変わると考えられるが、よくわからない.

### デバッグ用apkのビルド

1. 以下のコマンドを実行

    ```sh
    flutter build apk --debug
    ```

2. リリースビルドができていることを確認

    `build/app/outputs/flutter-sdk/app-debug.apk`
    
    この名前は、build.gradleの設定で変わると考えられるが、よくわからない.
