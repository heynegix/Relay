/* ==========================================================================
   Relay — landing page behaviour
   Bilingual switching is pure CSS (`html[data-lang]`); this script only
   stores the preference, updates document metadata, and reveals sections.
   ========================================================================== */

(function () {
  "use strict";

  var STORAGE_KEY = "relay-lang";
  var root = document.documentElement;
  var toggle = document.getElementById("langToggle");
  var label = document.getElementById("langLabel");

  var META = {
    ja: {
      title: "Relay — 切れた通信を、次の接点へ。",
      description:
        "Relay は、災害時に通信が不安定でも救助情報を運ぶオープンソースのストア・キャリー・フォワード型プロジェクトです。Nearby / ローカル LAN / HTTPS Broker を経由して、救助調整地点の PC Gateway へ届けます。"
    },
    en: {
      title: "Relay — Keep rescue information moving when connectivity fails",
      description:
        "Relay is an open-source, local-first disaster communication project. It encrypts rescue information on Android and relays it through Nearby, local LAN, or an HTTPS Broker toward a PC Gateway at a rescue coordination point."
    }
  };

  function normalize(value) {
    return value === "en" ? "en" : "ja";
  }

  function storedLang() {
    try {
      var saved = window.localStorage.getItem(STORAGE_KEY);
      if (saved === "ja" || saved === "en") return saved;
    } catch (e) {
      /* storage unavailable — fall through to browser preference */
    }
    return (navigator.language || "ja").toLowerCase().indexOf("ja") === 0 ? "ja" : "en";
  }

  function queryLang() {
    var match = /[?&]lang=(ja|en)\b/i.exec(window.location.search);
    return match ? match[1].toLowerCase() : null;
  }

  function apply(lang, persist) {
    var next = normalize(lang);
    root.setAttribute("data-lang", next);
    root.setAttribute("lang", next);

    var meta = META[next];
    document.title = meta.title;

    var desc = document.querySelector('meta[name="description"]');
    if (desc) desc.setAttribute("content", meta.description);

    var ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle) ogTitle.setAttribute("content", meta.title);

    var ogDesc = document.querySelector('meta[property="og:description"]');
    if (ogDesc) ogDesc.setAttribute("content", meta.description);

    if (label) label.textContent = next === "ja" ? "EN" : "JA";
    if (toggle) {
      toggle.setAttribute(
        "aria-label",
        next === "ja" ? "Switch to English" : "日本語に切り替える"
      );
      toggle.setAttribute("title", next === "ja" ? "Switch to English" : "日本語に切り替える");
    }

    if (persist) {
      try {
        window.localStorage.setItem(STORAGE_KEY, next);
      } catch (e) {
        /* ignore: preference simply will not persist */
      }
    }
  }

  apply(queryLang() || storedLang(), false);

  if (toggle) {
    toggle.addEventListener("click", function () {
      apply(root.getAttribute("data-lang") === "ja" ? "en" : "ja", true);
    });
  }

  /* ------------------------------------------------------ reveal on scroll */

  var targets = document.querySelectorAll(".reveal");

  if (!("IntersectionObserver" in window)) {
    Array.prototype.forEach.call(targets, function (el) {
      el.classList.add("is-visible");
    });
  } else {
    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          var el = entry.target;
          var siblings = el.parentElement ? el.parentElement.children : null;
          var index = 0;
          if (siblings) {
            for (var i = 0; i < siblings.length; i += 1) {
              if (siblings[i] === el) {
                index = i;
                break;
              }
            }
          }
          el.style.transitionDelay = Math.min(index, 6) * 70 + "ms";
          el.classList.add("is-visible");
          observer.unobserve(el);
        });
      },
      { rootMargin: "0px 0px -12% 0px", threshold: 0.12 }
    );

    Array.prototype.forEach.call(targets, function (el) {
      observer.observe(el);
    });
  }
})();
