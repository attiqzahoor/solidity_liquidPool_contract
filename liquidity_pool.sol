// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LiquidityPool is Ownable {
    IERC20 public wbtcToken;
    IERC20 public runeToken;

    uint256 public totalLiquidityWBTC;
    uint256 public totalLiquidityRUNE;

    mapping(address => uint256) public liquidityWBTC;
    mapping(address => uint256) public liquidityRUNE;

    event LiquidityProvided(
        address indexed provider,
        uint256 amountWBTC,
        uint256 amountRUNE
    );
    event LiquidityRemoved(
        address indexed provider,
        uint256 amountWBTC,
        uint256 amountRUNE
    );
    event Swapped(
        address indexed swapper,
        uint256 amountIn,
        uint256 amountOut,
        bool isWBTCtoRUNE
    );

    constructor(address _wbtcToken, address _runeToken) Ownable(_msgSender()) {
        wbtcToken = IERC20(_wbtcToken);
        runeToken = IERC20(_runeToken);
    }

    function provideLiquidity(uint256 amountWBTC, uint256 amountRUNE) external {
        require(
            amountWBTC > 0 && amountRUNE > 0,
            "Amounts must be greater than zero"
        );
        require(
            (totalLiquidityWBTC == 0 && totalLiquidityRUNE == 0) ||
                (amountWBTC * totalLiquidityRUNE ==
                    amountRUNE * totalLiquidityWBTC),
            "Must provide liquidity in equal value"
        );

        require(
            wbtcToken.transferFrom(msg.sender, address(this), amountWBTC),
            "WBTC transfer failed"
        );
        require(
            runeToken.transferFrom(msg.sender, address(this), amountRUNE),
            "RUNE transfer failed"
        );

        liquidityWBTC[msg.sender] += amountWBTC;
        liquidityRUNE[msg.sender] += amountRUNE;

        totalLiquidityWBTC += amountWBTC;
        totalLiquidityRUNE += amountRUNE;

        emit LiquidityProvided(msg.sender, amountWBTC, amountRUNE);
    }

    function removeLiquidity(uint256 amountWBTC, uint256 amountRUNE) external {
        require(
            amountWBTC > 0 && amountRUNE > 0,
            "Amounts must be greater than zero"
        ); // Added line
        require(
            (totalLiquidityWBTC == 0 && totalLiquidityRUNE == 0) ||
                (amountWBTC * totalLiquidityRUNE ==
                    amountRUNE * totalLiquidityWBTC),
            "Must remove liquidity in equal value"
        ); // Added lines

        require(
            liquidityWBTC[msg.sender] >= amountWBTC,
            "Insufficient WBTC liquidity"
        );
        require(
            liquidityRUNE[msg.sender] >= amountRUNE,
            "Insufficient RUNE liquidity"
        );

        liquidityWBTC[msg.sender] -= amountWBTC;
        liquidityRUNE[msg.sender] -= amountRUNE;

        totalLiquidityWBTC -= amountWBTC;
        totalLiquidityRUNE -= amountRUNE;

        require(
            wbtcToken.transfer(msg.sender, amountWBTC),
            "WBTC transfer failed"
        );
        require(
            runeToken.transfer(msg.sender, amountRUNE),
            "RUNE transfer failed"
        );

        emit LiquidityRemoved(msg.sender, amountWBTC, amountRUNE);
    }

    function swapWBTCtoRUNE(uint256 amountWBTC) external {
        require(
            wbtcToken.transferFrom(msg.sender, address(this), amountWBTC),
            "WBTC transfer failed"
        );
        uint256 amountRUNE = getSwapAmount(
            amountWBTC,
            totalLiquidityWBTC,
            totalLiquidityRUNE
        );
        require(
            runeToken.transfer(msg.sender, amountRUNE),
            "RUNE transfer failed"
        );

        totalLiquidityWBTC += amountWBTC;
        totalLiquidityRUNE -= amountRUNE;

        emit Swapped(msg.sender, amountWBTC, amountRUNE, true);
    }

    function swapRUNEtoWBTC(uint256 amountRUNE) external {
        require(
            runeToken.transferFrom(msg.sender, address(this), amountRUNE),
            "RUNE transfer failed"
        );
        uint256 amountWBTC = getSwapAmount(
            amountRUNE,
            totalLiquidityRUNE,
            totalLiquidityWBTC
        );
        require(
            wbtcToken.transfer(msg.sender, amountWBTC),
            "WBTC transfer failed"
        );

        totalLiquidityRUNE += amountRUNE;
        totalLiquidityWBTC -= amountWBTC;

        emit Swapped(msg.sender, amountRUNE, amountWBTC, false);
    }

    function getSwapAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        uint256 inputAmountWithFee = inputAmount * 997; // Assuming a 0.3% fee
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 1000) + inputAmountWithFee;
        return numerator / denominator;
    }
}
