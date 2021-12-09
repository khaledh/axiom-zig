const uefi = @import("std").os.uefi;

pub const ComponentName2Protocol = extern struct {
    _get_driver_name: fn (*align(1) const ComponentName2Protocol, [*:0]const u8, *[*:0]const u16) callconv(.C) uefi.Status,
    _get_controller_name: fn (*align(1) const ComponentName2Protocol, uefi.Handle, ?uefi.Handle, [:0]const u8, *[*:0]const u16) callconv(.C) uefi.Status,
    supported_languages: [*:0]const u8,

    pub fn getDriverName(
        self: *align(1) const ComponentName2Protocol,
        language: [*:0]const u8,
        driver_name: *[*:0]const u16
    ) uefi.Status {
        return self._get_driver_name(self, language, driver_name);
    }

    pub fn getControllerName(
        self: *align(1) const ComponentName2Protocol,
        controller_handle: uefi.Handle,
        child_handle: ?uefi.Handle,
        language: [:0]const u8,
        driver_name: *[*:0]const u16
    ) uefi.Status {
        return self._get_controller_name(self, controller_handle, child_handle, language, driver_name);
    }
};
