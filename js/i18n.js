(function () {
    var I18N = {
        en: {
            "nav.home": "Home",
            "nav.members": "Members",
            "nav.publication": "Publications",
            "nav.album": "Album",
            "nav.contact": "Contact",
            "footer.rights": "© 2026 The Nanosynthesis Consortium. All rights reserved.",
            "home.focus": "The Chen lab works to develop methodologies for the synthesis of complex nanostructures for novel applications.",
            "home.explore": "Explore the Lab",
            "home.card.members": "Members",
            "home.card.publication": "Publications",
            "home.card.album": "Album",
            "home.card.contact": "Contact",
            "backtop.aria": "Back to top",
            "lang.button": "中文"
        },
        zh: {
            "nav.home": "首页",
            "nav.members": "成员名单",
            "nav.publication": "学术成果",
            "nav.album": "相册",
            "nav.contact": "联系方式",
            "footer.rights": "© 2026 西湖纳米合成实验室 版权所有",
            "home.focus": "陈虹宇课题组致力于开发复杂纳米结构合成的方法学，应用于新颖的科学探索。",
            "home.explore": "探索实验室",
            "home.card.members": "成员名单",
            "home.card.publication": "学术成果",
            "home.card.album": "相册",
            "home.card.contact": "联系方式",
            "backtop.aria": "返回顶部",
            "lang.button": "EN"
        }
    };

    var KEY = "ns_lang";

    function t(key, lang) {
        var dict = I18N[lang];
        if (dict && dict[key]) return dict[key];
        return I18N.en[key] || key;
    }

    function apply(lang) {
        document.documentElement.setAttribute("lang", lang);
        document.documentElement.setAttribute("data-lang", lang);
        var all = document.querySelectorAll("[data-i18n]");
        for (var i = 0; i < all.length; i++) {
            var el = all[i];
            var key = el.getAttribute("data-i18n");
            var val = t(key, lang);
            if (el.getAttribute("data-i18n-html") === "1") {
                el.innerHTML = val;
            } else {
                el.textContent = val;
            }
        }
        var btn = document.querySelector(".lang-btn");
        if (btn) {
            var lbl = btn.querySelector(".lang-btn-text");
            if (lbl) lbl.textContent = t("lang.button", lang);
            btn.setAttribute("aria-label", lang === "en" ? "Switch to Chinese" : "切换到英文");
        }
    }

    function ensureButton() {
        var header = document.querySelector(".site-header-inner");
        if (!header) return null;
        var existing = header.querySelector(".lang-btn");
        if (existing) return existing;
        var btn = document.createElement("button");
        btn.className = "lang-btn";
        btn.type = "button";
        btn.innerHTML = '<span class="lang-icon">🌐</span><span class="lang-btn-text"></span>';
        btn.addEventListener("click", function () {
            var cur = document.documentElement.getAttribute("data-lang") || "zh";
            var target = (cur === "en") ? "zh" : "en";
            localStorage.setItem(KEY, target);
            apply(target);
        });
        header.appendChild(btn);
        return btn;
    }

    function init() {
        var saved = localStorage.getItem(KEY);
        var lang = (saved === "en" || saved === "zh") ? saved : "zh";
        apply(lang);
        ensureButton();
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
})();
