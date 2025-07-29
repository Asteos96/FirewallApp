# 📝 Description
An AHK script for GTA Online that allows you to temporarily block the connection to Rockstar servers (by blocking ports) or suspend the game process.

# 📷 Screenshots
<img width="200" height="330" src="https://github.com/user-attachments/assets/855b4b5a-d2df-46fa-b6dc-8ad07d70595e" />
&nbsp;&nbsp;
<img width="200" height="330" src="https://github.com/user-attachments/assets/3fbf2479-c3eb-4279-b3b6-b35157cbb0a5" />
&nbsp;&nbsp;
<img width="200" height="330" src="https://github.com/user-attachments/assets/ed4d42ea-42cf-4336-bb93-4becc1429c07" />

# 📚 Use Cases
### 🔁 Fast Heist Restarts
Specify port `80` in `Advanced Settings > FW Ports`. Fast restarts are useful when completing Elite Challenges or speedrunning.
- On the heist restart screen, enable the Firewall using the assigned hotkey and vote to restart — `PgUp`.
- Disable the Firewall once you see the black popup message in the top-left corner. If AutoFW is enabled (in the main window), the script will disable the Firewall automatically.
- You will return to the session, while the host will be placed back in the Heist Planning Room.
> If AutoFW doesn't work correctly, try adjusting the delay in `Advanced Settings > AutoFW Delay`. Decrease the delay if you're kicked to the Main Menu after the restart, or increase it if the Firewall disables too early.

### 💾 Saving a Heist Finale
To save the finale and prevent the host from receiving any money, specify ports `80, 443` in `Advanced Settings > FW Ports`. If you want the host to receive "dirty" money from the finale, block only port `80`
- Enable the Firewall before triggering the final checkpoint of the heist.
- On the results screen, an error will appear. Press `Alt+F4` to close the game.
- Disable the Firewall and start the game.
> For OG Heists: if you save the finale and later join a session or job with players who were not part of that heist, the saved finale may be lost.

### 🔌 Fully Disconnecting from Rockstar Servers
Set `FW Ports` to `All`, or leave the field empty. A full disconnection can be useful for preserving a CMM progress if a player dies.
- Enable the Firewall as soon as any player dies.
- Press `Alt+F4` to exit the game.
- Disable the Firewall and start the game.
> Only the player who used Firewall have a chance to keep their CMM progress. This does not affect the entire group.

### ⌛ Fixing Infinite Loading Screens
- Suspend the game process.
- Resume it after 10 seconds by pressing the hotkey again, or configure an auto-resume timer under `Advanced Settings > Suspend Timeout`.

### ⚡ Dealing with High Ping Issues
High ping between players during heists can cause issues such as stuck vehicles or frozen animations. Pausing the game process for a 5 seconds may help.
- Suspend the game process.
- Resume it after 5 seconds by pressing the hotkey again, or configure an auto-resume timer under `Advanced Settings > Suspend Timeout`.
