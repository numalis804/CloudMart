# Helper Scripts
Automation scripts for CloudMart project management.

## AWS Session Management

### Method 1: Shell Function (Recommended for Development)
Add to `~/.bashrc` or `~/.zshrc`:
```bash
refresh_aws_session() {
    # [function code here]
}
```
Then use: `refresh_aws_session`

### Method 2: Standalone Script (For CI/CD)
```bash
source scripts/aws-session.sh
```

Session tokens are valid for 12 hours.