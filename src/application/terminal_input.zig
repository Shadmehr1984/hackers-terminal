/// Maximum input storage retained by the terminal REPL.
pub const buffer_capacity: usize = 512;

/// The previous REPL accepted at most 511 bytes before the line delimiter.
pub const max_line_length: usize = buffer_capacity - 1;

/// Returns whether a delimiter-free input slice exceeds the accepted command size.
pub fn isOverlong(line: []const u8) bool {
    return line.len > max_line_length;
}
