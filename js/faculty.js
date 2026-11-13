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
		function fileName(u){
			if(!u) return '';
			var s=u.split('?')[0].split('#')[0];
			if(s.charAt(s.length-1)==='/') return 'index.html';
			return s.split('/').pop();
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
		if(document.referrer){
			prevIdx=indexFromReferrer();
			if(prevIdx<0) return;   /* 来源页不在该导航中，不做动画 */
		}else{
			var prev=null;
			try{ prev = window.name ? JSON.parse(window.name) : null; }catch(err){ prev=null; }
			if(!prev || prev.nav!==item.key || typeof prev.index!=='number') return;
			prevIdx=prev.index;
		}

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
		pill.className='nav-fly-pill' + (item.key==='site' ? ' nav-fly-pill-site' : '');
		pill.style.left=(rOld.left-navRect.left)+'px';
		pill.style.top=(rOld.top-navRect.top)+'px';
		pill.style.width=rOld.width+'px';
		pill.style.height=rOld.height+'px';

		/* 按位移距离换算时长，让三个导航栏的滑动速度保持一致
		   （以顶部主导航一格（约 100px / 0.62s）的速度为基准） */
		var dist=Math.abs((rNew.left+rNew.width/2)-(rOld.left+rOld.width/2));
		var dur=Math.max(0.45, Math.min(1.35, dist*0.0062));
		pill.style.transitionDuration=dur+'s';

		nav.appendChild(pill);
		nav.className += ' nav-flying';

		/* 强制回流后再移动到目标位置，触发过渡 */
		void pill.offsetWidth;
		pill.style.left=(rNew.left-navRect.left)+'px';
		pill.style.top=(rNew.top-navRect.top)+'px';
		pill.style.width=rNew.width+'px';
		pill.style.height=rNew.height+'px';

		setTimeout(function(){
			if(pill.parentNode) pill.parentNode.removeChild(pill);
			nav.className = nav.className.replace(' nav-flying','');
		}, dur*1000+120);
	}

	for(var k=0;k<navs.length;k++){ initNav(navs[k]); }

	/* 解除高亮锁定 */
	document.documentElement.className = document.documentElement.className.replace(' nav-pending','');
}

if(document.readyState === 'loading'){
	document.addEventListener('DOMContentLoaded', initNavs, false);
}else{
	initNavs();
}

window.onload=function ()
{
	var faculty=document.getElementById("faculty");
	var subGroupe=document.getElementById("subGroupe");
	if(!faculty || !subGroupe) return;
	var facArr=faculty.getElementsByTagName("a");
	var subArr=subGroupe.getElementsByTagName("div");

	function bind(obj,eventstr,callback){
		if(obj.addEventListener){
			obj.addEventListener(eventstr,callback,false);
		}else{
			obj.attachEvent("on"+eventStr,callback);
		}
	}

	for(var i=0; i<facArr.length; i++)
	{
		bind(facArr[i], "click", function(){
			for(var j=0; j<facArr.length; j++)
			{
				facArr[j].style.backgroundColor="#EBEBEB";
			};
			this.style.backgroundColor="#11719E";
		});
	}
}
