#!/usr/bin/env bash
# scripts/aws-session.sh
# Refresh AWS STS session token (valid 12 hours)

# Usage Option 1: Source this script directly
#   source scripts/aws-session.sh
#
# Usage Option 2: Add refresh_aws_session() function to ~/.bashrc
#   See README.md for function definition
#
# Usage Option 3: CI/CD pipelines
#   bash scripts/aws-session.sh
#   source /tmp/aws-env.sh

set -euo pipefail

DURATION=${1:-43200}  # Default: 12 hours (43200 seconds)
PROFILE=${2:-cloudmart_user}

echo "🔐 Requesting new STS session token for profile: ${PROFILE}"
echo "⏱️  Duration: ${DURATION} seconds ($((DURATION / 3600)) hours)"

# Request session token
aws sts get-session-token \
  --duration-seconds "$DURATION" \
  --profile "$PROFILE" \
  > /tmp/session.json

# Verify session.json was created successfully
if [ ! -f /tmp/session.json ]; then
    echo "❌ Error: Failed to create session token file"
    return 1 2>/dev/null || exit 1
fi

# Extract credentials and export them
export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' /tmp/session.json)
export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' /tmp/session.json)
export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' /tmp/session.json)
export AWS_DEFAULT_REGION=eu-central-1

# Verify credentials were extracted
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ "$AWS_ACCESS_KEY_ID" = "null" ]; then
    echo "❌ Error: Failed to extract credentials from session token"
    return 1 2>/dev/null || exit 1
fi

echo ""
echo "✅ Session credentials exported to environment"

# Optional: Export to a file for CI/CD usage
cat > /tmp/aws-env.sh << EOF
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
export AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
EOF

echo "💡 Credentials exported to environment and saved to /tmp/aws-env.sh"

echo "📅 Session valid until:"
jq -r '.Credentials.Expiration' /tmp/session.json

echo ""
echo "💡 To persist for this terminal session, these variables are now active:"
echo "   AWS_ACCESS_KEY_ID (set)"
echo "   AWS_SECRET_ACCESS_KEY (set)"
echo "   AWS_SESSION_TOKEN (set)"
echo "   AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"