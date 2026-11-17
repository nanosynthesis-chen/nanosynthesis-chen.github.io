(function () {
    var scale = 1;
    var tx = 0;
    var ty = 0;
    var dragging = false;
    var moved = false;
    var startX = 0;
    var startY = 0;
    var startTx = 0;
    var startTy = 0;

    function applyTransform(img) {
        if (!img) {
            return;
        }
        img.style.transform = "translate(" + tx + "px," + ty + "px) scale(" + scale + ")";
        img.style.cursor = scale > 1 ? (dragging ? "grabbing" : "grab") : "zoom-in";
    }

    function resetView(img) {
        scale = 1;
        tx = 0;
        ty = 0;
        dragging = false;
        moved = false;
        if (img) {
            img.style.transformOrigin = "center center";
            applyTransform(img);
        }
    }

    function createOverlay() {
        var overlay = document.getElementById("ns-lightbox");
        if (overlay) {
            return overlay;
        }
        overlay = document.createElement("div");
        overlay.id = "ns-lightbox";
        overlay.className = "ns-lightbox";
        overlay.setAttribute("role", "dialog");
        overlay.innerHTML = '<div class="ns-lightbox-inner"><img alt=""/></div>';
        document.body.appendChild(overlay);

        overlay.addEventListener("click", function (e) {
            if (moved) {
                moved = false;
                return;
            }
            closeOverlay();
        });

        overlay.addEventListener("wheel", function (e) {
            var img = overlay.querySelector("img");
            if (!img) {
                return;
            }
            e.preventDefault();
            var factor = e.deltaY < 0 ? 1.18 : 1 / 1.18;
            var next = Math.max(1, Math.min(6, scale * factor));
            if (next === scale) {
                return;
            }
            var rect = img.getBoundingClientRect();
            if (rect.width && rect.height) {
                var anchorX = Math.min(Math.max(window.innerWidth / 2, rect.left), rect.right);
                var anchorY = Math.min(Math.max(window.innerHeight / 2, rect.top), rect.bottom);
                var baseX = rect.left + rect.width / 2 - tx;
                var baseY = rect.top + rect.height / 2 - ty;
                var k = next / scale;
                tx = k * tx + (1 - k) * (anchorX - baseX);
                ty = k * ty + (1 - k) * (anchorY - baseY);
            }
            scale = next;
            if (scale === 1) {
                tx = 0;
                ty = 0;
            }
            img.style.transformOrigin = "center center";
            applyTransform(img);
        }, { passive: false });

        overlay.addEventListener("pointerdown", function (e) {
            var img = overlay.querySelector("img");
            if (!img || scale <= 1 || e.button !== 0) {
                return;
            }
            dragging = true;
            moved = false;
            startX = e.clientX;
            startY = e.clientY;
            startTx = tx;
            startTy = ty;
            applyTransform(img);
            if (overlay.setPointerCapture) {
                try {
                    overlay.setPointerCapture(e.pointerId);
                } catch (err) {}
            }
            e.preventDefault();
        });

        overlay.addEventListener("pointermove", function (e) {
            if (!dragging) {
                return;
            }
            var dx = e.clientX - startX;
            var dy = e.clientY - startY;
            if (Math.abs(dx) > 3 || Math.abs(dy) > 3) {
                moved = true;
            }
            tx = startTx + dx;
            ty = startTy + dy;
            applyTransform(overlay.querySelector("img"));
            e.preventDefault();
        });

        function endDrag(e) {
            if (!dragging) {
                return;
            }
            dragging = false;
            applyTransform(overlay.querySelector("img"));
            if (overlay.releasePointerCapture) {
                try {
                    overlay.releasePointerCapture(e.pointerId);
                } catch (err) {}
            }
        }

        overlay.addEventListener("pointerup", endDrag);
        overlay.addEventListener("pointercancel", endDrag);

        document.addEventListener("keydown", function (e) {
            if (e.key === "Escape") {
                closeOverlay();
            }
        });
        return overlay;
    }

    function fitImage(img) {
        var inner = img && img.parentNode;
        if (!inner || !img.naturalWidth || !img.naturalHeight) {
            return;
        }
        var boxW = inner.clientWidth;
        var boxH = inner.clientHeight;
        if (!boxW || !boxH) {
            return;
        }
        var k = Math.min(boxW / img.naturalWidth, boxH / img.naturalHeight);
        img.style.width = Math.round(img.naturalWidth * k) + "px";
        img.style.height = Math.round(img.naturalHeight * k) + "px";
    }

    function openOverlay(src) {
        var overlay = createOverlay();
        var img = overlay.querySelector("img");
        resetView(img);
        img.style.width = "";
        img.style.height = "";
        img.draggable = false;
        overlay.classList.add("open");
        document.body.style.overflow = "hidden";
        img.onload = function () {
            fitImage(img);
        };
        if (img.getAttribute("src") !== src) {
            img.setAttribute("src", src);
        }
        if (img.complete && img.naturalWidth) {
            fitImage(img);
        }
    }

    window.addEventListener("resize", function () {
        var overlay = document.getElementById("ns-lightbox");
        if (overlay && overlay.classList.contains("open")) {
            fitImage(overlay.querySelector("img"));
        }
    }, false);

    function closeOverlay() {
        var overlay = document.getElementById("ns-lightbox");
        if (overlay) {
            overlay.classList.remove("open");
            document.body.style.overflow = "";
            resetView(overlay.querySelector("img"));
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
        var full = img.getAttribute && img.getAttribute("data-full") ? img.getAttribute("data-full") : (img.currentSrc || img.src);
        openOverlay(full);
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
