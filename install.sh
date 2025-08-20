#!/bin/bash
prompt_install() {
	echo -n "$1 is not installed. Would you like to install it? (y/n) " >&2
	old_stty_cfg=$(stty -g)
	stty raw -echo
	answer=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
	stty $old_stty_cfg && echo
	if echo "$answer" | grep -iq "^y" ;then
		# This could def use community support
		if [ -x "$(command -v apt-get)" ]; then
			sudo apt-get install $1 -y

		elif [ -x "$(command -v brew)" ]; then
			brew install $1

		elif [ -x "$(command -v zypper)" ]; then
			sudo zypper install $1

		elif [ -x "$(command -v pkg)" ]; then
			sudo pkg install $1

		elif [ -x "$(command -v pacman)" ]; then
			sudo pacman -S $1

		else
			echo "I'm not sure what your package manager is! Please install $1 on your own and run this deploy script again. Tests for package managers are in the deploy script you just ran starting at line 13. Feel free to make a pull request at https://github.com/parth/dotfiles :)" 
		fi 
	fi
}

check_for_software() {
	echo "Checking to see if $1 is installed"
	if ! [ -x "$(command -v $1)" ]; then
		prompt_install $1
	else
		echo "$1 is installed."
	fi
}
system=`uname -a | grep -q "Linux" && echo "Linux" || echo "OSX"`

check_for_software git
check_for_software nvim
check_for_software gcc
check_for_software fzf
check_for_software luarocks
if [ "$system" = "OSX"]; then
	check_for_software node
else
	check_for_software nodejs
fi
sudo npm i -g markdownlint-cli
# LSP Related
# GO

if ! [ -x "$(command -v go)" ]; then
	echo "TODO: INSTALL GOLANG! ideally with GVM \n"
fi
# debugger
check_for_software delve

## NVIM
if [ -d "$HOME/.config/nvim" ]; then
	echo "backup"
	tar -czf ~/.config/nvim-$(date +%Y%m%d%H%M%S).tar.gz ~/.config/nvim 
	rm -rf ~/.config/nvim
fi

git clone git@github.com:orchowski/seamlessvim.git ~/.config/nvim

