# vuljector-projects

Real OSS-Fuzz C/C++ projects with injected, PoV-validated vulnerabilities, built with VulJector.

## Layout

```text
<project>/
├── project.json                        # metadata + secure_base_commit
├── setup/                              # Dockerfile, build.sh, project.yaml (OSS-Fuzz build)
├── unit_tests/                         # test.sh + parse_results.py
└── vulnerabilities/
    └── vulnerability_<PIPELINE>_<N>/
        ├── inject_vulnerability.diff    # apply → introduces the vulnerability
        ├── vulnerability_metadata.json  # id, cwe_id, secure_base_commit, ...
        ├── sanitizer_report.txt         # the crash/divergence proving it triggers
        ├── vuln_description.md           # natural-language bug report
        └── exploit_files/
            └── exploit.sh               # proof-of-vulnerability entrypoint
```

`<PIPELINE>` is the injection pipeline: `FZ` (fuzzer-guided), `WF_RAG` and `WF_LLM` (agentic).

## Key files

- **`inject_vulnerability.diff`** — applying it to the project at `secure_base_commit` *introduces* the vulnerability; reverting it is the ground-truth fix.
- **`exploit_files/exploit.sh`** — runs the proof-of-vulnerability against the built target.
- **`sanitizer_report.txt`** — the sanitizer crash (or, for non-memory bugs, the behavioral divergence) that fires on the vulnerable build and is silent on the secure build. Present for most samples.

## `project.json`

| Field | Description |
|-------|-------------|
| `project` | OSS-Fuzz project name |
| `language` | `c` or `c++` |
| `main_repo_url` | upstream repository |
| `secure_base_commit` | 40-char SHA of the secure baseline (authoritative base for the diff) |
| `dockerhub_image` | prebuilt `vuljector/<project>:setup` image |
| `unit_tests.expected_passing_count` | baseline passing-test count |

## Reproduce

Pull `dockerhub_image` (or build `setup/`), check out `secure_base_commit`, apply `inject_vulnerability.diff`, rebuild, and run `exploit_files/exploit.sh`: the sanitizer fires on the vulnerable build and stays silent on the secure build.
