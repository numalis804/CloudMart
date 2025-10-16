#!/usr/bin/env bash
# scripts/create-budget.sh
# Create AWS Budget with email alerts

set -euo pipefail

BUDGET_NAME="CloudMart-Monthly-Budget"
BUDGET_LIMIT=25  # Default $25/month
EMAIL=${1:-"emanuele.lisetti@gmail.com"}  # Replace with your email

echo "💰 Creating AWS Budget: ${BUDGET_NAME}"
echo "   Limit: $ ${BUDGET_LIMIT}/month"
echo "   Alert email: ${EMAIL}"

# Create budget configuration
cat > /tmp/budget.json << EOF
{
  "BudgetName": "${BUDGET_NAME}",
  "BudgetLimit": {
    "Amount": "${BUDGET_LIMIT}",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
EOF

# Create notifications configuration
cat > /tmp/notifications.json << EOF
[
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 1,
      "ThresholdType": "ABSOLUTE_VALUE"
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "${EMAIL}"
      }
    ]
  },
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 50,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "${EMAIL}"
      }
    ]
  },
  {
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 100,
      "ThresholdType": "PERCENTAGE"
    },
    "Subscribers": [
      {
        "SubscriptionType": "EMAIL",
        "Address": "${EMAIL}"
      }
    ]
  }
]
EOF

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create budget
aws budgets create-budget \
  --account-id ${ACCOUNT_ID} \
  --budget file:///tmp/budget.json \
  --notifications-with-subscribers file:///tmp/notifications.json

echo "✅ Budget created successfully"
echo "📧 Check your email (${EMAIL}) to confirm subscription"

# Cleanup
rm /tmp/budget.json /tmp/notifications.json
