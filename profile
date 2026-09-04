xattr -r -d com.apple.quarantine /path/to/oc

-------------------------------------------
alias kc="/usr/local/bin/kubectl"
alias ocp="oc project"
alias kcp="kc cluster-info"
alias ktx="kubectx"

kc_ns(){
  if [[ -z "$1" ]]; then
    echo "Missing namespace"
    return 1
  fi
  HTTPS_PROXY=$PROXY kubectl config set-context --current --namespace="$1"
}

azl() {
    keychain-environment-variable <id> | pbcopy && \
    open -na "Google Chrome" --args --incognito "https://portal.azure.com/"
}

# for merging bash history from multiple tabs
# Maximum number of history lines in memory
export HISTSIZE=50000
# Maximum number of history lines on disk
export HISTFILESIZE=50000
# Ignore duplicate lines
export HISTCONTROL=ignoreboth:erasedups
# When the shell exits, append to the history file
#  instead of overwriting it
setopt histappend
export ANSIBLE_HOST_KEY_CHECKING=False

# Alias AKS
alias argocd_password="kubectl -n argocd get secret argocd-initial-admin-secret -ojson | jq .data.password | tr -d '\"' | base64 -d | pbcopy "
alias kc_events="kc get events --sort-by='.lastTimestamp'"

####### Argocd #######
argocd_connect (){
    if kubectl -n argocd get ingress -ojsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null  ; then
      ep=$(kubectl -n argocd get ingress -ojsonpath='{.items[0].spec.rules[0].host}')
    else
      ep=$(kubectl -n argocd get route -ojsonpath='{.items[0].spec.host}')
    fi
    argocd_password
    open -a "Firefox" -n --args https://${ep} 2>&1
}

argo_app_status(){
   if [ -z "$1" ]; then
      echo "Missing app name !!"
   else
    kc -n argocd get app "$1" -ojson | jq '.status| .sync, .summary'
   fi
}

### Functions for setting and getting environment variables from the OSX keychain ###
### Adapted from https://www.netmeister.org/blog/keychain-passwords.html ###

# Use: keychain-environment-variable SECRET_ENV_VAR
function keychain-environment-variable () {
    security find-generic-password -w -a ${USER} -D "environment variable" -s "${1}"
}

# Use: set-keychain-environment-variable SECRET_ENV_VAR
#   provide: super_secret_key_abc123
function set-keychain-environment-variable () {
    [ -n "$1" ] || print "Missing environment variable name"

    # Note: if using bash, use `-p` to indicate a prompt string, rather than the leading `?`
    read -s "?Enter Value for ${1}: " secret

    ( [ -n "$1" ] && [ -n "$secret" ] ) || return 1
    security add-generic-password -U -a ${USER} -D "environment variable" -s "${1}" -w "${secret}"
}


#########RIGHT PROMPT #############
prompt_time() {
  echo -n "%{%F{blue}%}"
  echo -n "\ue0b2"
#   echo -n "%{%K{blue}%}%{%F{white}%}"
  echo -n " "
  echo -n "$(date '+%X ')"
  echo -n "$http_proxy"
}

build_right_prompt() {
  prompt_time
}
if [[ -z "${POWERLEVEL9K_MODE-}" && -z "${POWERLEVEL10K_LEFT_PROMPT_ELEMENTS-}" ]]; then
  RPROMPT='$(build_right_prompt)'
fi
###################################
# pipe output to grep
alias -g G='| grep'
# pipe output to less
alias -g L='| less'
# pipe output to `wc` with option `-l`
alias -g W='| wc -l'
# convert multiline output to single line and copy it to the system clipboard
alias -g C='| tr -d ''\n'' | pbcopy'

# Search through your command history and print the top 10 commands
alias history-stat='history 0 | awk ''{print $2}'' | sort | uniq -c | sort -n -r | head'

# Use `which` to find aliases and functions including binaries
which='(alias; declare -f) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot'
alias jwt_decode="jq -R 'split(\".\") | select(length > 0) | .[0],.[1] | @base64d | fromjson'"

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
# Configure fuzzy find "ctl+t" and "ctl+r"
export FZF_DEFAULT_COMMAND="rg --files --follow --no-ignore-vcs --hidden -g '!{**/node_modules/*,**/.git/*,**.emacs.d/*}'"
export FZF_CTRL_T_OPTS="--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"


# Add bash completion
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
