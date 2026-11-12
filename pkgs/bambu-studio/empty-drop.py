#!/usr/bin/env python3
# Parche binario para bambulab/BambuStudio v02.09.01.70 (ubu24).
#
# Un drop sin ficheros (en wxGTK, un text/uri-list sin file://, p. ej. un enlace arrastrado desde
# el WebView) llega a PlaterDropTarget::handleOnIdle con m_filenames vacio. Plater::load_files
# llama a load_svg, que con la lista vacia devuelve true, y luego lee filenames[0] de un
# wxArrayString sin elementos: puntero nulo y SIGSEGV. Aqui handleOnIdle salta load_files si
# m_filenames.m_nCount == 0. Los offsets son de esta version: los asserts fallan si cambia.
import sys

src, dst = sys.argv[1], sys.argv[2]
data = bytearray(open(src, "rb").read())

patches = [
    # handleOnIdle: lea 0x40(%rbx),%rsi -> jmp 0x213fcf2 ; nop ; nop
    (0x213FC91, "488d7340", "eb5f9090"),
    # Relleno de alineacion tras la funcion: lea 0x40(%rbx),%rsi ; cmpl $0,0x10(%rsi) (m_nCount,
    # el que lee load_svg) ; je 0x213fcc8 (epilogo sin load_files) ; jmp 0x213fc95 (call load_files)
    (0x213FCF2, "66662e0f1f840000000000" "0f1f00", "488d7340" "837e1000" "74cc" "eb97" "9090"),
]
for off, old, new in patches:
    old, new = bytes.fromhex(old), bytes.fromhex(new)
    assert len(old) == len(new)
    assert data[off:off + len(old)] == old, f"bytes inesperados en {off:#x}"
    data[off:off + len(new)] = new

open(dst, "wb").write(data)
