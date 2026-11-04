# Artable — Google AdMob (Android) IDs

**App name:** artable_app  
**Platform:** Android  
**AdMob console:** https://admob.google.com/v2/apps/3296460099/adunits/list  
**App settings:** https://admob.google.com/v2/apps/3296460099/settings  

---

## 1. App ID (put in mobile app config — NOT an ad unit)

```
ca-app-pub-8377462640468284~3296460099
```

- Used in `AndroidManifest.xml` as `com.google.android.gms.ads.APPLICATION_ID`
- Do **not** confuse with ad unit IDs (those use `/`, App ID uses `~`)

---

## 2. Ad unit IDs (by placement)

| Placement (proposal) | AdMob name | Format | Ad unit ID |
|---|---|---|---|
| Home Banner Ads | Android_Home_Banner | Banner | `ca-app-pub-8377462640468284/1511148864` |
| Feed Ads (banner) | Android_Feed_Banner | Banner | `ca-app-pub-8377462640468284/7637802428` |
| Feed Ads (native) | Android_Feed_Native | Native advanced | `ca-app-pub-8377462640468284/6757458882` |
| Video Ads | Android_Video_Interstitial | Interstitial | `ca-app-pub-8377462640468284/2385475747` |
| Reward Ads / Daily Bonus | Android_Reward_Ad | Rewarded | `ca-app-pub-8377462640468284/9824982069` |
| App open (optional) | Android_App_Open | App open | `ca-app-pub-8377462640468284/8655582654` |

---

## 3. Same data as JSON (for backend / config)

```json
{
  "platform": "android",
  "app_name": "artable_app",
  "admob_app_id": "ca-app-pub-8377462640468284~3296460099",
  "ad_units": {
    "home_banner": "ca-app-pub-8377462640468284/1511148864",
    "feed_banner": "ca-app-pub-8377462640468284/7637802428",
    "feed_native": "ca-app-pub-8377462640468284/6757458882",
    "video_interstitial": "ca-app-pub-8377462640468284/2385475747",
    "reward": "ca-app-pub-8377462640468284/9824982069",
    "app_open": "ca-app-pub-8377462640468284/8655582654"
  }
}
```

---

## 4. Who needs what?

| Team | Needs |
|---|---|
| **Mobile (Flutter)** | App ID + all ad unit IDs to show AdMob ads |
| **Backend** | Usually **does not** load AdMob ads. Optional: store these IDs in config/env if you want remote toggle of which unit is used; control **Prime = ad-free** and **custom sponsored banners** via APIs |
| **Admin panel** | Custom sponsored banners (not AdMob); subscription/Prime flag to hide ads |

---

## 5. Approval status: “Requires review” — how to set up

1. Open **App settings**: https://admob.google.com/v2/apps/3296460099/settings  
2. Confirm **App ID** is correct (above).  
3. After Play Store listing exists → **App store details** → **Add** → paste Play Store URL.  
4. AdMob may ask for **app review** before serving real ads to users.  
5. Until approved:
   - Use Google **test ad unit IDs** while developing (never click your own live ads).  
   - Live units may return few/no ads.  
6. Submit / wait for review in AdMob if prompted under Approval status.  
7. After approval + store link, production ads fill better.

**Official test App ID (dev only):**  
`ca-app-pub-3940256099942544~3347511713`

---

## 6. Not in AdMob (backend / admin)

- Custom Sponsored Ads → Admin banner management  
- Prime membership (ad-free, diamond badge) → subscription APIs + user flag  
- Razorpay wallet → separate from AdMob  

---

## 7. iOS (pending)

Create the same 6 ad units under an **iOS** AdMob app and add a second JSON block when ready.
