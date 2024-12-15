const std = @import("std");

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

    pub fn delete(self: *Self, url: []const u8, headers: []std.http.Header) !std.http.Client.FetchResult {
        return self.base_http_req(url, null, headers, .delete);
    }

    /// Blocking
    pub fn get(self: *Self, url: []const u8, headers: []std.http.Header) !std.http.Client.FetchResult {
        return self.base_http_req(url, null, headers, .get);
    }

    pub fn get_with_body(self: *Self, url: []const u8, body: []const u8, headers: []std.http.Header) !std.http.Client.FetchResult {
        return self.base_http_req(url, body, headers, .get);
    }

    /// Blocking
    pub fn post(self: *Self, url: []const u8, body: []const u8, headers: []std.http.Header) !std.http.Client.FetchResult {
        return self.base_http_req(url, body, headers, .post);
    }

    pub fn put(self: *Self, url: []const u8, body: []const u8, headers: []std.http.Header) !std.http.Client.FetchResult {
        return self.base_http_req(url, body, headers, .put);
    }

    pub fn base_http_req(self: *Self, url: ?[]const u8, body: []const u8, headers: []std.http.Header, method_type: method) !std.http.Client.FetchResult {
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
        return res;
    }

    // Make a more generic function using an enum to denote which method should be used. For the generic elemetns we can include all with _j or not depending since in theory, you could send a JSON body on delete request

    // Fills the incoming struct with the returned data from the POST request and returns the T type.
    pub fn post_j(self: *Self, url: []const u8, body: []const u8, headers: []std.http.Header, data: anytype) !data {
        const post_resp = try self.post(url, body, headers);

        if (post_resp.status.class() != .success) {
            // Do Something, perhaps add an error field and write to that?
        }

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

    const data = try req.post_j("http://192.168.1.71:3000/test", json_post, &headers, test_resp);

    std.debug.print("I have returned from the post {s}", .{data.words});
}

test test_post {
    const allocator = std.heap.page_allocator;
    var req = Zinger.init(allocator);

    defer req.deinit();

    const test_request = test_req{
        .field1 = "Testing words",
    };

    const json_post = try std.json.stringifyAlloc(allocator, test_request, .{});
    defer allocator.free(json_post);

    var headers = [_]std.http.Header{.{ .name = "content-type", .value = "application/json" }};

    const resp = try req.post("http://192.168.1.71:3000/test", json_post, &headers);
    const body = try req.body.toOwnedSlice();
    defer req.allocator.free(body);

    if (resp.status.class() != .success) {
        std.debug.print("Yo the request died bro\n", .{});
    }

    const parsed_body = try std.json.parseFromSlice(test_resp, allocator, body, .{});

    std.debug.print("Rquest body in string form: {s}\n", .{parsed_body.value.words});
}

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
