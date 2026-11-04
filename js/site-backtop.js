(function () {
    if (document.body && document.body.getAttribute("data-backtop") === "false") {
        return;
    }
    var btn = document.createElement("button");
    btn.className = "site-backtop";
    btn.setAttribute("aria-label", "返回顶部");
    btn.textContent = "↑";
    document.body.appendChild(btn);
    function toggle() {
        if ((window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop) > 200) {
            btn.classList.add("show");
        } else {
            btn.classList.remove("show");
        }
    }
    btn.addEventListener("click", function () {
        window.scrollTo({ top: 0, behavior: "smooth" });
    });
    window.addEventListener("scroll", toggle);
    toggle();
})();
