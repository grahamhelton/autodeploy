# AutoDeploy
AutoDeploy is a tool written in 100% bash that allows for extensible synchronization of configuration files, auto installation of programs your commonly use, and allows for git-like pull/commit. This is intended to be extensible to allow for you to quickly push out a set of configuration files, and have them be pulled into any other machine.

# Goals
I work on so many different machines that keeping my configuration files and the versions of the software I use in sync between many machines is a painstaking task. Autodeploy should help with the following:

- Easily moving all configuraiton files (`~/.vimrc`,`~/.config/i3/config`,`~/.xprofile`,etc) between multiple machines
- 100% bash 
- [Trufflehog](https://github.com/trufflesecurity/trufflehog)-like functionality for configuration files being stored in public places (IE: Github)

# Features
- Pulling down of files from remote repository
- Pushing of files to a remote repository
- *Staging* of files defined in `global_dotFiles.conf` into `~/.config/autodeploy/$(hostname)_config/`
- Distributing config files in `$(hostname)_config/` to their correct locations
- Backing up of local configuration files to `~/.config/autodeploy/$(hostname)_config/backup/` before overwriting them
- Installing of any application defined in `global_applications`
- Editing configuration files in `.config/autodeploy` through the autodeploy tool 

# Documentation

`global_applications.conf` -> The names of applications you wish to install via apt

```markdown
neovim
mupdf
curl
```

`global_config.conf` -> Defines variables such as your remote repository, your config folder name, etc

```makrdown
config_name=thinkpad
remote_repo=http://github.com/grahamhelton/configurationFiles
```

`global_dotFiles.conf` -> Dot files you'd want on any system

```markdown
.tmux
.vimrc
```


