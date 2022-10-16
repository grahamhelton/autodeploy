#/bin/bash

# Preamble 
BOLD="\e[1m"
RED="\e[31m"
BLUE="\e[94m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"
TITLE="\e[4m"
TICK="[$GREEN+$ENDCOLOR] "
TICK_MOVE="[$GREEN~>$ENDCOLOR]"
TICK_BACKUP="[$GREEN<~~$ENDCOLOR] "
TICK_INPUT="[$YELLOW!$ENDCOLOR] "
TICK_ERROR="[$RED!$ENDCOLOR] "
TAB="--"
CONFIG_PATH=~/.config/autodeploy
HOST_CONFIG_PATH=~/.config/autodeploy/$(hostname)_config/
BACKUP_DIR=$HOST_CONFIG_PATH"backup/"
FILE_LOG=$HOST_CONFIG_PATH$(hostname)_files.log
remote_repo="http://iroh.int/Graham/ConfigFiles.git"
user=$(hostname)
selected_config=$HOST_CONFIG_PATH

#
# Prints usage information
#

usage() { 

echo -e $GREEN"-------------------------------------------------------------------"$ENDCOLOR
echo -e $GREEN"*** $BLUE AutoDeploy - A pure bash configuration management tool$GREEN ***"$ENDCOLOR
echo -e $GREEN"-------------------------------------------------------------------"$ENDCOLOR
echo -e "
$BLUE Usage:
  autodeploy -h 
  autodeploy -e [apps|config|files]

$BLUE Options:
 $GREEN -h$BLUE        Show this [h]elp screen.
  $GREEN-l$BLUE        [L]ist available configuration files 
  $GREEN-p$BLUE        [P]ush files to remote repository
  $GREEN-g$BLUE        [G]et files from the remote repository
  $GREEN-c$BLUE        [C]ollect configuration files on the local file system and prepare them for a remote push (-p)
  $GREEN-f$BLUE        Re-run [f]irst time setup 
  $GREEN-a$BLUE        [I]nstalls applications found in autodeploy_apps.conf
  $GREEN-b$BLUE        [B]acks up files defined in autodeploy_files.conf
  $GREEN-m$BLUE        [M]oves dotfiles defined in autodeploy_files.conf to their correct locations on the local machine 
  $GREEN-e <File> $BLUE[E]dits autodeploy's configuration files
  
        "
        exit 0

} 

clear


first_setup(){
# This function is run if the the directory ~/.config/autodeploy is not detected
# It handles creating the configuration directory, establishing the git repository for configuration files, and initializing
# the ~/.config/autodeploy/ as a git repository

    echo -e $TICK$GREEN"Running first time setup"$ENDCOLOR
    echo -e $TICK$GREEN"Creating Configuration Files in $BLUE~/.config/autodeploy/ "$ENDCOLOR
    mkdir -p ~/.config/autodeploy/ 

    echo -e $TICK$GREEN"Enter your remote git repository URL"$ENDCOLOR
    echo -e $TICK$GREEN"For example: $BLUE"https://github.com/grahamhelton/DotFiles""$ENDCOLOR

    echo -e -n $TICK_INPUT$GREEN"Enter Remote Repository URL: $YELLOW"
    read remote_repo 
    echo -e $NOCOLOR$TICK$GREEN"Setting Remote Repository to: $YELLOW$remote_repo "

    #. ~/.config/autodeploy/autodeploy_config.conf 
    cd $CONFIG_PATH
    git init > /dev/null 2>&1; 
    git remote add origin $remote_repo > /dev/null 2>&1; 
    git checkout -b main > /dev/null 2>&1; 

    echo -e $NOCOLOR$TICK$GREEN"First time setup complete, use$BLUE autodeploy -f $GREEN to rerun first time setup"$NOCOLOR
}

get_posture(){
# This function is used to determine if the current system has the required dependencies to run AutoDeploy

    # Change to wget -q --spider $remote_repo then check for return code with $?
    if  ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo -e $TICK"Internet Connectivity Detected"$ENDCOLOR
        internet=True
    else
        echo -e $RED"Internet Connectivity Not Detected"$ENDCOLOR
        internet=false
    fi

    if apt help install -h > /dev/null 2>&1; then
        echo -e $TICK"APT is installed"$ENDCOLOR
        apt=true
    else
        echo -e $RED"APT is NOT installed"$ENDCOLOR
        apt=false
    fi 

}

install_apps(){
# This function is responsible for installing any applications (using apt) defined in ~/.config/autodeploy/autodeploy_apps.conf
    echo -e $TICK$BLUE"Please input SUDO password"$ENDCOLOR

    # Runs sudo apt update and upgrade
    echo -e $TICK$GREEN"Running apt update and apt upgrade..."$ENDCOLOR ; sudo apt update > /dev/null 2>&1 && sudo apt upgrade -y  > /dev/null 2>&1
    echo -e $TICK$GREEN"Installing applications from $BLUE$CONFIG_PATH/autodeploy_apps.conf"$ENDCOLOR 

    # Install each application listed in $CONFIG_PATH/autodeploy_apps 
    grep -v '^#' $CONFIG_PATH/autodeploy_apps.conf | while read -r line; do
        echo -e $TICK$GREEN"Installing $BLUE$line"$ENDCOLOR 
        sudo apt install $line -y > /dev/null 2>&1 #| grep -A 1 "NEW packages" | grep -v "NEW packages"
    done
    echo -e $TICK$GREEN"Applications installed."$ENDCOLOR 
}

list_configs(){
    # Lists the config files found in ~/.config/autodeploy/*.conf
    echo -e $TICK$GREEN"Listing configs found in $BLUE$CONFIG_PATH"$ENDCOLOR
    echo -e -n $BLUE
    ls $CONFIG_PATH | grep "_config$"
}


collect_files(){
    echo -e $TICK$GREEN"Collecting files from around the system"$ENDCOLOR
    # Pulls files from the remote repository and checks to see if the configuration path already exists
    git -C $CONFIG_PATH pull origin main --allow-unrelated-histories > /dev/null 2>&1

    # Check if the configuration path already exists
    echo -e $TICK$GREEN"Moving files"$ENDCOLOR
    if test -d $HOST_CONFIG_PATH;then
        echo -e $TICK$GREEN"Creating files in $BLUE$CONFIG_PATH/$(hostname)_config"$ENDCOLOR
    else
        mkdir -p $HOST_CONFIG_PATH
        echo -e $TICK$GREEN"Creating files in $BLUE$CONFIG_PATH/$(hostname)_config"$ENDCOLOR
    fi

    # Copy each line in $CONFIG_PATH/autodeploy_files.conf to $HOST_CONFIG_PATH
    cd $HOME
    while read line; do
        # Copies all files listed in $HOST_CONFIG_PATH/autodeploy_files.conf recursively, verbosely, and forcefully to the staging area. Filters out un-needed lines, and logs them to $hostname_files.log
        cp -rvf --parents $line $HOST_CONFIG_PATH | grep "^'" | awk '{print $1}' | sed "s/'//g" | sed 's@'"$HOME"'@$HOME@' 2>/dev/null
        # Going to need to add sorting somewhere in here because this log will keep growing
        echo -e $TICK_MOVE$GREEN" Copied $BLUE$line$GREEN to $BLUE$HOST_CONFIG_PATH"$ENDCOLOR
    done < $CONFIG_PATH/autodeploy_files.conf | grep -v "^#"

    cd $CONFIG_PATH 

    echo -e $TICK$GREEN"Configuration files saved to $BLUE$HOST_CONFIG_PATH$GREEN. Files can be pushed to $BLUE$remote_repo$GREEN with$BLUE autodeploy -p$GREEN"$ENDCOLOR

}

edit_files() {
    # Edit configuration files in $CONFIG_PATH
    if [ $OPTARG = "apps" ];then
        "${EDITOR:-vi}" $CONFIG_PATH/autodeploy_apps.conf
    elif [ $OPTARG = "config" ];then
        "${EDITOR:-vi}" $CONFIG_PATH/autodeploy_config.conf
    elif [ $OPTARG = "files" ];then
        "${EDITOR:-vi}" $CONFIG_PATH/autodeploy_files.conf
    else
        usage
    fi
}
move_dev(){
    if [ -z "$2" ];then
        echo -e $TICK$GREEN"No arguments supplied, using configuration in $BLUE$HOST_CONFIG_PATH"$ENDCOLOR
        collect_files
    else
        select_config "$@"
    fi


}
select_config(){
        echo -e $TICK_ERROR$YELLOW"Please specify the name of the config file you wish to use"$ENDCOLOR
        selected_config=$2
        if test -d "$CONFIG_PATH/$selected_config";then
            echo -e $TICK$GREEN"$selected_config selected"
            distribute_files
        else
            list_configs
        fi

}

check_git(){
    # Check if the autodeploy configuration files are are in the current repo. If not, creates them
    if ! test -f "$CONFIG_PATH/autodeploy_files.conf";then
        echo -e $TICK$GREEN"Config file not found, generating base configuration..."$ENDCOLOR
        echo -e "config_name=$(hostname)" > $CONFIG_PATH/autodeploy_config.conf 

        # Add $remote_repo to autodeploy_config 
        echo -e "$remote_repo" >> $CONFIG_PATH/autodeploy_config.conf 

        # Add default applications to autodeploy_apps
        echo -e "curl\nneovim\nzsh" > $CONFIG_PATH/autodeploy_apps.conf 

        # Add default dot files to autodeploy_files.conf 
        echo -e ".tmux.conf" > $CONFIG_PATH/autodeploy_files.conf 
    fi
}

get_files(){
    # pulls files from origin 
    cd $CONFIG_PATH
    git -C $CONFIG_PATH pull origin main --allow-unrelated-histories  > /dev/null 2>&1; # Figure out how to check if repo exists
    check_git
    echo -e $TICK$GREEN"Pull complete"$ENDCOLOR

}

remote_push(){
    # Commit and push files to $remote_repo
    cd $CONFIG_PATH
    echo -e $TICK$GREEN"Adding Files"$ENDCOLOR
    git add . > /dev/null 2>&1
    echo -e $TICK$GREEN"Commiting"$ENDCOLOR
    git commit -m "Autodeploy from $(hostname) on $(date)" > /dev/null 2>&1
    echo -e $TICK$GREEN"Pushing"$ENDCOLOR
    git push -u origin main > /dev/null 2>&1

}

backup_old(){
    # Backs up all the files that will be overwritten by autodeploy
    mkdir -p $HOST_CONFIG_PATH"backup"
    while read line; do
        echo -e $TICK_BACKUP$GREEN"Backing up $BLUE$line$GREEN to $BLUE$BACKUP_DIR"
        cp -rf $HOME/$line $BACKUP_DIR > /dev/null 2>&1; 
    done < $CONFIG_PATH/autodeploy_files.conf # Fix
}

new_client(){
    # Pulles files from origin, 
    get_files
    collect_files
    install_apps
    
}

distribute_files(){
    # Places files defined in autodeploy_file.conf to the correct location in the file system 
    backup_old
    cd $CONFIG_PATH/$selected_config

    # Need an odd for loop syntax because zsh handles file globs differently than bash 
    for f in .[!.]* *; do
        echo -e $TICK_MOVE$GREEN"Copying $BLUE$f$GREEN to $BLUE$HOME"
        cp -rf  $f $HOME # Going to need to figure out a way to move all files except for the backup folder
    done
}

main(){
    # Check if this is the first time autodeploy is being ran
    if  !(test -d $CONFIG_PATH);then
        first_setup
    fi

    if [ $# -eq 0 ]; then
        usage
    fi

    # Process command line arugments
    while getopts "d n m c p s f a b l :e:" o; do
        case "${o}" in
            l)
                c=${OPTARG}
                echo -e $TICK$GREEN$TITLE"Listing available configuration files"$ENDCOLOR
                list_configs 
                ;;
            e)
                e=${OPTARG}
                echo -e $TICK$GREEN$TITLE"Editing Files"$ENDCOLOR
                edit_files 
                ;;
            p)
                c=${OPTARG}
                echo -e $TICK$BLUE"Push config to $remote_repo"$ENDCOLOR
                remote_push
                ;;
            g)
                g=${OPTARG}
                echo -e $TICK$GREEN"Getting config from $BLUE$remote_repo"$ENDCOLOR
                get_files 
                ;;
            c)
                c=${OPTARG}
                echo -e $TICK$GREEN"Collecting config files and storing them in $BLUE$HOST_CONFIG_PATH"$ENDCOLOR
                collect_files
                ;;
            f)
                f=${OPTARG}
                echo -e $TICK$BLUE"Re-running first time setup"$ENDCOLOR

                # Add this feature
                ;;
            a)
                a=${OPTARG}
                echo -e $TICK$BLUE"Installing applications"$ENDCOLOR
                install_apps 
                ;;
            b)
                b=${OPTARG}
                echo -e $TICK$BLUE"Backing up current dotfiles to $BACKUP_DIR"$ENDCOLOR
                backup_old 
                ;;
            m)
                m=${OPTARG}
                echo -e $BOLD$BLUE"Move files to correct locations"$ENDCOLOR
                echo -e $GREEN$BOLD"---------------------------------------"$ENDCOLOR
                distribute_files 
                ;;
            n)
                n=${OPTARG}
                echo -e $BOLD$BLUE"Running full new client install"$ENDCOLOR
                echo -e $GREEN$BOLD"---------------------------------------"$ENDCOLOR
                new_client 
                ;;
            d)
                d=${OPTARG}
                echo -e $BOLD$BLUE"Running move dev"$ENDCOLOR
                echo -e $OPTARG
                echo -e $GREEN$BOLD"---------------------------------------"$ENDCOLOR
                move_dev "$@"
                ;;
            ?)
                usage
                ;;
        esac
    done
}

# Run main funciton and pass it command line arguments
main "$@"

