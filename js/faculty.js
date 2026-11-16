/* 页面跳转前记录当前高亮按钮，跳转后让绿色高亮块平滑滑过去。
   本脚本在 <head> 中同步执行，先锁住高亮颜色，避免新页面先闪一下再回跳。 */
(function (){
	try{
		var st = window.name ? JSON.parse(window.name) : null;
		if(st && (st.nav === 'faculty' || st.nav === 'album' || st.nav === 'site')){
			document.documentElement.className += ' nav-pending';
		}
	}catch(e){}
})();

function initNavs(){
	var faculty=document.getElementById("faculty");
	var album=document.getElementById("album");
	var siteNav=document.querySelector('.site-nav');
	var header=document.querySelector('.site-header');
	var navs=[];
	var flying=false;
	if(faculty) navs.push({el:faculty,key:'faculty',activeClass:'present',sticky:true});
	if(album) navs.push({el:album,key:'album',activeClass:'IAS',sticky:true});
	if(siteNav) navs.push({el:siteNav,key:'site',activeClass:'active',sticky:false});

	/* 吸顶：top 跟随顶部 header 实际高度 */
	function setNavTop(){
		var h = header ? header.offsetHeight : 78;
		for(var i=0;i<navs.length;i++){
			if(navs[i].sticky) navs[i].el.style.top = h + 'px';
		}
	}
	setNavTop();
	window.addEventListener('resize', setNavTop);

	function initNav(item){
		var nav=item.el;
		var links=nav.getElementsByTagName("a");

		/* 点击时记录当前高亮按钮序号，供下一页做滑动动画 */
		nav.addEventListener('click', function(e){
			var el=e.target;
			while(el && el!==nav && el.tagName!=='A'){ el=el.parentNode; }
			if(!el || el===nav) return;
			var active=-1;
			for(var i=0;i<links.length;i++){
				var cls=links[i].className||'';
				if(cls.indexOf(item.activeClass)>=0){ active=i; }
			}
			try{ window.name = JSON.stringify({nav:item.key, index:active}); }catch(err){}
		}, false);

		/* 绿色高亮块从上一页的按钮滑到当前按钮 */
		/* Cloudflare Pages 会把 /chy.html 重写成 /chy，匹配时统一去掉 .html 后缀。
		   尾部斜杠（如 /chy/）也要正确识别为 chy */
		function fileName(u){
			if(!u) return '';
			var s=u.split('?')[0].split('#')[0];
			s=s.replace(/\/+$/, '');   /* 去掉尾部一个或多个斜杠 */
			if(!s || s.charAt(s.length-1)==='/') return 'index';
			var n=s.split('/').pop();
			return n ? n.replace(/\.html?$/i,'') : 'index';
		}
		function indexFromReferrer(){
			var ref=document.referrer;
			if(!ref) return -1;
			var name=fileName(ref);
			for(var i=0;i<links.length;i++){
				if(fileName(links[i].getAttribute('href'))===name) return i;
			}
			return -1;
		}

		var prevIdx=-1;
		var nameMatched=false;
		if(document.referrer){
			prevIdx=indexFromReferrer();
			if(prevIdx>=0){ nameMatched=true; }
		}
		/* referrer 匹配失败时 fallback 到 window.name */
		if(!nameMatched){
			var prev=null;
			try{ prev = window.name ? JSON.parse(window.name) : null; }catch(err){ prev=null; }
			if(prev && prev.nav===item.key && typeof prev.index==='number'){
				prevIdx=prev.index;
				nameMatched=true;
			}
		}
		if(!nameMatched || prevIdx<0) return;

		var cur=-1;
		for(var j=0;j<links.length;j++){
			var c=links[j].className||'';
			if(c.indexOf(item.activeClass)>=0){ cur=j; }
		}
		if(cur<0 || prevIdx===cur || prevIdx>=links.length) return;

		var navRect=nav.getBoundingClientRect();
		var rOld=links[prevIdx].getBoundingClientRect();
		var rNew=links[cur].getBoundingClientRect();
		if(!rOld.width || !rNew.width) return;

		var pill=document.createElement('div');
		pill.className='nav-fly-pill nav-fly-pill-' + item.key;
		pill.style.left=(rOld.left-navRect.left)+'px';
		pill.style.top=(rOld.top-navRect.top)+'px';
		pill.style.width=rOld.width+'px';
		pill.style.height=rOld.height+'px';
		pill.style.opacity='0';   /* 初始隐藏，避免突兀出现 */

		/* 按位移距离换算时长，让三个导航栏的滑动速度保持一致。
		   位置过渡用 dur，opacity 保持快速（0.16s） */
		var dist=Math.abs((rNew.left+rNew.width/2)-(rOld.left+rOld.width/2));
		var dur=Math.max(0.3, Math.min(0.9, dist*0.0045));
		pill.style.transition = 'left ' + dur + 's cubic-bezier(0.16,0.84,0.3,1), '
			+ 'top ' + dur + 's cubic-bezier(0.16,0.84,0.3,1), '
			+ 'width ' + dur + 's cubic-bezier(0.16,0.84,0.3,1), '
			+ 'height ' + dur + 's cubic-bezier(0.16,0.84,0.3,1), '
			+ 'opacity 0.16s ease-out';

		nav.appendChild(pill);
		nav.className += ' nav-flying';   /* 触发 CSS 覆盖规则：目标按钮透明底+深灰字 */
		flying=true;
		window.__navAnimated=true;

		/* 等浏览器把起始状态画出来之后再移动，否则页面首帧渲染慢时动画会直接跳过 */
		function go(){
			document.documentElement.className = document.documentElement.className.replace(' nav-pending','');
			pill.style.opacity='1';   /* 开始飞前淡入 */
			pill.style.left=(rNew.left-navRect.left)+'px';
			pill.style.top=(rNew.top-navRect.top)+'px';
			pill.style.width=rNew.width+'px';
			pill.style.height=rNew.height+'px';
		}
		if(window.requestAnimationFrame){
			requestAnimationFrame(function(){ requestAnimationFrame(go); });
		}else{
			setTimeout(go, 40);
		}

		/* 到达终点：移除 nav-flying 让按钮恢复正常绿底白字，pill 淡出删除 */
		var arrived=false;
		function arrive(){
			if(arrived) return;
			arrived=true;
			nav.className = nav.className.replace(' nav-flying','');   /* CSS 覆盖规则失效，按钮恢复绿底白字 */
			pill.style.opacity='0';
			setTimeout(function(){
				if(pill.parentNode) pill.parentNode.removeChild(pill);
			}, 160);
		}
		pill.addEventListener('transitionend', function(e){
			if(e.target!==pill) return;
			if(e.propertyName==='left' || e.propertyName==='width') arrive();
		}, false);
		setTimeout(arrive, dur*1000+80);
	}

	for(var k=0;k<navs.length;k++){ initNav(navs[k]); }

	/* 没有动画时立即解除高亮锁定 */
	if(!flying){
		document.documentElement.className = document.documentElement.className.replace(' nav-pending','');
	}
}

if(document.readyState === 'loading'){
	document.addEventListener('DOMContentLoaded', initNavs, false);
}else{
	initNavs();
}

/* 个别页面 DOMContentLoaded 时样式/布局尚未就绪会导致动画被跳过，加载完成后兜底重试一次 */
window.addEventListener('load', function(){
	if(!window.__navAnimated){ initNavs(); }
}, false);
