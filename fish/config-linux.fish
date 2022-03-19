if type -q exa
  alias ll "exa -l -g --icons"
  alias lla "ll -a"
end

# WSL
function os
    set target (string trim $argv -c '/' -r)
    switch (echo $target)
        case ''
            wslview .
	case '*'
	    wslview $target
    end
end