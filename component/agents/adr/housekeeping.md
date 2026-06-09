Run the housekeeping script to regenerate the ADR README with all ADRs grouped by status.

## Process

1. Execute the housekeeping script:
   ```
   bash adrs/recipes/housekeeping.sh
   ```

2. Verify the generated README.md is correct and complete.

The script will:
- Scan all ADR directories matching the YYYY-MM-DD-<feature> pattern
- Extract metadata (status, created date, title) from each spec.md
- Group entries by status: Implemented, Accepted, Draft, Rejected, Superseded
- Generate a properly formatted README.md with links to each ADR

If no ADRs are found, the README will be created with the workflow description only.
