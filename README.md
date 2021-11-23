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
    -global PIIX4_PM.acpi-root-pci-hotplug=off \
    -global PIIX4_PM.acpi-pci-hotplug-with-bridge-support=off \
    [-nographic | -serial stdio]
```
