//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakePeriodProvider {
    event PeriodCreated(uint256 pid, uint256 duration, uint32 allocPoint);
    event PeriodUpdated(uint256 pid, uint256 allocPoint);
    event PeriodMetaSet(
        uint256 pid,
        bool hasMeta,
        uint32 minUnlockPercent,
        uint32 unlockIfTimeLeft
    );

    struct Period {
        uint32 allocPoint;
        uint256 duration;
    }

    struct Metadata {
        uint32 minUnlockPercent; // can withdraw if locked up for % of time
        uint32 unlockIfTimeLeft; // can withdraw if time to locked remain of time
    }

    function countPeriods() external view returns (uint256);

    function allPeriods(uint256 pid)
        external
        view
        returns (
            uint32 allocPoint,
            uint256 duration,
            bool hasMeta,
            uint32 minUnlockPercent,
            uint32 unlockIfTimeLeft
        );

    function byDuration(uint256 duration_)
        external
        view
        returns (
            uint256 pid,
            uint32 allocPoint,
            uint256 duration,
            bool hasMeta,
            uint32 minUnlockPercent,
            uint32 unlockIfTimeLeft
        );

    function byDurationPeriod(uint256 duration_)
        external
        view
        returns (
            uint256 pid,
            uint32 allocPoint,
            uint256 duration
        );

    function calcUnlockTime(uint256 pid, uint256 start)
        external
        view
        returns (uint256 unlockTime, uint256 minUnlockTime);

    function calcUnlockTimeByDuration(uint256 duration_, uint256 start)
        external
        view
        returns (uint256 unlockTime, uint256 minUnlockTime);

    /**
     * Emit PeriodCreated event
     */
    function createPeriod(uint256 duration, uint32 allocPoint) external returns (uint256 pid);

    /**
     * Emit PeriodUpdated event
     */
    function updatePeriod(uint256 pid, uint32 allocPoint) external;

    /**
     * Emit PeriodMetaSet event
     */
    function setPeriodMeta(
        uint256 pid,
        uint32 minUnlockPercent,
        uint32 unlockIfTimeLeft
    ) external;
}
