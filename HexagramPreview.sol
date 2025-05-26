// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract HexagramMint {
    using Strings for uint256;

    mapping(uint8 => bool) public isOriginalMinted;
    uint8[] public originalValues;
    uint8 public totalOriginals;
    uint256 public totalMinted;

    struct Hexagram {
        uint8 value;
        bool isDuplicate;
        bool isAfterAllOriginals;
    }

    mapping(uint256 => Hexagram) public tokens;

    function mint(uint8 value) public {
        bool afterAll = totalOriginals >= 64;
        bool isDup;

        if (!afterAll) {
            isDup = isOriginalMinted[value];
            if (!isDup) {
                isOriginalMinted[value] = true;
                totalOriginals++;
                originalValues.push(value);
            }
        } else {
            // после 64 оригиналов — все неоригиналы становятся "серыми"
            isDup = false;
        }

        tokens[totalMinted] = Hexagram({
            value: value,
            isDuplicate: isDup,
            isAfterAllOriginals: afterAll
        });

        totalMinted++;
    }


    function getOriginalValues() public view returns (uint8[] memory) {
        return originalValues;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        Hexagram memory h = tokens[tokenId];
        string memory svg = generateSVG(h.value, h.isDuplicate, h.isAfterAllOriginals, tokenId);

        string memory json = string(
            abi.encodePacked(
                '{"name":"Hexagram #', uint256(h.value).toString(),
                '", "description":"Hexagram SVG logic variant", "image":"data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function generateSVG(uint8 value, bool isDup, bool isAfterAll, uint256 tokenId) internal pure returns (string memory) {
        string memory fillOuter = isDup ? "black" : (isAfterAll ? "#eee" : "white");
        string memory strokeInner = isDup ? "white" : "black";
        string memory textColor = isDup ? "white" : "black";

        string memory svgStart = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 400 400'>";
        string memory outerBox = string(
            abi.encodePacked("<rect x='0' y='0' width='400' height='400' fill='", fillOuter, "' stroke='black'/>")
        );
        string memory innerBox = string(
            abi.encodePacked("<rect x='74' y='74' width='252' height='252' fill='none' stroke='", strokeInner, "'/>")
        );

        string[6] memory fills;
        for (uint8 i = 0; i < 6; i++) {
            fills[i] = ((value >> (5 - i)) & 1) == 1 ? "white" : "black";
        }

        string memory bars = string(
            abi.encodePacked(
                "<rect x='74' y='74' width='252' height='42' fill='", fills[5], "'/>",
                "<rect x='74' y='116' width='252' height='42' fill='", fills[4], "'/>",
                "<rect x='74' y='158' width='252' height='42' fill='", fills[3], "'/>",
                "<rect x='74' y='200' width='252' height='42' fill='", fills[2], "'/>",
                "<rect x='74' y='242' width='252' height='42' fill='", fills[1], "'/>",
                "<rect x='74' y='284' width='252' height='42' fill='", fills[0], "'/>"
            )
        );

        string memory binary = toBinary(value);

        string memory label = string(
            abi.encodePacked(
                "<text x='200' y='355' font-size='20' text-anchor='middle' font-family='monospace' fill=\"",
                textColor,
                "\">",
                binary,
                "</text>"
            )
        );

        string memory tokenNumber = string(
            abi.encodePacked(
                "<text x='200' y='377' font-size='12' text-anchor='middle' font-family='monospace' fill=\"",
                textColor,
                "\">#",
                tokenId.toString(),
                "</text>"
            )
        );

        return string(abi.encodePacked(svgStart, outerBox, bars, innerBox, label, tokenNumber, "</svg>"));
    }

    function toBinary(uint8 value) internal pure returns (string memory) {
        bytes memory out = new bytes(6);
        for (uint8 i = 0; i < 6; i++) {
            out[i] = ((value >> (5 - i)) & 1) == 1 ? bytes1("1") : bytes1("0");
        }
        return string(out);
    }
}
