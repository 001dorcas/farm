#[allow(unused_use)]

// Define the module named `yield_farming` under the crate `yield_farming`.
module yield_farming::yield_farming {

    // Import necessary modules and symbols from the `sui` crate.
    use sui::transfer;                               // Import transfer functions from `sui`.
    use sui::sui::SUI;                               // Import the `SUI` type from `sui`.
    use std::string::{Self, String};                 // Import `String` type from standard library for string manipulation.
    use sui::coin::{Self, Coin};                     // Import `Coin` type and functions from `sui::coin`.
    use sui::clock::{Self, Clock};                   // Import `Clock` type and functions from `sui::clock`.
    use sui::object::{Self, UID, ID};                // Import `UID`, `ID`, and object-related functions from `sui::object`.
    use sui::balance::{Self, Balance};               // Import `Balance` type and functions from `sui::balance`.
    use sui::tx_context::{Self, TxContext};          // Import `TxContext` type and functions from `sui::tx_context`.
    use sui::table::{Self, Table};                   // Import `Table` type and functions from `sui::table`.

    // Define error constants for different error scenarios.
    const EInsufficientFunds: u64 = 1;               // Error code for insufficient funds.
    const EInvalidCoin: u64 = 2;                      // Error code for invalid coin type.
    const ENotStaker: u64 = 3;                       // Error code for caller not being a staker.
    const EInvalidFarm: u64 = 4;                     // Error code for invalid farm operation.
    const EInvalidYieldClaim: u64 = 5;               // Error code for invalid yield claim operation.

    // Define a structure `Farm` with a primary key.
    struct Farm has key {
        id: UID,                                     // Unique identifier for the farm.
        name: String,                                // Name of the farm.
        balance: Balance<SUI>,                       // Current balance of the farm in `SUI`.
        stakers: Table<ID, Staker>,                  // Table storing staker information (ID to `Staker` mapping).
        farm: address,                               // Address of the farm contract.
        yield_rate: u64                              // Annual yield rate for the farm.
    }

    // Define a structure `Staker` with a primary key.
    struct Staker has key {
        id: UID,                                     // Unique identifier for the staker.
        staker: address,                             // Address of the staker.
        balance: Balance<SUI>,                       // Balance of funds staked by the staker in `SUI`.
        stake_time: u64,                             // Timestamp when the staker made the deposit.
        yield_claimed: u64                           // Total amount of yield claimed by the staker.
    }

    // Function to create a new farm.
    public fun create_farm(ctx:&mut TxContext, name: String, yield_rate: u64) {
        // Create a new `Farm` object with the given parameters.
        let farm = Farm {
            id: object::new(ctx),                     // Assign a new unique identifier to the farm.
            name: name,                               // Set the name of the farm.
            balance: balance::zero<SUI>(),            // Initialize the farm's balance to zero.
            stakers: table::new<ID, Staker>(ctx),     // Create a new table to store stakers associated with this farm.
            farm: tx_context::sender(ctx),            // Set the farm's address to the sender's address.
            yield_rate: yield_rate                    // Set the annual yield rate for the farm.
        };

        // Share the `Farm` object with other components.
        transfer::share_object(farm);
    }

    // Function to stake funds into a farm.
    public fun stake_funds(
        farm: &mut Farm,                             // Mutable reference to the farm where funds are being staked.
        amount: Coin<SUI>,                           // Amount of funds (in `SUI` coins) to be staked.
        ctx: &mut TxContext,                         // Mutable reference to the transaction context.
        clock: &Clock                               // Reference to the clock for timestamping.
    ) {
        // Assert that the caller is the farm itself.
        assert!(farm.farm == tx_context::sender(ctx), ENotStaker);

        // Get the address of the staker (sender of the transaction).
        let staker_address = tx_context::sender(ctx);

        // Get the current timestamp.
        let stake_time = clock::timestamp_ms(clock);

        // Check if the staker already exists in the farm's stakers table.
        let staker = if (table::contains<ID, Staker>(&farm.stakers, object::id_from_address(staker_address))) {
            // If the staker already exists, borrow mutable reference to the existing staker.
            let mut existing_staker = table::borrow_mut<ID, Staker>(&farm.stakers, object::id_from_address(staker_address));
            // Add the staked amount to the existing staker's balance.
            balance::join(&mut existing_staker.balance, coin::into_balance(amount));
            existing_staker                            // Return the existing staker.
        } else {
            // If the staker does not exist, create a new staker.
            let new_staker = Staker {
                id: object::new(ctx),                  // Assign a new unique identifier to the staker.
                staker: staker_address,                // Set the staker's address.
                balance: coin::into_balance(amount),   // Initialize the staker's balance with the staked amount.
                stake_time: stake_time,                // Set the stake time.
                yield_claimed: 0                       // Initialize yield claimed to zero.
            };
            // Add the new staker to the farm's stakers table.
            table::add<ID, Staker>(&mut farm.stakers, object::id_from_address(staker_address), new_staker);
            new_staker                                 // Return the new staker.
        };

        // Share the `Staker` object with other components.
        transfer::share_object(staker);
    }

    // Function to claim yields for a staker from a farm.
    public fun claim_yield(
        farm: &mut Farm,                             // Mutable reference to the farm from which yields are claimed.
        staker: &mut Staker,                         // Mutable reference to the staker claiming yields.
        ctx: &mut TxContext,                         // Mutable reference to the transaction context.
        clock: &Clock                               // Reference to the clock for timestamping.
    ) {
        // Assert that the caller is the staker.
        assert!(staker.staker == tx_context::sender(ctx), ENotStaker);

        // Get the current timestamp.
        let current_time = clock::timestamp_ms(clock);

        // Calculate the duration for which the staker has staked funds.
        let stake_duration = current_time - staker.stake_time;

        // Calculate the yield amount based on the staker's balance, farm's yield rate, and stake duration.
        let yield_amount = (balance::value(&staker.balance) * farm.yield_rate * stake_duration) / (100 * 365 * 24 * 60 * 60 * 1000); // Yield calculation based on annual percentage rate

        // Mint new `SUI` coins as yield.
        let yield_coin = coin::mint<SUI>(yield_amount, ctx);

        // Add the yield amount to the staker's balance.
        balance::join(&mut staker.balance, coin::into_balance(yield_coin));

        // Update the staker's yield claimed amount.
        staker.yield_claimed += yield_amount;

        // Add the yield amount to the farm's balance.
        balance::join(&mut farm.balance, coin::into_balance(yield_coin));
    }

    // Function to get the balance of a farm.
    public fun get_farm_balance(farm: &Farm): &Balance<SUI> {
        // Return a reference to the farm's balance.
        &farm.balance
    }

    // Function to get the balance of a staker.
    public fun get_staker_balance(staker: &Staker): &Balance<SUI> {
        // Return a reference to the staker's balance.
        &staker.balance
    }

    // Function to withdraw funds from a farm.
    public fun withdraw_funds(
        farm: &mut Farm,                             // Mutable reference to the farm from which funds are withdrawn.
        staker: &mut Staker,                         // Mutable reference to the staker withdrawing funds.
        amount: u64,                                 // Amount of funds to withdraw.
        ctx: &mut TxContext                          // Mutable reference to the transaction context.
    ) {
        // Assert that the caller is the staker.
        assert!(staker.staker == tx_context::sender(ctx), ENotStaker);

        // Assert that the staker has sufficient funds to withdraw.
        assert!(amount <= balance::value(&staker.balance), EInsufficientFunds);

        // Take the specified amount from the staker's balance.
        let amount_to_withdraw = coin::take(&mut staker.balance, amount, ctx);

        // Perform a public transfer of the withdrawn amount to the staker's address.
        transfer::public_transfer(amount_to_withdraw, staker.staker);
    }
}
