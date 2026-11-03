# 🎬 UzDub YouTube AI — Production MVP Architecture & Prototype

**UzDub YouTube AI** — real vaqt rejimida YouTube videolari subtitrlarini tutib, o‘zbek tiliga tarjima qiluvchi va tabiiy Microsoft Edge Neural ovozlari (`uz-UZ-MadinaNeural`, `uz-UZ-SardorNeural`) hamda robot ovozda o‘quvchi, "Premium Luxury" dizayndagi xavfsiz mobil ilova va backend ekotizimi.

---

## 🏛 1. Loyiha Arxitekturasi (Folder Structure)

```
uzbdub youtube 1/
├── flutter_app/                          # Flutter Cross-Platform Mobil Ilova
│   ├── pubspec.yaml                      # flutter_inappwebview, flutter_secure_storage, crypto
│   ├── lib/
│   │   ├── main.dart                     # Ilova kirish nuqtasi + Security Audit tekshiruvi
│   │   ├── core/
│   │   │   ├── security/
│   │   │   │   ├── security_guard.dart   # Root, Frida, Charles Proxy, HMAC-SHA256 & Barmoq izi
│   │   │   │   └── native_vault.dart     # C++ NDK Native Vault bridge & XOR maskali kalitlar
│   │   │   ├── theme/
│   │   │   │   └── app_theme.dart        # Luxury Dark Theme (#0A0A0A, #FF0033 neon, Glassmorphism)
│   │   │   └── constants/
│   │   │       └── app_constants.dart    # Ovozlar, limitlar (60 min), Telegram bot sozlamalari
│   │   └── features/
│   │       ├── webview/presentation/
│   │       │   └── youtube_webview_screen.dart # InAppWebView, Guest Mode, Tap gestures, JS Handlers
│   │       ├── player_overlay/presentation/
│   │       │   ├── floating_player_bar.dart    # Suzuvchi shisha panel, Dublyaj, Ovoz, Tezlik, Limit
│   │       │   └── voice_selector_sheet.dart   # Madina HD, Sardor HD, Robot ovoz tanlagich
│   │       ├── subscription/
│   │       │   ├── domain/quota_manager.dart   # Freemium limit boshqaruvi (15m HD, 45m Robot, tun reset)
│   │       │   └── presentation/pro_modal.dart # Shisha effektli PRO modal + Telegram bot integratsiyasi
│   │       └── injection/
│   │           ├── injection_builder.dart      # Dinamik imzoli JWT/HMAC shartnoma bilan JS inyeksiya
│   │           └── assets/
│   │               └── obfuscated_injection.js # Himoyalangan va shifrlangan inyeksiya skripti
│   └── android/
│       ├── app/
│       │   ├── build.gradle              # NDK CMake, ProGuard, minify & shrinkResources konfiguratsiyasi
│       │   ├── proguard-rules.pro        # Maksimal darajada baytkodni chalkashtirish (DexGuard/ProGuard)
│       │   └── src/main/cpp/
│       │       ├── CMakeLists.txt        # Native C++ kutubxona kompilyatsiyasi
│       │       └── native-vault.cpp      # ptrace anti-debugging + maxfiy kalitlar (.so xotirasida)
│
├── backend/                              # FastAPI Security Proxy & Background Orchestrator
│   ├── requirements.txt                  # fastapi, uvicorn, edge-tts, websockets, cryptography
│   ├── Dockerfile                        # Konteynerizatsiya
│   └── app/
│       ├── main.py                       # FastAPI kirish nuqtasi, CORS va yo'naltiruvchilar
│       ├── core/
│       │   ├── config.py                 # Loyiha sozlamalari va maxfiy kalitlar
│       │   └── security.py               # HMAC-SHA256 tekshiruv, Nonce anti-replay va vaqt drifti
│       ├── services/
│       │   ├── edge_tts_service.py       # Microsoft Edge TTS WebSocket orqali audio oqimi
│       │   └── translation_service.py    # Subtitrlar uchun keshlanuvchi Google GTX tarjimon
│       └── api/v1/endpoints/
│           ├── auth.py                   # Dinamik inyeksiya shartnomasi beruvchi shlyuz
│           ├── tts_ws.py                 # Real vaqtda audio oqimini uzatuvchi WebSocket (/ws/tts)
│           ├── translate.py              # Zaxira tarjima endpointi
│           └── license.py                # PRO kalitlarni tasdiqlash & Telegram bot vebhuki
│
├── injection/                            # Subtitrlarni tutish va TTS inyeksiya skripti
│   ├── src/injection_core.js             # MutationObserver, Audio Ducking (20%), Subtitr tutuvchi
│   ├── scripts/obfuscate.js              # Base64, Anti-tamper va Anti-debugger bilan o'rovchi generator
│   └── dist/obfuscated_injection.js      # Tayyor himoyalangan JS fayl
│
├── web_prototype/                        # Jonli Sinov Simulyatori (Interaktiv Prototip)
│   ├── server.js                         # Node.js http server (Port 3000)
│   └── public/
│       ├── index.html                    # iPhone ramkasi, real YouTube video, suzuvchi panel
│       ├── style.css                     # Glassmorphism, neon animatsiyalar, 100% responsive
│       └── app.js                        # Audio Ducking (20%), Tap-to-hide, Ovoz tanlagich, PRO faollashtirish
│
└── scripts/
    └── build_secure_apk.ps1              # flutter build apk --obfuscate --split-debug-info skripti
```

---

## 🔒 2. Amalga Oshirilgan Xavfsizlik va Anti-Reverse Engineering Mexanizmlari

1. **Native C++ (NDK) va Anti-Debugging:**
   - `native-vault.cpp` faylida Linux `ptrace(PTRACE_TRACEME, ...)` orqali ishga tushirish paytida GDB, Frida yoki LLDB debuggerlari ulanganligini tekshiradi.
   - Barcha API shlyuz manzillari va HMAC kalitlari Dart baytkodida ochiq matn (cleartext) ko‘rinishida saqlanmaydi, balki C++ `.so` faylining `.rodata` qismida XOR shifrlangan holda yashirilgan.
2. **Flutter Obfuscation & ProGuard (DexGuard):**
   - Release APK yig‘ishda `--obfuscate` va `--split-debug-info` buyrug‘i orqali barcha Dart funksiyalari va klass nomlari o‘chirilib, shifrlanadi.
   - `proguard-rules.pro` qoidalarida barcha Android `Log.*` chaqiriqlari yo‘qotiladi, klasslar bitta harfli g‘alati nomlarga o‘zgartiriladi.
3. **Root, Frida, Xposed va Proxy (Charles) Aniqlash (`security_guard.dart`):**
   - Android (`/system/bin/su`, `/data/local/tmp/frida-server`, `test-keys`, Magisk) va iOS (`Cydia`, `MobileSubstrate`) tekshiriladi.
   - Frida serverining standart `27042` TCP porti skaner qilinadi.
   - Qurilmada Charles/Fiddler/Burp Suite orqali MITM tahlili olib borilayotgan bo‘lsa (Proxy), ilova bloklanadi va `SecurityLockdownScreen` ekrani ochiladi.
4. **HMAC-SHA256 So‘rov Imzolash & Anti-Replay:**
   - Har bir so‘rov `X-UzDub-Timestamp`, `X-UzDub-Nonce`, `X-UzDub-Signature`, `X-UzDub-DeviceID` sarlavhalari bilan yuboriladi.
   - Backend 60 soniyadan eski so‘rovlarni va qayta ishlatilgan noncelarni (Replay Attack) rad etadi.
5. **JavaScript Inyeksiya Himoyasi (`obfuscated_injection.js`):**
   - Skript ochiq holda saqlanmaydi. U o‘zini himoyalovchi (`Function('debugger')()`) tuzoqlar va dinamik kontrakt tekshiruvi bilan himoyalangan.

---

## 💎 3. UI/UX "Premium Luxury" va Floating Player Bar

- **Foydalanuvchi Tajribasi:** YouTube lentasiga to‘g‘ridan-to‘g‘ri kirish (Guest Mode, majburiy ro‘yxatdan o‘tishsiz 0 sekundlik to‘siq).
- **Sinxron Suzuvchi Panel (Floating Player Bar):**
  - Ekranga bitta bosish (Tap) orqali panel YouTube boshqaruv tugmalari bilan birga yo‘qoladi va yana paydo bo‘ladi (`AnimatedSlide` + `AnimatedOpacity`).
  - **Dublyaj Tugmasi:** Neon qizil doira va impulsli animatsiya (`#FF0033`).
  - **Ovoz Tanlagich:** Madina Neural HD (Ayol), Sardor Neural HD (Erkak), Standart Robot.
  - **Tezlik:** 1.0x, 1.25x, 1.5x.
  - **Audio Ducking:** Dublyaj gapirgan vaqtda video ovozi 20% ga tushadi, tugashi bilan silliq ravishda 100% ga qaytadi.
  - **Kunlik Limit:** 60 daqiqalik datchik (15 min HD, 45 min Robot). Limit tugasa yoki PRO ovozlar tanlansa, avtomatik ravishda **PRO Modal** ochiladi.
  - **Telegram Bot Integratsiyasi:** "Telegram Bot Orqali Xarid Qilish" tugmasi foydalanuvchini `@UzDubAI_bot` ga yo‘naltiradi. To‘lovdan keyin olingan kalit (`UZDUB-PRO-XXXX-XXXX`) kiritilgach, cheksiz dublyaj faollashadi.

---

## ⚡ 4. Jonli Prototipni Hoziroq Brauzerda Sinab Ko‘rish

Jonli interaktiv simulyator allaqachon fonda ishga tushirildi:
👉 **http://localhost:3000** manzilini brauzerda oching!

**Unda sinab ko‘rishingiz mumkin bo‘lgan funksiyalar:**
1. **Video ijrosi:** Videoni yoqsangiz, real vaqtda subtitrlar chiqadi va u avtomatik o‘zbek tiliga tarjima qilinib ovoz beriladi.
2. **Audio Ducking:** Ovoz gapirayotganda ekranning yuqori o‘ng burchagidagi hajm ko‘rsatkichi `Vol: 20% (Ducked)` ga tushishini va nutq tugagach `Vol: 100%` ga qaytishini ko‘rishingiz mumkin.
3. **Tap-to-Hide Gesturasi:** Video maydoniga bir marta bossangiz, suzuvchi panel silliq pastga tushib yashirinadi; yana bossangiz chiqadi.
4. **Ovoz Tanlash:** `Madina (HD)`, `Sardor (HD)` va `Robot` ovozlarini tanlash oynasi.
5. **PRO Modal & Aktivatsiya:** "PRO" tugmasini bosing yoki `UZDUB-PRO-TEST-2026` kalitini kiritib PRO statusni faollashtiring!
