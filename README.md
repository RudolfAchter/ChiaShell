# A PowerShell CommandLine for Chia - ChiaShell

This is my attemnpt to automate Chia things with Powershell. I discovered the chia RPC API and i am astouned how easy it is for me to play around with it. Maybe it's also interesting for other chia people out there. So i'd like to share this as open source.

# Installation

You need openssl installed and available in PATH. For Windows look here:
- <https://medium.com/swlh/installing-openssl-on-windows-10-and-updating-path-80992e26f6a1>

Also on Windows you need [Powershell 7](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.2) for now. It should be backwards compatible to Powershell 5.1 but until now i cannot automatically get the necessary Client Certificates for RCP Connection on Powershell 5.1. Feel free to fork and make things better (come back with merge request 😉).

Clone this repository

put the Folder "ChiaShell" `Modules/ChiaShell` in your Powershell Module Directory

- `~/.local/share/powershell/Modules` on linux
- `%USERPROFILE%\Documents\WindowsPowershell\Modules` on windows

