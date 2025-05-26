// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SSTORE2.sol";

contract SvgSplitMandala {
    address public leftPtr;
    address public rightPtr;

    /// @notice Запись левой половины SVG
    function storeLeft(bytes memory data) public {
        leftPtr = SSTORE2.write(data);
    }

    /// @notice Запись правой половины SVG
    function storeRight(bytes memory data) public {
        rightPtr = SSTORE2.write(data);
    }

    /// @notice Сборка SVG из 2х кусков и инверсия цветов по флагу
    /// @param config [leftFlag, rightFlag] — 1 = белый, 0 = чёрный
    function getSvg(uint8[2] memory config) public view returns (string memory) {
        string memory head = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 100'>";
        string memory tail = "</svg>";

        string memory left = _setWhite(string(SSTORE2.read(leftPtr)), config[0]);
        string memory right = _setWhite(string(SSTORE2.read(rightPtr)), config[1]);

        return string.concat(head, left, right, tail);
    }

    function _setWhite(string memory part, uint8 flag) internal pure returns (string memory) {
        // если флаг = 0 — оставить чёрным
        if (flag == 0) return part;

        // иначе заменим fill='black' на fill='white'
        bytes memory input = bytes(part);
        bytes memory pattern = bytes("fill='black'");
        bytes memory replacement = bytes("fill='white'");

        for (uint256 i = 0; i <= input.length - pattern.length; i++) {
            bool matchFound = true;
            for (uint256 j = 0; j < pattern.length; j++) {
                if (input[i + j] != pattern[j]) {
                    matchFound = false;
                    break;
                }
            }
            if (matchFound) {
                for (uint256 j = 0; j < pattern.length; j++) {
                    input[i + j] = replacement[j];
                }
                break; // заменим только один раз
            }
        }

        return string(input);
    }
}
