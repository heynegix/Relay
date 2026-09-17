(function () {
  "use strict";

  var root = document.documentElement;
  var toggle = document.getElementById("langToggle");
  var label = document.getElementById("langLabel");
  var meta = {
    ja: {
      title: "Relay — 通信が途切れても、情報は進める。",
      description: "Relayは、通信が不安定な状況でも救助情報を次の接点へ運ぶ、オープンソースのローカルファースト災害通信プロジェクトです。"
    },
    en: {
      title: "Relay — When the network breaks, information can still move.",
      description: "Relay is an open-source, local-first disaster communication project that carries encrypted rescue information across available paths."
    }
  };

  function applyLanguage(next, persist) {
    next = next === "en" ? "en" : "ja";
    root.dataset.lang = next;
    root.lang = next;
    document.title = meta[next].title;

    var description = document.querySelector('meta[name="description"]');
    if (description) description.content = meta[next].description;
    var ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle) ogTitle.content = meta[next].title;
    var ogDescription = document.querySelector('meta[property="og:description"]');
    if (ogDescription) ogDescription.content = meta[next].description;

    if (label) label.textContent = next === "ja" ? "EN" : "JA";
    if (toggle) {
      toggle.setAttribute("aria-label", next === "ja" ? "Switch to English" : "日本語に切り替える");
      toggle.title = next === "ja" ? "Switch to English" : "日本語に切り替える";
    }
    if (persist) {
      try { localStorage.setItem("relay-lang", next); } catch (e) {}
    }
  }

  if (toggle) {
    toggle.addEventListener("click", function () {
      applyLanguage(root.dataset.lang === "ja" ? "en" : "ja", true);
    });
  }
  applyLanguage(root.dataset.lang, false);

  var targets = document.querySelectorAll(".reveal");
  if (!("IntersectionObserver" in window)) {
    Array.prototype.forEach.call(targets, function (element) { element.classList.add("is-visible"); });
    return;
  }

  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) return;
      var element = entry.target;
      var siblings = element.parentElement ? Array.prototype.indexOf.call(element.parentElement.children, element) : 0;
      element.style.transitionDelay = Math.min(Math.max(siblings, 0), 5) * 65 + "ms";
      element.classList.add("is-visible");
      observer.unobserve(element);
    });
  }, { rootMargin: "0px 0px -12% 0px", threshold: 0.1 });

  Array.prototype.forEach.call(targets, function (element) { observer.observe(element); });
})();
