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

    // Address of AAVE Data Provider contract
    address private AAVE_DATA_PROVIDER;
    
    // Address of AAVE Lending Pool contract
    address private AAVE_LENDING_POOL;


    constructor(address _dataProvider, address _lendingPool) {
        AAVE_DATA_PROVIDER = _dataProvider;
        AAVE_LENDING_POOL = _lendingPool;
    }

    function drawCredit(address _asset, uint256 _interestRateMode) external {
        // Check correctness of interest rate mode parameter
        require(_interestRateMode == 1 || _interestRateMode == 2, "Incorrect Interest Rate Mode");

        // Get the address of debt tokens
        (, address sDebtTokenAddr, address vDebtTokenAddr) = IProtocolDataProvider(AAVE_DATA_PROVIDER).getReserveTokensAddresses(_asset);
        // Assign the address of debtAsset based on the interest rate mode (1 = Stable / 2 = Variable)
        IERC20 debtAsset = _interestRateMode == 1 ? IStableDebtToken(sDebtTokenAddr) : IVariableDebtToken(vDebtTokenAddr);  

        // Assign and check the amount approved for delegation
        uint256 amount = debtAsset.borrowAllowance(msg.sender, address(this));
        require(amount > 0, "Amount approved for delegation is 0");

        // Borrow amount of asset on behalf of msg.sender
        ILendingPool(AAVE_LENDING_POOL).borrow(_asset, amount, _interestRateMode, 0, msg.sender);

        // Here, deposit to Beefy 
    }

    function requestDebtRepayment(_asset, _interestRateMode) external {
        // Check correctness of interest rate mode parameter
        require(_interestRateMode == 1 || _interestRateMode == 2, "Incorrect Interest Rate Mode");

        // Get the address of debt tokens
        (, address sDebtTokenAddr, address vDebtTokenAddr) = IProtocolDataProvider(AAVE_DATA_PROVIDER).getReserveTokensAddresses(_asset);
        // Assign the address of debtAsset based on the interest rate mode (1 = Stable / 2 = Variable)
        IERC20 debtAsset = _interestRateMode == 1 ? IStableDebtToken(sDebtTokenAddr) : IVariableDebtToken(vDebtTokenAddr);

        // Here, withdraw from Beefy

        debtAsset.approve(AAVE_LENDING_POOL, amount);
        // Repay the amount of asset on behalf of msg.sender
        ILendingPool(AAVE_LENDING_POOL).repay(_asset, amount, _interestRateMode, msg.sender);

    }
}