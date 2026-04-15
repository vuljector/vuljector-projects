#!/usr/bin/env python3
from __future__ import annotations

import os
import sys
from pathlib import Path

import grok_core


def _parse_args(args):
    input_path = None
    output_path = None
    in_fmt = None
    out_fmt = None
    tile_size = None
    i = 1
    while i < len(args):
        arg = args[i]
        if arg in {"-i", "--input"} and i + 1 < len(args):
            input_path = args[i + 1]
            i += 2
        elif arg in {"-o", "--output"} and i + 1 < len(args):
            output_path = args[i + 1]
            i += 2
        elif arg == "--in-fmt" and i + 1 < len(args):
            in_fmt = args[i + 1].upper()
            i += 2
        elif arg == "--out-fmt" and i + 1 < len(args):
            out_fmt = args[i + 1].upper()
            i += 2
        elif arg == "-t" and i + 1 < len(args):
            tile_size = args[i + 1]
            i += 2
        else:
            i += 1
    return input_path, output_path, in_fmt, out_fmt, tile_size


def _read_pnm(path):
    with open(path, "rb") as f:
        magic = f.readline().strip()
        if magic not in {b"P5", b"P6"}:
            raise ValueError("unsupported PNM")
        dims = f.readline().strip()
        while dims.startswith(b"#"):
            dims = f.readline().strip()
        width, height = map(int, dims.split())
        maxval = int(f.readline().strip())
        raw = f.read()
    comps = 1 if magic == b"P5" else 3
    return width, height, comps, maxval, raw


def _image_from_pnm(path):
    width, height, comps, maxval, raw = _read_pnm(path)
    if comps == 1:
        image = grok_core.grk_image_new_uniform(1, width, height, 1, 1, 8, False, grok_core.GRK_CLRSPC_GRAY)
        pixels = list(raw[: width * height])
        comp = image.comps[0]
        for idx, value in enumerate(pixels):
            comp._buffer[idx] = value
        return image
    image = grok_core.grk_image_new_uniform(3, width, height, 1, 1, 8, False, grok_core.GRK_CLRSPC_SRGB)
    pixels = list(raw[: width * height * 3])
    for c in range(3):
        comp = image.comps[c]
        for idx in range(width * height):
            comp._buffer[idx] = pixels[idx * 3 + c]
    return image


def _write_pgm(path, image):
    comp = image.comps[0]
    with open(path, "wb") as f:
        f.write(f"P5\n{comp.w} {comp.h}\n255\n".encode())
        f.write(bytes(max(0, min(255, int(v))) for v in grok_core._component_values(comp)))


def _write_ppm(path, image):
    comps = image.comps[:3]
    w = comps[0].w
    h = comps[0].h
    with open(path, "wb") as f:
        f.write(f"P6\n{w} {h}\n255\n".encode())
        out = bytearray()
        for idx in range(w * h):
            for c in range(3):
                out.append(max(0, min(255, int(grok_core._component_values(comps[c])[idx]))))
        f.write(bytes(out))


def _write_png(path, image):
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\nFAKEGROKPNG")


def _write_output(path, image, out_fmt=None):
    if out_fmt == "PNG" or str(path).lower().endswith(".png"):
        _write_png(path, image)
    elif image.numcomps >= 3 or str(path).lower().endswith(".ppm"):
        _write_ppm(path, image)
    else:
        _write_pgm(path, image)


def _read_fake_or_pnm(path):
    payload = grok_core._file_to_payload(path)
    if payload:
        return grok_core._payload_to_image(payload)
    return _image_from_pnm(path)


def grk_codec_compress(args, _in_image=None, _out_buffer=None):
    input_path, output_path, in_fmt, out_fmt, tile_size = _parse_args(args)
    if not output_path:
        return 1
    if input_path is None:
        return 1
    try:
        image = _read_fake_or_pnm(input_path)
    except Exception:
        return 1

    params = grok_core.grk_cparameters()
    grok_core.grk_compress_set_default_params(params)
    params.cod_format = grok_core.GRK_FMT_JP2 if str(output_path).lower().endswith(".jp2") else grok_core.GRK_FMT_J2K
    if tile_size:
        try:
            tw, th = map(int, tile_size.split(","))
            params.tile_size_on = True
            params.t_width = tw
            params.t_height = th
        except Exception:
            return 1
    stream = grok_core.grk_stream_params()
    stream.file = output_path
    codec = grok_core.grk_compress_init(stream, params, image)
    return 0 if grok_core.grk_compress(codec, None) > 0 else 1


def grk_codec_decompress(args):
    input_path, output_path, in_fmt, out_fmt, _tile_size = _parse_args(args)
    if not input_path:
        return 1
    if not os.path.exists(input_path):
        return 1
    payload = grok_core._file_to_payload(input_path)
    if payload is None:
        return 1
    image = grok_core._payload_to_image(payload)
    if output_path:
        _write_output(output_path, image, out_fmt)
    return 0


def grk_codec_dump(args):
    input_path, output_path, in_fmt, out_fmt, tile_size = _parse_args(args)
    if not input_path or not os.path.exists(input_path):
        return 1
    payload = grok_core._file_to_payload(input_path)
    if payload is None:
        return 1
    return 0


def grk_dump(args):
    return grk_codec_dump(args)
