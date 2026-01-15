# Dashboard-as-Code (DaC)

This directory stores Perses dashboard definitions as code for version control and automated deployment.

## Directory Structure

```
dashboards/
├── README.md          # This file
├── system/            # System monitoring dashboards
│   ├── node-exporter.json
│   └── docker-stats.json
├── services/          # Service health dashboards
│   └── service-health.json
└── .gitkeep
```

## Workflow

### Hybrid Dashboard Management

We use a hybrid approach that balances flexibility with version control:

1. **Create/Edit in UI**: Use Perses UI at `https://dashboards.{DOMAIN}` for rapid iteration
2. **Export to Git**: When a dashboard is stable, export JSON from the UI
3. **Store in Git**: Save exported JSON files in this directory
4. **Version Control**: Commit dashboard JSON files to git for backup and versioning

### Future: Full Dashboard-as-Code

Once comfortable with the workflow, you can set up full DaC with:

- **percli CLI**: Use the Perses CLI tool to build and deploy dashboards
- **CUE SDK**: Define dashboards in CUE for better reusability and type safety
- **CI/CD**: Automatically apply dashboard changes on git push

## Exporting Dashboards from UI

1. Open the dashboard in Perses UI
2. Click the settings icon (gear) → Export
3. Copy the JSON output
4. Save to an appropriate file in this directory (e.g., `system/node-exporter.json`)
5. Commit to git

## Importing Dashboards

### Via UI

1. In Perses UI, go to Dashboards → Import
2. Paste JSON or upload file from this directory
3. Save the dashboard

### Via API/CLI (Future)

Once `percli` is set up:

```bash
percli apply -f dashboards/system/node-exporter.json
```

## Dashboard Organization

- **system/**: System-level monitoring (node exporter, docker stats, etc.)
- **services/**: Application service health dashboards
- **alerts/**: Alert-focused dashboards (future)

## Best Practices

1. Use descriptive file names matching dashboard titles
2. Group related dashboards in subdirectories
3. Export dashboards periodically to keep git in sync
4. Document dashboard purpose in commit messages
5. Review dashboard changes in git before deploying
