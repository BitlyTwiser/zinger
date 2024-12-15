const std = @import("std");

pub const ClassData = struct {
    status: std.http.Status.Class = .success,
    phrase: []const u8 = "",
    raw: ?std.http.Client.FetchResult = null, // Used to store the raw response in case users wish to deal with this diretly (in the case of a SOAP endpoint etc.. which we do not handle)
};

const method = union(enum) {
    get,
    post,
    delete,
    put,

    const Self = @This();

    fn method_type(self: Self) std.http.Method {
        switch (self) {
            .get => {
                return .GET;
            },
            .post => {
                return .POST;
            },
            .delete => {
                return .DELETE;
            },
            .put => {
                return .PUT;
            },
        }
    }
};

pub const Zinger = struct {
    /// Zinger is a small library to wrap the std.http.Client interactions for simplicity.
    /// https://www.rfc-editor.org/rfc/rfc9110.html
    const Self = @This();
    const Allocator = std.mem.Allocator;

    allocator: Allocator,
    client: std.http.Client,
    body: std.ArrayList(u8),
    class_data: ClassData = .{},

    pub fn init(allocator: Allocator) Self {
        const c = std.http.Client{ .allocator = allocator };
        return Self{
            .allocator = allocator,
            .client = c,
            .body = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.client.deinit();
        self.body.deinit();
    }

    pub fn delete(self: *Self, url: []const u8, headers: []std.http.Header) !Zinger {
        return self.base_http_req(url, null, headers, .delete);
    }

    pub fn get(self: *Self, url: []const u8, body: ?[]const u8, headers: []std.http.Header) !Zinger {
        return self.base_http_req(url, body, headers, .get);
    }

    pub fn get_with_body(self: *Self, url: []const u8, body: []const u8, headers: []std.http.Header) !Zinger {
        return self.base_http_req(url, body, headers, .get);
    }

    pub fn post(self: *Self, url: []const u8, body: []const u8, headers: []std.http.Header) !Zinger {
        return self.base_http_req(url, body, headers, .post);
    }

    pub fn put(self: *Self, url: []const u8, body: []const u8, headers: []std.http.Header) !std.http.Client.FetchResult {
        return self.base_http_req(url, body, headers, .put);
    }

    pub fn base_http_req(self: *Self, url: []const u8, body: ?[]const u8, headers: []std.http.Header, method_type: method) !Zinger {
        const fetch_options = std.http.Client.FetchOptions{
            .location = std.http.Client.FetchOptions.Location{
                .url = url,
            },
            .extra_headers = headers,
            .method = method_type.method_type(),
            .payload = body,
            .response_storage = .{ .dynamic = &self.body },
        };

        const res = try self.client.fetch(fetch_options);

        self.class_data = ClassData{
            .phrase = res.status.phrase() orelse "response from server was blank",
            .status = res.status.class(),
            .raw = res,
        };

        return self.*;
    }

    /// Used to check for any returned errors from the network request. resp.status.class() enum can also be checked for .success
    pub fn err(self: Self) ?ClassData {
        if (self.class_data.status != .success) {
            return self.class_data;
        }

        return null;
    }

    // Writes stored error data from a non-successful client connection
    pub fn printErr(self: Self) !void {
        const outw = std.io.getStdOut().writer();
        try outw.print("{s}", .{self.class_data.phrase});
    }

    // Converts the respons body to JSON of any request (Except delete - delete always expects an empty body to be present)
    pub fn json(self: Self, data: anytype) !data {
        const req_body = try self.body.toOwnedSlice();

        const parsed_body = try std.json.parseFromSlice(data, self.allocator, req_body, .{});

        return parsed_body.value;
    }
};

const test_req = struct {
    field1: []const u8,
};

const test_resp = struct {
    words: []const u8,
};

fn test_post() void {}

fn test_post_json() void {}

test test_post_json {
    const allocator = std.heap.page_allocator;

    var req = Zinger.init(allocator);
    defer req.deinit();

    const test_request = test_req{
        .field1 = "Testing words",
    };

    const json_post = try std.json.stringifyAlloc(allocator, test_request, .{});
    defer allocator.free(json_post);

    var headers = [_]std.http.Header{.{ .name = "content-type", .value = "application/json" }};

    const resp = try req.post("http://192.168.50.71:3000/zinger-test", json_post, &headers);

    if (resp.err()) |err| {
        std.debug.print("error in POST request: {s}", .{err.phrase});

        return;
    }

    const json_resp = try resp.json(test_resp);
    std.debug.print("{any}", .{json_resp});
}

test test_post {}

test "test get" {
    const allocator = std.heap.page_allocator;

    var req = Zinger.init(allocator);
    defer req.deinit();

    var headers = [_]std.http.Header{.{}};

    const resp = try req.get("", &headers);

    if (resp.status.class() == .success) {
        for (req.body.items) |item| {
            std.debug.print("Response body item: {s}", .{item});
        }
    }

    // or convert into JSON if you know the expected type
    // std.json.parseFromSlice(comptime T: type, allocator: Allocator, s: []const u8, options: ParseOptions)
}
