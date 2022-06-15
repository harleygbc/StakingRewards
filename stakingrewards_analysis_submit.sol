//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

// Call IERC20 functionality
contract StakingRewards {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

// Declare storage variables used throughout all the contract
    uint public rewardRate = 100;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    // MAPPINGS
// Mappings are more efficient than gas expensive arrays. These mappings hold all of the stakeholders
    mapping(address=>uint) public userRewardPerTokenPaid;
    mapping(address=>uint) public rewards;
    mapping(address=>uint) private _balances;

    uint private _totalSupply;

    // CONSTRUCTOR
//Upon deployments then contract sets up the staking token and the reward to be issued to the user
    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    // MODIFIER
//Modifers are an efficient way of applying to functions when certian conditions are met. Here these update the state of our storage variables based on the functions below
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    // Functions
//These finctions define the core functionality available to the contract users
//
// This specifies the reward level issued per token based on staked time
    function rewardPerToken() public view returns(uint) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }
//This specifies how much rewqard has been earned
    function earned(address account) public view returns(uint) {
        return ((_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }
// This function allows the user to set the amount that they want to stake
// The amount is added to the total supply and leaves the user account.
// It also starts the 'clock' on the duration of time that the user has staked a token
    function stake(uint _amount) external updateReward(msg.sender) {
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }
// This removes the staked tokens and returns it to the users available balance 
    function withdraw(uint _amount) external updateReward(msg.sender) {
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;       
        stakingToken.transfer(msg.sender, _amount);
    }
// This transfers the rewards earned while staking and and sent to the person performing the staking
// The external modifier allows this to be called from external smart contracts
    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
    }
}

interface IERC20 {
    function totalSupply() external view returns(uint);
    function balanceOf(address account) external view returns(uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns(uint);
    function approve(address spender, uint amount) external returns(bool);
    function transferFrom(address spender, address recipient, uint amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}