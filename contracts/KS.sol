pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KarrotStaking {
    IERC20 public stakingToken;
    IERC20 public rewardsToken;

    uint256 public rewardRate;  // rewards per second
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address _stakingToken, address _rewardsToken, uint256 _rewardRate) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        rewardRate = _rewardRate;
    }

    function stake(uint256 amount) external {
        updateReward(msg.sender);
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Stake failed");
    }

    function withdraw(uint256 amount) external {
        updateReward(msg.sender);
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Withdraw failed");
    }

    function getReward() external {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        require(rewardsToken.transfer(msg.sender, reward), "Reward transfer failed");
    }

    function updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if(account != address(0)) {
            rewards[account] += earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    function rewardPerToken() public view returns(uint256) {
        if(_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((block.timestamp - lastUpdateTime) * rewardRate * 1e18 / _totalSupply);
    }

    function earned(address account) public view returns(uint256) {
        return (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18) + rewards[account];
    }
}
