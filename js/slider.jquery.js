/*******

	***	imageSlider by Cedric Dugas	***
	*** Http://www.position-absolute.com ***
	
	Slide your image gallery without effort with this script
	
	You can use and modify this script for any project you want, but please leave this comment as credit.

*****/
$(document).ready(function() {

	nSliders=$('.slider').size();
	var oSliders=new Object();
	for(var i=0;i<nSliders;i++){
		var thisContainer=$('.slider:eq('+i+')');
		padding = 0
		if (thisContainer.attr("id") == "animVertical"){
			var animSide = "top"
		}else{
			var animSide ="left"
		}
		oSliders[i]=new rotateDiv(i, padding, thisContainer, animSide);
	}
});

function rotateDiv(num, padding, jqContainer, animSide){
	this.animSide = animSide
	this.numero=num;
	this.jqContainer=jqContainer;
    this.headline_size;
	this.animPos = 0;
	this.headlineNum = 0;
	this.oldHeadline = 0;
	this.divPos=0;
	this.side = 0;
	this.divWidth = 0;
	this.position = 0;
	this.divPadding = padding;
	
	if (this.animSide == "top"){ // place les items du sens voulu
		this.divWidth = jqContainer.find("div.items:eq(0)").height() + this.divPadding;
	} else {
		this.divWidth = jqContainer.find("div.items:eq(0)").width() + this.divPadding;
	}
	
	this.headline_size = jqContainer.find("div.items").size();
	this.headline_sizeMinusOne = jqContainer.find("div.items").size() -1;
	for(x=0;x<this.headline_size; x++){
		jqContainer.find("div.items:eq(" + x + ")").css(this.animSide, this.position);
		this.position = this.position + this.divWidth;
	}
	jqContainer.find("a.moveLeft").click(associateObjWithEvent(this,"move"));
	jqContainer.find("a.moveRight").click(associateObjWithEvent(this,"move"));
}
rotateDiv.prototype.move=function(e, o)  {

	//quel sens? depend du a clique
	var classe=o.getAttribute('name');
	var sens=classe=='moveLeft'?-1:1;

    itemContainer = this.jqContainer.find('.containerItems'); 
	this.multipleWidth = this.divWidth * this.headline_size;

    if ((this.side ==0 && sens==-1) || (this.side ==1 && sens==1)){
		this.divPos=this.divPos - (sens * this.multipleWidth);
		this.side=!this.side;
	}
	this.animPos = this.animPos +(sens* this.divWidth) ; //on incremente la position target du div selon le mouvement que l'on veut

    var animation=new Object();
	animation[this.animSide]=this.animPos;

	if(sens==-1){
		var passeObject=this;

		itemContainer.animate(animation,800,
            function bouge() {
				itemContainer.children().eq(passeObject.oldHeadline).css(passeObject.animSide, passeObject.divPos);
				passeObject.divPos = passeObject.divPos + passeObject.divWidth;
				passeObject.headlineNum = (passeObject.oldHeadline + 1 ) % (passeObject.headline_size);

				passeObject.oldHeadline = passeObject.headlineNum;
		});
	} else {
        this.headlineNum = (this.oldHeadline +this.headline_size-1) % (this.headline_size);
        this.oldHeadline = this.headlineNum;
		this.divPos = this.divPos - (sens * this.divWidth);
		this.jqContainer.find("div.items:eq(" + this.headlineNum + ")").css(this.animSide, this.divPos);

		this.jqContainer.find("div.containerItems").animate(animation,800);
	}
return false;
}
function associateObjWithEvent(obj, methodName){
    return (function(e){
        e = e||window.event;
        return obj[methodName](e, this);
    });
}





















