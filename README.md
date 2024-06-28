# Yield Farming Module

This module defines a simple yield farming mechanism in Rust, designed to be used with the `sui` crate. The module allows users to create farms, stake funds, claim yields, and withdraw funds.

## Table of Contents
1. [Overview](#overview)
2. [Structure Definitions](#structure-definitions)
    - [Farm](#farm)
    - [Staker](#staker)
3. [Error Codes](#error-codes)
4. [Functions](#functions)
    - [create_farm](#create_farm)
    - [stake_funds](#stake_funds)
    - [claim_yield](#claim_yield)
    - [get_farm_balance](#get_farm_balance)
    - [get_staker_balance](#get_staker_balance)
    - [withdraw_funds](#withdraw_funds)

## Overview
The `yield_farming` module allows users to participate in yield farming by staking their funds into a farm, earning yields over time based on the farm's annual yield rate, and withdrawing their funds along with the earned yield. The module includes functionalities to create farms, manage stakers, calculate yields, and perform transfers.

## Structure Definitions

### Farm
The `Farm` structure represents a farm where users can stake their funds. It includes the following fields:
- `id: UID`: Unique identifier for the farm.
- `name: String`: Name of the farm.
- `balance: Balance<SUI>`: Current balance of the farm in `SUI`.
- `stakers: Table<ID, Staker>`: Table storing staker information (ID to `Staker` mapping).
- `farm: address`: Address of the farm contract.
- `yield_rate: u64`: Annual yield rate for the farm.

### Staker
The `Staker` structure represents a user who has staked funds in a farm. It includes the following fields:
- `id: UID`: Unique identifier for the staker.
- `staker: address`: Address of the staker.
- `balance: Balance<SUI>`: Balance of funds staked by the staker in `SUI`.
- `stake_time: u64`: Timestamp when the staker made the deposit.
- `yield_claimed: u64`: Total amount of yield claimed by the staker.

## Error Codes
The module defines several error codes for different scenarios:
- `EInsufficientFunds: u64 = 1`: Error code for insufficient funds.
- `EInvalidCoin: u64 = 2`: Error code for invalid coin type.
- `ENotStaker: u64 = 3`: Error code for caller not being a staker.
- `EInvalidFarm: u64 = 4`: Error code for invalid farm operation.
- `EInvalidYieldClaim: u64 = 5`: Error code for invalid yield claim operation.

## Functions

### create_farm
Creates a new farm with the specified name and annual yield rate.

**Parameters:**
- `ctx: &mut TxContext`: Mutable reference to the transaction context.
- `name: String`: Name of the farm.
- `yield_rate: u64`: Annual yield rate for the farm.

### stake_funds
Stakes funds into a specified farm.

**Parameters:**
- `farm: &mut Farm`: Mutable reference to the farm where funds are being staked.
- `amount: Coin<SUI>`: Amount of funds (in `SUI` coins) to be staked.
- `ctx: &mut TxContext`: Mutable reference to the transaction context.
- `clock: &Clock`: Reference to the clock for timestamping.

### claim_yield
Claims the yield for a staker from a specified farm.

**Parameters:**
- `farm: &mut Farm`: Mutable reference to the farm from which yields are claimed.
- `staker: &mut Staker`: Mutable reference to the staker claiming yields.
- `ctx: &mut TxContext`: Mutable reference to the transaction context.
- `clock: &Clock`: Reference to the clock for timestamping.

### get_farm_balance
Gets the balance of a specified farm.

**Parameters:**
- `farm: &Farm`: Reference to the farm.

**Returns:**
- `&Balance<SUI>`: Reference to the farm's balance.

### get_staker_balance
Gets the balance of a specified staker.

**Parameters:**
- `staker: &Staker`: Reference to the staker.

**Returns:**
- `&Balance<SUI>`: Reference to the staker's balance.

### withdraw_funds
Withdraws funds from a specified farm for a specified staker.

**Parameters:**
- `farm: &mut Farm`: Mutable reference to the farm from which funds are withdrawn.
- `staker: &mut Staker`: Mutable reference to the staker withdrawing funds.
- `amount: u64`: Amount of funds to withdraw.
- `ctx: &mut TxContext`: Mutable reference to the transaction context.

---
