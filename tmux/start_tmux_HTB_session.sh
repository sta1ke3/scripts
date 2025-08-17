#!/bin/bash

# Creating tmux session named "HTB". add this script path to ~/.zshrc or ~/.bashrc

SESSION="HTB"

# Check if the session does NOT exist
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "Tmux session '$SESSION' does not exist. Creating..."

    tmux new-session -d -s "$SESSION" -n VPN

    tmux new-window -t "$SESSION":1 -n Scan
    tmux new-window -t "$SESSION":2 -n Main
    tmux new-window -t "$SESSION":3 -n Tools

    # Optional: Start VPN in the first window
    tmux send-keys -t "$SESSION":0 'sudo openvpn $HOME/HackTheBox/vpn/academy-regular.ovpn' C-m

    tmux send-keys -t "$SESSION":3 "cd $HOME/Tools" C-m
fi


