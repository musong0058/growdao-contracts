// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "../ERC20/ERC20.sol";
import "../ERC20/ERC20Burnable.sol";
import "../../access/Ownable.sol";

contract GROWToken is ERC20, ERC20Burnable, Ownable {
    address public swapRouter;
    address public lpToken;
    address public admin;
    bool public buyLocked = true;

    constructor(address _swapRouter, address _mintTo) ERC20("GROW DAO Token", "GROW") {
        swapRouter = _swapRouter;
        _mint(_mintTo, 1_000_000 * 10 ** decimals());
    }

    function setAdmin(address _admin) external onlyOwner {
        require(admin == address(0), "Admin already configured");
        admin = _admin;
    }

    function setSwapRouter(address _swapRouter) external onlyOwner {
        require(swapRouter == address(0), "Dex router already configured");
        swapRouter = _swapRouter;
    }

    function setLPToken(address _lpToken) external onlyOwner {
        require(lpToken == address(0), "LP token already configured");
        lpToken = _lpToken;
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == admin, "Mint: only admin can mint tokens");
        _mint(to, amount);
    }

    function unlockBuy() external onlyOwner {
        if (buyLocked) {
            buyLocked = false;
        }
    }

    function lockBuy() external onlyOwner {
        if (!buyLocked) {
            buyLocked = true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal view override {
        if (lpToken == address(0) || !buyLocked) {
            return;
        }

        if (from == lpToken || from == swapRouter) {
            require(
                to == admin
                || to == swapRouter
                || to == lpToken
                || to == address(0),
                "Transfer: only admin can buy tokens"
            );
        }
    }
}