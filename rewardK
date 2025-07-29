// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GamifiedKarrotStaking is Ownable {
    IERC20 public stakingToken;    // Token to stake
    IERC20 public rewardsToken;    // Token rewarded (Karrot)

    uint256 public rewardRate;     // Karrot tokens per second per staked token (scaled)
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // Gamified elements
    mapping(address => uint256) public xp;       // Experience Points
    mapping(address => uint256) public level;    // Level derived from xp
    uint256 public constant XP_PER_SECOND_PER_TOKEN = 1; // Base XP per second per token staked

    // Level thresholds (can tune as you see fit)
    uint256[] public levels = [0, 1000, 5000, 15000, 35000, 70000];

    // Leaderboard (top stakers by balance, simplified, you can extend off-chain)
    address[] public leaderboard;

    // Emergency withdrawal penalty (10%)
    uint256 public constant EMERGENCY_PENALTY = 10;

    // Pause mechanism
    bool public paused;

    // EVENTS
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event LevelUp(address indexed user, uint256 newLevel);
    event EmergencyWithdraw(address indexed user, uint256 amountAfterPenalty);

    constructor(
        address _stakingToken,
        address _rewardsToken,
        uint256 _rewardRate
    ) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        rewardRate = _rewardRate;
        lastUpdateTime = block.timestamp;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // STAKE tokens
    function stake(uint256 amount) external notPaused {
        require(amount > 0, "Cannot stake zero");
        updateReward(msg.sender);

        _totalSupply += amount;
        _balances[msg.sender] += amount;

        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Stake failed");

        _tryUpdateLevel(msg.sender);

        emit Staked(msg.sender, amount);
    }

    // WITHDRAW staked tokens
    function withdraw(uint256 amount) public notPaused {
        require(amount > 0, "Cannot withdraw zero");
        require(_balances[msg.sender] >= amount, "Withdraw exceeds balance");
        updateReward(msg.sender);

        _totalSupply -= amount;
        _balances[msg.sender] -= amount;

        require(stakingToken.transfer(msg.sender, amount), "Withdraw failed");

        _tryUpdateLevel(msg.sender);

        emit Withdrawn(msg.sender, amount);
    }

    // CLAIM rewards
    function getReward() public notPaused {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards");

        rewards[msg.sender] = 0;

        require(rewardsToken.transfer(msg.sender, reward), "Reward transfer failed");

        emit RewardPaid(msg.sender, reward);
    }

    // EMERGENCY WITHDRAW - withdraw without rewards, lose 10% penalty
    function emergencyWithdraw() external {
        uint256 balance = _balances[msg.sender];
        require(balance > 0, "Nothing to withdraw");

        _totalSupply -= balance;
        _balances[msg.sender] = 0;
        rewards[msg.sender] = 0; // Lose pending rewards

        uint256 penalty = (balance * EMERGENCY_PENALTY) / 100;
        uint256 amountAfterPenalty = balance - penalty;

        // Transfer back tokens after penalty
        require(stakingToken.transfer(msg.sender, amountAfterPenalty), "Emergency withdraw failed");

        // Penalty stays in contract as a game "tax"
        emit EmergencyWithdraw(msg.sender, amountAfterPenalty);

        _tryUpdateLevel(msg.sender);
    }

    // VIEW functions
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Calculate reward per token incorporating level multipliers
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) return rewardPerTokenStored;

        // Calculate base reward per token accumulated since last update
        uint256 base = rewardPerTokenStored + ((block.timestamp - lastUpdateTime) * rewardRate * 1e18 / _totalSupply);

        return base;
    }

    // Calculate how much reward a user has earned including level bonus multiplier
    function earned(address account) public view returns (uint256) {
        uint256 baseEarned = (_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + rewards[account];
        uint256 multiplier = 100 + (level[account] * 10); // Each level adds 10% bonus reward
        return (baseEarned * multiplier) / 100;
    }

    // Internal reward update
    function updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
            _tryAddToLeaderboard(account);
        }
    }

    // XP and leveling system:
    function _tryUpdateLevel(address user) internal {
        // Increase XP by staked tokens * time elapsed * XP_PER_SECOND_PER_TOKEN
        // For simplicity, here we grant XP based on current time snapshot. Complex time tracking requires per-user staking time.
        // You can expand this with timestamps of stake/unstake for precision.
        uint256 userXP = xp[user];
        uint256 currentLevel = level[user];

        // Simple heuristic: XP proportional to balance * time since last update (done in updateReward)
        // Here we'll simulate XP increase from rewards for demonstration
        if (rewards[user] > 0) {
            xp[user] += rewards[user] / 1e18; // scale down to XP points
        }

        for (uint256 i = levels.length - 1; i > currentLevel; i--) {
            if (xp[user] >= levels[i]) {
                level[user] = i;
                emit LevelUp(user, i);
                break;
            }
        }
    }

    // Simplified leaderboard adding addresses who have nonzero stake
    function _tryAddToLeaderboard(address user) internal {
        if (_balances[user] > 0) {
            bool found = false;
            for (uint256 i = 0; i < leaderboard.length; i++) {
                if (leaderboard[i] == user) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                leaderboard.push(user);
                // You can add sorting logic by stake amount off-chain or extend here (gas-heavy)
            }
        }
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    // Allow owner to set reward rate (to tune yield)
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        updateReward(address(0)); // update global state before changing rate
        rewardRate = _rewardRate;
    }

    // Get user's current level and XP
    function getUserStats(address user) external view returns (uint256 userXP, uint256 userLevel) {
        return (xp[user], level[user]);
    }

    // Get leaderboard addresses (simplified)
    function getLeaderboard() external view returns (address[] memory) {
        return leaderboard;
    }
}
