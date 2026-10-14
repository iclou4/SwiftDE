/* swiftde-checkpw — verify the INVOKING user's own password via PAM.
 * Installed setuid root (4755): pam_unix needs /etc/shadow access.
 * Usage: echo <password> | swiftde-checkpw <username>
 * Exits 0 on success, 1 on bad password, 2 on misuse. Only allows
 * checking the caller's own account (getuid), never other users. */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <pwd.h>
#include <security/pam_appl.h>

static char pwbuf[512];

static int convfn(int nmsg, const struct pam_message **msgs,
                  struct pam_response **resps, void *data) {
    (void)data;
    struct pam_response *r = calloc(nmsg, sizeof *r);
    if (!r)
        return PAM_BUF_ERR;
    for (int i = 0; i < nmsg; i++) {
        if (msgs[i]->msg_style == PAM_PROMPT_ECHO_OFF) {
            r[i].resp = strdup(pwbuf);
            if (!r[i].resp) {
                free(r);
                return PAM_BUF_ERR;
            }
        }
    }
    *resps = r;
    return PAM_SUCCESS;
}

int main(int argc, char **argv) {
    if (argc != 2)
        return 2;
    struct passwd *me = getpwuid(getuid());
    if (!me || strcmp(me->pw_name, argv[1]) != 0)
        return 2;
    if (!fgets(pwbuf, sizeof pwbuf, stdin))
        return 1;
    pwbuf[strcspn(pwbuf, "\r\n")] = 0;

    struct pam_conv conv = { convfn, NULL };
    pam_handle_t *h = NULL;
    if (pam_start("login", argv[1], &conv, &h) != PAM_SUCCESS) {
        explicit_bzero(pwbuf, sizeof pwbuf);
        return 1;
    }
    int rc = pam_authenticate(h, 0);
    pam_end(h, rc);
    explicit_bzero(pwbuf, sizeof pwbuf);
    return rc == PAM_SUCCESS ? 0 : 1;
}
