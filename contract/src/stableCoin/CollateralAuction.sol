// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {Math} from "../lib/Math.sol";
import {ISpotter} from "../interfaces/ISpotter.sol";
import {IPriceFeed} from "../interfaces/IPriceFeed.sol";
import {ICollateralAuctionCallee} from "../interfaces/ICollateralAuctionCallee.sol";
import {ICDPEngine} from "../interfaces/ICDPEngine.sol";
import {ICollateralCalc} from "../interfaces/ICollateralCalc.sol";
import {ILiquidationengine} from "../interfaces/ILiquidationengine.sol";

contract collateralAuction is Auth {
    error collateralAuction_InValidinrcAmount();
    error collateralAuction_Stopped();
    error collateralAuction_InValidcollAmount();
    error collateralAuction_InValidStartingPRice();
    error collateralAuction_CannotRestart();
    error collateralAuction_InValidCdpAddress();

    bytes32 public immutable collateralType;
    //vat
    ICDPEngine public immutable cdpEngine;
    // after auction dine
    ICollateralAuctionCallee public collateralAucSuccess;
    // colc calculator
    ICollateralCalc public collaCalc;
    //spooter
    ISpotter public spotter; // collateral priceModule
    // debt and surplus engine
    address public dsEngine;
    // liquidation eninge
    ILiquidationengine public liquidationEngine;

    uint256 public boost; // multiplicative factor to ncrease strting price
    uint256 public maxDuration; // the maximum duration for an auctoin
    uint256 public minDeltaPriceRatio; // percentage drop before auction reset
    uint64 public feeRate; //  the amount issued to calleer as an incentive suck from wow
    uint192 public flatFee;
    ///flat fee tp suck from wow to incentice keepres
    // chost caches the product of dust (minimum vault debt) and chop (liquidation penalty) for an ilk to optimize gas by reducing storage reads during auctions.
    uint256 public minCoin;
    uint256 public lastAuctionId; //aka total auction tiil yet
    uint256[] public active;
    /// the auction id of active auctions

    struct Bid {
        uint256 id; // index of auctoin
        uint256 inrcAmount; // amount of token to raise
        uint256 collAmount; // amount Of Collateral To raise;
        uint96 startTime; // the time auciton started
        address liquidated; // the addrss of liquidated CDP
        uint256 startingPrice; // starting price for Auctin
    }

    mapping(uint256 => Bid) public bids;

    // Levels for circuit breaker
    // 0: no breaker
    // 1: no new kick()
    // 2: no new kick() or redo()
    // 3: no new kick(), redo(), or take()
    uint256 public stopped = 0;

    modifier isStopped(uint256 level) {
        if (stopped == level) revert collateralAuction_Stopped();
        _;
    }

    event Start(
        uint256 indexed id,
        uint256 starting_price,
        uint256 coin_amount,
        uint256 collateral_amount,
        address indexed user,
        address indexed keeper,
        uint256 fee
    );
    event Take(
        uint256 indexed id,
        uint256 max_collateral,
        uint256 price,
        uint256 owe,
        uint256 coin_amount,
        uint256 collateral_amount,
        address indexed user
    );
    event Redo(
        uint256 indexed id,
        uint256 starting_price,
        uint256 coin_amount,
        uint256 collateral_amount,
        address indexed user,
        address indexed keeper,
        uint256 fee
    );
    //this is kick funciton mean to kickstaart the auction

    function start(uint256 inrcAmount, uint256 collAmount, address cdo, address keeper)
        external
        auth
        isStopped(1)
        returns (uint256 id)
    {
        if (inrcAmount <= 0) revert collateralAuction_InValidinrcAmount();
        if (collAmount <= 0) revert collateralAuction_InValidcollAmount();
        if (address(0) == cdo) revert collateralAuction_InValidCdpAddress();
        id += lastAuctionId;
        active.push(id);
        bids[id].id = active.length - 1;
        bids[id].collAmount = collAmount;
        bids[id].inrcAmount = inrcAmount;
        bids[id].startTime = uint96(block.timestamp);
        bids[id].liquidated = cdo;

        // starting orice for auction
        uint256 startingPrice = Math.rmul(getPrice(), boost);
        if (startingPrice <= 0) revert collateralAuction_InValidStartingPRice();
        bids[id].startingPrice = startingPrice;
        uint256 fee; // incentive fee
        if (feeRate > 0 || flatFee > 0) {
            fee = flatFee + Math.wmul(inrcAmount, feeRate);
            cdpEngine.mint({_debtDest: dsEngine, _coinDest: keeper, _rad: fee});
        }
        emit Start(id, startingPrice, inrcAmount, collAmount, cdo, keeper, fee);
    }
    // this is for restarting every functions

    function redo(uint256 id, address keeper) external auth isStopped(2) {
        uint256 startingprice = bids[id].startingPrice;
        address user = bids[id].liquidated;
        uint256 sartingTime = bids[id].startTime;
        if (user == address(0)) revert collateralAuction_InValidCdpAddress();
        (bool done,) = status(sartingTime, startingprice);
        if (!done) revert collateralAuction_CannotRestart();
        uint256 coinAmout = bids[id].inrcAmount;
        uint256 collAmount = bids[id].collAmount;
        uint256 price = getPrice();
        startingprice = Math.rmul(price, boost);
        bids[id].startTime = uint96(block.timestamp);
        if (startingprice <= 0) revert collateralAuction_InValidStartingPRice();
        bids[id].startingPrice = startingprice;

        uint256 fee;
        if (flatFee > 0 || feeRate > 0) {
            if (coinAmout >= minCoin && collAmount * price >= minCoin) {
                fee = flatFee + Math.rmul(coinAmout, feeRate);
                cdpEngine.mint(dsEngine, keeper, fee);
            }
        }
        emit Redo(id, startingprice, coinAmout, collAmount, user, keeper, fee);
    }

    function take(
        // id - Auction id
        uint256 id,
        // amt [wad] - Upper limit on amount of collateral to buy
        uint256 max_collateral,
        // max [ray] - Maximum acceptable price (BEI / collateral)
        uint256 max_price,
        // who - Receiver of collateral and external call address
        address receiver,
        // Data to pass in external call; if length 0, no call is done
        bytes calldata data
    ) external isStopped(3) {
        Bid storage sale = bids[id];
        address user = sale.liquidated;
        uint96 startTime = sale.startTime;

        require(user != address(0), "not running auction");

        uint256 price;
        {
            bool done;
            (done, price) = status(startTime, sale.startingPrice);
            // Check that auction doesn't need reset
            require(!done, "needs reset");
        }

        // Ensure price is acceptable to buyer
        require(max_price >= price, "price > max");

        uint256 collateral_amount = sale.collAmount;
        uint256 coin_amount = sale.inrcAmount;
        // BEI needed to buy a slice of this sale
        uint256 owe;
        {
            // Purchase as much as possible, up to max_collateral
            // slice <= collateral_amount
            uint256 slice = Math.min(collateral_amount, max_collateral);

            // BEI needed to buy a slice of this sale
            // rad = wad * ray
            // owe = amount collateral * BEI / collateral
            owe = slice * price;

            // owe > coin amount                         -> set own = coin amount and recalculate slice
            // owe < coin amount && slice < col amount -> ?
            // Don't collect more than coin_amount of BEI
            if (owe > coin_amount) {
                // Total debt will be paid
                // owe' <= owe
                owe = coin_amount;
                // Adjust slice
                // slice' = owe' / price <= owe / price = slice <= collateral_amount
                // wad = rad / ray
                slice = owe / price;
            } else if (owe < coin_amount && slice < collateral_amount) {
                // If owe = coin amount or slice = collateral_amount -> auction completed -> dust doesn't matter
                if (coin_amount - owe < minCoin) {
                    // safe as owe < coin_amount
                    // If coin_amount <= minCoin, buyers have to take the entire collateral_amount.
                    require(coin_amount > minCoin, "no partial purchase");
                    // Adjust amount to pay
                    // coin amount - min coin < owe
                    owe = coin_amount - minCoin;
                    // Adjust slice
                    // slice' = owe' / price < owe / price == slice < collateral_amount
                    slice = owe / price;
                }
            }

            // Calculate remaining coin_amount after operation
            // safe since owe <= coin_amount
            coin_amount -= owe;
            // Calculate remaining collateral_amount after operation
            collateral_amount -= slice;

            // Send collateral to receiver
            cdpEngine.transferCollateral(collateralType, address(this), receiver, slice);

            // Do external call (if data is defined) but to be
            // extremely careful we don't allow to do it to the two
            // contracts which the Clipper needs to be authorized
            if (data.length > 0 && receiver != address(cdpEngine) && receiver != address(liquidationEngine)) {
                ICollateralAuctionCallee(receiver).callback(msg.sender, owe, slice, data);
            }

            // Get BEI from caller
            cdpEngine.transferInrc(msg.sender, dsEngine, owe);

            // Removes BEI out for liquidation from accumulator
            liquidationEngine.removeCoinFromAuction(collateralType, collateral_amount == 0 ? coin_amount + owe : owe);
        }

        if (collateral_amount == 0) {
            _remove(id);
        } else if (coin_amount == 0) {
            cdpEngine.transferCollateral(collateralType, address(this), user, collateral_amount);
            _remove(id);
        } else {
            sale.inrcAmount = coin_amount;
            sale.collAmount = collateral_amount;
        }

        emit Take(id, max_collateral, price, owe, coin_amount, collateral_amount, user);
    }

    function _remove(uint256 id) internal {
        uint256 last = active[active.length - 1];
        if (id != last) {
            uint256 index = bids[id].id;
            active[index] = last;
            bids[last].id = index;
        }
        active.pop();
        delete bids[id];
    }

    //this for getting the price direct from priceOracle
    function getPrice() internal returns (uint256 price) {
        ISpotter.Collateral memory col = spotter.collaterals(collateralType);
        (uint256 val, bool isOk) = IPriceFeed(col.priceFeed).peek();
        if (!isOk) revert IPriceFeed.PriceFeed_InvalidPrice();
        price = Math.rdiv(val * 1e9, spotter.par());
    }

    //returns boolean specifiy the function needs redo or not the auction will finish if time ends or it's value goes below the minimum value
    function status(uint256 _startingTime, uint256 startingValue) internal view returns (bool done, uint256 price) {
        price = collaCalc.price(startingValue, block.timestamp - _startingTime);
        // here the ratio of currentPrice/ startinPrice and how far it's gone it it crosses the limit then it has to stop
        done = block.timestamp - _startingTime > maxDuration || Math.rdiv(price, _startingTime) < minDeltaPriceRatio;
    }
    // this function updates the minum value must be for auctions by multiipling the minimun debt of collateral to the system penalty

    function updateMinCoin() external {
        ICDPEngine.Collateral memory colla = ICDPEngine(cdpEngine).collaterals(collateralType);
        minCoin = Math.wmul(colla.minDebt, liquidationEngine.penalty(collateralType));
    }
}
