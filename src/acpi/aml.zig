const io = @import("../io.zig");
const print = io.print;
const println = io.println;
const std = @import("std");
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const AllocationError = std.mem.Allocator.Error;

const Prefix = enum(u8) {
    BytePrefix         = 0x0A,
    WordPrefix         = 0x0B,
    DWordPrefix        = 0x0C,
    StringPrefix       = 0x0D,
    QWordPrefix        = 0x0E,
    DualNamePrefix     = 0x2E, // ('.')
    MultiNamePrefix    = 0x2F, // ('/')
    ExtOpPrefix        = 0x5B, // ('[')'
};

const Char = enum(u8) {
    Null               = 0x00,
    DigitChar_Start    = 0x30, // ('0'-'9')
    DigitChar_End      = 0x39, // ('0'-'9')
    AlphaChar_Start    = 0x41, // ('A'-'Z')
    AlphaChar_End      = 0x5A, // ('A'-'Z')
    RootChar           = 0x5C, // ('\')
    ParentPrefixChar   = 0x5E, // ('^')
    UnderscoreChar     = 0x5F, // ('_')
    AsciiChar_Start    = 0x01,
    AsciiChar_End      = 0x7F,
};

const OpCodeByte = enum(u8) {
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
    Local0Op           = 0x60, // ('`')
    Local1Op           = 0x61, // ('a')
    Local2Op           = 0x62, // ('b')
    Local3Op           = 0x63, // ('c')
    Local4Op           = 0x64, // ('d')
    Local5Op           = 0x65, // ('e')
    Local6Op           = 0x66, // ('f')
    Local7Op           = 0x67, // ('g')
    Arg0Op             = 0x68, // ('h')
    Arg1Op             = 0x69, // ('i')
    Arg2Op             = 0x6A, // ('j')
    Arg3Op             = 0x6B, // ('k')
    Arg4Op             = 0x6C, // ('l')
    Arg5Op             = 0x6D, // ('m')
    Arg6Op             = 0x6E, // ('n')
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

const OpCodeWord = enum(u16) {
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

const TermObj = union(enum) {
    obj: *Object,
    stmt_opcode: *StatementOpcode,
    expr_opcode: *ExpressionOpcode,
};

const StatementOpcode = union(enum) {
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

const Break = struct {};

const IfElse = struct {
    predicate: *TermArg,
    terms: []TermObj,
    else_terms: ?[]TermObj,
};

const Notify = struct {
    object: *SuperName,
    value: *TermArg,
};

const Release = struct {
    mutex: *SuperName,
};

const Return = struct {
    arg_obj: *TermArg,
};

const While = struct {
    predicate: *TermArg,
    terms: []TermObj,
};

const ExpressionOpcode = union(enum) {
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

const Acquire = struct {
    mutex: *SuperName,
    timeout: u32,
};

const Add = struct {
    operand1: *TermArg,
    operand2: *TermArg,
    target: ?*Target,
};

const LAnd = struct {
    operand1: *TermArg,
    operand2: *TermArg,
};

const Buffer = struct {
    size: *TermArg,
    bytes: []u8,
};

const DerefOf = struct {
    obj_ref: *TermArg,
};

const Increment = struct {
    operand: *SuperName,
};

const Index = struct {
    obj: *TermArg,
    index: *TermArg,
    target: ?*Target,
};

const LEqual = struct {
    operand1: *TermArg,
    operand2: *TermArg,
};

const LGreater = struct {
    operand1: *TermArg,
    operand2: *TermArg,
};

const LLess = struct {
    operand1: *TermArg,
    operand2: *TermArg,
};

const LNot = struct {
    operand: *TermArg,
};

const LOr = struct {
    operand1: *TermArg,
    operand2: *TermArg,
};

const Or = struct {
    operand1: *TermArg,
    operand2: *TermArg,
    target: ?*Target,
};

const And = struct {
    operand1: *TermArg,
    operand2: *TermArg,
    target: ?*Target,
};

const Package = struct {
    n_elements: u8,
    elements: []PackageElement,
};

const PackageElement = union(enum) {
    data_obj: *DataObject,
    name: *NameString,
};

const RefOf = struct {
    source: *SuperName,
};

const ShiftLeft = struct {
    operand: *TermArg,
    shift_count: *TermArg,
    target: ?*Target,
};

const ShiftRight = struct {
    operand: *TermArg,
    shift_count: *TermArg,
    target: ?*Target,
};

const SizeOf = struct {
    operand: *SuperName,
};

const Store = struct {
    source: *TermArg,
    dest: *SuperName,
};

const Subtract = struct {
    operand1: *TermArg,
    operand2: *TermArg,
    target: ?*Target,
};

const ToBuffer = struct {
    operand: *TermArg,
    target: ?*Target,
};

const ToHexString = struct {
    operand: *TermArg,
    target: ?*Target,
};

const MethodInvocation = struct {
    name: *NameString,
    args: []TermArg,
};

const Target = union(enum) {
    name: *SuperName,
    null_: void,
};

const SuperName = union(enum) {
    simple_name: *SimpleName,
    debug_obj: *DebugObj,
    ref_type_opcode: *ReferenceTypeOpcode,
};

const SimpleName = union(enum) {
    name: *NameString,
    arg: ArgObj,
    local: LocalObj
};

const DebugObj = struct {};

const ReferenceTypeOpcode = union(enum) {
    ref_of: *RefOf,
    deref_of: *DerefOf,
    index: *Index,
};

const Object = union(enum) {
    ns_mod_obj: *NameSpaceModifierObj,
    named_obj: *NamedObj,
};

const NameSpaceModifierObj = union(enum) {
    // def_alias: *DefAlias,
    def_name: *DefName,
    def_scope: *DefScope,
};

const DefScope = struct {
    name: *NameString,
    terms: []TermObj,
};

const DefName = struct {
    name: *NameString,
    data_ref_obj: *DataRefObject,
};

const DataRefObject = union(enum) {
    data_obj: *DataObject,
    obj_ref: u64,
};

const NameString = struct {
    name: []const u8,
};

const NamedObj = union(enum) {
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

const DefField = struct {
    name: *NameString,
    flags: u8,
    field_elements: []FieldElement,
};

const FieldElement = union(enum) {
    named_fld: *NamedField,
    reserved_fld: *ReservedField,
    // access_fld: AccessField,
    // ext_access_fld: ExtendedAccessField,
    // connect_fld: ConnectField,
};

const NamedField = struct {
    name: NameSeg,
    bits: u32,
};

const ReservedField = struct {
    len: u32,
};

const NameSeg = [4]u8;

const DefMethod = struct {
    name: *NameString,
    arg_count: u3,
    flags: u8,
    terms: []TermObj,
};

const DefCreateDWordField = struct {
    source_buff: *TermArg,
    byte_index: *TermArg,
    field_name: *NameString,
};

const DefDevice = struct {
    name: *NameString,
    terms: []TermObj,
};

const DefMutex = struct {
    name: *NameString,
    sync_flags: u8,
};

const DefOpRegion = struct {
    name: *NameString,
    space: u8,
    offset: *TermArg,
    len: *TermArg,
};

// deprecated in 6.4
const DefProcessor = struct {
    name: *NameString,
    proc_id: u8,
    pblk_addr: u32,
    pblk_len: u8,
    terms: []TermObj,
};

const TermArg = union(enum) {
    expr_opcode: *ExpressionOpcode,
    data_obj: *DataObject,
    arg_obj: ArgObj,
    local_obj: LocalObj,
    name_str: *NameString,
};

const DataObject = union(enum) {
    comp_data: *ComputationalData,
    // DefPackage,
    // DefVarPackage,
};

const ArgObj = enum(u8) {
    arg0 = @enumToInt(OpCodeByte.Arg0Op),
    arg1 = @enumToInt(OpCodeByte.Arg1Op),
    arg2 = @enumToInt(OpCodeByte.Arg2Op),
    arg3 = @enumToInt(OpCodeByte.Arg3Op),
    arg4 = @enumToInt(OpCodeByte.Arg4Op),
    arg5 = @enumToInt(OpCodeByte.Arg5Op),
    arg6 = @enumToInt(OpCodeByte.Arg6Op),
};

const LocalObj = enum(u8) {
    local0 = @enumToInt(OpCodeByte.Local0Op),
    local1 = @enumToInt(OpCodeByte.Local1Op),
    local2 = @enumToInt(OpCodeByte.Local2Op),
    local3 = @enumToInt(OpCodeByte.Local3Op),
    local4 = @enumToInt(OpCodeByte.Local4Op),
    local5 = @enumToInt(OpCodeByte.Local5Op),
    local6 = @enumToInt(OpCodeByte.Local6Op),
    local7 = @enumToInt(OpCodeByte.Local7Op)
};

const ComputationalData = union(enum) {
    byte_const: u8,
    word_const: u16,
    dword_const: u32,
    // QWordConst,
    string: [:0]const u8,
    const_obj: u8,
    // RevisionOp,
    // DefBuffer,
};

// Namespace

const ObjectType = enum {
    Uninitialized,
    Integer,
    String,
    Buffer,
    Package,
    FieldUnit,
    Device,
    Event,
    Method,
    Mutex,
    OpRegion,
    PowerResource,
    Processor,
    ThermalZone,
    BufferField,
    _Reserved2,
    DebugObject,
};

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

        pub fn init(alloc: *std.mem.Allocator) Self {
            var names = std.StringHashMap(NamespaceObject).init(alloc);
            
            // hack: add missing method
            // var pcnt_method = try alloc.create(NameString);
            // pcnt_method.* = NameString{ .name = "PCNT" };
            // names.append("\\_SB.PCI0.PCNT", DefMethod{
            //     .name = pcnt_method,
            //     .arg_count = 1,
            //     .flags = 1,
            //     .terms = .{},
            // });

            return .{
                .alloc = alloc,
                .stack = std.ArrayList([]const u8).init(alloc),
                .names = names,
            };
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

var buf: [1024 * 1024]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&buf);
const allocator = &fba.allocator;

var method_names = std.StringHashMap(u8).init(allocator);
var ns_builder = NamespaceBuilder().init(allocator);

var block: []const u8 = undefined;
var loc: usize = 0;
var indent: usize = 0;

fn printIndented(comptime str: [:0]const u8, args: anytype) void {
    var i: usize = 0;
    while (i < indent) : (i += 1) {
        print(" ", .{});
    }
    println(str, args);
}

pub fn parse(aml_block: []const u8) void {
    block = aml_block;
    _ = terms(aml_block.len) catch |err| {
        println("error: {}", .{err});
    };

    ns_builder.print();
}

fn terms(len: usize) AllocationError![]TermObj {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: []TermObj = undefined;
    var list = std.ArrayList(TermObj).init(allocator);

    const start_loc = loc;
    while (loc < start_loc + len) {
        if (try termObj()) |term_obj| {
            try list.append(term_obj.*);
        }
        else {
            break;
        }
    }

    result = list.items;

    indent -= 2;
    return result;
}

fn termObj() !?*TermObj {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*TermObj = null;

    if (try object()) |obj| {
        var term_obj = try allocator.create(TermObj);
        term_obj.* = TermObj{
            .obj = obj,
        };
        result = term_obj;
    }
    else if (try statementOpCode()) |stmt_opcode| {
        var term_obj = try allocator.create(TermObj);
        term_obj.* = TermObj{
            .stmt_opcode = stmt_opcode,
        };
        result = term_obj;
    }
    else if (try expressionOpCode()) |expr_opcode| {
        var term_obj = try allocator.create(TermObj);
        term_obj.* = TermObj{
            .expr_opcode = expr_opcode,
        };
        result = term_obj;
    }

    indent -= 2;
    return result;
}

fn object() !?*Object {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*Object = null;

    if (try namespaceModifierObj()) |ns_mod_obj| {
        var obj = try allocator.create(Object);
        obj.* = Object{
            .ns_mod_obj = ns_mod_obj,
        };
        result = obj;
    }
    else if (try namedObj()) |named_obj| {
        var obj = try allocator.create(Object);
        obj.* = Object{
            .named_obj = named_obj,
        };
        result = obj;
    }

    indent -= 2;
    return result;
}

fn statementOpCode() !?*StatementOpcode {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*StatementOpcode = null;

    if (matchOpCodeByte(.BreakOp)) {
        printIndented("Break()", .{});
        var stmt_opcode = try allocator.create(StatementOpcode);
        stmt_opcode.* = StatementOpcode{
            .break_ = try allocator.create(Break),
        };
        result = stmt_opcode;
    }
    if (matchOpCodeByte(.IfOp)) {
        var pkg_start = loc;
        if (pkgLength()) |pkglen_if| {
            printIndented("If()", .{});
            if (try termArg()) |predicate| {
                const len_if = pkglen_if - (loc - pkg_start);
                var if_else = try allocator.create(IfElse);
                if_else.* = IfElse{
                    .predicate = predicate,
                    .terms = try terms(len_if),
                    .else_terms = null,
                };
                if (matchOpCodeByte(.ElseOp)) {
                    printIndented("Else()", .{});
                    pkg_start = loc;
                    if (pkgLength()) |pkglen_else| {
                        const len_else = pkglen_else - (loc - pkg_start);
                        if_else.else_terms = try terms(len_else);
                    }
                }

                var stmt_opcode = try allocator.create(StatementOpcode);
                stmt_opcode.* = StatementOpcode{
                    .if_else = if_else,
                };

                result = stmt_opcode;
            }
        }
    }
    else if (matchOpCodeByte(.NotifyOp)) {
        if (try superName()) |obj| {
            if (try termArg()) |value| {
                printIndented("Notify()", .{});
                var notify = try allocator.create(Notify);
                notify.* = Notify{
                    .object = obj,
                    .value = value,
                };

                var stmt_opcode = try allocator.create(StatementOpcode);
                stmt_opcode.* = StatementOpcode{
                    .notify = notify,
                };

                result = stmt_opcode;
            }
        }
    }
    else if (matchOpCodeWord(.ReleaseOp)) {
        if (try superName()) |mutex| {
            printIndented("Release()", .{});
            var release = try allocator.create(Release);
            release.* = Release{
                .mutex = mutex,
            };

            var stmt_opcode = try allocator.create(StatementOpcode);
            stmt_opcode.* = StatementOpcode{
                .release = release,
            };

            result = stmt_opcode;
        }
    }
    else if (matchOpCodeByte(.ReturnOp)) {
        printIndented("Return()", .{});
        if (try termArg()) |arg_obj| {
            var return_ = try allocator.create(Return);
            return_.* = Return{
                .arg_obj = arg_obj,
            };

            var stmt_opcode = try allocator.create(StatementOpcode);
            stmt_opcode.* = StatementOpcode{
                .return_ = return_,
            };

            result = stmt_opcode;
        }
    }
    else if (matchOpCodeByte(.WhileOp)) {
        const start_loc = loc;
        if (pkgLength()) |pkglen| {
            printIndented("While()", .{});
            if (try termArg()) |predicate| {
                const len = pkglen - (loc - start_loc);
                var while_ = try allocator.create(While);
                while_.* = While{
                    .predicate = predicate,
                    .terms = try terms(len),
                };

                var stmt_opcode = try allocator.create(StatementOpcode);
                stmt_opcode.* = StatementOpcode{
                    .while_ = while_,
                };

                result = stmt_opcode;
            }
        }
    }

    indent -= 2;
    return result;
}

fn expressionOpCode() !?*ExpressionOpcode {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*ExpressionOpcode = null;

    if (matchOpCodeWord(.AcquireOp)) {
        if (try superName()) |mutex| {
            if (readWord()) |timeout| {
                printIndented("Acquire()", .{});
                var acquire = try allocator.create(Acquire);
                acquire.* = Acquire{
                    .mutex = mutex,
                    .timeout = timeout,
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .acquire = acquire,
                };

                result = expr_opcode;
            }
        }
    }
    else if (matchOpCodeByte(.AddOp)) {
        printIndented("Add()", .{});
        if (try termArg()) |operand1| {
            if (try termArg()) |operand2| {
                if (try target()) |tgt| {
                    var add = try allocator.create(Add);
                    add.* = Add{
                        .operand1 = operand1,
                        .operand2 = operand2,
                        .target = tgt,
                    };

                    var expr_opcode = try allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .add = add,
                    };

                    result = expr_opcode;
                }
            }
        }
    }
    else if (matchOpCodeByte(.LandOp)) {
        printIndented("LAnd()", .{});
        if (try termArg()) |operand1| {
            if (try termArg()) |operand2| {
                var land = try allocator.create(LAnd);
                land.* = LAnd{
                    .operand1 = operand1,
                    .operand2 = operand2,
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .land = land,
                };

                result = expr_opcode;

            }
        }
    }
    else if (matchOpCodeByte(.BufferOp)) {
        const start_loc = loc;
        if (pkgLength()) |pkglen| {
            printIndented("Buffer()", .{});
            if (try termArg()) |size| {
                const len = pkglen - (loc - start_loc);
                var buffer = try allocator.create(Buffer);
                buffer.* = Buffer{
                    .size = size,
                    .bytes = try allocator.dupe(u8, block[loc..loc+len]),
                };
                var i: usize = 0;
                while (i < len) : (i += 1) {
                    _ = advance();
                }
                // println("buffer size={}, bytes.len={}", .{size, buffer.bytes.len});

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .buffer = buffer,
                };

                result = expr_opcode;
            }
        }
    }
    else if (matchOpCodeByte(.DerefOfOp)) {
        printIndented("DerefOf()", .{});
        if (try termArg()) |obj_ref| {
            var deref_of = try allocator.create(DerefOf);
            deref_of.* = DerefOf{
                .obj_ref = obj_ref,
            };

            var expr_opcode = try allocator.create(ExpressionOpcode);
            expr_opcode.* = ExpressionOpcode{
                .deref_of = deref_of,
            };

            result = expr_opcode;

        }
    }
    else if (matchOpCodeByte(.LEqualOp)) {
        printIndented("LEqual()", .{});
        if (try termArg()) |operand1| {
            if (try termArg()) |operand2| {
                var lequal = try allocator.create(LEqual);
                lequal.* = LEqual{
                    .operand1 = operand1,
                    .operand2 = operand2,
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .lequal = lequal,
                };

                result = expr_opcode;

            }
        }
    }
    else if (matchOpCodeByte(.LGreaterOp)) {
        printIndented("LGreater()", .{});
        if (try termArg()) |operand1| {
            if (try termArg()) |operand2| {
                var lgreater = try allocator.create(LGreater);
                lgreater.* = LGreater{
                    .operand1 = operand1,
                    .operand2 = operand2,
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .lgreater = lgreater,
                };

                result = expr_opcode;

            }
        }
    }
    else if (matchOpCodeByte(.LLessOp)) {
        printIndented("LLess()", .{});
        if (try termArg()) |operand1| {
            if (try termArg()) |operand2| {
                var lless = try allocator.create(LLess);
                lless.* = LLess{
                    .operand1 = operand1,
                    .operand2 = operand2,
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .lless = lless,
                };

                result = expr_opcode;

            }
        }
    }
    else if (matchOpCodeByte(.LnotOp)) {
        printIndented("LNot()", .{});
        if (try termArg()) |operand| {
            var lnot = try allocator.create(LNot);
            lnot.* = LNot{
                .operand = operand,
            };

            var expr_opcode = try allocator.create(ExpressionOpcode);
            expr_opcode.* = ExpressionOpcode{
                .lnot = lnot,
            };

            result = expr_opcode;

        }
    }
    else if (matchOpCodeByte(.IncrementOp)) {
        printIndented("Increment()", .{});
        if (try superName()) |operand| {
            var increment = try allocator.create(Increment);
            increment.* = Increment{
                .operand = operand,
            };

            var expr_opcode = try allocator.create(ExpressionOpcode);
            expr_opcode.* = ExpressionOpcode{
                .increment = increment,
            };

            result = expr_opcode;

        }
    }
    else if (matchOpCodeByte(.IndexOp)) {
        printIndented("Index()", .{});
        if (try termArg()) |obj| {
            if (try termArg()) |index_val| {
                if (try target()) |tgt| {
                    var index = try allocator.create(Index);
                    index.* = Index{
                        .obj = obj,
                        .index = index_val,
                        .target = tgt,
                    };

                    var expr_opcode = try allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .index = index,
                    };

                    result = expr_opcode;
                }
            }
        }
    }
    else if (matchOpCodeByte(.PackageOp)) {
        printIndented("Package()", .{});
        if (pkgLength()) |_| {
            if (advance()) |n_elements| {
                var list = std.ArrayList(PackageElement).init(allocator);
                var i: usize = 0;
                while (i < n_elements) : (i += 1) {
                    if (try packageElement()) |pkg_elem| {
                        try list.append(pkg_elem.*);
                    }
                }
                var package = try allocator.create(Package);
                package.* = Package{
                    .n_elements = n_elements,
                    .elements = list.items,
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .package = package,
                };

                result = expr_opcode;
            }
        }
    }
    else if (matchOpCodeByte(.RefOfOp)) {
        printIndented("RefOf()", .{});
        if (try superName()) |source| {
            var ref_of = try allocator.create(RefOf);
            ref_of.* = RefOf{
                .source = source,
            };

            var expr_opcode = try allocator.create(ExpressionOpcode);
            expr_opcode.* = ExpressionOpcode{
                .ref_of = ref_of,
            };

            result = expr_opcode;
        }
    }
    else if (matchOpCodeByte(.LorOp)) {
        printIndented("LOr()", .{});
        if (try termArg()) |operand1| {
            if (try termArg()) |operand2| {
                var lor = try allocator.create(LOr);
                lor.* = LOr{
                    .operand1 = operand1,
                    .operand2 = operand2,
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .lor = lor,
                };

                result = expr_opcode;
            }
        }
    }
    else if (matchOpCodeByte(.OrOp)) {
        printIndented("Or()", .{});
        if (try termArg()) |operand1| {
            if (try termArg()) |operand2| {
                if (try target()) |tgt| {
                    var or_ = try allocator.create(Or);
                    or_.* = Or{
                        .operand1 = operand1,
                        .operand2 = operand2,
                        .target = tgt,
                    };

                    var expr_opcode = try allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .or_ = or_,
                    };

                    result = expr_opcode;
                }
            }
        }
    }
    else if (matchOpCodeByte(.AndOp)) {
        printIndented("And()", .{});
        if (try termArg()) |operand1| {
            if (try termArg()) |operand2| {
                if (try target()) |tgt| {
                    var and_ = try allocator.create(And);
                    and_.* = And{
                        .operand1 = operand1,
                        .operand2 = operand2,
                        .target = tgt,
                    };

                    var expr_opcode = try allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .and_ = and_,
                    };

                    result = expr_opcode;
                }
            }
        }
    }
    else if (matchOpCodeByte(.ShiftLeftOp)) {
        printIndented("ShiftLeft()", .{});
        if (try termArg()) |operand| {
            if (try termArg()) |shift_count| {
                if (try target()) |tgt| {
                    var shl = try allocator.create(ShiftLeft);
                    shl.* = ShiftLeft{
                        .operand = operand,
                        .shift_count = shift_count,
                        .target = tgt,
                    };

                    var expr_opcode = try allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .shift_left = shl,
                    };

                    result = expr_opcode;
                }
            }
        }
    }
    else if (matchOpCodeByte(.ShiftRightOp)) {
        printIndented("ShiftRight()", .{});
        if (try termArg()) |operand| {
            if (try termArg()) |shift_count| {
                if (try target()) |tgt| {
                    var shr = try allocator.create(ShiftRight);
                    shr.* = ShiftRight{
                        .operand = operand,
                        .shift_count = shift_count,
                        .target = tgt,
                    };

                    var expr_opcode = try allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .shift_right = shr,
                    };

                    result = expr_opcode;
                }
            }
        }
    }
    else if (matchOpCodeByte(.SizeOfOp)) {
        printIndented("SizeOf()", .{});
        if (try superName()) |operand| {
            var size_of = try allocator.create(SizeOf);
            size_of.* = SizeOf{
                .operand = operand,
            };

            var expr_opcode = try allocator.create(ExpressionOpcode);
            expr_opcode.* = ExpressionOpcode{
                .size_of = size_of,
            };

            result = expr_opcode;

        }
    }
    else if (matchOpCodeByte(.StoreOp)) {
        printIndented("Store()", .{});
        if (try termArg()) |source| {
            if (try superName()) |dest| {
                var store = try allocator.create(Store);
                store.* = Store{
                    .source = source,
                    .dest = dest,
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .store = store,
                };

                result = expr_opcode;
            }
        }
    }
    else if (matchOpCodeByte(.SubtractOp)) {
        printIndented("Subtract()", .{});
        if (try termArg()) |operand1| {
            if (try termArg()) |operand2| {
                if (try target()) |tgt| {
                    var subtract = try allocator.create(Subtract);
                    subtract.* = Subtract{
                        .operand1 = operand1,
                        .operand2 = operand2,
                        .target = tgt,
                    };

                    var expr_opcode = try allocator.create(ExpressionOpcode);
                    expr_opcode.* = ExpressionOpcode{
                        .subtract = subtract,
                    };

                    result = expr_opcode;
                }
            }
        }
    }
    else if (matchOpCodeByte(.ToBufferOp)) {
        printIndented("ToBuffer()", .{});
        if (try termArg()) |operand| {
            if (try target()) |tgt| {
                var to_buffer = try allocator.create(ToBuffer);
                to_buffer.* = ToBuffer{
                    .operand = operand,
                    .target = tgt,
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .to_buffer = to_buffer,
                };

                result = expr_opcode;
            }
        }
    }
    else if (matchOpCodeByte(.ToHexStringOp)) {
        printIndented("ToHexString()", .{});
        if (try termArg()) |operand| {
            if (try target()) |tgt| {
                var to_hex_string = try allocator.create(ToHexString);
                to_hex_string.* = ToHexString{
                    .operand = operand,
                    .target = tgt,
                };

                var expr_opcode = try allocator.create(ExpressionOpcode);
                expr_opcode.* = ExpressionOpcode{
                    .to_hex_string = to_hex_string,
                };

                result = expr_opcode;
            }
        }
    }
    else {
        // Due to ambiguity between ExpressionOpcode->MethodInvocation and TermArg->NameString
        // we need to keep track of the start loc to rewind to in case this is not a method name
        const start_loc = loc;
        if (try nameString()) |name_str| {
            if (try ns_builder.getName(name_str.name)) |obj| {
                // printIndented("found namespace object ({})", .{obj});
                switch (obj) {
                    .method => |method| {
                        printIndented("MethodInvocation ({s})", .{name_str.name});
                        var list = std.ArrayList(TermArg).init(allocator);
                        var i: usize = 0;
                        while (i < method.arg_count) : (i += 1) {
                            const arg = (try termArg()).?;
                            try list.append(arg.*);
                        }

                        var call = try allocator.create(MethodInvocation);
                        call.* = MethodInvocation{
                            .name = name_str,
                            .args = list.items,
                        };

                        var expr_opcode = try allocator.create(ExpressionOpcode);
                        expr_opcode.* = ExpressionOpcode{
                            .call = call,
                        };

                        result = expr_opcode;
                    },
                    else => {
                        // rewind to let another rule consume the nameString
                        loc = start_loc;
                    }
                }
            }
            else {
                // rewind to let another rule consume the nameString
                loc = start_loc;
            }
        }
    }

    indent -= 2;
    return result;
}

fn target() !?*Target {
    indent += 2;

    var result: ?*Target = null;

    if (try superName()) |name| {
        var tgt = try allocator.create(Target);
        tgt.* = Target{
            .name = name,
        };
        result = tgt;
    }
    else if (nullName()) {
        var tgt = try allocator.create(Target);
        tgt.* = Target{
            .null_ = {},
        };
        result = tgt;
    }

    indent -= 2;
    return result;
}

fn superName() !?*SuperName {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*SuperName = null;

    if (try simpleName()) |simple_name| {
        var super_name = try allocator.create(SuperName);
        super_name.* = SuperName{
            .simple_name = simple_name,
        };
        result = super_name;
    }
    else if (try debugObj()) |debug_obj| {
        printIndented("DebugObj()", .{});
        var super_name = try allocator.create(SuperName);
        super_name.* = SuperName{
            .debug_obj = debug_obj,
        };
        result = super_name;
    }
    else if (try refTypeOpcode()) |ref_type_opcode| {
        // println("ReferenceTypeOpcode()", .{});
        var super_name = try allocator.create(SuperName);
        super_name.* = SuperName{
            .ref_type_opcode = ref_type_opcode,
        };
        result = super_name;
    }

    indent -= 2;
    return result;
}

fn simpleName() !?*SimpleName {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*SimpleName = null;

    if (try nameString()) |name_str| {
        var simple_name = try allocator.create(SimpleName);
        simple_name.* = SimpleName{
            .name = name_str,
        };
        result = simple_name;
    }
    else if (argObj()) |arg| {
        var simple_name = try allocator.create(SimpleName);
        simple_name.* = SimpleName{
            .arg = arg,
        };
        result = simple_name;
    }
    else if (localObj()) |local| {
        var simple_name = try allocator.create(SimpleName);
        simple_name.* = SimpleName{
            .local = local,
        };
        result = simple_name;
    }

    indent -= 2;
    return result;
}

fn debugObj() !?*DebugObj {
    var result: ?*DebugObj = null;

    if (matchOpCodeWord(.DebugOp)) {
        result = try allocator.create(DebugObj);
    }

    return result;
}

fn refTypeOpcode() AllocationError!?*ReferenceTypeOpcode {
    indent += 2;

    var result: ?*ReferenceTypeOpcode = null;

    if (matchOpCodeByte(.RefOfOp)) {
        printIndented("RefOf()", .{});
        if (try superName()) |source| {
            var ref_of = try allocator.create(RefOf);
            ref_of.* = RefOf{
                .source = source,
            };

            var ref_type_opcode = try allocator.create(ReferenceTypeOpcode);
            ref_type_opcode.* = ReferenceTypeOpcode{
                .ref_of = ref_of,
            };

            result = ref_type_opcode;
        }
    }
    else if (matchOpCodeByte(.DerefOfOp)) {
        printIndented("DerefOf()", .{});
        if (try termArg()) |obj_ref| {
            var deref_of = try allocator.create(DerefOf);
            deref_of.* = DerefOf{
                .obj_ref = obj_ref,
            };

            var ref_type_opcode = try allocator.create(ReferenceTypeOpcode);
            ref_type_opcode.* = ReferenceTypeOpcode{
                .deref_of = deref_of,
            };

            result = ref_type_opcode;
        }
    }
    else if (matchOpCodeByte(.IndexOp)) {
        printIndented("Index()", .{});
        if (try termArg()) |obj| {
            if (try termArg()) |index_val| {
                if (try target()) |tgt| {
                    var index = try allocator.create(Index);
                    index.* = Index{
                        .obj = obj,
                        .index = index_val,
                        .target = tgt,
                    };

                    var ref_type_opcode = try allocator.create(ReferenceTypeOpcode);
                    ref_type_opcode.* = ReferenceTypeOpcode{
                        .index = index,
                    };

                    result = ref_type_opcode;
                }
            }
        }
    }

    indent -= 2;
    return result;
}

fn namespaceModifierObj() !?*NameSpaceModifierObj {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*NameSpaceModifierObj = null;

    // if (try defAlias()) |def_alias| {
    //     var ns_mod_obj = try allocator.create(NameSpaceModifierObj);
    //     ns_mod_obj.* = NameSpaceModifierObj{
    //         .def_alias = def_alias,
    //     };
    //     result = ns_mod_obj;
    // }

    if (try defScope()) |def_scope| {
        var ns_mod_obj = try allocator.create(NameSpaceModifierObj);
        ns_mod_obj.* = NameSpaceModifierObj{
            .def_scope = def_scope,
        };
        result = ns_mod_obj;
    }

    if (try defName()) |def_name| {
        var ns_mod_obj = try allocator.create(NameSpaceModifierObj);
        ns_mod_obj.* = NameSpaceModifierObj{
            .def_name = def_name,
        };
        result = ns_mod_obj;
    }

    indent -= 2;
    return result;
}

fn namedObj() !?*NamedObj {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*NamedObj = null;

    if (try defOpRegion()) |def_op_region| {
        var named_obj = try allocator.create(NamedObj);
        named_obj.* = NamedObj{
            .def_op_region = def_op_region,
        };
        result = named_obj;
    }
    else if (try defField()) |def_field| {
        var named_obj = try allocator.create(NamedObj);
        named_obj.* = NamedObj{
            .def_field = def_field,
        };
        result = named_obj;
    }
    else if (try defMethod()) |def_method| {
        var named_obj = try allocator.create(NamedObj);
        named_obj.* = NamedObj{
            .def_method = def_method,
        };
        result = named_obj;
    }
    else if (try defDevice()) |def_device| {
        var named_obj = try allocator.create(NamedObj);
        named_obj.* = NamedObj{
            .def_device = def_device,
        };
        result = named_obj;
    }
    else if (try defMutex()) |def_mutex| {
        var named_obj = try allocator.create(NamedObj);
        named_obj.* = NamedObj{
            .def_mutex = def_mutex,
        };
        result = named_obj;
    }
    else if (try defCreateDWordField()) |def_create_dword_field| {
        var named_obj = try allocator.create(NamedObj);
        named_obj.* = NamedObj{
            .def_create_dword_field = def_create_dword_field,
        };
        result = named_obj;
    }
    else if (try defProcessor()) |def_processor| {
        var named_obj = try allocator.create(NamedObj);
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

    indent -= 2;
    return result;
}

fn defOpRegion() !?*DefOpRegion {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*DefOpRegion = null;

    if (matchOpCodeWord(.OpRegionOp)) {
        if (try nameString()) |name_str| {
            if (advance()) |region_space| {
                if (try termArg()) |region_offset| {
                    if (try termArg()) |region_len| {
                        printIndented("OperationRegion ({s})", .{name_str.name});
                        var def_op_region = try allocator.create(DefOpRegion);
                        def_op_region.* = DefOpRegion{
                            .name = name_str,
                            .space = region_space,
                            .offset = region_offset,
                            .len = region_len,
                        };
                        result = def_op_region;

                    }
                }
            }
        }
    }

    indent -= 2;
    return result;
}

// fn regionSpace() bool {
//     // printIndented(@src().fn_name, .{});
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

//     _ = advance();
//     return true;
// }

// fn regionOffset() bool {
//     // printIndented(@src().fn_name, .{});
//     indent += 2;

//     const result = termArg();

//     indent -= 2;
//     return result;
// }

// fn regionLen() bool {
//     // printIndented(@src().fn_name, .{});
//     indent += 2;

//     const result = termArg();

//     indent -= 2;
//     return result;
// }

fn defField() !?*DefField {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*DefField = null;

    if (matchOpCodeWord(.FieldOp)) {
        const pkg_start = loc;
        if (pkgLength()) |pkg_len| {
            if (try nameString()) |name_str| {
                printIndented("Field ({s})", .{name_str.name});
                if (advance()) |flags| {
                    var list = std.ArrayList(FieldElement).init(allocator);

                    while (loc < pkg_start + pkg_len) {
                        if (try namedField()) |named_fld| {
                            try list.append(FieldElement{
                                .named_fld = named_fld,
                            });
                        } else if (try reservedField()) |reserved_fld| {
                            try list.append(FieldElement{
                                .reserved_fld = reserved_fld,
                            });
                        }

                        var def_field = try allocator.create(DefField);
                        def_field.* = DefField{
                            .name = name_str,
                            .flags = flags,
                            .field_elements = list.items,
                        };

                        result = def_field;
                    }
                }
            }
        }
    }

    indent -= 2;
    return result;
}

fn namedField() !?*NamedField {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*NamedField = null;

    if (nameSeg()) |name_seg| {
        var named_fld = try allocator.create(NamedField);
        named_fld.* = NamedField{
            .name = name_seg,
            .bits = pkgLength() orelse 0,
        };
        std.mem.copy(u8, named_fld.name[0..], name_seg[0..]);
        
        result = named_fld;

        printIndented("NamedField ({s}, {})", .{named_fld.name, named_fld.bits});
    }

    indent -= 2;
    return result;
}

fn reservedField() !?*ReservedField {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*ReservedField = null;

    if (matchByte(0x00)) {
        if (pkgLength()) |field_len| {
            var reserved_fld = try allocator.create(ReservedField);
            reserved_fld.* = ReservedField{
                .len = field_len,
            };
            
            result = reserved_fld;

            printIndented("ReservedField ({})", .{field_len});
        }
    }

    indent -= 2;
    return result;
}



fn defMethod() !?*DefMethod {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*DefMethod = null;
    if (matchOpCodeByte(.MethodOp)) {
        const start_loc = loc;
        if (pkgLength()) |pkglen| {
            if (try nameString()) |name_str| {
                printIndented("Method ({s})", .{name_str.name});
                if (advance()) |flags| {
                    const arg_count = @intCast(u3, flags & 0x07);

                    try method_names.put(name_str.name, arg_count);

                    const len = pkglen - (loc - start_loc);
                    var def_method = try allocator.create(DefMethod);
                    def_method.* = DefMethod{
                        .name = name_str,
                        .arg_count = arg_count,
                        .flags = flags,
                        .terms = undefined,
                    };
                    result = def_method;

                    _ = try ns_builder.addName(name_str.name, NamespaceObject{ .method = def_method });

                    def_method.terms = try terms(len);
                }
            }
        }
    }

    indent -= 2;
    return result;
}

fn defDevice() !?*DefDevice {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*DefDevice = null;

    if (matchOpCodeWord(.DeviceOp)) {
        const start_loc = loc;
        if (pkgLength()) |pkglen| {
            if (try nameString()) |name_str| {
                printIndented("Device ({s})", .{name_str.name});
                const len = pkglen - (loc - start_loc);
                var def_device = try allocator.create(DefDevice);
                def_device.* = DefDevice{
                    .name = name_str,
                    .terms = undefined,
                };
                result = def_device;

                const ns_path = try ns_builder.addName(name_str.name, NamespaceObject{ .device = def_device });
                try ns_builder.pushNamespace(ns_path);

                def_device.terms = try terms(len);

                _ = ns_builder.popNamespace();
            }
        }
    }

    indent -= 2;
    return result;
}

fn defMutex() !?*DefMutex {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*DefMutex = null;

    if (matchOpCodeWord(.MutexOp)) {
        if (try nameString()) |name_str| {
            if (advance()) |sync_flags| {
                printIndented("Mutex ({s})", .{name_str.name});
                var def_mutex = try allocator.create(DefMutex);
                def_mutex.* = DefMutex{
                    .name = name_str,
                    .sync_flags = sync_flags,
                };
                result = def_mutex;
            }
        }
    }

    indent -= 2;
    return result;
}

fn defCreateDWordField() !?*DefCreateDWordField {
    indent += 2;

    var result: ?*DefCreateDWordField = null;

    if (matchOpCodeByte(.CreateDWordFieldOp)) {
        if (try termArg()) |source_buff| {
            if (try termArg()) |byte_index| {
                if (try nameString()) |name_str| {
                    printIndented("CreateDWordField ({s})", .{name_str.name});
                    var def_create_dword_field = try allocator.create(DefCreateDWordField);
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

    indent -= 2;
    return result;
}

fn defProcessor() !?*DefProcessor {
    indent += 2;

    var result: ?*DefProcessor = null;

    if (matchOpCodeWord(.ProcessorOp)) {
        const start_loc = loc;
        if (pkgLength()) |pkg_len| {
            if (try nameString()) |name_str| {
                printIndented("Processor ({s})", .{name_str.name});
                if (advance()) |proc_id| {
                    if (readDWord()) |pblk_addr| {
                        if (advance()) |pblk_len| {

                        const len = pkg_len - (loc - start_loc);
                        var def_processor = try allocator.create(DefProcessor);
                        def_processor.* = DefProcessor{
                            .name = name_str,
                            .proc_id = proc_id,
                            .pblk_addr = pblk_addr,
                            .pblk_len = pblk_len,
                            .terms = undefined,
                        };
                        result = def_processor;

                        const ns_path = try ns_builder.addName(name_str.name, NamespaceObject{ .processor = def_processor });
                        try ns_builder.pushNamespace(ns_path);

                        def_processor.terms = try terms(len);

                        _ = ns_builder.popNamespace();
                        }
                    }
                }
            }
        }
    }

    indent -= 2;
    return result;
}

fn termArg() AllocationError!?*TermArg {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*TermArg = null;

    if (try expressionOpCode()) |expr_opcode| {
        var term_arg = try allocator.create(TermArg);
        term_arg.* = TermArg{
            .expr_opcode = expr_opcode,
        };
        result = term_arg;
    }
    else if (try dataObject()) |data_obj| {
        var term_arg = try allocator.create(TermArg);
        term_arg.* = TermArg{
            .data_obj = data_obj,
        };
        result = term_arg;
    }
    else if (argObj()) |arg_obj| {
        var term_arg = try allocator.create(TermArg);
        term_arg.* = TermArg{
            .arg_obj = arg_obj,
        };
        result = term_arg;
    }
    else if (localObj()) |local_obj| {
        var term_arg = try allocator.create(TermArg);
        term_arg.* = TermArg{
            .local_obj = local_obj,
        };
        result = term_arg;
    }
    else if (try nameString()) |name_str| {
        var term_arg = try allocator.create(TermArg);
        term_arg.* = TermArg{
            .name_str = name_str,
        };
        result = term_arg;
    }

    indent -= 2;
    return result;
}

fn packageElement() !?*PackageElement {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*PackageElement = null;

    if (try dataObject()) |data_obj| {
        var pkg_elem = try allocator.create(PackageElement);
        pkg_elem.* = PackageElement{
            .data_obj = data_obj,
        };
        result = pkg_elem;
    }
    else if (try nameString()) |name_str| {
        var pkg_elem = try allocator.create(PackageElement);
        pkg_elem.* = PackageElement{
            .name = name_str,
        };
        result = pkg_elem;
    }

    indent -= 2;
    return result;
}

fn dataObject() !?*DataObject {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*DataObject = null;

    if (try computationalData()) |comp_data| {
        var data_obj = try allocator.create(DataObject);
        data_obj.* = DataObject{
            .comp_data = comp_data,
        };
        result = data_obj;
    }
    // const result =
    //     computationalData();
    //     defPackage() or
    //     defVarPackage();

    indent -= 2;
    return result;
}

fn computationalData() !?*ComputationalData {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*ComputationalData = null;

    if (byteConst()) |byte_const| {
        var comp_data = try allocator.create(ComputationalData);
        comp_data.* = ComputationalData{
            .byte_const = byte_const,
        };
        result = comp_data;
    }
    else if (wordConst()) |word_const| {
        var comp_data = try allocator.create(ComputationalData);
        comp_data.* = ComputationalData{
            .word_const = word_const,
        };
        result = comp_data;
    }
    else if (dWordConst()) |dword_const| {
        var comp_data = try allocator.create(ComputationalData);
        comp_data.* = ComputationalData{
            .dword_const = dword_const,
        };
        result = comp_data;
    }
    else if (constObj()) |const_obj| {
        var comp_data = try allocator.create(ComputationalData);
        comp_data.* = ComputationalData{
            .const_obj = const_obj,
        };
        result = comp_data;
    }
    else if (try string()) |str| {
        var comp_data = try allocator.create(ComputationalData);
        comp_data.* = ComputationalData{
            .string = str,
        };
        result = comp_data;
    }
    // const result =
    //     byteConst() or wordConst() or // dWordConst() or qWordConst() or
    //     // string() or
    //     constObj(); // or revisionOp() or defBuffer();

    indent -= 2;
    return result;
}

// fn byteConst() bool {
//     // printIndented(@src().fn_name, .{});
//     return false;
// }

fn byteConst() ?u8 {
    // printIndented(@src().fn_name, .{});
    
    var result: ?u8 = null;

    if (matchPrefix(.BytePrefix)) {
        result = advance();
    }

    return result;
}

fn wordConst() ?u16 {
    // printIndented(@src().fn_name, .{});
    
    var result: ?u16 = null;

    if (matchPrefix(.WordPrefix)) {
        result = readWord();
    }

    return result;
}

fn dWordConst() ?u32 {
    // printIndented(@src().fn_name, .{});
    
    var result: ?u32 = null;

    if (matchPrefix(.DWordPrefix)) {
        result = readDWord();
    }

    return result;
}

fn constObj() ?u8 {
    // printIndented(@src().fn_name, .{});
    
    var result: ?u8 = null;

    if (matchOpCodeByte(.ZeroOp)) {
        result = 0x00;
    } else if (matchOpCodeByte(.OneOp)) {
        result = 0x01;
    } else if (matchOpCodeByte(.OnesOp)) {
        result = 0xFF;
    }

    return result;
}

fn string() !?[:0]const u8 {
    var result: ?[:0]const u8 = null;
    if (matchPrefix(.StringPrefix)) {
        if (readString()) |str| {
            result = try allocator.dupeZ(u8, str);
        }
    }

    return result;
}

fn argObj() ?ArgObj {
    // printIndented(@src().fn_name, .{});
    
    var result: ?ArgObj = null;

    if (matchByteRange(@enumToInt(OpCodeByte.Arg0Op), @enumToInt(OpCodeByte.Arg6Op))) |arg| {
        result = @intToEnum(ArgObj, arg);
    }

    return result;
}

fn localObj() ?LocalObj {
    // printIndented(@src().fn_name, .{});
    
    var result: ?LocalObj = null;

    if (matchByteRange(@enumToInt(OpCodeByte.Local0Op), @enumToInt(OpCodeByte.Local7Op))) |local| {
        result = @intToEnum(LocalObj, local);
    }

    return result;
}

// fn defAlias() !*DefAlias {
//     // printIndented(@src().fn_name, .{});
//     return null;
// }

fn defScope() !?*DefScope {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*DefScope = null;

    if (matchOpCodeByte(.ScopeOp)) {
        const start_loc = loc;
        if (pkgLength()) |pkglen| {
            if (try nameString()) |name_str| {
                printIndented("Scope ({s})", .{name_str.name});
                const len = pkglen - (loc - start_loc);
                var def_scope = try allocator.create(DefScope);
                def_scope.* = DefScope{
                    .name = name_str,
                    .terms = undefined,
                };
                result = def_scope;

                const ns_path = try ns_builder.addName(name_str.name, NamespaceObject{ .scope = def_scope });
                try ns_builder.pushNamespace(ns_path);

                printIndented("Scope -> terms() len={x}", .{len});
                def_scope.terms = try terms(len);

                _ = ns_builder.popNamespace();
            }
        }
    }

    indent -= 2;
    return result;
}

fn defName() !?*DefName {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*DefName = null;

    if (matchOpCodeByte(.NameOp)) {
        if (try nameString()) |name_str| {
            if (try dataRefObject()) |data_ref_obj| {
                printIndented("Name ({s})", .{name_str.name});
                var def_name = try allocator.create(DefName);
                def_name.* = DefName{
                    .name = name_str,
                    .data_ref_obj = data_ref_obj,
                };
                result = def_name;

                _ = try ns_builder.addName(name_str.name, NamespaceObject{ .name = def_name });
            }
        }
    }

    indent -= 2;
    return result;
}

fn dataRefObject() !?*DataRefObject {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*DataRefObject = null;

    if (try dataObject()) |data_obj| {
        var data_ref_obj = try allocator.create(DataRefObject);
        data_ref_obj.* = DataRefObject{
            .data_obj = data_obj,
        };
        result = data_ref_obj;
    }
    else {
        var data_ref_obj = try allocator.create(DataRefObject);
        data_ref_obj.* = DataRefObject{
            // TODO: implement
            .obj_ref = 0,
        };
        result = data_ref_obj;
    }

    indent -= 2;
    return result;
}

fn pkgLength() ?u32 {
    // printIndented(@src().fn_name, .{});
    return matchPkgLength();
}

fn nameString() !?*NameString {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?*NameString = null;

    if(matchChar(.RootChar)) {
        if (try namePath()) |name_path| {
            var name_string = try allocator.create(NameString);
            name_string.* = NameString{
                .name = try std.mem.concat(allocator, u8, &[_][]const u8{ "\\", name_path }),
            };
            result = name_string;
        } else if (nullName()) {
            var name_string = try allocator.create(NameString);
            name_string.* = NameString{
                .name = try allocator.dupe(u8, "\\"),
            };
            result = name_string;
        }
    }
    else if (try prefixPath()) |prefix_path| {
        if (try namePath()) |name_path| {
            var name_string = try allocator.create(NameString);
            name_string.* = NameString{
                .name = try std.mem.concat(allocator, u8, &[_][]const u8{ prefix_path, name_path }),
            };
            result = name_string;
        } else if (nullName()) {
            var name_string = try allocator.create(NameString);
            name_string.* = NameString{
                .name = prefix_path,
            };
            result = name_string;
        }
    }
    else if (try namePath()) |name_path| {
        var name_string = try allocator.create(NameString);
        name_string.* = NameString{
            .name = name_path,
        };
        result = name_string;
    }

    indent -= 2;
    return result;
}

fn prefixPath() !?[]u8 {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?[]u8 = null;

    var count: usize = 0;
    while (matchChar(.ParentPrefixChar)) {
        count += 1;
    }
    if (count > 0) {
        var prefix_path = try allocator.alloc(u8, count);
        std.mem.set(u8, prefix_path, '^');
        result = prefix_path;
    }

    indent -= 2;
    return result;
}

fn namePath() !?[]const u8 {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?[]const u8 = null;

    if(nameSeg()) |name_seg| {
        var name_path = try allocator.alloc(u8, name_seg.len);
        std.mem.copy(u8, name_path, name_seg[0..]);
        result = name_path;
    } else if (try dualNamePath()) |dual_name_path| {
        result = dual_name_path;
    } else if (try multiNamePath()) |multi_name_path| {
        result = multi_name_path;
    }

    indent -= 2;
    return result;
}

fn nameSeg() ?[4]u8 {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?[4]u8 = null;

    if (leadNameChar()) |ch1| {
        if (nameChar()) |ch2| {
            if (nameChar()) |ch3| {
                if (nameChar()) |ch4| {
                    result = [_]u8{ ch1, ch2, ch3, ch4 };
                }
            }
        }
    }

    indent -= 2;
    return result;
}

fn leadNameChar() ?u8 {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?u8 = null;

    if (matchCharRange(.AlphaChar_Start, .AlphaChar_End)) |ch| {
        result = ch;
    }
    else if (matchChar(.UnderscoreChar)) {
        result = '_';
    }

    indent -= 2;
    return result;
}

fn nameChar() ?u8 {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?u8 = null;

    if (leadNameChar()) |ch| {
        result = ch;
    }
    else if (matchCharRange(.DigitChar_Start, .DigitChar_End)) |ch| {
        result = ch;
    }

    indent -= 2;
    return result;
}

fn asciiChar() ?u8 {
    var result: ?u8 = null;

    if (matchCharRange(.AsciiChar_Start, .AsciiChar_End)) |ch| {
        result = ch;
    }

    return result;
}

fn dualNamePath() !?[]const u8 {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?[]const u8 = null;

    if (matchPrefix(.DualNamePrefix)) {
        if (nameSeg()) |seg1| {
            if (nameSeg()) |seg2| {
                result = try std.mem.concat(allocator, u8, &[_][]const u8{ seg1[0..], ".", seg2[0..] });
            }
        }
    }

    indent -= 2;
    return result;
}

fn multiNamePath() !?[]const u8 {
    // printIndented(@src().fn_name, .{});
    indent += 2;

    var result: ?[]const u8 = null;

    if (matchPrefix(.MultiNamePrefix)) {
        if (advance()) |seg_count| {
            var list = std.ArrayList([]const u8).init(allocator);
            var i: usize = 0;
            while (i < seg_count) : (i += 1) {
                if (nameSeg()) |seg| {
                    try list.append(try std.mem.dupe(allocator, u8, seg[0..]));
                } else {
                    return null;
                }
            }
            result = try std.mem.join(allocator, ".", list.items);
        }
    }

    indent -= 2;
    return result;
}

fn nullName() bool {
    // printIndented(@src().fn_name, .{});
    return matchChar(.Null);
}

//
// matching routines
//

fn matchOpCodeByte(opCode: OpCodeByte) bool {
    // // printIndented(@src().fn_name, .{});
    if (peekByte()) |byte| {
        if (byte == @enumToInt(opCode)) {
            _ = advance();
            return true;
        }
    }
    return false;
}

fn matchOpCodeWord(opCode: OpCodeWord) bool {
    // // printIndented(@src().fn_name, .{});
    if (peekWord()) |word| {
        if (word == @enumToInt(opCode)) {
            _ = advance();
            _ = advance();
            return true;
        }
    }
    return false;
}

fn matchPrefix(prefix: Prefix) bool {
    // // printIndented(@src().fn_name, .{});
    return matchByte(@enumToInt(prefix));
}

fn matchChar(ch: Char) bool {
    // // printIndented(@src().fn_name, .{});
    return matchByte(@enumToInt(ch));
}

fn matchCharRange(start: Char, end: Char) ?u8 {
    // // printIndented(@src().fn_name, .{});
    return matchByteRange(@enumToInt(start), @enumToInt(end));
}

fn matchByte(byte: u8) bool {
    // // printIndented(@src().fn_name, .{});
    if (peekByte()) |b| {
        if (b == byte) {
            _ = advance();
            return true;
        }
    }
    return false;
}

fn matchByteRange(start: u8, end: u8) ?u8 {
    // // printIndented(@src().fn_name, .{});
    if (peekByte()) |byte| {
        if (byte >= start and byte <= end) {
            return advance();
        }
    }
    return null;
}

fn matchPkgLength() ?u32 {
    // printIndented(@src().fn_name, .{});

    var length: ?u32 = null;

    if (peekByte()) |lead_byte| {
        var count = lead_byte >> 6;
        if (count == 0) {
            if (advance()) |byte| {
                length = @intCast(u32, byte & 0x3F);
            }
        }
        else if (lead_byte & 0b00110000 == 0) {
            if (advance()) |byte| {
                var len = @intCast(u32, byte & 0x0F);
                var i: usize = 1;
                while (i < count + 1) : (i += 1) {
                    if (advance()) |next_byte| {
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

fn peekByte() ?u8 {
    // // printIndented(@src().fn_name, .{});
    if (loc >= block.len) {
        return null;
    }
    return block[loc];
}

fn peekWord() ?u16 {
    // // printIndented(@src().fn_name, .{});
    if (loc >= block.len - 1) {
        return null;
    }
    return block[loc] | @intCast(u16, block[loc + 1]) << 8;
}

fn readWord() ?u16 {
    if (advance()) |lo| {
        if (advance()) |hi| {
            return @intCast(u16, lo) | @intCast(u16, hi) << 8;
        }
    }
    return null;
}

fn readDWord() ?u32 {
    if (readWord()) |lo| {
        if (readWord()) |hi| {
            return @intCast(u32, lo) | @intCast(u32, hi) << 16;
        }
    }
    return null;
    // return
    //     @intCast(u32, advance()) << 00 | @intCast(u32, advance()) << 08 |
    //     @intCast(u32, advance()) << 16 | @intCast(u32, advance()) << 24;
}

fn readString() ?[]const u8 {
    const start = loc;
    while (block[loc] != 0 and loc < block.len) {
        loc += 1;
    }
    if (loc < block.len) {
        loc += 1;
        return block[start..loc-1];
    }
    return null;
}

fn advance() ?u8 {
    if (loc >= block.len) {
        return null;
    }
    loc += 1;
    return block[loc - 1];
}
