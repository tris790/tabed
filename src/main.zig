const std = @import("std");
const UIAutomation = @import("UIAutomation.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const automation = try UIAutomation.init(allocator);
    _ = automation;
    while (true) {
        std.time.sleep(1_000_000_000); // 1s
    }
}
