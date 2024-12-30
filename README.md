<div align="center"> 

<img src="/assets/zinger.jpg" width="450" height="500">

# Zinger
A Simple HTTP request library 

# Contents
[Usage](#usage) |
[Make Requests](#make-requests) |
[GET](#get) |
[POST](#post) |
[PUT and DELETE](#put-and-delete) |
[Supported Requests](#supports) |

</div>


## Usage
Add Zinger to your Zig project with Zon:

```sh
zig fetch --save https://github.com/BitlyTwiser/zinger/archive/refs/tags/v0.1.1.tar.gz
```

Add the following to build.zig file:
```zig
    const zinger = b.dependency("zinger", .{});
    exe.root_module.addImport("zinger", zinger.module("zinger"));
```

Import Zinger and you should be set!
```zig
const zinger = @import("zinger").Zinger;
```

Please see the examples in the main.zig file or below to view using the package 

## Make requests
Any of the requsts can be made with a body utilizing the optional values. Additionally, any body can be converted to JSON by utilizing the anytype passed into the `json` function call.

The example in main shows how to make a request and check for errors in the query

### max_append_size
Note: The std.http.Client.FetchOptions, by default, sets a max body size (if not defined) to: ``` 2 * 1024 * 1024```.
If this is enough for your use cases (most general HTTP requests with a smaller JSON body would fit within this allotment), then everything is fine. Overwise, you will need to pass in the alloted/desired amount into Zinger init.

Example:
```zig
 var z = zinger.Zinger.init(allocator, null);

 // OR

// The numerical value here should be carefully considered to avoid over allocation.
var z = zinger.Zinger.init(allocator, 1024 * 10);
```

```zig
    const allocator = std.heap.page_allocator;
    var z = zinger.Zinger.init(allocator, null);

    defer z.deinit();

    var headers = [_]std.http.Header{};

    const resp = try z.get("<some api>", null, &headers);

    if (resp.err()) |err_data| {
        std.debug.print("{s}", .{err_data.phrase});
    }

    if (resp.err() != null) {
        try resp.printErr();
    }
```

This is the most *basic* example there is for curating requests. A simple get request, but otherwiese does not display anything as we pass in a null body. (Perhaps useful if all you want to check is the status of the response which is done in the resp.err() check)

## GET
```zig
    const allocator = std.heap.page_allocator;
    var z = zinger.Zinger.init(allocator, 1024 * 2 * 2);

    defer z.deinit();

    var headers = [_]std.http.Header{};

    const resp = try z.get("<some api>", null, &headers);

    if (resp.err()) |err_data| {
        std.debug.print("{s}", .{err_data.phrase});
    }

    if (resp.err() != null) {
        try resp.printErr();
    }

    // Serialize the JSON data from the body using the json(anytype) method.
    // Pass any struct type here to marshal the body into the struct.
    //    Obviously, ensure that the struct attributes match the returned JSON data from the endpoint
    const json_resp = try resp.json(test_resp_type);
    std.debug.print("{any}", .{json_resp});
```

## POST
You can denote whatever type you want for the JSON data in a custom struct
```zig
const test_resp_type = struct {
    test_data: []const u8,
};
```

```zig
fn post(allocator: std.mem.Allocator) !void {
    // Create Zinger instance for POST
    var z = zinger.Zinger.init(allocator, null);

    const test_data = struct {
        example_string: []const u8,
    }{
        .example_string = "testing",
    };

    const json_body = std.json.stringifyAlloc(allocator, test_data, .{});
    defer allocator.free(json_body);

    var headers = [_]std.http.Header{.{ .name = "content-type", .value = "application/json" }};

    const resp = try z.get("<api endpoint>", test_data, &headers);

    if (resp.err()) |err_data| {
        std.debug.print("{s}", .{err_data.phrase});
    }

    if (resp.err() != null) {
        try resp.printErr();
    }

    // Serialize the JSON data from the body using the json(anytype) method using the custom struct above
    const resp_data = struct {
        example_string: []const u8,
    }{};

    const json_resp = try resp.json(resp_data);
    std.debug.print("{any}", .{json_resp});
}
```

## PUT and DELETE
 Following the same pattern above, you *can* unclude a body as part of the DELETE/PUT requests. The library is really designed around however the user wants to present the data, attempting to make it as simple as possible to make all the general requests you need.

 For PUT/DELETE, simply change the HTTP verb in the above examples and you are set!

 PUT/DELETE:
 ```zig
 fn delete(allocator: std.mem.Allocator) !void {
    // Create Zinger instance for POST
    // The value for the max_override here is just symbolic for reference,
    //   this would generally be null unless you *need* to override this value 
    var z = zinger.Zinger.init(allocator, 2048 * 10);

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
 ```


# Supports
GET, POST, PUT, and DELETE requests

