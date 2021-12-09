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

  dev: <span class="dev">hpet</span>, id "" <span class="dev-desc">(HPET)</span>
    gpio-in "" 2
    gpio-out "" 1
    gpio-out "sysbus-irq" 32
    timers = 3 (0x3)
    msi = false
    hpet-intcap = 4 (0x4)
    hpet-offset-saved = true
    mmio 00000000fed00000/0000000000000400

  dev: <span class="dev">ioapic</span>, id "" <span class="dev-desc">(I/O APIC)</span>
    gpio-in "" 24
    version = 32 (0x20)
    mmio 00000000fec00000/0000000000001000

  dev: <span class="dev">i440FX-pcihost</span>, id "" <span class="dev-desc">(PCI-Host Bridge)</span>
    pci-hole64-size = 2147483648 (2 GiB)
    short_root_bus = 0 (0x0)
    x-pci-hole64-fix = true
    x-config-reg-migration-enabled = true

    bus: <span class="bus">pci.0</span> <span class="dev-desc">(PCI Bus 0)</span>
      type <b>PCI</b>

      dev: <span class="dev">i440FX</span>, id "" <span class="dev-desc">(North Bridge)</span>
        class <span class="dev-class">Host bridge</span>, addr 00:00.0, pci id 8086:1237 (sub 1af4:1100)
        addr = 00.0
        romfile = ""
        romsize = 4294967295 (0xffffffff)
        rombar = 1 (0x1)
        multifunction = false
        x-pcie-lnksta-dllla = true
        x-pcie-extcap-init = true
        failover_pair_id = ""
        acpi-index = 0 (0x0)

      dev: <span class="dev">PIIX4_PM</span>, id "" <span class="dev-desc">(SMBus Bridge)</span>
        class <span class="dev-class">Bridge</span>, addr 00:01.3, pci id 8086:7113 (sub 1af4:1100)
        smb_io_base = 45312 (0xb100)
        disable_s3 = 0 (0x0)
        disable_s4 = 0 (0x0)
        s4_val = 2 (0x2)
        acpi-pci-hotplug-with-bridge-support = true
        acpi-root-pci-hotplug = true
        memory-hotplug-support = true
        smm-compat = false
        addr = 01.3
        romfile = ""
        romsize = 4294967295 (0xffffffff)
        rombar = 1 (0x1)
        multifunction = false
        x-pcie-lnksta-dllla = true
        x-pcie-extcap-init = true
        failover_pair_id = ""
        acpi-index = 0 (0x0)

        bus: <span class="bus">i2c</span> <span class="dev-desc">(SMBus)</span>
          type <span class="dev-class">i2c-bus</span>
          dev: smbus-eeprom, id ""
            address = 87 (0x57)
          dev: smbus-eeprom, id ""
            address = 86 (0x56)
          dev: smbus-eeprom, id ""
            address = 85 (0x55)
          dev: smbus-eeprom, id ""
            address = 84 (0x54)
          dev: smbus-eeprom, id ""
            address = 83 (0x53)
          dev: smbus-eeprom, id ""
            address = 82 (0x52)
          dev: smbus-eeprom, id ""
            address = 81 (0x51)
          dev: smbus-eeprom, id ""
            address = 80 (0x50)

      dev: <span class="dev">piix3-ide</span>, id "" <span class="dev-desc">(IDE Controller)</span>
        class <span class="dev-class">IDE controller</span>, addr 00:01.1, pci id 8086:7010 (sub 1af4:1100)
        addr = 01.1
        romfile = ""
        romsize = 4294967295 (0xffffffff)
        rombar = 1 (0x1)
        multifunction = false
        x-pcie-lnksta-dllla = true
        x-pcie-extcap-init = true
        failover_pair_id = ""
        acpi-index = 0 (0x0)
        bar 4: i/o at 0xc000 [0xc00f]

        bus: <span class="bus">ide.0</span> <span class="dev-desc">(IDE Bus 0)</span>
          type <span class="dev-class">IDE</span>
          dev: <span class="dev">ide-hd</span>, id "" <span class="dev-desc">(IDE HDD)</span>
            drive = <b>"ide0-hd0"</b>
            unit = 0 (0x0)
            model = ""
            serial = "QM00001"
            logical_block_size = 512 (512 B)
            physical_block_size = 512 (512 B)
            min_io_size = 0 (0 B)
            opt_io_size = 0 (0 B)
            discard_granularity = 512 (512 B)
            write-cache = "auto"
            share-rw = false
            rerror = "auto"
            werror = "auto"
            ver = "2.5+"
            wwn = 0 (0x0)
            cyls = 1024 (0x400)
            heads = 16 (0x10)
            secs = 63 (0x3f)
            lcyls = 0 (0x0)
            lheads = 0 (0x0)
            lsecs = 0 (0x0)
            bios-chs-trans = "none"
            rotation_rate = 0 (0x0)

        bus: <span class="bus">ide.1</span> <span class="dev-desc">(IDE Bus 1)</span>
          type <span class="dev-class">IDE</span>
          dev: <span class="dev">ide-cd</span>, id "" <span class="dev-desc">(IDE CD-ROM)</span>
            drive = <b>"ide1-cd0"</b>
            unit = 0 (0x0)
            model = ""
            serial = "QM00003"
            logical_block_size = 512 (512 B)
            physical_block_size = 512 (512 B)
            min_io_size = 0 (0 B)
            opt_io_size = 0 (0 B)
            discard_granularity = 512 (512 B)
            write-cache = "auto"
            share-rw = false
            rerror = "auto"
            werror = "auto"
            ver = "2.5+"
            wwn = 0 (0x0)

      dev: <span class="dev">VGA</span>, id "" <span class="dev-desc">(VGA Adapter)</span>
        class <span class="dev-class">VGA controller</span>, addr 00:02.0, pci id 1234:1111 (sub 1af4:1100)
        xres = 1024 (0x400)
        yres = 768 (0x300)
        xmax = 0 (0x0)
        ymax = 0 (0x0)
        vgamem_mb = 16 (0x10)
        mmio = true
        qemu-extended-regs = true
        edid = true
        global-vmstate = false
        addr = 02.0
        romfile = "vgabios-stdvga.bin"
        romsize = 65536 (0x10000)
        rombar = 1 (0x1)
        multifunction = false
        x-pcie-lnksta-dllla = true
        x-pcie-extcap-init = true
        failover_pair_id = ""
        acpi-index = 0 (0x0)
        bar 0: mem at 0x80000000 [0x80ffffff]
        bar 2: mem at 0x81010000 [0x81010fff]
        bar 6: mem at 0xffffffffffffffff [0xfffe]

      dev: <span class="dev">PIIX3</span>, id "" <span class="dev-desc">(South Bridge)</span>
        class <span class="dev-class">ISA bridge</span>, addr 00:01.0, pci id 8086:7000 (sub 1af4:1100)
        addr = 01.0
        romfile = ""
        romsize = 4294967295 (0xffffffff)
        rombar = 1 (0x1)
        multifunction = true
        x-pcie-lnksta-dllla = true
        x-pcie-extcap-init = true
        failover_pair_id = ""
        acpi-index = 0 (0x0)

        bus: <span class="bus">isa.0</span> <span class="dev-desc">(ISA Bus)</span>
          type <span class="dev-class">ISA</span>

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

          dev: <span class="dev">isa-fdc</span>, id "" <span class="dev-desc">(Floppy Disk Controller)</span>
            iobase = 1008 (0x3f0)
            irq = 6 (0x6)
            dma = 2 (0x2)
            fdtypeA = "auto"
            fdtypeB = "auto"
            fallback = "288"
            isa irq 6

            bus: <span class="bus">floppy-bus.0</span> <span class="dev-desc">(Floppy Disk Bus 0)</span>
              type <span class="dev-class">floppy-bus</span>

              dev: <span class="dev">floppy</span>, id "" <span class="dev-desc">(Floppy Disk)</span>
                drive = <b>"floppy0"</b>
                drive-type = "288"
                unit = 0 (0x0)
                logical_block_size = 512 (512 B)
                physical_block_size = 512 (512 B)
                min_io_size = 0 (0 B)
                opt_io_size = 0 (0 B)
                discard_granularity = 4294967295 (4 GiB)
                write-cache = "auto"
                share-rw = false

          dev: <span class="dev">isa-parallel</span>, id "" <span class="dev-desc">(Parallel Port)</span>
            chardev = <b>"parallel0"</b>
            index = 0 (0x0)
            iobase = 888 (0x378)
            irq = 7 (0x7)
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

  dev: <span class="dev">fw_cfg_io</span>, id "" <span class="dev-desc">(QEMU Firmware Configuration)</span>
    dma_enabled = true
    x-file-slots = 32 (0x20)
    acpi-mr-restore = true

  dev: <span class="dev">kvmvapic</span>, id "" <span class="dev-desc">(Hyper-V Virtual APIC)</span>
</pre>