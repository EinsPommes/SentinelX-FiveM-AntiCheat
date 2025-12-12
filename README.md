# SentinelX - FiveM Anti-Cheat System

SentinelX is a comprehensive anti-cheat system designed for FiveM servers. It provides robust protection against various types of cheats and exploits that can ruin the gaming experience for legitimate players.

## What It Does

SentinelX monitors player behavior and detects common cheating methods including:

- Speed hacking detection - catches players moving faster than physically possible
- Health and armor modification detection - identifies players with modified health or armor values
- Weapon damage modification detection - detects altered weapon damage multipliers
- Resource integrity validation - ensures game resources haven't been tampered with
- Memory modification detection - catches attempts to modify game memory
- Unauthorized native function calls - monitors suspicious function usage
- Configurable warning and ban system - flexible punishment system that fits your server's needs

## Getting Started

Installing SentinelX is straightforward:

1. Download or clone this repository
2. Place the folder in your FiveM server's resources directory
3. Add `ensure SentinelX` to your server.cfg file
4. Configure the settings in `shared/config.lua` to match your server's needs

That's it. The system will start protecting your server once it's loaded.

## Configuration

All settings can be customized in `shared/config.lua`. Here's what you can adjust:

- Detection thresholds - fine-tune sensitivity for different cheat types
- Whitelisted resources and commands - allow trusted resources to bypass checks
- Punishment settings - configure warnings, kicks, and bans
- Debug options - enable detailed logging for troubleshooting

The configuration file is well-documented with comments explaining each setting. Take some time to review it and adjust values based on your server's specific needs.

## How It Works

SentinelX uses a multi-layered approach to detect cheating:

- Server-side validation handles critical actions that must be verified on the server
- Client-side integrity checks run continuously to catch modifications early
- Resource hash verification ensures game files haven't been altered
- Automated monitoring tracks player behavior patterns over time
- Staged punishment system escalates from warnings to bans based on violation frequency

The system is designed to minimize false positives while catching real cheaters. Most detection methods use configurable thresholds that you can adjust based on your server's gameplay style.

## Requirements

- FiveM server (obviously)
- MySQL database (optional but recommended for logging violations)
- screenshot-basic resource (optional, for screenshot evidence collection)

The system will work without MySQL, but violation logging will be disabled. For full functionality, install mysql-async or oxmysql.

## Contributing

Found a bug or have an idea for improvement? We'd love to hear from you. Please open an issue on GitHub with details about what you found or what you'd like to see added.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Getting Help

If you run into issues or have questions:

- Open an issue on GitHub with a detailed description of your problem
- Check the configuration file comments for common settings
- Review the server console for error messages (enable debug mode for more details)

Remember to check that your configuration matches your server setup, especially database connections and resource dependencies.
