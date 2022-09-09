#!/bin/bash
########################################################################
# Version: 0.3
# License: AGPL-3.0 (https://choosealicense.com/licenses/agpl-3.0/)
########################################################################
{
MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
ME="${0##*/}"

[ $(id -u) -eq 0 ] && echo "LANCEMENT root INTERDIT. Utilisez un simple utilisateur du groupe \"sudo\" SVP" && exit 1

########################################################################
[[ ! $(which ipfs) ]] && echo "=== Installez IPFS !!" && echo "https://docs.ipfs.io/install/command-line/#official-distributions" && exit 1

# MAIN # SI AUCUNE CLEF DE STATION...
if [[ ! -f ~/.zen/game/players/.current/secret.dunikey ]];
then

# Check requirements
echo "Astroport.ONE installateur pour distributions DEBIAN et dérivées : LinuxMint (https://www.linuxmint.com/) ou XBIAN (https://xbian.org) recommandées"
echo "Appuyez sur ENTRER pour commencer."; read TEST;  [[ "$TEST" != "" ]] && echo "SORTIE" && exit 0 ## Ajouter confirmation à chaque nouvelle étape (+explications)
echo ; echo "Mise à jour des dépots de votre distribution..."
sudo apt-get update

[[ "$USER" != "xbian" ]] &&\
    for i in x11-utils xclip zenity handbrake*; do\
        [ $(dpkg-query -W -f='${Status}' $i 2>/dev/null | grep -c "ok installed") -eq 0 ] &&\
            echo ">>> Installation $i <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<";\
            sudo apt install -y $i;
    done

for i in git fail2ban npm netcat-traditional inotify-tools curl net-tools libsodium* python3-dev python3-pip python3-setuptools python3-wheel python3-dotenv mpack libssl-dev libffi-dev; do
    if [ $(dpkg-query -W -f='${Status}' $i 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        echo ">>> Installation $i <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        sudo apt install -y $i
    fi
done

for i in build-essential qrencode jq bc file gawk yt-dlp ffmpeg sqlite dnsutils v4l-utils espeak vlc mp3info musl-dev openssl* cargo detox nmap httrack html2text ssmtp imagemagick ttf-mscorefonts-installer libcurl4-openssl-dev; do
    if [ $(dpkg-query -W -f='${Status}' $i 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        echo ">>> Installation $i <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        sudo apt install -y $i
    fi
done

### Install tiddlywiki node.js
sudo npm install -g tiddlywiki



[[ ! $(which kodi) && "$USER" != "xbian" ]] &&\
    echo ">>> Installation Kodi + Vstream = VOTRE VIDEOTHEQUE ! <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<";\
    sudo apt-get install kodi -y;\
    ${MY_PATH}/.install/kodi_uqload_downloader.sh

# echo "## INSTALLATION AstroGEEK OpenCV = 'Intelligence Amie' "
# sudo apt-get install python3-opencv -y

## Correct PDF restrictions for imagemagick
echo "# Correction des droits export PDF imagemagick"
if [[ $(cat /etc/ImageMagick-6/policy.xml | grep PDF) ]]; then
    cat /etc/ImageMagick-6/policy.xml | grep -Ev PDF > /tmp/policy.xml
    sudo cp /tmp/policy.xml /etc/ImageMagick-6/policy.xml
fi

echo "###########################"
echo "## INSTALL PYTHON CRYPTO LAYER "
echo "###########################"
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc && source ~/.bashrc; echo ">>> PATH=$PATH"
python3 -m pip install -U pip
python3 -m pip install -U setuptools wheel
python3 -m pip install -U cryptography Ed25519 base58 google duniterpy pynacl pgpy
python3 -m pip install -U nicotine-plus silkaj
python3 -m pip install -U protobuf==3.19.0


if [[ "$USER" == "pi" ]]; then ## PROPOSE QR_CODE PRINTER SUR RPI
    echo "Ambassade? Ajouter imprimante 'brother_ql'? Saisissez OUI, sinon laissez vide et tapez sur ENTRER"
    read saisie
    if [[ $saisie != "" ]]; then
        sudo apt install printer-driver-all cups -y
        sudo pip3 install brother_ql
        sudo cupsctl --remote-admin
        sudo usermod -aG lpadmin pi
        sudo usermod -a -G tty pi
        sudo usermod -a -G lp pi

    fi
fi

# python3 -m pip install -U silkaj
## python -> python3 link
sudo ln -f -s  /usr/bin/python3 /usr/bin/python


########################################################################
echo "=== Clonage git CODE 'astrXbian' + 'Astroport.ONE' depuis https://git.p2p.legal"
mkdir -p ~/.zen
cd ~/.zen
git clone https://git.p2p.legal/axiom-team/astrXbian.git
git clone https://git.p2p.legal/qo-op/Astroport.ONE.git
# TODO INSTALL FROM IPFS / IPNS


## Scripts pour systemd ou InitV (xbian)
echo "=== Astroport SYSTEM IPFS"
~/.zen/astrXbian/.install/ipfs_alone.sh

########################################################################
echo "=== IMPORT configuration ASTROPORT dans ~/.kodi"
cp -Rf ~/.zen/astrXbian/.install/.kodi ~/

########################################################################
echo "=== Configuration jaklis: Centre de communication CESIUM+ GCHANGE+"
cd $MY_PATH/toos/jaklis
./setup.sh

########################################################################
echo "=== Sécurisation DEFCON SUDOERS FAIL2BAN"
## XBIAN fail2ban ERROR correction ##
#[....] Starting authentication failure monitor: fail2ban No file(s) found for glob /var/log/auth.log
[[ "$USER" == "xbian" ]] && sudo sed -i "s/auth.log/faillog/g" /etc/fail2ban/paths-common.conf
# NODE activates fail2ban IN zen/ipfs_SWARM_refresh.sh

### MODIFIYING /etc/sudoers ###
[[ "$USER" == "xbian" ]] && echo "xbian ALL=(ALL) NOPASSWD:ALL" | (sudo su -c 'EDITOR="tee" visudo -f /etc/sudoers.d/astroport')

# PERSONNAL DEFCON LEVEL
# cp ~/.zen/astrXbian/DEFCON ~/.zen/

if [[ "$USER" == "xbian" ]]
then
    echo "enabling ipfs initV service autostart"
    cd /etc/rc2.d && sudo ln -s ../init.d/ipfs S02ipfs
    cd /etc/rc3.d && sudo ln -s ../init.d/ipfs S02ipfs
    cd /etc/rc4.d && sudo ln -s ../init.d/ipfs S02ipfs
    cd /etc/rc5.d && sudo ln -s ../init.d/ipfs S02ipfs

    cd /etc/rc0.d && sudo ln -s ../init.d/ipfs K01ipfs
    cd /etc/rc1.d && sudo ln -s ../init.d/ipfs K01ipfs
    cd /etc/rc6.d && sudo ln -s ../init.d/ipfs K01ipfs

    # Disable xbian-config auto launch
    echo 0 > ~/.xbian-config-start

fi

########################################################################
# CREATE ~/astroport FILESYSTEM GATE
mkdir -p ~/astroport/film
mkdir -p ~/astroport/serie
mkdir -p ~/astroport/anime
echo '${TYPE};${MEDIAID};${YEAR};${TITLE};${SAISON};${GENRES};_IPNSKEY_;${RES};/ipfs/_IPFSREPFILEID_/$URLENCODE_FILE_NAME' > ~/astroport/ajouter_video.modele.txt


#######################################################################

echo "## INSTALL open_with_linux.py ##
## https://darktrojan.github.io/openwith/webextension.html"
~/.zen/astrXbian/open_with_linux.py install

echo ">>> INFO : Ajoutez l'extension 'OpenWith' à votre navigateur !!
# https://addons.mozilla.org/firefox/addon/open-with/
# https://chrome.google.com/webstore/detail/open-with/cogjlncmljjnjpbgppagklanlcbchlno"

if [[ "$USER" != "xbian" ]]
then
    ## Desktop install
    echo "INITIALISATION Astroport"
    echo "Appuyez sur la touche ENTREE pour démarrer le mode Aventure"
    echo "sinon interrompez ici l'installation, et activez votre Ambassade  ~/.zen/Astroport.ONE/start.sh"
    read
    # ~/.zen/Astroport.ONE/adventure.sh
 #
    ~/.zen/astrXbian/ISOconfig.sh
else
    ## Rpi Xbian install.
    cat /etc/rc.local | grep -Ev "exit 0" > /tmp/new.rc.local ## REMOVE "exit 0"
    # PREPARE NEXT BOOT - Network config - NEXTBOOT - ISOConfig - NEXTBOOT - OK
    echo "su - xbian -c '~/.zen/astrXbian/FirstBOOT.sh'" >> /tmp/new.rc.local
    echo "exit 0" >> /tmp/new.rc.local
    sudo cp -f /tmp/new.rc.local /etc/rc.local

    echo "STOP!! Redémarrer Xbian pour continuer la configuration de votre station Astroport/KODI"
    echo "Faites une ISO : sudo xbian-config"
    exit 0
fi

###########################################
# ACTIVATE IPFS OPTIONS: #swarm0 INIT
###########################################
### IMPORTANT !!!!!!! IMPORTANT !!!!!!
###########################################
# DHT PUBSUB mode
ipfs config Pubsub.Router gossipsub
# MAXSTORAGE = 1/2 available
availableDiskSize=$(df -P ~/ | awk 'NR>1{sum+=$4}END{print sum}')
diskSize="$((availableDiskSize / 2))"
ipfs config Datastore.StorageMax $diskSize
## Activate Rapid "ipfs p2p"
ipfs config --json Experimental.Libp2pStreamMounting true
ipfs config --json Experimental.P2pHttpProxy true
ipfs config --json Swarm.ConnMgr.LowWater 0
ipfs config --json Swarm.ConnMgr.HighWater 0
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["http://127.0.0.1:8080", "http://astroport", "https://astroport.com", "https://qo-op.com", "https://tube.copylaradio.com" ]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "GET", "POST"]'
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Credentials '["true"]'

ipfs config Addresses.API "/ip4/0.0.0.0/tcp/5001"
ipfs config Addresses.Gateway "/ip4/0.0.0.0/tcp/8080"

######### CLEAN DEFAULT BOOTSTRAP TO STAY INVISIBLE ###########
ipfs bootstrap rm --all
###########################################
# BOOTSTRAP NODES ARE ADDED LATER
###########################################
# AVOID CONFLICT WITH KODI ./.install/.kodi/userdata/guisettings.xml
ipfs config Addresses.Gateway "/ip4/0.0.0.0/tcp/8080"

[[ "$USER" != "xbian" ]] && sudo systemctl restart ipfs

########################################################################
# SUDO permissions
########################################################################
## USED FOR fail2ban-client (DEFCON)
echo "$USER ALL=(ALL) NOPASSWD:/usr/bin/fail2ban-client" | (sudo su -c 'EDITOR="tee" visudo -f /etc/sudoers.d/fail2ban-client')
## USED FOR RAMDISK (video live streaming)
echo "$USER ALL=(ALL) NOPASSWD:/bin/mount" | (sudo su -c 'EDITOR="tee" visudo -f /etc/sudoers.d/mount')
echo "$USER ALL=(ALL) NOPASSWD:/bin/umount" | (sudo su -c 'EDITOR="tee" visudo -f /etc/sudoers.d/umount')
## USED FOR SYSTEM UPGRADE
echo "$USER ALL=(ALL) NOPASSWD:/usr/bin/apt-get" | (sudo su -c 'EDITOR="tee" visudo -f /etc/sudoers.d/apt-get')
echo "$USER ALL=(ALL) NOPASSWD:/usr/bin/apt" | (sudo su -c 'EDITOR="tee" visudo -f /etc/sudoers.d/apt')
## USED FOR "systemctl restart ipfs"
echo "$USER ALL=(ALL) NOPASSWD:/bin/systemctl" | (sudo su -c 'EDITOR="tee" visudo -f /etc/sudoers.d/systemctl')

## brother_ql_print
echo "$USER ALL=(ALL) NOPASSWD:/usr/local/bin/brother_ql_print" | (sudo su -c 'EDITOR="tee" visudo -f /etc/sudoers.d/brother_ql_print')


# MAIN # -f ~/.zen/secret.june (ISOConfig déjà lancé) ##
else

echo "Installation existante !!
========================
Astroport/KODI (Gchange)
========================
Connectez-vous sur https://gchange.fr avec vos identifiants

$(cat ~/.zen/game/players/.current/secret.june)

https://astroport.com
"

# MAIN #
fi
}
