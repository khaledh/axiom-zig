const std = @import("std");
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const AllocationError = std.mem.Allocator.Error;
const amltree = @import("amltree.zig");
const io = @import("../io.zig");
const print = io.print;
const printIndented = io.printIndented;
const println = io.println;
const printlnIndented = io.printlnIndented;

pub const Prefix = enum(u8) {
    BytePrefix         = 0x0A,
    WordPrefix         = 0x0B,
    DWordPrefix        = 0x0C,
    StringPrefix       = 0x0D,
    QWordPrefix        = 0x0E,
    DualNamePrefix     = 0x2E,
    MultiNamePrefix    = 0x2F,
    ExtOpPrefix        = 0x5B,
};

pub const Char = enum(u8) {
    Null               = 0x00,
    DigitChar_Start    = 0x30, // ('0'-   )
    DigitChar_End      = 0x39, // (   -'9')
    AlphaChar_Start    = 0x41, // ('A'-   )
    AlphaChar_End      = 0x5A, // (   -'Z')
    RootChar           = 0x5C, // ('\')
    ParentPrefixChar   = 0x5E, // ('^')
    UnderscoreChar     = 0x5F, // ('_')
    AsciiChar_Start    = 0x01,
    AsciiChar_End      = 0x7F,
};

pub const OpCodeByte = enum(u8) {
    ZeroOp             = 0x00,
    OneOp              = 0x01,
    AliasOp            = 0x06,
    NameOp             = 0x08,
    ScopeOp            = 0x10,
    BufferOp           = 0x11,
    PackageOp          = 0x12,
    VarPackageOp       = 0x13,
    MethodOp           = 0x14,
    ExternalOp         = 0x15,
    Local0Op           = 0x60,
    Local1Op           = 0x61,
    Local2Op           = 0x62,
    Local3Op           = 0x63,
    Local4Op           = 0x64,
    Local5Op           = 0x65,
    Local6Op           = 0x66,
    Local7Op           = 0x67,
    Arg0Op             = 0x68,
    Arg1Op             = 0x69,
    Arg2Op             = 0x6A,
    Arg3Op             = 0x6B,
    Arg4Op             = 0x6C,
    Arg5Op             = 0x6D,
    Arg6Op             = 0x6E,
    StoreOp            = 0x70,
    RefOfOp            = 0x71,
    AddOp              = 0x72,
    ConcatOp           = 0x73,
    SubtractOp         = 0x74,
    IncrementOp        = 0x75,
    DecrementOp        = 0x76,
    MultiplyOp         = 0x77,
    DivideOp           = 0x78,
    ShiftLeftOp        = 0x79,
    ShiftRightOp       = 0x7A,
    AndOp              = 0x7B,
    NandOp             = 0x7C,
    OrOp               = 0x7D,
    NorOp              = 0x7E,
    XorOp              = 0x7F,
    NotOp              = 0x80,
    FindSetLeftBitOp   = 0x81,
    FindSetRightBitOp  = 0x82,
    DerefOfOp          = 0x83,
    ConcatResOp        = 0x84,
    ModOp              = 0x85,
    NotifyOp           = 0x86,
    SizeOfOp           = 0x87,
    IndexOp            = 0x88,
    MatchOp            = 0x89,
    CreateDWordFieldOp = 0x8A,
    CreateWordFieldOp  = 0x8B,
    CreateByteFieldOp  = 0x8C,
    CreateBitFieldOp   = 0x8D,
    ObjectTypeOp       = 0x8E,
    CreateQWordFieldOp = 0x8F,
    LandOp             = 0x90,
    LorOp              = 0x91,
    LnotOp             = 0x92,
    LEqualOp           = 0x93,
    LGreaterOp         = 0x94,
    LLessOp            = 0x95,
    ToBufferOp         = 0x96,
    ToDecimalStringOp  = 0x97,
    ToHexStringOp      = 0x98,
    ToIntegerOp        = 0x99,
    ToStringOp         = 0x9C,
    CopyObjectOp       = 0x9D,
    MidOp              = 0x9E,
    ContinueOp         = 0x9F,
    IfOp               = 0xA0,
    ElseOp             = 0xA1,
    WhileOp            = 0xA2,
    NoopOp             = 0xA3,
    ReturnOp           = 0xA4,
    BreakOp            = 0xA5,
    BreakPointOp       = 0xCC,
    OnesOp             = 0xFF,
};

pub const OpCodeWord = enum(u16) {
    MutexOp            = 0x01_5B,
    EventOp            = 0x02_5B,
    CondRefOfOp        = 0x12_5B,
    CreateFieldOp      = 0x13_5B,
    LoadTableOp        = 0x1F_5B,
    LoadOp             = 0x20_5B,
    StallOp            = 0x21_5B,
    SleepOp            = 0x22_5B,
    AcquireOp          = 0x23_5B,
    SignalOp           = 0x24_5B,
    WaitOp             = 0x25_5B,
    ResetOp            = 0x26_5B,
    ReleaseOp          = 0x27_5B,
    FromBCDOp          = 0x28_5B,
    ToBCD              = 0x29_5B,
    Reserved           = 0x2A_5B,
    RevisionOp         = 0x30_5B,
    DebugOp            = 0x31_5B,
    FatalOp            = 0x32_5B,
    TimerOp            = 0x33_5B,
    OpRegionOp         = 0x80_5B,
    FieldOp            = 0x81_5B,
    DeviceOp           = 0x82_5B,
    ProcessorOp        = 0x83_5B, // deprecated in 6.4
    PowerResOp         = 0x84_5B,
    ThermalZoneOp      = 0x85_5B,
    IndexFieldOp       = 0x86_5B,
    BankFieldOp        = 0x87_5B,
    DataRegionOp       = 0x88_5B,
    LNotEqualOp        = 0x93_92,
    LLessEqualOp       = 0x94_92,
    LGreaterEqualOp    = 0x95_92,
};

// AST

pub const TermObj = union(enum) {
    obj: *Object,
    stmt_opcode: *StatementOpcode,
    expr_opcode: *ExpressionOpcode,
};

pub const StatementOpcode = union(enum) {
    break_: *Break,
    // break_point: *BreakPoint,
    // continue_: *Continue,
    // fatal: *Fatal,
    if_else: *IfElse,
    // noop: *Noop,
    notify: *Notify,
    release: *Release,
    // reset: *Reset,
    return_: *Return,
    // signal: *Signal,
    // sleep: *Sleep,
    // stall: *Stall,
    while_: *While,
};

pub const Break = struct {};

pub const IfElse = struct {
    predicate: *TermArg,
    terms: []TermObj,
    else_terms: ?[]TermObj,
};

pub const Notify = struct {
    object: *SuperName,
    value: *TermArg,
};

pub const Release = struct {
    mutex: *SuperName,
};

pub const Return = struct {
    arg_obj: *TermArg,
};

pub const While = struct {
    predicate: *TermArg,
    terms: []TermObj,
};

pub const ExpressionOpcode = union(enum) {
    acquire: *Acquire,
    add: *Add,
    and_: *And,
    buffer: *Buffer,
    // DefConcat,
    // DefConcatRes,
    // DefCondRefOf,
    // DefCopyObject,
    // DefDecrement,
    deref_of: *DerefOf,
    // DefDivide,
    // DefFindSetLeftBit,
    // DefFindSetRightBit,
    // DefFromBCD,
    increment: *Increment,
    index: *Index,
    land: *LAnd,
    lequal: *LEqual,
    lgreater: *LGreater,
    // DefLGreaterEqual,
    lless: *LLess,
    // DefLLessEqual,
    // DefMid,
    lnot: *LNot,
    // DefLNotEqual,
    // DefLoadTable,
    lor: *LOr,
    // DefMatch,
    // DefMod,
    // DefMultiply,
    // DefNAnd,
    // DefNOr,
    // DefNot,
    // DefObjectType,
    or_: *Or,
    package: *Package,
    // DefVarPackage,
    ref_of: *RefOf,
    shift_left: *ShiftLeft,
    shift_right: *ShiftRight,
    size_of: *SizeOf,
    store: *Store,
    subtract: *Subtract,
    // DefTimer,
    // DefToBCD,
    to_buffer: *ToBuffer,
    // DefToDecimalString,
    to_hex_string: *ToHexString,
    // DefToInteger,
    // DefToString,
    // DefWait,
    // DefXOr,
    call: *MethodInvocation,
};

pub const Acquire = struct {
    mutex: *SuperName,
    timeout: u32,
};

pub const Add = struct {
    operand1: *TermArg,
    operand2: *TermArg,
    target: ?*Target,
};

pub const LAnd = struct {
    operand1: *TermArg,
    operand2: *TermArg,
};

pub const Buffer = struct {
    size: *TermArg,
    payload: *BufferPayload,
};

pub const BufferPayload = union(enum) {
    bytes: []const u8,
    res_desc: []ResourceDescriptor,
};

pub const ResourceDescriptor = union(enum) {
    // irq: *IrqDesc,
    // dma: *DmaDesc,
    // dma_fixed: *DmaFixedDesc,
    io: *IoDesc,
    // io_fixed: *IoFixedDesc,
    // memory24: *Memory24Desc,
    // memory32: *Memory32Desc,
    memory32_fixed: *Memory32FixedDesc,
    // vendor_defined: *VendorDefinedDsec,
    // qword_addr_space: *QWordAddressSpaceDesc,
    dword_addr_space: *DWordAddressSpaceDesc,
    word_addr_space: *WordAddressSpaceDesc,
    // ext_addr_space: *ExtendedAddressSpaceDesc,
    ext_interrupt: *ExtendedInterruptDesc,
    // gen_register: *GenericRegisterDesc,
    // gpio_conn: *GpioConnectionDesc,
    // gen_serial_conn: *GenericSerialConnectionDesc,
    // i2c_serial_conn: *I2cSerialConnectionDesc,
    // spi_serial_conn: *SpiSerialConnectionDesc,
    // uart_serial_conn: *UartSerialConnectionDesc,
    // cam_serial_conn: *CameraSerialConnectionDesc,
    // pin_func: *PinFunctionDesc,
    // pin_conf: *PinConfigDesc,
    // pin_group: *PinGroupDesc,
    // pin_group_func: *PinGroupFuncDesc,
    // pin_group_conf: *PinGroupConfigDesc,
};

pub const SmallResourceItemTag = enum(u8) {
    irq            = 0x04 << 3,
    dma            = 0x05 << 3,
    start_dep_func = 0x06 << 3,
    end_dep_func   = 0x07 << 3,
    io             = 0x08 << 3,
    io_fixed       = 0x09 << 3,
    dma_fixed      = 0x0a << 3,
    vendor_defined = 0x0e << 3,
    end_tag        = 0x0f << 3,
};

pub const LargeResourceItemTag = enum(u8) {
    memory24         = 0x01 | 0x80,
    gen_register     = 0x02 | 0x80,
    vendor_defined   = 0x04 | 0x80,
    memory32         = 0x05 | 0x80,
    memory32_fixed   = 0x06 | 0x80,
    dword_addr_space = 0x07 | 0x80,
    word_addr_space  = 0x08 | 0x80,
    ext_interrupt    = 0x09 | 0x80,
    qword_addr_space = 0x0a | 0x80,
    ext_addr_space   = 0x0b | 0x80,
    gpio_conn        = 0x0c | 0x80,
    pin_func         = 0x0d | 0x80,
    gen_serial_conn  = 0x0e | 0x80,
    pin_conf         = 0x0f | 0x80,
    pin_group        = 0x10 | 0x80,
    pin_group_func   = 0x11 | 0x80,
    pin_group_conf   = 0x12 | 0x80,
};

pub const AddressSpaceFlags = packed struct {
    resource_usage: u1,
    decode_type: u1,
    min_addr_fixed: u1,
    max_addr_fixed: u1,
    reserved: u4 = 0,
};

pub const WordAddressSpaceDesc = struct {
    resource_type: u8,
    general_flags: AddressSpaceFlags,
    type_flags: u8,
    granularity: u16,
    min: u16,
    max: u16,
    translation_offset: u16,
    length: u16,
    res_source: ?[]const u8 = null,
    res_source_index: ?u8 = null,
};

pub const DWordAddressSpaceDesc = struct {
    resource_type: u8,
    general_flags: AddressSpaceFlags,
    type_flags: u8,
    granularity: u32,
    min: u32,
    max: u32,
    translation_offset: u32,
    length: u32,
    res_source: ?[]const u8 = null,
    res_source_index: ?u8 = null,
};

pub const ReadWriteType = enum(u1) {
    ReadOnly = 0,
    ReadWrite = 1,
};

pub const Memory32FixedDesc = struct {
    info: packed struct {
        rw_type: ReadWriteType,
        ignored: u7,
    },
    base: u32,
    length: u32,
};

pub const ExtendedInterruptDesc = struct {
    int_vector_flags: packed struct {
        usage: u1,
        mode: u1,
        polarity: u1,
        sharing: u1,
        wake_cap: u1,
        reserved: u3 = 0,
    },
    int_table: []const u32,
    res_source: ?[]const u8 = null,
    res_source_index: ?u8 = null,
};

pub const IoDesc = struct {
    info: packed struct {
        decode: u1,
        ignored: u7,
    },
    addr_min: u16,
    addr_max: u16,
    addr_align: u8,
    length: u8,
};

pub const DerefOf = struct {
    obj_ref: *TermArg,
};

pub const Increment = struct {
    operand: *SuperName,
};

pub const Index = struct {
    obj: *TermArg,
    index: *TermArg,
    target: ?*Target,
};

pub const LEqual = struct {
    operand1: *TermArg,
    operand2: *TermArg,
};

pub const LGreater = struct {
    operand1: *TermArg,
    operand2: *TermArg,
};

pub const LLess = struct {
    operand1: *TermArg,
    operand2: *TermArg,
};

pub const LNot = struct {
    operand: *TermArg,
};

pub const LOr = struct {
    operand1: *TermArg,
    operand2: *TermArg,
};

pub const Or = struct {
    operand1: *TermArg,
    operand2: *TermArg,
    target: ?*Target,
};

pub const And = struct {
    operand1: *TermArg,
    operand2: *TermArg,
    target: ?*Target,
};

pub const Package = struct {
    n_elements: u8,
    elements: []PackageElement,
};

pub const PackageElement = union(enum) {
    data_ref_obj: *DataRefObject,
    name: *NameString,
};

pub const RefOf = struct {
    source: *SuperName,
};

pub const ShiftLeft = struct {
    operand: *TermArg,
    shift_count: *TermArg,
    target: ?*Target,
};

pub const ShiftRight = struct {
    operand: *TermArg,
    shift_count: *TermArg,
    target: ?*Target,
};

pub const SizeOf = struct {
    operand: *SuperName,
};

pub const Store = struct {
    source: *TermArg,
    dest: *SuperName,
};

pub const Subtract = struct {
    operand1: *TermArg,
    operand2: *TermArg,
    target: ?*Target,
};

pub const ToBuffer = struct {
    operand: *TermArg,
    target: ?*Target,
};

pub const ToHexString = struct {
    operand: *TermArg,
    target: ?*Target,
};

pub const MethodInvocation = struct {
    name: *NameString,
    args: []TermArg,
};

pub const Target = union(enum) {
    name: *SuperName,
    null_: void,
};

pub const SuperName = union(enum) {
    simple_name: *SimpleName,
    debug_obj: *DebugObj,
    ref_type_opcode: *ReferenceTypeOpcode,
};

pub const SimpleName = union(enum) {
    name: *NameString,
    arg: ArgObj,
    local: LocalObj
};

pub const DebugObj = struct {};

pub const ReferenceTypeOpcode = union(enum) {
    ref_of: *RefOf,
    deref_of: *DerefOf,
    index: *Index,
};

pub const Object = union(enum) {
    ns_mod_obj: *NameSpaceModifierObj,
    named_obj: *NamedObj,
};

pub const NameSpaceModifierObj = union(enum) {
    // def_alias: *DefAlias,
    def_name: *DefName,
    def_scope: *DefScope,
};

pub const DefScope = struct {
    name: *NameString,
    terms: []TermObj,
};

pub const DefName = struct {
    name: *NameString,
    data_ref_obj: *DataRefObject,
};

pub const DataRefObject = union(enum) {
    data_obj: *DataObject,
    obj_ref: *TermArg,
};

pub const NameString = struct {
    name: []const u8,
};

pub const NamedObj = union(enum) {
    // DefBankField,
    // DefCreateBitField,
    // DefCreateByteField,
    def_create_dword_field: *DefCreateDWordField,
    // DefCreateField,
    // DefCreateQWordField,
    // DefCreateWordField,
    // DefDataRegion,
    def_device: *DefDevice,
    // DefEvent,
    def_field: *DefField,
    // DefFunction,
    // DefIndexField,
    def_method: *DefMethod,
    def_mutex: *DefMutex,
    def_op_region: *DefOpRegion,
    // DefPowerRes,
    def_processor: *DefProcessor, // deprecated in 6.4
    // DefThermalZone,
};

pub const FieldFlags = packed struct {
    access_type: enum(u4) {
        AnyAcc,
        ByteAcc,
        WordAcc,
        DWordAcc,
        QWordAcc,
        BufferAcc,
        _,
    },
    lock_rule: enum(u1) {
        NoLock,
        Lock,
    },
    update_rule: enum(u2) {
        Preserve,
        WriteAsOnes,
        WriteAsZeros,
        _,
    },
    reserved: u1 = 0,
};

pub const DefField = struct {
    name: *NameString,
    flags: FieldFlags,
    field_elements: []FieldElement,
};

pub const FieldElement = union(enum) {
    named_fld: *NamedField,
    reserved_fld: *ReservedField,
    // access_fld: AccessField,
    // ext_access_fld: ExtendedAccessField,
    // connect_fld: ConnectField,
};

pub const NamedField = struct {
    name: NameSeg,
    bits: u32,
    bit_offset: u32 = 0,
};

pub const ReservedField = struct {
    bits: u32,
    bit_offset: u32 = 0,
};

pub const NameSeg = [4]u8;

pub const DefMethod = struct {
    name: *NameString,
    arg_count: u3,
    flags: u8,
    terms: []TermObj,
};

pub const DefCreateDWordField = struct {
    source_buff: *TermArg,
    byte_index: *TermArg,
    field_name: *NameString,
};

pub const DefDevice = struct {
    name: *NameString,
    terms: []TermObj,
};

pub const DefMutex = struct {
    name: *NameString,
    sync_flags: u8,
};

pub const OpRegionSpace = enum(u8) {
    SystemMemory,
    SystemIO,
    PCI_Config,
    EmbeddedControl,
    SMBus,
    SystemCMOS,
    PciBarTarget,
    IPMI,
    GeneralPurposeIO,
    GenericSerialBus,
    PCC
};

pub const DefOpRegion = struct {
    name: *NameString,
    space: OpRegionSpace,
    offset: *TermArg,
    len: *TermArg,
};

// deprecated in 6.4
pub const DefProcessor = struct {
    name: *NameString,
    proc_id: u8,
    pblk_addr: u32,
    pblk_len: u8,
    terms: []TermObj,
};

pub const TermArg = union(enum) {
    expr_opcode: *ExpressionOpcode,
    data_obj: *DataObject,
    arg_obj: ArgObj,
    local_obj: LocalObj,
    name_str: *NameString,
};

pub const DataObject = union(enum) {
    comp_data: *ComputationalData,
    package: *Package,
    // DefVarPackage,
};

pub const ArgObj = enum(u8) {
    arg0 = @enumToInt(OpCodeByte.Arg0Op),
    arg1 = @enumToInt(OpCodeByte.Arg1Op),
    arg2 = @enumToInt(OpCodeByte.Arg2Op),
    arg3 = @enumToInt(OpCodeByte.Arg3Op),
    arg4 = @enumToInt(OpCodeByte.Arg4Op),
    arg5 = @enumToInt(OpCodeByte.Arg5Op),
    arg6 = @enumToInt(OpCodeByte.Arg6Op),
};

pub const LocalObj = enum(u8) {
    local0 = @enumToInt(OpCodeByte.Local0Op),
    local1 = @enumToInt(OpCodeByte.Local1Op),
    local2 = @enumToInt(OpCodeByte.Local2Op),
    local3 = @enumToInt(OpCodeByte.Local3Op),
    local4 = @enumToInt(OpCodeByte.Local4Op),
    local5 = @enumToInt(OpCodeByte.Local5Op),
    local6 = @enumToInt(OpCodeByte.Local6Op),
    local7 = @enumToInt(OpCodeByte.Local7Op)
};

pub const ComputationalData = union(enum) {
    byte_const: u8,
    word_const: u16,
    dword_const: u32,
    qword_const: u64,
    const_obj: u8,
    string: [:0]const u8,
    revision: u64,
    buffer: *Buffer,
};

// Namespace

const NamespaceObject = union(enum) {
    scope: *DefScope,
    device: *DefDevice,
    method: *DefMethod,
    name: *DefName,
    processor: *DefProcessor,
};

fn NamespaceBuilder() type {
    // const PredefinedRootNamespaces = [_][]const u8 {
    //     "_GPE",
    //     "_PR",
    //     "_SB",
    //     "_SI",
    //     "_TZ",
    // };

    return struct {
        alloc: *std.mem.Allocator,
        stack: std.ArrayList([]const u8),
        names: std.StringHashMap(NamespaceObject),

        const Self = @This();

        var pcnt_method_name = NameString{ .name = "PCNT" };
        var pcnt_method = DefMethod{
            .name = &pcnt_method_name,
            .arg_count = 0,
            .flags = 0,
            .terms = &.{},
        };

        pub fn init(alloc: *std.mem.Allocator) Self {
            var self = Self{
                .alloc = alloc,
                .stack = std.ArrayList([]const u8).init(alloc),
                .names = std.StringHashMap(NamespaceObject).init(alloc),
            };

            // hack: add missing method
            _ = self.addName("\\_SB_.PCI0.PCNT", NamespaceObject{ .method = &pcnt_method }) catch unreachable;

            return self;
        }

        pub fn pushNamespace(self: *Self, namespace: []const u8) !void {
            try self.stack.append(namespace);
        }

        pub fn popNamespace(self: *Self) []const u8 {
            return self.stack.pop();
        }

        pub fn currentNamespace(self: *Self) []const u8 {
            if (self.stack.items.len == 0) {
                return "\\";
            }
            return self.stack.items[self.stack.items.len - 1];
        }

        pub fn addName(self: *Self, name: []const u8, obj: NamespaceObject) ![]const u8 {
            // var it = std.mem.split(u8, name, ".");
            const normalized_name = try self.normalizeName(name);
            try self.names.put(normalized_name, obj);
            return normalized_name;
        }

        pub fn getName(self: *Self, name: []const u8) !?NamespaceObject {
            var search_name = try self.normalizeName(name);
            // println("searching for: {s}", .{search_name});

            var obj = self.names.get(search_name);
            while (obj == null) {
                if (try self.liftName(search_name)) |lifted_name| {
                    // println("searching lifted_name: {s}", .{lifted_name});
                    search_name = lifted_name;
                    obj = self.names.get(search_name);
                } else {
                    break;
                }
            }
            // if (obj != null) {
                // println("found obj = {}", .{obj});
            // }
            return obj;
        }

        fn normalizeName(self: *Self, name: []const u8) ![]const u8 {
            var namespace = self.currentNamespace();
            var localname = name;

            if (std.mem.lastIndexOfScalar(u8, name, '.')) |index| {
                localname = name[index+1..];
                
                if (std.mem.startsWith(u8, name, "\\")) {
                    namespace = name[0..index];
                }
                else {
                    namespace = try self.formatName(namespace, name[0..index]);
                }
            }
            else if (std.mem.startsWith(u8, name, "\\")) {
                namespace = name[0..1];
                localname = name[1..];
            }

            return self.formatName(namespace, localname);
        }

        fn liftName(self: *Self, name: []const u8) !?[]const u8 {
            if (split(name)) |this| {
                if (split(this.namespace)) |parent| {
                    return try self.formatName(parent.namespace, this.localname);
                }
            }
            return null;
        }

        const SplitName = struct {
            namespace: []const u8,
            localname: []const u8,
        };

        fn split(name: []const u8) ?SplitName {
            if (std.mem.lastIndexOfScalar(u8, name, '.')) |index| {
                const split_name = SplitName{
                    .namespace = name[0..index],
                    .localname = name[index+1..],
                };
                return split_name;
            }
            if (std.mem.eql(u8, name, "\\")) {
                return null;
            }
            const split_name = SplitName{
                .namespace = "\\",
                .localname = name[1..],
            };
            return split_name;
        }

        fn formatName(self: *Self, namespace: []const u8, localname: []const u8) ![]const u8 {
            const delim = if (std.mem.eql(u8, namespace, "\\")) "" else ".";
            return try std.mem.concat(self.alloc, u8, &[_][]const u8 {namespace, delim, localname});
        }

        fn cmpName(context: void, a: []const u8, b: []const u8) bool {
            _ = context;
            return std.mem.lessThan(u8, a, b);
        }

        pub fn print(self: *Self) void {
            // std.sort.sort(Name, self.names.items, {}, cmpName);
            var it = self.names.iterator();
            while (it.next()) |entry| {
                println("{s}", .{entry.key_ptr.*});
            }
        }
    };
}

// Parser

pub fn AmlParser() type {
    const ParseContext = struct {
        block: []const u8,
        loc: usize,
    };

    return struct {
        const Self = @This();

        var buf: [1024 * 1024]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);

        allocator: *std.mem.Allocator,
        ns_builder: NamespaceBuilder(),
        ctx_stack: std.ArrayList(ParseContext),
        ctx: ParseContext,
        indent: usize,

        pub fn init() Self {
            return .{
                .allocator = &fba.allocator,
                .ns_builder = NamespaceBuilder().init(&fba.allocator),
                .ctx_stack = std.ArrayList(ParseContext).init(&fba.allocator),
                .ctx = undefined,
                .indent = 0,
            };
        }

        fn enterContext(self: *Self, len: usize) !void {
            try self.ctx_stack.append(self.ctx);
            self.ctx = ParseContext{
                .block = self.ctx.block[self.ctx.loc..(self.ctx.loc + len)],
                .loc = 0,
            };
        }

        fn exitContext(self: *Self) void {
            const exit_ctx = self.ctx;
            self.ctx = self.ctx_stack.pop();
            self.ctx.loc += exit_ctx.block.len;
        }

        fn rewindContext(self: *Self) void {
            self.ctx = self.ctx_stack.pop();
        }

        pub fn parse(self: *Self, aml_block: []const u8) void {
            self.ctx = ParseContext{
                .block = aml_block,
                .loc = 0,
            };

            println("\n\n### Parse Tree\n", .{});

            const term_list = self.terms(self.ctx.block.len) catch |err| {
                println("error: {}", .{err});
                return;
            };
            _ = term_list;

            // println("\n\n### Namespace\n", .{});
            // self.ns_builder.print();

            println("\n\n### AML Tree\n", .{});

            var tree_printer = amltree.AmlTreePrinter.init();
            tree_printer.print(term_list);
        }

        fn terms(self: *Self, len: usize) AllocationError![]TermObj {
            var result: []TermObj = undefined;
            var list = std.ArrayList(TermObj).init(self.allocator);

            const start_loc = self.ctx.loc;
            if (len > 0) {
                while (self.ctx.loc < start_loc + len) {
                    if (try self.termObj()) |term_obj| {
                        try list.append(term_obj.*);
                    }
                    else {
                        break;
                    }
                }
            } else {
                while (true) {
                    if (try self.termObj()) |term_obj| {
                        try list.append(term_obj.*);
                    }
                    else break;
                }
            }

            result = list.items;

            return result;
        }

        fn termObj(self: *Self) !?*TermObj {
            var result: ?*TermObj = null;

            if (try self.object()) |obj| {
                var term_obj = try self.allocator.create(TermObj);
                term_obj.* = TermObj{
                    .obj = obj,
                };
                result = term_obj;
            }
            else if (try self.statementOpCode()) |stmt_opcode| {
                var term_obj = try self.allocator.create(TermObj);
                term_obj.* = TermObj{
                    .stmt_opcode = stmt_opcode,
                };
                result = term_obj;
            }
            else if (try self.expressionOpCode()) |expr_opcode| {
                var term_obj = try self.allocator.create(TermObj);
                term_obj.* = TermObj{
                    .expr_opcode = expr_opcode,
                };
                result = term_obj;
            }

            return result;
        }

        fn object(self: *Self) !?*Object {
            var result: ?*Object = null;

            if (try self.namespaceModifierObj()) |ns_mod_obj| {
                var obj = try self.allocator.create(Object);
                obj.* = Object{
                    .ns_mod_obj = ns_mod_obj,
                };
                result = obj;
            }
            else if (try self.namedObj()) |named_obj| {
                var obj = try self.allocator.create(Object);
                obj.* = Object{
                    .named_obj = named_obj,
                };
                result = obj;
            }

            return result;
        }

        fn statementOpCode(self: *Self) !?*StatementOpcode {
            self.indent += 2;

            var result: ?*StatementOpcode = null;

            if (self.matchOpCodeByte(.BreakOp)) {
                printlnIndented(self.indent, "Break()", .{});
                var stmt_opcode = try self.allocator.create(StatementOpcode);
                stmt_opcode.* = StatementOpcode{
                    .break_ = try self.allocator.create(Break),
                };
                result = stmt_opcode;
            }
            if (self.matchOpCodeByte(.IfOp)) {
                if (self.pkgPayload()) |payload_if| {
                    printlnIndented(self.indent, "If()", .{});
                    const payload_start = self.ctx.loc;
                    if (try self.termArg()) |predicate| {

                        var if_else = try self.allocator.create(IfElse);

                        try self.enterContext(payload_if.len - (self.ctx.loc - payload_start));
                        {
                            if_else.* = IfElse{
                                .predicate = predicate,
                                .terms = try self.terms(0),
                                .else_terms = null,
                            };
                        }
                        self.exitContext();

                        if (self.matchOpCodeByte(.ElseOp)) {
                            if (self.pkgPayload()) |payload_else| {
                                printlnIndented(self.indent, "Else()", .{});

                                try self.enterContext(payload_else.len);
                                {
                                    if_else.else_terms = try self.terms(0);
                                }
                                self.exitContext();
                            }
                        }

                        var stmt_opcode = try self.allocator.create(StatementOpcode);
                        stmt_opcode.* = StatementOpcode{
                            .if_else = if_else,
                        };

                        result = stmt_opcode;
                    }
                }
            }
            else if (self.matchOpCodeByte(.NotifyOp)) {
                if (try self.superName()) |obj|
                if (try self.termArg()) |value| {
                    printlnIndented(self.indent, "Notify()", .{});
                    var notify = try self.allocator.create(Notify);
                    notify.* = Notify{
                        .object = obj,
                        .value = value,
                    };

                    var stmt_opcode = try self.allocator.create(StatementOpcode);
                    stmt_opcode.* = StatementOpcode{
                        .notify = notify,
                    };

                    result = stmt_opcode;
                };
            }
            else if (self.matchOpCodeWord(.ReleaseOp)) {
                if (try self.superName()) |mutex| {
                    printlnIndented(self.indent, "Release()", .{});
                    var release = try self.allocator.create(Release);
                    release.* = Release{
                        .mutex = mutex,
                    };

                    var stmt_opcode = try self.allocator.create(StatementOpcode);
                    stmt_opcode.* = StatementOpcode{
                        .release = release,
                    };

                    result = stmt_opcode;
                }
            }
            else if (self.matchOpCodeByte(.ReturnOp)) {
                printlnIndented(self.indent, "Return()", .{});
                if (try self.termArg()) |arg_obj| {
                    var return_ = try self.allocator.create(Return);
                    return_.* = Return{
                        .arg_obj = arg_obj,
                    };

                    var stmt_opcode = try self.allocator.create(StatementOpcode);
                    stmt_opcode.* = StatementOpcode{
                        .return_ = return_,
                    };

                    result = stmt_opcode;
                }
            }
            else if (self.matchOpCodeByte(.WhileOp)) {
                if (self.pkgPayload()) |payload| {
                    const payload_start = self.ctx.loc;
                    if (try self.termArg()) |predicate| {
                        printlnIndented(self.indent, "While()", .{});
                        try self.enterContext(payload.len - (self.ctx.loc - payload_start));
                        {                            
                            var while_ = try self.allocator.create(While);
                            while_.* = While{
                                .predicate = predicate,
                                .terms = try self.terms(0),
                            };

                            var stmt_opcode = try self.allocator.create(StatementOpcode);
                            stmt_opcode.* = StatementOpcode{
                                .while_ = while_,
                            };

                            result = stmt_opcode;
                        }
                        self.exitContext();
                    }
                }
            }

            self.indent -= 2;
            return result;
        }

        fn expressionOpCode(self: *Self) !?*ExpressionOpcode {
            self.indent += 2;

            var result: ?*ExpressionOpcode = null;

            if (self.matchOpCodeWord(.AcquireOp)) {
                if (try self.superName()) |mutex|
                if (self.readWord()) |timeout| {
                    printlnIndented(self.indent, "Acquire()", .{});
                    var acquire = try self.allocator.create(Acquire);
                    acquire.* = Acquire{
                        .mutex = mutex,
                        .timeout = timeout,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .acquire = acquire,
                    };

                    result = expr_opcode;
                };
            }
            else if (self.matchOpCodeByte(.AddOp)) {
                printlnIndented(self.indent, "Add()", .{});
                if (try self.termArg()) |operand1|
                if (try self.termArg()) |operand2|
                if (try self.target()) |tgt| {
                    var add = try self.allocator.create(Add);
                    add.* = Add{
                        .operand1 = operand1,
                        .operand2 = operand2,
                        .target = tgt,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .add = add,
                    };

                    result = expr_opcode;
                };
            }
            else if (self.matchOpCodeByte(.LandOp)) {
                printlnIndented(self.indent, "LAnd()", .{});
                if (try self.termArg()) |operand1|
                if (try self.termArg()) |operand2| {
                    var land = try self.allocator.create(LAnd);
                    land.* = LAnd{
                        .operand1 = operand1,
                        .operand2 = operand2,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .land = land,
                    };

                    result = expr_opcode;

                };
            }
            else if (try self.buffer()) |buff| {
                var expr_opcode = try self.allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .buffer = buff,
                };

                result = expr_opcode;
            }
            else if (self.matchOpCodeByte(.DerefOfOp)) {
                printlnIndented(self.indent, "DerefOf()", .{});
                if (try self.termArg()) |obj_ref| {
                    var deref_of = try self.allocator.create(DerefOf);
                    deref_of.* = DerefOf{
                        .obj_ref = obj_ref,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .deref_of = deref_of,
                    };

                    result = expr_opcode;

                }
            }
            else if (self.matchOpCodeByte(.LEqualOp)) {
                printlnIndented(self.indent, "LEqual()", .{});
                if (try self.termArg()) |operand1|
                if (try self.termArg()) |operand2| {
                    var lequal = try self.allocator.create(LEqual);
                    lequal.* = LEqual{
                        .operand1 = operand1,
                        .operand2 = operand2,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .lequal = lequal,
                    };

                    result = expr_opcode;

                };
            }
            else if (self.matchOpCodeByte(.LGreaterOp)) {
                printlnIndented(self.indent, "LGreater()", .{});
                if (try self.termArg()) |operand1|
                if (try self.termArg()) |operand2| {
                    var lgreater = try self.allocator.create(LGreater);
                    lgreater.* = LGreater{
                        .operand1 = operand1,
                        .operand2 = operand2,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .lgreater = lgreater,
                    };

                    result = expr_opcode;

                };
            }
            else if (self.matchOpCodeByte(.LLessOp)) {
                printlnIndented(self.indent, "LLess()", .{});
                if (try self.termArg()) |operand1|
                if (try self.termArg()) |operand2| {
                    var lless = try self.allocator.create(LLess);
                    lless.* = LLess{
                        .operand1 = operand1,
                        .operand2 = operand2,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .lless = lless,
                    };

                    result = expr_opcode;

                };
            }
            else if (self.matchOpCodeByte(.LnotOp)) {
                printlnIndented(self.indent, "LNot()", .{});
                if (try self.termArg()) |operand| {
                    var lnot = try self.allocator.create(LNot);
                    lnot.* = LNot{
                        .operand = operand,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .lnot = lnot,
                    };

                    result = expr_opcode;

                }
            }
            else if (self.matchOpCodeByte(.IncrementOp)) {
                printlnIndented(self.indent, "Increment()", .{});
                if (try self.superName()) |operand| {
                    var increment = try self.allocator.create(Increment);
                    increment.* = Increment{
                        .operand = operand,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .increment = increment,
                    };

                    result = expr_opcode;

                }
            }
            else if (self.matchOpCodeByte(.IndexOp)) {
                printlnIndented(self.indent, "Index()", .{});
                if (try self.termArg()) |obj| {
                    if (try self.termArg()) |index_val| {
                        if (try self.target()) |tgt| {
                            var index = try self.allocator.create(Index);
                            index.* = Index{
                                .obj = obj,
                                .index = index_val,
                                .target = tgt,
                            };

                            var expr_opcode = try self.allocator.create(ExpressionOpcode);
                            expr_opcode.* = ExpressionOpcode{
                                .index = index,
                            };

                            result = expr_opcode;
                        }
                    }
                }
            }
            else if (try self.package()) |pkg| {
                var expr_opcode = try self.allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .package = pkg,
                };

                result = expr_opcode;
            }
            else if (self.matchOpCodeByte(.RefOfOp)) {
                printlnIndented(self.indent, "RefOf()", .{});
                if (try self.superName()) |source| {
                    var ref_of = try self.allocator.create(RefOf);
                    ref_of.* = RefOf{
                        .source = source,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .ref_of = ref_of,
                    };

                    result = expr_opcode;
                }
            }
            else if (self.matchOpCodeByte(.LorOp)) {
                printlnIndented(self.indent, "LOr()", .{});
                if (try self.termArg()) |operand1|
                if (try self.termArg()) |operand2| {
                    var lor = try self.allocator.create(LOr);
                    lor.* = LOr{
                        .operand1 = operand1,
                        .operand2 = operand2,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .lor = lor,
                    };

                    result = expr_opcode;
                };
            }
            else if (self.matchOpCodeByte(.OrOp)) {
                printlnIndented(self.indent, "Or()", .{});
                if (try self.termArg()) |operand1|
                if (try self.termArg()) |operand2| {
                    if (try self.target()) |tgt| {
                        var or_ = try self.allocator.create(Or);
                        or_.* = Or{
                            .operand1 = operand1,
                            .operand2 = operand2,
                            .target = tgt,
                        };

                        var expr_opcode = try self.allocator.create(ExpressionOpcode);
                        expr_opcode.* = ExpressionOpcode{
                            .or_ = or_,
                        };

                        result = expr_opcode;
                    }
                };
            }
            else if (self.matchOpCodeByte(.AndOp)) {
                printlnIndented(self.indent, "And()", .{});
                if (try self.termArg()) |operand1|
                if (try self.termArg()) |operand2| {
                    if (try self.target()) |tgt| {
                        var and_ = try self.allocator.create(And);
                        and_.* = And{
                            .operand1 = operand1,
                            .operand2 = operand2,
                            .target = tgt,
                        };

                        var expr_opcode = try self.allocator.create(ExpressionOpcode);
                        expr_opcode.* = ExpressionOpcode{
                            .and_ = and_,
                        };

                        result = expr_opcode;
                    }
                };
            }
            else if (self.matchOpCodeByte(.ShiftLeftOp)) {
                printlnIndented(self.indent, "ShiftLeft()", .{});
                if (try self.termArg()) |operand|
                if (try self.termArg()) |shift_count|
                if (try self.target()) |tgt| {
                    var shl = try self.allocator.create(ShiftLeft);
                    shl.* = ShiftLeft{
                        .operand = operand,
                        .shift_count = shift_count,
                        .target = tgt,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .shift_left = shl,
                    };

                    result = expr_opcode;
                };
            }
            else if (self.matchOpCodeByte(.ShiftRightOp)) {
                printlnIndented(self.indent, "ShiftRight()", .{});
                if (try self.termArg()) |operand|
                if (try self.termArg()) |shift_count|
                if (try self.target()) |tgt| {
                    var shr = try self.allocator.create(ShiftRight);
                    shr.* = ShiftRight{
                        .operand = operand,
                        .shift_count = shift_count,
                        .target = tgt,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .shift_right = shr,
                    };

                    result = expr_opcode;
                };
            }
            else if (self.matchOpCodeByte(.SizeOfOp)) {
                printlnIndented(self.indent, "SizeOf()", .{});
                if (try self.superName()) |operand| {
                    var size_of = try self.allocator.create(SizeOf);
                    size_of.* = SizeOf{
                        .operand = operand,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .size_of = size_of,
                    };

                    result = expr_opcode;

                }
            }
            else if (self.matchOpCodeByte(.StoreOp)) {
                printlnIndented(self.indent, "Store()", .{});
                if (try self.termArg()) |source|
                if (try self.superName()) |dest| {
                    var store = try self.allocator.create(Store);
                    store.* = Store{
                        .source = source,
                        .dest = dest,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .store = store,
                    };

                    result = expr_opcode;
                };
            }
            else if (self.matchOpCodeByte(.SubtractOp)) {
                printlnIndented(self.indent, "Subtract()", .{});
                if (try self.termArg()) |operand1|
                if (try self.termArg()) |operand2|
                if (try self.target()) |tgt| {
                    var subtract = try self.allocator.create(Subtract);
                    subtract.* = Subtract{
                        .operand1 = operand1,
                        .operand2 = operand2,
                        .target = tgt,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .subtract = subtract,
                    };

                    result = expr_opcode;
                };
            }
            else if (self.matchOpCodeByte(.ToBufferOp)) {
                printlnIndented(self.indent, "ToBuffer()", .{});
                if (try self.termArg()) |operand|
                if (try self.target()) |tgt| {
                    var to_buffer = try self.allocator.create(ToBuffer);
                    to_buffer.* = ToBuffer{
                        .operand = operand,
                        .target = tgt,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .to_buffer = to_buffer,
                    };

                    result = expr_opcode;
                };
            }
            else if (self.matchOpCodeByte(.ToHexStringOp)) {
                printlnIndented(self.indent, "ToHexString()", .{});
                if (try self.termArg()) |operand|
                if (try self.target()) |tgt| {
                    var to_hex_string = try self.allocator.create(ToHexString);
                    to_hex_string.* = ToHexString{
                        .operand = operand,
                        .target = tgt,
                    };

                    var expr_opcode = try self.allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .to_hex_string = to_hex_string,
                    };

                    result = expr_opcode;
                };
            }
            else {
                // Due to ambiguity between ExpressionOpcode->MethodInvocation and TermArg->NameString
                // we need to keep track of the start loc to rewind to in case this is not a method name
                const start_loc = self.ctx.loc;
                if (try self.nameString()) |name_str| {
                    if (try self.ns_builder.getName(name_str.name)) |obj| {
                        if (obj == .method) {
                            printlnIndented(self.indent, "MethodInvocation ({s})", .{name_str.name});
                            var list = std.ArrayList(TermArg).init(self.allocator);
                            var i: usize = 0;
                            while (i < obj.method.arg_count) : (i += 1) {
                                const arg = (try self.termArg()).?;
                                try list.append(arg.*);
                            }

                            var call = try self.allocator.create(MethodInvocation);
                            call.* = MethodInvocation{
                                .name = name_str,
                                .args = list.items,
                            };

                            var expr_opcode = try self.allocator.create(ExpressionOpcode);
                            expr_opcode.* = ExpressionOpcode{
                                .call = call,
                            };

                            result = expr_opcode;
                        }
                        else {
                            // rewind to let another rule consume the nameString
                            self.ctx.loc = start_loc;
                        }
                    }
                    else {
                        // rewind to let another rule consume the nameString
                        self.ctx.loc = start_loc;
                    }
                }
            }

            self.indent -= 2;
            return result;
        }

        fn target(self: *Self) !?*Target {
            var result: ?*Target = null;

            if (try self.superName()) |name| {
                var tgt = try self.allocator.create(Target);
                tgt.* = Target{
                    .name = name,
                };
                result = tgt;
            }
            else if (self.nullName()) {
                var tgt = try self.allocator.create(Target);
                tgt.* = Target{
                    .null_ = {},
                };
                result = tgt;
            }

            return result;
        }

        fn superName(self: *Self) !?*SuperName {
            var result: ?*SuperName = null;

            if (try self.simpleName()) |simple_name| {
                var super_name = try self.allocator.create(SuperName);
                super_name.* = SuperName{
                    .simple_name = simple_name,
                };
                result = super_name;
            }
            else if (try self.debugObj()) |debug_obj| {
                var super_name = try self.allocator.create(SuperName);
                super_name.* = SuperName{
                    .debug_obj = debug_obj,
                };
                result = super_name;
            }
            else if (try self.refTypeOpcode()) |ref_type_opcode| {
                // println("ReferenceTypeOpcode()", .{});
                var super_name = try self.allocator.create(SuperName);
                super_name.* = SuperName{
                    .ref_type_opcode = ref_type_opcode,
                };
                result = super_name;
            }

            return result;
        }

        fn simpleName(self: *Self) !?*SimpleName {
            var result: ?*SimpleName = null;

            if (try self.nameString()) |name_str| {
                var simple_name = try self.allocator.create(SimpleName);
                simple_name.* = SimpleName{
                    .name = name_str,
                };
                result = simple_name;
            }
            else if (self.argObj()) |arg| {
                var simple_name = try self.allocator.create(SimpleName);
                simple_name.* = SimpleName{
                    .arg = arg,
                };
                result = simple_name;
            }
            else if (self.localObj()) |local| {
                var simple_name = try self.allocator.create(SimpleName);
                simple_name.* = SimpleName{
                    .local = local,
                };
                result = simple_name;
            }

            return result;
        }

        fn debugObj(self: *Self) !?*DebugObj {
            var result: ?*DebugObj = null;

            if (self.matchOpCodeWord(.DebugOp)) {
                printlnIndented(self.indent, "DebugObj()", .{});
                result = try self.allocator.create(DebugObj);
            }

            return result;
        }

        fn refTypeOpcode(self: *Self) AllocationError!?*ReferenceTypeOpcode {
            self.indent += 2;

            var result: ?*ReferenceTypeOpcode = null;

            if (self.matchOpCodeByte(.RefOfOp)) {
                printlnIndented(self.indent, "RefOf()", .{});
                if (try self.superName()) |source| {
                    var ref_of = try self.allocator.create(RefOf);
                    ref_of.* = RefOf{
                        .source = source,
                    };

                    var ref_type_opcode = try self.allocator.create(ReferenceTypeOpcode);
                    ref_type_opcode.* = ReferenceTypeOpcode{
                        .ref_of = ref_of,
                    };

                    result = ref_type_opcode;
                }
            }
            else if (self.matchOpCodeByte(.DerefOfOp)) {
                printlnIndented(self.indent, "DerefOf()", .{});
                if (try self.termArg()) |obj_ref| {
                    var deref_of = try self.allocator.create(DerefOf);
                    deref_of.* = DerefOf{
                        .obj_ref = obj_ref,
                    };

                    var ref_type_opcode = try self.allocator.create(ReferenceTypeOpcode);
                    ref_type_opcode.* = ReferenceTypeOpcode{
                        .deref_of = deref_of,
                    };

                    result = ref_type_opcode;
                }
            }
            else if (self.matchOpCodeByte(.IndexOp)) {
                printlnIndented(self.indent, "Index()", .{});
                if (try self.termArg()) |obj| {
                    if (try self.termArg()) |index_val| {
                        if (try self.target()) |tgt| {
                            var index = try self.allocator.create(Index);
                            index.* = Index{
                                .obj = obj,
                                .index = index_val,
                                .target = tgt,
                            };

                            var ref_type_opcode = try self.allocator.create(ReferenceTypeOpcode);
                            ref_type_opcode.* = ReferenceTypeOpcode{
                                .index = index,
                            };

                            result = ref_type_opcode;
                        }
                    }
                }
            }

            self.indent -= 2;
            return result;
        }

        fn namespaceModifierObj(self: *Self) !?*NameSpaceModifierObj {
            var result: ?*NameSpaceModifierObj = null;

            // if (try self.defAlias()) |def_alias| {
            //     var ns_mod_obj = try self.allocator.create(NameSpaceModifierObj);
            //     ns_mod_obj.* = NameSpaceModifierObj{
            //         .def_alias = def_alias,
            //     };
            //     result = ns_mod_obj;
            // }

            if (try self.defScope()) |def_scope| {
                var ns_mod_obj = try self.allocator.create(NameSpaceModifierObj);
                ns_mod_obj.* = NameSpaceModifierObj{
                    .def_scope = def_scope,
                };
                result = ns_mod_obj;
            }

            if (try self.defName()) |def_name| {
                var ns_mod_obj = try self.allocator.create(NameSpaceModifierObj);
                ns_mod_obj.* = NameSpaceModifierObj{
                    .def_name = def_name,
                };
                result = ns_mod_obj;
            }

            return result;
        }

        fn namedObj(self: *Self) !?*NamedObj {
            var result: ?*NamedObj = null;

            if (try self.defOpRegion()) |def_op_region| {
                var named_obj = try self.allocator.create(NamedObj);
                named_obj.* = NamedObj{
                    .def_op_region = def_op_region,
                };
                result = named_obj;
            }
            else if (try self.defField()) |def_field| {
                var named_obj = try self.allocator.create(NamedObj);
                named_obj.* = NamedObj{
                    .def_field = def_field,
                };
                result = named_obj;
            }
            else if (try self.defMethod()) |def_method| {
                var named_obj = try self.allocator.create(NamedObj);
                named_obj.* = NamedObj{
                    .def_method = def_method,
                };
                result = named_obj;
            }
            else if (try self.defDevice()) |def_device| {
                var named_obj = try self.allocator.create(NamedObj);
                named_obj.* = NamedObj{
                    .def_device = def_device,
                };
                result = named_obj;
            }
            else if (try self.defMutex()) |def_mutex| {
                var named_obj = try self.allocator.create(NamedObj);
                named_obj.* = NamedObj{
                    .def_mutex = def_mutex,
                };
                result = named_obj;
            }
            else if (try self.defCreateDWordField()) |def_create_dword_field| {
                var named_obj = try self.allocator.create(NamedObj);
                named_obj.* = NamedObj{
                    .def_create_dword_field = def_create_dword_field,
                };
                result = named_obj;
            }
            else if (try self.defProcessor()) |def_processor| {
                var named_obj = try self.allocator.create(NamedObj);
                named_obj.* = NamedObj{
                    .def_processor = def_processor,
                };
                result = named_obj;
            }
                // defBankField() or
                // defCreateBitField() or defCreateByteField() or defCreateDWordField() or
                // defCreateField() or defCreateQWordField() or defCreateWordField() or
                // defDataRegion or defDevice() or DefEvent() or defExternal() or
                // defField() or defIndexField() or defMethod() or defMutex() or
                // defOpRegion() or defPowerRes() or defThermalZone();

            return result;
        }

        fn defOpRegion(self: *Self) !?*DefOpRegion {
            self.indent += 2;

            var result: ?*DefOpRegion = null;

            if (self.matchOpCodeWord(.OpRegionOp)) {
                if (try self.nameString()) |name_str| {
                    if (self.advance()) |region_space| {
                        if (try self.termArg()) |region_offset| {
                            if (try self.termArg()) |region_len| {
                                printlnIndented(self.indent, "OperationRegion ({s})", .{name_str.name});
                                var def_op_region = try self.allocator.create(DefOpRegion);
                                def_op_region.* = DefOpRegion{
                                    .name = name_str,
                                    .space = @intToEnum(OpRegionSpace, region_space),
                                    .offset = region_offset,
                                    .len = region_len,
                                };
                                result = def_op_region;

                            }
                        }
                    }
                }
            }

            self.indent -= 2;
            return result;
        }

        // fn regionSpace(self: *Self) bool {
        //     // printlnIndented(self.indent, @src().fn_name, .{});
        //     // TODO: read ByteData
        //     // ByteData
        //     //   0x00 SystemMemory
        //     //   0x01 SystemIO
        //     //   0x02 PCI_Config
        //     //   0x03 EmbeddedControl
        //     //   0x04 SMBus
        //     //   0x05 System CMOS
        //     //   0x06 PciBarTarget
        //     //   0x07 IPMI
        //     //   0x08 GeneralPurposeIO
        //     //   0x09 GenericSerialBus
        //     //   0x0A PCC
        //     //   0x80-0xFF: OEM Defined

        //     _ = self.advance();
        //     return true;
        // }

        fn defField(self: *Self) !?*DefField {
            self.indent += 2;

            var result: ?*DefField = null;

            if (self.matchOpCodeWord(.FieldOp)) {
                if (self.pkgPayload()) |payload| {
                    try self.enterContext(payload.len);

                    if (try self.nameString()) |name_str| {
                        printlnIndented(self.indent, "Field ({s})", .{name_str.name});
                        if (self.advance()) |flags| {
                            var list = std.ArrayList(FieldElement).init(self.allocator);

                            var curr_bit_offset: u32 = 0;
                            var more_fields = true;
                            while (more_fields) {
                                if (try self.namedField()) |named_fld| {
                                    named_fld.bit_offset = curr_bit_offset;
                                    curr_bit_offset += named_fld.bits;
                                    try list.append(FieldElement{
                                        .named_fld = named_fld,
                                    });
                                }
                                else if (try self.reservedField()) |reserved_fld| {
                                    reserved_fld.bit_offset = curr_bit_offset;
                                    curr_bit_offset += reserved_fld.bits;
                                    try list.append(FieldElement{
                                        .reserved_fld = reserved_fld,
                                    });
                                }
                                else {
                                    more_fields = false;
                                }
                            }

                            var def_field = try self.allocator.create(DefField);
                            def_field.* = DefField{
                                .name = name_str,
                                .flags = @bitCast(FieldFlags, flags),
                                .field_elements = list.items,
                            };

                            result = def_field;
                        }
                    }

                    self.exitContext();
                }
            }

            self.indent -= 2;
            return result;
        }

        fn namedField(self: *Self) !?*NamedField {
            self.indent += 2;

            var result: ?*NamedField = null;

            if (self.nameSeg()) |name_seg|
            if (self.pkgLength()) |field_bits| {
                var named_fld = try self.allocator.create(NamedField);
                named_fld.* = NamedField{
                    .name = name_seg,
                    .bits = field_bits,
                };
                std.mem.copy(u8, named_fld.name[0..], name_seg[0..]);
                
                result = named_fld;

                printlnIndented(self.indent, "NamedField ({s}, {})", .{named_fld.name, named_fld.bits});
            };

            self.indent -= 2;
            return result;
        }

        fn reservedField(self: *Self) !?*ReservedField {
            self.indent += 2;

            var result: ?*ReservedField = null;

            if (self.matchByte(0x00))
            if (self.pkgLength()) |field_bits| {
                var reserved_fld = try self.allocator.create(ReservedField);
                reserved_fld.* = ReservedField{
                    .bits = field_bits,
                };
                
                result = reserved_fld;

                printlnIndented(self.indent, "ReservedField ({})", .{field_bits});
            };

            self.indent -= 2;
            return result;
        }



        fn defMethod(self: *Self) !?*DefMethod {
            self.indent += 2;

            var result: ?*DefMethod = null;

            if (self.matchOpCodeByte(.MethodOp)) {
                if (self.pkgPayload()) |payload| {
                    try self.enterContext(payload.len);
                    {
                        if (try self.nameString()) |name_str|
                        if (self.advance()) |flags| {
                            printlnIndented(self.indent, "Method ({s})", .{name_str.name});
                            const arg_count = @intCast(u3, flags & 0x07);
                            var def_method = try self.allocator.create(DefMethod);
                            def_method.* = DefMethod{
                                .name = name_str,
                                .arg_count = arg_count,
                                .flags = flags,
                                .terms = try self.terms(0),
                            };
                            result = def_method;

                            _ = try self.ns_builder.addName(name_str.name, NamespaceObject{ .method = def_method });
                        };
                    }
                    self.exitContext();
                }
            }

            self.indent -= 2;
            return result;
        }

        fn defDevice(self: *Self) !?*DefDevice {
            self.indent += 2;

            var result: ?*DefDevice = null;

            if (self.matchOpCodeWord(.DeviceOp)) {
                if (self.pkgPayload()) |payload| {
                    try self.enterContext(payload.len);
                    {
                        if (try self.nameString()) |name_str| {
                            printlnIndented(self.indent, "Device ({s})", .{name_str.name});
                            var def_device = try self.allocator.create(DefDevice);
                            def_device.* = DefDevice{
                                .name = name_str,
                                .terms = undefined,
                            };
                            result = def_device;

                            const ns_path = try self.ns_builder.addName(name_str.name, NamespaceObject{ .device = def_device });
                            try self.ns_builder.pushNamespace(ns_path);

                            def_device.terms = try self.terms(0);

                            _ = self.ns_builder.popNamespace();
                        }
                    }
                    self.exitContext();
                }
            }

            self.indent -= 2;
            return result;
        }

        fn defMutex(self: *Self) !?*DefMutex {
            self.indent += 2;

            var result: ?*DefMutex = null;

            if (self.matchOpCodeWord(.MutexOp)) {
                if (try self.nameString()) |name_str| {
                    if (self.advance()) |sync_flags| {
                        printlnIndented(self.indent, "Mutex ({s})", .{name_str.name});
                        var def_mutex = try self.allocator.create(DefMutex);
                        def_mutex.* = DefMutex{
                            .name = name_str,
                            .sync_flags = sync_flags,
                        };
                        result = def_mutex;
                    }
                }
            }

            self.indent -= 2;
            return result;
        }

        fn defCreateDWordField(self: *Self) !?*DefCreateDWordField {
            self.indent += 2;

            var result: ?*DefCreateDWordField = null;

            if (self.matchOpCodeByte(.CreateDWordFieldOp)) {
                if (try self.termArg()) |source_buff| {
                    if (try self.termArg()) |byte_index| {
                        if (try self.nameString()) |name_str| {
                            printlnIndented(self.indent, "CreateDWordField ({s})", .{name_str.name});
                            var def_create_dword_field = try self.allocator.create(DefCreateDWordField);
                            def_create_dword_field.* = DefCreateDWordField{
                                .source_buff = source_buff,
                                .byte_index = byte_index,
                                .field_name = name_str,
                            };
                            result = def_create_dword_field;
                        }
                    }
                }
            }

            self.indent -= 2;
            return result;
        }

        fn defProcessor(self: *Self) !?*DefProcessor {
            self.indent += 2;

            var result: ?*DefProcessor = null;

            if (self.matchOpCodeWord(.ProcessorOp)) {
                if (self.pkgPayload()) |payload| {
                    try self.enterContext(payload.len);
                    {
                        if (try self.nameString()) |name_str|
                        if (self.advance()) |proc_id|
                        if (self.readDWord()) |pblk_addr|
                        if (self.advance()) |pblk_len| {
                            printlnIndented(self.indent, "Processor ({s})", .{name_str.name});

                        var def_processor = try self.allocator.create(DefProcessor);
                        def_processor.* = DefProcessor{
                            .name = name_str,
                            .proc_id = proc_id,
                            .pblk_addr = pblk_addr,
                            .pblk_len = pblk_len,
                            .terms = undefined,
                        };
                        result = def_processor;

                        const ns_path = try self.ns_builder.addName(name_str.name, NamespaceObject{ .processor = def_processor });
                        try self.ns_builder.pushNamespace(ns_path);

                        def_processor.terms = try self.terms(0);

                        _ = self.ns_builder.popNamespace();
                        };
                    }
                    self.exitContext();
                }
            }

            self.indent -= 2;
            return result;
        }

        fn termArg(self: *Self) AllocationError!?*TermArg {
            var result: ?*TermArg = null;

            if (try self.expressionOpCode()) |expr_opcode| {
                var term_arg = try self.allocator.create(TermArg);
                term_arg.* = TermArg{
                    .expr_opcode = expr_opcode,
                };
                result = term_arg;
            }
            else if (try self.dataObject()) |data_obj| {
                var term_arg = try self.allocator.create(TermArg);
                term_arg.* = TermArg{
                    .data_obj = data_obj,
                };
                result = term_arg;
            }
            else if (self.argObj()) |arg_obj| {
                var term_arg = try self.allocator.create(TermArg);
                term_arg.* = TermArg{
                    .arg_obj = arg_obj,
                };
                result = term_arg;
            }
            else if (self.localObj()) |local_obj| {
                var term_arg = try self.allocator.create(TermArg);
                term_arg.* = TermArg{
                    .local_obj = local_obj,
                };
                result = term_arg;
            }
            else if (try self.nameString()) |name_str| {
                var term_arg = try self.allocator.create(TermArg);
                term_arg.* = TermArg{
                    .name_str = name_str,
                };
                result = term_arg;
            }

            return result;
        }

        fn package(self: *Self) !?*Package {
            self.indent += 2;

            var result: ?*Package = null;

            if (self.matchOpCodeByte(.PackageOp))
            if (self.pkgPayload()) |payload| {
                printlnIndented(self.indent, "Package()", .{});
                try self.enterContext(payload.len);
                {
                    if (self.advance()) |n_elements| {
                        var list = std.ArrayList(PackageElement).init(self.allocator);
                        var i: usize = 0;
                        while (i < n_elements) : (i += 1) {
                            if (try self.packageElement()) |pkg_elem| {
                                try list.append(pkg_elem.*);
                            }
                        }
                        var pkg = try self.allocator.create(Package);
                        pkg.* = Package{
                            .n_elements = n_elements,
                            .elements = list.items,
                        };

                        result = pkg;
                    }
                }
                self.exitContext();
            };

            self.indent -= 2;
            return result;
        }

        fn packageElement(self: *Self) AllocationError!?*PackageElement {
            var result: ?*PackageElement = null;

            if (try self.nameString()) |name_str| {
                var pkg_elem = try self.allocator.create(PackageElement);
                pkg_elem.* = PackageElement{
                    .name = name_str,
                };
                result = pkg_elem;
            }
            else if (try self.dataRefObject()) |data_ref_obj| {
                var pkg_elem = try self.allocator.create(PackageElement);
                pkg_elem.* = PackageElement{
                    .data_ref_obj = data_ref_obj,
                };
                result = pkg_elem;
            }

            return result;
        }


        fn buffer(self: *Self) !?*Buffer {
            self.indent += 2;

            var result: ?*Buffer = null;

            if (self.matchOpCodeByte(.BufferOp)) {
                const start_loc = self.ctx.loc;
                if (self.pkgLength()) |pkglen| {
                    if (try self.termArg()) |size| {

                        const len = pkglen - (self.ctx.loc - start_loc);

                        if (self.ctx.loc + len - 1 < self.ctx.block.len and
                            self.ctx.block[self.ctx.loc + len - 2] & 0xF8 == @enumToInt(SmallResourceItemTag.end_tag) and
                            self.ctx.block[self.ctx.loc + len - 1] == 0
                        ) {
                            try self.enterContext(len);
                            {
                                print("Buffer() <ResourceDescriptor>", .{});
                                var list = std.ArrayList(ResourceDescriptor).init(self.allocator);
                                while (try self.resourceDescriptor()) |res_desc| {
                                    try list.append(res_desc.*);
                                }
                                var buff_payload = try self.allocator.create(BufferPayload);
                                buff_payload.* = BufferPayload{
                                    .res_desc = list.items,
                                };

                                var buff = try self.allocator.create(Buffer);
                                buff.* = Buffer{
                                    .size = size,
                                    .payload = buff_payload,
                                };

                                result = buff;
                            }
                            self.exitContext();
                        }
                        else if (self.readBytes(len)) |bytes| {
                            printlnIndented(self.indent, "Buffer()", .{});
                            var buff_payload = try self.allocator.create(BufferPayload);
                            buff_payload.* = BufferPayload{
                                .bytes = bytes,
                            };

                            var buff = try self.allocator.create(Buffer);
                            buff.* = Buffer{
                                .size = size,
                                .payload = buff_payload,
                            };

                            result = buff;
                        }
                    }
                }
            }

            self.indent -= 2;
            return result;
        }

        fn resourceDescriptor(self: *Self) !?*ResourceDescriptor {
            self.indent += 2;

            var result: ?*ResourceDescriptor = null;

            if (self.matchByte(@enumToInt(LargeResourceItemTag.word_addr_space))) {
                if (self.readWord()) |desc_len|
                if (self.readByte()) |res_type|
                if (self.readByte()) |general_flags|
                if (self.readByte()) |type_flags|
                if (self.readWord()) |granularity|
                if (self.readWord()) |min|
                if (self.readWord()) |max|
                if (self.readWord()) |translation_offset|
                if (self.readWord()) |length| {
                    print("WordSpace", .{});
                    var addr_space = try self.allocator.create(WordAddressSpaceDesc);
                    addr_space.* = WordAddressSpaceDesc{
                        .resource_type = res_type,
                        .general_flags = @bitCast(AddressSpaceFlags, general_flags),
                        .type_flags = type_flags,
                        .granularity = granularity,
                        .min = min,
                        .max = max,
                        .translation_offset = translation_offset,
                        .length = length,
                    };

                    if (desc_len > 13) {
                        println("WordSpace: resource source and index", .{});
                        addr_space.res_source_index = self.advance();
                        addr_space.res_source = self.readBytes(desc_len - 13);
                    }

                    var res_desc = try self.allocator.create(ResourceDescriptor);
                    res_desc.* = ResourceDescriptor{
                        .word_addr_space = addr_space,
                    };

                    result = res_desc;
                };
            }
            if (self.matchByte(@enumToInt(LargeResourceItemTag.dword_addr_space))) {
                if (self.readWord()) |desc_len|
                if (self.readByte()) |res_type|
                if (self.readByte()) |general_flags|
                if (self.readByte()) |type_flags|
                if (self.readDWord()) |granularity|
                if (self.readDWord()) |min|
                if (self.readDWord()) |max|
                if (self.readDWord()) |translation_offset|
                if (self.readDWord()) |length| {
                    print("DWordSpace", .{});
                    var addr_space = try self.allocator.create(DWordAddressSpaceDesc);
                    addr_space.* = DWordAddressSpaceDesc{
                        .resource_type = res_type,
                        .general_flags = @bitCast(AddressSpaceFlags, general_flags),
                        .type_flags = type_flags,
                        .granularity = granularity,
                        .min = min,
                        .max = max,
                        .translation_offset = translation_offset,
                        .length = length,
                    };

                    if (desc_len > 23) {
                        println("DWordSpace: resource source and index", .{});
                        addr_space.res_source_index = self.advance();
                        addr_space.res_source = self.readBytes(desc_len - 23);
                    }

                    var res_desc = try self.allocator.create(ResourceDescriptor);
                    res_desc.* = ResourceDescriptor{
                        .dword_addr_space = addr_space,
                    };

                    result = res_desc;
                };
            }
            else if (self.matchByte(@enumToInt(LargeResourceItemTag.memory32_fixed))) {
                if (self.readWord()) |_|
                if (self.readByte()) |info|
                if (self.readDWord()) |base|
                if (self.readDWord()) |length| {
                    print("Memory32Fixed", .{});
                    var memory32_fixed = try self.allocator.create(Memory32FixedDesc);
                    memory32_fixed.* = Memory32FixedDesc{
                        .info = @bitCast(@TypeOf(memory32_fixed.info), info),
                        .base = base,
                        .length = length,
                    };

                    var res_desc = try self.allocator.create(ResourceDescriptor);
                    res_desc.* = ResourceDescriptor{
                        .memory32_fixed = memory32_fixed,
                    };

                    result = res_desc;
                };
            }
            else if (self.matchByte(@enumToInt(LargeResourceItemTag.ext_interrupt))) {
                if (self.readWord()) |desc_len|
                if (self.readByte()) |int_vector_flags|
                if (self.readByte()) |int_table_len| {
                    print("ExtendedInterrupt", .{});

                    var list = std.ArrayList(u32).init(self.allocator);
                    while (self.readDWord()) |int_num| {
                        try list.append(int_num);
                    }
                    
                    var ext_interrupt = try self.allocator.create(ExtendedInterruptDesc);
                    ext_interrupt.* = ExtendedInterruptDesc{
                        .int_vector_flags = @bitCast(@TypeOf(ext_interrupt.int_vector_flags), int_vector_flags),
                        .int_table = list.items,
                    };

                    if (desc_len > 2 + int_table_len * 4) {
                        println("ExtendedInterrupt: resource source and index", .{});
                        ext_interrupt.res_source_index = self.advance();
                        ext_interrupt.res_source = self.readBytes(desc_len - (2 + int_table_len * 4));
                    }

                    var res_desc = try self.allocator.create(ResourceDescriptor);
                    res_desc.* = ResourceDescriptor{
                        .ext_interrupt = ext_interrupt,
                    };

                    result = res_desc;
                };
            }
            else if (self.matchBits(@enumToInt(SmallResourceItemTag.io), 0x78)) |_| {
                if (self.readByte()) |info|
                if (self.readWord()) |addr_min|
                if (self.readWord()) |addr_max|
                if (self.readByte()) |addr_align|
                if (self.readByte()) |length| {
                    print("IO", .{});
                    var io_desc = try self.allocator.create(IoDesc);
                    io_desc.* = IoDesc{
                        .info = @bitCast(@TypeOf(io_desc.info), info),
                        .addr_min = addr_min,
                        .addr_max = addr_max,
                        .addr_align = addr_align,
                        .length = length,
                    };

                    var res_desc = try self.allocator.create(ResourceDescriptor);
                    res_desc.* = ResourceDescriptor{
                        .io = io_desc,
                    };

                    result = res_desc;
                };
            }

            self.indent -= 2;
            return result;
        }

        fn dataObject(self: *Self) !?*DataObject {
            var result: ?*DataObject = null;

            if (try self.computationalData()) |comp_data| {
                var data_obj = try self.allocator.create(DataObject);
                data_obj.* = DataObject{
                    .comp_data = comp_data,
                };
                result = data_obj;
            }
            else if (try self.package()) |pkg| {
                var data_obj = try self.allocator.create(DataObject);
                data_obj.* = DataObject{
                    .package = pkg,
                };
                result = data_obj;
            }
            // const result =
            //     computationalData();
            //     defPackage() or
            //     defVarPackage();

            return result;
        }

        fn computationalData(self: *Self) !?*ComputationalData {
            var result: ?*ComputationalData = null;

            if (self.byteConst()) |byte_const| {
                var comp_data = try self.allocator.create(ComputationalData);
                comp_data.* = ComputationalData{
                    .byte_const = byte_const,
                };
                result = comp_data;
            }
            else if (self.wordConst()) |word_const| {
                var comp_data = try self.allocator.create(ComputationalData);
                comp_data.* = ComputationalData{
                    .word_const = word_const,
                };
                result = comp_data;
            }
            else if (self.dwordConst()) |dword_const| {
                var comp_data = try self.allocator.create(ComputationalData);
                comp_data.* = ComputationalData{
                    .dword_const = dword_const,
                };
                result = comp_data;
            }
            else if (self.qwordConst()) |qword_const| {
                var comp_data = try self.allocator.create(ComputationalData);
                comp_data.* = ComputationalData{
                    .qword_const = qword_const,
                };
                result = comp_data;
            }
            else if (self.constObj()) |const_obj| {
                var comp_data = try self.allocator.create(ComputationalData);
                comp_data.* = ComputationalData{
                    .const_obj = const_obj,
                };
                result = comp_data;
            }
            else if (self.revision()) |rev| {
                var comp_data = try self.allocator.create(ComputationalData);
                comp_data.* = ComputationalData{
                    .revision = rev,
                };
                result = comp_data;
            }
            else if (try self.string()) |str| {
                var comp_data = try self.allocator.create(ComputationalData);
                comp_data.* = ComputationalData{
                    .string = str,
                };
                result = comp_data;
            }
            else if (try self.buffer()) |buff| {
                self.indent -= 2;
                var comp_data = try self.allocator.create(ComputationalData);
                comp_data.* = ComputationalData{
                    .buffer = buff,
                };
                result = comp_data;
                self.indent += 2;
            }

            return result;
        }

        fn byteConst(self: *Self) ?u8 {
            
            var result: ?u8 = null;

            if (self.matchPrefix(.BytePrefix)) {
                result = self.advance();
                // print("0x{x}", .{result});
            }

            return result;
        }

        fn wordConst(self: *Self) ?u16 {
            
            var result: ?u16 = null;

            if (self.matchPrefix(.WordPrefix)) {
                result = self.readWord();
                // print("0x{x}", .{result});
            }

            return result;
        }

        fn dwordConst(self: *Self) ?u32 {
            
            var result: ?u32 = null;

            if (self.matchPrefix(.DWordPrefix)) {
                result = self.readDWord();
                // print("0x{x}", .{result});
            }

            return result;
        }

        fn qwordConst(self: *Self) ?u64 {
            
            var result: ?u64 = null;

            if (self.matchPrefix(.QWordPrefix)) {
                result = self.readQWord();
                // print("0x{x}", .{result});
            }

            return result;
        }

        fn constObj(self: *Self) ?u8 {
            
            var result: ?u8 = null;

            if (self.matchOpCodeByte(.ZeroOp)) {
                result = 0x00;
                // print("0x{x}", .{result});
            } else if (self.matchOpCodeByte(.OneOp)) {
                result = 0x01;
                // print("0x{x}", .{result});
            } else if (self.matchOpCodeByte(.OnesOp)) {
                result = 0xFF;
                // print("0x{x}", .{result});
            }

            return result;
        }

        fn revision(self: *Self) ?u64 {
            var result: ?u8 = null;

            if (self.matchOpCodeWord(.RevisionOp)) {
                result = 1;
            }

            return null;
        }

        fn string(self: *Self) !?[:0]const u8 {
            var result: ?[:0]const u8 = null;
            if (self.matchPrefix(.StringPrefix)) {
                if (self.readString()) |str| {
                    result = try self.allocator.dupeZ(u8, str);
                    print("\"{s}\"", .{result});
                }
            }

            return result;
        }

        fn argObj(self: *Self) ?ArgObj {
            
            var result: ?ArgObj = null;

            if (self.matchByteRange(@enumToInt(OpCodeByte.Arg0Op), @enumToInt(OpCodeByte.Arg6Op))) |arg| {
                result = @intToEnum(ArgObj, arg);
                // print("{s}", .{@tagName(result.?)});
            }

            return result;
        }

        fn localObj(self: *Self) ?LocalObj {
            
            var result: ?LocalObj = null;

            if (self.matchByteRange(@enumToInt(OpCodeByte.Local0Op), @enumToInt(OpCodeByte.Local7Op))) |local| {
                result = @intToEnum(LocalObj, local);
                // print("{s}", .{@tagName(result.?)});
            }

            return result;
        }

        // fn defAlias(self: *Self) !*DefAlias {
        //     // printlnIndented(self.indent, @src().fn_name, .{});
        //     return null;
        // }

        fn defScope(self: *Self) !?*DefScope {
            self.indent += 2;

            var result: ?*DefScope = null;

            if (self.matchOpCodeByte(.ScopeOp)) {
                const start_loc = self.ctx.loc;
                if (self.pkgLength()) |pkglen| {
                    if (try self.nameString()) |name_str| {
                        printlnIndented(self.indent, "Scope ({s})", .{name_str.name});
                        const len = pkglen - (self.ctx.loc - start_loc);
                        var def_scope = try self.allocator.create(DefScope);
                        def_scope.* = DefScope{
                            .name = name_str,
                            .terms = undefined,
                        };
                        result = def_scope;

                        const ns_path = try self.ns_builder.addName(name_str.name, NamespaceObject{ .scope = def_scope });
                        try self.ns_builder.pushNamespace(ns_path);

                        def_scope.terms = try self.terms(len);

                        _ = self.ns_builder.popNamespace();
                    }
                }
            }

            self.indent -= 2;
            return result;
        }

        fn defName(self: *Self) !?*DefName {
            self.indent += 2;

            var result: ?*DefName = null;

            if (self.matchOpCodeByte(.NameOp)) {
                if (try self.nameString()) |name_str| {
                    printIndented(self.indent, "Name ({s}, ", .{name_str.name});
                    if (try self.dataRefObject()) |data_ref_obj| {
                        printlnIndented(self.indent, ")", .{});
                        var def_name = try self.allocator.create(DefName);
                        def_name.* = DefName{
                            .name = name_str,
                            .data_ref_obj = data_ref_obj,
                        };
                        result = def_name;

                        _ = try self.ns_builder.addName(name_str.name, NamespaceObject{ .name = def_name });
                    }
                }
            }

            self.indent -= 2;
            return result;
        }

        fn dataRefObject(self: *Self) !?*DataRefObject {
            var result: ?*DataRefObject = null;

            if (try self.dataObject()) |data_obj| {
                var data_ref_obj = try self.allocator.create(DataRefObject);
                data_ref_obj.* = DataRefObject{
                    .data_obj = data_obj,
                };
                result = data_ref_obj;
            }
            else if (try self.termArg()) |term_arg| {
                var data_ref_obj = try self.allocator.create(DataRefObject);
                data_ref_obj.* = DataRefObject{
                    .obj_ref = term_arg,
                };
                result = data_ref_obj;
            }

            return result;
        }

        fn pkgLength(self: *Self) ?u32 {
            return self.matchPkgLength();
        }

        fn pkgPayload(self: *Self) ?[]const u8 {
            const pkg_start = self.ctx.loc;
            if (self.matchPkgLength()) |pkg_len| {
                if (pkg_start + pkg_len < self.ctx.block.len) {
                    return self.ctx.block[self.ctx.loc..(pkg_start + pkg_len)];
                }
            }
            return null;
        }

        fn nameString(self: *Self) !?*NameString {
            var result: ?*NameString = null;

            if(self.matchChar(.RootChar)) {
                if (try self.namePath()) |name_path| {
                    var name_string = try self.allocator.create(NameString);
                    name_string.* = NameString{
                        .name = try std.mem.concat(self.allocator, u8, &[_][]const u8{ "\\", name_path }),
                    };
                    result = name_string;
                } else if (self.nullName()) {
                    var name_string = try self.allocator.create(NameString);
                    name_string.* = NameString{
                        .name = try self.allocator.dupe(u8, "\\"),
                    };
                    result = name_string;
                }
            }
            else if (try self.prefixPath()) |prefix_path| {
                if (try self.namePath()) |name_path| {
                    var name_string = try self.allocator.create(NameString);
                    name_string.* = NameString{
                        .name = try std.mem.concat(self.allocator, u8, &[_][]const u8{ prefix_path, name_path }),
                    };
                    result = name_string;
                } else if (self.nullName()) {
                    var name_string = try self.allocator.create(NameString);
                    name_string.* = NameString{
                        .name = prefix_path,
                    };
                    result = name_string;
                }
            }
            else if (try self.namePath()) |name_path| {
                var name_string = try self.allocator.create(NameString);
                name_string.* = NameString{
                    .name = name_path,
                };
                result = name_string;
            }

            return result;
        }

        fn prefixPath(self: *Self) !?[]u8 {
            var result: ?[]u8 = null;

            var count: usize = 0;
            while (self.matchChar(.ParentPrefixChar)) {
                count += 1;
            }
            if (count > 0) {
                var prefix_path = try self.allocator.alloc(u8, count);
                std.mem.set(u8, prefix_path, '^');
                result = prefix_path;
            }

            return result;
        }

        fn namePath(self: *Self) !?[]const u8 {
            var result: ?[]const u8 = null;

            if(self.nameSeg()) |name_seg| {
                var name_path = try self.allocator.alloc(u8, name_seg.len);
                std.mem.copy(u8, name_path, name_seg[0..]);
                result = name_path;
            } else if (try self.dualNamePath()) |dual_name_path| {
                result = dual_name_path;
            } else if (try self.multiNamePath()) |multi_name_path| {
                result = multi_name_path;
            }

            return result;
        }

        fn nameSeg(self: *Self) ?[4]u8 {
            var result: ?[4]u8 = null;

            if (self.leadNameChar()) |ch1| {
                if (self.nameChar()) |ch2| {
                    if (self.nameChar()) |ch3| {
                        if (self.nameChar()) |ch4| {
                            result = [_]u8{ ch1, ch2, ch3, ch4 };
                        }
                    }
                }
            }

            return result;
        }

        fn leadNameChar(self: *Self) ?u8 {
            var result: ?u8 = null;

            if (self.matchCharRange(.AlphaChar_Start, .AlphaChar_End)) |ch| {
                result = ch;
            }
            else if (self.matchChar(.UnderscoreChar)) {
                result = '_';
            }

            return result;
        }

        fn nameChar(self: *Self) ?u8 {
            var result: ?u8 = null;

            if (self.leadNameChar()) |ch| {
                result = ch;
            }
            else if (self.matchCharRange(.DigitChar_Start, .DigitChar_End)) |ch| {
                result = ch;
            }

            return result;
        }

        fn asciiChar(self: *Self) ?u8 {
            var result: ?u8 = null;

            if (self.matchCharRange(.AsciiChar_Start, .AsciiChar_End)) |ch| {
                result = ch;
            }

            return result;
        }

        fn dualNamePath(self: *Self) !?[]const u8 {
            var result: ?[]const u8 = null;

            if (self.matchPrefix(.DualNamePrefix)) {
                if (self.nameSeg()) |seg1| {
                    if (self.nameSeg()) |seg2| {
                        result = try std.mem.concat(self.allocator, u8, &[_][]const u8{ seg1[0..], ".", seg2[0..] });
                    }
                }
            }

            return result;
        }

        fn multiNamePath(self: *Self) !?[]const u8 {
            var result: ?[]const u8 = null;

            if (self.matchPrefix(.MultiNamePrefix)) {
                if (self.advance()) |seg_count| {
                    var list = std.ArrayList([]const u8).init(self.allocator);
                    var i: usize = 0;
                    while (i < seg_count) : (i += 1) {
                        if (self.nameSeg()) |seg| {
                            try list.append(try std.mem.dupe(self.allocator, u8, seg[0..]));
                        } else {
                            return null;
                        }
                    }
                    result = try std.mem.join(self.allocator, ".", list.items);
                }
            }

            return result;
        }

        fn nullName(self: *Self) bool {
            return self.matchChar(.Null);
        }

        //
        // matching routines
        //

        fn matchOpCodeByte(self: *Self, opCode: OpCodeByte) bool {
            // // printlnIndented(self.indent, @src().fn_name, .{});
            if (self.peekByte()) |byte| {
                if (byte == @enumToInt(opCode)) {
                    _ = self.advance();
                    return true;
                }
            }
            return false;
        }

        fn matchOpCodeWord(self: *Self, opCode: OpCodeWord) bool {
            // // printlnIndented(self.indent, @src().fn_name, .{});
            if (self.peekWord()) |word| {
                if (word == @enumToInt(opCode)) {
                    _ = self.advance();
                    _ = self.advance();
                    return true;
                }
            }
            return false;
        }

        fn matchPrefix(self: *Self, prefix: Prefix) bool {
            // // printlnIndented(self.indent, @src().fn_name, .{});
            return self.matchByte(@enumToInt(prefix));
        }

        fn matchChar(self: *Self, ch: Char) bool {
            // // printlnIndented(self.indent, @src().fn_name, .{});
            return self.matchByte(@enumToInt(ch));
        }

        fn matchCharRange(self: *Self, start: Char, end: Char) ?u8 {
            // // printlnIndented(self.indent, @src().fn_name, .{});
            return self.matchByteRange(@enumToInt(start), @enumToInt(end));
        }

        fn matchBits(self: *Self, byte: u8, mask: u8) ?u8 {
            if (self.peekByte()) |b| {
                if (b & mask == byte) {
                    return self.advance();
                }
            }
            return null;
        }

        fn matchByte(self: *Self, byte: u8) bool {
            // // printlnIndented(self.indent, @src().fn_name, .{});
            if (self.peekByte()) |b| {
                if (b == byte) {
                    _ = self.advance();
                    return true;
                }
            }
            return false;
        }

        fn matchByteRange(self: *Self, start: u8, end: u8) ?u8 {
            // // printlnIndented(self.indent, @src().fn_name, .{});
            if (self.peekByte()) |byte| {
                if (byte >= start and byte <= end) {
                    return self.advance();
                }
            }
            return null;
        }

        fn matchPkgLength(self: *Self) ?u32 {
            var length: ?u32 = null;

            if (self.peekByte()) |lead_byte| {
                var count = lead_byte >> 6;
                if (count == 0) {
                    if (self.advance()) |byte| {
                        length = @intCast(u32, byte & 0x3F);
                    }
                }
                else if (lead_byte & 0b00110000 == 0) {
                    if (self.advance()) |byte| {
                        var len = @intCast(u32, byte & 0x0F);
                        var i: usize = 1;
                        while (i < count + 1) : (i += 1) {
                            if (self.advance()) |next_byte| {
                                len |= @intCast(u32, next_byte) << @intCast(u5, i * 8 - 4);
                            } else {
                                break;
                            }
                        }
                        length = len;
                    }
                }
            }

            return length;
        }

        fn peekByte(self: *Self) ?u8 {
            if (self.ctx.loc >= self.ctx.block.len) {
                return null;
            }
            return self.ctx.block[self.ctx.loc];
        }

        fn peekWord(self: *Self) ?u16 {
            if (self.ctx.loc >= self.ctx.block.len - 1) {
                return null;
            }
            return self.ctx.block[self.ctx.loc] | @intCast(u16, self.ctx.block[self.ctx.loc + 1]) << 8;
        }

        fn readByte(self: *Self) ?u8 {
            return self.advance();
        }

        fn readWord(self: *Self) ?u16 {
            if (self.advance()) |lo| {
                if (self.advance()) |hi| {
                    return @intCast(u16, lo) | @intCast(u16, hi) << 8;
                }
            }
            return null;
        }

        fn readDWord(self: *Self) ?u32 {
            if (self.readWord()) |lo| {
                if (self.readWord()) |hi| {
                    return @intCast(u32, lo) | @intCast(u32, hi) << 16;
                }
            }
            return null;
        }

        fn readQWord(self: *Self) ?u64 {
            if (self.readDWord()) |lo| {
                if (self.readDWord()) |hi| {
                    return @intCast(u64, lo) | @intCast(u64, hi) << 32;
                }
            }
            return null;
        }

        fn readBytes(self: *Self, len: usize) ?[]const u8 {
            if (self.ctx.loc + len - 1 < self.ctx.block.len) {
                defer self.ctx.loc += len;
                return self.ctx.block[self.ctx.loc..(self.ctx.loc + len)];
            }
            return null;
        }

        fn readWords(self: *Self, len: usize) ?[]align(1) const u16 {
            if (self.readBytes(len * 2)) |bytes| {
                return std.mem.bytesAsSlice(u16, bytes);
            }
            return null;
        }

        fn readDWords(self: *Self, len: usize) ?[]align(1) const u32 {
            if (self.readBytes(len * 4)) |bytes| {
                println("bytes = {*}", .{bytes.ptr});
                return std.mem.bytesAsSlice(u32, bytes);
            }
            return null;
        }

        fn readQWords(self: *Self, len: usize) ?[]align(1) const u64 {
            if (self.readBytes(len * 8)) |bytes| {
                return std.mem.bytesAsSlice(u64, bytes);
            }
            return null;
        }

        fn readString(self: *Self) ?[]const u8 {
            const start = self.ctx.loc;
            while (self.ctx.block[self.ctx.loc] != 0 and self.ctx.loc < self.ctx.block.len) {
                self.ctx.loc += 1;
            }
            if (self.ctx.loc < self.ctx.block.len) {
                self.ctx.loc += 1;
                return self.ctx.block[start..(self.ctx.loc - 1)];
            }
            return null;
        }

        fn advance(self: *Self) ?u8 {
            if (self.ctx.loc >= self.ctx.block.len) {
                return null;
            }
            self.ctx.loc += 1;
            return self.ctx.block[self.ctx.loc - 1];
        }
    };
}
