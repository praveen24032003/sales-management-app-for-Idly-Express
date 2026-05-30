# Android Release Signing Handoff

This project can build release artifacts in two modes:

- internal validation mode: falls back to debug signing when no production keystore is configured
- production mode: uses a real keystore and should be enforced before public distribution

## Files involved

- Android app config: [../android/app/build.gradle.kts](../android/app/build.gradle.kts)
- ignored keystore properties file: [../android/.gitignore](../android/.gitignore)
- template properties file: [../android/key.properties.example](../android/key.properties.example)
- local keystore properties file: `android/key.properties`

## Production keystore setup

1. Create or obtain the production upload keystore.
2. Store the keystore outside source control. A common local path is `android/keystore/upload-keystore.jks`.
3. Copy [../android/key.properties.example](../android/key.properties.example) to `android/key.properties`.
4. Replace all placeholder values in `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeType=PKCS12
storeFile=../keystore/upload-keystore.jks
```

Exact meaning of each field:

- `storePassword`: the password for the `.jks` keystore file itself
- `keyPassword`: the password for the specific signing key entry inside that keystore; if you created the key with the same password as the keystore, repeat the same value here
- `keyAlias`: the alias name used when the upload key was created, for example `upload`
- `storeType`: the keystore format; keep this as `PKCS12` for the current release setup
- `storeFile`: the path to the keystore file relative to `android/app/build.gradle.kts`; if the keystore lives at `android/keystore/upload-keystore.jks`, keep this as `../keystore/upload-keystore.jks`

## Validation commands

Internal release validation without a production keystore:

```powershell
flutter build apk --release
```

Production enforcement build from the Android directory:

```powershell
Set-Location android
.\gradlew assembleRelease -PidlyRequireReleaseSigning=true
```

Store-upload app bundle build with the same enforced signing guard:

```powershell
Set-Location android
.\gradlew bundleRelease -PidlyRequireReleaseSigning=true
```

Recommended final public-release check sequence:

```powershell
Set-Location android
./gradlew assembleRelease -PidlyRequireReleaseSigning=true --no-daemon
./gradlew bundleRelease -PidlyRequireReleaseSigning=true --no-daemon
Set-Location ..
Get-Item .\build\app\outputs\flutter-apk\app-release.apk | Select-Object FullName, Length, LastWriteTime
Get-Item .\build\app\outputs\bundle\release\app-release.aab | Select-Object FullName, Length, LastWriteTime
jarsigner -verify -verbose -certs .\build\app\outputs\bundle\release\app-release.aab
```

If `android/key.properties` is missing or incomplete, the enforced build now fails fast with a clear error instead of silently producing a debug-signed release artifact.

## Handoff notes

- `android/key.properties`, `*.jks`, and `*.keystore` are already ignored by Git.
- The current application id is `com.idlyexpress.salesmanager`.
- The latest local APK path is `build/app/outputs/flutter-apk/app-release.apk`.
- The Android app bundle path for store upload is `build/app/outputs/bundle/release/app-release.aab`.
- A signed release APK has already been installed successfully on a physical Android device.
- Before store submission, archive the keystore in your normal password-managed backup process and keep `android/key.properties` out of any shared history.