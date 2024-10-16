// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVRFV2PlusWrapper} from "@chainlink-contracts-1.2.0/src/v0.8/vrf/dev/interfaces/IVRFV2PlusWrapper.sol";

contract MockVRFV2PlusWrapper is IVRFV2PlusWrapper {
    // State variables to simulate the behavior
    uint256 private _lastRequestId;
    address private _linkTokenAddress;
    address private _linkNativeFeedAddress;
    uint256 private _mockPrice;

    constructor(address linkToken, address linkNativeFeed) {
        _linkTokenAddress = linkToken;
        _linkNativeFeedAddress = linkNativeFeed;
        _lastRequestId = 0;
        _mockPrice = 1000 gwei; // Default price for simplicity in testing
    }

    // Mock implementation of lastRequestId
    function lastRequestId() external view override returns (uint256) {
        return _lastRequestId;
    }

    // Mock implementation of calculateRequestPrice
    function calculateRequestPrice(uint32 _callbackGasLimit, uint32 _numWords)
        external
        view
        override
        returns (uint256)
    {
        // Just return a simple mock value for testing
        return _mockPrice + (_callbackGasLimit * _numWords);
    }

    // Mock implementation of calculateRequestPriceNative
    function calculateRequestPriceNative(uint32 _callbackGasLimit, uint32 _numWords)
        external
        view
        override
        returns (uint256)
    {
        // Return mock price in native token (e.g., ETH)
        return _mockPrice + (_callbackGasLimit * _numWords * 2);
    }

    // Mock implementation of estimateRequestPrice
    function estimateRequestPrice(uint32 _callbackGasLimit, uint32 _numWords, uint256 _requestGasPriceWei)
        external
        view
        override
        returns (uint256)
    {
        // Estimate price based on gas limit and gas price
        return (_callbackGasLimit * _requestGasPriceWei * _numWords);
    }

    // Mock implementation of estimateRequestPriceNative
    function estimateRequestPriceNative(uint32 _callbackGasLimit, uint32 _numWords, uint256 _requestGasPriceWei)
        external
        view
        override
        returns (uint256)
    {
        // Return mock estimation in native token
        return (_callbackGasLimit * _requestGasPriceWei * _numWords * 2);
    }

    // Mock implementation of requestRandomWordsInNative
    function requestRandomWordsInNative(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        bytes calldata extraArgs
    ) external payable override returns (uint256) {
        // Increment the requestId to simulate a new request
        _lastRequestId++;
        // Simulate processing and return the request ID
        return _lastRequestId;
    }

    // Mock implementation to return LINK token address
    function link() external view override returns (address) {
        return _linkTokenAddress;
    }

    // Mock implementation to return LINK-native price feed address
    function linkNativeFeed() external view override returns (address) {
        return _linkNativeFeedAddress;
    }

    // For testing purposes, set a mock price
    function setMockPrice(uint256 newPrice) external {
        _mockPrice = newPrice;
    }
}
