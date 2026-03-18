# vuljector-projects

Dataset of OSS-Fuzz projects with injected vulnerabilities, built using Vuljector.

## Structure

```text
vuljector-projects/
│
└── <project>/
    ├── project.json
    ├── setup/
    │   ├── Dockerfile
    │   ├── project.yaml
    │   └── ...
    ├── unit_tests/                  # optional
    │   └── test.sh                  # optional standardized unit-test entrypoint
    ├── vulnerabilities/             # success artifacts for non-debug runs
    │   └── vulnerability_N/
    │       ├── vulnerability_metadata.json
    │       ├── exploit_files/
    │       │   └── exploit.sh
    │       └── snapshot/
    │           ├── files/
    │           └── manifest.json
    └── debug/                       # only when debug=true in injection run
        ├── success/
        │   └── vulnerability_N/
        └── failed/
            └── vulnerability_N/
```

## `project.json` fields

| Field | Description |
|-------|-------------|
| `schema_version` | Schema version (V2 uses `v2`) |
| `project` | Project name |
| `source.oss_fuzz_project_dir` | OSS-Fuzz source project path |
| `repos.original_main_repo` | Upstream repository URL |
| `repos.forked_main_repo` | Forked repository URL |
| `target_dir` | Repo directory inside container |
| `secure_base_commit` | Secure baseline commit used for reset/verification |
| `unit_tests.enabled` (optional) | Whether unit tests are part of verification |
| `unit_tests.script` (optional) | Script path, usually `unit_tests/test.sh` |
| `unit_tests.expected_passing_count` (optional) | Baseline passing-test count captured in setup phase |

## `vulnerability_metadata.json` fields

| Field | Description |
|-------|-------------|
| `schema_version` | Schema version (`v2`) |
| `id` | Vulnerability identifier (e.g. `vulnerability_0`) |
| `project` | Project name |
| `cwe_group` | CWE group selected for injection |
| `cwe_id` | CWE id selected for injection |
| `selection_run_id` | Run id of selection phase used by this injection |
| `injection_run_id` | Run id of injection phase that produced this artifact |
| `snapshot_manifest` | Relative path to snapshot manifest (`snapshot/manifest.json`) |
| `snapshot_links` | Mapping from `repo_path` to saved `snapshot_path` |
| `exploit_dir` | Relative path to exploit files directory (`exploit_files`) |
| `secure_base_commit` | Secure baseline commit |
| `complexity` | Optional complexity value |

## Snapshot format

`snapshot/manifest.json` stores changed files and how they map back to repository paths.
`snapshot/files/` stores only modified/added files using repository-relative paths.
