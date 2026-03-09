#pragma once

#include <chrono>
#include <cstdint>
#include <functional>
#include <queue>
#include <vector>

class DelayedTaskQueue {
public:
    using TaskFn = std::function<void()>;

    struct Task {
        int64_t run_at = 0;
        uint64_t id = 0;
        TaskFn fn;
    };

    struct Compare {
        bool operator()(const Task& a, const Task& b) const {
            if (a.run_at != b.run_at) {
                return a.run_at > b.run_at;
            }
            return a.id > b.id;
        }
    };

    uint64_t push_after(double delay_seconds, TaskFn fn) {
        const uint64_t id = next_id_++;
        const int64_t delay_ms = static_cast<int64_t>(delay_seconds * 1000.0);

        tasks_.push(Task{
            now_ts() + delay_ms,
            id,
            std::move(fn)
        });
        return id;
    }

    void run_due() {
        const int64_t now = now_ts();
        while (!tasks_.empty() && tasks_.top().run_at <= now) {
            auto task = std::move(tasks_.top());
            tasks_.pop();

            if (task.fn) {
                task.fn();
            }
        }
    }

    bool empty() const {
        return tasks_.empty();
    }

private:
    static int64_t now_ts() {
        return std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()
        ).count();
    }

    uint64_t next_id_ = 1;
    std::priority_queue<Task, std::vector<Task>, Compare> tasks_;
};