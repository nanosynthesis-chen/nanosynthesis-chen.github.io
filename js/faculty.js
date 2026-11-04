window.onload=function ()
{
		
	var faculty=document.getElementById("faculty");
	var subGroupe=document.getElementById("subGroupe");
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
	

	/*for(var i=0; i<subArr.length; i++){
			if(facArr[i].style.backgroundColor="#11719E"){
				subArr[i].style.display="block";
			}		
	}*/
			


}