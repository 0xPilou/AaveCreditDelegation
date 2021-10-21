pragma solidity ^0.8.0;

import './interfaces/ILendingPool.sol';
import './interfaces/IProtocolDataProvider.sol';
import './interfaces/IVariableDebtToken.sol';
import './interfaces/IStableDebtToken.sol';

import 'openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol';
import 'openzeppelin-solidity/contracts/utils/math/SafeMath.sol';


contract AaveCreditDelegation {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // DAI Address (on Polygon)
    address private constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;

    // USDC Address (on Polygon)
    address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    // USDT Address (on Polygon)
    address private constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    // Interface to AAVE Data Provider contract
    IProtocolDataProvider private dataProvider;
    
    // Interface to AAVE Lending Pool contract
    ILendingPool private lendingPool;

    // Amount delegated by the user to AAVE Credit Delegation contract
    uint256 private amountDelegated = 0;


    constructor(address _dataProvider, address _lendingPool) {
        dataProvider = IProtocolDataProvider(_dataProvider);
        lendingPool = ILendingPool(_lendingPool);
    }

    function drawCredit(address _asset, uint256 _interestRateMode) external {
        // Verifies that the asset requested for dekegation is supported by the contract
        require(_isSupportedAsset(_asset), "Asset not supported");
        // Check correctness of interest rate mode parameter
        require(_interestRateMode == 1 || _interestRateMode == 2, "Incorrect Interest Rate Mode");

        // Get the address of debt tokens
        (, address sDebtTokenAddr, address vDebtTokenAddr) = dataProvider.getReserveTokensAddresses(_asset);

        // Assign and check the amount approved for delegation
        uint256 amount;
        if(_interestRateMode == 1) {
            amount = IStableDebtToken(sDebtTokenAddr).borrowAllowance(msg.sender, address(this));
        } else {
            amount = IVariableDebtToken(vDebtTokenAddr).borrowAllowance(msg.sender, address(this));
        }
        require(amount > 0, "Amount approved for delegation is 0");

        // Borrow amount of asset on behalf of msg.sender
        lendingPool.borrow(_asset, amount, _interestRateMode, 0, msg.sender);

        // Here, deposit to Beefy 
    }

    function requestDebtRepayment(address _asset, uint256 _interestRateMode) external {
        // Verifies that the asset requested for repayment is supported by the contract
        require(_isSupportedAsset(_asset), "Asset not supported");
        // Check correctness of interest rate mode parameter
        require(_interestRateMode == 1 || _interestRateMode == 2, "Incorrect Interest Rate Mode");

        // Here, withdraw from Beefy
        uint256 amount = IERC20(_asset).balanceOf(address(this));

        IERC20(_asset).approve(address(lendingPool), amount);
        // Repay the amount of asset on behalf of msg.sender
        lendingPool.repay(_asset, amount, _interestRateMode, msg.sender);

    }

    function _isSupportedAsset(address _asset) internal pure returns (bool){
        if(_asset == DAI || _asset == USDC || _asset == USDT) {
            return true;
        } else return false;
    }
}