//
//  ArtworkWebScript.swift
//  AppLocalizer
//

import Foundation

/// AppLocalizer's own JavaScript for a Claude Design page, run with
/// `callAsyncJavaScript` in its own content world (the page's scripts never
/// run): fill in a language, fit the text, step the motion, read where
/// everything landed.
enum ArtworkWebScript {
    /// Fills the page for one language and pauses its motion at `time`
    /// (ms), waits for its images and fonts, fits each `data-al-fit` text
    /// between `minimumScale` and its full size, and returns the measure
    /// as JSON. Each `data-al="text"` is a phrase written in the primary
    /// language: its words there (the `lang` child of `primary`, else the
    /// first, when it carries its own versions) are its key in `phrases`,
    /// which gives its words in this language. Without them, a phrase with
    /// versions keeps only its child whose `lang` is the language's code,
    /// else its language part ("pt" for pt-BR), as `ArtworkWebTextVersions`
    /// matches them, and one without keeps its words, missing in any other
    /// language. Arguments: headline, appName, lang, dir, time,
    /// minimumScale, fontCSS, primary, phrases.
    static let fill = """
    const root = document.documentElement;
    root.lang = lang;
    root.dir = dir;
    if (fontCSS && !document.querySelector('style[data-al-fonts]')) {
      const style = document.createElement('style');
      style.setAttribute('data-al-fonts', '');
      style.textContent = fontCSS;
      (document.head || root).prepend(style);
    }
    for (const el of document.querySelectorAll('[data-al="headline"]')) el.textContent = headline;
    for (const el of document.querySelectorAll('[data-al="appName"]')) el.textContent = appName;
    const words = s => (s || '').replace(/\\s+/g, ' ').trim();
    const langOf = c => c.getAttribute('lang').trim();
    const pick = (versions, code) => {
      const wanted = (code || '').toLowerCase();
      return versions.find(c => langOf(c).toLowerCase() === wanted)
        || versions.find(c => langOf(c).toLowerCase() === wanted.split('-')[0]);
    };
    const texts = new Map();
    for (const el of document.querySelectorAll('[data-al="text"]')) {
      const versions = [...el.children].filter(c => c.hasAttribute('lang'));
      const source = words((versions.length ? (pick(versions, primary) || versions[0]) : el).textContent);
      const written = {};
      for (const c of versions) written[langOf(c)] = words(c.textContent);
      let isMissing = false;
      if (phrases && Object.prototype.hasOwnProperty.call(phrases, source)) {
        el.textContent = phrases[source];
      } else if (versions.length) {
        const own = pick(versions, lang);
        for (const c of versions) if (c !== own) c.remove();
        isMissing = !own;
      } else {
        isMissing = source.length > 0 && lang.toLowerCase() !== (primary || lang).toLowerCase();
      }
      texts.set(el, {source, written, languages: versions.map(langOf), isMissing});
    }
    const urls = [];
    const point = (el, url) => {
      urls.push(url);
      if (el.tagName === 'IMG') el.src = url; else el.style.backgroundImage = `url("${url}")`;
    };
    for (const el of document.querySelectorAll('[data-al="icon"]')) point(el, 'al-asset://app/icon.png');
    for (const el of document.querySelectorAll('[data-al="capture"]')) {
      const slot = parseInt(el.dataset.slot || '1', 10) || 1;
      point(el, `al-asset://app/capture-${slot}.png`);
    }
    \(seekBody)
    const within = (promise, ms) => Promise.race([promise, new Promise(resolve => setTimeout(resolve, ms))]);
    await within(Promise.all([
      ...[...document.images].map(i => i.decode().catch(() => null)),
      ...urls.map(u => { const i = new Image(); i.src = u; return i.decode().catch(() => null); }),
    ]), 10000);
    await within(document.fonts.ready, 10000);
    \(fitBody)
    \(measureBody)
    return JSON.stringify(measure());
    """

    /// Pauses every CSS animation and SVG animation at `time` (ms). No
    /// `requestAnimationFrame`: it never fires offscreen; the snapshot
    /// waits for the page to update.
    static let seek = """
    \(seekBody)
    return true;
    """

    /// The boxes of the text and icon at `time` (ms), to see whether they
    /// move: [{marker, x, y, width, height}].
    static let textBoxes = """
    \(seekBody)
    return JSON.stringify([...document.querySelectorAll('[data-al="headline"], [data-al="appName"], [data-al="icon"]')].map(el => {
      const r = el.getBoundingClientRect();
      return {marker: el.dataset.al, x: r.x, y: r.y, width: r.width, height: r.height};
    }));
    """

    /// Plays the page's motion live from where it was paused (the viewer),
    /// or pauses it (`playing` false).
    static let play = """
    for (const a of document.getAnimations()) { if (playing) { a.play(); } else { a.pause(); } }
    for (const svg of document.querySelectorAll('svg')) {
      if (playing) { svg.unpauseAnimations?.(); } else { svg.pauseAnimations?.(); }
    }
    return true;
    """

    /// Hides the text AppLocalizer filled in (`hidden`) or shows it again,
    /// to see what's behind it.
    static let hideText = """
    for (const el of document.querySelectorAll('[data-al="headline"], [data-al="appName"], [data-al="text"]')) {
      el.style.visibility = hidden ? 'hidden' : '';
    }
    return true;
    """

    private static let seekBody = """
    for (const a of document.getAnimations()) { a.pause(); a.currentTime = time; }
    for (const svg of document.querySelectorAll('svg')) {
      if (svg.pauseAnimations && !svg.ownerSVGElement) { svg.pauseAnimations(); svg.setCurrentTime(time / 1000); }
    }
    """

    private static let fitBody = """
    const boxOf = el => getComputedStyle(el).display === 'inline' && el.parentElement ? el.parentElement : el;
    const textRange = el => { const r = document.createRange(); r.selectNodeContents(el); return r; };
    const overflows = el => {
      const box = boxOf(el);
      if (box.scrollWidth > box.clientWidth + 1 || box.scrollHeight > box.clientHeight + 1) return true;
      const lines = parseInt(el.dataset.alLines || '0', 10);
      if (lines > 0) {
        const style = getComputedStyle(el);
        const lineHeight = parseFloat(style.lineHeight) || parseFloat(style.fontSize) * 1.2;
        if (Math.round(textRange(el).getBoundingClientRect().height / lineHeight) > lines) return true;
      }
      return false;
    };
    const fits = new Map();
    for (const el of document.querySelectorAll('[data-al="headline"], [data-al="appName"], [data-al="text"]')) {
      if (el.dataset.alFullSize === undefined) el.dataset.alFullSize = getComputedStyle(el).fontSize;
      const full = parseFloat(el.dataset.alFullSize);
      const at = scale => { el.style.fontSize = (full * scale) + 'px'; return !overflows(el); };
      if (!el.textContent.trim() || !el.hasAttribute('data-al-fit')) {
        fits.set(el, {scale: 1, fits: !el.textContent.trim() || !overflows(el)});
        continue;
      }
      if (at(1)) { fits.set(el, {scale: 1, fits: true}); continue; }
      let low = minimumScale, high = 1;
      if (!at(low)) { fits.set(el, {scale: low, fits: false}); continue; }
      for (let i = 0; i < 10; i++) { const mid = (low + high) / 2; if (at(mid)) low = mid; else high = mid; }
      at(low);
      fits.set(el, {scale: low, fits: true});
    }
    """

    private static let measureBody = """
    const visible = el => {
      const style = getComputedStyle(el);
      if (style.display === 'none' || style.visibility === 'hidden' || parseFloat(style.opacity) === 0) return false;
      const r = el.getBoundingClientRect();
      return r.width > 0 && r.height > 0;
    };
    const measure = () => {
      const elements = [...document.querySelectorAll('[data-al]')].map(el => {
        const marker = el.dataset.al;
        const style = getComputedStyle(el);
        const isText = marker === 'headline' || marker === 'appName' || marker === 'text';
        let r = el.getBoundingClientRect();
        if (isText && el.textContent.trim()) {
          const t = textRange(el).getBoundingClientRect();
          if (t.width > 0 && t.height > 0) r = t;
        }
        const item = {marker, x: r.x, y: r.y, width: r.width, height: r.height, fits: true, isVisible: visible(el)};
        if (marker === 'capture') item.slot = parseInt(el.dataset.slot || '1', 10) || 1;
        if (isText) {
          const fit = fits.get(el) || {scale: 1, fits: true};
          item.text = marker === 'text' ? el.textContent.replace(/\\s+/g, ' ').trim() : el.textContent;
          if (marker === 'text') {
            const versions = texts.get(el) || {source: item.text, written: {}, languages: [], isMissing: false};
            item.source = versions.source;
            item.languages = versions.languages;
            if (versions.languages.length) item.versions = versions.written;
            item.isMissingLanguage = versions.isMissing;
          }
          item.color = style.webkitTextFillColor || style.color;
          item.font = (style.fontFamily || '').split(',')[0].trim().replace(/^["']|["']$/g, '');
          item.fontSize = parseFloat(style.fontSize);
          item.fitScale = fit.scale;
          item.fits = fit.fits;
        }
        if (el.tagName === 'IMG') item.isLoaded = el.complete && el.naturalWidth > 0;
        return item;
      });
      const motions = document.getAnimations().map(a => {
        const timing = a.effect ? a.effect.getComputedTiming() : {};
        const duration = Number(timing.duration) || 0;
        const alternates = String(timing.direction || '').startsWith('alternate');
        const isInfinite = timing.iterations === Infinity;
        return {period: alternates ? duration * 2 : duration, isInfinite, end: isInfinite ? 0 : Number(timing.endTime) || 0};
      });
      // Words the page writes itself, outside every data-al: the same in
      // every language.
      const strayText = [];
      const walker = document.createTreeWalker(document.body || root, NodeFilter.SHOW_TEXT);
      for (let node = walker.nextNode(); node && strayText.length < 6; node = walker.nextNode()) {
        const words = node.textContent.replace(/\\s+/g, ' ').trim();
        const parent = node.parentElement;
        if (!/\\p{L}/u.test(words) || !parent || parent.closest('[data-al], style, script, template, noscript, title')) continue;
        if (visible(parent)) strayText.push(words.slice(0, 80));
      }
      return {
        elements, motions, strayText,
        hasSVGAnimation: document.querySelector('animate, animateTransform, animateMotion, set') !== null,
        contentWidth: root.scrollWidth, contentHeight: root.scrollHeight,
      };
    };
    """
}
