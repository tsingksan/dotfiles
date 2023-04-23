#!/bin/zsh

# Convenient proxy toggle functions
proxy() {
    local PROXY_URL="http://127.0.0.1:7890"
    # export HTTP_PROXY="$PROXY_URL"
    # export HTTPS_PROXY="$PROXY_URL"
    export ALL_PROXY="$PROXY_URL"
    # echo "🌐 Proxy Enabled: $PROXY_URL"
}

noproxy() {
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
    echo "🚫 Proxy Disabled"
}

# Auto-enable proxy if not set
# [[ -z "$HTTPS_PROXY" ]] && proxy