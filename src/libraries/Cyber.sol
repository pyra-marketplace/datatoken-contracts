// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

library CyberTypes {
    struct RegisterEssenceParams {
        uint256 profileId;
        string name;
        string symbol;
        string essenceTokenURI;
        address essenceMw;
        bool transferable;
        bool deployAtRegister;
    }

    struct CollectParams {
        address collector;
        uint256 profileId;
        uint256 essenceId;
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }
}

interface IProfileNFT {
    /**
     * @notice Register an essence with signature.
     *
     * @param params The params for registration.
     * @param initData The registration initial data.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     * @return uint256 The new essence count.
     */
    function registerEssenceWithSig(
        CyberTypes.RegisterEssenceParams calldata params,
        bytes calldata initData,
        CyberTypes.EIP712Signature calldata sig
    ) external returns (uint256);

    /**
     * @notice Collect a profile's essence with signature.
     *
     * @param sender The sender address.
     * @param params The params for collect.
     * @param preData The collect data for preprocess.
     * @param postData The collect data for postprocess.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     * @return uint256 The collected essence nft id.
     */
    function collectWithSig(
        CyberTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData,
        address sender,
        CyberTypes.EIP712Signature calldata sig
    ) external returns (uint256);

    /**
     * @notice Gets the Essence NFT token URI.
     *
     * @param profileId The profile ID.
     * @param essenceId The Essence ID.
     * @return string The Essence NFT token URI.
     */
    function getEssenceNFTTokenURI(uint256 profileId, uint256 essenceId) external view returns (string memory);

    /**
     * @notice Gets the Essence NFT address.
     *
     * @param profileId The profile ID.
     * @param essenceId The Essence ID.
     * @return address The Essence NFT address.
     */
    function getEssenceNFT(uint256 profileId, uint256 essenceId) external view returns (address);
}
