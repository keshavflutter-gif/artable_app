/* =========================================================
   ARTABLE — shared front-end helpers for the auth prototype.
   Pure UI logic only — no real auth/network calls. Every
   function that would eventually hit an API is marked with
   a "// TODO(api):" comment so it's easy to find later.
   ========================================================= */

/**
 * Wire up a password field's show/hide eye icon.
 * Usage: <button class="field-toggle" data-toggle-for="password">...</button>
 */
function initPasswordToggles(scope = document) {
  scope.querySelectorAll('[data-toggle-for]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-toggle-for');
      const input = document.getElementById(targetId);
      if (!input) return;
      const isHidden = input.type === 'password';
      input.type = isHidden ? 'text' : 'password';
      btn.classList.toggle('is-visible', isHidden);
      btn.innerHTML = isHidden ? ICONS.eyeOff : ICONS.eye;
    });
  });
}

/**
 * Wire up a row of OTP boxes: auto-advance on input, backspace
 * moves back, and paste distributes digits across boxes.
 */
function initOtpInputs(containerSelector = '.otp-row') {
  const container = document.querySelector(containerSelector);
  if (!container) return;
  const boxes = Array.from(container.querySelectorAll('input'));

  boxes.forEach((box, idx) => {
    box.addEventListener('input', () => {
      box.value = box.value.replace(/[^0-9]/g, '').slice(0, 1);
      if (box.value && idx < boxes.length - 1) boxes[idx + 1].focus();
      container.classList.remove('error');
    });
    box.addEventListener('keydown', (e) => {
      if (e.key === 'Backspace' && !box.value && idx > 0) {
        boxes[idx - 1].focus();
      }
    });
    box.addEventListener('paste', (e) => {
      e.preventDefault();
      const digits = (e.clipboardData.getData('text') || '').replace(/[^0-9]/g, '').split('');
      digits.forEach((d, i) => { if (boxes[i]) boxes[i].value = d; });
      const next = boxes[Math.min(digits.length, boxes.length - 1)];
      if (next) next.focus();
      container.classList.remove('error');
    });
  });
}

/**
 * Returns true if every OTP box has a digit. The CTA button stays
 * visually "enabled" at all times (per design direction) — this is
 * only used at submit-time to decide whether to proceed or show a
 * shake + red-outline validation state.
 */
function isOtpComplete(containerSelector = '.otp-row') {
  const boxes = Array.from(document.querySelectorAll(`${containerSelector} input`));
  return boxes.length > 0 && boxes.every((b) => b.value.length === 1);
}

function flagOtpError(containerSelector = '.otp-row', buttonId = 'verifyBtn') {
  const container = document.querySelector(containerSelector);
  const btn = document.getElementById(buttonId);
  if (container) container.classList.add('error');
  if (btn) {
    btn.classList.remove('shake');
    // eslint-disable-next-line no-unused-expressions
    void btn.offsetWidth; // restart animation
    btn.classList.add('shake');
  }
}

/**
 * Countdown "Resend OTP in 00:30" helper.
 * Re-enables the resend link/button when the timer hits zero.
 */
function startResendTimer(seconds = 30) {
  const timerEl = document.getElementById('resendTimer');
  const resendBtn = document.getElementById('resendBtn');
  if (!timerEl || !resendBtn) return;

  let remaining = seconds;
  resendBtn.classList.add('hidden');
  timerEl.classList.remove('hidden');

  const tick = () => {
    const m = String(Math.floor(remaining / 60)).padStart(2, '0');
    const s = String(remaining % 60).padStart(2, '0');
    timerEl.textContent = `Resend code in ${m}:${s}`;
    if (remaining <= 0) {
      clearInterval(interval);
      timerEl.classList.add('hidden');
      resendBtn.classList.remove('hidden');
      return;
    }
    remaining -= 1;
  };

  tick();
  const interval = setInterval(tick, 1000);

  resendBtn.addEventListener('click', () => {
    // TODO(api): trigger resend-OTP request here.
    startResendTimer(seconds);
  }, { once: true });
}

/**
 * Splash screen placeholder logic.
 * TODO(api): replace the setTimeout with real version-check +
 * auto-login/token-validation calls, then route accordingly.
 */
function runSplashSequence({ nextIfLoggedIn = 'onboarding.html', nextIfLoggedOut = 'onboarding.html', delay = 1800 } = {}) {
  // TODO(api): const isLoggedIn = await checkAutoLogin();
  // TODO(api): const versionOk = await checkAppVersion();
  const isLoggedIn = false;
  setTimeout(() => {
    window.location.href = isLoggedIn ? nextIfLoggedIn : nextIfLoggedOut;
  }, delay);
}

/** Simple onboarding slider controller. */
function initOnboarding() {
  const track = document.querySelector('.onboard-track');
  const dots = Array.from(document.querySelectorAll('.dot'));
  const nextBtn = document.getElementById('nextBtn');
  const skipBtn = document.getElementById('skipBtn');
  const slides = Array.from(document.querySelectorAll('.onboard-slide'));
  if (!track || !slides.length) return;

  let index = 0;

  function render() {
    track.style.transform = `translateX(-${index * 100}%)`;
    dots.forEach((d, i) => d.classList.toggle('active', i === index));
    const isLast = index === slides.length - 1;
    nextBtn.textContent = isLast ? 'Get Started' : 'Next';
    nextBtn.querySelector('.btn-arrow')?.classList.toggle('hidden', false);
  }

  nextBtn.addEventListener('click', () => {
    if (index < slides.length - 1) {
      index += 1;
      render();
    } else {
      // TODO(api): mark onboarding as seen for this device/user.
      window.location.href = 'login.html';
    }
  });

  skipBtn.addEventListener('click', () => {
    window.location.href = 'login.html';
  });

  dots.forEach((dot, i) => {
    dot.addEventListener('click', () => { index = i; render(); });
  });

  // basic touch swipe support
  let startX = 0;
  track.addEventListener('touchstart', (e) => { startX = e.touches[0].clientX; }, { passive: true });
  track.addEventListener('touchend', (e) => {
    const diff = e.changedTouches[0].clientX - startX;
    if (diff < -40 && index < slides.length - 1) { index += 1; render(); }
    if (diff > 40 && index > 0) { index -= 1; render(); }
  });

  render();
}

/** Minimal client-side validation feedback (visual only). */
function showFieldHint(inputId, message, type = 'error') {
  const input = document.getElementById(inputId);
  if (!input) return;
  const group = input.closest('.field-group');
  if (!group) return;
  let hint = group.querySelector('.field-hint');
  if (!hint) {
    hint = document.createElement('p');
    hint.className = 'field-hint';
    group.appendChild(hint);
  }
  hint.textContent = message;
  hint.className = `field-hint ${type}`;
}

const ICONS = {
  eye: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7Z"/><circle cx="12" cy="12" r="3"/></svg>',
  eyeOff: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.94 10.94 0 0 1 12 19c-7 0-11-7-11-7a21.4 21.4 0 0 1 5.06-5.94M9.9 4.24A10.94 10.94 0 0 1 12 4c7 0 11 7 11 7a21.4 21.4 0 0 1-2.16 3.19M14.12 14.12a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>',
};

document.addEventListener('DOMContentLoaded', () => {
  initPasswordToggles();
});
