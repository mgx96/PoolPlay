// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Math, WAD} from "../lib/Math.sol";
import {ICDPEngine} from "../interfaces/ICDPEngine.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {Auth} from "../lib/Auth.sol";
import {ICOllateralAuction} from "../interfaces/ICollateralAuctoin.sol";
import {IDSEngine} from "../interfaces/IDSEngine.sol";

//dog it hadles call cliiper fpr auction

contract Liquidationengine is CircuitBreaker, Auth {
    error Liquidationengine_NotUnSage();
    error Liquidationengine_LiquidationLimit();
    error Liquidationengine_MathOverFlow();
    error Liquidationengine_NullAuction();
    error DustyActionFromPartialLiquidation();

    IDSEngine public dsEngine;
    ICDPEngine public cdpEngine;
    ICOllateralAuction public collateralAuction;

    struct Collateral {
        // clip - auction addresss
        address auction;
        //chop - penaleey - liquidation penalty
        uint256 penalty;
        //whole - max coin (inrc) need to cover debt + fee of currently live auction [rad]
        uint256 maxAmount;
        // dirt - amount of inrc coin needed to cover debt + fee of currently live auctoin [rad]
        uint256 coinAmount;
    }

    //  totoal oamout of coin needed to cover debt + fee of active auctoin
    uint256 public totalCoin;
    // max dai token need to cover
    uint256 public maxCoin;
    // this run when user liquidated

    event Liquidate(
        bytes32 indexed colType,
        address indexed cdp,
        uint256 deltaColl,
        uint256 deltaDebt,
        uint256 due,
        address auction,
        uint256 indexed id
    );

    mapping(bytes32 => Collateral) public collaterals;

    event Remove(bytes32 indexed colType, uint256 rad);

    constructor(address _cdpEngine) {
        cdpEngine = ICDPEngine(_cdpEngine);
    }

    function penalty(bytes32 _colType) external view returns (uint256) {
        return collaterals[_colType].penalty;
    }

    //the liquidate function
    function liquidate(
        bytes32 _colType,
        address _cdp,
        // te user called for liquidate and gonna pay his debt
        address _keeper
    ) external auth notStopped returns (uint256 id) {
        // ink - collatral
        // art - debt
        ICDPEngine.Position memory pos = cdpEngine.positions(_colType, _cdp);
        // rate , spot , dust
        ICDPEngine.Collateral memory col = cdpEngine.collaterals(_colType);

        Collateral memory collateral = collaterals[_colType];
        uint256 deltaDebt;

        {
            //first it verify is collateral active or not then it verify the caollateral is in condition of liquiudation or not
            if (col.spot < 0 || pos.collateral * col.spot > pos.debt * col.accRate) {
                revert Liquidationengine_NotUnSage();
            }
            if (maxCoin <= totalCoin || collateral.maxAmount <= collateral.coinAmount) {
                revert Liquidationengine_LiquidationLimit();
            }

            // how much minting space is left before hitting system limits.o this line ensures the liquidation doesn’t mint too much DAI beyond allowed limits.
            //room
            uint256 room = Math.min(maxCoin - totalCoin, collateral.maxAmount - collateral.maxAmount);

            // hte amount of debt actually to raise from auction
            deltaDebt = Math.min(pos.debt, (room * WAD) / col.accRate / collateral.penalty);
            // not to liquidate if there is dust mean veery few amount left that cost hign and gives 0 profit
            if (pos.debt > deltaDebt) {
                if ((pos.debt - deltaDebt) * col.accRate < col.minDebt) {
                    deltaDebt = pos.debt;
                } else {
                    if (deltaDebt * col.accRate < col.minDebt) {
                        revert DustyActionFromPartialLiquidation();
                    }
                }
            }
            // It’s how the system figures out how much collateral to seize when you’re only liquidating part of someone’s position.
        }
        // it calculates the proportional amount of collateral to seize for the part of the debt being cleared
        uint256 deltaCol = (pos.collateral * deltaDebt) / pos.debt;

        if (deltaCol < 0) revert Liquidationengine_NullAuction();
        if (deltaCol > 2 ** 255 - 1 && deltaDebt > 2 ** 255 - 1) {
            revert Liquidationengine_MathOverFlow();
        }

        // This is like the internal accounting hack. It’s just adjusting balances:
        // _collateral and _deltaDebt are negative because you’re taking them out of the CDP
        cdpEngine.grab({
            _colType: _colType,
            _cdp: _cdp,
            _victim: collateral.auction,
            _liquidator: address(dsEngine),
            _collateral: -int256(deltaCol),
            _deltaDebt: -int256(deltaDebt)
        });
        //  Now we’re looking at how much the liquidator actually has to pay.
        // deltaDebt is the raw debt amount; multiplying by accRate accounts for interest accumulated over time.
        // This is the number that the system expects to recover in stablecoin, i.e., the actual “due”
        uint256 due = deltaDebt * col.accRate;
        dsEngine.pushDebtToQueue(due);
        // nnow as protocol will apply penalty to on that debt to recover incentives so
        {
            uint256 targetCoinAmount = (due * collateral.penalty) / WAD;
            totalCoin += targetCoinAmount;
            collaterals[_colType].coinAmount += targetCoinAmount;
            // Now we’re launching the auction to liquidate the collateral:
            // collAmount → amount of collateral being sold.
            // inrcAmount → how much stablecoin the bidder has to pay, including the liquidation penalty.
            // Notice inrcAmount != deltaDebt because of that penalty the protocol adds to incentivize liquidators.
            id = ICOllateralAuction(collateral.auction).start({
                inrcAmount: targetCoinAmount,
                collAmount: deltaCol,
                user: _cdp,
                keeper: _keeper
            });
        }
        emit Liquidate(_colType, _cdp, deltaCol, deltaDebt, due, collateral.auction, id);
    }

    //dig:, this removes cin from auction
    function removeCoinFromAuction(bytes32 _colType, uint256 rad) external auth {
        totalCoin -= rad;
        collaterals[_colType].coinAmount -= rad;
        emit Remove(_colType, rad);
    }
}
