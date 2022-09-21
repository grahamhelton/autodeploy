#/bin/bash
# Pretext
RED="\e[31m"
BLUE="\e[94m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"
TICK="[$GREEN+$ENDCOLOR] "
CONFIG_PATH=~/.config/autodeploy

pre_check(){
    # Sets default variables, creates config folder, and uses pre-existing config file if it exists
    echo  $TICK$BLUE"Running Pre-flight check"$ENDCOLOR
    user=$(hostname)
    mkdir -p ~/.config/autodeploy/ 
    if test -f $CONFIG_PATH/"$user"_config.txt ;then
        echo "File exists"
        . ~/.config/autodeploy/"$user"_config.txt 
    else
        echo "config_name=$(hostname)" > ~/.config/autodeploy/config.txt 
        echo "remote_repo="https://github.com/grahamhelton"" >> ~/.config/autodeploy/config.txt 
        . ~/.config/autodeploy/config.txt 
    fi
    echo $config_name
    echo $remote_repo 

}

get_posture(){
# This function is used to determine what kind of system the script is being deployed on. It will check for the following items:
# 1. Internet connectivity 
# 2. Checks for dependencies 
# 3. 

    if  ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo $TICK"Internet Connectivity Detected"$ENDCOLOR
        internet=True
    else
        echo $RED"Internet Connectivity Not Detected"$ENDCOLOR
        internet=False
    fi

    if apt help install -h > /dev/null 2>&1; then
        echo $TICK"APT is installed"$ENDCOLOR
        apt=True
    else
        echo $RED"APT is NOT installed"$ENDCOLOR
        apt=False
    fi 

}

install_apt(){
    echo $TICK$GREEN"Please input SUDO password"$ENDCOLOR
    echo $TICK$GREEN"Installing from $CONFIG_PATH/install.txt"$ENDCOLOR && xargs sudo apt install -y <$CONFIG_PATH/install.txt | grep "Unpacking" 
}
pre_check
install_apt
