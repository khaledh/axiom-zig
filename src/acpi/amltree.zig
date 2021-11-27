const std = @import("std");
const ast = @import("amlparser.zig");
const io = @import("../io.zig");


// Visitor interface
const AmlTreeVisitor = struct {
    const Self = @This();

    visitTerms: fn (self: *Self, terms: []const ast.TermObj) void,
    visitTermObj: fn (self: *Self, term_obj: *const ast.TermObj) void,
    visitObject: fn (self: *Self, obj: *const ast.Object) void,
    visitStatementOpcode: fn (self: *Self, obj: *const ast.StatementOpcode) void,
    visitExpressionOpcode: fn (self: *Self, obj: *const ast.ExpressionOpcode) void,
    visitNameSpaceModifierObj: fn (self: *Self, obj: *const ast.NameSpaceModifierObj) void,
    visitNamedObj: fn (self: *Self, obj: *const ast.NamedObj) void,
    visitDefScope: fn (self: *Self, obj: *const ast.DefScope) void,
    visitDefName: fn (self: *Self, obj: *const ast.DefName) void,
    visitDataObject: fn (self: *Self, obj: *const ast.DataObject) void,
    visitComputationalData: fn (self: *Self, obj: *const ast.ComputationalData) void,
    visitByteConst: fn (self: *Self, byte_const: u8) void,
    visitWordConst: fn (self: *Self, word_const: u16) void,
    visitDWordConst: fn (self: *Self, dword_const: u32) void,
    visitQWordConst: fn (self: *Self, qword_const: u64) void,
    visitConstObj: fn (self: *Self, const_obj: u8) void,
    visitRevision: fn (self: *Self, revision: u64) void,
    visitString: fn (self: *Self,  [:0]const u8) void,
    visitBuffer: fn (self: *Self,  *const ast.Buffer) void,
    visitDefDevice: fn (self: *Self,  *const ast.DefDevice) void,
    visitDefOpRegion: fn (self: *Self,  *const ast.DefOpRegion) void,
    visitDefField: fn (self: *Self,  *const ast.DefField) void,
    visitFieldElement: fn (self: *Self,  *const ast.FieldElement) void,
    visitNamedField: fn (self: *Self,  *const ast.NamedField) void,
    visitReservedField: fn (self: *Self,  *const ast.ReservedField) void,
    visitDefMethod: fn (self: *Self,  *const ast.DefMethod) void,
    visitPackage: fn (self: *Self,  *const ast.Package) void,
    visitDataRefObject: fn (self: *Self,  *const ast.DataRefObject) void,
    visitNameString: fn (self: *Self,  *const ast.NameString) void,

    fn acceptTerms(self: *Self, terms: []const ast.TermObj) void {
        for (terms) |*term_obj| {
            self.visitTermObj(self, term_obj);
        }
    }

    fn acceptTermObj(self: *Self, term_obj: *const ast.TermObj) void {
        switch (term_obj.*) {
            .obj => |obj| self.visitObject(self, obj),
            .stmt_opcode => |stmt_opcode| self.visitStatementOpcode(self, stmt_opcode),
            .expr_opcode => |expr_opcode| self.visitExpressionOpcode(self, expr_opcode),
        }
    }

    fn acceptObject(self: *Self, obj: *const ast.Object) void {
        switch (obj.*) {
            .ns_mod_obj => |ns_mod_obj| self.visitNameSpaceModifierObj(self, ns_mod_obj),
            .named_obj => |named_obj| self.visitNamedObj(self, named_obj),
        }
    }

    fn acceptStatementOpcode(_: *Self, stmt_opcode: *const ast.StatementOpcode) void {
        switch (stmt_opcode.*) {
            else => {},
        }
    }

    fn acceptExpressionOpcode(_: *Self, expr_opcode: *const ast.ExpressionOpcode) void {
        switch (expr_opcode.*) {
            else => {},
        }
    }

    fn acceptNameSpaceModifierObj(self: *Self, ns_mod_obj: *const ast.NameSpaceModifierObj) void {
        switch (ns_mod_obj.*) {
            .def_scope => |def_scope| self.visitDefScope(self, def_scope),
            .def_name => |def_name| self.visitDefName(self, def_name),
        }
    }

    fn acceptDefScope(self: *Self, def_scope: *const ast.DefScope) void {
        self.acceptTerms(def_scope.terms);
    }

    fn acceptDefName(self: *Self, def_name: *const ast.DefName) void {
        switch (def_name.data_ref_obj.*) {
            .data_obj => |data_obj| self.visitDataObject(self, data_obj),
            .obj_ref => {},
        }
    }

    fn acceptDataObject(self: *Self, data_obj: *const ast.DataObject) void {
        switch (data_obj.*) {
            .comp_data => |comp_data| self.visitComputationalData(self, comp_data),
            .package => |pkg| self.visitPackage(self, pkg),
        }
    }

    fn acceptComputationalData(self: *Self, comp_data: *const ast.ComputationalData) void {
        switch (comp_data.*) {
            .byte_const => |byte_const| self.visitByteConst(self, byte_const),
            .word_const => |word_const| self.visitWordConst(self, word_const),
            .dword_const => |dword_const| self.visitDWordConst(self, dword_const),
            .qword_const => |qword_const| self.visitQWordConst(self, qword_const),
            .const_obj => |const_obj| self.visitConstObj(self, const_obj),
            .revision => |revision| self.visitRevision(self, revision),
            .string => |str| self.visitString(self, str),
            .buffer => |buff| self.visitBuffer(self, buff),
            .res_desc_buffer => {},
        }
    }

    fn acceptNamedObj(self: *Self, named_obj: *const ast.NamedObj) void {
        switch (named_obj.*) {
            .def_device => |def_device| self.visitDefDevice(self, def_device),
            .def_op_region => |def_op_region| self.visitDefOpRegion(self, def_op_region),
            .def_field => |def_field| self.visitDefField(self, def_field),
            .def_method => |def_method| self.visitDefMethod(self, def_method),
            else => {},
        }
    }

    fn acceptDefDevice(self: *Self, def_device: *const ast.DefDevice) void {
        self.acceptTerms(def_device.terms);
    }

    fn acceptDefField(self: *Self, def_field: *const ast.DefField) void {
        for (def_field.field_elements) |*field_elem| {
            self.visitFieldElement(self, field_elem);
        }
    }

    fn acceptFieldElement(self: *Self, field_elem: *const ast.FieldElement) void {
        switch (field_elem.*) {
            .named_fld => |named_fld| self.visitNamedField(self, named_fld),
            .reserved_fld => |reserved_fld| self.visitReservedField(self, reserved_fld),
        }
    }

    fn acceptPackageElement(self: *Self, pkg_elem: *const ast.PackageElement) void {
        switch (pkg_elem.*) {
            .data_ref_obj => |data_ref_obj| self.visitDataRefObject(self, data_ref_obj),
            .name => |name_str| self.visitNameString(self, name_str),
        }
    }

    fn acceptDataRefObject(self: *Self, data_ref_obj: *const ast.DataRefObject) void {
        switch (data_ref_obj.*) {
            .data_obj => |data_obj| self.visitDataObject(self, data_obj),
            .obj_ref => {},
        }
    }

};

pub const AmlTreePrinter = struct {
    const Self = @This();

    visitor: AmlTreeVisitor,
    indent: usize = 0,

    pub fn init() Self {
        return .{
            .visitor = AmlTreeVisitor{
                .visitTerms = visitTerms,
                .visitTermObj = visitTermObj,
                .visitObject = visitObject,
                .visitStatementOpcode = visitStatementOpcode,
                .visitExpressionOpcode = visitExpressionOpcode,
                .visitNameSpaceModifierObj = visitNameSpaceModifierObj,
                .visitNamedObj = visitNamedObj,
                .visitDefScope = visitDefScope,
                .visitDefName = visitDefName,
                .visitDataObject = visitDataObject,
                .visitComputationalData = visitComputationalData,
                .visitByteConst = visitByteConst,
                .visitWordConst = visitWordConst,
                .visitDWordConst = visitDWordConst,
                .visitQWordConst = visitQWordConst,
                .visitConstObj = visitConstObj,
                .visitRevision = visitRevision,
                .visitString = visitString,
                .visitBuffer = visitBuffer,
                .visitDefDevice = visitDefDevice,
                .visitDefOpRegion = visitDefOpRegion,
                .visitDefField = visitDefField,
                .visitFieldElement = visitFieldElement,
                .visitNamedField = visitNamedField,
                .visitReservedField = visitReservedField,
                .visitDefMethod = visitDefMethod,
                .visitPackage = visitPackage,
                .visitDataRefObject = visitDataRefObject,
                .visitNameString = visitNameString,
            },
        };
    }

    pub fn print(self: *Self, terms: []const ast.TermObj) void {
        visitTerms(&self.visitor, terms);
    }

    fn visitTerms(visitor: *AmlTreeVisitor, terms: []const ast.TermObj) void {
        visitor.acceptTerms(terms);
    }

    fn visitTermObj(visitor: *AmlTreeVisitor, term_obj: *const ast.TermObj) void {
        visitor.acceptTermObj(term_obj);
    }

    fn visitObject(visitor: *AmlTreeVisitor, obj: *const ast.Object) void {
        visitor.acceptObject(obj);
    }

    fn visitStatementOpcode(visitor: *AmlTreeVisitor, stmt_opcode: *const ast.StatementOpcode) void {
        visitor.acceptStatementOpcode(stmt_opcode);
    }

    fn visitExpressionOpcode(visitor: *AmlTreeVisitor, stmt_opcode: *const ast.ExpressionOpcode) void {
        visitor.acceptExpressionOpcode(stmt_opcode);
    }

    fn visitNameSpaceModifierObj(visitor: *AmlTreeVisitor, ns_mod_obj: *const ast.NameSpaceModifierObj) void {
        visitor.acceptNameSpaceModifierObj(ns_mod_obj);
    }

    fn visitNamedObj(visitor: *AmlTreeVisitor, named_obj: *const ast.NamedObj) void {
        visitor.acceptNamedObj(named_obj);
    }

    fn visitDefScope(visitor: *AmlTreeVisitor, def_scope: *const ast.DefScope) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "Scope ({s})", .{def_scope.name.name});

        self.indent += 2;
        visitor.acceptDefScope(def_scope);
        self.indent -= 2;
    }

    fn visitDefName(visitor: *AmlTreeVisitor, def_name: *const ast.DefName) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printIndented(self.indent, "Name ({s}, ", .{def_name.name.name});
        visitor.acceptDefName(def_name);
        io.println(")", .{});
    }

    fn visitDataObject(visitor: *AmlTreeVisitor, data_obj: *const ast.DataObject) void {
        visitor.acceptDataObject(data_obj);
    }

    fn visitComputationalData(visitor: *AmlTreeVisitor, comp_data: *const ast.ComputationalData) void {
        visitor.acceptComputationalData(comp_data);
    }

    fn visitByteConst(_: *AmlTreeVisitor, byte_const: u8) void {
        io.print("0x{x:0>2}", .{byte_const});
    }

    fn visitWordConst(_: *AmlTreeVisitor, word_const: u16) void {
        io.print("0x{x:0>4}", .{word_const});
    }

    fn visitDWordConst(_: *AmlTreeVisitor, dword_const: u32) void {
        // handle EISAID-encoded values
        const v1: u8 = @intCast(u8, (dword_const >> 2) & 0x1F) + 0x40;
        const v2: u8 = @intCast(u8, (dword_const >> 13 & 0x07) | @intCast(u8, (dword_const & 0x03) << 3)) + 0x40;
        const v3: u8 = @intCast(u8, (dword_const >> 8) & 0x1F) + 0x40;
        var p1: u8 = @intCast(u8, (dword_const >> 20) & 0x0F) + 0x30;
        var p2: u8 = @intCast(u8, (dword_const >> 16) & 0x0F) + 0x30;
        var p3: u8 = @intCast(u8, (dword_const >> 28) & 0x0F) + 0x30;
        var p4: u8 = @intCast(u8, (dword_const >> 24) & 0x0F) + 0x30;

        if (p1 > '9') { p1 += 0x7; }
        if (p2 > '9') { p2 += 0x7; }
        if (p3 > '9') { p3 += 0x7; }
        if (p4 > '9') { p4 += 0x7; }

        if (v1 >= 'A' and v1 <= 'Z' and
            v2 >= 'A' and v2 <= 'Z' and
            v3 >= 'A' and v3 <= 'Z' and
            (p1 >= '0' and p1 <= '9' or p1 >= 'A' and p1 <= 'F') and
            (p2 >= '0' and p2 <= '9' or p2 >= 'A' and p2 <= 'F') and
            (p3 >= '0' and p3 <= '9' or p3 >= 'A' and p3 <= 'F') and
            (p4 >= '0' and p4 <= '9' or p4 >= 'A' and p4 <= 'F'))
        {
            io.print("EISAID(\"{c}{c}{c}{c}{c}{c}{c}\")", .{v1, v2, v3, p1, p2, p3, p4});
        } else {
            io.print("0x{x:0>8}", .{dword_const});
        }
    }

    fn visitQWordConst(_: *AmlTreeVisitor, qword_const: u64) void {
        io.print("0x{x:0>16}", .{qword_const});
    }

    fn visitConstObj(_: *AmlTreeVisitor, const_obj: u8) void {
        io.print("0x{x:0>2}", .{const_obj});
    }

    fn visitRevision(_: *AmlTreeVisitor, revision: u64) void {
        io.print("{}", .{revision});
    }

    fn visitString(_: *AmlTreeVisitor, str: [:0]const u8) void {
        io.print("\"{s}\"", .{str});
    }

    fn visitBuffer(visitor: *AmlTreeVisitor, _: *const ast.Buffer) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.println("Buffer", .{});
        self.indent += 2;
        
        self.indent -= 2;
    }

    fn visitDefDevice(visitor: *AmlTreeVisitor, def_device: *const ast.DefDevice) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "Device ({s})", .{def_device.name.name});

        self.indent += 2;
        visitor.acceptDefDevice(def_device);
        self.indent -= 2;
    }

    fn visitDefOpRegion(visitor: *AmlTreeVisitor, def_op_region: *const ast.DefOpRegion) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "OperationRegion ({s})", .{def_op_region.name.name});

        self.indent += 2;
        // visitor.acceptDefField(def_op_region);
        self.indent -= 2;
    }

    fn visitDefField(visitor: *AmlTreeVisitor, def_field: *const ast.DefField) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "Field ({s})", .{def_field.name.name});

        self.indent += 2;
        visitor.acceptDefField(def_field);
        self.indent -= 2;
    }

    fn visitFieldElement(visitor: *AmlTreeVisitor, field_elem: *const ast.FieldElement) void {
        visitor.acceptFieldElement(field_elem);
    }

    fn visitNamedField(visitor: *AmlTreeVisitor, named_fld: *const ast.NamedField) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "{s}, {}", .{named_fld.name, named_fld.bits});
    }

    fn visitReservedField(visitor: *AmlTreeVisitor, reserved_fld: *const ast.ReservedField) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "Reserved, {}", .{reserved_fld.len});
    }

    fn visitDefMethod(visitor: *AmlTreeVisitor, def_method: *const ast.DefMethod) void {
        const self = @fieldParentPtr(Self, "visitor", visitor);

        io.printlnIndented(self.indent, "Method ({s})", .{def_method.name.name});

        self.indent += 2;
        // visitor.acceptDefMethod(def_method);
        self.indent -= 2;
    }

    fn visitPackage(visitor: *AmlTreeVisitor, pkg: *const ast.Package) void {
        io.print("[", .{});
        var i: usize = 0;
        while (i < pkg.elements.len) : (i += 1) {
            visitor.acceptPackageElement(&pkg.elements[i]);
            if (i < pkg.elements.len - 1) {
                io.print(", ", .{});
            }
        }
        io.print("]", .{});
    }

    fn visitDataRefObject(visitor: *AmlTreeVisitor, data_ref_obj: *const ast.DataRefObject) void {
        visitor.acceptDataRefObject(data_ref_obj);
    }

    fn visitNameString(_: *AmlTreeVisitor, name_str: *const ast.NameString) void {
        io.print("{s}", .{name_str.name});
    }

};
