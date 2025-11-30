#[test_only]
module nft::nft_tests;

use nft::nft::{Self, NFTRegistry, MintingCap};
use std::string;
use sui::test_scenario::{Self as ts};
use std::unit_test::assert_eq;

// Test addresses
const ADMIN: address = @0xAD;
const USER1: address = @0x1;
const USER2: address = @0x2;

// ===== Complete Tests (Examples for Students) =====

/// Test 1: COMPLETE - Verify basic NFT minting works
/// This test demonstrates the full flow of minting an NFT
#[test]
fun test_mint_nft_success() {
    let mut scenario = ts::begin(ADMIN);

    // Initialize the module (creates registry, minting cap, etc)
    {
        nft::test_init(ts::ctx(&mut scenario));
    };

    // Get the shared registry and mint an NFT
    ts::next_tx(&mut scenario, USER1);
    {
        let mut registry = ts::take_shared<NFTRegistry>(&scenario);

        let nft = nft::mint_nft(
            &mut registry,
            string::utf8(b"Test Hero"),
            string::utf8(b"A test hero for unit testing"),
            string::utf8(b"https://example.com/hero.png"),
            ts::ctx(&mut scenario)
        );

        // Verify NFT properties
        assert_eq!(nft::get_nft_name(&nft), string::utf8(b"Test Hero"));
        assert_eq!(nft::get_nft_description(&nft), string::utf8(b"A test hero for unit testing"));

        // Verify registry was updated
        assert_eq!(nft::get_total_nfts_minted(&registry), 1);

        // Clean up
        transfer::public_transfer(nft, USER1);
        ts::return_shared(registry);
    };

    ts::end(scenario);
}

/// Test 2: COMPLETE - Verify weapon creation and registry tracking
#[test]
fun test_create_weapon_updates_registry() {
    let mut scenario = ts::begin(ADMIN);

    {
        nft::test_init(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, USER1);
    {
        let mut registry = ts::take_shared<NFTRegistry>(&scenario);

        // Create a weapon
        let weapon = nft::create_weapon(
            &mut registry,
            string::utf8(b"Sword"),
            100,
            ts::ctx(&mut scenario)
        );

        // Check registry updated
        assert_eq!(nft::get_total_weapons_created(&registry), 1);
        assert_eq!(nft::get_weapon_power_value(&weapon), 100);

        transfer::public_transfer(weapon, USER1);
        ts::return_shared(registry);
    };

    ts::end(scenario);
}

// ===== Incomplete Tests (For Students to Complete) =====

/// Test 3: INCOMPLETE - Students should complete this test
/// TODO: Test that equipping a weapon to an NFT works correctly
///
/// Steps to complete:
/// 1. Initialize the module
/// 2. Mint an NFT
/// 3. Create a weapon
/// 4. Equip the weapon to the NFT
/// 5. Verify the NFT has a weapon equipped (use has_weapon function)
/// 6. Verify the weapon power matches (use get_weapon_power function)
#[test]
fun test_equip_weapon_to_nft() {
    let mut scenario = ts::begin(ADMIN);

    // Step 1: Initialize
    {
        nft::test_init(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, USER1);
    {
        let mut registry = ts::take_shared<NFTRegistry>(&scenario);

        // Step 2: TODO - Mint an NFT here
        // Hint: let mut hero = nft::mint_nft(&mut registry, string::utf8(b"Archer"), string::utf8(b"A nimble archer"), string::utf8(b"https://example.com/archer.png"), ts::ctx(&mut scenario));


        // Step 3: TODO - Create a weapon here
        // Hint: let bow = nft::create_weapon(&mut registry, string::utf8(b"Bow"), 150u8, ts::ctx(&mut scenario));


        // Step 4: TODO - Equip the weapon to the NFT
        // Hint: nft::equip_weapon(&mut hero, bow);


        // Step 5: TODO - Verify NFT has weapon equipped
        // Hint: assert_eq!(nft::has_weapon(&hero), true);


        // Step 6: TODO - Verify weapon power
        // Hint: assert_eq!(nft::get_weapon_power(&hero), 150u8);


        // Clean up (this is provided)
        // transfer::public_transfer(nft, USER1);
        ts::return_shared(registry);
    };

    ts::end(scenario);
}

/// Test 4: INCOMPLETE - Students should test unequipping weapons
/// TODO: Test that unequipping a weapon works correctly
///
/// Steps to complete:
/// 1. Initialize module
/// 2. Mint NFT and create weapon
/// 3. Equip weapon to NFT
/// 4. Unequip the weapon (use nft::unequip_weapon)
/// 5. Verify NFT no longer has weapon (has_weapon should return false)
/// 6. Verify the weapon object is returned correctly
#[test]
fun test_unequip_weapon_from_nft() {
    let mut scenario = ts::begin(ADMIN);

    {
        nft::test_init(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, USER1);
    {
        let mut registry = ts::take_shared<NFTRegistry>(&scenario);

        // Setup: Mint NFT with equipped weapon (provided as example)
        let mut nft = nft::mint_nft(
            &mut registry,
            string::utf8(b"Warrior"),
            string::utf8(b"A warrior"),
            string::utf8(b"https://example.com/warrior.png"),
            ts::ctx(&mut scenario)
        );

        let weapon = nft::create_weapon(
            &mut registry,
            string::utf8(b"Axe"),
            200,
            ts::ctx(&mut scenario)
        );

        nft::equip_weapon(&mut nft, weapon);

        // TODO: Step 4 - Unequip the weapon
        // Hint: let unequipped_weapon = nft::unequip_weapon(&mut nft);


        // TODO: Step 5 - Verify NFT has no weapon
        // Hint: assert_eq!(nft::has_weapon(&nft), false);


        // TODO: Step 6 - Verify the weapon was returned
        // Hint: assert_eq!(nft::get_weapon_power_value(&unequipped_weapon), 200u8);


        // Clean up
        transfer::public_transfer(nft, USER1);
        // transfer::public_transfer(unequipped_weapon, USER1);
        ts::return_shared(registry);
    };

    ts::end(scenario);
}

/// Test 5: INCOMPLETE - Students should test admin minting with capability
/// TODO: Test that only MintingCap holders can use admin_mint_nft
///
/// Steps to complete:
/// 1. Take the MintingCap that was created in init
/// 2. Use admin_mint_nft to mint an NFT to USER2
/// 3. Verify the NFT was created and sent to USER2
/// 4. Verify the registry counter increased
#[test]
fun test_admin_mint_with_capability() {
    let mut scenario = ts::begin(ADMIN);

    {
        nft::test_init(ts::ctx(&mut scenario));
    };

    // Admin mints NFT for USER2
    ts::next_tx(&mut scenario, ADMIN);
    {
        let mint_cap = ts::take_from_sender<MintingCap>(&scenario);
        let mut registry = ts::take_shared<NFTRegistry>(&scenario);

        // TODO: Use admin_mint_nft to mint NFT for USER2
        // Hint: nft::admin_mint_nft(&mint_cap, &mut registry, string::utf8(b"Admin Hero"), string::utf8(b"Minted by admin"), string::utf8(b"https://example.com/admin-hero.png"), USER2, ts::ctx(&mut scenario));


        // TODO: Verify registry counter increased to 1
        // Hint: assert_eq!(nft::get_total_nfts_minted(&registry), 1u64);


        ts::return_to_sender(&scenario, mint_cap);
        ts::return_shared(registry);
    };

    // USER2 receives the NFT
    ts::next_tx(&mut scenario, USER2);
    {
        // TODO: Take the NFT that USER2 received
        // Hint: let nft_obj = ts::take_from_sender<HeroNft>(&scenario);


        // TODO: Verify the NFT properties are correct
        // Hint: assert_eq!(nft::get_nft_name(&nft_obj), string::utf8(b"Admin Hero")); and assert_eq description


        // Clean up
        // transfer::public_transfer(nft_obj, USER2);
    };

    ts::end(scenario);
}

/// Test 6: BONUS CHALLENGE - Students create this test from scratch
/// TODO: Write a test that verifies multiple NFTs and weapons can be tracked
///
/// Requirements:
/// - Mint 3 different NFTs (store in mut hero1, mut hero2, mut hero3)
/// - Create 5 different weapons (store in w1, w2, w3, w4, w5)
/// - Equip w1 to hero1 and w2 to hero2
/// - Verify registry shows total_nfts_minted = 3
/// - Verify registry shows total_weapons_created = 5
/// - Verify has_weapon returns true for equipped NFTs, false for hero3
/// - Transfer all objects back to USER1 and return the registry
///
/// Hint structure:
/// 1. Set up with ts::begin(ADMIN) and nft::test_init()
/// 2. ts::next_tx() and take_shared registry
/// 3. Mint/create using the same patterns from Test 3
/// 4. Use assertions matching Test 3 patterns
/// 5. Clean up with transfer::public_transfer() and ts::return_shared()
#[test]
fun test_multiple_nfts_and_weapons_tracking() {
    // TODO: Write the entire test here
    // Good luck! Use the tests above as reference




}

// ===== Error Tests (Advanced - Optional) =====

/// Test 7: COMPLETE - Verify equipping weapon to slot that's occupied fails
#[test]
#[expected_failure(abort_code = 3)]  // EWeaponSlotOccupied = 3
fun test_cannot_equip_weapon_when_slot_occupied() {
    let mut scenario = ts::begin(USER1);

    {
        nft::test_init(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, USER1);
    {
        let mut registry = ts::take_shared<NFTRegistry>(&scenario);

        let mut nft = nft::mint_nft(
            &mut registry,
            string::utf8(b"Hero"),
            string::utf8(b"Desc"),
            string::utf8(b"url"),
            ts::ctx(&mut scenario)
        );

        // Equip first weapon
        let weapon1 = nft::create_weapon(&mut registry, string::utf8(b"Sword"), 50, ts::ctx(&mut scenario));
        nft::equip_weapon(&mut nft, weapon1);

        // Try to equip second weapon - should fail
        let weapon2 = nft::create_weapon(&mut registry, string::utf8(b"Axe"), 100, ts::ctx(&mut scenario));
        nft::equip_weapon(&mut nft, weapon2); // This should abort

        transfer::public_transfer(nft, USER1);
        ts::return_shared(registry);
    };

    ts::end(scenario);
}

/// Test 8: INCOMPLETE - Students write a test for invalid NFT name
/// TODO: Write a test that verifies minting fails with empty name
///
/// Hint: Use #[expected_failure(abort_code = 0)]  // EInvalidName = 0
/// Steps:
/// 1. Set up scenario and initialize module
/// 2. ts::next_tx() and take_shared registry
/// 3. Call nft::mint_nft with an empty name: string::utf8(b"")
/// 4. Pass valid description and image_url
/// 5. The call should abort - the test framework catches it automatically
/// Note: Even though the call aborts, you may need to reference the return value
///       to satisfy Move's type-checking (it won't execute, but the code must type-check)
#[test]
#[expected_failure(abort_code = 0)]  // EInvalidName = 0
fun test_cannot_mint_nft_with_empty_name() {
    // TODO: Complete this test
    // 1. Set up scenario
    // Hint: let mut scenario = ts::begin(USER1);
    
    // 2. Initialize the module
    // Hint: { nft::test_init(ts::ctx(&mut scenario)); };
    
    // 3. Create a transaction and take the registry
    // Hint: ts::next_tx(&mut scenario, USER1); let mut registry = ts::take_shared<NFTRegistry>(&scenario);
    
    // 4. Try to mint with empty name - should abort
    // Hint: let nft_obj = nft::mint_nft(&mut registry, string::utf8(b""), string::utf8(b"Some desc"), string::utf8(b"some-url"), ts::ctx(&mut scenario));
    
    // 5. Use the returned object (won't execute but needed for type-check)
    // Hint: transfer::public_transfer(nft_obj, USER1);
    
    // 6. Clean up
    // Hint: ts::return_shared(registry); ts::end(scenario);
}
