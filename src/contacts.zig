// Compatibility facade; implementation lives in domain/contacts.zig.
const implementation = @import("domain/contacts.zig");
pub const ContactId = implementation.ContactId;
pub const intel_price = implementation.intel_price;
pub const detection_reduction = implementation.detection_reduction;
pub const isUnlocked = implementation.isUnlocked;
pub const fixerServicePrice = implementation.fixerServicePrice;
