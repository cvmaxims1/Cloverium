//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEarlyUnlock {
    event UnstakeRequest(uint256 indexed stakeId, uint256 unlockTime);
    event UnstakeRequestCancel(uint256 indexed stakeId);
    event UnstakeRequestProceed(uint256 indexed stakeId, uint256 received);

    /**
     * @dev return current unstake lock period
     */
    function lockPeriod() external view returns (uint256);

    /**
     * @dev Set unstake request lock period
     */
    function setLockPeriod(uint32 period) external;

    /**
     * @dev return current penalty fee
     */
    function penaltyFee() external view returns (uint32);

    /**
     * @dev Set penalty fee when unstake before end time
     */
    function setPenaltyFee(uint32 fee) external;

    /**
     * @dev Wallet address send penalty fee to
     */
    function penaltyFeeTo() external view returns (address);

    /**
     * @dev Update early unlock fee to wallet
     */
    function setPenaltyFeeTo(address feeTo) external;

    /**
     * @dev Burn `stakeId` before stake end time
     * Requirements:
     * - `stakeId` must exists
     * - stakeId is not request for unstake
     * - sender must be owner of stakeId
     * Emits an {EarlyUnstakeRequest} event
     */
    function requestUnstake(uint256 stakeId) external;

    // --------- platform function ---------- //
    /**
     * @dev cancel early unstake request
     */
    function cancelUnstakeRequest(uint256 stakeId) external;

    /**
     * @dev process early unstake request
     */
    function processUnstakeRequest(uint256 stakeId) external;
}
