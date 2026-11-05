pub const Player = struct {
    handle: []const u8 = "ghost",
    balance: u32 = 250,
    reputation: u32 = 0,
    xp: u32 = 0,
    has_decryptor: bool = false,
};
