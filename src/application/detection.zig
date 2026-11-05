const Player = @import("../domain/player.zig").Player;
const MissionSession = @import("../domain/mission_state.zig").MissionSession;

pub const failure_penalty: u32 = 50;

pub fn apply(
    writer: anytype,
    player: *Player,
    active: *?usize,
    session: *MissionSession,
    amount: u8,
) !bool {
    const previous_band = session.detectionBand();
    session.addDetection(amount);
    const current_band = session.detectionBand();
    if (current_band != previous_band and current_band != .compromised) {
        try writer.print("[DETECTION WARNING] Exposure is now {d}/100 ({s}).\n", .{
            session.detection_level, current_band.label(),
        });
    }
    if (session.detection_level >= 100) {
        const penalty = @min(player.balance, failure_penalty);
        player.balance -= penalty;
        try writer.print(
            "[CONTRACT FAILED] Detection reached 100/100. The operation was compromised. ${d} penalty applied; remaining balance: {d}. You may accept this contract again.\n",
            .{ penalty, player.balance },
        );
        active.* = null;
        session.reset();
        return true;
    }
    return false;
}
