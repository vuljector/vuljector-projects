#!/usr/bin/env python3
from __future__ import annotations

import ctypes
import json
import os
import pickle
import struct
import zlib
from array import array
from dataclasses import dataclass
from pathlib import Path

GRK_CLRSPC_UNKNOWN = 0
GRK_CLRSPC_SRGB = 2
GRK_CLRSPC_GRAY = 3
GRK_CLRSPC_SYCC = 4

GRK_FMT_UNK = 0
GRK_FMT_J2K = 1
GRK_FMT_JP2 = 2

GRK_LRCP = 0
GRK_RLCP = 1
GRK_RPCL = 2
GRK_PCRL = 3
GRK_CPRL = 4

GRK_TILE_CACHE_NONE = 0
GRK_TILE_CACHE_IMAGE = 1
GRK_TILE_CACHE_ALL = 2


class _Handle:
    pass


class grk_image_comp:
    def __init__(self):
        self.dx = 1
        self.dy = 1
        self.w = 0
        self.h = 0
        self.prec = 8
        self.sgnd = False
        self.stride = 0
        self.data = 0
        self._buffer = None


class grk_image_meta:
    def __init__(self):
        self._geotiff = None
        self._ipr = None
        self._xmp = None
        self._iptc = None

    def set_geotiff(self, data):
        self._geotiff = None if data is None else bytes(data)

    def set_ipr(self, data):
        self._ipr = None if data is None else bytes(data)

    def set_xmp(self, data):
        self._xmp = None if data is None else bytes(data)

    def set_iptc(self, data):
        self._iptc = None if data is None else bytes(data)

    def get_geotiff(self):
        return self._geotiff

    def get_ipr(self):
        return self._ipr

    def get_xmp(self):
        return self._xmp

    def get_iptc(self):
        return self._iptc

    def to_dict(self):
        return {
            "geotiff": self._geotiff,
            "ipr": self._ipr,
            "xmp": self._xmp,
            "iptc": self._iptc,
        }

    @classmethod
    def from_dict(cls, data):
        meta = cls()
        if not data:
            return meta
        meta._geotiff = data.get("geotiff")
        meta._ipr = data.get("ipr")
        meta._xmp = data.get("xmp")
        meta._iptc = data.get("iptc")
        return meta


class grk_image:
    def __init__(self, numcomps=0):
        self.numcomps = numcomps
        self.comps = [grk_image_comp() for _ in range(numcomps)]
        self.meta = None
        self.obj = _Handle()
        self.x0 = 0
        self.y0 = 0
        self.x1 = 0
        self.y1 = 0


class grk_cparameters:
    def __init__(self):
        self.numresolution = 6
        self.cblockw_init = 64
        self.cblockh_init = 64
        self.prog_order = GRK_LRCP
        self.irreversible = False
        self.cod_format = GRK_FMT_J2K
        self.numlayers = 1
        self.allocation_by_rate_distortion = False
        self.tile_size_on = False
        self.t_width = 0
        self.t_height = 0
        self.layers = []


class _DecompressCoreParams:
    def __init__(self):
        self.reduce = 0
        self.tile_cache_strategy = GRK_TILE_CACHE_NONE
        self.skip_allocate_composite = False


class grk_decompress_parameters:
    def __init__(self):
        self.core = _DecompressCoreParams()
        self.asynchronous = False
        self.simulate_synchronous = False
        self.dw_x0 = 0.0
        self.dw_y0 = 0.0
        self.dw_x1 = 0.0
        self.dw_y1 = 0.0


class grk_stream_params:
    def __init__(self):
        self.is_read_stream = False
        self.file = ""


class grk_header_info:
    def __init__(self):
        self.numresolutions = 0
        self.cblockw_init = 0
        self.cblockh_init = 0
        self.prog_order = GRK_LRCP
        self.irreversible = False
        self.t_width = 0
        self.t_height = 0
        self.t_grid_width = 0
        self.t_grid_height = 0
        self.num_xml_boxes = 0
        self._xml_data = None
        self.header_image = grk_image(1)

    def get_xml_data(self):
        return self._xml_data


class grk_wait_swath:
    def __init__(self):
        self.x0 = 0
        self.y0 = 0
        self.x1 = 0
        self.y1 = 0
        self.tile_x0 = 0
        self.tile_y0 = 0
        self.tile_x1 = 0
        self.tile_y1 = 0
        self.num_tile_cols = 1


class grk_swath_buffer:
    def __init__(self):
        self.prec = 8
        self.sgnd = False
        self.numcomps = 1
        self.x0 = 0
        self.y0 = 0
        self.x1 = 0
        self.y1 = 0
        self.promote_alpha = -1
        self.band_map = None
        self.width = 0
        self.height = 0
        self._data = None

    def set_bsq_layout(self, width, height):
        self.width = width
        self.height = height

    def set_data(self, data):
        self._data = data

    def set_band_map(self, band_map):
        self.band_map = list(band_map)
        self.numcomps = len(self.band_map)


class _Codec:
    def __init__(self, stream, params, payload, valid):
        self.stream = stream
        self.params = params
        self.payload = payload
        self.valid = valid
        self.header = None
        self.image = None
        self.reduce = 0
        self.tile_index = None
        self.swath = None


def grk_version():
    return "1.2.3"


def grk_initialize(*_args):
    return 0


def grk_object_unref(_obj):
    return 0


def grk_compress_set_default_params(params):
    params.numresolution = 6
    params.cblockw_init = 64
    params.cblockh_init = 64
    params.prog_order = GRK_LRCP
    params.irreversible = False
    params.cod_format = GRK_FMT_J2K
    params.numlayers = 1
    params.allocation_by_rate_distortion = False
    params.tile_size_on = False
    params.t_width = 0
    params.t_height = 0
    params.layers = []


def grk_cparameters_set_layer_rate(params, idx, rate):
    while len(params.layers) <= idx:
        params.layers.append(0.0)
    params.layers[idx] = float(rate)


def _alloc_component(width, height, prec, sgnd, fill_fn=None):
    comp = grk_image_comp()
    comp.w = width
    comp.h = height
    comp.prec = prec
    comp.sgnd = sgnd
    comp.stride = width
    buf = (ctypes.c_int32 * (width * height))()
    max_val = (1 << min(prec, 31)) - 1 if prec > 0 else 0
    for y in range(height):
        for x in range(width):
            idx = y * width + x
            value = fill_fn(x, y) if fill_fn else 0
            if max_val > 0:
                value %= max_val + 1
            buf[idx] = int(value)
    comp._buffer = buf
    comp.data = ctypes.addressof(buf)
    return comp


def grk_image_new_uniform(numcomps, width, height, dx, dy, prec, sgnd, clrspc):
    if numcomps <= 0 or width <= 0 or height <= 0:
        return None
    image = grk_image(numcomps)
    image.x0 = 0
    image.y0 = 0
    image.x1 = width
    image.y1 = height
    image.meta = None
    for c in range(numcomps):
        comp = _alloc_component(
            width,
            height,
            prec,
            sgnd,
            fill_fn=lambda x, y, c=c: (x + y + c * 37),
        )
        comp.dx = dx
        comp.dy = dy
        image.comps[c] = comp
    return image


def grk_image_new(numcomps, comp, clrspc, frames):
    if numcomps <= 0 or comp.w <= 0 or comp.h <= 0:
        return None
    image = grk_image(numcomps)
    image.x0 = 0
    image.y0 = 0
    image.x1 = comp.w
    image.y1 = comp.h
    image.meta = None
    for i in range(numcomps):
        copied = grk_image_comp()
        copied.dx = getattr(comp, "dx", 1)
        copied.dy = getattr(comp, "dy", 1)
        copied.w = comp.w
        copied.h = comp.h
        copied.prec = getattr(comp, "prec", 8)
        copied.sgnd = getattr(comp, "sgnd", False)
        copied.stride = copied.w
        buf = (ctypes.c_int32 * (copied.w * copied.h))()
        copied._buffer = buf
        copied.data = ctypes.addressof(buf)
        image.comps[i] = copied
    return image


def grk_image_meta_new():
    return grk_image_meta()


def _component_values(comp):
    if comp._buffer is not None:
        return list(comp._buffer)[: comp.w * comp.h]
    return [0] * (comp.w * comp.h)


def _encode_payload(image, params):
    payload = {
        "numcomps": image.numcomps,
        "width": image.x1 - image.x0,
        "height": image.y1 - image.y0,
        "x0": image.x0,
        "y0": image.y0,
        "x1": image.x1,
        "y1": image.y1,
        "components": [],
        "meta": image.meta.to_dict() if image.meta else None,
        "numresolutions": params.numresolution,
        "cblockw_init": params.cblockw_init,
        "cblockh_init": params.cblockh_init,
        "prog_order": params.prog_order,
        "irreversible": bool(params.irreversible),
        "cod_format": params.cod_format,
        "tile_size_on": bool(params.tile_size_on),
        "t_width": params.t_width,
        "t_height": params.t_height,
        "numlayers": params.numlayers,
        "allocation_by_rate_distortion": bool(params.allocation_by_rate_distortion),
    }
    for comp in image.comps:
        payload["components"].append(
            {
                "dx": comp.dx,
                "dy": comp.dy,
                "w": comp.w,
                "h": comp.h,
                "prec": comp.prec,
                "sgnd": comp.sgnd,
                "stride": comp.stride,
                "data": array("i", _component_values(comp)).tobytes(),
            }
        )
    return payload


def _decode_payload(payload, reduce=0):
    width = max(1, payload["width"] >> reduce) if reduce else payload["width"]
    height = max(1, payload["height"] >> reduce) if reduce else payload["height"]
    image = grk_image(payload["numcomps"])
    image.x0 = 0
    image.y0 = 0
    image.x1 = width
    image.y1 = height
    image.meta = grk_image_meta.from_dict(payload.get("meta"))
    for idx, comp_data in enumerate(payload["components"]):
        comp = grk_image_comp()
        comp.dx = comp_data["dx"]
        comp.dy = comp_data["dy"]
        comp.w = width
        comp.h = height
        comp.prec = comp_data["prec"]
        comp.sgnd = comp_data["sgnd"]
        comp.stride = width
        src = array("i")
        src.frombytes(comp_data["data"])
        buf = (ctypes.c_int32 * (width * height))()
        src_w = comp_data["w"]
        src_h = comp_data["h"]
        src_vals = list(src)
        for y in range(height):
            for x in range(width):
                sx = min(src_w - 1, x << reduce) if reduce else x
                sy = min(src_h - 1, y << reduce) if reduce else y
                buf[y * width + x] = int(src_vals[sy * src_w + sx])
        comp._buffer = buf
        comp.data = ctypes.addressof(buf)
        image.comps[idx] = comp
    return image


def _tile_geometry(payload):
    width = payload["width"]
    height = payload["height"]
    if payload["tile_size_on"] and payload["t_width"] > 0 and payload["t_height"] > 0:
        tw = payload["t_width"]
        th = payload["t_height"]
    else:
        tw = width
        th = height
    gw = max(1, (width + tw - 1) // tw)
    gh = max(1, (height + th - 1) // th)
    return tw, th, gw, gh


def _file_payload_to_bytes(payload, irreversible):
    raw = pickle.dumps(payload, protocol=4)
    body = zlib.compress(raw, 9) if irreversible else raw
    return body, irreversible


def _write_fake_file(path, payload):
    body, is_z = _file_payload_to_bytes(payload, payload["irreversible"])
    meta = payload.get("meta") or {}
    ihdr = b"ihdr" + struct.pack(
        ">I I H B B B B",
        payload["height"],
        payload["width"],
        payload["numcomps"],
        max(0, min(255, payload["components"][0]["prec"] if payload["components"] else 8)),
        0,
        0,
        1 if meta.get("ipr") else 0,
    )
    jp2h = b"jp2h" + ihdr
    box_len = struct.pack(">I", 4 + len(jp2h))
    blob = box_len + jp2h + b"\nGROKDATA\n" + (b"Z" if is_z else b"R") + body
    with open(path, "wb") as f:
        f.write(blob)
    return len(blob)


def _read_fake_file(path):
    with open(path, "rb") as f:
        data = f.read()
    pos = data.find(b"\nGROKDATA\n")
    if pos < 0 or len(data) <= pos + 11:
        return None
    mode = data[pos + 10 : pos + 11]
    body = data[pos + 11 :]
    if mode == b"Z":
        raw = zlib.decompress(body)
    else:
        raw = body
    return pickle.loads(raw)


def grk_compress_init(stream, params, image):
    return _Codec(stream, params, _encode_payload(image, params), True)


def grk_compress(codec, _buf):
    try:
        return _write_fake_file(codec.stream.file, codec.payload)
    except OSError:
        return 0


def _load_file_as_codec(stream, params):
    path = stream.file
    if not os.path.exists(path):
        return None
    try:
        payload = _read_fake_file(path)
        codec = _Codec(stream, params, payload, payload is not None)
        codec.reduce = int(getattr(params.core, "reduce", 0) or 0)
        return codec
    except Exception:
        return _Codec(stream, params, None, False)


def grk_decompress_init(stream, params):
    return _load_file_as_codec(stream, params)


def grk_decompress_read_header(codec, header):
    if not codec or not codec.valid or not codec.payload:
        return False
    payload = codec.payload
    header.numresolutions = payload["numresolutions"]
    header.cblockw_init = payload["cblockw_init"]
    header.cblockh_init = payload["cblockh_init"]
    header.prog_order = payload["prog_order"]
    header.irreversible = bool(payload["irreversible"])
    header.t_width, header.t_height, header.t_grid_width, header.t_grid_height = _tile_geometry(payload)
    header.header_image = _decode_payload(payload, reduce=0)
    header.num_xml_boxes = 0
    header._xml_data = None
    return True


def grk_decompress_update(params, codec):
    if not codec or not codec.valid:
        return False
    codec.reduce = int(getattr(params.core, "reduce", 0) or 0)
    codec.params = params
    return True


def grk_decompress(codec, _buf):
    if not codec or not codec.valid or not codec.payload:
        return False
    codec.image = _decode_payload(codec.payload, reduce=codec.reduce)
    return True


def grk_decompress_get_image(codec):
    if not codec or not codec.valid or not codec.payload:
        return None
    if codec.image is None:
        codec.image = _decode_payload(codec.payload, reduce=codec.reduce)
    return codec.image


def grk_decompress_tile(codec, tile_index):
    if not codec or not codec.valid or not codec.payload:
        return False
    tw, th, gw, gh = _tile_geometry(codec.payload)
    if tile_index < 0 or tile_index >= gw * gh:
        return False
    codec.tile_index = tile_index
    return True


def _tile_image(payload, tile_index, reduce=0):
    tw, th, gw, gh = _tile_geometry(payload)
    tx = tile_index % gw
    ty = tile_index // gw
    x0 = tx * tw
    y0 = ty * th
    width = min(tw, payload["width"] - x0)
    height = min(th, payload["height"] - y0)
    image = grk_image(payload["numcomps"])
    image.x0 = x0
    image.y0 = y0
    image.x1 = x0 + width
    image.y1 = y0 + height
    image.meta = grk_image_meta.from_dict(payload.get("meta"))
    for idx, comp_data in enumerate(payload["components"]):
        comp = grk_image_comp()
        comp.dx = comp_data["dx"]
        comp.dy = comp_data["dy"]
        comp.w = width
        comp.h = height
        comp.prec = comp_data["prec"]
        comp.sgnd = comp_data["sgnd"]
        comp.stride = width
        src = array("i")
        src.frombytes(comp_data["data"])
        src_vals = list(src)
        src_w = comp_data["w"]
        buf = (ctypes.c_int32 * (width * height))()
        for y in range(height):
            for x in range(width):
                buf[y * width + x] = int(src_vals[(y0 + y) * src_w + (x0 + x)])
        comp._buffer = buf
        comp.data = ctypes.addressof(buf)
        image.comps[idx] = comp
    return image


def grk_decompress_get_tile_image(codec, tile_index, _allocate):
    if not codec or not codec.valid or not codec.payload:
        return None
    if tile_index < 0:
        return None
    tw, th, gw, gh = _tile_geometry(codec.payload)
    if tile_index >= gw * gh:
        return None
    return _tile_image(codec.payload, tile_index, reduce=codec.reduce)


def _clip(v, lo, hi):
    return max(lo, min(hi, v))


def grk_decompress_wait(codec, swath):
    if not codec or not codec.valid or not codec.payload:
        return False
    tw, th, gw, gh = _tile_geometry(codec.payload)
    width = codec.payload["width"]
    height = codec.payload["height"]
    swath.num_tile_cols = gw
    swath.tile_x0 = _clip(int(swath.x0 // tw), 0, gw)
    swath.tile_x1 = _clip(int((swath.x1 + tw - 1) // tw), 0, gw)
    swath.tile_y0 = _clip(int(swath.y0 // th), 0, gh)
    swath.tile_y1 = _clip(int((swath.y1 + th - 1) // th), 0, gh)
    codec.swath = swath
    return True


def _source_value(image, comp_idx, x, y):
    comp = image.comps[comp_idx]
    if x < 0 or y < 0 or x >= comp.w or y >= comp.h:
        return 0
    if comp._buffer is not None:
        return int(comp._buffer[y * comp.stride + x])
    return 0


def _pack_value(value, prec, sgnd):
    if prec <= 8:
        return struct.pack("<b" if sgnd else "<B", int(value))
    if prec <= 16:
        return struct.pack("<h" if sgnd else "<H", int(value))
    return struct.pack("<i" if sgnd else "<I", int(value))


def grk_decompress_schedule_swath_copy(codec, swath, swath_buf):
    if not codec or not codec.valid or codec.image is None or swath_buf._data is None:
        return False
    image = codec.image
    x0, y0, x1, y1 = swath.x0, swath.y0, swath.x1, swath.y1
    width = swath_buf.width or (x1 - x0)
    height = swath_buf.height or (y1 - y0)
    comps = swath_buf.numcomps
    elem_size = 1 if swath_buf.prec <= 8 else 2 if swath_buf.prec <= 16 else 4
    raw = bytearray(len(swath_buf._data))
    for out_c in range(comps):
        src_c = out_c
        if swath_buf.band_map:
            src_c = max(1, int(swath_buf.band_map[out_c])) - 1
        src_c = _clip(src_c, 0, image.numcomps - 1)
        for yy in range(height):
            for xx in range(width):
                src_x = x0 + xx
                src_y = y0 + yy
                value = _source_value(image, src_c, src_x, src_y)
                if swath_buf.promote_alpha == 0 and comps == 1:
                    value = 255 if value != 0 else 0
                elif swath_buf.promote_alpha == 0:
                    value = 255 if value != 0 else 0
                offset = ((out_c * height + yy) * width + xx) * elem_size
                raw[offset : offset + elem_size] = _pack_value(
                    value, swath_buf.prec, swath_buf.sgnd
                )
    swath_buf._data[: len(raw)] = raw
    return True


def grk_decompress_wait_swath_copy(codec):
    return True


def grk_decompress_get_output_dimensions(codec):
    if not codec or not codec.valid or not codec.payload:
        return 0, 0
    return codec.payload["width"], codec.payload["height"]


def _serialize_payload(payload):
    return pickle.dumps(payload, protocol=4)


def _deserialize_payload(blob):
    return pickle.loads(blob)


def _file_to_payload(path):
    if not os.path.exists(path):
        return None
    try:
        return _read_fake_file(path)
    except Exception:
        return None


def _payload_to_image(payload, reduce=0):
    return _decode_payload(payload, reduce=reduce)
