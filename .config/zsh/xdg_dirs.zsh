#!/bin/zsh

# Tool-specific XDG configurations
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export GOPATH="$XDG_DATA_HOME/go"
export GOBIN="$XDG_DATA_HOME/go/bin"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export RBENV_ROOT="$XDG_DATA_HOME/rbenv"
export BUN_INSTALL="$XDG_DATA_HOME/bun"
export N_PREFIX="$XDG_DATA_HOME/n"
export _Z_DATA="$XDG_DATA_HOME/z"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
alias yarn='yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config"'
export PSQLRC="$XDG_CONFIG_HOME/pg/psqlrc"
export PSQL_HISTORY="$XDG_STATE_HOME/psql_history"
export PGPASSFILE="$XDG_CONFIG_HOME/pg/pgpass"
export PGSERVICEFILE="$XDG_CONFIG_HOME/pg/pg_service.conf"



export PNPM_HOME="$HOME/.local/share/pnpm"