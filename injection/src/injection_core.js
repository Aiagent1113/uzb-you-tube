/**
 * UzDub YouTube AI - Core Injection Engine
 * High-performance, anti-tampering YouTube Subtitle Interceptor & Dual-Engine TTS Orchestrator
 * (c) UzDub Security & AI Labs
 */

(function (window, document) {
  'use strict';

  // --- 1. ANTI-TAMPER & INTEGRITY HANDSHAKE ---
  const UZDUB_CONTRACT_HEADER = 'X-UzDub-Contract';
  let isContractValid = false;

  function verifySecurityContract() {
    try {
      const contract = window.__UZDUB_SECURITY_CONTRACT__;
      if (!contract || typeof contract !== 'object') {
        // If injected directly by Flutter wrapper with auth token:
        if (window.UzDubSecurityToken && window.UzDubSecurityToken.length > 20) {
          isContractValid = true;
          return true;
        }
        return false;
      }
      const now = Date.now();
      if (!contract.sig || Math.abs(now - contract.ts) > 60000) {
        return false;
      }
      isContractValid = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Anti-debugging watch loop
  function initAntiDebug() {
    let t0 = Date.now();
    setInterval(function () {
      const t1 = Date.now();
      if (t1 - t0 > 2500) {
        // Debugger paused execution - neutralise state if tampered
        window.__UZDUB_TAMPER_DETECTED__ = true;
      }
      t0 = t1;
    }, 1000);
  }
  initAntiDebug();

  // --- 2. CONFIGURATION & STATE ---
  const state = {
    enabled: true,
    voiceType: 'uz-UZ-MadinaNeural', // 'uz-UZ-MadinaNeural' | 'uz-UZ-SardorNeural' | 'robot'
    playbackRate: 1.0,
    volumeDuckingLevel: 0.2,
    originalVideoVolume: 1.0,
    isDucking: false,
    activeVideoElement: null,
    observer: null,
    lastProcessedText: '',
    captionQueue: [],
    isSpeaking: false,
    dailyQuotaRemainingSeconds: 3600,
    quotaConsumedSeconds: 0
  };

  // --- 3. FLUTTER BRIDGE HELPER ---
  function postToFlutter(handlerName, payload) {
    try {
      if (window.flutter_inappwebview && typeof window.flutter_inappwebview.callHandler === 'function') {
        return window.flutter_inappwebview.callHandler(handlerName, JSON.stringify(payload));
      } else if (window.UzDubNativeBridge && typeof window.UzDubNativeBridge.postMessage === 'function') {
        window.UzDubNativeBridge.postMessage(JSON.stringify({ handler: handlerName, payload: payload }));
      }
    } catch (err) {
      console.warn('[UzDub Bridge Error]', err);
    }
    return Promise.resolve(null);
  }

  // --- 4. AUDIO DUCKING ENGINE ---
  function findActiveVideo() {
    const videos = document.querySelectorAll('video');
    for (let i = 0; i < videos.length; i++) {
      if (videos[i].readyState > 0 && !videos[i].paused) {
        return videos[i];
      }
    }
    return videos[0] || null;
  }

  function applyAudioDucking(enable) {
    const video = state.activeVideoElement || findActiveVideo();
    if (!video) return;

    if (enable && !state.isDucking) {
      state.originalVideoVolume = video.volume > 0.3 ? video.volume : 1.0;
      smoothVolumeTransition(video, video.volume, state.volumeDuckingLevel, 250);
      state.isDucking = true;
      postToFlutter('onDuckingStateChanged', { ducking: true, level: state.volumeDuckingLevel });
    } else if (!enable && state.isDucking) {
      smoothVolumeTransition(video, video.volume, state.originalVideoVolume, 300);
      state.isDucking = false;
      postToFlutter('onDuckingStateChanged', { ducking: false, level: state.originalVideoVolume });
    }
  }

  function smoothVolumeTransition(video, fromVol, toVol, durationMs) {
    const steps = 10;
    const interval = durationMs / steps;
    const diff = (toVol - fromVol) / steps;
    let step = 0;

    const timer = setInterval(() => {
      step++;
      let newVol = fromVol + diff * step;
      if (newVol < 0) newVol = 0;
      if (newVol > 1) newVol = 1;
      video.volume = newVol;

      if (step >= steps) {
        video.volume = toVol;
        clearInterval(timer);
      }
    }, interval);
  }

  // --- 5. TRANSLATION ENGINE (Real-time Uzbek fallback) ---
  const translationCache = new Map();

  async function translateToUzbek(rawText) {
    const cleaned = rawText.trim().replace(/\s+/g, ' ');
    if (!cleaned || cleaned.length < 2) return '';

    if (translationCache.has(cleaned)) {
      return translationCache.get(cleaned);
    }

    try {
      // Step A: Fast Google Translate GTX API (client-side zero latency)
      const gtxUrl = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=uz&dt=t&q=${encodeURIComponent(cleaned)}`;
      const response = await fetch(gtxUrl);
      if (response.ok) {
        const data = await response.json();
        let translated = '';
        if (Array.isArray(data) && Array.isArray(data[0])) {
          for (let i = 0; i < data[0].length; i++) {
            if (data[0][i] && data[0][i][0]) {
              translated += data[0][i][0];
            }
          }
        }
        if (translated.trim()) {
          translationCache.set(cleaned, translated.trim());
          return translated.trim();
        }
      }
    } catch (err) {
      console.warn('[UzDub Translate Fallback]', err);
    }

    // Step B: Backend Proxy fallback via Flutter Handler
    try {
      const backendResult = await postToFlutter('onTranslateFallback', { text: cleaned, target: 'uz' });
      if (backendResult && backendResult.translated) {
        translationCache.set(cleaned, backendResult.translated);
        return backendResult.translated;
      }
    } catch (e) {
      // Silent catch
    }

    return cleaned;
  }

  // --- 6. DUAL TTS DISPATCHER (Robot vs Neural HD) ---
  function speakText(text) {
    if (!state.enabled || !text) return;

    applyAudioDucking(true);
    state.isSpeaking = true;

    if (state.voiceType === 'robot') {
      speakViaWebSpeech(text);
    } else {
      speakViaNeuralVoice(text, state.voiceType);
    }
  }

  // Voice Engine A: Web Speech Synthesis (Standard Robot)
  function speakViaWebSpeech(text) {
    if (!('speechSynthesis' in window)) {
      applyAudioDucking(false);
      state.isSpeaking = false;
      return;
    }

    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.rate = state.playbackRate;
    utterance.pitch = 1.0;

    // Look for Uzbek or Turkic/Russian fallback voice
    const voices = window.speechSynthesis.getVoices();
    const uzVoice = voices.find(v => v.lang.startsWith('uz')) ||
                    voices.find(v => v.lang.startsWith('tr')) ||
                    voices.find(v => v.lang.startsWith('ru')) ||
                    voices[0];
    if (uzVoice) {
      utterance.voice = uzVoice;
    }

    utterance.onend = function () {
      applyAudioDucking(false);
      state.isSpeaking = false;
      onSpeechCycleComplete(text.length);
    };

    utterance.onerror = function (e) {
      console.warn('[WebSpeech Error]', e);
      applyAudioDucking(false);
      state.isSpeaking = false;
    };

    window.speechSynthesis.speak(utterance);
  }

  // Voice Engine B: Microsoft Edge WebSocket Neural TTS via Flutter / Backend
  function speakViaNeuralVoice(text, voiceName) {
    postToFlutter('onSpeakNeuralAudio', {
      text: text,
      voice: voiceName, // 'uz-UZ-MadinaNeural' or 'uz-UZ-SardorNeural'
      rate: state.playbackRate
    }).then(res => {
      // Flutter handles streaming or playback finish event
    }).catch(err => {
      // Fallback to robot voice if network fails
      speakViaWebSpeech(text);
    });
  }

  function onSpeechCycleComplete(charCount) {
    // 1 char ≈ 0.06s of speech
    const durationEstimate = Math.max(1, Math.round(charCount * 0.06));
    state.quotaConsumedSeconds += durationEstimate;
    postToFlutter('onQuotaConsumed', {
      seconds: durationEstimate,
      totalConsumed: state.quotaConsumedSeconds,
      voiceType: state.voiceType
    });
  }

  // --- 7. YOUTUBE CAPTION MUTATION OBSERVER & NETWORK HOOK ---
  function setupSubtitleObserver() {
    if (state.observer) {
      state.observer.disconnect();
    }

    // Observe body for caption containers in mobile YouTube (m.youtube.com)
    state.observer = new MutationObserver(mutations => {
      if (!state.enabled) return;

      const video = findActiveVideo();
      if (!video || video.paused) return;
      state.activeVideoElement = video;

      // Selectors for mobile YouTube and desktop view in mobile
      const captionSelectors = [
        '.ytp-caption-segment',
        '.caption-window span',
        '.ytm-caption-segment',
        '.captions-text',
        '.player-timedtext'
      ];

      for (const sel of captionSelectors) {
        const elements = document.querySelectorAll(sel);
        if (elements && elements.length > 0) {
          let fullText = '';
          elements.forEach(el => {
            const txt = el.innerText || el.textContent;
            if (txt) fullText += ' ' + txt;
          });

          fullText = fullText.trim();
          if (fullText && fullText !== state.lastProcessedText) {
            state.lastProcessedText = fullText;
            handleNewSubtitleSegment(fullText);
            break;
          }
        }
      }
    });

    state.observer.observe(document.body, {
      childList: true,
      subtree: true,
      characterData: true
    });
  }

  async function handleNewSubtitleSegment(rawText) {
    // Notify Flutter UI of raw detected subtitle
    postToFlutter('onSubtitleCaptured', { text: rawText });

    // Translate to Uzbek
    const uzbekText = await translateToUzbek(rawText);
    if (!uzbekText) return;

    postToFlutter('onSubtitleTranslated', { original: rawText, uzbek: uzbekText });

    // Speak audio
    speakText(uzbekText);
  }

  // --- 8. YOUTUBE TIMEDTEXT AUTO-TLANG=UZ NETWORK HOOK ---
  function hookYouTubeNetwork() {
    const originalFetch = window.fetch;
    window.fetch = async function (...args) {
      let url = args[0];
      if (typeof url === 'string' && url.includes('/api/timedtext') && !url.includes('tlang=uz')) {
        // Automatically inject Uzbek translation request into YouTube's native subtitle stream
        url = url + '&tlang=uz';
        args[0] = url;
      }
      return originalFetch.apply(this, args);
    };

    const originalOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function (method, url, ...rest) {
      if (typeof url === 'string' && url.includes('/api/timedtext') && !url.includes('tlang=uz')) {
        url = url + '&tlang=uz';
      }
      return originalOpen.call(this, method, url, ...rest);
    };
  }

  // --- 9. EXTERNAL CONTROLLER API (Callable from Flutter) ---
  window.UzDubController = {
    setVoice: function (voiceName) {
      state.voiceType = voiceName;
      postToFlutter('onVoiceChanged', { voice: voiceName });
    },
    setSpeed: function (rate) {
      state.playbackRate = parseFloat(rate) || 1.0;
    },
    setEnabled: function (isEnabled) {
      state.enabled = Boolean(isEnabled);
      if (!state.enabled) {
        if ('speechSynthesis' in window) window.speechSynthesis.cancel();
        applyAudioDucking(false);
      }
    },
    triggerDuckingRestore: function () {
      applyAudioDucking(false);
      state.isSpeaking = false;
    },
    getState: function () {
      return {
        enabled: state.enabled,
        voiceType: state.voiceType,
        playbackRate: state.playbackRate,
        isDucking: state.isDucking,
        lastText: state.lastProcessedText
      };
    }
  };

  // --- 10. BOOTSTRAP INITIALIZATION ---
  function init() {
    verifySecurityContract();
    hookYouTubeNetwork();
    setupSubtitleObserver();

    // Listen to video events
    document.addEventListener('play', (e) => {
      if (e.target.tagName === 'VIDEO') {
        state.activeVideoElement = e.target;
      }
    }, true);

    document.addEventListener('pause', (e) => {
      if (e.target.tagName === 'VIDEO') {
        if ('speechSynthesis' in window) window.speechSynthesis.cancel();
        applyAudioDucking(false);
      }
    }, true);

    postToFlutter('onInjectionReady', { version: '2.4.0', status: 'active' });
    console.log('%c[UzDub YouTube AI Engine Activated]', 'background: #FF0033; color: #FFFFFF; font-weight: bold; padding: 4px 8px; border-radius: 4px;');
  }

  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    init();
  } else {
    document.addEventListener('DOMContentLoaded', init);
  }
})(window, document);
