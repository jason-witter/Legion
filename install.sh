#!/usr/bin/env bash
# Legion install script

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
BACKUP_DIR="$CLAUDE_DIR/backup-$(date +%Y%m%d-%H%M%S)"
BACKED_UP=false

backup_file() {
    local src="$1"
    local label="$2"
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
    fi
    cp -a "$src" "$BACKUP_DIR/"
    echo "  ↳ backed up $label to $BACKUP_DIR/"
    BACKED_UP=true
}

echo ""
echo "Legion — Mob Programming Orchestration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

mkdir -p "$CLAUDE_DIR"

# --- Pre-flight: detect existing configuration ---
EXISTING_FILES=()
[[ -f "$CLAUDE_DIR/CLAUDE.md" ]] && EXISTING_FILES+=("CLAUDE.md")
[[ -d "$CLAUDE_DIR/agents" && ! -L "$CLAUDE_DIR/agents" ]] && EXISTING_FILES+=("agents/")
[[ -d "$CLAUDE_DIR/rules" && ! -L "$CLAUDE_DIR/rules" ]] && EXISTING_FILES+=("rules/")

if [[ ${#EXISTING_FILES[@]} -gt 0 ]]; then
    echo "Existing Claude Code configuration detected:"
    for f in "${EXISTING_FILES[@]}"; do
        echo "  • ~/.claude/$f"
    done
    echo ""
    echo "Legion needs to replace these. The install will back them up"
    echo "to ~/.claude/backup-*/ before making any changes."
    echo ""
    read -rp "Continue? [y/N] " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Aborted."
        exit 0
    fi
    echo ""
fi

# --- Friday ---
FRIDAY_SRC="$REPO_DIR/install/friday-claude.md"
FRIDAY_DEST="$CLAUDE_DIR/CLAUDE.md"

if [[ -f "$FRIDAY_DEST" ]]; then
    backup_file "$FRIDAY_DEST" "CLAUDE.md"
fi

echo "Friday needs to know who to work for."
echo ""
read -rp "  What should Friday call you? " USER_NAME
if [[ -z "$USER_NAME" ]]; then
    USER_NAME="Boss"
fi
echo ""

sed "s/{{USER_NAME}}/$USER_NAME/g" "$FRIDAY_SRC" > "$FRIDAY_DEST"
echo "✓ Friday is ready. Working for $USER_NAME."

# --- Configure additionalDirectories ---
echo ""
echo "Registering Legion with Claude Code..."

if [[ -f "$SETTINGS_FILE" ]]; then
    if grep -q "$REPO_DIR" "$SETTINGS_FILE"; then
        echo "  ~ Legion already registered in ~/.claude/settings.json"
    else
        echo "  ! ~/.claude/settings.json exists but Legion isn't registered."
        echo "    Add these to the file:"
        echo ""
        echo "    In the top-level object:"
        echo "      \"env\": { \"CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD\": \"1\" }"
        echo ""
        echo "    In the permissions object:"
        echo "      \"additionalDirectories\": [\"$REPO_DIR\"]"
        echo ""
        echo "    For PreToolUse hooks, see docs/hooks.md for the configuration block."
    fi
else
    cat > "$SETTINGS_FILE" << EOF
{
  "env": {
    "CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD": "1"
  },
  "permissions": {
    "additionalDirectories": [
      "$REPO_DIR"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$REPO_DIR/hooks/block-chained-commands.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$REPO_DIR/hooks/block-git-c-flag.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$REPO_DIR/hooks/block-bash-search.sh"
          }
        ]
      }
    ]
  }
}
EOF
    echo "  ✓ created ~/.claude/settings.json with Legion registered"
fi


# --- Symlinks for agents and rules ---
#
# Claude Code does NOT load agents from additionalDirectories — agents must live
# in ~/.claude/agents/ to be discoverable as invocable subagents.
#
# Additionally, additionalDirectories does NOT propagate rules/ to Task
# subagents — rules only reach subagents when symlinked into ~/.claude/rules/.
#
# Protocols stay in protocols/ and are read explicitly by agents via file
# reads, so they don't need this treatment.
echo ""
echo "Setting up agent and rules symlinks..."

AGENTS_LINK="$CLAUDE_DIR/agents"
AGENTS_TARGET="$REPO_DIR/agents"

if [[ -L "$AGENTS_LINK" ]]; then
    CURRENT_TARGET="$(readlink "$AGENTS_LINK")"
    if [[ "$CURRENT_TARGET" == "$AGENTS_TARGET" ]]; then
        echo "  ~ ~/.claude/agents/ symlink already points to $AGENTS_TARGET"
    else
        echo "  ! ~/.claude/agents/ symlink exists but points elsewhere ($CURRENT_TARGET)"
        echo "    Update it manually: ln -sfn $AGENTS_TARGET $AGENTS_LINK"
    fi
elif [[ -d "$AGENTS_LINK" ]]; then
    backup_file "$AGENTS_LINK" "agents/"
    rm -r "$AGENTS_LINK"
    ln -s "$AGENTS_TARGET" "$AGENTS_LINK"
    echo "  ✓ linked ~/.claude/agents/ -> $AGENTS_TARGET"
else
    ln -s "$AGENTS_TARGET" "$AGENTS_LINK"
    echo "  ✓ linked ~/.claude/agents/ -> $AGENTS_TARGET"
fi

RULES_LINK="$CLAUDE_DIR/rules"
RULES_TARGET="$REPO_DIR/rules"

if [[ -L "$RULES_LINK" ]]; then
    CURRENT_TARGET="$(readlink "$RULES_LINK")"
    if [[ "$CURRENT_TARGET" == "$RULES_TARGET" ]]; then
        echo "  ~ ~/.claude/rules/ symlink already points to $RULES_TARGET"
    else
        echo "  ! ~/.claude/rules/ symlink exists but points elsewhere ($CURRENT_TARGET)"
        echo "    Update it manually: ln -sfn $RULES_TARGET $RULES_LINK"
    fi
elif [[ -d "$RULES_LINK" ]]; then
    backup_file "$RULES_LINK" "rules/"
    rm -r "$RULES_LINK"
    ln -s "$RULES_TARGET" "$RULES_LINK"
    echo "  ✓ linked ~/.claude/rules/ -> $RULES_TARGET"
else
    ln -s "$RULES_TARGET" "$RULES_LINK"
    echo "  ✓ linked ~/.claude/rules/ -> $RULES_TARGET"
fi

# --- Scratch directory structure ---
echo ""
echo "Ensuring scratch directory structure..."
mkdir -p "$REPO_DIR/scratch/output"
mkdir -p "$REPO_DIR/scratch/context"
echo "  ✓ scratch directories ready"

# --- Summary ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$BACKED_UP" == true ]]; then
    echo "Previous configuration backed up to:"
    echo "  $BACKUP_DIR"
    echo ""
fi
echo "The legion is ready. Open a new Claude Code session and say hello."
echo ""
