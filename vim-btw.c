#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <discord_rpc.h>

#define APP_ID "xxxxxxxxxxx" // Replace with your Discord Application ID

void handle_ready(const DiscordUser* user) {
    printf("Connected to Discord as %s#%s\n", user->username, user->discriminator);
}

void handle_disconnected(int errorCode, const char* message) {
    printf("Disconnected: %d - %s\n", errorCode, message);
}

void handle_error(int errorCode, const char* message) {
    printf("Error: %d - %s\n", errorCode, message);
}

void init_discord() {
    DiscordEventHandlers handlers;
    memset(&handlers, 0, sizeof(handlers));
    handlers.ready = handle_ready;
    handlers.disconnected = handle_disconnected;
    handlers.errored = handle_error;

    Discord_Initialize(APP_ID, &handlers, 1, "com.mikey.vimbtw");
}

int is_vim_running() {
    FILE *fp = popen("pgrep -x vim", "r");
    if (!fp) return 0;
    char buffer[16];
    int running = fread(buffer, 1, sizeof(buffer), fp) > 0;
    pclose(fp);
    return running;
}

void get_vim_file(char *filename, size_t size) {
    FILE *fp = popen("lsof -c vim | grep REG | awk '{print $9}' | grep '\\.swp$' | tail -1", "r");
    if (!fp) {
        strncpy(filename, "Unknown File", size);
        return;
    }

    char swp_path[512];
    if (fgets(swp_path, sizeof(swp_path), fp) != NULL) {
        swp_path[strcspn(swp_path, "\n")] = 0; // Remove newline
        pclose(fp);

        // Convert "/path/.file.swp" to "file"
        char *basename = strrchr(swp_path, '/'); // Get last "/" in the path
        if (basename) {
            basename++; // Move past "/"
            if (basename[0] == '.') basename++; // Remove leading "."

            char *ext = strstr(basename, ".swp"); // Find ".swp"
            if (ext) *ext = '\0'; // Remove ".swp"

            strncpy(filename, basename, size); // Copy to output
        } else {
            strncpy(filename, "Unknown File", size);
        }
    } else {
        strncpy(filename, "Unknown File", size);
        pclose(fp);
    }
}

void update_presence() {
    DiscordRichPresence presence;
    memset(&presence, 0, sizeof(presence));

    if (is_vim_running()) {
        char filename[256] = "Unknown File";
        get_vim_file(filename, sizeof(filename));
        presence.details = "Editing in Vim";
        presence.state = filename;
    } else {
        presence.details = "Using Terminal";
        presence.state = "Idle";
    }

    presence.largeImageKey = "terminal";
    presence.largeImageText = "macOS Terminal";
    presence.startTimestamp = time(NULL);
    Discord_UpdatePresence(&presence);
}

int main() {
    init_discord();

    while (1) {
        update_presence();
        sleep(10);  // Update every 10 seconds
    }

    Discord_Shutdown();
    return 0;
}

