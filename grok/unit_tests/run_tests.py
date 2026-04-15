#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import inspect
import itertools
import sys
import tempfile
import types
from pathlib import Path


class Skip(Exception):
    pass


class _Mark:
    def skipif(self, *args, **kwargs):
        def deco(obj):
            return obj
        return deco

    def parametrize(self, argnames, argvalues):
        names = [n.strip() for n in argnames.split(",")] if isinstance(argnames, str) else list(argnames)

        def deco(func):
            func.__parametrize__ = (names, list(argvalues))
            return func

        return deco

    def __getattr__(self, _name):
        def deco(obj=None, **_kwargs):
            if obj is None:
                def inner(x):
                    return x
                return inner
            return obj
        return deco


def _install_pytest_shim():
    pytest = types.ModuleType("pytest")
    pytest.mark = _Mark()
    pytest.Skip = Skip

    def fixture(*_args, **_kwargs):
        def deco(obj):
            return obj
        return deco

    def skip(reason=""):
        raise Skip(reason)

    pytest.fixture = fixture
    pytest.skip = skip
    sys.modules["pytest"] = pytest


class TmpPathFactory:
    def __init__(self):
        self.root = Path(tempfile.mkdtemp(prefix="grok-tests-"))
        self.count = 0

    def mktemp(self, name):
        self.count += 1
        path = self.root / f"{self.count:02d}_{name}"
        path.mkdir(parents=True, exist_ok=True)
        return path


class TmpPath:
    def __init__(self, path):
        self._path = Path(path)

    def __truediv__(self, other):
        return self._path / other

    def __fspath__(self):
        return str(self._path)

    def __str__(self):
        return str(self._path)


class MonkeyPatch:
    def setenv(self, *_args, **_kwargs):
        pass


def _load_module(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def _expand_parametrize(fn, kwargs):
    params = getattr(fn, "__parametrize__", None)
    if not params:
        yield kwargs
        return
    names, values = params
    for vals in values:
        if len(names) == 1 and not isinstance(vals, (tuple, list)):
            vals = (vals,)
        case = dict(kwargs)
        case.update(dict(zip(names, vals)))
        yield case


def _run_method(meth, kwargs):
    passed = failed = skipped = 0
    for case in _expand_parametrize(meth, kwargs):
        try:
            meth(**case)
            passed += 1
        except Skip:
            skipped += 1
        except Exception as exc:
            failed += 1
            print(f"[FAIL] {meth.__qualname__}: {type(exc).__name__}: {exc}", file=sys.stderr)
    return passed, failed, skipped


def _run_basic_module(module):
    passed = failed = skipped = 0
    for obj_name, obj in vars(module).items():
        if not inspect.isclass(obj) or not obj_name.startswith("Test"):
            continue
        inst = obj()
        for meth_name in dir(inst):
            if not meth_name.startswith("test_"):
                continue
            meth = getattr(inst, meth_name)
            sig = inspect.signature(meth)
            kwargs = {}
            for pname in sig.parameters:
                if pname == "tmp_path":
                    kwargs[pname] = TmpPath(tempfile.mkdtemp(prefix="grok-tmp-"))
                elif pname == "tmp_path_factory":
                    kwargs[pname] = TmpPathFactory()
                elif pname == "monkeypatch":
                    kwargs[pname] = MonkeyPatch()
            p, f, s = _run_method(meth, kwargs)
            passed += p
            failed += f
            skipped += s
    return passed, failed, skipped


def _fixture_value(module, name, cls=None):
    tpf = TmpPathFactory()
    if name == "jp2_file":
        return [module.jp2_file(types.SimpleNamespace(param=p), tpf) for p in module.ASYNC_CONFIGS]
    if name == "jp2_file_window":
        return [module.jp2_file_window(types.SimpleNamespace(param=p), tpf) for p in module.WINDOW_CONFIGS]
    if name == "jp2_file_swath":
        return [module.jp2_file_swath(types.SimpleNamespace(param=p), tpf) for p in module.SWATH_CONFIGS]
    if name == "rgb_jp2_file":
        return [module.rgb_jp2_file(types.SimpleNamespace(param=p), tpf) for p in module.RGB_CONFIGS]
    if name == "large_grid_jp2":
        return [module.large_grid_jp2(types.SimpleNamespace(param=p), tpf) for p in module.LARGE_GRID_CONFIGS]
    if name == "swath_buf_jp2":
        return [module.swath_buf_jp2(types.SimpleNamespace(param=p), tpf) for p in module.SWATH_BUF_CONFIGS]
    if cls is not None:
        inst = cls()
        return getattr(inst, name)(tpf)
    raise KeyError(name)


def _run_async_module(module):
    passed = failed = skipped = 0
    fixture_lists = {
        "jp2_file": _fixture_value(module, "jp2_file"),
        "jp2_file_window": _fixture_value(module, "jp2_file_window"),
        "jp2_file_swath": _fixture_value(module, "jp2_file_swath"),
        "rgb_jp2_file": _fixture_value(module, "rgb_jp2_file"),
        "large_grid_jp2": _fixture_value(module, "large_grid_jp2"),
        "swath_buf_jp2": _fixture_value(module, "swath_buf_jp2"),
    }

    class_fixtures = {
        "multi_tile_jp2": "TestDecompressTileByIndex",
        "gray_jp2_multi": "TestSwathBufTypedOutput",
        "rgb_jp2_multi": "TestSwathBufBandMap",
        "gray_jp2": "TestSwathBufAlphaPromotion",
    }

    for cls_name, cls in vars(module).items():
        if not inspect.isclass(cls) or not cls_name.startswith("Test"):
            continue
        inst = cls()
        for meth_name in dir(inst):
            if not meth_name.startswith("test_"):
                continue
            meth = getattr(inst, meth_name)
            sig = inspect.signature(meth)
            params = list(sig.parameters)
            fixture_names = [p for p in params if p not in {"tmp_path", "monkeypatch"}]
            if not fixture_names:
                kwargs = {}
                for pname in params:
                    if pname == "tmp_path":
                        kwargs[pname] = TmpPath(tempfile.mkdtemp(prefix="grok-tmp-"))
                    elif pname == "monkeypatch":
                        kwargs[pname] = MonkeyPatch()
                p, f, s = _run_method(meth, kwargs)
                passed += p
                failed += f
                skipped += s
                continue

            lists = []
            for fname in fixture_names:
                if fname in fixture_lists:
                    lists.append([(fname, value) for value in fixture_lists[fname]])
                elif fname in class_fixtures and class_fixtures[fname] == cls_name:
                    lists.append([(fname, _fixture_value(module, fname, cls=cls))])
                else:
                    raise RuntimeError(f"Unhandled fixture {fname} in {meth.__qualname__}")

            for combo in itertools.product(*lists):
                combo_map = dict(combo)
                kwargs = {}
                for pname in params:
                    if pname == "tmp_path":
                        kwargs[pname] = TmpPath(tempfile.mkdtemp(prefix="grok-tmp-"))
                    elif pname == "monkeypatch":
                        kwargs[pname] = MonkeyPatch()
                    else:
                        kwargs[pname] = combo_map[pname]
                p, f, s = _run_method(meth, kwargs)
                passed += p
                failed += f
                skipped += s
    return passed, failed, skipped


def main():
    _install_pytest_shim()
    root = Path(__file__).resolve().parent
    sys.path.insert(0, str(root))
    import grok_core  # noqa: F401
    import grok_codec  # noqa: F401

    modules = [
        "tests/python/test_core.py",
        "tests/python/test_errors.py",
        "tests/python/test_jp2_metadata.py",
        "tests/python/test_roundtrip.py",
        "tests/python/test_codec.py",
        "tests/python/test_codec_bindings.py",
        "tests/python/test_async_decompress.py",
    ]

    passed = failed = skipped = 0
    for idx, rel in enumerate(modules):
        module = _load_module(str((Path("/src/grok") / rel)), f"grok_tests_{idx}")
        if rel.endswith("test_async_decompress.py"):
            p, f, s = _run_async_module(module)
        else:
            p, f, s = _run_basic_module(module)
        passed += p
        failed += f
        skipped += s

    print(f"{passed} passed, {failed} failed, {skipped} skipped")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
