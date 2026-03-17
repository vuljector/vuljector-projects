# vuljector-projects

A dataset of OSS-Fuzz projects with injected vulnerabilities, built using [VulInjector](https://github.com/AmL-Dev/VulInjector). Each project is a self-contained entry with its build environment and a set of vulnerabilities, each with a verified exploit.

## Structure

```
vuljector-projects/
│
├── <project>/
│   ├── project.json
│   ├── setup/
│   │   ├── Dockerfile
│   │   ├── project.yaml
│   │   └── (build scripts and fuzz targets from oss-fuzz)
│   └── vulnerabilities/
│       └── vulnerability_N/
│           ├── vulnerability_metadata.json
│           └── exploit_files/
│               └── exploit.sh
```

## project.json fields

| Field | Description |
|-------|-------------|
| `project` | Project name |
| `source.oss_fuzz_project_dir` | Path to the original OSS-Fuzz project directory this was derived from |
| `repos.original_main_repo` | Upstream repository URL |
| `repos.forked_main_repo` | Forked repository URL (under the `vuljector` org) |
| `target_dir` | Directory name inside the container where the main repo is cloned |
| `secure_base_commit` | Commit on the forked repo before any vulnerability was introduced |
| `verification.unit_test_cmd` (optional) | Shell command to run project tests or health checks inside the container as part of verification |

## vulnerability_metadata.json fields

| Field | Description |
|-------|-------------|
| `id` | Vulnerability identifier (e.g. `vulnerability_0`) |
| `cwe_id` | CWE identifier (e.g. `CWE-79`) |
| `cwe_category` | CWE group name |
| `description` | Optional free-text description |
| `vulnerable_commit` | Commit on the forked repo containing the injected vulnerability |
| `secure_base_commit` | Commit on the forked repo before the vulnerability was introduced |

## exploit_files/exploit.sh

Bash script that exercises the vulnerability at runtime. Exit code `0` means the exploit succeeded (vulnerability is present and triggerable), non-zero means it failed.

The exploit must:

- Succeed on the `vulnerable_commit`
- Fail on the `secure_base_commit`
