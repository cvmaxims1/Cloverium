//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolVoting {
    event AddVoting(address indexed user, address indexed exchange, uint256 amount);
    event RemoveVoting(address indexed user, address indexed exchange, uint256 amount);

    /**
     * @dev return max allowed voting pools
     */
    function maxPoolVotes() external view returns (uint8);

    /**
     * @dev update max pool vote for single user
     */
    function setMaxPoolVotes(uint8 maxPool) external;

    /**
     * @dev return total of vote for all LP
     */
    function totalVotes() external view returns (uint256);

    /**
     * @dev Return total number of vote per LP
     */
    function poolVotes(address exchange) external view returns (uint256);

    /**
     * @dev return total votes by user
     */
    function userVotes(address user) external view returns (uint256);

    /**
     * @dev return remaining votes owned by user
     */
    function userRemainVotes(address user) external view returns (uint256);

    /**
     * @dev Return total number of voted LP by user
     */
    function userVotingLPCount(address user) external view returns (uint256);

    /**
     * @dev return total of vote for LP by user
     */
    function userPoolVotes(address user, address exchange) external view returns (uint256);

    /**
     * @dev return LP address at index
     */
    function userVotingPoolAddress(address user, uint256 lpIndex) external view returns (address);

    /**
     * @dev return total of vote for LP at index
     */
    function userVotingPoolAmount(address user, uint256 lpIndex) external view returns (uint256);

    /**
     * @dev add voting for LP
     * Requirements:
     * - LP exists
     * - User has enough vote left
     * emit AddVoting
     */
    function addVoting(address exchange, uint256 amount) external;

    /**
     * @dev remove voting for LP
     * Requirements:
     * - LP exists
     * emit RemoveVoting
     */
    function removeVoting(address exchange, uint256 amount) external;

    /**
     * @dev remove all voting for LP
     * emit RemoveVoting
     */
    function removeAllVoting() external;
}
