#/bin/bash
# Preamble 
RED="\e[31m"
BLUE="\e[94m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"
TITLE="\e[4m"
TICK="[$GREEN+$ENDCOLOR] "
TICK_MOVE="[$GREEN~>$ENDCOLOR] "
TICK_BACKUP="[$GREEN<~~$ENDCOLOR] "
TICK_INPUT="[$YELLOW!$ENDCOLOR] "
TAB="--"
CONFIG_PATH=~/.config/autodeploy
HOST_CONFIG_PATH=~/.config/autodeploy/$(hostname)_config/
BACKUP_DIR=$HOST_CONFIG_PATH"backup/"
FILE_LOG=$HOST_CONFIG_PATH$(hostname)_files.log
remote_repo="http://iroh.int/Graham/ConfigFiles.git"
user=$(hostname)
usage() { echo "Usage: $0 [-s <45|90>] [-p <string>]" 1>&2; exit 1; } # Copy and pasted, need to update

echo $GREEN"-------------------------------------------------------------------"$ENDCOLOR
echo $GREEN"*** $BLUE AutoDeploy - A pure bash configuration management tool$GREEN ***"$ENDCOLOR
echo $GREEN"-------------------------------------------------------------------"$ENDCOLOR

echo $TICK$GREEN"Autodeploy config path is located at $BLUE$CONFIG_PATH"
echo $GREEN"-------------------------------------------------------------------"$ENDCOLOR
first_setup(){
    echo $TICK$GREEN"Running first time setup"$ENDCOLOR
    echo $TICK$GREEN"Creating Configuration Files in $BLUE~/.config/autodeploy/ "$ENDCOLOR
    mkdir -p ~/.config/autodeploy/ 

    echo $TICK$GREEN"Welcome to first time setup"$ENDCOLOR
    echo $TICK$GREEN"Enter your remote git repository URL"$ENDCOLOR
    echo $TICK$GREEN"For example: $BLUE"https://github.com/grahamhelton/DotFiles""$ENDCOLOR

    echo -n $TICK_INPUT$GREEN"Enter Remote Repository URL: $YELLOW"
    read remote_repo
    echo $TICK$GREEN"Setting Remote Repository to: $YELLOW$remote_repo "

    #. ~/.config/autodeploy/global_config.conf 
    cd $CONFIG_PATH
    git init > /dev/null 2>&1; 
    git remote add origin $remote_repo > /dev/null 2>&1; 
    git checkout -b main> /dev/null 2>&1; 

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
    echo $TICK$GREEN"Running apt update and apt upgrade..."$ENDCOLOR ; sudo apt update > /dev/null 2>&1 && sudo apt upgrade -y  > /dev/null 2>&1
    echo $TICK$GREEN"Installing applications from $CONFIG_PATH/global_applications.conf"$ENDCOLOR && temp_output=$(xargs sudo apt install -y < $CONFIG_PATH/global_applications.conf)
    echo $temp_output
}
list_configs(){
    echo -n $BLUE
    ls $CONFIG_PATH | grep "_config$"
}


stage_files(){
    git -C $CONFIG_PATH pull origin main --allow-unrelated-histories
    # Grab files from around the system and move them to $CONFIG_PATH
    echo $TICK$GREEN"Staging Files!"$ENDCOLOR
    if test -d $HOST_CONFIG_PATH;then
        echo $TICK$GREEN"Config file already found in $BLUE$CONFIG_PATH/$(hostname)_config"$ENDCOLOR
    else
        mkdir -p $HOST_CONFIG_PATH
        echo $TICK$GREEN"Created config file in $BLUE$CONFIG_PATH/$(hostname)_config"$ENDCOLOR
    fi
    # Copy each line in $CONFIG_PATH/global_dotFiles.conf to $HOST_CONFIG_PATH
    cd $HOME
    while read line; do
        cp -rvf --parents $line $HOST_CONFIG_PATH | grep "^'" | awk '{print $1}' | sed "s/'//g" | sed 's@'"$HOME"'@$HOME@' >> $HOST_CONFIG_PATH/$(hostname)_files.log
        # Going to need to add sorting somewhere in here because this log will keep growing
        echo $TICK_MOVE$GREEN"Copied $BLUE$line$GREEN to $BLUE$HOST_CONFIG_PATH"$ENDCOLOR
    done < $CONFIG_PATH/global_dotFiles.conf
    cd $CONFIG_PATH 
    echo $TICK$GREEN"Configuration files saved to $BLUE$HOST_CONFIG_PATH$GREEN, ready to push!"$ENDCOLOR

}


check_git(){
    # Check if global_dotFiles.conf is in the current repo
    if test -f "$CONFIG_PATH/global_dotFiles.conf";then
        echo $RED"-------DEBUG--------"
        echo $TICK$GREEN"Config file already found"$ENDCOLOR
    else
        echo $RED"-------DEBUG--------"
        echo $TICK$GREEN"Config file not found, generating base configuration..."$ENDCOLOR
        echo "config_name=$(hostname)" > $CONFIG_PATH/global_config.conf 
        # Add $remote_repo to global_config 
        echo "$remote_repo" >> $CONFIG_PATH/global_config.conf 
        # Add default applications to global_applications
        echo "curl\nneovim\nzsh" >> $CONFIG_PATH/global_applications.conf 
        # Add default dot files to global_dotFiles.conf 
        echo ".tmux.conf" >> $CONFIG_PATH/global_dotFiles.conf 

        
    fi
}

pull_files(){
    # Push files to $remote_repo
    cd $CONFIG_PATH
    echo $TICK$GREEN"Pulling Files"$ENDCOLOR
    git -C $CONFIG_PATH pull origin main --allow-unrelated-histories
    check_git
    # This has an error during first time setup. If global files are already in the $CONFIG_PATH, the pull will fail because they'll be overwritten

}

remote_commit(){
    # Push files to $remote_repo
    cd $CONFIG_PATH
    echo $TICK$GREEN"Adding Files"$ENDCOLOR
    git add . 
    echo $TICK$GREEN"Commiting"$ENDCOLOR
    git commit -m "Autodeploy from $(hostname) on $(date)"
    echo $TICK$GREEN"Pushing"$ENDCOLOR
    git push -u origin main 

}

backup_old(){
    # Backs up all the files that will be overwritten by autodeploy
    mkdir -p $HOST_CONFIG_PATH"backup"
    while read line; do
        echo $TICK_BACKUP$GREEN"Backing up $BLUE$line$GREEN to $BLUE$BACKUP_DIR"
        cp -rf $HOME/$line $BACKUP_DIR > /dev/null 2>&1; 
    done < $CONFIG_PATH/global_dotFiles.conf # Fix
}

distribute_files(){
    # Places files defined in global_dotFiles in correct folders
    backup_old
    cd $HOST_CONFIG_PATH
    for f in .[!.]* *; do
        echo "Copying $f to $HOME"
        cp -rf  $f $HOME 
        # Going to need to figure out a way to move all files except for the backup folder
    done
        #echo $TICK_MOVE$GREEN"Copied $BLUE$line$GREEN to $BLUE$BACKUP_DIR"$ENDCOLOR
}

main(){
    # Check if this is the first time autodeploy is being ran
    if  !(test -d $CONFIG_PATH);then
        first_setup
    fi

    # Process command line arugments
    while getopts "d c p s f a b l" o; do
        case "${o}" in
            # Pull config
            l)
                c=${OPTARG}
                echo $TICK$GREEN$TITLE"Listing available configuration files"$ENDCOLOR
                list_configs 
                ;;
            c)
                c=${OPTARG}
                echo $TICK$BLUE"Commit config to $remote_repo"$ENDCOLOR
                remote_commit
                ;;
            p)
                c=${OPTARG}
                echo $TICK$BLUE"Pulling config from $remote_repo"$ENDCOLOR
                pull_files 
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
            b)
                b=${OPTARG}
                echo $TICK$BLUE"Backing up current dotfiles to $BACKUP_DIR"$ENDCOLOR
                backup_old 
                ;;
            d)
                d=${OPTARG}
                echo $TICK$BLUE"Distributing files to correct locations"$ENDCOLOR
                distribute_files 
                ;;
            *)
                usage
                ;;
        esac
    done
}

# Run main funciton and pass it command line arguments
main "$@"

