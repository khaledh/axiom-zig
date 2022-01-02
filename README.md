# Axiom OS

Axiom is an experimental kernel written in [Zig](https://ziglang.org).

## Build

`zig build`

## Run (QEMU)

```console
$ qemu-system-x86_64 \
    -bios /usr/share/OVMF/OVMF_CODE.fd \
    -nic none \
    -drive format=raw,file.driver=vvfat,file.rw=on,file.dir=disk-img \
    -machine q35 \
    -nographic
```
