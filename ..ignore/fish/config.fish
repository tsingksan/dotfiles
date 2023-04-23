if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -xg ALL_PROXY http://localhost:7890     	# proxy
nvm use default --silent                    	# nvm
export PATH="$HOME/.cargo/bin:$PATH" 		# cargo
