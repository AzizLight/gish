__is_a_git_repo() {
  local repo=$(command git rev-parse --show-toplevel 2> /dev/null)
  if [[ -z "$repo" ]]
  then
    echo -e "${RED}Not in a git repository${NO_COLOR}"
    return 1
  else
    return 0
  fi
}

gs() {
  if __is_a_git_repo
  then
    gish status "$@"

    if [[ $? -eq 49 ]]
    then
      echo ""
      echo -e "${RED}Falling back to the basic \`git status\`${NO_COLOR}"
      echo ""

      command git status
    fi
  fi
}

ga() {
  if __is_a_git_repo
  then
    gish add "$@"

    gs
  fi
}

gap() {
  if __is_a_git_repo
  then
    local argv=""
    local cmd="command git diff --name-only"

    if [[ "$1" ]]
    then
      local argv=$(gish find -c "$cmd" "$@" | tr '\n' ' ')

      if [[ -z "$argv" ]]
      then
        echo -e "${RED}No matches found${NO_COLOR}"
        return 0
      fi
    fi

    command git add -p $argv
    gs
  fi
}

gb() {
  if __is_a_git_repo
  then
    command git branch "$@"
  fi
}

gba() {
  if __is_a_git_repo
  then
    command git branch -a "$@"
  fi
}

gbr() {
  if __is_a_git_repo
  then
    command type hub > /dev/null

    if [[ $? -gt 0 ]]
    then
      echo -e "${RED}You need to install `hub` to use this command${NO_COLOR}"
      return 1
    fi

    command hub browse
  fi
}

gc() {
  if __is_a_git_repo
  then
    local status=$(command git status --porcelain | command grep "^[^ ?]")
    if [[ "$status" ]]
    then
      local argv=""
      local cmd="command git diff --cached --name-only"

      parse "$@"

      if [[ "${ARGV[0]}" ]]
      then
        argv=$(gish find -c "$cmd" "${ARGV[@]}" | tr '\n' ' ')

        if [[ -z "$argv" ]]
        then
          echo -e "${RED}No matches found${NO_COLOR}"
          return 0
        fi
      fi

      # NOTE: The if/else conditionals below are necessary due to a bug in git
      if [[ -z "${OPTV[0]}" && -z "$argv" ]]
      then
        command git commit
      elif [[ -z "${OPTV[0]}" ]]
      then
        command git commit $argv
      elif [[ -z "$argv" ]]
      then
        command git commit "${OPTV[@]}"
      else
        command git commit "${OPTV[@]}" $argv
      fi

      gs
    else
      echo -e "${YELLOW}Nothing to commit...${NO_COLOR}"
      return 1
    fi
  fi
}

gcd() {
  if __is_a_git_repo
  then
    builtin cd $(command git rev-parse --show-toplevel)
  fi
}

gcl() {
  if [[ $# -eq 0 ]]
  then
    local clipboard=""

    command type pbpaste > /dev/null

    if [[ $(command type pbpaste) ]]
    then
      clipboard=$(pbpaste)
    elif [[ $(command type xsel) ]]
    then
      clipboard=$(command xsel --clipboard --output)
    elif [[ $(command type xclip) ]]
    then
      clipboard=$(command xclip -selection clipboard -o)
    else
      echo -e "${RED}No clipboard management command was found${NO_COLOR}"
      echo -e "${RED}pbpaste, xsel or xclip required${NO_COLOR}"

      return 1
    fi

    command git clone "$clipboard" > /dev/null 2> /dev/null

    if [[ $? -gt 0 ]]
    then
      echo -e "${RED}Invalid git repository in clipboard${NO_COLOR}"
      return 128
    fi

    echo -e "${GREEN}Clone repository: ${clipboard}${NO_COLOR}"
  else
    command git clone "$@" > /dev/null 2> /dev/null

    if [[ $? -gt 0 ]]
    then
      echo -e "${RED}Unable to find the repository ${@}${NO_COLOR}"
      return 128
    fi

    echo -e "${GREEN}Clone repository: ${@}${NO_COLOR}"
  fi
}

gcm() {
  if __is_a_git_repo
  then
    local status=$(command git status --porcelain | command grep "^[^ ?]")
    if [[ "$status" ]]
    then
      if [[ $# -eq 0 ]]
      then
        echo -e "${RED}Arborting commit due to empty commit message${NO_COLOR}"
        return 1
      fi

      command git commit -m "$@"
      gs
    else
      echo -e "${YELLOW}Nothing to commit...${NO_COLOR}"
      return 1
    fi
  fi
}

gco() {
  if __is_a_git_repo
  then
    if [[ -z "$1" ]]
    then
      echo -e "${RED}A branch is needed${NO_COLOR}"
      return 1
    fi

    local cmd="git branch --no-color | command sed -E 's/^\*? ? //g'"
    local branch=$(gish find -c "$cmd" "$1")
    shift

    if [[ -z ${branch[0]} ]]
    then
      echo -e "${RED}No matches found${NO_COLOR}"
      return 0
    elif [[ -n ${branch[1]} ]]
    then
      echo -e "${YELLOW}Too many matches${NO_COLOR}"
      echo -e "${YELLOW}Refine your query please${NO_COLOR}"
      return 1
    fi

    local current_branch=$(git branch --no-color | command grep "* ${branch[0]}")
    if [[ "$current_branch" ]]
    then
      echo -e "${YELLOW}Already on branch '${branch[0]}'${NO_COLOR}"
      return 0
    fi

    # NOTE: The if/else conditionals below are necessary due to a bug in git
    if [[ "$1" ]]
    then
      command git checkout --quiet "${branch[0]}" -- "$@"
    else
      command git checkout --quiet "${branch[0]}"
    fi

    gs
    echo -e "${GREEN}Swiched to branch '${branch[0]}'${NO_COLOR}"
  fi
}

gcob() {
  if __is_a_git_repo
  then
    if [[ -z "$1" ]]
    then
      echo -e "${RED}You need to specify a name for the new branch${NO_COLOR}"
      return 129
    fi

    local existing_branch=$(command git branch --no-color | command sed -E "s/^\*? ? //g" | command grep -E "^$argv\$")
    if [[ "$existing_branch" ]]
    then
      echo -e "${RED}A branch named '$1' already exists${NO_COLOR}"
      return 128
    fi

    command git checkout --quiet -b "$1"
    gs

    echo -e "${GREEN}Swiched to a new branch '$1'${NO_COLOR}"
  fi
}

gcv() {
  gc --verbose "$@"
}

gd() {
  if __is_a_git_repo
  then
    local argv=()
    local cmd="command git status --porcelain | sed 's/^.\{3\}//g'"

    if [[ "$1" ]]
    then
      argv=$(gish find -c "$cmd" "$@")

      if [[ -z "${argv[0]}" ]]
      then
        echo -e "${RED}No matches found${NO_COLOR}"
        return 0
      fi
    fi

    command git diff $argv
  fi
}

gdanger() {
  if __is_a_git_repo
  then
    local revision=""

    if [[ -z "$1" ]]
    then
      revision="HEAD"
    else
      revision="$1"
    fi

    command git reset --hard "$revision"
  fi
}

gdc() {
  if __is_a_git_repo
  then
    local argv=""
    local cmd="command git diff --cached --name-only"

    if [[ "$1" ]]
    then
      argv=$(gish find -c "$cmd" "$@" | tr '\n' ' ')

      if [[ -z "$argv" ]]
      then
        echo -e "${RED}No matches found${NO_COLOR}"
        return 0
      fi
    fi

    command git diff --cached $argv
  fi
}

gl() {
  if __is_a_git_repo
  then
    local top_level=$(command git rev-parse --show-toplevel 2> /dev/null)

    command ls "${top_level}/.git/logs" > /dev/null 2> /dev/null

    if [[ $? -gt 0 ]]
    then
      echo -e "${RED}You didn't commit anything yet...${NO_COLOR}"
      return 1
    fi

    command git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit "$@"
  fi
}

gla() {
  gl --branches --remotes "$@"
}

gps() {
  command git push "$@"
}

grm() {
  if __is_a_git_repo
  then
    if [[ -z "$1" ]]
    then
      echo -e "${RED}You need to list the files to remove${NO_COLOR}"
      return 129
    fi

    local argv=""
    local cmd="command git ls-files"

    parse "$@"

    if [[ "${ARGV[0]}" ]]
    then
      argv=$(gish find -c "$cmd" "${ARGV[@]}" | tr '\n' ' ')
    fi

    if [[ -z "$argv" ]]
    then
      echo -e "${RED}No matches found${NO_COLOR}"
      return 0
    fi

    if [[ -z "${OPTV[0]}" ]]
    then
      command git rm --quiet $argv
    else
      command git rm --quiet "${OPTV[@]}" $argv
    fi

    gs
  fi
}

grs() {
  if __is_a_git_repo
  then
    local argv=""
    local cmd="command git diff --cached --name-only"

    if [[ "$1" ]]
    then
      argv=$(gish find -c "$cmd" "$@" | tr '\n' ' ')

      if [[ -z "$argv" ]]
      then
        echo -e "${RED}No matches found${NO_COLOR}"
        return 0
      fi
    fi

    command git reset --quiet -- $argv
    gs
  fi
}
