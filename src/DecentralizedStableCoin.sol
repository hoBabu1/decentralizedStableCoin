//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
/**
 * @title DecentralizedStableCoin
 * @author hoBabu aka Aman Kumar
 * Relative Stability: Pegged to USD
 * Minting: Algorithmic(Decentralized)
 * Colletral: Exogenous(ETH , wBTC)
 */

contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    /* Errors */

    /* If User Wants to Burn zero Token */
    error DecentralizedStableCoin__BurnMoreThanZero();

    /* If user Balance is Less than Buring Amount */
    error DecentralizedStableCoin__BalanceIsLessThanBurnAmount();

    /* If minting address is 0 */
    error DecentralizedStableCoin__InvalidAddress();

    /* If minting amount is 0 */
    error DecentralizedStableCoin__MintingAmountShouldBeGreaterThanZero();

    /* Constructor */
    constructor() ERC20("hoBabu", "hB") Ownable(msg.sender) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin__BurnMoreThanZero();
        }
        if (balance < _amount) {
            revert DecentralizedStableCoin__BalanceIsLessThanBurnAmount();
        }
        super.burn(_amount);
    }

    function mint(address to, uint256 value) external onlyOwner returns (bool) {
        if (to == address(0)) {
            revert DecentralizedStableCoin__InvalidAddress();
        }
        if (value <= 0) {
            revert DecentralizedStableCoin__MintingAmountShouldBeGreaterThanZero();
        }
        _mint(to, value);
        return true;
    }
}
