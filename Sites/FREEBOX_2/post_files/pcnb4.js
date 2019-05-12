var urlParams = extractUrlParams();
var timer = 7000;

window.onresize = function(event) {
        if (document.getElementById("box") != null && document.getElementById("box").style.display=="block"){
                var winW,winH;
                if (document.body && document.body.offsetWidth) {
                 winW = document.body.offsetWidth;
                 winH = document.body.offsetHeight;
                }
                if (document.compatMode=='CSS1Compat' && document.documentElement && document.documentElement.offsetWidth ) {
                 winW = document.documentElement.offsetWidth;
                 winH = document.documentElement.offsetHeight;
                }
                if (window.innerWidth && window.innerHeight) {
                 winW = window.innerWidth;
                 winH = window.innerHeight;
                }
                var larg = (winW - document.getElementById('box').offsetWidth) / 2;
                var haut = (winH - document.getElementById('box').offsetHeight) / 2;
                document.getElementById("box").style.top=haut+"px";
                document.getElementById("box").style.left=larg+"px";
        }
}

function init() {
    if (urlParams['res'] == 'success') {
        openPopup(645, 310, 'successDiv', false);
        setTimeout('redirectUserURL()', 1000);
    }
    initError(urlParams['res']);
    if (urlParams['res'] != 'success') {
	if (getCookie('autoProviderSFR')) {
	    document.forms['connect'].choix.value = getCookie('autoProviderSFR');
	}
	if (getCookie('autoLoginSFR')) {
	    document.forms['connect'].username.value = getCookie('autoLoginSFR');
	    document.forms['connect'].password.focus();
	    document.forms['connect'].save.checked = true;
	}
    } else
	    document.forms['connect'].username.focus();
}

function initError(res){
	var error = getCookie('error');
	var date=new Date;
	if (error != null){
		var endstr = error.indexOf(",", 0);
		num_error = parseInt(unescape(error.substring(0, endstr)));
		var date_end = parseInt(unescape(error.substring(endstr+1, error.length)));
		if (res == 'failed'){
			num_error = num_error + 1;
			if (num_error == 3){
				date.setHours(date.getHours()+1);
				openPopup(600, 270, 'erreurDiv', false);
			} else if (num_error > 3) {
				openPopup(600, 270, 'erreurDiv', false);
				date.setTime(date_end);
			} else {
				openPopup(600, 270, 'erreurDiv', true);
				date.setTime(date_end);
			}
			setCookie("error", num_error.toString()+","+date.getTime(), date);
		} else if (res == "success"){
			setCookie("error", num_error.toString()+","+date.getTime(), null);
		} else if (res == "notyet" && num_error > 3){
			openPopup(600, 270, 'erreurDiv', false);
		}
	} else if (res == 'failed'){
		date.setMinutes(date.getMinutes()+10);
		setCookie("error", "1,"+date.getTime(), date);
		openPopup(600, 270, 'erreurDiv', true);
	} else if (res == 'success'){
		setCookie("error", num_error.toString()+","+date.getTime(), null);
	}
}

function retirerLangue(){
    var doc, docs, docTemp;
    docs=document.location.href.split("#");
    docTemp = docs[0];
    doc=docTemp.split("?");
    var res = doc[0];
    if(doc[1]){
        var first = true;
        for(var key in urlParams){
            if(key != "lang"){
                if(first == true){
                    res = res+"?";
                    res += key+'='+urlParams[key];
                    first = false;
                }else
                    res += '&'+key+'='+urlParams[key];
            }
        }
    }
    return res;
}

function changeLangue(langue){
    var doc, docTemp;
    doc = retirerLangue();
    if (langue=="en"){
        docTemp=document.location.href.split("?");
        if (docTemp[1])
            window.location = doc+"&lang=en";
        else
            window.location = doc+"?lang=en";
    }else{
        window.location = doc;
    }
}

function setCookie(sName, sValue, sTime) {
        document.cookie=sName+"="+escape(sValue)+
				  ((sTime==null) ? "" : ("; expires="+sTime.toGMTString()));
}

function getCookie(sName) {
        var oRegex = new RegExp("(?:; )?" + sName + "=([^;]*);?");
 
        if (oRegex.test(document.cookie)) {
                return decodeURIComponent(RegExp["$1"]);
        } else {
                return null;
        }
}

function redirectUserURL(){
    timer = timer - 1000;
    document.getElementById("theTimer").innerHTML = "&nbsp;" +(timer / 1000) + " secondes";
    if (timer == 0){
        var userurl = "http://www.sfr.fr";
        if (urlParams['userurl']){
            var myString = new String(unescape(urlParams['userurl']));
            var myArray = myString.split(';');
            userurl = myArray[0];
            if (myArray[4]) userurl = myArray[4];
        }
        window.location = userurl;
    }else
        setTimeout('redirectUserURL()', 1000);
}

function extractUrlParams(){
	var t = location.search.substring(1).split('&');
	var f = [];
	for (var i=0; i<t.length; i++){
		var x = t[ i ].split('=');
		f[x[0]]=x[1];
	}
	return f;
}

function openPopup(largeur, hauteur, contenu, fermer){
    document.getElementById("voile").style.display="block";
    document.getElementById("contenuBox").innerHTML = document.getElementById(contenu).innerHTML;
    if (fermer == false) document.getElementById("fermerBox").style.display="none";
        else document.getElementById("fermerBox").style.display="inline";
    document.getElementById("box").style.width=largeur+"px";
    document.getElementById("box").style.height=hauteur+"px";
    document.getElementById("box").style.display="block";
    var winW,winH;
    if (document.body && document.body.offsetWidth) {
     winW = document.body.offsetWidth;
     winH = document.body.offsetHeight;
    }
    if (document.compatMode=='CSS1Compat' &&
        document.documentElement &&
        document.documentElement.offsetWidth ) {
     winW = document.documentElement.offsetWidth;
     winH = document.documentElement.offsetHeight;
    }
    if (window.innerWidth && window.innerHeight) {
     winW = window.innerWidth;
     winH = window.innerHeight;
    }
    var larg = (winW - document.getElementById('box').offsetWidth) / 2;
    var haut = (winH - document.getElementById('box').offsetHeight) / 2;
    document.getElementById("box").style.top=haut+"px";
    document.getElementById("box").style.left=larg+"px";

}

function closePopup(){
    document.getElementById("voile").style.display="none";
    document.getElementById("box").style.display="none";
}

function showInfos(id){
    var ids = new Array('p1','p2','p3');
    var i;
    var hautC, hautB, hautE;
    for (i = 0; i < 3; i++){
        if (ids[i] == id && document.getElementById(ids[i]).style.display == "none"){
            document.getElementById(ids[i]).style.display = "block";
        }else if (ids[i] == id && document.getElementById(ids[i]).style.display == "block"){
            document.getElementById(ids[i]).style.display = "none";
        }else{
            document.getElementById(ids[i]).style.display = "none";
        }
    }
    
}

function validForm(){
    var date=new Date;
    if (document.forms['connect'].username.value == ''){
        alert('Merci d\'entrer votre E-mail ou NeufID');
        return false;
    }
    document.forms['connect'].username2.value = document.forms['connect'].username.value;
    if (document.forms['connect'].password.value == ''){
        alert('Merci d\'entrer votre mot de passe');
        return false;
    }
    if (document.forms['connect'].conditions.checked == false){
        alert('Merci de valider les termes et conditions du service');
        return false;
    }

    var challenge = '';
    if (urlParams['challenge']) challenge = urlParams['challenge'];
    document.forms['connect'].challenge.value = challenge;

    var accessType = 'neuf';
    if (document.forms['connect'].choix){
        var selected = (document.forms['connect'].choix.options.selectedIndex);
        var choix = choix = document.forms['connect'].choix.options[selected].value;
        document.forms['connect'].accessType.value = choix;
    }else
        document.forms['connect'].accessType.value = accessType;

    var lang = 'fr';
    if (urlParams['lang'] && urlParams['lang'] == 'en') lang = urlParams['lang'];
    document.forms['connect'].lang.value = lang;
    date=new Date;
    date.setMinutes(date.getMinutes() + 15);
    setCookie('langSFR', lang, date);

    var userurl = 'http://www.sfr.fr';
    if (urlParams['userurl']){
        var myString = new String(urlParams['userurl']);
        var myArray = myString.split('%253b');
        userurl = myArray[0];
        if (myArray[4]) userurl = myArray[4];
    }
    document.forms['connect'].userurl.value = userurl;

    var mode = '3';
    if (urlParams['mode']) mode = urlParams['mode'];
    document.forms['connect'].mode.value = mode;

    var channel = '0';
    if (urlParams['channel']) channel = urlParams['channel'];
    document.forms['connect'].channel.value = channel;

    var uamip = '192.168.2.1';
    if (urlParams['uamip']) uamip = urlParams['uamip'];
    document.forms['connect'].uamip.value = uamip;

    var uamport = '3990';
    if (urlParams['uamport']) uamport = urlParams['uamport'];
    document.forms['connect'].uamport.value = uamport;
	
    var mac = '00:00:00:00:00';
    if (urlParams['mac']) mac = urlParams['mac'];
    document.forms['connect'].mac.value = mac+'|'+urlParams['nasid'];
    
	if (document.forms['connect'].save.checked == true){
            date=new Date;
            date.setMinutes(date.getMinutes()+ (7*24*60));
            setCookie('autoLoginSFR', document.forms['connect'].username.value, date);
	    setCookie('autoProviderSFR', document.forms['connect'].choix.value, date);
    }

    return true;
}