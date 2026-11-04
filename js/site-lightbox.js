(function () {
    function createOverlay() {
        var overlay = document.getElementById("ns-lightbox");
        if (overlay) {
            return overlay;
        }
        overlay = document.createElement("div");
        overlay.id = "ns-lightbox";
        overlay.className = "ns-lightbox";
        overlay.setAttribute("role", "dialog");
        overlay.innerHTML = '<div class="ns-lightbox-inner"><img alt=""/><button class="ns-lightbox-close" aria-label="关闭">×</button></div>';
        document.body.appendChild(overlay);
        overlay.addEventListener("click", function () {
            closeOverlay();
        });
        document.addEventListener("keydown", function (e) {
            if (e.key === "Escape") {
                closeOverlay();
            }
        });
        return overlay;
    }

    function openOverlay(src) {
        var overlay = createOverlay();
        var img = overlay.querySelector("img");
        if (img.getAttribute("src") !== src) {
            img.setAttribute("src", src);
        }
        overlay.classList.add("open");
        document.body.style.overflow = "hidden";
    }

    function closeOverlay() {
        var overlay = document.getElementById("ns-lightbox");
        if (overlay) {
            overlay.classList.remove("open");
            document.body.style.overflow = "";
        }
    }

    document.addEventListener("click", function (e) {
        var img = e.target.closest ? e.target.closest("img") : null;
        if (!img) {
            return;
        }
        if (img.closest && img.closest(".ns-lightbox")) {
            return;
        }
        if (img.closest && img.closest("#banner")) {
            return;
        }
        e.preventDefault();
        e.stopPropagation();
        var full = img.getAttribute && img.getAttribute("data-full") ? img.getAttribute("data-full") : (img.currentSrc || img.src); openOverlay(full);
    }, true);
    function setupHints() {
        var imgs = document.querySelectorAll("img");
        for (var i = 0; i < imgs.length; i++) {
            var img = imgs[i];
            if (img.closest && (img.closest(".ns-lightbox") || img.closest("#banner"))) {
                continue;
            }
            img.setAttribute("title", "点击放大图片");
            img.style.cursor = "zoom-in";
        }
    }
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", setupHints);
    } else {
        setupHints();
    }
})();
