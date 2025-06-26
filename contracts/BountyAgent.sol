// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./BountyNFT.sol";

contract BountyAgent is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Bounty {
        address creator;
        uint256 prize;
        uint256 entryFee;
        uint32 maxWinners;
        uint256 deadline;
        bool settled;
        bool canceled;
        string topic;
        string description;
    }

    struct Submission {
        address contributor;
        string cid;
    }

    uint256 public bountyCount;
    mapping(uint256 => Bounty) public bounties;
    mapping(uint256 => Submission[]) public submissions;
    mapping(uint256 => mapping(address => uint256)) public feesPaid;

    BountyNFT public nftContract;
    IERC20 public usdc;
    uint256 public platformFeeBps = 500;

    event BountyCreated(uint256 indexed id, address creator, uint256 prize);
    event SubmissionPaid(uint256 indexed id, address contributor, string cid);
    event PrizesDistributed(uint256 indexed id, uint256[] winnerIndexes);
    event BountyCanceled(uint256 indexed id);
    event PlatformFeeUpdated(uint256 oldBps, uint256 newBps);

    constructor(address _nftAddress, address _usdcAddress) Ownable(msg.sender) {
        nftContract = BountyNFT(_nftAddress);
        usdc = IERC20(_usdcAddress);
    }

    function setPlatformFee(uint256 _bps) external onlyOwner {
        require(_bps <= 1000, "Max fee 10%");
        emit PlatformFeeUpdated(platformFeeBps, _bps);
        platformFeeBps = _bps;
    }

    function createBounty(
        uint256 _prize,
        uint256 _entryFee,
        uint32 _maxWinners,
        uint256 _deadline,
        string memory _topic,
        string memory _description
    ) external {
        require(_prize > 0, "Prize must be > 0");
        require(_deadline > block.timestamp, "Deadline must be future");
        require(
            usdc.allowance(msg.sender, address(this)) >= _prize,
            "Insufficient allowance for prize"
        );

        usdc.transferFrom(msg.sender, address(this), _prize);

        bountyCount++;
        bounties[bountyCount] = Bounty(
            msg.sender,
            _prize,
            _entryFee,
            _maxWinners,
            _deadline,
            false,
            false,
            _topic,
            _description
        );

        emit BountyCreated(bountyCount, msg.sender, _prize);
    }

    function submitWork(
        uint256 _bountyId,
        string calldata _cid
    ) external nonReentrant {
        Bounty storage b = bounties[_bountyId];
        require(!b.settled && !b.canceled, "Bounty closed");
        require(block.timestamp < b.deadline, "Deadline passed");
        require(feesPaid[_bountyId][msg.sender] == 0, "Already submitted");

        usdc.transferFrom(msg.sender, address(this), b.entryFee);
        feesPaid[_bountyId][msg.sender] = b.entryFee;

        submissions[_bountyId].push(
            Submission({contributor: msg.sender, cid: _cid})
        );

        emit SubmissionPaid(_bountyId, msg.sender, _cid);
    }

    function distributePrizes(
        uint256 _bountyId,
        uint256[] calldata winnerIndexes
    ) external nonReentrant {
        Bounty storage b = bounties[_bountyId];
        require(msg.sender == b.creator, "Only creator");
        require(block.timestamp >= b.deadline, "Too early");
        require(!b.settled && !b.canceled, "Already settled");
        require(
            winnerIndexes.length > 0 && winnerIndexes.length <= b.maxWinners,
            "Invalid winners"
        );

        uint256 totalPrize = b.prize;
        uint256 fee = (totalPrize * platformFeeBps) / 10000;
        uint256 payoutPerWinner = (totalPrize - fee) / winnerIndexes.length;

        usdc.transfer(owner(), fee);

        uint256 cntSubs = submissions[_bountyId].length;
        bool[] memory isWinner = new bool[](cntSubs);

        for (uint i = 0; i < winnerIndexes.length; i++) {
            uint256 idx = winnerIndexes[i];
            require(idx < cntSubs, "Winner index OOB");
            isWinner[idx] = true;

            Submission memory s = submissions[_bountyId][winnerIndexes[i]];
            address winner = s.contributor;
            string memory cid = s.cid;

            usdc.transfer(winner, payoutPerWinner);
            nftContract.mint(winner, cid);
        }

        for (uint256 i = 0; i < cntSubs; i++) {
            if (!isWinner[i]) {
                address user = submissions[_bountyId][i].contributor;
                uint256 amt  = feesPaid[_bountyId][user];
                if (amt > 0) {
                    usdc.safeTransfer(user, amt);
                }
            }
        }

        b.settled = true;
        emit PrizesDistributed(_bountyId, winnerIndexes);
    }

    function cancelBounty(uint256 _bountyId) external nonReentrant {
        Bounty storage b = bounties[_bountyId];
        require(msg.sender == b.creator, "Only creator");
        require(!b.settled && !b.canceled, "Already closed");
        require(block.timestamp < b.deadline, "Too late to cancel");

        b.canceled = true;
        usdc.safeTransfer(b.creator, b.prize);

        emit BountyCanceled(_bountyId);
    }
}
