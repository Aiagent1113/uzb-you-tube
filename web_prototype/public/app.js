/**
 * UzDub YouTube AI - Interactive Prototype Controller
 * High-fidelity simulation of Flutter InAppWebView & Core JavaScript Injection
 */

document.addEventListener('DOMContentLoaded', () => {
  // DOM Elements
  const video = document.getElementById('demoVideo');
  const playBtn = document.getElementById('videoPlayPauseBtn');
  const videoTapArea = document.getElementById('videoTapArea');
  const volumeIndicator = document.getElementById('volumeIndicator');
  const duckingBadge = document.getElementById('duckingBadge');
  const floatingBar = document.getElementById('floatingPlayerBar');
  const dubbingToggleBtn = document.getElementById('dubbingToggleBtn');
  const toggleIcon = document.getElementById('toggleIcon');
  const rawSubTag = document.getElementById('rawSubtitleTag');
  const translatedSubText = document.getElementById('translatedSubText');
  
  // Voice & Speed Elements
  const voiceSelectTrigger = document.getElementById('voiceSelectTrigger');
  const currentVoiceLabel = document.getElementById('currentVoiceLabel');
  const voiceModal = document.getElementById('voiceModalBackdrop');
  const closeVoiceSheetBtn = document.getElementById('closeVoiceSheetBtn');
  const speedTrigger = document.getElementById('speedTrigger');
  const speedLabel = document.getElementById('speedLabel');
  const speedModal = document.getElementById('speedModalBackdrop');
  const closeSpeedSheetBtn = document.getElementById('closeSpeedSheetBtn');

  // Quota & Pro Elements
  const quotaText = document.getElementById('quotaText');
  const quotaFill = document.getElementById('quotaFill');
  const openProModalBtn = document.getElementById('openProModalBtn');
  const proModal = document.getElementById('proModalBackdrop');
  const closeProModalBtn = document.getElementById('closeProModalBtn');
  const licenseKeyInput = document.getElementById('licenseKeyInput');
  const activateLicenseBtn = document.getElementById('activateLicenseBtn');
  const keyStatusMsg = document.getElementById('keyStatusMsg');

  // Application State
  const state = {
    isDubbingEnabled: true,
    isBarVisible: true,
    activeVoice: 'uz-UZ-MadinaNeural',
    activeVoiceLabel: 'Madina (HD)',
    playbackSpeed: 1.0,
    isPro: false,
    dailyQuotaTotalSeconds: 3600, // 60 mins
    dailyQuotaRemainingSeconds: 3600,
    hdRemainingSeconds: 900, // 15 mins
    isSpeaking: false,
    subtitlesIndex: 0
  };

  // Mock Subtitles & Instant Uzbek Translation Stream
  const sampleSubtitles = [
    { en: "Welcome to this deep dive into autonomous AI systems.", uz: "Avtonom sun'iy intellekt tizimlari bo'yicha chuqur tahlilimizga xush kelibsiz." },
    { en: "Today we will explore multi-agent architectures and neural networks.", uz: "Bugun biz ko'p agentli arxitektura va neyron tarmoqlarni ko'rib chiqamiz." },
    { en: "Notice how low latency inference completely transforms user experience.", uz: "Kichik kechikishli xulosa chiqarish foydalanuvchi tajribasini qanday o'zgartirishiga e'tibor bering." },
    { en: "Security and obfuscation are critical for production mobile deployments.", uz: "Xavfsizlik va obfuskatsiya mobil ilovalarni tarqatish uchun juda muhimdir." },
    { en: "UzDub seamlessly ducked the video volume to twenty percent.", uz: "UzDub video ovozini yigirma foizga muvaffaqiyatli tushirdi." },
    { en: "And now the Uzbek neural voice delivers clear and crystal narration.", uz: "Endi esa o'zbek neyron ovozi tiniq va aniq hikoyani taqdim etmoqda." }
  ];

  // 1. Video Playback & Tap Gestures (Tap to hide/show controls)
  playBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    if (video.paused) {
      video.play();
      playBtn.textContent = '❚❚';
      startSubtitleSimulation();
    } else {
      video.pause();
      playBtn.textContent = '▶';
      stopSpeech();
    }
  });

  videoTapArea.addEventListener('click', () => {
    state.isBarVisible = !state.isBarVisible;
    if (state.isBarVisible) {
      floatingBar.classList.remove('hidden');
    } else {
      floatingBar.classList.add('hidden');
    }
  });

  // 2. Audio Ducking Engine (Lowers video volume to 20% while speaking)
  function applyAudioDucking(enable) {
    if (enable) {
      video.volume = 0.20;
      volumeIndicator.textContent = 'Vol: 20% (Ducked)';
      volumeIndicator.style.color = '#ff0033';
      duckingBadge.textContent = '20% DUCKED';
      duckingBadge.style.color = '#ff0033';
    } else {
      video.volume = 1.0;
      volumeIndicator.textContent = 'Vol: 100%';
      volumeIndicator.style.color = '#00ffcc';
      duckingBadge.textContent = 'NORMAL';
      duckingBadge.style.color = '#00e1ff';
    }
  }

  // 3. Speech Synthesis & Dual Voice Dispatcher
  function speakUzbek(text) {
    if (!state.isDubbingEnabled) return;

    // Check Quota
    if (!state.isPro) {
      if (state.activeVoice.includes('Neural') && state.hdRemainingSeconds <= 0) {
        showProModal();
        return;
      }
      if (state.dailyQuotaRemainingSeconds <= 0) {
        showProModal();
        return;
      }
    }

    state.isSpeaking = true;
    applyAudioDucking(true);

    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = state.playbackSpeed;
      utterance.pitch = state.activeVoice.includes('Sardor') ? 0.9 : 1.1;

      utterance.onend = () => {
        applyAudioDucking(false);
        state.isSpeaking = false;
        deductQuota(Math.round(text.length * 0.05));
      };

      utterance.onerror = () => {
        applyAudioDucking(false);
        state.isSpeaking = false;
      };

      window.speechSynthesis.speak(utterance);
    } else {
      // Fallback timer simulation
      setTimeout(() => {
        applyAudioDucking(false);
        state.isSpeaking = false;
        deductQuota(3);
      }, 3500 / state.playbackSpeed);
    }
  }

  function stopSpeech() {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
    }
    applyAudioDucking(false);
    state.isSpeaking = false;
  }

  // 4. Subtitle Simulation Loop
  let subTimer = null;
  function startSubtitleSimulation() {
    if (subTimer) clearInterval(subTimer);
    
    subTimer = setInterval(() => {
      if (video.paused || !state.isDubbingEnabled) return;

      const current = sampleSubtitles[state.subtitlesIndex % sampleSubtitles.length];
      state.subtitlesIndex++;

      // Update Subtitle UI
      rawSubTag.textContent = `Orig: "${current.en}"`;
      translatedSubText.textContent = current.uz;

      // Speak in Uzbek
      speakUzbek(current.uz);
    }, 4500);
  }

  // 5. Dubbing Toggle
  dubbingToggleBtn.addEventListener('click', () => {
    state.isDubbingEnabled = !state.isDubbingEnabled;
    if (state.isDubbingEnabled) {
      dubbingToggleBtn.classList.add('active');
      toggleIcon.textContent = '🔊';
      if (!video.paused) startSubtitleSimulation();
    } else {
      dubbingToggleBtn.classList.remove('active');
      toggleIcon.textContent = '🔇';
      stopSpeech();
    }
  });

  // 6. Voice Selection Bottom Sheet
  voiceSelectTrigger.addEventListener('click', () => {
    voiceModal.classList.remove('hidden');
  });
  closeVoiceSheetBtn.addEventListener('click', () => {
    voiceModal.classList.add('hidden');
  });

  document.querySelectorAll('.voice-option').forEach(option => {
    option.addEventListener('click', () => {
      document.querySelectorAll('.voice-option').forEach(el => el.classList.remove('selected'));
      option.classList.add('selected');

      const voiceId = option.getAttribute('data-voice');
      const voiceLabel = option.getAttribute('data-label');

      state.activeVoice = voiceId;
      state.activeVoiceLabel = voiceLabel;
      currentVoiceLabel.textContent = voiceLabel;

      voiceModal.classList.add('hidden');

      // Check if user clicked Neural HD with exhausted quota
      if (voiceId.includes('Neural') && !state.isPro && state.hdRemainingSeconds <= 0) {
        showProModal();
      }
    });
  });

  // 7. Speed Selector Sheet
  speedTrigger.addEventListener('click', () => {
    speedModal.classList.remove('hidden');
  });
  closeSpeedSheetBtn.addEventListener('click', () => {
    speedModal.classList.add('hidden');
  });

  document.querySelectorAll('.speed-opt-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.speed-opt-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const speed = parseFloat(btn.getAttribute('data-speed'));
      state.playbackSpeed = speed;
      speedLabel.textContent = `${speed.toFixed(1)}x`;
      speedModal.classList.add('hidden');
    });
  });

  // 8. Quota Manager & PRO Modal
  function deductQuota(seconds) {
    if (state.isPro) return;

    state.dailyQuotaRemainingSeconds = Math.max(0, state.dailyQuotaRemainingSeconds - seconds);
    if (state.activeVoice.includes('Neural')) {
      state.hdRemainingSeconds = Math.max(0, state.hdRemainingSeconds - seconds);
    }

    const remainingMins = (state.dailyQuotaRemainingSeconds / 60).toFixed(0);
    quotaText.textContent = `Kunlik: ${remainingMins}/60 daq`;

    const percentage = (state.dailyQuotaRemainingSeconds / state.dailyQuotaTotalSeconds) * 100;
    quotaFill.style.width = `${percentage}%`;

    // Update voice hint in sheet
    const madinaHint = document.getElementById('madinaQuotaHint');
    const sardorHint = document.getElementById('sardorQuotaHint');
    const hdMins = (state.hdRemainingSeconds / 60).toFixed(1);
    if (madinaHint) madinaHint.textContent = `Qolgan HD limit: ${hdMins} daqiqa`;
    if (sardorHint) sardorHint.textContent = `Qolgan HD limit: ${hdMins} daqiqa`;
  }

  function showProModal() {
    stopSpeech();
    proModal.classList.remove('hidden');
  }

  openProModalBtn.addEventListener('click', showProModal);
  closeProModalBtn.addEventListener('click', () => {
    proModal.classList.add('hidden');
  });

  // 9. PRO License Key Activation
  activateLicenseBtn.addEventListener('click', () => {
    const key = licenseKeyInput.value.trim().toUpperCase();
    if (!key) {
      keyStatusMsg.className = 'key-status-msg error';
      keyStatusMsg.textContent = 'Iltimos, kalitni kiriting!';
      return;
    }

    if (key.startsWith('UZDUB-PRO-') && key.length >= 18) {
      state.isPro = true;
      keyStatusMsg.className = 'key-status-msg success';
      keyStatusMsg.textContent = '✓ PRO Status Faollashtirildi!';

      quotaText.textContent = 'PRO: Cheksiz Dublyaj';
      quotaFill.style.width = '100%';
      quotaFill.style.background = '#00ff88';

      setTimeout(() => {
        proModal.classList.add('hidden');
      }, 1000);
    } else {
      keyStatusMsg.className = 'key-status-msg error';
      keyStatusMsg.textContent = 'Yaroqsiz kalit! Telegram botdan oling.';
    }
  });

  // Status Bar Clock
  setInterval(() => {
    const now = new Date();
    const h = String(now.getHours()).padStart(2, '0');
    const m = String(now.getMinutes()).padStart(2, '0');
    const el = document.getElementById('statusTime');
    if (el) el.textContent = `${h}:${m}`;
  }, 1000);
});
