// Keep the test module root at the repository root so tests can import src modules.
test {
    _ = @import("tests/test_all.zig");
}
