const std = @import("std");
const zinger = @import("lib.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var z = zinger.Zinger.init(allocator);

    defer z.deinit();

    var headers = [_]std.http.Header{};

    const resp = try z.get("192.168.50.71:3000/zinger-test", null, &headers);

    if (resp.err()) |err_data| {
        std.debug.print("{s}", .{err_data.phrase});
    }

    if (resp.err() != null) {
        try resp.printErr();
    }
}
