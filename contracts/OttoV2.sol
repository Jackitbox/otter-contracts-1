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
        uint256 mintAt;
        uint256 summonAt;
        uint256 birthday;
        // u16 [
        // Background, SkinColor, SkinType, Clothes, Mouth, Eyes, FacialAccessories,
        // Headwear, Holding, Heraldry, Voice, Personality, Gender, ...
        // ]
        uint256 traits;
        PortalStatus portalStatus;
        bool legendary;
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
                mintAt: block.timestamp,
                summonAt: 0,
                birthday: 0,
                traits: 0,
                portalStatus: PortalStatus.UNOPENED,
                legendary: false
            });
        }
    }

    function openPortal(
        uint256 tokenId_,
        uint256[] memory candidates_,
        bool legendary_
    ) external onlyManager validOttoId(tokenId_) {
        require(
            block.timestamp >= infos[tokenId_].mintAt + summonPeriod,
            'summon period is not over'
        );
        require(
            portalStatusOf(tokenId_) == PortalStatus.UNOPENED,
            'portal is already opened'
        );
        if (legendary_) {
            require(
                candidates_.length == 1,
                'legendary otto can only have one candidate'
            );
        }

        candidates[tokenId_] = candidates_;
        _setLegendary(tokenId_, legendary_);
        _setPortalStatus(tokenId_, PortalStatus.OPENED);
    }

    function summon(
        uint256 tokenId_,
        uint256 candidateIndex,
        uint256 birthday_
    ) external onlyManager validOttoId(tokenId_) {
        require(
            portalStatusOf(tokenId_) == PortalStatus.OPENED,
            'portal is not opened or already summoned'
        );
        require(
            candidateIndex < candidates[tokenId_].length,
            'invalid candidate index'
        );
        _setPortalStatus(tokenId_, PortalStatus.SUMMONED);
        infos[tokenId_].traits = candidates[tokenId_][candidateIndex];
        infos[tokenId_].birthday = birthday_;
        infos[tokenId_].summonAt = block.timestamp;
        delete candidates[tokenId_];
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

    function setTraits(uint256 tokenId_, uint256 traits_)
        external
        virtual
        override
        onlyAdmin
        validOttoId(tokenId_)
    {
        infos[tokenId_].traits = traits_;
    }

    function _setPortalStatus(uint256 tokenId_, PortalStatus status_)
        private
        validOttoId(tokenId_)
    {
        infos[tokenId_].portalStatus = status_;
        emit PortalStatusChanged(tx.origin, tokenId_, status_);
    }

    function _setLegendary(uint256 tokenId_, bool legendary_)
        private
        validOttoId(tokenId_)
    {
        infos[tokenId_].legendary = legendary_;
        if (legendary_) {
            emit LegendaryFound(tx.origin, tokenId_);
        }
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

    function exists(uint256 tokenId_)
        external
        view
        virtual
        override
        returns (bool)
    {
        return _exists(tokenId_);
    }

    function portalStatusOf(uint256 tokenId_)
        public
        view
        virtual
        override
        validOttoId(tokenId_)
        returns (PortalStatus)
    {
        return infos[tokenId_].portalStatus;
    }

    function legendary(uint256 tokenId_)
        public
        view
        virtual
        override
        validOttoId(tokenId_)
        returns (bool)
    {
        return infos[tokenId_].legendary;
    }

    function candidatesOf(uint256 tokenId_)
        external
        view
        virtual
        override
        validOttoId(tokenId_)
        returns (uint256[] memory)
    {
        return candidates[tokenId_];
    }

    function traitsOf(uint256 tokenId_)
        external
        view
        virtual
        override
        validOttoId(tokenId_)
        returns (uint16[16] memory arr_)
    {
        uint256 traits_ = infos[tokenId_].traits;
        for (uint16 i = 0; i < 16; i++) {
            arr_[i] = uint16(traits_ >> (i * 16));
        }
    }

    function canSummonAt(uint256 tokenId_)
        external
        view
        virtual
        override
        validOttoId(tokenId_)
        returns (uint256)
    {
        if (infos[tokenId_].mintAt == 0) {
            return 1648645200 + summonPeriod; // 2022-03-30T13:00:00.000Z + 7 days
        } else {
            return infos[tokenId_].mintAt + summonPeriod;
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

    function _authorizeUpgrade(address) internal override onlyAdmin {}
}
