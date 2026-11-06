const Player = @import("../domain/player.zig").Player;
const MissionSession = @import("../domain/mission_state.zig").MissionSession;

/// Defines the maximum in-game balance penalty when a mission is compromised.
pub const failure_penalty: u32 = 50;

/// Applies simulated Detection exposure and resets the active run if it reaches 100.
/// State is committed only after every corresponding output write succeeds.
pub fn apply(
    writer: anytype,
    player: *Player,
    active: *?usize,
    session: *MissionSession,
    amount: u8,
) !bool {
    var next_player = player.*;
    var next_active = active.*;
    var next_session = session.*;

    const previous_band = next_session.detectionBand();
    next_session.addDetection(amount);
    const current_band = next_session.detectionBand();
    if (current_band != previous_band and current_band != .compromised) {
        try writer.print("[DETECTION WARNING] Exposure is now {d}/100 ({s}).\n", .{
            next_session.detection_level, current_band.label(),
        });
    }
    if (next_session.detection_level >= 100) {
        const penalty = @min(next_player.balance, failure_penalty);
        next_player.balance -= penalty;
        try writer.print(
            "[CONTRACT FAILED] Detection reached 100/100. The operation was compromised. ${d} penalty applied; remaining balance: {d}. You may accept this contract again.\n",
            .{ penalty, next_player.balance },
        );
        next_active = null;
        next_session.reset();
        player.* = next_player;
        active.* = next_active;
        session.* = next_session;
        return true;
    }

    player.* = next_player;
    active.* = next_active;
    session.* = next_session;
    return false;
}
