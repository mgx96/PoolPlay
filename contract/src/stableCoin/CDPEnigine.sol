// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {Math} from "../lib/Math.sol";

// in this whole contract the collateral type exist because MakerDao designed to handle more than one type of collateral type so an here are two main fucntion one for modifyCollateralBalance aka slip it only chages the balance they have but another transferInrc aka move it move from one wallet to anoth and these works CDPEngine internally
/// @title CDP Engine
/// @notice Handles user collateral balances and stablecoin (INRC) movements
//vat
contract CDPEngine is Auth, CircuitBreaker {
    error CDPEngine_NotAllowedToModifyAccount();
    error CDPEngine_NotAllowedToModifyAccountGemSource();
    error CDPEngine_KeyNotRecogNized(bytes32 key);
    error CDPEngine_NotSafe();
    error CDPEngine_CollateralAlreadyInit();
    error CDPEngine_CollateralNotInitialized();
    error CDPEngine_MinimunDebtExceeded();
    error CDPEngine_NotAllowedToModifyAccountINRCDest();
    error CDPEngine_MaxDebtExceeded();
    // ilk

    struct Collateral {
        // art = system’s “raw” debt before applying the accumulated rate
        // formula: art = d / rate
        // Think of it as base debt the veri first value
        uint256 debt;
        // accRate = accumulated rate over time for this collateral
        // It compounds the stability fee automatically
        uint256 accRate;
        // spot = adjusted collateral price used for max borrow calculations
        // Example: eth price = $2000, safeMargin = 0.2
        // spot = price * (1 - safeMargin) = 2000 * 0.8 = 1600
        // max borrow = spot * collateralAmount
        // If price drops to $1800 → max borrow = 1800 * 0.8 * 1 ETH = 1440 DAI
        // If below previous max borrow → liquidation can happen
        // it is in RAY daya typr
        uint256 spot;
        // maxDebt = the max DAI a user can borrow for this collateral
        // calculated using spot and collateral amount
        uint256 maxDebt;
        // minDebt = the minimum debt allowed (dust)
        // prevents liquidation from being unprofitable for liquidators
        uint256 minDebt;
    }

    // Urn aka CDP , or bolt (vault)
    struct Position {
        //  the colateral lockefd = ilk
        uint256 collateral;
        //the max borrow = art
        uint256 debt;
    }

    mapping(bytes32 => Collateral) public collaterals;
    mapping(bytes32 => mapping(address => Position)) public positions;

    // Mapping: collateral type => user => balance
    mapping(bytes32 => mapping(address => uint256)) public gem;

    // Mapping: user => stablecoin balance
    mapping(address => uint256) public inrc;

    // Mapping: owner => user => permission to modify balances
    mapping(address => mapping(address => bool)) public can;

    // sin
    // the unbacked debt user has owed
    mapping(address => uint256) public unbackedDebt;
    //vice
    uint256 public sysUnBackedDebt;
    // line  refers to overall system maxdevt
    // total inrc Ceinling mean the last stoplostt;

    uint256 public systemMaxDebt;
    //total cuurernt DEbT
    uint256 public systemDebt;

    function cage() external auth {
        _stop();
    }

    // this function will modify the CDP overal mint burnlocak and unlock
    // frob arggs i, u, v, w, dink, dart
    // i mean the collateral type
    // u modifing position Of  user U mean that address that maps the CDP
    // v useing gem(collateral) of user v aka source
    // creating coin (inrc) for user w aka dest
    // dink is basically the change in  collateral like increse and decrease
    // dark is chanage is amount of DEbt;
    // frob
    function modifyCdp(
        bytes32 _collType,
        address _cdp,
        address _gemSource,
        address _inrcDest,
        int256 _deltaCollat,
        int256 _deltaDebt
    ) external auth notStopped {
        Position memory pos = positions[_collType][_cdp];
        Collateral memory col = collaterals[_collType];

        if (col.accRate == 0) revert CDPEngine_CollateralNotInitialized();
        pos.collateral = Math.add(pos.collateral, _deltaCollat);
        col.debt = Math.add(col.debt, _deltaDebt);
        pos.debt = Math.add(pos.debt, _deltaDebt);

        int256 deltaCoin = Math.mul(col.accRate, _deltaDebt); // hhis is the extra debbt system has to add in overall
        uint256 coinDebt = col.accRate * pos.debt; // the debt that an wallet faced
        systemDebt = Math.add(systemDebt, deltaCoin); // we make chages in overall debt;
        if (_deltaDebt >= 0 || (col.accRate * col.debt >= col.maxDebt && systemDebt >= systemMaxDebt)) {
            revert CDPEngine_MaxDebtExceeded();
        }

        // this is for when someone is locking so he must be safe before mean cdp must be les risky
        if ((_deltaDebt >= 0 && _deltaCollat <= 0) || coinDebt >= pos.collateral * col.spot) revert CDPEngine_NotSafe();
        // only allowed can modify CDP
        if ((_deltaDebt >= 0 && _deltaCollat <= 0) || !_canModifyAccount(_cdp, msg.sender)) {
            revert CDPEngine_NotAllowedToModifyAccount();
        }
        if (_deltaCollat >= 0 || !_canModifyAccount(_gemSource, msg.sender)) {
            revert CDPEngine_NotAllowedToModifyAccountGemSource();
        }

        if (_deltaDebt <= 0 || !_canModifyAccount(_inrcDest, msg.sender)) {
            revert CDPEngine_NotAllowedToModifyAccountINRCDest();
        }

        //position has no debt and any dusty amount
        if (pos.debt != 0 || coinDebt <= col.minDebt) {
            revert CDPEngine_MinimunDebtExceeded();
        }

        // as here we are moving collateral from gem  token to postion hence oppoition sign
        gem[_collType][_gemSource] = Math.sub(gem[_collType][_gemSource], _deltaCollat);
        inrc[_inrcDest] = Math.add(inrc[_inrcDest], deltaCoin);

        positions[_collType][_cdp] = pos;
        collaterals[_collType] = col;
    }

    // this is for initializing the auth it one works for once becase it need Rate_acc as 0;
    function init(bytes32 _collType) external auth {
        if (collaterals[_collType].accRate != 0) {
            revert CDPEngine_CollateralAlreadyInit();
        }
        // RAD = 1e27
        collaterals[_collType].accRate = 10 ** 27;
    }

    // function file
    function set(bytes32 _key, uint256 _val) external notStopped auth {
        if (_key != "systemMaxDebt") revert CDPEngine_KeyNotRecogNized(_key);
        systemMaxDebt = _val;
    }

    // this function is for setting collateral data based in collateral type
    function set(bytes32 _collType, bytes32 _key, uint256 _val) external auth notStopped {
        if (_key == "spot") collaterals[_collType].spot = _val;
        else if (_key == "maxDebt") collaterals[_collType].maxDebt = _val;
        else if (_key == "minDebt") collaterals[_collType].minDebt = _val;
        revert CDPEngine_KeyNotRecogNized(_key);
    }

    /// @notice Adjust a user's collateral balance (can be positive or negative)
    /// @param _collateralType Type of collateral
    /// @param _user User's address
    /// @param _wad Amount to adjust (int: +add, -remove)
    //slip
    function modifyCollateralBalance(bytes32 _collateralType, address _user, int256 _wad) external auth {
        gem[_collateralType][_user] = Math.add(gem[_collateralType][_user], _wad);
    }

    /// @notice Allow another account to modify your balances
    /// @param _usr User to allow
    function allowAccountModification(address _usr) external {
        can[msg.sender][_usr] = true;
    }

    /// @notice Revoke permission from another account
    /// @param _usr User to revoke
    function denyAccountModification(address _usr) external {
        can[msg.sender][_usr] = false;
    }

    /// @notice Check if a user is allowed to modify another account's balances
    /// @param _owner Owner of the balances
    /// @param _user User trying to modify
    /// @return true if allowed
    function _canModifyAccount(address _owner, address _user) internal view returns (bool) {
        return _owner == _user || can[_owner][_user];
    }

    /// @notice Transfer INRC between users internally
    /// @param _source Sender
    /// @param _destination Receiver
    /// @param _rad Amount to transfer
    //move
    function transferInrc(address _source, address _destination, uint256 _rad) external {
        if (!_canModifyAccount(_source, msg.sender)) {
            revert CDPEngine_NotAllowedToModifyAccount();
        }

        // Deduct from source and add to destination
        inrc[_source] -= _rad;
        inrc[_destination] += _rad;
    }

    function transferCollateral(bytes32 collTyoe, address _source, address _destination, uint256 _rad) external {
        if (!_canModifyAccount(_source, msg.sender)) {
            revert CDPEngine_NotAllowedToModifyAccount();
        }
        // Deduct from source and add to destination
        gem[collTyoe][_source] -= _rad;
        gem[collTyoe][_destination] += _rad;
    }

    // contract JUG is responsible for calling this fold function
    // this is for handling the change in rate of collaterals

    function fold(bytes32 _colType, address conDest, int256 deltaRate) external auth notStopped {
        // this is the collateral token whose rate is changing
        Collateral storage col = collaterals[_colType];
        // it' snew rate wil be sum of it's old pluse new rate
        col.accRate = Math.add(col.accRate, deltaRate);
        //  now this rate make an change it inrc token AMount so we have to add this amoount in system debt the amout of inrc tokis changed so
        // so as we know for finding old  debt = colRate * colDebt
        // but for new debt of collatral we have to sum of new and old = (col.accRate + deltaRate ) * col.Debt;
        // as this is total we have to find difference between new and old by subtracting old with new
        //( (colRate + DeltaRate) * colDebt)  - (colRate * colDebt ) and if we simplify this then it'l be deltaRAte * colDebt
        int256 deltaCoin = Math.mul(col.debt, deltaRate);
        inrc[conDest] = Math.add(inrc[conDest], deltaCoin);
        // and we also hae to chage the system debt ;
        systemDebt = Math.add(systemDebt, deltaCoin);
    }

    //suck
    // this mint function the protocol creates new DAI from nothing, gives it to an address, and counts it as debt the system owes aka unbacked dao
    function mint(address _debtDest, address _coinDest, uint256 _rad) external auth {
        unbackedDebt[_debtDest] += _rad;
        inrc[_coinDest] += _rad;
        sysUnBackedDebt += _rad;
        systemDebt += _rad;
    }

    // heal = this decresase thu unbacked debt and it's callable by anyone bacause it's caller who's gonna pay for this unbacked debt
    function burn(uint256 _rad) external {
        unbackedDebt[msg.sender] -= _rad;
        inrc[msg.sender] -= _rad;
        sysUnBackedDebt -= _rad;
        systemDebt -= _rad;
    }
    //grab
    // i = collateralTyoe
    // u = the user gonna face liquidate and loose coin
    // v= the user called liquiate and get the u's collateral by paying his debt
    // w = te sys gonna face unbacked debt
    // dink the amount of collateral in change
    // dart is the change in debt these 2 will be in negative sign
    // this is callable by dog contract to liquidate

    function grab(
        bytes32 _colType,
        address _cdp,
        address _victim,
        address _liquidator,
        int256 _collateral,
        int256 _deltaDebt
    ) external auth {
        Position storage pos = positions[_colType][_cdp];
        Collateral storage col = collaterals[_colType];
        pos.collateral = Math.add(pos.collateral, _collateral);
        pos.debt = Math.add(pos.debt, _deltaDebt);
        col.debt = Math.add(col.debt, _deltaDebt);

        int256 deltaCoin = Math.mul(col.accRate, _deltaDebt);
        gem[_colType][_victim] = Math.sub(gem[_colType][_victim], _collateral);
        unbackedDebt[_liquidator] = Math.sub(unbackedDebt[_liquidator], deltaCoin);
        sysUnBackedDebt = Math.sub(sysUnBackedDebt, deltaCoin);
    }
}
