#[test_only]
module nft::nft_tests_fixed;

use nft::nft::{Self, NFTRegistry, MintingCap, HeroNft};
use std::string;
use sui::test_scenario::{Self as ts};
use std::unit_test::assert_eq;

// Test addresses
const ADMIN: address = @0xAD;
const USER1: address = @0x1;
const USER2: address = @0x2;

/// This file contains completed versions of the student exercises in
/// `tests/nft_tests.move`. It mirrors those tests but fills in the TODOs
/// so you have fully-working examples to show students how to fix them.

#[test]
fun test_equip_weapon_to_nft_completed() {
    let mut scenario = ts::begin(ADMIN);

    // Initialize the module (creates registry, minting cap, etc)
    {
        nft::test_init(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, USER1);
    {
        let mut registry = ts::take_shared<NFTRegistry>(&scenario);

        // Mint an NFT
        let mut hero = nft::mint_nft(
            &mut registry,
            string::utf8(b"Archer"),
            string::utf8(b"A nimble archer"),
            string::utf8(b"https://example.com/archer.png"),
            ts::ctx(&mut scenario)
        );

        // Create a weapon
        let bow = nft::create_weapon(
            &mut registry,
            string::utf8(b"Bow"),
            150u8,
            ts::ctx(&mut scenario)
        );

        // Equip the weapon to the NFT
        nft::equip_weapon(&mut hero, bow);

        // Verify NFT has weapon equipped and the power matches
        assert_eq!(nft::has_weapon(&hero), true);
        assert_eq!(nft::get_weapon_power(&hero), 150u8);

        // Clean up - send objects back to USER1 (example flow)
        transfer::public_transfer(hero, USER1);
        ts::return_shared(registry);
    };

    ts::end(scenario);
}

#[test]
fun test_unequip_weapon_from_nft_completed() {
    let mut scenario = ts::begin(ADMIN);

    // Initialize
    {
        nft::test_init(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, USER1);
    {
        let mut registry = ts::take_shared<NFTRegistry>(&scenario);

        // Mint NFT and create weapon
        let mut warrior = nft::mint_nft(
            &mut registry,
            string::utf8(b"Warrior"),
            string::utf8(b"A strong warrior"),
            string::utf8(b"https://example.com/warrior.png"),
            ts::ctx(&mut scenario)
        );

        let axe = nft::create_weapon(
            &mut registry,
            string::utf8(b"Axe"),
            200u8,
            ts::ctx(&mut scenario)
        );

        // Equip and then unequip
        nft::equip_weapon(&mut warrior, axe);

        let unequipped_weapon = nft::unequip_weapon(&mut warrior);

        // Verify NFT has no weapon equipped and check unequipped weapon
        assert_eq!(nft::has_weapon(&warrior), false);
        assert_eq!(nft::get_weapon_power_value(&unequipped_weapon), 200u8);

        // Clean up: send the NFT and the returned weapon back to the owner
        transfer::public_transfer(warrior, USER1);
        transfer::public_transfer(unequipped_weapon, USER1);
        ts::return_shared(registry);
    };

    ts::end(scenario);
}

#[test]
fun test_admin_mint_with_capability_completed() {
    let mut scenario = ts::begin(ADMIN);

    // Initialize module which creates the MintingCap and shared registry
    {
        nft::test_init(ts::ctx(&mut scenario));
    };

    // Admin mints NFT for USER2 using MintingCap
    ts::next_tx(&mut scenario, ADMIN);
    {
        let mint_cap = ts::take_from_sender<MintingCap>(&scenario);
        let mut registry = ts::take_shared<NFTRegistry>(&scenario);

        // Use admin_mint_nft to mint an NFT for USER2
        nft::admin_mint_nft(
            &mint_cap,
            &mut registry,
            string::utf8(b"Admin Hero"),
            string::utf8(b"Minted by admin"),
            string::utf8(b"https://example.com/admin-hero.png"),
            USER2,
            ts::ctx(&mut scenario)
        );

        // Verify registry counter increased to 1
        assert_eq!(nft::get_total_nfts_minted(&registry), 1u64);

        // Return the MintingCap and the registry back
        ts::return_to_sender(&scenario, mint_cap);
        ts::return_shared(registry);
    };

    // USER2 receives the NFT - take it and validate properties
    ts::next_tx(&mut scenario, USER2);
    {
        let nft_obj = ts::take_from_sender<HeroNft>(&scenario);

        // Verify the NFT properties are correct
        assert_eq!(nft::get_nft_name(&nft_obj), string::utf8(b"Admin Hero"));
        assert_eq!(nft::get_nft_description(&nft_obj), string::utf8(b"Minted by admin"));

        // Clean up
        transfer::public_transfer(nft_obj, USER2);
    };

    ts::end(scenario);
}

#[test]
fun test_multiple_nfts_and_weapons_tracking_completed() {
    let mut scenario = ts::begin(ADMIN);

    // Initialize module
    {
        nft::test_init(ts::ctx(&mut scenario));
    };

    // Single transaction by USER1: mint 3 NFTs and create 5 weapons
    ts::next_tx(&mut scenario, USER1);
    {
        let mut registry = ts::take_shared<NFTRegistry>(&scenario);

        // Mint 3 distinct NFTs
        let mut hero1 = nft::mint_nft(&mut registry, string::utf8(b"Hero A"), string::utf8(b"A"), string::utf8(b"url1"), ts::ctx(&mut scenario));
        let mut hero2 = nft::mint_nft(&mut registry, string::utf8(b"Hero B"), string::utf8(b"B"), string::utf8(b"url2"), ts::ctx(&mut scenario));
        let hero3 = nft::mint_nft(&mut registry, string::utf8(b"Hero C"), string::utf8(b"C"), string::utf8(b"url3"), ts::ctx(&mut scenario));

        // Create 5 weapons
        let w1 = nft::create_weapon(&mut registry, string::utf8(b"W1"), 10u8, ts::ctx(&mut scenario));
        let w2 = nft::create_weapon(&mut registry, string::utf8(b"W2"), 20u8, ts::ctx(&mut scenario));
        let w3 = nft::create_weapon(&mut registry, string::utf8(b"W3"), 30u8, ts::ctx(&mut scenario));
        let w4 = nft::create_weapon(&mut registry, string::utf8(b"W4"), 40u8, ts::ctx(&mut scenario));
        let w5 = nft::create_weapon(&mut registry, string::utf8(b"W5"), 50u8, ts::ctx(&mut scenario));

        // Equip weapons to 2 of the NFTs
        nft::equip_weapon(&mut (hero1), w1);
        nft::equip_weapon(&mut (hero2), w2);

        // Verify registry totals
        assert_eq!(nft::get_total_nfts_minted(&registry), 3u64);
        assert_eq!(nft::get_total_weapons_created(&registry), 5u64);

        // Verify has_weapon values
        assert_eq!(nft::has_weapon(&hero1), true);
        assert_eq!(nft::has_weapon(&hero2), true);
        assert_eq!(nft::has_weapon(&hero3), false);

        // Clean up: transfer created objects back to USER1
        transfer::public_transfer(hero1, USER1);
        transfer::public_transfer(hero2, USER1);
        transfer::public_transfer(hero3, USER1);

        // w3, w4, w5 are still standalone objects and should be returned too
        transfer::public_transfer(w3, USER1);
        transfer::public_transfer(w4, USER1);
        transfer::public_transfer(w5, USER1);

        ts::return_shared(registry);
    };

    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = 0)]
fun test_cannot_mint_nft_with_empty_name_completed() {
    let mut scenario = ts::begin(USER1);

    // Initialize
    {
        nft::test_init(ts::ctx(&mut scenario));
    };

    ts::next_tx(&mut scenario, USER1);
    {
        let mut registry = ts::take_shared<NFTRegistry>(&scenario);

        // Attempt to mint with an empty name - should abort
        let nft_obj = nft::mint_nft(
            &mut registry,
            string::utf8(b""),
            string::utf8(b"Some desc"),
            string::utf8(b"some-url"),
            ts::ctx(&mut scenario)
        );

        // Use the created object so Move static checks are satisfied (this line is
        // not reached because the mint should abort with EInvalidName, but the
        // value must be used for the module to type-check).
        transfer::public_transfer(nft_obj, USER1);
        ts::return_shared(registry);
    };

    ts::end(scenario);
}
