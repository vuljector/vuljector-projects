# vuljector-projects

Dataset of OSS-Fuzz projects with injected vulnerabilities, built using VulJector.

## Structure

```text
vuljector-projects/
│
└── <project>/
    ├── project.json
    ├── setup/
    │   ├── Dockerfile
    │   ├── build.sh
    │   ├── project.yaml
    │   └── ...
    ├── unit_tests/
    │   ├── test.sh                   # standardized unit-test entrypoint
    │   └── parse_results.py          # output normalizer → {"passed": N, "failed": M}
    ├── vulnerabilities/
    │   └── vulnerability_N/
    │       ├── vulnerability_metadata.json
    │       ├── exploit_files/
    │       │   └── exploit.sh
    │       └── snapshot/
    │           ├── files/
    │           └── manifest.json
    └── debug/
        ├── success/
        │   └── vulnerability_N/
        └── failed/
            └── vulnerability_N/
```

## `project.json`

```json
{
  "project": "flask",
  "main_repo_url": "https://github.com/pallets/flask",
  "target_dir": "flask",
  "secure_base_commit": "<sha>",
  "unit_tests": {
    "enabled": true,
    "expected_passing_count": 489
  }
}
```

| Field | Description |
|-------|-------------|
| `project` | OSS-Fuzz project name |
| `main_repo_url` | Upstream GitHub repository URL |
| `target_dir` | Directory name inside container (`/src/<target_dir>`) |
| `secure_base_commit` | Commit SHA of the secure baseline |
| `unit_tests.enabled` | Whether unit tests are configured for this project |
| `unit_tests.expected_passing_count` | Baseline passing-test count |

## Unit test scripts

Each `unit_tests/test.sh` builds and runs the project's native test suite inside
the Docker container, piping output through `parse_results.py` to produce a JSON
summary as the last line:

```bash
<test_command> 2>&1 | python3 /src/unit_tests/parse_results.py --framework <framework>
# Output: {"passed": 489, "failed": 0}
```

Supported frameworks: `pytest`, `cargo`, `gotest`, `ctest`, `maven`, `gradle`,
`jest`, `tap`, `phptest`, `btest`, `gtest`, `meson`, `unittest`, `generic`.

A project is considered **PASS** if `passed == expected_passing_count` and `passed >= 4`.

## `vulnerability_metadata.json`

| Field | Description |
|-------|-------------|
| `schema_version` | Schema version (`v2`) |
| `id` | Vulnerability identifier (e.g. `vulnerability_0`) |
| `project` | Project name |
| `cwe_group` | CWE group selected for injection |
| `cwe_id` | CWE id selected for injection |
| `selection_run_id` | Run id of selection phase |
| `injection_run_id` | Run id of injection phase |
| `snapshot_manifest` | Relative path to `snapshot/manifest.json` |
| `snapshot_links` | Mapping from `repo_path` to `snapshot_path` |
| `exploit_dir` | Relative path to `exploit_files/` |
| `secure_base_commit` | Secure baseline commit |
| `complexity` | Optional complexity value |

## Snapshot format

`snapshot/manifest.json` stores changed files and how they map back to repository paths.
`snapshot/files/` stores only modified/added files using repository-relative paths.
