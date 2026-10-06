
# Roblox Luau Shop & Persistence System

A modular, server-authoritative shop and data persistence framework built in Luau for Roblox Studio. 

Designed for scalability, security against client exploitation, and low latency network communication.

## Showcase
*(Insert a link to your showcase video or streamable recording here)*

## Architecture & Features

- **Server-Authoritative Validation:** All transactions (gold deduction, inventory checks, price lookup) are calculated and validated exclusively on the server to prevent client-side exploit manipulation.
- **Session Caching:** Player data is stored in memory (`PlayerDataCache`) upon join to avoid exceeding DataStore limits during frequent transactions.
- **Data Persistence:** Utilizes `DataStoreService` with fallback error handling (`pcall`), `PlayerRemoving` triggers, and `game:BindToClose` support for server shutdown safety.
- **Modular Design:** `ShopCatalog` module keeps item data decoupled from backend logic, allowing easy expansion without altering core code.
- **Dynamic Syncing:** `leaderstats` value tracking uses `.Changed` signals to dynamically mirror any external gold adjustments (e.g. coin pickups) directly into the session cache.

## Technical Details

- **Language:** Luau (`--!strict` typed)
- **Networking:** RemoteEvents (`ReplicatedStorage`)
- **Storage:** `DataStoreService`
