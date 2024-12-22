const std = @import("std");
const zinger = @import("lib.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    try get(allocator);
    try post(allocator);
    try delete(allocator);
    try put(allocator);
}

// Here is a roster of examples
fn get(allocator: std.mem.Allocator) !void {
    // Create Zinger instance for GET
    var z = zinger.Zinger.init(allocator, null);

    defer z.deinit();

    var headers = [_]std.http.Header{};

    const resp = try z.get("<api endpoint>", null, &headers);

    if (resp.err()) |err_data| {
        std.debug.print("{s}", .{err_data.phrase});

        return;
    }

    // Another example of how to deal with the errors that may be found
    if (resp.err() != null) {
        try resp.printErr();

        return;
    }
}

const test_resp_type = struct {
    test_data: []const u8,
};

fn post(allocator: std.mem.Allocator) !void {
    // Create Zinger instance for POST
    var z = zinger.Zinger.init(allocator, 1024 * 2);

    const test_data = struct {
        example_string: []const u8,
    }{
        .example_string = "testing",
    };

    const json_body = try std.json.stringifyAlloc(allocator, test_data, .{});
    defer allocator.free(json_body);

    var headers = [_]std.http.Header{.{ .name = "content-type", .value = "application/json" }};

    var resp = try z.post("<api endpoint>", json_body, &headers);

    if (resp.err()) |err_data| {
        std.debug.print("{s}", .{err_data.phrase});

        return;
    }

    // Serialize the JSON data from the body using the json(anytype) method.
    const json_resp = try resp.json(test_resp_type);
    std.debug.print("{any}", .{json_resp});
}

fn delete(allocator: std.mem.Allocator) !void {
    // Create Zinger instance for POST
    var z = zinger.Zinger.init(allocator, null);

    const test_data = struct {
        example_string: []const u8,
    }{
        .example_string = "testing",
    };

    const json_body = try std.json.stringifyAlloc(allocator, test_data, .{});
    defer allocator.free(json_body);

    var headers = [_]std.http.Header{.{ .name = "content-type", .value = "application/json" }};

    var resp = try z.delete("<api endpoint>", json_body, &headers);

    if (resp.err() != null) {
        try resp.printErr();

        return;
    }

    // Serialize the JSON data from the body using the json(anytype) method.
    const json_resp = try resp.json(test_resp_type);
    std.debug.print("{any}", .{json_resp});
}

fn put(allocator: std.mem.Allocator) !void {
    // Create Zinger instance for POST
    var z = zinger.Zinger.init(allocator, null);

    const test_data = struct {
        example_string: []const u8,
    }{
        .example_string = "testing",
    };

    const json_body = try std.json.stringifyAlloc(allocator, test_data, .{});
    defer allocator.free(json_body);

    var headers = [_]std.http.Header{.{ .name = "content-type", .value = "application/json" }};

    var resp = try z.put("<api endpoint>", json_body, &headers);

    if (resp.err()) |err_data| {
        std.debug.print("{s}", .{err_data.phrase});

        return;
    }

    // Serialize the JSON data from the body using the json(anytype) method.
    const json_resp = try resp.json(test_resp_type);
    std.debug.print("{any}", .{json_resp});
}
