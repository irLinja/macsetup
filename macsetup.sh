#! /bin/bash


#########################
#                       #
# Script Configurations #
#                       #
#########################

email="hi@example.com"

function notification {
    terminal-notifier -message "$1"
    read -pr 'Press enter to continue'
}

function pausethescript {
    echo "Press any key to continue the installation script"
    read -r
}

function openfilewithregex {
    file=$(find . -maxdepth 1 -execdir echo {} ';'  | grep "$1")
    open "${file}"
    pausethescript
    rm "${file}"
}

#
# DisplayLink Manager & DisplayLink Manager MacOS Extension
#
# Add the possibility to have more than one external monitor on MacBook M1 with a DisplayLink compatible hub
# Extension for DisplayLink Manager to work at the login screen
#
# https://www.displaylink.com
#
open "https://www.displaylink.com/downloads/file?id=1713"
openfilewithregex "DisplayLink Manager Graphics Connectivity.*\.pkg"
open "https://displaylink.com/downloads/macos_extension"
open "macOS App LoginExtension-EXE.dmg"



#######################
#                     #
# Pre-Installalations #
#                     #
#######################

#
# Rosetta2
#
# Run x86_64 app on arm64 chip
#
# https://developer.apple.com/documentation/apple_silicon/about_the_rosetta_translation_environment
#
/usr/sbin/softwareupdate --install-rosetta --agree-to-license

#
# Oh My Zsh
#
# https://github.com/ohmyzsh/ohmyzsh
#
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"


#
# tmux
#
# Running multiple terminal sessions in the same window
#
# https://github.com/tmux/tmux
#
brew install tmux

#
# Configure SSH
#
# ssh-keygen -t rsa -b 4096 -C $email
# ssh-add -K ~/.ssh/id_rsa
# ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
# ssh-keyscan -t rsa bitbucket.org >> ~/.ssh/known_hosts
# pbcopy < ~/.ssh/id_rsa.pub
# open https://github.com/settings/keys
# notification "Add your SSH key to Github (copied into the clipboard)"


############################
#                          #
# Utils to run this script #
#     (needed order)       #
#                          #
############################

#
# Xcode Command Line Tools
#
# Command line XCode tools & the macOS SDK frameworks and headers
#
# https://developer.apple.com/xcode
#
xcode-select --install

#
# Homebrew + homebrew-cask-versions + brew-cask-upgrade + Casks for Fonts
#
# macOS package manager
# Alternate versions of Homebrew Casks
# CLI for upgrading outdated Homebrew Casks
# Casks for Fonts
#
# https://github.com/Homebrew/brew
# https://github.com/Homebrew/homebrew-cask-versions
# https://github.com/buo/homebrew-cask-upgrade
# https://github.com/Homebrew/homebrew-cask-fonts
#
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew analytics off
brew tap homebrew/cask-versions
brew tap buo/cask-upgrade
brew tap homebrew/cask-fonts

#
# Dockutil
#
# Utility to manage macOS Dock items
#
# https://github.com/kcrawford/dockutil
#
brew install dockutil

#
# Duti
#
# Utility to set default applications for document types (file extensions)
#
# https://github.com/moretension/duti
#
brew install duti

#
# Git
#
# File versioning
#
# https://github.com/git/git
#
brew install git

#
# lastversion
#
# CLI to get latest GitHub Repo Release assets URL
#
# https://github.com/dvershinin/lastversion
#
pip install lastversion

#
# loginitems
#
# Utility to manage startup applications
#
# https://github.com/ojford/loginitems
#
brew tap OJFord/formulae
brew install loginitems

#
# mas-cli
#
# Unofficial macOS App Store CLI
#
# https://github.com/mas-cli/mas
#
brew install mas
mas signin $email

#
# tccutil
#
# Command line tool to modify the accessibility database
#
# https://github.com/jacobsalmela/tccutil
#
brew install tccutil

#
# Script Editor
#
sudo -E tccutil -e com.apple.ScriptEditor2

#
# terminal-notifier
#
# Utility to send macOS notifications
#
# https://github.com/julienXX/terminal-notifier
#
brew install terminal-notifier


###########################
#                         #
# Top Helper Applications #
#                         #
###########################


notification "Deactivate the System Integrity Protection with 'csrutil disable' in Recovery Mode"

#
# Alfred & alfred-google-translate & alfred-language-configuration
#
# Spotlight replacement
# Google Translate Workflow
# Google Translate Language Configuration Workflow (needed by alfred-google-translate)
#
# https://www.alfredapp.com
# https://github.com/xfslove/alfred-google-translate
# https://github.com/xfslove/alfred-language-configuration
#
# brew install --cask alfred
# defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>" # Deactivate Spotlight Global Shortcut to use it with Alfred instead (will work after logging off)
# open -a "Alfred 4"
# notification "Add Alfred's licenses & set sync folder"
# sudo -E tccutil -e com.runningwithcrayons.Alfred
# npm install -g alfred-google-translate
# npm install -g alfred-language-configuration
# notification "Configure alfred-google-translate with 'trc en&fr'"

#
# Bartender
#
# macOS menubar manager
#
# https://www.macbartender.com
#
# brew install --cask bartender
# sudo -E tccutil -e com.surteesstudios.Bartender

#
# Raycast
#
# macOS productivity tool, Alfred + Bartender
#
# https://raycast.app
#
brew install --cask raycast

#
# CommandQ
#
# Utility to prevent accidentally quiting an application
#
# https://commandqapp.com
#
# brew install --cask commandq

#
# Contexts
#
# Application windows switcher
#
# https://contexts.co
#
# brew install --cask contexts
# sudo -E tccutil -e com.contextsformac.Contexts
# notification "Open the license file from 1Password"

#
# Control Plane
#
# Utility to automate things based on context & location
#
# https://github.com/dustinrue/ControlPlane
#
brew install --cask controlplane

#
# IINA
#
# The modern media player for macOS
#
# https://iina.io
#
brew install --cask iina

#
# Espanso
#
# Text expander / snipet
#
# https://github.com/federico-terzi/espanso
#
brew tap federico-terzi/espanso
brew install espanso
sudo tccutil -e "$(print -r =espanso\(:A\))"
espanso register
espanso start

#
# HSTR
#
# Shell command history management
#
# https://github.com/dvorka/hstr
#
brew install hh

#
# Karabiner-Elements
#
# Keyboard customization utility
#
# https://github.com/pqrs-org/Karabiner-Elements
#
brew install --cask karabiner-elements

#
# Amphetamine
#
# Menubar app to manage caffeinate
#
# https://apps.apple.com/us/app/amphetamine/id937984704
#
mas install 937984704

#
# Little Snitch
#
# Kinda dynamic firewall
#
# https://www.obdev.at/products/littlesnitch/index.html
# 
# brew install --cask little-snitch

#
# Logitech Mouse Manager
#
# Mouse Configuration
#
# https://www.logitech.com/en-ca/product/options
#
# curl -L https://download01.logi.com/web/ftp/pub/techsupport/options/options_installer.zip --output logitech.zip
# unzip logitech.zip
# rm logitech.zip
# openfilewithregex "LogiMgr Installer.*"
# rm -rf "${file}"


#
# Shush
#
# Easily mute or unmute your microphone
#
# https://mizage.com/shush/
#
# mas install 496437906

#
# Sound Control
#
# Advanced audio controls
#
# https://staticz.com/soundcontrol/
#
# brew install --cask sound-control

#
# TripMode
#
# Manage applications internet access
#
# https://tripmode.ch
#
# brew install --cask TripMode

#
# Zoom
#
# Video conference
#
# https://zoom.us
#
# brew install --cask zoomus

#
# Zsh-z
#
# fastest cd alternative
#
# https://github.com/agkozak/zsh-z
#
git clone git@github.com:agkozak/zsh-z.git "$ZSH_CUSTOM"/plugins/zsh-z


########################
#                      #
# Applications Cleanup #
#                      #
########################

#
# Garage Band
#
sudo rm -rf /Applications/GarageBand.app

#
# iMovie
#
sudo rm -rf /Applications/iMovie.app

#
# Keynote
#
sudo rm -rf /Applications/Keynote.app
dockutil --remove 'Keynote' --allhomes

#
# Numbers
#
sudo rm -rf /Applications/Numbers.app
dockutil --remove 'Numbers' --allhomes

#
# Pages
#
sudo rm -rf /Applications/Pages.app
dockutil --remove 'Pages' --allhomes


################
#              #
# Dock Cleanup #
#              #
################

#
# App Store
#
dockutil --remove 'App Store' --allhomes

#
# Calendar
#
# dockutil --remove 'Calendar' --allhomes

#
# Contacts
#
dockutil --remove 'Contacts' --allhomes

#
# Facetime
#
dockutil --remove 'FaceTime' --allhomes

#
# Launchpad
#
dockutil --remove 'Launchpad' --allhomes

#
# Mail
#
dockutil --remove 'Mail' --allhomes

#
# Maps
#
dockutil --remove 'Maps' --allhomes

#
# Messages
#
dockutil --remove 'Messages' --allhomes

#
# Music
#
dockutil --remove 'Music' --allhomes

#
# News
#
dockutil --remove 'News' --allhomes

#
# Notes
#
dockutil --remove 'Notes' --allhomes

#
# Photos
#
dockutil --remove 'Photos' --allhomes

#
# Podcasts
#
dockutil --remove 'Podcasts' --allhomes

#
# Reminders
#
dockutil --remove 'Reminders' --allhomes

#
# Safari
#
dockutil --remove 'Safari' --allhomes

#
# System Preferences
#
dockutil --remove 'System Preferences' --allhomes

#
# TV
#
dockutil --remove 'TV' --allhomes

###############################
#                             #
# Dock & Menu Bar Preferences #
#                             #
###############################

#
# Minimize window into application icon
#
defaults write com.apple.dock minimize-to-application -bool true

#
# Position on screen
#
defaults write com.apple.dock "orientation" -string "buttom"

#
# Show recent applications in Dock
#
defaults write com.apple.dock show-recents -bool false

#
# Tile Size
#
defaults write com.apple.dock tilesize -int 35


######################
#                    #
# Finder Preferences #
#                    #
######################

#
# .DS_Store files creation on Network Disk
#
defaults write com.apple.desktopservices DSDontWriteNetworkStores true

#
# New Finder windows show
#
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads"

#
# Show all filename extensions
#
# defaults write -g AppleShowAllExtensions -bool true

#
# Show Library Folder
#
xattr -d com.apple.FinderInfo ~/Library
sudo chflags nohidden ~/Library

#
# Show Path Bar
#
# defaults write com.apple.finder ShowPathbar -bool true

#
# Show Status Bar
#
defaults write com.apple.finder ShowStatusBar -boolean true

#
# Show these items on the desktop - CDs, DVDs, and iPods
#
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

#
# Show these items on the desktop - External disks
#
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false


##################################
#                                #
# Security & Privacy Preferences #
#                                #
##################################

#
# FileVault - Turn On Filevault...
#
sudo fdesetup enable

#
# General - Allow apps downloaded from Anywhere
#
sudo spctl --master-disable

##########################
#                        #
# Sharing Configurations #
#                        #
##########################

#
# Computer name
#
sudo scutil --set ComputerName "FunLand pro"
sudo scutil --set HostName "Funland"
sudo scutil --set LocalHostName "Funland-pro"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "Funland"


########################
#                      #
# Sound Configurations #
#                      #
########################

#
# Sound Effects - Don't Play sound on startup
#
sudo nvram StartupMute=%01

#
# Sound Effects - Play user interface sound effects
#
# defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -int 0


###########################
#                         #
# Trackpad Configurations #
#                         #
###########################

#
# Point & Click - Look up & data detector
#
# defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool false


################################
#                              #
# User & Groups Configurations #
#                              #
################################

#
# Guest User
#
sudo defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool false
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool false


########################
#                      #
# Other Configurations #
#                      #
########################

#
# Terminal configurations
#
dockutil --add /System/Applications/Utilities/Terminal.app --allhomes

#
# Sound - Play user interface sound effects
#
# defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -int 0

#
# Sound - Show volume in menu bar
#
# need to find a way to do this with the command line since Apple removed the Sound.menu from Menu Extras
#
# open /System/Library/PreferencePanes/Sound.prefPane
# notification 'Uncheck "Show volume in menu bar"'


# Trackpad - App Expose & Mission Control (need to be done together)
# defaults write com.apple.dock showAppExposeGestureEnabled -bool false
# defaults write com.apple.dock showMissionControlGestureEnabled -bool false
# defaults -currentHost write NSGlobalDomain com.apple.trackpad.fourFingerVertSwipeGesture -bool false
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -bool false
# defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -bool false

# Trackpad - Smart zoom
defaults write com.apple.dock showSmartZoomEnabled -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseTwoFingerDoubleTapGesture -bool true

# Trackpad - Swipe between full-screen apps
defaults -currentHost write NSGlobalDomain com.apple.trackpad.threeFingerVertSwipeGesture -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -bool true

# Show Notification Center on Trackpad
defaults -currentHost write NSGlobalDomain com.apple.trackpad.twoFingerFromRightEdgeSwipeGesture -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -bool true

#Disable Launchpad and Show Desktop Gestures on Trackpad
defaults write com.apple.dock showDesktopGestureEnabled -bool true
defaults write com.apple.dock showLaunchpadGestureEnabled -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.fourFingerPinchSwipeGesture -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerPinchGesture -bool false
defaults -currentHost write NSGlobalDomain com.apple.trackpad.fiveFingerPinchSwipeGesture -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadFiveFingerPinchGesture -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFiveFingerPinchGesture -bool false

#Deactivate the Force click and haptic feedback from Trackpad manually
# defaults write com.apple.systemsound "com.apple.sound.uiaudio.enabled" -bool false

#Activate Silent clicking
# defaults write com.apple.AppleMultitouchTrackpad ActuationStrength -int 0

#Finder display settings
defaults write com.apple.finder FXEnableExtensionChangeWarning -boolean false
defaults write com.apple.finder ShowPathbar -bool true

# Prevent the dock from moving monitors
defaults write com.apple.Dock position-immutable -bool true

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

#Expand save panel
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

#Search the current folder by default in Finder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

#Change the log in screen background
# cp ~/Documents/misc/Mojave.heic /Library/Desktop\ Pictures

# Keyboard - Press Fn to
# Change to do nothing
# defaults write com.apple.HIToolbox AppleFnUsageType -int 0



#
# Disable the accent characters menu
#
defaults write -g ApplePressAndHoldEnabled -bool false

#
# Kill Finder, Dock & SystemUIServer
#
# (for applying modified settings)
#
killall Finder
killall Dock
killall SystemUIServer


#####################
#                   #
# Main applications #
#                   #
#####################

#
# 1Password
#
# Password manager
#
# https://1password.com
#
brew install --cask 1password
dockutil --add /Applications/1Password\ 8.app/ --allhomes

#
# Slack
#
# https://slack.com
#
brew install --cask slack
dockutil --add /Applications/Slack.app/ --allhomes

#
# Spaceship Prompt
#
# https://github.com/denysdovhan/spaceship-prompt
#
npm install -g spaceship-prompt

#
# Spotify
#
# https://www.spotify.com
#
brew install --cask spotify
dockutil --add /Applications/Spotify.app --allhomes

#
# Visual Studio Code
#
# https://github.com/microsoft/vscode
#
# brew install --cask visual-studio-code
# dockutil --add /Applications/Visual\ Studio\ Code.app/ --allhomes

#
# Sublime Text
#
# https://www.sublimetext.com/
#
brew install --cask sublime-text

###################
#                 #
# Developer stuff #
#                 #
###################

#
# BFG Repo-Cleaner
#
# https://github.com/rtyley/bfg-repo-cleaner
#
# git-filter-branch replacement
#
brew install bfg

#
# Git
#
# https://github.com/git/git
#
brew install git
git config --global user.name "Arash Haghighat"
git config --global user.email $email
git config --global init.defaultBranch master
git config --global push.default current
git config --global pull.rebase true
git config --global difftool.prompt true

#
# Git Large File Storage
#
# https://github.com/git-lfs/git-lfs
#
brew install git-lfs

#
# GoEnv + Go
#
# https://github.com/syndbg/goenv
# https://golang.org
#
# brew install goenv
# goenv install 1.11.4

#
# GPG Suite
#
# https://gpgtools.org
#
brew install --cask gpg-suite
notification "get my private key from 1Password"
gpg --import private.key
git config --global user.signingkey 523390FAB896836F8769F6E1A3E03EE956F9208C
git config --global commit.gpgsign true

#
# Grip
#
# GitHub Readme Instant Preview
#
# https://github.com/joeyespo/grip
#
brew install grip

#
# Prettier
#
# https://github.com/prettier/prettier
#
brew install prettier

#
# pyenv + Python + Wheel + Pylint + pytest
#
# Python version manager
# Python SDK
# Python wheel packaging tool
# Python linter
# Python tests framework
#
# https://github.com/pyenv/pyenv
# https://www.python.org
# https://github.com/pypa/wheel
# https://github.com/PyCQA/pylint/
# https://github.com/pytest-dev/pytest
#
brew install pyenv
pyenv install 3.9.7
pyenv global 3.9.7
python -m pip install --upgrade pip
python -m pip install --upgrade build
pip install wheel
pip install pylint
pip install -U pytest

#
# ShellCheck
#
# https://github.com/koalaman/shellcheck
#
# ibrew install shellcheck
# https://github.com/koalaman/shellcheck/issues/2162

#
# Ripgrep
#
# https://github.com/BurntSushi/ripgrep
#
# Recursively searches directories for a regex pattern
#
brew install ripgrep

#
# google-cloud-sdk - gcloud
#
# https://cloud.google.com/sdk/docs/install
#
brew install --cask google-cloud-sdk
######################
#                    #
# Command line tools #
#                    #
######################

#
# Asciinema
#
# https://github.com/asciinema/asciinema
#
# brew install asciinema
# asciinema auth

#
# Bandwhich
#
# https://github.com/imsnif/bandwhich
#
brew install bandwhich

#
# Bat
#
# https://github.com/sharkdp/bat
#
brew install bat

#
# Color LS
#
# https://github.com/athityakumar/colorls
#
gem install colorls

#
# htop
#
# https://github.com/htop-dev/htop
#
brew install htop

#
# ImageMagick
#
# https://github.com/ImageMagick/ImageMagick
#
brew install imagemagick

#
# jq
#
# https://github.com/stedolan/jq
#
brew install jq

#
# lsusb
#
# https://github.com/jlhonora/lsusb
#
brew install lsusb

#
# LZip
#
# https://www.nongnu.org/lzip
#
brew install lzip

#
# Noti
#
# https://github.com/variadico/noti
#
brew install noti

#
# The Fuck
#
# https://github.com/nvbn/thefuck
#
brew install thefuck

#
# tl;dr Pages
#
# https://github.com/tldr-pages/tldr
#
brew install tldr

#
# Vundle
#
# Vim plugin manager
#
# https://github.com/VundleVim/Vundle.vim
#
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

#
# Wifi Password
#
# https://github.com/rauchg/wifi-password
#
brew install wifi-password

#
# Youtube Downloader
#
# https://github.com/ytdl-org/youtube-dl/
#
brew install youtube-dl


################
#              #
# Applications #
#              #
################

#
# AppCleaner
#
# https://freemacsoft.net/appcleaner
#
brew install --cask appcleaner

#
# AutoMute
#
# Mute your laptop when your headphones disconnect
#
# https://yoni.ninja/automute/
#
mas install 1118136179

#
# Bearded Spice
#
# https://github.com/beardedspice/beardedspice
#
# brew install --cask beardedspice

#
# Captin
#
# https://captin.mystrikingly.com/
#
brew install --cask captin

#
# Chrome
#
# https://www.google.com/chrome
#
brew install cask google-chrome

#
# DaisyDisk
#
# https://daisydiskapp.com
#
brew install --cask daisydisk

#
# Disk Drill
#
# https://www.cleverfiles.com/
#
brew install --cask disk-drill

#
# Keycastr
#
# https://github.com/keycastr/keycastr
#
# brew install --cask keycastr

#
# Loopback
#
# https://rogueamoeba.com/loopback
#
# brew install --cask loopback

#
# Muzzle
#
# https://muzzleapp.com
#
brew install --cask muzzle

#
# NordVPN
#
# https://nordvpn.com
#
brew install --cask nordvpn

#
# Parcel
#
# https://parcelapp.net
#
# mas install 639968404
# loginitems -a Parcel -s false

#
# Silicon
#
# https://github.com/DigiDNA/Silicon
#
brew install --cask silicon

#
# Spotica Menu
#
# A Spotify menubar control
#
# https://spoti.ca
#
mas install 570549457

#
# The Unarchiver
#
# https://theunarchiver.com
#
brew install --cask the-unarchiver

#
# WiFi Explorer Lite
#
# https://www.intuitibits.com/products/wifi-explorer
#
mas install 1408727408


##########################
# Restore configurations #
##########################

brew install mackup
mackup restore --force

#########
#       #
# Fonts #
#       #
#########

brew install --cask font-fira-sans
brew install --cask font-fira-code
brew install --cask font-arial
brew install --cask font-open-sans
brew install --cask font-dancing-script
brew install --cask font-dejavu
brew install --cask font-roboto
brew install --cask font-roboto-condensed
brew install --cask font-hack
brew install --cask font-pacifico
brew install --cask font-leckerli-one
brew install --cask font-gidole
brew install --cask font-fira-mono
brew install --cask font-blackout
brew install --cask font-alex-brush
brew install --cask font-fira-code-nerd-font #use with Starfish
brew install --cask font-hack-nerd-font #use with lscolor
brew install --cask font-caveat-brush
brew install --cask font-archivo-narrow


##################################################
#                                                #
# File Type Default App                          #
#                                                #
# Find the app bundle identifier                 #
# mdls /Applications/Photos.app | grep kMDItemCF #
#                                                #
# Find the Uniform Type Identifiers              #
# mdls -name kMDItemContentTypeTree ~/init.lua   #
#                                                #
##################################################

duti -s com.apple.Preview com.nikon.raw-image all #NEF
duti -s com.apple.Preview com.adobe.pdf all #pdf
duti -s com.apple.Preview org.openxmlformats.presentationml.presentation all #PPTX
duti -s com.apple.Preview public.standard-tesselated-geometry-format all #3d CAD


#########
#       #
# Games #
#       #
#########

#
# Epic Games
#
# https://www.epicgames.com
#
brew install --cask epic-games

#
# Epic Games
#
# https://www.leagueoflegends.com
#
brew install --cask league-of-legends

###################
#                 #
# Dock apps order #
#                 #
###################

# dockutil --move 'Brave Browser' --position end --allhomes
# dockutil --move 'Evernote' --position end --allhomes
# dockutil --move 'Todoist' --position end --allhomes
dockutil --move 'Slack' --position end --allhomes
dockutil --move 'Spotify' --position end --allhomes
dockutil --move 'Terminal' --position end --allhomes
