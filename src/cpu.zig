pub fn out16(port: u16, value: u16) void {
    asm volatile (
        "out %[value], %[port]"
        :
        : [port] "{dx}" (port),
          [value] "{ax}" (value)
        : "dx", "ax"
    );
}

pub fn halt() noreturn {
    while (true) {
        asm volatile (
            "hlt"
        );
    }
}
