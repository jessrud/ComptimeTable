const std = @import("std");

pub fn ComptimeTable(comptime K: type, comptime V: type, comptime eq: fn (K, K) bool) type {
    return struct {
        pub fn set(comptime self: *@This(), comptime key: K, comptime value: V) void {
            if (self.lookupNode(key)) |node| {
                node.value = value;
            } else
                comptime {
                var old_self = self.*; //comptime allocator :^)
                self.* = @This(){
                    .key = key,
                    .value = value,
                    .next = &old_self,
                };
            }
        }

        pub fn init(comptime key: K, comptime value: V) @This() {
            return @This(){
                .key = key,
                .value = value,
                .next = null,
            };
        }
        pub fn lookup(comptime self: @This(), comptime key: K) ?V {
            if (self.lookupNodeConst(key)) |node| return node.value else return null;
        }

        fn lookupNode(comptime self: *@This(), comptime key: K) ?*@This() {
            var table: @TypeOf(self.next) = self;
            while (table) |node| : (table = node.next) {
                if (eq(key, node.key)) return node;
            }
            return null;
        }
        fn lookupNodeConst(comptime self: @This(), comptime key: K) ?@This() {
            var newself = self;
            var table: @TypeOf(self.next) = &newself;
            while (table) |node| : (table = node.next) {
                if (eq(key, node.key)) return node.*;
            }
            return null;
        }

        key: K,
        value: V,
        next: ?*@This(),
    };
}

fn strEq(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}
fn typeEq(comptime a: type, comptime b: type) bool {
    return a == b;
}
test "stuff" {
    @setEvalBranchQuota(1000000);
    const table = comptime blk: {
        var table = ComptimeTable([]const u8, type, strEq).init("hello", i32);
        var i: u8 = 0;
        while (i < 40) : (i += 1) {
            table.set(&[1]u8{i}, u8);
        }
        table.set("there", type);
        table.set("cruel", ComptimeTable(type, type, typeEq));
        table.set("world", i64);
        while (i < 40) : (i += 1) {
            table.set(&[1]u8{i}, u8);
        }
        break :blk table;
    };
    std.debug.warn("\ntable[\"hello\"] = {}\n", .{@typeName(comptime table.lookup("hello").?)});
    std.debug.warn("\ntable[20] = {}\n", .{@typeName(comptime table.lookup(&[1]u8{20}).?)});

    std.debug.warn("table = {}\n", .{table});
}
