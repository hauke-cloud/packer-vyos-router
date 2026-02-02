# Find Server Location Action

This GitHub Action determines the optimal Hetzner Cloud server location based on a prioritized list of server types and preferred locations.

## Features

- **Prioritized server type selection**: Iterates through a list of server types (e.g., cx23, cx33, cx43) to find availability
- **Location preference**: Selects from preferred locations in priority order
- **Automatic fallback**: Falls back to first available location if preferred ones aren't available
- **Robust error handling**: Provides sensible defaults if API queries fail

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `token` | Hetzner Cloud API token | Yes | - |
| `server-types` | Comma-separated list of server types in priority order | No | `"cx23,cx33,cx43"` |
| `preferred-locations` | Comma-separated list of preferred locations in priority order | No | `"nbg1,fsn1,hel1,ash,hil"` |

## Outputs

| Output | Description |
|--------|-------------|
| `location` | Selected location for the server |
| `server-type` | Selected server type that is available |

## Usage Example

```yaml
- name: Determine available location and server type
  id: location
  uses: ./.github/actions/find-server-location
  with:
    token: ${{ secrets.HCLOUD_TOKEN }}
    server-types: "cx23,cx33,cx43"
    preferred-locations: "nbg1,fsn1,hel1,ash,hil"

- name: Use the outputs
  run: |
    echo "Selected location: ${{ steps.location.outputs.location }}"
    echo "Selected server type: ${{ steps.location.outputs.server-type }}"
```

## How It Works

1. The action queries the Hetzner Cloud API for each server type in the priority list
2. For each server type, it retrieves available locations
3. It attempts to match available locations with the preferred locations list
4. Returns the first match found (highest priority server type with a preferred location)
5. If no preferred location is available, it uses the first available location for that server type
6. If all queries fail, it falls back to the first server type and location from the input lists

## Algorithm

The selection algorithm prioritizes server types over locations:
1. Prefer the first server type (e.g., cx23) with any preferred location
2. If not available, try the next server type (e.g., cx33) with any preferred location
3. Continue until a match is found
4. Within available locations, prefer those earlier in the preferred-locations list
