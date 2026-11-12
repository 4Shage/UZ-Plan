# Wydawanie wersji

Release buduje się sam, gdy na `main` trafi zmiana `config/version` w `project.godot` (format `1.2.3`). Powstaje GitHub Release z APK i AAB, a AAB trafia do Google Play (domyślnie ścieżka `internal`).
Ręcznie: Actions → Release → Run workflow.

## Nowy klucz uploadu

```
keytool -genkeypair -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
keytool -export -rfc -alias upload -file upload_certificate.pem -keystore upload-keystore.jks
```

Hasło do keystore i klucza ma być jedno (Godot tego wymaga). Pliki `.jks` i `.keystore` zostają poza repo.

## Google Play: reset klucza uploadu

Play Console → aplikacja → App integrity (Play app signing) → Request upload key reset → powód: klucz zgubiony → wgraj `upload_certificate.pem`. Google odpisze mailem i poda datę, od której nowy klucz działa.

## Secrets (Settings → Secrets and variables → Actions)

| Secret | Wartość |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | keystore zakodowany w base64 |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEYSTORE_PASSWORD` | hasło keystore |
| `PLAY_SERVICE_ACCOUNT_JSON` | cały plik JSON konta serwisowego (opcjonalny, bez niego pomijany jest upload do Play) |

PowerShell:

```
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | gh secret set ANDROID_KEYSTORE_BASE64 -R 4Shage/UZ-Plan
```

Linux/macOS: `base64 -w0 upload-keystore.jks | gh secret set ANDROID_KEYSTORE_BASE64 -R 4Shage/UZ-Plan`

## Konto serwisowe Google Play

1. Google Cloud: projekt → włącz Google Play Android Developer API → Service accounts → utwórz konto → Keys → JSON.
2. Play Console → Users and permissions → Invite new users → e-mail konta serwisowego → uprawnienia do aplikacji (release do testów i produkcji).

## Zmienne repo (opcjonalne)

`PLAY_TRACK` (`internal`, `alpha`, `beta`, `production`; domyślnie `internal`) i `PLAY_STATUS` (`completed` albo `draft`; domyślnie `completed`).

## Pakiet

`package/unique_name` w `export_presets.cfg` musi być identyczne z nazwą pakietu aplikacji w Play Console.
