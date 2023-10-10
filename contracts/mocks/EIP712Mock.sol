// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library EIP712Mock {
    bytes32 internal constant POST_WITH_SIG_TYPEHASH = keccak256(
        "PostWithSig(uint256 profileId,string contentURI,address collectModule,bytes collectModuleInitData,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)"
    );

    bytes32 internal constant COMMENT_WITH_SIG_TYPEHASH = keccak256(
        "CommentWithSig(uint256 profileId,string contentURI,uint256 profileIdPointed,uint256 pubIdPointed,bytes referenceModuleData,address collectModule,bytes collectModuleInitData,address referenceModule,bytes referenceModuleInitData,uint256 nonce,uint256 deadline)"
    );

    bytes32 internal constant COLLECT_WITH_SIG_TYPEHASH =
        keccak256("CollectWithSig(uint256 profileId,uint256 pubId,bytes data,uint256 nonce,uint256 deadline)");

    function calculateDigest(bytes32 domainSeparator, bytes32 hashedMessage) internal pure returns (bytes32) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashedMessage));
        return digest;
    }

    function getSigNonce(address lensHub, address user) internal view returns (uint256) {
        (bool success, bytes memory data) = lensHub.staticcall(abi.encodeWithSignature("sigNonces(address)", user));
        require(success, "failed to get sigNonce");
        uint256 nonce = abi.decode(data, (uint256));
        return nonce;
    }
}
