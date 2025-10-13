// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

uint256 constant WAD = 10 ** 18;
uint256 constant RAY = 10 ** 27;
uint256 constant RAD = 10 ** 45;

/// @title Math Library
/// @notice Handles addition of uint and int safely without overflow
library Math {
    /// @notice Adds an int `_y` to uint `_x` safely
    /// @param _x The base uint value
    /// @param _y The int value to add (can be negative)
    /// @return z The resulting uint after addition/subtraction
    function add(uint256 _x, int256 _y) internal pure returns (uint256 z) {
        // if _y is positive, just add it
        // if _y is negative, subtract its absolute value from _x
        return _y >= 0 ? _x + uint256(_y) : _x - uint256(-_y);
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * RAY) / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * y) / RAY;
    }

    function sub(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x - uint256(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x >= y ? x : y;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * y) / WAD;
    }

    function diff(uint256 x, uint256 y) internal pure returns (int256 z) {
        require(int256(x) >= 0 && int256(y) >= 0);
        z = int256(x) - int256(y);
    }

    function mul(uint256 x, int256 y) internal pure returns (int256 z) {
        z = int256(x) * y;
        require(int256(x) >= 0);
        require(y == 0 || z / y == int256(x));
    }

    // (x / b) ** n * b

    // first it's taking three input first x thar is interest of evert sec and n is number of sec or time and then b is the scale valur to keep the result in limit
    function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 { z := b }
                default { z := 0 }
            }
            default {
                switch mod(n, 2)
                case 0 { z := b }
                default { z := x }
                let half := div(b, 2) // for rounding.
                for { n := div(n, 2) } n { n := div(n, 2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0, 0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0, 0) }
                    x := div(xxRound, b)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0, 0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0, 0) }
                        z := div(zxRound, b)
                    }
                }
            }
        }
    }
}

// function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
//     assembly {
//         // Handle x = 0 separately
//         switch x
//         case 0 {
//             switch n
//             // 0^0 = 1 in fixed-point → return b (scaled 1)
//             case 0 {
//                 z := b
//             }
//             // 0^n = 0 for n != 0
//             default {
//                 z := 0
//             }
//         }
//         default {
//             // Initialize z depending on whether n is even or odd
//             switch mod(n, 2)
//             // if n even, start with z = 1 in fixed-point
//             case 0 {
//                 z := b
//             }
//             // if n odd, start with z = x
//             default {
//                 z := x
//             }

//             let half := div(b, 2) // for rounding during divisions

//             // Exponentiation by squaring loop
//             for {
//                 n := div(n, 2)
//             } n {
//                 n := div(n, 2)
//             } {
//                 // square x
//                 let xx := mul(x, x)
//                 // overflow check: if xx / x != x, revert
//                 if iszero(eq(div(xx, x), x)) {
//                     revert(0, 0)
//                 }

//                 // rounding: add half before dividing
//                 let xxRound := add(xx, half)
//                 if lt(xxRound, xx) {
//                     revert(0, 0)
//                 } // check overflow again

//                 // scale back down by b (fixed-point adjustment)
//                 x := div(xxRound, b)

//                 // if current n bit is 1, multiply z by x
//                 if mod(n, 2) {
//                     let zx := mul(z, x)
//                     // overflow check
//                     if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
//                         revert(0, 0)
//                     }

//                     let zxRound := add(zx, half) // rounding
//                     if lt(zxRound, zx) {
//                         revert(0, 0)
//                     }

//                     // update z
//                     z := div(zxRound, b)
//                 }
//             }
//         }
//     }
// }
