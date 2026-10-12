// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {MockUSDC} from "../../src/MockUSDC.sol";
import {SimpleStablecoin} from "../../src/SimpleStablecoin.sol";
import {Vault} from "../../src/Vault.sol";

/// @title Ex2 + Ex4 — decimal amounts, permissions and pausing
/// @notice Tests for the 1:1 loop, pause behavior, and the vault's broad burn permission.
contract LoopTasksTest is Test {
    MockUSDC internal usdc;
    SimpleStablecoin internal stable;
    Vault internal vault;

    address internal admin = address(this);
    address internal alice = makeAddr("alice");
    address internal attacker = makeAddr("attacker");

    function setUp() public {
        usdc = new MockUSDC();
        stable = new SimpleStablecoin(admin);
        vault = new Vault(usdc, stable);
        stable.grantRole(stable.MINTER_ROLE(), address(vault));
    }
    function _depositForAlice() internal {
        usdc.faucet(alice, 1000e6);

        vm.startPrank(alice);
        usdc.approve(address(vault), 1000e6);
        vault.deposit(1000e6);
        vm.stopPrank();
    }

    // ==================================================================
    // Ex2 · the decimals trap: a 6-decimal stablecoin meets 18-decimal intuition
    // ==================================================================

    /// @dev Each deposit must increase supply by the same amount in 6-decimal units.
    function test_Ex2_DepositIncreasesSupplyByExactly(uint96 raw) public {
        uint256 amount = uint256(raw) % 1_000_000e6;
        vm.assume(amount > 0);

        uint256 supplyBefore = stable.totalSupply();

        usdc.faucet(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(vault), amount);
        vault.deposit(amount);
        vm.stopPrank();

        assertEq(stable.totalSupply() - supplyBefore, amount);
        assertEq(stable.balanceOf(alice), amount);
        assertEq(vault.totalCollateral(), stable.totalSupply());
    }

    /// @dev With 6 decimals, 1000e18 means 10^15 USDC: 10^12 times the intended amount.
    function test_Ex2_DecimalsTrap() public {
        uint256 intendedAmount = 1000e6;
        uint256 wrongAmount = 1000e18;

        assertEq(usdc.decimals(), 6);
        assertEq(stable.decimals(), 6);

        usdc.faucet(alice, wrongAmount);

        vm.startPrank(alice);
        usdc.approve(address(vault), wrongAmount);
        vault.deposit(wrongAmount);
        vm.stopPrank();

        assertEq(stable.balanceOf(alice), wrongAmount);
        assertEq(stable.totalSupply(), wrongAmount);
        assertEq(vault.totalCollateral(), wrongAmount);

        assertEq(wrongAmount / intendedAmount, 1e12);
        assertEq(stable.balanceOf(alice) / 1e6, 1e15);
    }

    // ==================================================================
    // Ex4 · permissions and pausing: where the guard is, who holds the key
    // ==================================================================

    /// @dev The revert must identify the unauthorized attacker and the required role.
    function test_Ex4_Mint_RevertsForNonMinter() public {
        bytes32 role = stable.MINTER_ROLE();

        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(
                    keccak256(
                        "AccessControlUnauthorizedAccount(address,bytes32)"
                    )
                ),
                attacker,
                role
            )
        );

        vm.prank(attacker);
        stable.mint(attacker, 100e6);

        assertEq(stable.totalSupply(), 0);
    }

    /// @dev After pause(), an ordinary transfer must revert
    function test_Ex4_Pause_BlocksTransfers() public {
        _depositForAlice();
        stable.pause();

        vm.expectRevert(bytes4(keccak256("EnforcedPause()")));
        vm.prank(alice);
        stable.transfer(attacker, 100e6);

        assertEq(stable.balanceOf(alice), 1000e6);
        assertEq(stable.balanceOf(attacker), 0);
    }

    /// @dev Redemption burns tokens through _update, so pause blocks it too.
    function test_Ex4_Pause_BlocksRedeem() public {
        _depositForAlice();
        stable.pause();

        vm.expectRevert(bytes4(keccak256("EnforcedPause()")));
        vm.prank(alice);
        vault.redeem(100e6);

        assertEq(stable.balanceOf(alice), 1000e6);
        assertEq(stable.totalSupply(), 1000e6);
        assertEq(vault.totalCollateral(), 1000e6);
        assertEq(usdc.balanceOf(alice), 0);
    }

    /// @dev An attacker cannot burn someone else's balance
    function test_Ex4_AttackerCannotBurnOthersBalance() public {
        _depositForAlice();
        bytes32 role = stable.MINTER_ROLE();

        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(
                    keccak256(
                        "AccessControlUnauthorizedAccount(address,bytes32)"
                    )
                ),
                attacker,
                role
            )
        );

        vm.prank(attacker);
        stable.burn(alice, 100e6);

        assertEq(stable.balanceOf(alice), 1000e6);
        assertEq(stable.totalSupply(), 1000e6);
    }

    /// @dev Pranking Vault shows the token's permission; no public Vault call burns others' tokens.
    function test_Ex4_VaultHoldsTheKey_CanBurnAnyonesBalance() public {
        _depositForAlice();

        vm.prank(address(vault));
        stable.burn(alice, 100e6);

        assertEq(stable.balanceOf(alice), 900e6);
        assertEq(stable.totalSupply(), 900e6);
        assertEq(vault.totalCollateral(), 1000e6);
    }
}
