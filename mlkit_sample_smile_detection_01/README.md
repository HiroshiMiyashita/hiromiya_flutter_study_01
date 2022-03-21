# GoogleのMLKitを使用した笑顔採点アプリケーション

GoogleのMLKitを使用した笑顔採点のAndrodiアプリケーション.

カメラで撮影した写真やギャラリーの写真に対してMLKitのVisionのFace Detection機能で顔認識とその顔に対する笑顔のスコアを算出し、firestorageに写真を、firestoreにスコアを保存する.

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
            
3. firebaseの使用を設定

    1. firebaseに本Androidアプリケーションを登録し、得られたgoogle-services.jsonを以下のファイル名で保存.
                        
        firebaseに登録するときのAndroidパッケージ名は、`android/app/src/main/AndroidManifest.xml`で指定しているパッケージ名.

        `AndroidManifest.xml`の例)

        ```xml
        <manifest xmlns:android="http://schemas.android.com/apk/res/android"
            package="jp.gr.java_conf.hiro_titan_d.mlkit_sample_smile_detection_01">
        ```
        
        ここでは、パッケージ名は `jp.gr.java_conf.hiro_titan_d.mlkit_sample_smile_detection_01` 
        
    2. firebaseにアプリケーションを登録するときに指示に従いファイルを更新.
    
    3. 念のため、multiDex対応するように設定

        設定ファイル `android/app/build.gradle`

        設定箇所は `android.defaultConfig`

        ```gradle
        multiDexEnabled true
        ```

4. google_ml_kit(拡張パッケージ)で顔認識、画像ラベリング、バーコードスキャンを使用できるようにするための設定.

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


        
        def keystorePropertiesFile = rootProject.file("app/keystore.properties")
    android/app/google-services.json
    
5.  android/app/build.gradleの編集.

    1. firebaseを使えるようにするために、android/app/build.gradleに以下の1行を追加.

        追加先はファイルの直下に追加.

        ```gradle
        apply plugin: 'com.google.gms.google-services'
        ```
        
    2. firebaseに登録するときに指定したAndroidパッケージ名を設定.

        追加先は、 `android.defaultConfig`

        ```gradle
        applicationId 'firebaseに登録するときに指定したAndroidパッケージ名`
        ```

    3. 
    

    

    
   
6. ビルドで失敗しないように android/app/build.gradle に以下を追加.

    追加先 `android` 直下の設定値として追加.

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

5. firebaseを使えるようにするために、android/app/build.gradleに以下の1行を追加.

   ```gradle
   

2. flutter 2.10.3
## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
