# vuljector-projects

Dataset of OSS-Fuzz projects with injected vulnerabilities, built using VulJector.

## Projects

| Project | Language | Test Framework | Passing Tests |
|---------|----------|---------------|---------------|
| ansible | Python | pytest | 616 |
| assimp | C++ | gtest | 584 |
| brotli | C | ctest | 28 |
| coturn | C | ctest | 16 |
| flask | Python | pytest | 481 |
| golang | Go | gotest | 3713 |
| hcl | Go | gotest | 1926 |
| hdf5 | C | ctest | 125 |
| jackson-databind | Java | maven | 11230 |
| jsoncpp | C++ | ctest | 3 |
| linkerd2-proxy | Rust | cargo | 24 |
| openssl | C | tap | 4531 |
| php | C | phptest | 816 |
| pip | Python | pytest | 1665 |
| pygments | Python | pytest | 5167 |
| pyodbc | Python/C | pytest | 10 |
| quartz | Java | gradle | 609 |
| quickjs | C | pytest (custom) | 8 |
| rhai | Rust | cargo | 362 |
| ruby | C/Ruby | btest | 2047 |
| thrift-js | JavaScript | pytest (custom) | 23 |
| thrift-rust | Rust | cargo | 182 |
| u-root | Go | gotest | 5687 |
| wamr | C | ctest | 148 |

## Structure

```text
vuljector-projects/
│
└── <project>/
    ├── project.json
    ├── codebase/
    │   └── <repo_name>/              # git submodule of upstream repo
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

## `project.json` (schema v2)

```json
{
  "schema_version": "v2",
  "project": "flask",
  "repo": {
    "url": "https://github.com/pallets/flask",
    "branch": null
  },
  "target_dir": "flask",
  "secure_base_commit": "<sha>",
  "unit_tests": {
    "enabled": true,
    "expected_passing_count": 481
  }
}
```

| Field | Description |
|-------|-------------|
| `schema_version` | Always `"v2"` |
| `project` | OSS-Fuzz project name |
| `repo.url` | Upstream GitHub repository URL |
| `repo.branch` | Branch to track (`null` = default branch) |
| `target_dir` | Directory name inside container (`/src/<target_dir>`) |
| `secure_base_commit` | Commit SHA of the secure baseline |
| `unit_tests.enabled` | Whether unit tests are configured for this project |
| `unit_tests.expected_passing_count` | Baseline passing-test count (`null` if not enabled) |

## Unit test scripts

Each `unit_tests/test.sh` builds and runs the project's native test suite inside
the Docker container, piping output through `parse_results.py` to produce a JSON
summary as the last line:

```bash
<test_command> 2>&1 | python3 /src/unit_tests/parse_results.py --framework <framework>
# Output: {"passed": 481, "failed": 0}
```

Supported frameworks: `pytest`, `cargo`, `gotest`, `ctest`, `maven`, `gradle`,
`jest`, `tap`, `phptest`, `btest`, `gtest`, `meson`, `unittest`, `generic`.

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
