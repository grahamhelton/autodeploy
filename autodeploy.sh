#/bin/bash
# Preamble 
RED="\e[31m"
BLUE="\e[94m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"
TICK="[$GREEN+$ENDCOLOR] "
TICK_MOVE="[$GREEN~>$ENDCOLOR] "
TAB="--"
CONFIG_PATH=~/.config/autodeploy
HOST_CONFIG_PATH=~/.config/autodeploy/$(hostname)_config/
user=$(hostname)
usage() { echo "Usage: $0 [-s <45|90>] [-p <string>]" 1>&2; exit 1; } # Copy and pasted, need to update

clear
echo $GREEN"-------------------------------------------------------------------"$ENDCOLOR
echo $GREEN"*** $BLUE AutoDeploy - A pure bash configuration management tool$GREEN ***"$ENDCOLOR
echo $GREEN"-------------------------------------------------------------------"$ENDCOLOR
sleep 1
first_setup(){
    echo $TICK$GREEN"Running first time setup"$ENDCOLOR
    echo $TICK$GREEN"Creating Configuration Files in $BLUE~/.config/autodeploy/ "$ENDCOLOR
    mkdir -p ~/.config/autodeploy/ 
    echo $TICK$GREEN"Add your git repository by editing $BLUE~/.config/autodeploy/global_config.conf"$ENDCOLOR # Change this to accept user input
    echo "config_name=$(hostname)" > $CONFIG_PATH/global_config.conf 
    echo "remote_repo="http://iroh.int/Graham/ConfigFiles.git"" >> $CONFIG_PATH/global_config.conf 
    . ~/.config/autodeploy/global_config.conf 
    cd $CONFIG_PATH
    git init > /dev/null 2>&1; 
    git remote add origin $remote_repo > /dev/null 2>&1; 
    git checkout -b main> /dev/null 2>&1; 
    
    echo "config_name=$(hostname)" > $CONFIG_PATH/global_config.conf 
    echo "remote_repo="http://iroh.int:80/Graham/ConfigFiles.git"" >> $CONFIG_PATH/global_config.conf 
    echo "neovim\nmupdf" >> $CONFIG_PATH/global_applications.conf 
    echo "~/.tmux.conf" >> $CONFIG_PATH/global_dotFiles.conf 
    . $CONFIG_PATH/global_config.conf 

}



# Handle command line options. Not sure why this isn't working inside a function

get_posture(){
# This function is used to determine what kind of system the script is being deployed on. It will check for the following items:
# 1. Internet connectivity 
# 2. Checks for dependencies 
# 3. 
    # Change to wget -q --spider $remote_repo then check for return code with $?
    if  ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo $TICK"Internet Connectivity Detected"$ENDCOLOR
        internet=True
    else
        echo $RED"Internet Connectivity Not Detected"$ENDCOLOR
        internet=false
    fi

    if apt help install -h > /dev/null 2>&1; then
        echo $TICK"APT is installed"$ENDCOLOR
        apt=true
    else
        echo $RED"APT is NOT installed"$ENDCOLOR
        apt=false
    fi 

}

install_apt(){
    echo $TICK$BLUE"Please input SUDO password"$ENDCOLOR
    echo $TICK$GREEN"Running apt update and apt upgrade..."$ENDCOLOR ; sudo apt update && sudo apt upgrade -y  | grep "newly installed"
    echo $TICK$GREEN"Installing applications from $CONFIG_PATH/global_applications.conf"$ENDCOLOR && xargs sudo apt install -y <$CONFIG_PATH/global_applications.conf | grep "Setting up"
}

stage_files(){
    git -C $CONFIG_PATH pull
    # Grab files from around the system and move them to $CONFIG_PATH
    echo $TICK$GREEN"Staging Files!"$ENDCOLOR
    if test -d $HOST_CONFIG_PATH;then
        echo $TAB$TICK$GREEN"Config file already found in $BLUE$CONFIG_PATH/$(hostname)_config"$ENDCOLOR
    else
        mkdir -p $HOST_CONFIG_PATH
        echo $TICK$GREEN"Created config file in $BLUE$CONFIG_PATH/$(hostname)_config"$ENDCOLOR
    fi
    # Copy each line in $CONFIG_PATH/global_dotFiles.conf to $HOST_CONFIG_PATH
    while read line; do
        cp -rf $HOME/$line $HOST_CONFIG_PATH 
        echo $TICK_MOVE$GREEN"Copied $BLUE$line$GREEN to $BLUE$HOST_CONFIG_PATH"$ENDCOLOR
    done < $CONFIG_PATH/global_dotFiles.conf
    echo $TICK$GREEN"Configuration files saved to $BLUE$HOST_CONFIG_PATH$GREEN, ready to push!"$ENDCOLOR

}

remote_push(){
    # Push files to $remote_repo
    cd $CONFIG_PATH
    echo $TICK$GREEN"Adding Files"$ENDCOLOR
    git add . 
    echo $TICK$GREEN"Commiting"$ENDCOLOR
    git commit -m "Autodeploy from $(hostname) on $(date)"
    echo $TICK$GREEN"Pushing"$ENDCOLOR
    git push -u origin main --force

}

main(){
    # Check if this is the first time autodeploy is being ran
    if  !(test -d $CONFIG_PATH);then
        first_setup
    fi

    # Process command line arugments
    while getopts "p s f a" o; do
        case "${o}" in
            # Pull config
            p)
                p=${OPTARG}
                echo $TICK$BLUE"Pushing config to $remote_repo"$ENDCOLOR
                remote_push
                ;;
            # Commit config
            s)
                s=${OPTARG}
                echo $TICK$GREEN"Staging config files to $BLUE$HOST_CONFIG_PATH"$ENDCOLOR
                stage_files
                ;;
            # Full install
            f)
                f=${OPTARG}
                echo $TICK$BLUE"Running full install"$ENDCOLOR

                ;;
            # Only install applications 
            a)
                a=${OPTARG}
                echo $TICK$BLUE"Installing applications"$ENDCOLOR
                install_apt 
                ;;
            *)
                usage
                ;;
        esac
    done
}

# Run main funciton and pass it command line arguments
main "$@"
