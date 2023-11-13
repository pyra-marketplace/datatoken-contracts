// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Config {
    uint256 internal constant BSC = 56;
    uint256 internal constant BSCTestnet = 97;
    uint256 internal constant Polygon = 137;
    uint256 internal constant PolygonMumbai = 80001;
    uint256 internal constant Scroll = 534352;
    uint256 internal constant ScrollSepolia = 534351;
    uint256 internal constant Filecoin = 34;
    uint256 internal constant FilecoinCalibration = 314159;
    uint256 internal constant FhenixDevnet = 5432;

    uint256 internal _privateKey;

    // Graph: Lens
    address internal _lensHubProxy;
    address internal _collectPublicationAction;
    address internal _simpleFeeCollectModule;
    address internal _multirecipientFeeCollectModule;

    // Graph: Cyber
    address internal _cyberProfileProxy;
    address internal _collectPaidMw;

    // Graph: Profileless
    address internal _profilelessHub;
    address[] internal _currencys;

    constructor() {
        if (block.chainid == Polygon) {
            _lensHubProxy = 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d;
        }
        if (block.chainid == PolygonMumbai) {
            _lensHubProxy = 0xC1E77eE73403B8a7478884915aA599932A677870;
            _collectPublicationAction = 0x5FE7918C3Ef48E6C5Fd79dD22A3120a3C4967aC2;
            _simpleFeeCollectModule = 0x98daD8B389417A5A7D971D7F83406Ac7c646A8e2;
            _multirecipientFeeCollectModule = 0xa878101e04518693ABE7fccd03778174A2B08159;

            address WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
            address WETH = 0x3C68CE8504087f89c640D02d133646d98e64ddd9;
            address USDC = 0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e;
            address DAI = 0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F;

            _currencys.push(WMATIC);
            _currencys.push(WETH);
            _currencys.push(USDC);
            _currencys.push(DAI);
        }
        if (block.chainid == BSC) {
            _cyberProfileProxy = 0x2723522702093601e6360CAe665518C4f63e9dA6;
            _collectPaidMw = 0xB09Ae63A2fD28686A0f386D1dDfD4b53687bf298;
        }
        if (block.chainid == BSCTestnet) {
            _cyberProfileProxy = 0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271;
            _collectPaidMw = 0x4e0D14e52418881511Fd8156585D4B03eEc1FF36;

            address USDT = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;
            address BNB = 0xEE786A1aA32fc164cca9A28F763Fbc835E748129;
            address CCT = 0xce91C2bbEdfda8A120fD4884d720725E5E1D7d30;
            address LINK = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;
            _currencys.push(USDT);
            _currencys.push(BNB);
            _currencys.push(CCT);
            _currencys.push(LINK);
        }
        if (block.chainid == ScrollSepolia) {
            address WETH = 0x5300000000000000000000000000000000000004;
            address USDC = 0x690000EF01deCE82d837B5fAa2719AE47b156697;
            address USDT = 0x551197e6350936976DfFB66B2c3bb15DDB723250;
            _currencys.push(WETH);
            _currencys.push(USDC);
            _currencys.push(USDT);
        }
        if (block.chainid == FilecoinCalibration) {
            address WFIL = 0xaC26a4Ab9cF2A8c5DBaB6fb4351ec0F4b07356c4;
            _currencys.push(WFIL);
        }
        if (block.chainid == FhenixDevnet) {
            address PHET = 0xb942C11C074a7D9018d8569B2389d1F331e52fA6;
            _currencys.push(PHET);
        }
    }
}
