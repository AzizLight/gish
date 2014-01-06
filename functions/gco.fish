function gco --description="git checkout"
  set -l arguments

  set -l cmd "git branch --no-color | command sed -E 's/^\*? ? //g'"

  eval "$GISH_DIR/include/parse $argv"

  if test (count $ARGV) -gt 0
    set arguments (gish find -c $cmd $ARGV)

    if test (count $arguments) -gt 1
      set_color yellow
      echo "Too many matches"
      echo "Refine your query please"
      set_color normal
      return 1
    end
  end

  if test -z $arguments
    set_color red
    echo "No matches found"
    set_color normal
    return 0
  end

  if test (count (git branch --no-color | command grep "* $arguments")) -eq 1
    set_color yellow
    echo "Already on branch '$arguments'"
    set_color normal
    return 0
  end

  command git checkout $OPTV $arguments > /dev/null

  set_color green
  echo "Swiched to branch '$arguments'"
  set_color normal

  gs
end