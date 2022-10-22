![](/autodeploy_ascii.png)
# AutoDeploy
AutoDeploy is a tool written in 100% bash that allows for extensible synchronization of configuration files, auto installation of programs your commonly use, and allows for git-like pull/commit. This is intended to be extensible to allow for you to quickly push out a set of configuration files, and have them be pulled into any other machine.

# Goals
I work on so many different machines that keeping my configuration files and the versions of the software I use in sync between many machines is a painstaking task. Autodeploy should help with the following:

- Easily moving all configuraiton files (`~/.vimrc`,`~/.config/i3/config`,`~/.xprofile`,etc) between multiple machines
- 100% bash 
- [Trufflehog](https://github.com/trufflesecurity/trufflehog)-like functionality for configuration files being stored in public places (IE: Github) (Coming soon!)

# Features
- Pulling down of files from remote repository
- Pushing of files to a remote repository
- *Staging* of files defined in `global_dotFiles.conf` into `~/.config/autodeploy/$(hostname)_config/`
- Distributing config files in `$(hostname)_config/` to their correct locations
- Backing up of local configuration files to `~/.config/autodeploy/$(hostname)_config/backup/` before overwriting them
- Installing of any application defined in `global_applications`
- Editing configuration files in `.config/autodeploy` through the autodeploy tool 

# Documentation

`autodeploy_apps.conf` -> The names of applications you wish to install via apt

```markdown
neovim
mupdf
curl
```

`autodeploy_config.conf` -> Defines variables such as your remote repository, your config folder name, etc. You shouldn't have to edit this unless chaning repos.

```makrdown
config_name=thinkpad
remote_repo=http://github.com/grahamhelton/configurationFiles
```

`autodeploy_files.conf` -> Configuration files you would like to carry over to different systems. It is important that you define files by their relative location to your home directory. For example, if I wanted to add a file to this, I would run `autodeploy -e files` and add a new file with it's path relative to $HOME such as: `.config/graham/myfolder/myfile.conf` and **NOT** `/home/graham/.config/graham/myfolder/myfile.conf`.

```markdown
.tmux
.vimrc
.config/i3/config

```

# How to use

Autodeploy is fairly simple to use once you understand the switches. Here is a quick run down of what everything does.

`autodeploy -a`: Installs applications defined in the `autodeploy_apps.conf` file. Currently this only supports apt.

`autodeploy -b`: Backs the files on your system that will get overwritten by issuing the `-m` command.

`autodeploy -c`: Collects configuration files defined in `autodeploy_files.conf` from around the system and places them in a folder named <your_computer_name>_config.

`autodeploy -D`: Deletes the configuration files associated with autodeploy (~/.config/autodeploy/).

`autodeploy -e <apps|config|files>`: Allows you to edit the configuration files from autodeploy. This is functionally the same as running `vim ~/.config/autodeploy/autodeploy_files.conf`

`autodeploy -g`: Gets files from the remote repository. This is functionally the same as running `git pull`.

`autodeploy -h`: Show the help screen.

`autodeploy -l`: Lists the available configuration files for different systems. 

`autodeploy -m`: Moves the files defined in `autodeploy_files.conf` to their correct places in the file system.

`autodeploy -p`: Push files to remote directory. This takes files in the "staging directory" and pushes them to the remote repository. This is functionally the same as running `git push`

`autodeploy -u`: Moves the files from a different computer's configuration file to the local machine. You can see which configuration files you can choose from by running `autodeploy -l`
