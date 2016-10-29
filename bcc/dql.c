/*
 * dql.c
 */

#include <uapi/linux/ptrace.h>
#include <linux/cache.h>
#include <linux/kernel.h>
#include <linux/bug.h>
#include <linux/dynamic_queue_limits.h>

BPF_HASH(limit);
BPF_HASH(lowest_slack);
int do_return_completed(struct pt_regs *ctx, struct dql *dql)
{
    u64 *tsp, ts, limit_now, lowest_slack_now;
    limit_now = dql->adj_limit - dql->num_completed;
    lowest_slack_now = dql->lowest_slack;
    ts = bpf_ktime_get_ns();
    if (limit.lookup(&limit_now) == 0) {
            limit.update(&limit_now, &ts);
    } else if (lowest_slack.lookup(&lowest_slack_now) == 0) {
        lowest_slack.update(&lowest_slack_now, &ts);
    }
    return 0;
}
