function gotoLogin(){document.location="./index.php"}function getTokenStatus(){$.ajax({url:"/api/v4/login/reset/"+encodeURIComponent(track_id),cache:!1,type:"GET",headers:{"X-FBX-FREEBOX0S":"1"},dataType:"json",success:function(e){var t;if(e.success){t=e.result.status;if(t=="pending")setTimeout(getTokenStatus,500);else{$("#info-popup").hide(),$("#info-layer").hide(),$(".step").hide();switch(t){case"granted":$("#login-form").show(),$("#fbx-password").focus();break;case"denied":case"timeout":$("#failure-"+t).show();break;default:$("#failure-unknown").show()}}}else $("#errorMsg").text("Erreur interne"),$("#errorMsg").show()},error:function(){$("#errorMsg").text("Erreur interne"),$("#errorMsg").show()}})}function getResetToken(){$(".step").hide(),$("#info-popup").hide(),$("#info-layer").hide(),$("#step1").show(),$.ajax({url:"/api/v4/login/reset/",cache:!1,type:"POST",headers:{"X-FBX-FREEBOX0S":"1"},dataType:"json",success:function(e){e.success?(auth_token=e.result.token,track_id=e.result.track_id,getTokenStatus()):($("#errorMsg").text("Erreur interne"),$("#errorMsg").show())},error:function(){$("#errorMsg").text("Erreur interne"),$("#errorMsg").show()}})}function checkPasswordQuality(){var e={internal:"impossible de déterminer la qualité du mot de passe",too_short:"le mot de passe trop court",not_enough_different_chars:"le mot de passe ne contient pas assez de caractères différents",in_dictionnary:"le mot de passe est dans le dictionnaire",bad_xkcd:'<a href="http://xkcd.com/936/">You might want to read this</a>'};quality_req&&quality_req.abort(),quality_req=$.ajax({url:"/api/v4/login/quality/",cache:!1,type:"POST",dataType:"json",headers:{"X-FBX-FREEBOX0S":"1"},data:{password:$("#fbx-password").val()},success:function(t){var n;t.success?($("#warnMsg").text(""),$("#warnMsg").hide()):(n=e[t.error_code],n||(n=e.internal),$("#warnMsg").html("L'accès à distance ne sera pas possible avec ce mot de passe : <br />"+n),$("#warnMsg").show())}})}function infoPopupClick(){$("#info-layer").hide(),$("#info-popup").hide(),getResetToken()}var auth_token,track_id=0,auth_received=!1,quality_req=null,quality_req_timeout=null;$(function(){getResetToken(),$("#img-server").on("click",function(){$("#info-layer").show(),$("#info-popup").css("left",($(document).width()-$("#info-popup").outerWidth())/2),$("#info-popup").show()}),$("#login-form").on("submit",function(){if($("#fbx-password").val().length==0){$("#errorMsg").text("Le mot de passe ne peut être vide !"),$("#errorMsg").show();return}return $("#errorMsg").hide(),$.ajax({url:"/api/v4/login/change/",type:"POST",headers:{"X-FBX-FREEBOX0S":"1"},dataType:"json",data:{password:$("#fbx-password").val(),token:auth_token},success:function(e){e.success?document.location="./index.php":($("#errorMsg").text("La changement de mot de passe a échoué"),$("#errorMsg").show())},error:function(){$("#errorMsg").text("Erreur lors du changement de mot de passe"),$("#errorMsg").show()}}),!1}),$("#fbx-password").keyup(function(){quality_req_timeout&&clearTimeout(quality_req_timeout),quality_req_timeout=setTimeout(checkPasswordQuality,200)})});