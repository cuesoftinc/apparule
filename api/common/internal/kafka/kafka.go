// Package kafka is the transport: event names and lanes, the envelope with
// its claim-check (every payload goes by data_ref, §5.3), a producer for the
// outbox, and consumers that commit only after their handler succeeds
// (at-least-once, §9.2).
package kafka

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/google/uuid"
	kgo "github.com/segmentio/kafka-go"
	"github.com/segmentio/kafka-go/sasl/scram"

	"github.com/cuesoftinc/apparule/api/common/internal/config"
)

// Events (system-design.md §5.3): the envelope's type, and the schema its
// data must match (api/common/contract/<event>.schema.json).
const (
	EventCaptureUploaded       = "apparule.capture.uploaded"
	EventMediaUploaded         = "apparule.media.uploaded"
	EventCaptureReady          = "apparule.capture.ready"
	EventOrdersTransition      = "apparule.orders.transition"
	EventPaymentsProviderEvent = "apparule.payments.provider_event"
	EventPayoutsRecipient      = "apparule.payouts.recipient_requested"
	EventLedgerReconcile       = "apparule.ledger.reconcile_requested"
	EventNotificationsCreated  = "apparule.notifications.created"
	EventCaptureMeasured       = "apparule.capture.measured"
	EventPaymentsOutcome       = "apparule.payments.outcome"
)

// Topics are the lanes of the CueLABS shared message bus, which every
// product reads and writes (decisions.md X-11; the CueLABS delivery
// standard's shared-messaging.md). The event type says whose message it is.
const (
	TopicUploads  = "cuelabs.uploads"  // upload gateways -> control planes
	TopicRequests = "cuelabs.requests" // control planes -> processing
	TopicResults  = "cuelabs.results"  // processing -> control planes
)

// Product prefixes every event type this service may handle.
const Product = "apparule."

// TopicFor names the lane an event travels on.
var TopicFor = map[string]string{
	EventCaptureUploaded:       TopicUploads,
	EventMediaUploaded:         TopicUploads,
	EventCaptureReady:          TopicRequests,
	EventOrdersTransition:      TopicRequests,
	EventPaymentsProviderEvent: TopicRequests,
	EventPayoutsRecipient:      TopicRequests,
	EventLedgerReconcile:       TopicRequests,
	EventNotificationsCreated:  TopicRequests,
	EventCaptureMeasured:       TopicResults,
	EventPaymentsOutcome:       TopicResults,
}

const envelopeVersion = 1

type Envelope struct {
	Type       string          `json:"type"`
	Version    int             `json:"version"`
	ID         string          `json:"id"`
	ProducedAt string          `json:"produced_at"`
	Data       json.RawMessage `json:"data,omitempty"`
	DataRef    *ObjectRef      `json:"data_ref,omitempty"`
}

type ObjectRef struct {
	Bucket      string `json:"bucket"`
	Key         string `json:"key"`
	Size        int64  `json:"size,omitempty"`
	ContentType string `json:"content_type,omitempty"`
	SHA256      string `json:"sha256,omitempty"`
}

// Blobs is the slice of object storage the claim-check needs.
type Blobs interface {
	Bucket() string
	Prefix() string
	Put(ctx context.Context, key string, data []byte, contentType string) error
	Get(ctx context.Context, key string) ([]byte, error)
}

func dialer(cfg config.Kafka) (*kgo.Dialer, *kgo.Transport, error) {
	d := &kgo.Dialer{Timeout: 10 * time.Second, DualStack: true}
	t := &kgo.Transport{}
	if cfg.Username == "" {
		return d, t, nil
	}
	// Aiven: SASL/SCRAM over TLS, the product's own Kafka user (X-11).
	mechanism, err := scram.Mechanism(scram.SHA256, cfg.Username, cfg.Password)
	if err != nil {
		return nil, nil, err
	}
	tlsCfg := &tls.Config{MinVersion: tls.VersionTLS12}
	if cfg.SSLCA != "" {
		pool := x509.NewCertPool()
		if !pool.AppendCertsFromPEM([]byte(cfg.SSLCA)) {
			return nil, nil, errors.New("KAFKA_SSL_CA is not a PEM certificate")
		}
		tlsCfg.RootCAs = pool
	}
	d.SASLMechanism, d.TLS = mechanism, tlsCfg
	t.SASL, t.TLS = mechanism, tlsCfg
	return d, t, nil
}

// Producer publishes envelopes; only the outbox publisher uses it.
type Producer struct {
	writer   *kgo.Writer
	contract *Contract
	blobs    Blobs
}

func NewProducer(cfg config.Kafka, contract *Contract, blobs Blobs) (*Producer, error) {
	_, transport, err := dialer(cfg)
	if err != nil {
		return nil, err
	}
	return &Producer{
		writer: &kgo.Writer{
			Addr:         kgo.TCP(cfg.Brokers...),
			Balancer:     &kgo.Hash{},
			RequiredAcks: kgo.RequireAll,
			Transport:    transport,
			BatchTimeout: 20 * time.Millisecond,
		},
		contract: contract,
		blobs:    blobs,
	}, nil
}

func (p *Producer) Close() error { return p.writer.Close() }

// Message builds a validated envelope for an event, addressed to its lane.
// The data goes to compute/ in storage and the message carries the pointer:
// every product can read the lanes (shared-messaging.md rule 3).
func (p *Producer) Message(ctx context.Context, event, key string, data json.RawMessage) (kgo.Message, error) {
	topic, ok := TopicFor[event]
	if !ok {
		return kgo.Message{}, fmt.Errorf("%w: no topic for event %s", ErrContract, event)
	}
	if err := p.contract.Validate(event, data); err != nil {
		return kgo.Message{}, fmt.Errorf("%w: %s: %v", ErrContract, event, err)
	}
	env := Envelope{Type: event, Version: envelopeVersion, ID: uuid.NewString(), ProducedAt: time.Now().UTC().Format(time.RFC3339Nano)}
	objKey := fmt.Sprintf("%s/compute/%s.json", p.blobs.Prefix(), env.ID)
	if err := p.blobs.Put(ctx, objKey, data, "application/json"); err != nil {
		return kgo.Message{}, err
	}
	env.DataRef = &ObjectRef{Bucket: p.blobs.Bucket(), Key: objKey, Size: int64(len(data)), ContentType: "application/json"}
	raw, err := json.Marshal(env)
	if err != nil {
		return kgo.Message{}, err
	}
	if err := p.contract.Validate("envelope", raw); err != nil {
		return kgo.Message{}, fmt.Errorf("%w: envelope: %v", ErrContract, err)
	}
	return kgo.Message{Topic: topic, Key: []byte(key), Value: raw}, nil
}

func (p *Producer) Write(ctx context.Context, msgs ...kgo.Message) error {
	return p.writer.WriteMessages(ctx, msgs...)
}

// Handler processes one validated payload. Returning an error stops the
// consumer without committing, so the message is redelivered.
type Handler func(ctx context.Context, data json.RawMessage) error

// Consumer reads one topic and routes each message to the handler for its
// event type.
type Consumer struct {
	reader   *kgo.Reader
	topic    string
	handlers map[string]Handler
	contract *Contract
	blobs    Blobs
	running  bool
}

func NewConsumer(cfg config.Kafka, group, topic string, handlers map[string]Handler, contract *Contract, blobs Blobs) (*Consumer, error) {
	d, _, err := dialer(cfg)
	if err != nil {
		return nil, err
	}
	return &Consumer{
		reader: kgo.NewReader(kgo.ReaderConfig{
			Brokers:     cfg.Brokers,
			GroupID:     group,
			Topic:       topic,
			Dialer:      d,
			StartOffset: kgo.FirstOffset,
			MaxWait:     time.Second,
		}),
		topic: topic, handlers: handlers, contract: contract, blobs: blobs,
	}, nil
}

func (c *Consumer) Running() bool { return c.running }

// Run blocks until ctx ends or a handler fails.
func (c *Consumer) Run(ctx context.Context) error {
	c.running = true
	defer func() { c.running = false; _ = c.reader.Close() }()
	for {
		msg, err := c.reader.FetchMessage(ctx)
		if err != nil {
			if ctx.Err() != nil {
				return nil
			}
			return err
		}
		event, data, err := c.unwrap(ctx, msg.Value)
		if errors.Is(err, errNotOurs) {
			// Another product's event, or one this service doesn't handle.
		} else if err != nil {
			// Can never succeed; skip rather than block the partition.
			// Never log the payload (never-log list).
			slog.Error("dropping invalid message", "topic", c.topic, "offset", msg.Offset, "error", err)
		} else if err := c.handlers[event](ctx, data); err != nil {
			slog.Error("handler failed; stopping consumer", "topic", c.topic, "event", event, "offset", msg.Offset, "error", err)
			return err
		}
		if err := c.reader.CommitMessages(ctx, msg); err != nil && ctx.Err() == nil {
			return err
		}
	}
}

// ErrContract marks a message that can never be sent as it is (it fails its
// schema). Any other error from Message (storage, say) is worth retrying.
var ErrContract = errors.New("violates the contract")

// errNotOurs marks a message this consumer skips without a word: the lanes
// are shared, so most messages on them belong to someone else.
var errNotOurs = errors.New("not handled here")

func (c *Consumer) unwrap(ctx context.Context, raw []byte) (string, json.RawMessage, error) {
	// Read the type first: other products' envelopes are not ours to validate.
	var head struct {
		Type string `json:"type"`
	}
	if json.Unmarshal(raw, &head) != nil || !strings.HasPrefix(head.Type, Product) {
		return "", nil, errNotOurs
	}
	if _, ok := c.handlers[head.Type]; !ok || TopicFor[head.Type] != c.topic {
		return "", nil, errNotOurs
	}
	if err := c.contract.Validate("envelope", raw); err != nil {
		return "", nil, err
	}
	var env Envelope
	if err := json.Unmarshal(raw, &env); err != nil {
		return "", nil, err
	}
	data := env.Data
	if env.DataRef != nil {
		var err error
		if data, err = c.blobs.Get(ctx, env.DataRef.Key); err != nil {
			return "", nil, err
		}
	}
	return env.Type, data, c.contract.Validate(env.Type, data)
}
