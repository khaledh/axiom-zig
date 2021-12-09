const uefi = @import("std").os.uefi;
const DevicePathProtocol =uefi.protocols.DevicePathProtocol;

pub const DevicePathToTextProtocol = extern struct {
    _convert_device_node_to_text: fn (*const DevicePathProtocol, bool, bool) callconv(.C) [*:0]const u16,
    _convert_device_path_to_text: fn (*const DevicePathProtocol, bool, bool) callconv(.C) [*:0]const u16,

    pub fn convertDeviceNodeToText(
        self: *align(1) const DevicePathToTextProtocol,
        device_node: *const DevicePathProtocol,
        display_only: bool,
        allow_shortcuts: bool
    ) [*:0]const u16 {
        return self._convert_device_node_to_text(device_node, display_only, allow_shortcuts);
    }

    pub fn convertDevicePathToText(
        self: *align(1) const DevicePathToTextProtocol,
        device_path: *const DevicePathProtocol,
        display_only: bool,
        allow_shortcuts: bool
    ) [*:0]const u16 {
        return self._convert_device_path_to_text(device_path, display_only, allow_shortcuts);
    }
};
