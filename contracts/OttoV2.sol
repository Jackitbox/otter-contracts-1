// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;
//
//
//                       ██████╗ ████████╗████████╗ ██████╗ ██████╗ ██╗ █████╗
//                      ██╔═══██╗╚══██╔══╝╚══██╔══╝██╔═══██╗██╔══██╗██║██╔══██╗
//                      ██║   ██║   ██║      ██║   ██║   ██║██████╔╝██║███████║
//                      ██║   ██║   ██║      ██║   ██║   ██║██╔═══╝ ██║██╔══██║
//                      ╚██████╔╝   ██║      ██║   ╚██████╔╝██║     ██║██║  ██║
//                       ╚═════╝    ╚═╝      ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝
//
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔═══════⠳⠳ ⠳⠳═══════╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⣀⢤⠲⣃⠪⠠⠡⡁  ⡂⡵⡲⡤⣀⠀⠀⠀╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⡔⡍╔═════⠳⠳ ⠳⠳═════╗⢹⢹╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⣫⣫╔╝⢔⢔⢔⣨⣴⣷⣽⣖⣯⢷⣮⣐⠡⠡╚╗⡓⣷╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⢮⠞╔╝⣼⣼⣾⠀⠀⠀⠀⠀⠀⠀⠀⠀⣯⣷⢜⢔╚╗⠱⡲╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⣚⡦╔╝⣿⣿⢯⠀⣿⣿⣷⣿⣿⣿⣾⣷⣷⠀⠀⢿⣗⡌╚╗⢜⡞╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔╝⢎⢷╔╝⣿⠀⠀⣿⢿⣻⠀⠀⠀⠀⠀⢽⣻⢿⣷⠀⠀⡽⣿⡌╚╗⠨⡀╚╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀╔═════╗⠀⠀⣿⣻⣻⠀⠀⠀⠀⠀⠀⠀⠀⡳⣝⢿⣿⠀⠀⣳╔═════╗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀║█████║⠀⣿⠀⠀⣿⣟⣗⣿⣾⣿⣾⣾⣷⠀⠀⣳⣻⣷⣳⠀║█████║⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣿⡯⡯⠀⡻⣮⠀⠀⠀⠀⠀⠀⠀⢿⣧⠀⡽⣿⣽⣽⠀⡖|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣿⢯⡫⠀⡽⠀⢽⣿⡿⣿⣿⣿⠀⠀⢿⣽⠀⣻⣷⣷⠀⡝|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣿⡳⠀⢮⠀⡯⣿⣟⣿⣿⣿⣿⣿⠀⢽⣯⠀⣻⣿⣿⠀⢕|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣿⣝⠀⠀⡿⣽⣿⠀⠀⠀⠀⣿⣿⠀⣯⣿⠀⣿⣟⠀⠀⡃|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⣟⢮⠀⠀⣯⢿⣯⠀⣿⣿⠀⣿⣿⠀⣾⡷⠀⣿⣯⠀⠀⡅|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀|█|█|⡗⣷⠀⠀⡯⣿⡿⠀⣽⣿⠀⠀⣳⣯⣿⠀⣾⣿⣺⠀⡺⢌|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀|█|█|⡹⣾⠀⠀⣿⢽⣿⣻⠀⣟⣿⡾⣿⢿⠀⣽⣿⣗⠀⠀⣝⠆|█|█|⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⣀⠀⠀⠀|█|█|⣫⣿⣷⠀⠀⣯⣿⣿⣽⠀⠀⠀⠀⠀⣿⡿⣗⠀⠀⡳⣵⡣|█|█|⢀⠣⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡱⡱⡀⡄⠀|█|█|⣽⣾⣿⣟⠀⠀⣞⡿⣿⣷⣯⣿⣾⡿⡯⣯⠀⠀⣿⣿⣽⡗|█|█|⡐⢡⠅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠀⠀⠀⠠⣳⡱⠳⡡⡓⡕⠕⠀|█|█|⣺⣿⣿⣿⣽⠀⠀⡯⡯⡻⡽⡯⡳⡽⣝⠀⠀⣻⣿⣿⣿⡣|█|█|⠢⢃⠂⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⡢⢄⠀⡀⠀⠑⢭⢳⢄⢺⢜⠬⠀|█|█|⢾⣿⣷⣿⣷⣯⠀⠀⠀⠀⠀⠀⠀⠀⠀⣽⣿⣿⣟⣟⣷⠡|█|█|⠂⢄⠠⢂⢂⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠠⠁⠄⠨⡚⡪⢪⢳⠘⠌⢎⠀|█|█|⣺⣿⣿⣽⢿⣿⣳⣝⠀⠀⠀⠀⠀⠀⢿⣟⡯⣗⣗⣗⢷⡹|█|█|⠡⡂⡅⠎⡔⠖⠨⡣⡠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⡀⠀⠀⠀⠀⠀⠐⠈⠐⠄⢂⠪⠘⡒⡀⡑║███████████████████████████████████║⢐⡡⡑⡺⡱⠹⡪⠉⠁⡈⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠠⠁⠀⡀⡢⢄⠀⠀⠈⠠⠁⠂⢌⠠⠐⠀⠀///⡪ ╔════════════════════════════╗⣐\\\⠠⢉⠙⡌⠊⢀⠠⠐⠀⠀⠀⠠⢊⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢂⠢⢑⡁⠀⠄⠈⡈⡈⢐⠐⠈⠂///⡗⡱ ║████████████████████████████║⡂⢻\\\⠀⠀⡀⠀⢀⡀⠀⠀⠀⠂⠀⠂⠀⠂⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⡀⠐⢀⠀⠀⢀⠂⠁⢄⡐⠐⠈⠠⠨⡁///⢮ ╔════════════════════════════════╗⠳\\\⠢⠀⠂⡀⠠⠁⠀⠁⠐⠐⠀⠈⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⡐⢔⠝⠀⡄⠄⠀⠨⠀⠁⠂⠐⡈⠀⠅///⠇⡐ ║████████████████████████████████║⢀⠹\\\⠠⡂⠐⠀⠡⠈⠀⡀⠀⠀⠄⠀⠠⢈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢐⠠⠁⠄⠀⠈⠠⠀⠂⠀⢈⢄///⠄ ╔════════════════════════════════════╗⠀\\\⡌⢆⠀⡀⠀⠁⠈⠐⡀⢀⢈⠀⠐⠀⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⢀⢀⠀⠀⠠⠨⡊///⠌⠄ ║████████████████████████████████████║⠀⠁\\\⠈⢎⠢⢈⠀⠀⠁⠀⠁⠀⠂⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀══════════════════════════════════════════════════════════════⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠐⠀⠘⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//                      ʕ•̫͡•ʕ•̫͡•ʔ•̫͡•ʔ•̫͡•ʕ•̫͡•ʔ  \\OtterClam//  ʕ•̫͡•ʕ•̫͡•ʔ•̫͡•ʔ•̫͡•ʕ•̫͡•ʔ
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠐⠀⠘⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠐⠀⠘⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
import './interfaces/IOtto.sol';
import './libraries/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

contract OttoV2 is
    ERC721AUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IOttoV2
{
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    string private _baseTokenURI;
    mapping(uint256 => OttoInfo) public infos;
    mapping(uint256 => uint256[]) public candidates;
    uint256 public summonPeriod;

    struct OttoInfo {
        string name;
        string description;
        uint256 birthday;
        uint256 traits; // uint8 [...]
        uint256 values; // uint32 [level, experiences, hungerValue, friendship, ...reserved]
        // int16[] [STR, DEF, DEX, INT, LUK, CON, CUTE, BRS, ...reserved]
        uint256 attributes; // can be changed by level up
        uint256 attributeBonuses; // from traits & wearable
        uint256 flags; // bool [portalStatus, isLegendary, ...reserved]
        uint256 mintTimestamp;
    }

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    modifier onlyMinter() {
        _checkRole(MINTER_ROLE, _msgSender());
        _;
    }

    modifier onlyManager() {
        _checkRole(MANAGER_ROLE, _msgSender());
        _;
    }

    modifier onlyOttoOwner(uint256 tokenId_) {
        require(
            _msgSender() == ownerOf(tokenId_),
            'caller is not the owner of the token'
        );
        _;
    }

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), 'zero address');
        _;
    }

    modifier validOttoId(uint256 tokenId_) {
        require(_exists(tokenId_), 'invalid tokenId');
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) public virtual override initializer {
        ERC721AUpgradeable.initialize(
            name_,
            symbol_,
            maxBatchSize_,
            collectionSize_
        );
        __Ownable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    function grantMinter(address minter_) public onlyAdmin {
        _setupRole(MINTER_ROLE, minter_);
    }

    function revokeMinter(address minter_) public onlyAdmin {
        _revokeRole(MINTER_ROLE, minter_);
    }

    function grantManager(address manager_) public onlyAdmin {
        _setupRole(MANAGER_ROLE, manager_);
    }

    function revokeManager(address manager_) public onlyAdmin {
        _revokeRole(MANAGER_ROLE, manager_);
    }

    function mint(address to_, uint256 quantity_)
        external
        virtual
        onlyMinter
        nonZeroAddress(to_)
    {
        uint256 startTokenId = totalSupply();
        _safeMint(to_, quantity_);
        for (uint256 i = 0; i < quantity_; i++) {
            infos[startTokenId + i] = OttoInfo({
                name: '',
                description: '',
                birthday: 0,
                traits: 0,
                values: 0,
                attributes: 0,
                attributeBonuses: 0,
                flags: 0,
                mintTimestamp: block.timestamp
            });
        }
    }

    function set(
        string memory name_,
        string memory description_,
        uint256 tokenId_,
        uint256 birthday_,
        uint256 traits_,
        uint256 values_,
        uint256 attributes_,
        uint256 attributeBonuses_,
        uint256 flags_
    ) external virtual onlyManager validOttoId(tokenId_) {
        infos[tokenId_].name = name_;
        infos[tokenId_].description = description_;
        infos[tokenId_].birthday = birthday_;
        infos[tokenId_].traits = traits_;
        infos[tokenId_].values = values_;
        infos[tokenId_].attributes = attributes_;
        infos[tokenId_].attributeBonuses = attributeBonuses_;
        infos[tokenId_].flags = flags_;
    }

    function openPortal(
        uint256 tokenId_,
        uint256[] memory candidates_,
        bool legendary_
    ) external onlyManager validOttoId(tokenId_) {
        require(
            block.timestamp >= infos[tokenId_].mintTimestamp + summonPeriod,
            'summon period is not over'
        );
        require(
            portalStatus(tokenId_) == PortalStatus.UNOPENED,
            'portal is already opened'
        );
        if (legendary_) {
            require(
                candidates_.length == 1,
                'legendary otto can only have one candidate'
            );
        }

        candidates[tokenId_] = candidates_;
        uint8[32] memory flags_ = U256toU8(infos[tokenId_].flags);
        flags_[0] = uint8(PortalStatus.OPENED);
        if (legendary_) {
            flags_[1] = 1;
        } else {
            flags_[1] = 0;
        }
        infos[tokenId_].flags = U8toU256(flags_);
        emit PortalOpened(
            tx.origin,
            tokenId_,
            candidates_,
            legendary(tokenId_)
        );
    }

    function summon(
        uint256 tokenId_,
        uint256 candidateIndex,
        uint256 birthday_
    ) external onlyManager validOttoId(tokenId_) {
        require(
            portalStatus(tokenId_) == PortalStatus.OPENED,
            'portal is not opened or already summoned'
        );
        require(
            candidateIndex < candidates[tokenId_].length,
            'invalid candidate index'
        );
        uint8[32] memory flags_ = U256toU8(infos[tokenId_].flags);
        flags_[0] = uint8(PortalStatus.SUMMONED);
        infos[tokenId_].flags = U8toU256(flags_);
        infos[tokenId_].traits = candidates[tokenId_][candidateIndex];
        infos[tokenId_].birthday = birthday_;
        emit OttoSummoned(
            tx.origin,
            tokenId_,
            candidates[tokenId_][candidateIndex],
            birthday_
        );
    }

    function setBaseURI(string calldata baseURI) external onlyAdmin {
        _baseTokenURI = baseURI;
        emit BaseURIChanged(msg.sender, baseURI);
    }

    function setSummonPeriod(uint256 summonPeriod_)
        external
        virtual
        override
        onlyAdmin
    {
        require(summonPeriod_ > 0, 'summonPeriod_ than 0');
        summonPeriod = summonPeriod_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function totalMintable() external view virtual override returns (uint256) {
        return collectionSize - totalSupply();
    }

    function maxBatch() external view virtual override returns (uint256) {
        return maxBatchSize;
    }

    function minted(uint256 tokenId_)
        external
        view
        virtual
        override
        returns (bool)
    {
        return _exists(tokenId_);
    }

    function portalStatus(uint256 tokenId_)
        public
        view
        virtual
        override
        validOttoId(tokenId_)
        returns (PortalStatus)
    {
        return PortalStatus(U256toU8(infos[tokenId_].flags)[0]);
    }

    function legendary(uint256 tokenId_)
        public
        view
        virtual
        override
        validOttoId(tokenId_)
        returns (bool)
    {
        return U256toU8(infos[tokenId_].flags)[1] != 0;
    }

    function canSummonTimestamp(uint256 tokenId_)
        external
        view
        virtual
        override
        validOttoId(tokenId_)
        returns (uint256)
    {
        if (infos[tokenId_].mintTimestamp == 0) {
            return 1648645200 + summonPeriod; // 2022-03-30T13:00:00.000Z + 7 days
        } else {
            return infos[tokenId_].mintTimestamp + summonPeriod;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function U8toU256(uint8[32] memory arr_)
        public
        pure
        returns (uint256 traits_)
    {
        traits_ = 0;
        for (uint8 i = 0; i < 32; i++) {
            traits_ = (traits_ << 8) | arr_[31 - i];
        }
    }

    function U256toU8(uint256 traits_)
        public
        pure
        returns (uint8[32] memory arr_)
    {
        for (uint8 i = 0; i < 32; i++) {
            arr_[i] = uint8(traits_ >> (i * 8));
        }
    }

    function U16toU256(uint16[16] memory arr_)
        public
        pure
        returns (uint256 traits_)
    {
        traits_ = 0;
        for (uint16 i = 0; i < 16; i++) {
            traits_ = (traits_ << 16) | arr_[15 - i];
        }
    }

    function U256toU16(uint256 traits_)
        public
        pure
        returns (uint16[16] memory arr_)
    {
        for (uint16 i = 0; i < 16; i++) {
            arr_[i] = uint16(traits_ >> (i * 16));
        }
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}
}
