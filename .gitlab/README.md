# GitLab CI/CD Setup for Haven AKS Module

This directory contains GitLab CI/CD configuration files for the Haven AKS Terraform module.

## File Structure

```text
.gitlab/
├── ci/
│   └── integration-test.yml     # Integration test jobs configuration
└── README.md                    # This file

.gitlab-ci.yml                   # Main CI configuration (in repo root)
scripts/
├── integration-test/
│   ├── integration-test.sh      # Main integration test script
│   └── demo-integration-test.sh # Demo integration test script
└── tf-plan.sh                   # Terraform plan script
```

## Configuration Files

### `.gitlab-ci.yml` (Repository Root)

Main GitLab CI/CD configuration file that includes:

- Renovate configuration for dependency updates
- Integration test configuration from `.gitlab/ci/integration-test.yml`

### `.gitlab/ci/integration-test.yml`

Contains the integration test job definitions for:

- **validate**: Quick dry-run validation on merge requests
- **test-minimal**: Full test of the minimal example
- **test-existing-infrastructure**: Full test of the existing-infrastructure example
- **test-all**: Comprehensive test of all examples
- **cleanup**: Manual cleanup job for leftover resources

## GitLab CI/CD Variables

Configure these variables in your GitLab project settings (Settings → CI/CD → Variables):

| Variable | Description | Required | Masked | Protected |
|----------|-------------|----------|---------|-----------|
| `AZURE_CLIENT_ID` | Azure service principal client ID | Yes | No | Yes |
| `AZURE_CLIENT_SECRET` | Azure service principal client secret | Yes | Yes | Yes |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | Yes | No | Yes |
| `AZURE_TENANT_ID` | Azure tenant ID | Yes | No | Yes |

## Pipeline Stages

### 1. Validate Stage

- **Trigger**: Merge requests and main branch commits
- **Duration**: ~2-3 minutes
- **Purpose**: Quick validation without deploying resources
- **Command**: `DRY_RUN=true ./integration-test.sh all`

### 2. Test Stages

- **Trigger**: Main branch commits and scheduled pipelines
- **Duration**: 1-2 hours per stage
- **Purpose**: Full integration testing with real Azure resources
- **Parallel execution**: Can run multiple test stages simultaneously

### 3. Cleanup Stage

- **Trigger**: Manual execution only
- **Purpose**: Clean up any leftover resources from failed tests
- **Safe**: Uses `|| true` to prevent pipeline failures

## Pipeline Rules

| Job | Merge Request | Main Branch | Scheduled | Manual |
|-----|---------------|-------------|-----------|---------|
| validate | ✅ | ✅ | ❌ | ❌ |
| test-minimal | ❌ | ✅ | ✅ | ❌ |
| test-existing-infrastructure | ❌ | ✅ | ✅ | ❌ |
| test-all | ❌ | ❌ | ✅ | ✅ |
| cleanup | ❌ | ❌ | ❌ | ✅ |

## Artifacts and Reports

All test jobs generate:

- **JUnit XML reports**: For test result visualization in GitLab
- **Test logs**: Detailed execution logs
- **Summary reports**: Human-readable test summaries
- **Retention**: 1 week

## Timeouts

- **validate**: Default (10 minutes)
- **test-minimal**: 2 hours
- **test-existing-infrastructure**: 2 hours
- **test-all**: 3 hours

## Customization

### Adding New Test Stages

1. Add the stage to the `stages` list in `integration-test.yml`
2. Create a new job following the existing pattern
3. Use the `.setup` anchor for common configuration

### Modifying Test Rules

Update the `rules` section in each job to change when tests run:

```yaml
rules:
  - if: '$CI_COMMIT_BRANCH == "develop"'  # Run on develop branch
  - if: '$CI_COMMIT_TAG'                  # Run on tags
  - when: manual                          # Allow manual execution
```

### Environment-Specific Configuration

Use GitLab environments to manage different Azure subscriptions:

```yaml
test-production:
  <<: *setup
  environment:
    name: production
  variables:
    AZURE_SUBSCRIPTION_ID: $PROD_AZURE_SUBSCRIPTION_ID
```

## Troubleshooting

### Common Issues

1. **Authentication failures**: Verify Azure service principal variables are set correctly
2. **Resource conflicts**: Use the cleanup job to remove leftover resources
3. **Timeout issues**: Increase timeout values for slow Azure regions
4. **Permission errors**: Ensure service principal has Contributor role

### Debugging

1. **Check logs**: View detailed logs in GitLab CI/CD job output
2. **Manual cleanup**: Run the cleanup job if resources are left behind
3. **Local testing**: Use `DRY_RUN=true` locally to validate configuration
4. **Skip destroy**: Set `SKIP_DESTROY=true` to inspect failed deployments

## Best Practices

1. **Use scheduled pipelines** for regular testing
2. **Enable merge request validation** to catch issues early
3. **Set up notifications** for failed integration tests
4. **Monitor costs** as integration tests create real Azure resources
5. **Use protected variables** for sensitive Azure credentials
6. **Regular cleanup** to prevent resource accumulation

## Getting Started

1. Configure Azure service principal with appropriate permissions
2. Set GitLab CI/CD variables in project settings
3. Commit the GitLab CI configuration to your repository
4. Create a merge request to trigger the validation pipeline
5. Schedule regular integration test runs
