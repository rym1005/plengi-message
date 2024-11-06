# loplat_plengi_ai_message
loplat plengi message SDK guide - flutter plugin DEMO example

**데모 앱을 테스트 하려면 Firebase 프로젝트의 google-service.json / GoogleService-Info.plist 파일을 업데이트하고 패키지명/번들id 를 수정해야 합니다.**

## Supported platforms
* Flutter Android(plengi-ai-message v2.1.1.9.6)
* Flutter iOS(MiniPlengi v1.5.6-rc1)

|             | Android | iOS   |
|-------------|---------|-------|
| **Support** | SDK 21+ | 12.0+ |

## Usage
plugin을 사용하기 위해서 pubspec.yaml에 'loplat_plengi' 종속성을 추가해주세요. (1.1.0 이상 버전부터 일반 발송이 지원됩니다.)

[dependency in your pubspec.yaml file](https://flutter.dev/docs/development/platform-integration/platform-channels).
```yaml
dependencies:
  flutter:
    sdk: flutter

  loplat_plengi: ^[plugin_version] #upper 1.1.0 
```

# 일반 메시지 서비스 등록 가이드

### FCM 프로젝트 설정
---
**_tip_**

**파이어베이스 콘솔에 접근이 필요해 자사 개발팀 도움이 필요할 수 있습니다.**

**현재 SDK 버전을 안드로이드 2.1.2.0 / iOS 1.5.6 이상으로 업데이트 해주세요.**

**SDK 연동 가이드는 개발자 가이드에서 확인해 주세요.**


---

📢

**로플랫 일반 마케팅 메시지를 이용하기 위해서는 FCM 프로젝트 개설이 필요합니다.**

- [‘Firebase 콘솔’로 이동](https://console.firebase.google.com/)해서 프로젝트를 개설해주세요.
- 이미 개설한 프로젝트가 있는 경우 **'앱 등록 및 FCM 인증 정보 전달'** 작업을 진행해주세요.
  :::

파이어베이스 프로젝트 생성 및 Firebase Cloud Messaging API 활성화는 [다음 링크](https://loplatx-user-guide.notion.site/FCM-10c17375397580ce96bcc598b4295b8b)를 확인해주세요.

## 로플랫 X 앱 등록 및 FCM 인증 정보 전달

### 인증 정보

앱 등록을 위해 다음과 같은 인증 정보가 필요합니다.

1. 일반(General)에 있는 project id
2. 서비스 계정(Service accounts)에서 만든 비공개 키
3. 앱 정보

   a. 앱 패키지 네임(iOS의 경우 bundle id)

   b. 앱 이름

   c. 연동이 필요한 OS (android or iOS)


### 로플랫 메일로 등록 요청

위 인증 정보들을 로플랫 담당자 또는 business@loplat.com에 전달해주시면 서비스 등록을 도와드리겠습니다.


### Android
자세한 내용은 [로플랫 개발자 사이트](https://developers.loplat.com/android/)에 설명되어 있습니다.

iOS 개발자는 [iOS 가이드](#ios)를 확인 부탁드립니다.

#### **loplat SDK 종속성 추가**
안드로이드 디렉토리 최상위 build.gradle에 아래의 코드를 추가하세요.
```groovy
allprojects {
  repositories {
    jcenter()
    mavenCentral()
    maven { url "https://maven.loplat.com/artifactory/plengi-aimessage"}
    google()
  }
}
```
앱의 build.gradle에 아래의 코드를 추가하세요.

**WARNING :**
plugin이 정상적으로 동작하기 위해서 반드시 아래 지정된 버전만을 사용해야 합니다.

```groovy
implementation 'com.loplat:placeengine-ai-message:2.1.2.0'
```
<br>

sdk 인증을 위해 loplat client_id와 client_secret을 추가해주세요.

client_id, client_secret 관련 정보는 메일로 전달 합니다.
```
defaultConfig {
   resValue "string", "[client_id 키명]", "[client_id]"
   resValue "string", "[clinet_secret 키명]", "[client_secret]"
}
```

#### **Google Play Service libraries 적용**

loplat X를 사용하기 위해서 build.gradle 의 dependency에 아래와 같이 Google Play Services 라이브러리 적용이 필요합니다.
```groovy
implementation 'com.google.android.gms:play-services-ads-identifier:18.0.1'
```
<br>
#### **RETROFIT and GSON libraries 적용**
위치 확인 요청시 서버와의 통신을 위해 Retrofit 및 GSON 라이브러리를 사용합니다. Retrofit 및 GSON 라이브러리 적용을 위해서 프로젝트의 build.gradle 에 아래와 같이 추가합니다.

```groovy
implementation 'com.squareup.retrofit2:retrofit:2.9.0'
implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
implementation 'com.squareup.okhttp3:okhttp:3.14.9'
```

Proguard를 사용한다면, 아래와 같이 proguard 설정을 추가해야 합니다.
```proguard
-dontwarn okio.**
-dontwarn javax.annotation.**
# R8 compatibility for GSON, Serialization 관련한 룰보다 반드시 위에 먼저 선언
-keepclassmembers,allowobfuscation class * {
@com.google.gson.annotations.SerializedName <fields>;
}
-keepclasseswithmembers class * {
@retrofit2.http.* <methods>;
}

-keep class com.loplat.placeengine.cloud.ResponseMessage** {*;}

-keep, allowobfuscation, allowshrinking interface retrofit2.Call
-keep, allowobfuscation, allowshrinking class retrofit2.Response
```
<br>

1. MainApplication.onCreate()에서 fcmEventReceiver를 등록해주세요.
```java
import io.flutter.app.FlutterApplication;

import android.content.Context;
import com.loplat.placeengine.Plengi;

public class MainApplication extends FlutterApplication {
  @Override
  public void onCreate() {
    super.onCreate();

    Context applicationContext = getApplicationContext();
    Plengi plengi = Plengi.getInstance(applicationContext);
    plengi.setListener(new LoplatPlengiListener());
    plengi.setEchoCode("[your_echo_code]");
  }
}
```
<br>

#### **일반 방송 알림 수신 설정**
loplat X를 통해 알림을 받기 위해서는 마케팅 알림 설정 시 아래와 같은 코드 작성이 필요 합니다.

- 마케팅 알림 설정이 ON 인 경우
```dart
import 'package:loplat_plengi/loplat_plengi.dart';

// 앱이 만든 알림을 사용할 경우 (장소인식결과에서 advertisement 객체를 참고하여 알림 생성)
await LoplatPlengiPlugin.enableAdNetwork(true, false);
// SDK 가 만든 알림을 사용할 경우
await LoplatPlengiPlugin.enableAdNetwork(true, true);
```

- 마케팅 알림 설정이 OFF 인 경우
```dart
import 'package:loplat_plengi/loplat_plengi.dart';

await LoplatPlengiPlugin.enableAdNetwork(false);
```

***

### iOS
자세한 내용은 [로플랫 개발자 사이트](https://developers.loplat.com/ios/)에 설명되어 있습니다.

android 개발자는 [android 가이드](#android)를 확인 부탁드립니다.

#### **권한 추가**

loplat SDK를 사용하기 위해서는 권한을 추가해야합니다. 필요한 권한은 아래와 같습니다.

- Background Modes

  `Remote Notification` : 백그라운드에서 notification을 수신하기 위해 필요합니다.

- Push Notification

<br>

프로젝트에 FirebaseMessaging 의존성을 추가하고 앱을 초기화합니다. 파이어베이스 의존성을 추가하고 초기화 하는 방법에 대한 자세한 내용은 다음 링크를 참고해주세요.

이후 Xcode에서 Signing & Capabilities 탭에서 Capability 를 탭한 뒤 Push Notifications와 Background Modes를 추가합니다.
Xcode 에서 **Project > Capabilities** 에 들어가 위 권한 목록에 있는 권한들을 허용해줍니다.

![XCode에서 권한 허용하기](https://firebasestorage.googleapis.com/v0/b/loplat-developers.appspot.com/o/images%2F4.png?alt=media&token=f310784e-b82b-4e1e-984e-efe9235558ec)
---
capability 추가 Background Modes 와 Push Notifications를 추가
![XCode에서 권한 허용하기](https://firebasestorage.googleapis.com/v0/b/loplat-developers.appspot.com/o/images%2F5.png?alt=media&token=12cb4477-90ee-4461-b2fb-33389444031f)

<br>


#### **사용자에게 ATT(App Tracking Transparency) 권한 요청하기**

**!WARNING iOS 14.5부터 IDFA(광고아이디)를 사용하기 위하여 유저가 권한을 부여해야 합니다.**

서비스 시나리오에 따라 권한 요청 사유를 명시해주세요.

<br>

**!Tip 예시 문구는 다음과 같습니다.**

‘허용을 하시면 알맞는 정보를 받아 보실 수 있습니다.’

<br>

프로젝트의 **`info.plist`** 파일에 아래 값을 추가합니다.

**(필수)** 서비스 시나리오에서 권한을 요청하지 않더라도 추가를 해주셔야 합니다.

```xml tab="PLIST" linenums="1"
<?xml version="1.0" encoding="UTF-8">
<!DOCTYPE plist PUBLIC "=//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 중간 생략 -->
    <key>NSUserTrackingUsageDescription</key>
    <string>예 : 허용을 하시면 알맞는 정보를 받아보실수 있습니다.</string>
    <!-- 이하 생략 -->
</dict>
</plist>
```

<br>


```dart
      await LoplatPlengiPlugin.requestAlwaysAuthorization();
```

<br>

#### SDK 적용법
1. import 하기
   `AppDelegate.swift` (Swift) 파일에, 아래의 구문을 추가해줍니다.


```swift tab="SWIFT"
import MiniPlengi
```

2. Plengi 초기화

<br>

**!DANGER `Plengi.initialize()` 함수는 반드시 `AppDelegate 안의 application(_:didFinishLaunchingWithOptions:)` 에서 호출되어야 합니다.**

다른 곳에서 호출할 경우, SDK가 작동하지 않습니다.

<br>

`AppDelegate` 클래스 선언부를 아래와 같이 수정합니다.

```swift tab="SWIFT"
@objc class AppDelegate: FlutterAppDelegate , MessagingDelegate{
```

이후, `AppDelegate` 클래스에 실제 SDK를 초기화하는 코드를 추가합니다.


```swift tab="SWIFT" linenums="1"
func application(_ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [IOApplicationLaunchOptionsKey: Any]?) -> Bool {
        // ********** 중간 생략 ********** //
        if Plengi.initialize(clientID: "로플랫에서 발급받은 클라이언트 아이디",
                 clientSecret: "로플랫에서 발급받은 클라이언트 키")
                == .SUCCESS) {
                // init 성공
                //필요 시 호출
                Plengi.setEchoCode(echoCode: "고객사 별 사용자를 식별할 수 있는 코드 (개인정보 주의바람)")
        } else {
                // init 실패
        }
        // ********** 중간 생략 ********** //
}
```

3. Start / Stop Plengi

사용자 장소/매장 방문 모니터링을 시작하거나 정지 할 수 있습니다. start는 사용자의 위치약관동의 직후 호출해주세요.

<br>

**!WARNING 앱 시작 혹은 로그인 할 때  마다 사용자의 위치약관동의 여부를 매번 확인해서 start를 호출해줘야만 합니다.**

<br>

**!TIP SDK에는 Start / Stop 이 중복으로 호출될 수 없도록 처리되어 있습니다.**

<br>

start/stop을 **중복 호출** 하더라도 SDK 내에서 **1회만** 호출되도록 구현되어 있습니다.

모니터링 시작과 정지는 다음과 같이 선언합니다.

```dart
import 'package:loplat_plengi/loplat_plengi.dart';

await LoplatPlengiPlugin.start("[client_id]", "[client_secret]");

```
<br>

**!DANGER 예외적인 케이스에 대해서는 Stop을 호출하면 안됩니다.**

<br>

예외적인 케이스에 대해서 stop을 호출하지 마세요. stop은 사용자의 위치약관동의에 대한 거부시에만 호출해주세요.

```dart
await LoplatPlengiPlugin.stop();
```

#### **캠페인 알림 수신 설정**
loplat X를 통해 알림을 받기 위해서는 마케팅 알림 설정하기 전, plengi start 전에 아래와 같은 코드 작성이 필요 합니다.

- 마케팅 알림 설정이 ON 인 경우
```dart
import 'package:loplat_plengi/loplat_plengi.dart';

// 앱이 만든 알림을 사용할 경우 (장소인식결과에서 advertisement 객체를 참고하여 알림 생성)
await LoplatPlengiPlugin.enableAdNetwork(true, false);
// SDK 가 만든 알림을 사용할 경우
await LoplatPlengiPlugin.enableAdNetwork(true, true);
```

- 마케팅 알림 설정이 OFF 인 경우
```dart
import 'package:loplat_plengi/loplat_plengi.dart';

await LoplatPlengiPlugin.enableAdNetwork(false);
```

알림 권한이 허용된 후, SDK에서 loplat X 광고 수신을 사용하기 위해서 시스템에 이벤트를 등록해야 합니다.

`AppDelegate` 클래스에 `application_handleActionWithIdentifier` 이벤트를 추가하고, 아래의 코드를 추가해주세요.

```
if (@available(iOS 10.0, *)) {
  UNUserNotificationCenter.currentNotificationCenter.delegate = self;
}

(void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
    forLocalNotification:(UILocalNotification *)notification
        completionHandler:(void (^)())completionHandler {
  [Plengi processLoplatAdvertisement:application
          handleActionWithIdentifier:identifier
                      for:notification
              completionHandler:completionHandler];
}

(void)userNotificationCenter:(UNUserNotificationCenter *)center
      willPresentNotification:(UNNotification *)notification
        withCompletionHandler:(void  (^)(UNNotificationPresentationOptions))
      completionHandler API_AVAILABLE(ios(10.0)) {

  completionHandler(UNNotificationPresentationOptionAlert |
            UNNotificationPresentationOptionBadge |
            UNNotificationPresentationOptionSound);

  // iOS 10 이상에서도 포그라운드에서 알림을 띄울 수 있도록 하는 코드
  // (가이드에는 뱃지, 소리, 경고 를 사용하지만, 개발에 따라 빼도 상관 없습니다.)
}

(void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
      withCompletionHandler:(void  (^)(void))completionHandler API_AVAILABLE(ios(10.0)) {

  [Plengi processLoplatAdvertisement:center
              didReceive:response
              withCompletionHandler:completionHandler];
  completionHandler();
  // loplat SDK가 사용자의 알림 트래킹 (Click, Dismiss) 를 처리하기 위한 코드
}
```

---
```swift tab="SWIFT" linenums="1"
if #available(iOS  10.0, *) {
  UNUserNotificationCenter.current().delegate = self
}

func application(_ application: UIApplication,
                  handleActionWithIdentifier identifier: String?,
                  for notification: UILocalNotification,
                  completionHandler: @escaping () -> Void)
  Plengi.processLoplatAdvertisement(application,
                                      handleActionWithIdentifier: identifier,
                                      for: notification,
                                      completionHandler: completionHandler)
}

@available(iOS 10.0,  *)
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping ()  ->  Void) {
  Plengi.processLoplatAdvertisement(center,
                                      didReceive: response,
                                      withCompletionHandler: completionHandler)
  completionHandler()

  // loplat SDK가 사용자의 알림 트래킹 (Click, Dismiss) 를 처리하기 위한 코드
}

@available(iOS 10.0, *)
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping  (UNNotificationPresentationOptions) -> Void) {

  completionHandler([.alert,  .sound,  .badge])
  // iOS 10 이상에서도 포그라운드에서 알림을 띄울 수 있도록 하는 코드
  // (가이드에는 뱃지, 소리, 경고 를 사용하지만, 개발에 따라 빼도 상관 없습니다.)
}
```
---
### Flutter SDK (Firebase sdk를 사용하는 경우)

Flutter에 firebase관련 설정을 하는 방법은 [Firebase 문서](https://firebase.google.com/docs/flutter/setup?hl=ko)에 설명되어 있습니다.

```
$ firebase login
$ dart pub global activate flutterfire_cli
$ flutterfire configure v
$ flutter pub add firebase_core
$ flutter pub add firebase_messaging
```


initializeApp 이후의 시점에서 FCM 토큰 가져옵니다.
```
    //firebase initialize
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    //token 값 전달
    FirebaseMessaging.instance.onTokenRefresh
        .listen((fcmToken) {
      LoplatPlengiPlugin.setFCMToken(fcmToken);
    })
        .onError((err) {
    });
```

이후의 Notification 동작 설정과 Native의 설정은 동일합니다.Android / iOS 가이드에 맞게 설정해주시면 됩니다. 
