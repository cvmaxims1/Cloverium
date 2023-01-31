//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/staking/IStakePeriodProvider.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakePeriodProvider is IStakePeriodProvider, Ownable {
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 100000; // 00.000

    Period[] internal _allPeriods;
    mapping(uint256 => uint256) internal _durations;
    mapping(uint256 => bool) internal _hasMeta;
    mapping(uint256 => Metadata) internal _metadata;

    function countPeriods() external view override returns (uint256) {
        return _allPeriods.length;
    }

    function allPeriods(uint256 pid)
        public
        view
        override
        returns (
            uint32 allocPoint,
            uint256 duration,
            bool hasMeta,
            uint32 minUnlockPercent,
            uint32 unlockIfTimeLeft
        )
    {
        Period storage program = _allPeriods[pid];
        allocPoint = program.allocPoint;
        duration = program.duration;
        hasMeta = _hasMeta[pid];
        if (hasMeta) {
            Metadata storage meta = _metadata[pid];
            minUnlockPercent = meta.minUnlockPercent;
            unlockIfTimeLeft = meta.unlockIfTimeLeft;
        }
    }

    function byDuration(uint256 duration_)
        external
        view
        override
        returns (
            uint256 pid,
            uint32 allocPoint,
            uint256 duration,
            bool hasMeta,
            uint32 minUnlockPercent,
            uint32 unlockIfTimeLeft
        )
    {
        pid = _durations[duration_].sub(1);
        (allocPoint, duration, hasMeta, minUnlockPercent, unlockIfTimeLeft) = allPeriods(pid);
    }

    function byDurationPeriod(uint256 duration_)
        external
        view
        override
        returns (
            uint256 pid,
            uint32 allocPoint,
            uint256 duration
        )
    {
        pid = _durations[duration_].sub(1);
        Period storage program = _allPeriods[pid];
        allocPoint = program.allocPoint;
        duration = program.duration;
    }

    function calcUnlockTime(uint256 pid, uint256 start)
        public
        view
        override
        returns (uint256 unlockTime, uint256 minUnlockTime)
    {
        (
            ,
            uint256 duration,
            bool hasMeta,
            uint32 minUnlockPercent,
            uint32 unlockIfTimeLeft
        ) = allPeriods(pid);
        unlockTime = start.add(duration);
        if (hasMeta) {
            if (minUnlockPercent > 0) {
                minUnlockTime = start.add(duration.mul(minUnlockPercent).div(ONE_HUNDRED_PERCENT));
            } else {
                minUnlockTime = start.add(duration.sub(unlockIfTimeLeft));
            }
        } else {
            minUnlockTime = unlockTime;
        }
    }

    function calcUnlockTimeByDuration(uint256 duration_, uint256 start)
        external
        view
        override
        returns (uint256 unlockTime, uint256 minUnlockTime)
    {
        uint256 pid = _durations[duration_].sub(1);
        (unlockTime, minUnlockTime) = calcUnlockTime(pid, start);
    }

    /**
     * Emit ProgramCreated event
     */
    function createPeriod(uint256 duration, uint32 allocPoint)
        external
        override
        onlyOwner
        returns (uint256 pid)
    {
        require(duration > 0, "INV_DURATION");
        require(allocPoint > 0, "INV_ALLOC_POINT");
        require(_durations[duration] == 0, "INV_EXIST");

        pid = _allPeriods.length;
        Period memory prog;
        prog.duration = duration;
        prog.allocPoint = allocPoint;

        _allPeriods.push(prog);
        // hack by store non zero pid
        _durations[duration] = pid + 1;
        emit PeriodCreated(pid, duration, allocPoint);
    }

    /**
     * Emit ProgramUpdated event
     */
    function updatePeriod(uint256 pid, uint32 allocPoint) external override onlyOwner {
        require(allocPoint > 0, "INV_ALLOC_POINT");
        require(_exist(pid), "INV_NO_EXIST");
        Period storage program = _allPeriods[pid];
        program.allocPoint = allocPoint;
        emit PeriodUpdated(pid, allocPoint);
    }

    /**
     * Emit ProgramMetaSet event
     */
    function setPeriodMeta(
        uint256 pid,
        uint32 minUnlockPercent,
        uint32 unlockIfTimeLeft
    ) external override onlyOwner {
        require(_exist(pid), "INV_NO_EXIST");
        if (minUnlockPercent == 0 && unlockIfTimeLeft == 0) {
            delete _metadata[pid];
            _hasMeta[pid] = false;
            emit PeriodMetaSet(pid, false, 0, 0);
        } else {
            Period memory period = _allPeriods[pid];
            require(period.duration > unlockIfTimeLeft, "INV_DELAY");
            require(minUnlockPercent < ONE_HUNDRED_PERCENT, "INV_PERCENT");

            Metadata storage meta = _metadata[pid];
            meta.unlockIfTimeLeft = unlockIfTimeLeft;
            meta.minUnlockPercent = minUnlockPercent;
            _hasMeta[pid] = true;
            emit PeriodMetaSet(pid, true, minUnlockPercent, unlockIfTimeLeft);
        }
    }

    function _exist(uint256 pid) internal view returns (bool) {
        return pid < _allPeriods.length;
    }
}
