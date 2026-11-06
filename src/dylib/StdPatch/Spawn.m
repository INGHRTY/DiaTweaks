#import "StdPatch/StdPatch.h"
#include <spawn.h>

// A patch that needs to change how Dia starts a helper process registers a rewrite here. diapatch starts Dia, so there
// is one interposer for posix_spawn and patches add to it instead of interposing on their own, which dyld keeps to one.
static DPSpawnRewrite *DPRewrites;
static size_t DPRewriteCount;

void DPOnSpawn(DPSpawnRewrite rewrite) {
    DPRewrites = realloc(DPRewrites, ++DPRewriteCount * sizeof *DPRewrites);
    DPRewrites[DPRewriteCount - 1] = rewrite;
}

static int DPSpawnHook(pid_t *pid, const char *path, const posix_spawn_file_actions_t *files, const posix_spawnattr_t *attrs,
                       char *const argv[], char *const envp[]) {
    int argc = 0;
    while (argv[argc]) argc++;
    char *arguments[argc + 1];
    memcpy(arguments, argv, (argc + 1) * sizeof *argv);
    DPSpawn spawn = { path, arguments, (char **)envp };
    for (size_t i = 0; i < DPRewriteCount; i++) DPRewrites[i](&spawn);
    return posix_spawn(pid, spawn.path, files, attrs, spawn.argv, spawn.env);
}

__attribute__((used, section("__DATA,__interpose"))) static const struct { const void *replacement, *replacee; } DPInterposeSpawn = {
    (const void *)DPSpawnHook, (const void *)posix_spawn
};

char **DPEnvBySetting(char *const env[], NSDictionary<NSString *, NSString *> *values) {
    NSMutableArray<NSString *> *entries = [NSMutableArray new];
    for (size_t i = 0; env[i]; i++) {
        NSString *entry = @(env[i]);
        NSString *key = [entry componentsSeparatedByString:@"="].firstObject;
        if ([values.allKeys containsObject:key]) continue;
        [entries addObject:entry];
    }
    for (NSString *key in values) {
        NSString *value = values[key];
        if (value) [entries addObject:[key stringByAppendingFormat:@"=%@", value]];
    }
    char **result = calloc(entries.count + 1, sizeof *result);
    for (NSUInteger i = 0; i < entries.count; i++) result[i] = strdup(entries[i].UTF8String);
    return result;
}
