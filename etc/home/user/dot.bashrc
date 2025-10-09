#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Alias to runs lsd (LSDeluxe) to add colour icons to the ls command
alias ls='lsd'

# Alias to run rm -i to prompt to delete
alias rm='rm -i'

# Alias to show human readable for df(Disk Free)
alias df='df -h'

#Alias to show human readable for du(Disk Usage)
alias du='du -h'

# Alias to Sync Repository
alias pacs='sudo pacman -Sy'

# Alias to Update System
alias pacu='sudo pacman -Syu'
