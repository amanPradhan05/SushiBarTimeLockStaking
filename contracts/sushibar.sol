// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

// SushiBar is the coolest bar in town. You come in with some Sushi, and leave with more! The longer you stay, the more Sushi you get.
//
// This contract handles swapping to and from xSushi, SushiSwap's staking token.
contract SushiBar is ERC20("SushiBar", "xSUSHI") {
    using SafeMath for uint256;
    IERC20 public sushi;
    uint time;
    uint256 what; //what will help in get xsushi of the owner.

    // Define the Sushi token contract
    constructor(IERC20 _sushi) public {
        sushi = _sushi;
    }

    // Enter the bar. Pay some SUSHIs. Earn some shares.
    // Locks Sushi and mints xSushi
    function enter(uint256 _amount) public {
        // Gets the amount of Sushi locked in the contract
        uint256 totalSushi = sushi.balanceOf(address(this));
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply();
        // If no xSushi exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalSushi == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xSushi the Sushi is worth. The ratio will change overtime, as xSushi is burned/minted and Sushi deposited + gained from fees / withdrawn.
        else {
            what = _amount.mul(totalShares).div(totalSushi);

            _mint(msg.sender, what);
        }
        // Lock the Sushi in the contract

        sushi.transferFrom(msg.sender, address(this), _amount);

        time = block.timestamp + 2 days; //getting block time stamp
    }

    // Leave the bar. Claim back your SUSHIs.
    // Unlocks the staked + gained Sushi and burns xSushi
    function leave(uint256 _share) public {
        require(block.timestamp >= time, "your sushi locked now"); //can not unlock the sushi before 2 days
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply();
        //this code will unlock the 20% suhsi
        if (block.timestamp >= time && block.timestamp < time + 2 days) {
            uint amount = (what).div(5);
            require(_share <= amount, "can not take out more then 20%");
            uint256 unstaked = _share.mul(sushi.balanceOf(address(this))).div(
                totalShares
            );
            what = what - amount;
            _burn(msg.sender, _share);
            sushi.transfer(msg.sender, unstaked);
        }
        //this code will unlock the 50% suhsi
        else if (
            block.timestamp >= time + 2 days && block.timestamp < time + 4 days
        ) {
            uint amount = (what).div(2);
            require(_share <= amount, "can not take out more then 50%");
            uint256 unstaked = _share.mul(sushi.balanceOf(address(this))).div(
                totalShares
            );
            _burn(msg.sender, _share);
            sushi.transfer(msg.sender, unstaked);
        }
        //75% unstaked
        else if (
            block.timestamp >= time + 4 days && block.timestamp < time + 6 days
        ) {
            uint amount = ((what).div(4)).mul(3);
            require(_share <= amount, "can not take out more then 75%");
            uint256 unstaked = _share.mul(sushi.balanceOf(address(this))).div(
                totalShares
            );
            _burn(msg.sender, _share);
            sushi.transfer(msg.sender, unstaked);
        }
        //all amount can be unstacked
        else {
            uint256 unstaked = _share.mul(sushi.balanceOf(address(this))).div(
                totalShares
            );
            _burn(msg.sender, _share);
            sushi.transfer(msg.sender, unstaked);
        }
    }
}
