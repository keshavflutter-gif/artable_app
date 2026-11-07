# Host these files on `https://artable.app`

WhatsApp / Chrome App Links **will not open the app** until this domain resolves and serves the verification files.

## Required DNS
Point `artable.app` (and ideally `www`) to a host that serves HTTPS.

## Deploy
Serve the contents of this folder at the site root:

| URL | File |
|-----|------|
| `https://artable.app/.well-known/assetlinks.json` | `.well-known/assetlinks.json` |
| `https://artable.app/.well-known/apple-app-site-association` | `.well-known/apple-app-site-association` (no `.json` extension; `Content-Type: application/json`) |
| `https://artable.app/video/*` | rewrite to `video/index.html` (landing that opens the app) |

## Android fingerprint
`assetlinks.json` currently includes the **debug** keystore SHA-256.  
Before Play Store release, add the **upload / app signing** SHA-256 from Play Console → App integrity.

```text
keytool -list -v -keystore your-release.jks -alias your-alias
```

Use the SHA-256 value **without colons**.

## iOS
Replace `TEAMID` in `apple-app-site-association` with your Apple Developer Team ID.  
Enable Associated Domains for the App ID in the Apple Developer portal.

## Verify Android
```text
adb shell pm get-app-links com.artable
```
After hosting, status for `artable.app` should become `verified`.
