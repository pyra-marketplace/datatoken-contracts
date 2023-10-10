// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDataTokenHub {
    /**
     * @dev get currenct version of implementation contract
     * @return version string
     */
    function version() external view returns (string memory);

    /**
     * @notice initializer
     */
    function initialize() external;

    /**
     * @dev register data token address to DataTokenHub
     * @param dataTokenOwner the owner of the data token
     * @param originalContract the original contract
     * @param dataToken data token contract address
     */
    function registerDataToken(address dataTokenOwner, address originalContract, address dataToken) external;

    /**
     * @dev check whether this dataToken registered
     * @param dataToken data token contract address
     * @return bool
     */
    function isDataTokenRegistered(address dataToken) external view returns (bool);

    /**
     * @dev set new governor
     * @param newGovernor new governor
     */
    function setGovernor(address newGovernor) external;

    /**
     * @dev get the governor of DataTokenHub contract
     */
    function getGovernor() external view returns (address);

    /**
     * @param factory DataTokenFactory address
     * @param whitelistStatus true or false
     */
    function whitelistDataTokenFactory(address factory, bool whitelistStatus) external;

    /**
     * @dev get whitelisted status
     * @param factory DataTokenFactory address
     */
    function isDataTokenFactoryWhitelisted(address factory) external view returns (bool);

    /**
     * @dev emit collected event
     * @notice call by registered DataToken
     */
    function emitCollected(address collector, address collectNFT, uint256 tokenId) external;
}
