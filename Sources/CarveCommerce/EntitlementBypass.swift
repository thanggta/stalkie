// Sources/CarveCommerce/EntitlementBypass.swift
// Developer shortcuts exist only in DEBUG. Release builds compile the
// grant path out — launch arguments cannot unlock a paid case.

import Foundation

public enum EntitlementBypass {
  public static let unlockAllFlag = "-unlockAllCases"

  /// True only when compiled DEBUG *and* the flag is present.
  /// Release always returns false, even if the argument is supplied.
  public static func requested(arguments: [String]) -> Bool {
    #if DEBUG
    return arguments.contains(unlockAllFlag)
    #else
    return false
    #endif
  }
}
