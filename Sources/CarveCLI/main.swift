// Sources/CarveCLI/main.swift
import CarveCLILib
import Foundation

exit(CLIRunner.run(arguments: Array(CommandLine.arguments.dropFirst())))
