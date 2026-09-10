#  🟢 macOS GitHub Contributions Widget

I wanted a native GitHub contribution grid on my Mac desktop wallpaper without having to run a heavy third-party app or a browser wrapper in the background. So, I built this! 

It's a fully native macOS desktop widget written in **SwiftUI** and **WidgetKit** that displays your contribution calendar grid in clean, official GitHub dark mode styling. 

> [!NOTE]  
> **This project is strictly for personal practice and coding fun.** It is not for any college submissions, academic grades, or portfolio padding—just direct hands-on practice learning macOS system widget coordination, App Group containers, and Swift networking.

---

## What it does

*   **Native Desktop Grid:** Drag, drop, and place your GitHub contribution grid directly on your Mac desktop wallpaper (natively supported in macOS Sonoma/Sequoia).
*   **Automatic & Manual Sync:** Automatically pulls new data every 15 minutes in the background, or updates instantly when you click "Save" in the configurator app.
*   **Custom Color Themes:** Switch between standard GitHub Greens, Aurora Cyans, Sunset Oranges, or minimalist Graphite Grays in the configurator app.
*   **Token-Free Public Mode:** Runs instantly by scraping public profile data (zero configuration required).
*   **Authenticated GraphQL Mode (Optional):** Add a GitHub Personal Access Token (PAT) to track private contributions.
*   **PR Review Queue (Optional):** If you use a token and drag out the **Large** size widget, it displays active PR review requests at the bottom so you know when someone is waiting on you.

---

## 🛠️ How to run it on your Mac

Since it's a native macOS app compiled with developer certificates, you'll need Xcode (free on the Mac App Store) to build it locally.

### 1. Generate the Xcode project
We use `xcodegen` to keep the repo clean. Install it via Homebrew and generate the project file:
```bash
brew install xcodegen
xcodegen generate
```
This outputs `GitHubTahoeApp.xcodeproj`.

### 2. Configure Code Signing & App Groups in Xcode
Because widgets share data with a host configurator app, macOS requires them to be signed under the same developer team:
1. Open `GitHubTahoeApp.xcodeproj` in Xcode.
2. Select the blue **GitHubTahoeApp** project at the top of the left sidebar.
3. Click the **Signing & Capabilities** tab in the center panel.
4. Under **TARGETS** on the left:
    * Select **GitHubTahoeApp** and choose your personal Apple ID name in the **Team** dropdown.
    * Select **GitHubTahoeWidget** and choose the exact same **Team** in the dropdown.
5. Xcode will automatically resolve the provisioning profiles, and the red warnings will turn green.

### 3. Build and Run!
1. Set the target scheme at the top of Xcode (next to the Play button) to **`GitHubTahoeApp`**.
2. Press **Play** (`Cmd + R`) to compile and run.
3. The configuration app window will open. Type in your GitHub username, paste an optional token, choose your theme color, and click **Save & Apply**.
4. Close the configurator app.

### 4. Add the Widget to your Wallpaper
1. Right-click your desktop wallpaper and select **"Edit Widgets..."** (or open the Notification Center and click "Edit Widgets").
2. Search for **"GitHub Contributions Widget"**.
3. Choose your size:
    * **Small:** Quick stats and current streak.
    * **Medium:** Simple and sleek 1-year contribution grid (looks exactly like the GitHub profile chart!).
    * **Large:** Full stats row, 1-year grid, and active pull requests tracking.
4. Drag it onto your desktop!

---

## 📂 Code Layout

*   `project.yml` - Project setup file for XcodeGen.
*   `GitHubTahoeApp/` - Host settings app to save usernames, PATs, and colors.
*   `GitHubTahoeWidget/` - The extension that renders the widget views and manages background timeline intervals.
*   `GitHubTahoeApp.entitlements` / `GitHubTahoeWidget.entitlements` - System capability configurations enabling sandbox network access and shared App Group containers.

---

## 👥 Contributors & Acknowledgments

* **[Suryansh Saraf](https://github.com/Suryanshsaraf)** — Creator & Developer
* **Claude** (`noreply@anthropic.com`) — AI Pair Programmer (WidgetKit lifecycle debugging, App Group IPC cache coordination, and architecture fixes)

