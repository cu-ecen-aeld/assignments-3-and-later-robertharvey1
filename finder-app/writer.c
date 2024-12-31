#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

void log_message(int priority, const char *message) {
    syslog(priority, "%s", message);
}

int main(int argc, char *argv[]) {
    // Check command line arguments
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <file> <string>\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *filename = argv[1];
    const char *text = argv[2];

    // Open syslog
    openlog("writer", LOG_PID | LOG_CONS, LOG_USER);

    // Write to file
    FILE *file = fopen(filename, "a");  // Use "a" to append to the file
    if (file == NULL) {
        log_message(LOG_ERR, "Failed to open file");
        perror("Error opening file");
        return EXIT_FAILURE;
    }

    // Write the string to the file
    if (fprintf(file, "%s\n", text) < 0) {
        log_message(LOG_ERR, "Failed to write to file");
        perror("Error writing to file");
        fclose(file);
        return EXIT_FAILURE;
    }

    // Log successful write
    char log_buffer[256];
    snprintf(log_buffer, sizeof(log_buffer), "Writing \"%s\" to \"%s\"", text, filename);
    log_message(LOG_DEBUG, log_buffer);

    // Close the file and syslog
    fclose(file);
    closelog();

    return EXIT_SUCCESS;
}