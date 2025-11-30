module nft::nft;

// ===== Imports =====
use std::string::{Self, String};
use sui::package;
use sui::display;
use sui::event;

// ===== Errors =====
const EInvalidName: u64 = 0;
const EInvalidDescription: u64 = 1;
const EInvalidImageUrl: u64 = 2;
const EWeaponSlotOccupied: u64 = 3;
const ENoWeaponEquipped: u64 = 4;

// ===== Constants =====
const MAX_NAME_LENGTH: u64 = 50;
const MIN_NAME_LENGTH: u64 = 1;

// ===== Structs =====

/// One-time witness for the module, used to claim Publisher
public struct NFT has drop {}

/// Capability that allows minting new NFTs
/// Only holders of this object can mint NFTs using admin functions
public struct MintingCap has key, store {
    id: UID,
}

/// A weapon that can be equipped to a HeroNft
/// Weapons are standalone objects that can be traded independently
public struct Weapon has key, store {
    id: UID,
    name: String,
    power: u8,
}

/// The main NFT representing a hero character
/// Heroes can optionally equip a weapon for added power
public struct HeroNft has key, store {
    id: UID,
    name: String,
    description: String,
    image_url: String,
    /// Optional weapon slot - can hold one weapon at a time
    weapon_slot: Option<Weapon>,
}

/// Shared registry tracking global NFT statistics
/// This is a SHARED object - anyone can read/write, demonstrating shared object patterns
/// Unlike owned objects (like HeroNft), this requires consensus for mutations
public struct NFTRegistry has key {
    id: UID,
    /// Total number of NFTs minted across all users
    total_nfts_minted: u64,
    /// Total number of weapons created
    total_weapons_created: u64,
}

// ===== Events =====

/// Emitted when a new NFT is minted
public struct NFTMinted has copy, drop {
    nft_id: ID,
    name: String,
    description: String,
    image_url: String,
    recipient: address,
    minted_by: address,
}

/// Emitted when a weapon is created
public struct WeaponCreated has copy, drop {
    weapon_id: ID,
    name: String,
    power: u8,
    creator: address,
}

/// Emitted when a weapon is equipped to an NFT
public struct WeaponEquipped has copy, drop {
    nft_id: ID,
    weapon_id: ID,
    weapon_name: String,
}

/// Emitted when a weapon is unequipped from an NFT
public struct WeaponUnequipped has copy, drop {
    nft_id: ID,
    weapon_id: ID,
}

// ===== Public Functions =====

/// Creates and returns a new HeroNft and updates the shared registry
/// This function is designed for PTB composability - returns the NFT instead of transferring it
/// Callers can chain this with other operations in a programmable transaction
/// Note: Takes a mutable reference to the SHARED registry object
public fun mint_nft(
    registry: &mut NFTRegistry,
    name: String,
    description: String,
    image_url: String,
    ctx: &mut TxContext
): HeroNft {
    // Basic validation to prevent empty or oversized names
    assert!(string::length(&name) >= MIN_NAME_LENGTH, EInvalidName);
    assert!(string::length(&name) <= MAX_NAME_LENGTH, EInvalidName);
    assert!(string::length(&description) > 0, EInvalidDescription);
    assert!(string::length(&image_url) > 0, EInvalidImageUrl);

    let nft = HeroNft {
        id: object::new(ctx),
        name,
        description,
        image_url,
        weapon_slot: option::none<Weapon>(),
    };

    // Update shared registry statistics
    registry.total_nfts_minted = registry.total_nfts_minted + 1;

    nft
}

/// Creates and returns a new Weapon object and updates the shared registry
/// Designed for PTB composability - can be chained with equip_weapon in a single transaction
/// Example: mint_nft -> create_weapon -> equip_weapon (all in one PTB)
public fun create_weapon(
    registry: &mut NFTRegistry,
    name: String,
    power: u8,
    ctx: &mut TxContext
): Weapon {
    let weapon = Weapon {
        id: object::new(ctx),
        name,
        power,
    };

    // Update shared registry
    registry.total_weapons_created = registry.total_weapons_created + 1;

    event::emit(WeaponCreated {
        weapon_id: object::id(&weapon),
        name: weapon.name,
        power: weapon.power,
        creator: tx_context::sender(ctx),
    });

    weapon
}

/// Equips a weapon to an NFT's weapon slot
/// Takes ownership of the weapon and stores it inside the NFT
/// The weapon can later be unequipped to recover it as a standalone object
public fun equip_weapon(
    nft: &mut HeroNft,
    weapon: Weapon,
) {
    // Make sure there's no weapon already equipped
    assert!(option::is_none(&nft.weapon_slot), EWeaponSlotOccupied);

    event::emit(WeaponEquipped {
        nft_id: object::id(nft),
        weapon_id: object::id(&weapon),
        weapon_name: weapon.name,
    });

    option::fill(&mut nft.weapon_slot, weapon);
}

/// Removes and returns the equipped weapon from an NFT
/// The weapon becomes a standalone object again and can be traded or equipped elsewhere
public fun unequip_weapon(
    nft: &mut HeroNft,
): Weapon {
    // Verify there's actually a weapon to unequip
    assert!(option::is_some(&nft.weapon_slot), ENoWeaponEquipped);

    let weapon = option::extract(&mut nft.weapon_slot);

    event::emit(WeaponUnequipped {
        nft_id: object::id(nft),
        weapon_id: object::id(&weapon),
    });

    weapon
}

// ===== Entry Functions =====
// Entry modifiers are kept for explorer testing despite composability warnings

/// Mints an NFT and transfers it to the sender
/// This is the main minting function for regular users (no capability required)
/// Entry modifier allows calling from explorer for testing
#[allow(lint(public_entry))]
public entry fun mint_nft_to_sender(
    registry: &mut NFTRegistry,
    name: String,
    description: String,
    image_url: String,
    ctx: &mut TxContext
) {
    let nft = mint_nft(registry, name, description, image_url, ctx);
    let sender = tx_context::sender(ctx);

    event::emit(NFTMinted {
        nft_id: object::id(&nft),
        name: nft.name,
        description: nft.description,
        image_url: nft.image_url,
        recipient: sender,
        minted_by: sender,
    });

    transfer::public_transfer(nft, sender);
}

/// Entry function for creating a weapon and sending it to the caller
/// For PTB usage, prefer the create_weapon function which returns the weapon
#[allow(lint(public_entry))]
public entry fun mint_weapon_to_sender(
    registry: &mut NFTRegistry,
    name: String,
    power: u8,
    ctx: &mut TxContext
) {
    let weapon = create_weapon(registry, name, power, ctx);
    let sender = tx_context::sender(ctx);
    transfer::public_transfer(weapon, sender);
}

/// Entry wrapper for equipping a weapon
/// Useful when called directly from a wallet or explorer
#[allow(lint(public_entry))]
public entry fun equip_weapon_entry(
    nft: &mut HeroNft,
    weapon: Weapon,
) {
    equip_weapon(nft, weapon);
}

/// Entry wrapper for unequipping a weapon and sending it to the caller
#[allow(lint(public_entry))]
public entry fun unequip_weapon_to_sender(
    nft: &mut HeroNft,
    ctx: &mut TxContext
) {
    let weapon = unequip_weapon(nft);
    let sender = tx_context::sender(ctx);
    transfer::public_transfer(weapon, sender);
}

// ===== View Functions =====

/// Returns the NFT's name
public fun get_nft_name(nft: &HeroNft): String {
    nft.name
}

/// Returns the NFT's description
public fun get_nft_description(nft: &HeroNft): String {
    nft.description
}

/// Returns the NFT's image URL
public fun get_nft_image_url(nft: &HeroNft): String {
    nft.image_url
}

/// Checks if the NFT has a weapon equipped
public fun has_weapon(nft: &HeroNft): bool {
    option::is_some(&nft.weapon_slot)
}

/// Returns the equipped weapon's power (0 if no weapon)
public fun get_weapon_power(nft: &HeroNft): u8 {
    if (option::is_some(&nft.weapon_slot)) {
        option::borrow(&nft.weapon_slot).power
    } else {
        0
    }
}

/// Returns the weapon's name
public fun get_weapon_name(weapon: &Weapon): String {
    weapon.name
}

/// Returns the weapon's power value
public fun get_weapon_power_value(weapon: &Weapon): u8 {
    weapon.power
}

/// Returns total number of NFTs minted globally
public fun get_total_nfts_minted(registry: &NFTRegistry): u64 {
    registry.total_nfts_minted
}

/// Returns total number of weapons created globally
public fun get_total_weapons_created(registry: &NFTRegistry): u64 {
    registry.total_weapons_created
}

// ===== Admin Functions =====

/// Admin-only minting function that requires a MintingCap
/// This allows controlled NFT creation by authorized addresses
public fun admin_mint_nft(
    _mint_cap: &MintingCap,
    registry: &mut NFTRegistry,
    name: String,
    description: String,
    image_url: String,
    recipient: address,
    ctx: &mut TxContext
) {
    assert!(string::length(&name) >= MIN_NAME_LENGTH, EInvalidName);
    assert!(string::length(&name) <= MAX_NAME_LENGTH, EInvalidName);
    assert!(string::length(&description) > 0, EInvalidDescription);
    assert!(string::length(&image_url) > 0, EInvalidImageUrl);

    let nft = HeroNft {
        id: object::new(ctx),
        name,
        description,
        image_url,
        weapon_slot: option::none<Weapon>(),
    };

    // Update shared registry
    registry.total_nfts_minted = registry.total_nfts_minted + 1;

    event::emit(NFTMinted {
        nft_id: object::id(&nft),
        name: nft.name,
        description: nft.description,
        image_url: nft.image_url,
        recipient,
        minted_by: tx_context::sender(ctx),
    });

    transfer::public_transfer(nft, recipient);
}

/// Creates a new MintingCap and transfers it to the specified address
/// Only the package publisher can create new minting capabilities
/// This allows the original deployer to delegate minting rights to other addresses
public fun create_minting_capability(
    publisher: &package::Publisher,
    recipient: address,
    ctx: &mut TxContext
) {
    // Verify the publisher is for this package
    assert!(package::from_package<NFT>(publisher), 0);

    let new_cap = MintingCap {
        id: object::new(ctx),
    };
    transfer::public_transfer(new_cap, recipient);
}

// ===== Package Functions =====

/// Module initializer - runs once when the package is published
/// Sets up the Display object for NFT metadata and creates the first MintingCap
/// Also creates and shares the NFT Registry for global statistics tracking
fun init(otw: NFT, ctx: &mut TxContext) {
    let sender = tx_context::sender(ctx);
    let publisher = package::claim(otw, ctx);

    // Set up display metadata for wallets and explorers
    let keys = vector[
        std::string::utf8(b"name"),
        std::string::utf8(b"description"),
        std::string::utf8(b"image_url"),
        std::string::utf8(b"project_name"),
        std::string::utf8(b"creator"),
    ];

    let values = vector[
        std::string::utf8(b"{name}"),
        std::string::utf8(b"{description}"),
        std::string::utf8(b"{image_url}"),
        std::string::utf8(b"Sui Workshop"),
        std::string::utf8(b"Sui Workshop Novi Sad"),
    ];

    let mut display = display::new<HeroNft>(&publisher, ctx);
    display::add_multiple(&mut display, keys, values);
    display::update_version(&mut display);

    // Create the initial minting capability for the deployer
    let mint_cap = MintingCap {
        id: object::new(ctx),
    };

    // Create and SHARE the NFT registry
    // This demonstrates shared objects - anyone can access and modify this
    let registry = NFTRegistry {
        id: object::new(ctx),
        total_nfts_minted: 0,
        total_weapons_created: 0,
    };

    transfer::public_transfer(publisher, sender);
    transfer::public_transfer(mint_cap, sender);
    transfer::public_transfer(display, sender);

    // SHARE the registry instead of transferring it
    // This makes it globally accessible - anyone can read/write
    transfer::share_object(registry);
}

// ===== Test Functions =====

#[test_only]
public fun test_init(ctx: &mut TxContext) {
    let otw = NFT {};
    init(otw, ctx);
}
