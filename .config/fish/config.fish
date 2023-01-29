set fish_greeting ""

set -gx TERM xterm-256color

# theme
set -g theme_color_scheme terminal-dark
set -g theme_display_user yes

# aliases
alias c clear
alias ls "ls -p -G"
alias la "ls -A"
alias ll "ls -l"
alias lla "ll -A"
alias g git
alias gs "git status"
alias ga "git add"
alias gr "git reset"
alias grs "git restore"
alias gd "git diff --staged"
alias gc "git commit"
alias gp "git push"
alias gpm "git push origin main" 
alias gl "git log"
alias lg lazygit
command -qv nvim && alias vim nvim

set -gx EDITOR nvim

set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH

# NodeJS
set -gx PATH node_modules/.bin $PATH

# Go
set -g GOPATH $HOME/go
set -gx PATH $GOPATH/bin $PATH

# NVM
function __check_rvm --on-variable PWD --description 'Do nvm stuff'
  status --is-command-substitution; and return

  if test -f .nvmrc; and test -r .nvmrc;
    nvm use
  else
  end
end

switch (uname)
  case Darwin
    source (dirname (status --current-filename))/config-osx.fish
  case Linux
    source (dirname (status --current-filename))/config-linux.fish
  case '*'
    source (dirname (status --current-filename))/config-windows.fish
end

set LOCAL_CONFIG (dirname (status --current-filename))/config-local.fish
if test -f $LOCAL_CONFIG
  source $LOCAL_CONFIG
end

# Git Remote Create
function grc
  # Github Repository Name 
  set repo $argv[1]

  # Repositry Visibility
  set private $argv[2]
 
  # GitHub repos Create API call
  set GIT_STATUS (curl -H "Authorization: token $GIT_PAT" https://api.github.com/user/repos -d '{"name" : "'$repo'", "private": '$private'}' -o /dev/null -w '%{http_code}\n' -s)

  switch (echo $GIT_STATUS)
    case 201
      echo 'Github Repository Created Successfully!'
      mkdir $repo
      cd $repo
      git init
      git remote add origin https://github.com/$GIT_USER/$repo.git
      touch README.md
      git add README.md
      git commit -m "init commit"
      git branch -M main
      git push -u origin main
   case '*'
    echo "Github Repository Creation Failed!"
  end
end

# Git Remote Initialize
function gri
  # Github Repository Name 
  set repo $argv[1]

  # Repositry Visibility
  set private $argv[2]
 
  # GitHub repos Create API call
  set GIT_STATUS (curl -H "Authorization: token $GIT_PAT" https://api.github.com/user/repos -d '{"name" : "'$repo'", "private": '$private'}' -o /dev/null -w '%{http_code}\n' -s)

  switch (echo $GIT_STATUS)
    case 201
      echo 'Github Repository Created Successfully!'
      git init
      git remote add origin https://github.com/$GIT_USER/$repo.git
      git add -A
      git commit -m "init commit"
      git branch -M main
      git push -u origin main
   case '*'
    echo "Github Repository Creation Failed!"
  end
end

# Git Remote Delete
function grd
  # Github Repository Name
  set repo $argv[1]
  
  set GIT_STATUS (curl -X DELETE -H "Authorization: token $GIT_PAT" https://api.github.com/repos/$GIT_USER/$repo -o /dev/null -w '%{http_code}\n' -s)

  switch (echo $GIT_STATUS)
    case 204
      echo 'Github Repository Deleted Successfully!'
    case '*'
      echo 'Github Repository Deletion Failed!'
    end
end