/* ═══════════════════════════════════════════════════════════════════════════
   BoxVise Website — Script
   ═══════════════════════════════════════════════════════════════════════════ */

document.addEventListener('DOMContentLoaded', () => {

  // ── Theme Toggle ────────────────────────────────────────────────────────
  const themeToggle = document.getElementById('themeToggle');
  const html = document.documentElement;
  const savedTheme = localStorage.getItem('boxvise-theme') || 'light';
  html.setAttribute('data-theme', savedTheme);

  themeToggle.addEventListener('click', () => {
    const current = html.getAttribute('data-theme');
    const next = current === 'light' ? 'dark' : 'light';
    html.setAttribute('data-theme', next);
    localStorage.setItem('boxvise-theme', next);
  });

  // ── Navbar Scroll Effect ────────────────────────────────────────────────
  const navbar = document.getElementById('navbar');

  window.addEventListener('scroll', () => {
    navbar.classList.toggle('scrolled', window.scrollY > 20);
  }, { passive: true });

  // ── Active Nav Highlight ────────────────────────────────────────────────
  const navLinkItems = document.querySelectorAll('.nav-link');
  const pageSections = document.querySelectorAll('section[id]');

  const activeObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        navLinkItems.forEach(link => {
          link.classList.toggle('active', link.getAttribute('href') === `#${entry.target.id}`);
        });
      }
    });
  }, { threshold: 0.35 });

  pageSections.forEach(s => activeObserver.observe(s));

  // ── Mobile Menu ─────────────────────────────────────────────────────────
  const mobileMenuBtn = document.getElementById('mobileMenuBtn');
  const navLinks = document.getElementById('navLinks');

  mobileMenuBtn.addEventListener('click', () => {
    mobileMenuBtn.classList.toggle('open');
    navLinks.classList.toggle('mobile-open');
  });

  // Close mobile menu on link click
  navLinks.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', () => {
      mobileMenuBtn.classList.remove('open');
      navLinks.classList.remove('mobile-open');
    });
  });

  // ── Scroll Animations (Intersection Observer) ───────────────────────────
  const animatedElements = document.querySelectorAll('[data-animate]');

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const delay = entry.target.getAttribute('data-delay') || 0;
        setTimeout(() => {
          entry.target.classList.add('visible');
        }, parseInt(delay));
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -50px 0px' });

  animatedElements.forEach(el => observer.observe(el));

  // ── Counter Animation ───────────────────────────────────────────────────
  const counters = document.querySelectorAll('[data-count]');

  const counterObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        animateCounter(entry.target);
        counterObserver.unobserve(entry.target);
      }
    });
  }, { threshold: 0.5 });

  counters.forEach(el => counterObserver.observe(el));

  function animateCounter(el) {
    const target = parseInt(el.getAttribute('data-count'));
    const duration = 2000;
    const start = performance.now();

    function update(now) {
      const elapsed = now - start;
      const progress = Math.min(elapsed / duration, 1);
      // Ease out quad
      const eased = 1 - (1 - progress) * (1 - progress);
      const current = Math.floor(eased * target);
      el.textContent = current.toLocaleString();

      if (progress < 1) {
        requestAnimationFrame(update);
      } else {
        el.textContent = target.toLocaleString();
      }
    }
    requestAnimationFrame(update);
  }

  // ── Page Video — Smooth Scroll-driven Scrubbing ─────────────────────
  const heroVideo = document.getElementById('heroVideo');

  if (heroVideo) {
    // Force full preload for seamless frame access
    heroVideo.preload = 'auto';
    heroVideo.load();

    // Skip first 2 seconds of the video
    const VIDEO_START_OFFSET = 2;

    // Once metadata is known, jump to offset and warm up decoder
    heroVideo.addEventListener('loadedmetadata', () => {
      heroVideo.currentTime = VIDEO_START_OFFSET;
      const warmUp = heroVideo.play();
      if (warmUp) warmUp.then(() => heroVideo.pause()).catch(() => {});
    });

    let ticking = false;
    let lastScrubTime = -1;

    function scrubPageVideo() {
      if (!heroVideo.duration) { ticking = false; return; }

      const pageScrollable = document.body.scrollHeight - window.innerHeight;
      if (pageScrollable <= 0) { ticking = false; return; }

      const progress = Math.max(0, Math.min(1, window.scrollY / pageScrollable));
      // Map scroll progress across the usable portion of the video (after offset)
      const usableDuration = heroVideo.duration - VIDEO_START_OFFSET;
      const targetTime = VIDEO_START_OFFSET + progress * usableDuration;

      // Skip if change is less than one frame at 60fps (avoids useless seeks)
      if (Math.abs(targetTime - lastScrubTime) >= 1 / 60) {
        lastScrubTime = targetTime;
        // fastSeek is faster (keyframe-based) where supported
        if (typeof heroVideo.fastSeek === 'function') {
          heroVideo.fastSeek(targetTime);
        } else {
          heroVideo.currentTime = targetTime;
        }
      }
      ticking = false;
    }

    window.addEventListener('scroll', () => {
      if (!ticking) {
        requestAnimationFrame(scrubPageVideo);
        ticking = true;
      }
    }, { passive: true });

    // Also scrub on resize (page height changes)
    window.addEventListener('resize', () => requestAnimationFrame(scrubPageVideo), { passive: true });
  }

  // ── Smooth Scroll for anchor links ──────────────────────────────────────
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        e.preventDefault();
        const offset = navbar.offsetHeight + 20;
        const top = target.getBoundingClientRect().top + window.scrollY - offset;
        window.scrollTo({ top, behavior: 'smooth' });
      }
    });
  });

});
