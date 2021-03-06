function gc --description="git commit"
  if test -z (command git rev-parse --show-toplevel 2> /dev/null)
    set_color red
    echo "Not in a git repository"
    set_color normal
    return 1
  end

  if test (count (command git status --porcelain | command grep "^[^ ?]")) -eq 0
    set_color yellow
    echo "Nothing to commit..."
    set_color normal
    return 1
  end

  set -l arguments

  set -l cmd "command git diff --cached --name-only"

  eval "$GISH_DIR/fish/include/parse $argv"

  if test (count $ARGV) -gt 0
    set arguments (gish find -c $cmd $ARGV)

    if test (count $arguments) -eq 0
      set_color red
      echo "No matches found"
      set_color normal
      return 0
    end
  end

  command git commit $OPTV $arguments
  gs
end
