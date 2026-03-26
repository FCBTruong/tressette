#pragma once

#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <typeindex>
#include <unordered_map>
#include <utility>
#include <vector>

class SignalBus {
public:
    using SubscriptionId = std::uint64_t;

    template <typename Event>
    SubscriptionId subscribe(std::function<void(const Event&)> handler) {
        std::lock_guard<std::mutex> lock(mutex_);
        auto& handlers = handlers_for_locked<Event>();
        const SubscriptionId id = next_subscription_id_.fetch_add(1, std::memory_order_relaxed);
        handlers.push_back(HandlerEntry<Event>{id, std::move(handler)});
        return id;
    }

    template <typename Event>
    void publish(const Event& event) const {
        std::vector<std::function<void(const Event&)>> handlers_snapshot;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            auto it = handler_lists_.find(std::type_index(typeid(Event)));
            if (it == handler_lists_.end()) {
                return;
            }

            const auto* handlers = static_cast<const HandlerList<Event>*>(it->second.get());
            handlers_snapshot.reserve(handlers->entries.size());
            for (const auto& entry : handlers->entries) {
                handlers_snapshot.push_back(entry.handler);
            }
        }

        for (const auto& handler : handlers_snapshot) {
            handler(event);
        }
    }

private:
    struct IHandlerList {
        virtual ~IHandlerList() = default;
    };

    template <typename Event>
    struct HandlerEntry {
        SubscriptionId id;
        std::function<void(const Event&)> handler;
    };

    template <typename Event>
    struct HandlerList : IHandlerList {
        std::vector<HandlerEntry<Event>> entries;
    };

    template <typename Event>
    std::vector<HandlerEntry<Event>>& handlers_for_locked() {
        const auto key = std::type_index(typeid(Event));
        auto& list = handler_lists_[key];
        if (!list) {
            list = std::make_unique<HandlerList<Event>>();
        }

        return static_cast<HandlerList<Event>*>(list.get())->entries;
    }

    mutable std::mutex mutex_;
    std::atomic<SubscriptionId> next_subscription_id_{1};
    std::unordered_map<std::type_index, std::unique_ptr<IHandlerList>> handler_lists_;
};
