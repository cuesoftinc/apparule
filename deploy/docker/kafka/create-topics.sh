#!/bin/sh
# Creates the CueLABS shared bus lanes (decisions.md X-11; the delivery
# standard's shared-messaging.md) on the compose broker. In cloud every
# product shares one Kafka service with these same three topics, and Apparule
# never creates its own. Idempotent.
set -eu
BOOTSTRAP="$1"
TOPICS=/opt/kafka/bin/kafka-topics.sh
DAY_MS=86400000

# Two partitions each, as on the shared service; 24 h retention.
for topic in cuelabs.uploads cuelabs.requests cuelabs.results; do
  "$TOPICS" --bootstrap-server "$BOOTSTRAP" --create --if-not-exists --topic "$topic" \
    --partitions 2 --replication-factor 1 --config retention.ms=$DAY_MS
done

"$TOPICS" --bootstrap-server "$BOOTSTRAP" --list | grep '^cuelabs\.'
