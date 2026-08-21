# SuperTV — App Store Connect (English, ready to paste)

Positioning: a **media player the user configures with their own subscription**
(bring-your-own credentials). No bundled or suggested content. This wording is what
gets IPTV-style apps through review.

---

## App information

**Name** (max 30)
```
SuperTV
```

**Subtitle** (max 30)
```
Player for your own service
```

**Promotional Text** (max 170)
```
Connect your own compatible subscription and play your streams with native controls, Picture in Picture, and Control Center. You bring the service; SuperTV plays it.
```

**Description**
```
SuperTV is a media player for your own compatible subscription (Xtream Codes). The app does not include or provide any content: you enter the access details of a service you already subscribe to.

• Connect to your server by entering server, username, and password.
• Browse your categories and channels, with search and logos.
• Playback with native controls: play/pause, volume, full screen.
• Picture in Picture and Control Center support.
• Works offline with the last cached catalog.
• Your credentials are stored securely in the Keychain, only on your device.

SuperTV does not provide any channels or content. It requires you to have your own legal subscription to a compatible service.
```

**Keywords** (max 100, no spaces after commas)
```
media player,xtream,streams,player,pip,picture in picture,m3u,playback,video,tv player
```

**Category**
- Primary: **Entertainment** (or **Utilities** to reduce content scrutiny)
- Secondary: optional

**Support URL / Marketing URL**
```
https://regaloomar.github.io/SuperTV/support.html
```

---

## App Review Information → Notes
```
SuperTV is a generic media player. It does NOT include or distribute any content.
The user must enter the credentials of their own subscription to a compatible service
(Xtream Codes protocol) to play THEIR OWN streams.

How to test:
1. On the login screen, enter the server, username, and password of the demo account below.
2. Tap "Connect" → categories are listed → select one → select a channel → it plays.

Demo account (review only):
  Server:   https://supertv-q6jy.onrender.com
  Username: demo
  Password: demo

Technical note (ATS): the app allows arbitrary HTTP connections (NSAllowsArbitraryLoads)
because the compatible servers are configured by the user and usually serve over HTTP;
there is no fixed list of domains to declare in advance. No user data is sent to the
developer.
```

**Sign-In required:** Yes → Username `demo`, Password `demo`.

---

## App Privacy (nutrition labels)
- **Data Not Collected** — choose "No, we do not collect data from this app."
- Credentials live in the Keychain (device) and are sent only to the user's own server.
- Matches `SuperTV/PrivacyInfo.xcprivacy` (no tracking, no data collected).

## Privacy Policy URL
```
https://regaloomar.github.io/SuperTV/privacy.html
```

## Age Rating
- Likely **4+**. In the questionnaire, answer "None" to all frequency questions.
- The app has no built-in browser and provides no content of its own.

---

## Screenshots (sizes)
- tvOS: 1920×1080 or 3840×2160
- iPhone 6.7": 1290×2796
- iPad 12.9": 2048×2732
Suggested screens: Categories, Channel list, Player.

## Export Compliance
- Uses only standard HTTPS/HTTP → set `ITSAppUsesNonExemptEncryption = NO` (or answer
  "No" to the encryption question at submission).
