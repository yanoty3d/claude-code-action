#!/bin/bash
# Quick Claude Token Updater
# Usage: ./quick-update.sh

set -euo pipefail

CREDS_FILE="$HOME/.claude/.credentials.json"

# Check dependencies
for cmd in jq gh; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "❌ Required command '$cmd' not found"
        exit 1
    fi
done

if [ ! -f "$CREDS_FILE" ]; then
    echo "❌ Credentials file not found at $CREDS_FILE"
    echo "Please run 'claude' and '/login' first."
    exit 1
fi

# Check if OAuth data exists
if ! jq -e '.claudeAiOauth' "$CREDS_FILE" >/dev/null 2>&1; then
    echo "❌ No OAuth credentials found in $CREDS_FILE"
    echo "Please login with Claude Max OAuth."
    exit 1
fi

echo "🔄 Updating Claude tokens..."

# Extract and validate tokens
ACCESS_TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE")
REFRESH_TOKEN=$(jq -r '.claudeAiOauth.refreshToken // empty' "$CREDS_FILE")
EXPIRES_AT=$(jq -r '.claudeAiOauth.expiresAt // empty' "$CREDS_FILE")

if [[ -z "$ACCESS_TOKEN" || -z "$REFRESH_TOKEN" || -z "$EXPIRES_AT" ]]; then
    echo "❌ Missing required token data"
    exit 1
fi

# Update GitHub secrets
gh secret set CLAUDE_ACCESS_TOKEN --body "$ACCESS_TOKEN"
gh secret set CLAUDE_REFRESH_TOKEN --body "$REFRESH_TOKEN" 
gh secret set CLAUDE_EXPIRES_AT --body "$EXPIRES_AT"

# Show expiry date in readable format
READABLE_DATE=$(date -r $((EXPIRES_AT/1000)) '+%Y年%m月%d日 %H:%M:%S' 2>/dev/null || echo "Invalid date")
echo "✅ Tokens updated successfully!"
echo "📅 New expiry: $READABLE_DATE"

# Warn if expiring soon (within 7 days)
CURRENT_TIME=$(date +%s)
EXPIRES_TIME=$((EXPIRES_AT/1000))
DAYS_LEFT=$(((EXPIRES_TIME - CURRENT_TIME) / 86400))

if [ "$DAYS_LEFT" -lt 7 ]; then
    echo "⚠️  Warning: Token expires in $DAYS_LEFT days"
fi