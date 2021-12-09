<style>
.bus {
    font-weight: bold;
    background: #DFDFDF;
    color: red;
}
.dev {
    font-weight: bold;
    background: yellow;
    color: #843275;
}
.dev-class {
    font-weight: bold;
    background: #EAFFFF;
}
.dev-desc {
    font-size: 80%;
    color: #AAA
}
</style>

<pre>
bus: <span class="bus">main-system-bus</span> <span class="dev-desc">(System Bus)</span>
  type <b>System</b>

  dev: <span class="dev">fw_cfg_io</span>, id "" <span class="dev-desc">(QEMU Firmeware Configruation)</span>
    dma_enabled = true
    x-file-slots = 32 (0x20)
    acpi-mr-restore = true

  dev: <span class="dev">kvmvapic</span>, id "" <span class="dev-desc">(Hyper-V Virtual APIC)</span>

  dev: <span class="dev">ioapic</span>, id "" <span class="dev-desc">(I/O APIC)</span>
    gpio-in "" 24
    version = 32 (0x20)
    mmio 00000000fec00000/0000000000001000

  dev: <span class="dev">hpet</span>, id "" <span class="dev-desc">(HPET)</span>
    gpio-in "" 2
    gpio-out "" 1
    gpio-out "sysbus-irq" 32
    timers = 3 (0x3)
    msi = false
    hpet-intcap = 16711940 (0xff0104)
    hpet-offset-saved = true
    mmio 00000000fed00000/0000000000000400

  dev: <span class="dev">q35-pcihost</span>, id "" <span class="dev-desc">(PCI-Host Bridge)</span>
    MCFG = 2952790016 (0xb0000000)
    pci-hole64-size = 34359738368 (32 GiB)
    short_root_bus = 0 (0x0)
    below-4g-mem-size = 134217728 (128 MiB)
    above-4g-mem-size = 0 (0 B)
    x-pci-hole64-fix = true
    x-config-reg-migration-enabled = true

    bus: <span class="bus">pcie.0</span> <span class="dev-desc">(PCI Express Bus 0)</span>
      type <b>PCIE</b>

      dev: <span class="dev">mch</span>, id "" <span class="dev-desc">(MCH)</span>
        class <span class="dev-class">Host bridge</span>, addr 00:00.0, pci id 8086:29c0 (sub 1af4:1100)
        extended-tseg-mbytes = 16 (0x10)
        smbase-smram = true
        addr = 00.0
        romfile = ""
        romsize = 4294967295 (0xffffffff)
        rombar = 1 (0x1)
        multifunction = false
        x-pcie-lnksta-dllla = true
        x-pcie-extcap-init = true
        failover_pair_id = ""
        acpi-index = 0 (0x0)

      dev: <span class="dev">VGA</span>, id "" <span class="dev-desc">(VGA Adapter)</span>
        class <span class="dev-class">VGA controller</span>, addr 00:01.0, pci id 1234:1111 (sub 1af4:1100)
        xres = 1024 (0x400)
        yres = 768 (0x300)
        xmax = 0 (0x0)
        ymax = 0 (0x0)
        vgamem_mb = 16 (0x10)
        mmio = true
        qemu-extended-regs = true
        edid = true
        global-vmstate = false
        addr = 01.0
        romfile = "vgabios-stdvga.bin"
        romsize = 65536 (0x10000)
        rombar = 1 (0x1)
        multifunction = false
        x-pcie-lnksta-dllla = true
        x-pcie-extcap-init = true
        failover_pair_id = ""
        acpi-index = 0 (0x0)
        bar 0: mem at 0xc0000000 [0xc0ffffff]
        bar 2: mem at 0xc1011000 [0xc1011fff]
        bar 6: mem at 0xffffffffffffffff [0xfffe]

      dev: <span class="dev">ICH9-SMB</span>, id "" <span class="dev-desc">(SMBus Bridge)</span>
        class <span class="dev-class">SMBus</span>, addr 00:1f.3, pci id 8086:2930 (sub 1af4:1100)
        addr = 1f.3
        romfile = ""
        romsize = 4294967295 (0xffffffff)
        rombar = 1 (0x1)
        multifunction = true
        x-pcie-lnksta-dllla = true
        x-pcie-extcap-init = true
        failover_pair_id = ""
        acpi-index = 0 (0x0)
        bar 4: i/o at 0x6000 [0x603f]

        bus: <span class="bus">i2c</span> <span class="dev-desc">(SMBus)</span>
          type <b>i2c-bus</b>
          dev: <span class="dev">smbus-eeprom</span>, id ""
            address = 87 (0x57)
          dev: <span class="dev">smbus-eeprom</span>, id ""
            address = 86 (0x56)
          dev: <span class="dev">smbus-eeprom</span>, id ""
            address = 85 (0x55)
          dev: <span class="dev">smbus-eeprom</span>, id ""
            address = 84 (0x54)
          dev: <span class="dev">smbus-eeprom</span>, id ""
            address = 83 (0x53)
          dev: <span class="dev">smbus-eeprom</span>, id ""
            address = 82 (0x52)
          dev: <span class="dev">smbus-eeprom</span>, id ""
            address = 81 (0x51)
          dev: <span class="dev">smbus-eeprom</span>, id ""
            address = 80 (0x50)

      dev: <span class="dev">ich9-ahci</span>, id "" <span class="dev-desc">(AHCI Controller)</span>
        class <span class="dev-class">SATA controller</span>, addr 00:1f.2, pci id 8086:2922 (sub 1af4:1100)
        addr = 1f.2
        romfile = ""
        romsize = 4294967295 (0xffffffff)
        rombar = 1 (0x1)
        multifunction = true
        x-pcie-lnksta-dllla = true
        x-pcie-extcap-init = true
        failover_pair_id = ""
        acpi-index = 0 (0x0)
        bar 4: i/o at 0x6040 [0x605f]
        bar 5: mem at 0xc1010000 [0xc1010fff]

        bus: <span class="bus">ide.0</span> <span class="dev-desc">(IDE Bus 0)</span>
          type <b>IDE</b>

          dev: <span class="dev">ide-hd</span>, id "" <span class="dev-desc">(IDE HDD)</span>
            drive = <b>"ide0-hd0"</b>
            unit = 0 (0x0)
            model = ""
            serial = "QM00001"
            ver = "2.5+"
            logical_block_size = 512 (512 B)
            physical_block_size = 512 (512 B)
            min_io_size = 0 (0 B)
            opt_io_size = 0 (0 B)
            discard_granularity = 512 (512 B)
            write-cache = "auto"
            share-rw = false
            rerror = "auto"
            werror = "auto"
            wwn = 0 (0x0)
            cyls = 1024 (0x400)
            heads = 16 (0x10)
            secs = 63 (0x3f)
            lcyls = 0 (0x0)
            lheads = 0 (0x0)
            lsecs = 0 (0x0)
            bios-chs-trans = "none"
            rotation_rate = 0 (0x0)

        bus: <span class="bus">ide.1</span>
          type <b>IDE</b>

        bus: <span class="bus">ide.2</span>
          type <b>IDE</b>

        bus: <span class="bus">ide.3</span>
          type <b>IDE</b>

        bus: <span class="bus">ide.4</span>
          type <b>IDE</b>

        bus: <span class="bus">ide.5</span>
          type <b>IDE</b>

          dev: <span class="dev">ide-cd</span>, id "" <span class="dev-desc">(IDE CD-ROM)</span>
            drive = <b>"ide2-cd0"</b>
            unit = 0 (0x0)
            model = ""
            serial = "QM00005"
            ver = "2.5+"
            logical_block_size = 512 (512 B)
            physical_block_size = 512 (512 B)
            min_io_size = 0 (0 B)
            opt_io_size = 0 (0 B)
            discard_granularity = 512 (512 B)
            write-cache = "auto"
            share-rw = false
            rerror = "auto"
            werror = "auto"
            wwn = 0 (0x0)

      dev: <span class="dev">ICH9-LPC</span>, id "" <span class="dev-desc">(ISA/LPC Bridge)</span>
        class <span class="dev-class">ISA bridge</span>, addr 00:1f.0, pci id 8086:2918 (sub 1af4:1100)
        gpio-out "gsi" 24
        noreboot = true
        smm-compat = false
        x-smi-broadcast = true
        x-smi-cpu-hotplug = true
        x-smi-cpu-hotunplug = true
        addr = 1f.0
        romfile = ""
        romsize = 4294967295 (0xffffffff)
        rombar = 1 (0x1)
        multifunction = true
        x-pcie-lnksta-dllla = true
        x-pcie-extcap-init = true
        failover_pair_id = ""
        acpi-index = 0 (0x0)

        bus: <span class="bus">isa.0</span> <span class="dev-desc">(ISA Bus 0)</span>
          type <b>ISA</b>

          dev: <span class="dev">port92</span>, id ""
            gpio-out "a20" 1

          dev: <span class="dev">vmmouse</span>, id "" <span class="dev-desc">(Mouse)</span>

          dev: <span class="dev">vmport</span>, id ""
            x-read-set-eax = true
            x-signal-unsupported-cmd = true
            x-report-vmx-type = true
            x-cmds-v2 = true
            vmware-vmx-version = 6 (0x6)
            vmware-vmx-type = 2 (0x2)

          dev: <span class="dev">i8042</span>, id "" <span class="dev-desc">(Keyboard Controller)</span>
            gpio-out "a20" 1
            isa irqs 1,12

          dev: <span class="dev">isa-parallel</span>, id "" <span class="dev-desc">(Parallel Port)</span>
            index = 0 (0x0)
            iobase = 888 (0x378)
            irq = 7 (0x7)
            chardev = "parallel0"
            isa irq 7

          dev: <span class="dev">isa-serial</span>, id "" <span class="dev-desc">(Serial Port)</span>
            index = 0 (0x0)
            iobase = 1016 (0x3f8)
            irq = 4 (0x4)
            isa irq 4

          dev: <span class="dev">i8257</span>, id "" <span class="dev-desc">(8-bit DMA)</span>
            base = 0 (0x0)
            page-base = 128 (0x80)
            pageh-base = -1 (0xffffffffffffffff)
            dshift = 0 (0x0)

          dev: <span class="dev">i8257</span>, id "" <span class="dev-desc">(16-bit DMA)</span>
            base = 192 (0xc0)
            page-base = 136 (0x88)
            pageh-base = -1 (0xffffffffffffffff)
            dshift = 1 (0x1)

          dev: <span class="dev">isa-pcspk</span>, id "" <span class="dev-desc">(PC Speaker)</span>
            audiodev = ""
            iobase = 97 (0x61)
            migrate = true

          dev: <span class="dev">isa-pit</span>, id "" <span class="dev-desc">(PIT)</span>
            gpio-in "" 1
            gpio-out "" 1
            iobase = 64 (0x40)

          dev: <span class="dev">mc146818rtc</span>, id "" <span class="dev-desc">(RTC)</span>
            gpio-out "" 1
            base_year = 0 (0x0)
            lost_tick_policy = "discard"

          dev: <span class="dev">isa-i8259</span>, id "" <span class="dev-desc">(PIC - Master)</span>
            gpio-in "" 8
            gpio-out "" 1
            iobase = 32 (0x20)
            elcr_addr = 1232 (0x4d0)
            elcr_mask = 248 (0xf8)
            master = true

          dev: <span class="dev">isa-i8259</span>, id "" <span class="dev-desc">(PIC - Slave)</span>
            gpio-in "" 8
            gpio-out "" 1
            iobase = 160 (0xa0)
            elcr_addr = 1233 (0x4d1)
            elcr_mask = 222 (0xde)
            master = false
</pre>