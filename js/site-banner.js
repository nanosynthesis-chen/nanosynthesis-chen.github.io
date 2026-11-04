(function () {
    var banner = document.getElementById("banner");
    if (!banner) {
        return;
    }
    var lis = banner.querySelectorAll(".imgList > li");
    if (!lis.length) {
        return;
    }
    var index = 0;
    var timer = null;
    function show(i) {
        for (var k = 0; k < lis.length; k++) {
            lis[k].classList.toggle("active", k === i);
        }
    }
    function next() {
        index = (index + 1) % lis.length;
        show(index);
    }
    function start() {
        if (timer) {
            clearInterval(timer);
        }
        timer = setInterval(next, 4000);
    }
    show(0);
    start();
    banner.addEventListener("mouseenter", function () {
        if (timer) {
            clearInterval(timer);
            timer = null;
        }
    });
    banner.addEventListener("mouseleave", function () {
        start();
    });
})();
