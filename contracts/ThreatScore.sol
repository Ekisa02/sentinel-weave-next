// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title ThreatScore - Simple on-chain scoring utility
/// @notice Pure library computing a normalized risk score from severity, confirmations and age
library ThreatScore {
    /// @notice Compute a score on a 0-100 scale
    /// @param severity 0-10 (higher is more severe)
    /// @param confirmations number of independent confirmations (capped)
    /// @param ageSeconds age since report in seconds (used for decay)
    function compute(uint8 severity, uint8 confirmations, uint256 ageSeconds) internal pure returns (uint8) {
        // Normalize severity to 0-70 (severity weight is primary)
        uint256 sev = uint256(severity);
        if (sev > 10) {
            sev = 10;
        }
        uint256 sevScore = (sev * 7); // 0..70

        // confirmations add up to 20 points, 5 points per confirmation, capped at 4 confirmations
        uint256 conf = uint256(confirmations);
        if (conf > 4) conf = 4;
        uint256 confScore = conf * 5; // 0..20

        // age decay: every 7 days reduces up to 10 points
        uint256 weeksOld = ageSeconds / 1 weeks;
        uint256 decay = weeksOld * 2; // 2 points per week up to 10
        if (decay > 10) decay = 10;

        uint256 raw = sevScore + confScore;
        if (raw + 0 < decay) {
            return 0;
        }
        uint256 finalScore = raw > decay ? raw - decay : 0;
        if (finalScore > 100) finalScore = 100;
        return uint8(finalScore);
    }
}
