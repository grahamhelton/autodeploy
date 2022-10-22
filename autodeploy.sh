#! /bin/bash
# Preamble 
RED=`tput setaf 1`
BLUE=`tput setaf 4`
YELLOW=`tput setaf 3`
ENDCOLOR=`tput sgr0`
GREEN=`tput setaf 2`
#TITLE="\e[4m"
TICK="[$GREEN+$ENDCOLOR] "
TICK_MOVE="[$GREEN~>$ENDCOLOR]"
TICK_BACKUP="[$GREEN<~$ENDCOLOR] "
TICK_INPUT="[$YELLOW!$ENDCOLOR] "
TICK_ERROR="[$RED!$ENDCOLOR] "
TAB="--"
CONFIG_PATH=~/.config/autodeploy
HOST_CONFIG_PATH=~/.config/autodeploy/$(hostname)_config/
BACKUP_DIR=$HOST_CONFIG_PATH"backup/"
#FILE_LOG=$HOST_CONFIG_PATH$(hostname)_files.log
remote_repo="http://iroh.int/Graham/ConfigFiles.git"
user=$(hostname)
selected_config=$HOST_CONFIG_PATH

#
# Prints usage information
#

usage() { 

echo  "${GREEN}-------------------------------------------------------------------"$ENDCOLOR
echo  $GREEN"*** $BLUE AutoDeploy - A pure bash configuration management tool$GREEN ***"$ENDCOLOR
echo  $GREEN"-------------------------------------------------------------------"$ENDCOLOR
echo  "
$BLUE Usage:
  $GREEN autodeploy $BLUE -h 
  $GREEN autodeploy $BLUE -e [apps|config|files]
  $GREEN autodeploy $BLUE -u thinkpad_config

$BLUE Options:
  $GREEN-a$BLUE        [A]pplications found in autodeploy_apps.conf are installed
  $GREEN-b$BLUE        [B]acks up files defined in autodeploy_files.conf
  $GREEN-c$BLUE        [C]ollect configuration files on the local file system and prepare them for a remote push (-p)
  $GREEN-D$BLUE        [D]eletes your configuration files in ~/.config/autodeploy/
  $GREEN-e <File> $BLUE[E]dits autodeploy's configuration files
            -$GREEN apps:$BLUE Configure what apps are installed using apt.
            -$GREEN config:$BLUE Configure autodeploy settings. 
            -$GREEN files:$BLUE Configure what config files you want to mark for operations.
  $GREEN-f$BLUE        [F]irst time setup 
  $GREEN-g$BLUE        [G]et files from the remote repository
  $GREEN-h$BLUE        Show this [h]elp screen.
  $GREEN-l$BLUE        [L]ist available configuration files 
  $GREEN-m$BLUE        [M]oves dotfiles defined in autodeploy_files.conf to their correct locations on the local machine 
  $GREEN-p$BLUE        [P]ush files to remote repository
  $GREEN-u <file> $BLUE[U]se a different machine's configuration files 

        "$ENDCOLOR
    exit 0
} 



first_setup(){
# This function is run if the the directory ~/.config/autodeploy is not detected
# It handles creating the configuration directory, establishing the git repository for configuration files, and initializing
# the ~/.config/autodeploy/ as a git repository

    echo $TICK$GREEN"Running first time setup"$ENDCOLOR
    echo $TICK$GREEN"Creating Configuration Files in $BLUE~/.config/autodeploy/ "$ENDCOLOR
    mkdir -p ~/.config/autodeploy/ 

    echo $TICK$GREEN"Enter your remote git repository URL"$ENDCOLOR
    echo $TICK$GREEN"For example: $BLUE"https://github.com/grahamhelton/DotFiles""$ENDCOLOR

    echo -n $TICK_INPUT$GREEN"Enter Remote Repository URL: $YELLOW"
    read remote_repo 
    echo $ENDCOLOR$TICK$GREEN"Setting Remote Repository to: $YELLOW$remote_repo "$ENDCOLOR

    cd $CONFIG_PATH
    git init > /dev/null 2>&1; 
    git remote add origin $remote_repo > /dev/null 2>&1; 
    git checkout -b main > /dev/null 2>&1; 

    echo $ENDCOLOR$TICK$GREEN"First time setup complete, use$BLUE autodeploy -f $GREEN to rerun first time setup"$ENDCOLOR
}

get_posture(){
# This function is used to determine if the current system has the required dependencies to run AutoDeploy

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

install_apps(){
# This function is responsible for installing any applications (using apt) defined in ~/.config/autodeploy/autodeploy_apps.conf
    echo $TICK$BLUE"Please input SUDO password"$ENDCOLOR

    # Runs sudo apt update and upgrade
    echo $TICK$GREEN"Running apt update and apt upgrade..."$ENDCOLOR ; sudo apt update > /dev/null 2>&1 && sudo apt upgrade -y  > /dev/null 2>&1
    echo $TICK$GREEN"Installing applications from $BLUE$CONFIG_PATH/autodeploy_apps.conf"$ENDCOLOR 

    # Install each application listed in $CONFIG_PATH/autodeploy_apps 
    grep -v '^#' $CONFIG_PATH/autodeploy_apps.conf | while read -r line; do
        echo $TICK$GREEN"Installing $BLUE$line"$ENDCOLOR 
        sudo apt install $line -y > /dev/null 2>&1 #| grep -A 1 "NEW packages" | grep -v "NEW packages"
    done
    echo $TICK$GREEN"Applications installed."$ENDCOLOR 
}

list_configs(){
    # Lists the config files found in ~/.config/autodeploy/*.conf
    echo -n $BLUE
    ls $CONFIG_PATH | grep "_config$"
    echo $ENDCOLOR
}


collect_files(){
    echo $TICK$GREEN"Collecting files from around the system"$ENDCOLOR
    # Pulls files from the remote repository and checks to see if the configuration path already exists
    git -C $CONFIG_PATH pull origin main --allow-unrelated-histories > /dev/null 2>&1

    # Check if the configuration path already exists
    echo $TICK$GREEN"Moving files"$ENDCOLOR
    if test -d $HOST_CONFIG_PATH;then
        echo $TICK$GREEN"Creating files in $BLUE$CONFIG_PATH/$(hostname)_config"$ENDCOLOR
    else
        mkdir -p $HOST_CONFIG_PATH
        echo $TICK$GREEN"Creating files in $BLUE$CONFIG_PATH/$(hostname)_config"$ENDCOLOR
    fi

    # Copy each line in $CONFIG_PATH/autodeploy_files.conf to $HOST_CONFIG_PATH
    cd $HOME
    while read line; do
        # Copies all files listed in $HOST_CONFIG_PATH/autodeploy_files.conf recursively, verbosely, and forcefully to the staging area.
        cp -rf --parents $line $HOST_CONFIG_PATH 
        echo $TICK_MOVE$GREEN" Copying $BLUE$line$GREEN to $BLUE$HOST_CONFIG_PATH$GREEN if file exists"$ENDCOLOR
    done < $CONFIG_PATH/autodeploy_files.conf | grep -v "^#"

    cd $CONFIG_PATH 

    echo $TICK$GREEN"Configuration files saved to $BLUE$HOST_CONFIG_PATH$GREEN. Files can be pushed to $BLUE$remote_repo$GREEN with$BLUE autodeploy -p$GREEN"$ENDCOLOR

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

use_config(){
    if [ -z "$2" ];then
        echo $TICK_ERROR$YELLOW"Please specify the name of the config file you wish to use "$ENDCOLOR
        echo $TICK_ERROR$YELLOW"For example:$BLUE autodeploy -u thinkpad_config$YELLOW listing valid configs:"$ENDCOLOR
        echo $TICK_ERROR$YELLOW"Listing valid configs:"$ENDCOLOR
        list_configs
        #collect_files
    else

        select_config "$@"
    fi


}
select_config(){
        selected_config=$2
        if test -d "$CONFIG_PATH/$selected_config";then
            echo $TICK$GREEN"$selected_config selected"$ENDCOLOR
            HOST_CONFIG_PATH=$CONFIG_PATH/$2
            echo config path is $HOST_CONFIG_PATH
            distribute_files
        else
            echo $TICK_ERROR$YELLOW"Please select a valid file name!"$ENDCOLOR
            list_configs
        fi

}

check_git(){
    # Check if the autodeploy configuration files are are in the current repo. If not, creates them
    if ! test -f "$CONFIG_PATH/autodeploy_files.conf";then
        echo $TICK$GREEN"Config file not found, generating base configuration..."$ENDCOLOR
        echo "config_name=$(hostname)" > $CONFIG_PATH/autodeploy_config.conf $ENDCOLOR

        # Add $remote_repo to autodeploy_config 
        echo "$remote_repo" >> $CONFIG_PATH/autodeploy_config.conf $ENDCOLOR

        # Add default applications to autodeploy_apps
        echo "curl\nneovim\nzsh" > $CONFIG_PATH/autodeploy_apps.conf$ENDCOLOR

        # Add default dot files to autodeploy_files.conf 
        echo ".tmux.conf" > $CONFIG_PATH/autodeploy_files.conf$ENDCOLOR
    fi
}

get_files(){
    # pulls files from origin 
    cd $CONFIG_PATH
    git -C $CONFIG_PATH pull origin main --allow-unrelated-histories  > /dev/null 2>&1; # Figure out how to check if repo exists
    check_git
    echo $TICK$GREEN"Pull complete"$ENDCOLOR

}

remote_push(){
    # Commit and push files to $remote_repo
    cd $CONFIG_PATH
    echo $TICK$GREEN"Adding Files"$ENDCOLOR
    git add . > /dev/null 2>&1
    echo $TICK$GREEN"Commiting"$ENDCOLOR
    git commit -m "Autodeploy from $(hostname) on $(date)" > /dev/null 2>&1
    echo $TICK$GREEN"Pushing..."$ENDCOLOR
    git push -u origin main > /dev/null 2>&1
    echo $TICK$GREEN"Files have been pushed to $YELLOW$remote_repo"$ENDCOLOR

}

backup_old(){
    # Backs up all the files that will be overwritten by autodeploy
    mkdir -p $HOST_CONFIG_PATH"backup"
    while read line; do
        echo $TICK_BACKUP$GREEN"Backing up $BLUE$line$GREEN to $BLUE$BACKUP_DIR"$ENDCOLOR
        cp -rf $HOME/$line $BACKUP_DIR > /dev/null 2>&1; 
    done < $CONFIG_PATH/autodeploy_files.conf
}

new_client(){
    # Pulles files from origin, places files on local machine into $HOST_CONFIG_PATH, and installs apps defined in autodeploy_apps.conf
    get_files
    collect_files
    install_apps
    
}

distribute_files(){
    # Places files defined in autodeploy_file.conf to the correct location in the file system 
    backup_old
    cd $HOST_CONFIG_PATH


    # Need an odd for loop syntax because zsh handles file globs differently than bash 
    for f in .[!.]* *; do # <- for each file that does or does not start with a .
        echo $TICK_MOVE$GREEN"Copying $BLUE$f$GREEN from $BLUE$selected_config$green $GREEN to $BLUE$HOME"$ENDCOLOR
        cp -rf `ls -A | grep -v "backup/"` $HOME
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
    while getopts "D g h u n m c p s f a b l :e:" o; do
        case "${o}" in
            h)
                h=${OPTARG}
                usage
                ;;
            D)
                D=${OPTARG}
                echo $TICK_ERROR$RED"DELETING CONFIG FILES IN 5 SECONDS,$YELLOW PRESS CTRL+C TO CANCEL"$ENDCOLOR
                sleep 5
                rm ~/.config/autodeploy/ -rf
                echo $TICK$GREEN"Config files deleted. Run$BLUE autodeploy -f$GREEN to run first time setup."$ENDCOLOR
                
                ;;
            l)
                l=${OPTARG}
                echo $TICK$GREEN"Listing available configuration files in $CONFIG_PATH"$ENDCOLOR
                list_configs 
                ;;
            e)
                e=${OPTARG}
                echo $TICK$GREEN"Editing Files"$ENDCOLOR
                edit_files 
                ;;
            p)
                c=${OPTARG}
                echo $TICK$GREEN"Pushing config to $remote_repo"$ENDCOLOR
                remote_push
                ;;
            g)
                g=${OPTARG}
                echo $TICK$GREEN"Getting config from $BLUE$remote_repo"$ENDCOLOR
                get_files 
                ;;
            c)
                c=${OPTARG}
                echo $TICK$GREEN"Collecting config files and storing them in $BLUE$HOST_CONFIG_PATH"$ENDCOLOR
                collect_files
                ;;
            f)
                f=${OPTARG}
                echo $TICK$GREEN"Re-running first time setup"$ENDCOLOR

                # Add this feature
                ;;
            a)
                a=${OPTARG}
                echo $TICK$GREEN"Installing applications"$ENDCOLOR
                install_apps 
                ;;
            b)
                b=${OPTARG}
                echo $TICK$GREEN"Backing up current dotfiles to $BACKUP_DIR"$ENDCOLOR
                backup_old 
                ;;
            m)
                m=${OPTARG}
                echo $BOLD$GREEN"Moving files to correct locations"$ENDCOLOR
                distribute_files 
                ;;
            n)
                n=${OPTARG}
                echo $BOLD$GREEN"Running full new client install"$ENDCOLOR
                new_client 
                ;;
            u)
                u=${OPTARG}
                echo $TICK$GREEN"Selecting alternate configuration file"$ENDCOLOR
                use_config "$@"
                ;;
            ?)
                usage
                ;;
        esac
    done
}

# Run main funciton and pass it command line arguments
main "$@"

