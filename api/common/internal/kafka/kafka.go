// Package kafka is the transport: event names and lanes, the envelope with
// its claim-check (every payload goes by data_ref, §5.3), a producer for the
// outbox, and consumers that commit after their handler succeeds, or after
// a few failed attempts once the failure is recorded (at-least-once, §9.2;
// shared-messaging.md rule 10).
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

// Producers send envelopeVersion; consumers accept supportedMajor only.
const (
	envelopeVersion = "1.0"
	supportedMajor  = "1"
)

type Envelope struct {
	Type       string          `json:"type"`
	Version    string          `json:"version"`
	ID         string          `json:"id"`
	ProducedAt string          `json:"produced_at"`
	RequestID  string          `json:"request_id,omitempty"`
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
	// SASL/SCRAM over TLS, the product's own Kafka user (X-11).
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
// every product can read the lanes (shared-messaging.md rule 3). requestID
// is the piece of work the message belongs to, kept on re-send.
func (p *Producer) Message(ctx context.Context, event, key, requestID string, data json.RawMessage) (kgo.Message, error) {
	topic, ok := TopicFor[event]
	if !ok {
		return kgo.Message{}, fmt.Errorf("%w: no topic for event %s", ErrContract, event)
	}
	if err := p.contract.Validate(event, data); err != nil {
		return kgo.Message{}, fmt.Errorf("%w: %s: %v", ErrContract, event, err)
	}
	env := Envelope{Type: event, Version: envelopeVersion, ID: uuid.NewString(), ProducedAt: time.Now().UTC().Format(time.RFC3339Nano),
		RequestID: requestID}
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

// Handler processes one validated payload. An error is retried a few times
// with backoff; ctx carries the message's request_id (RequestID).
type Handler func(ctx context.Context, data json.RawMessage) error

// Failure records, where the handler's domain allows, a message whose
// handler kept failing; the message is then committed (rule 10).
type Failure func(ctx context.Context, data json.RawMessage, cause error) error

type requestIDKey struct{}

// RequestID is the request_id of the message being handled, or "".
func RequestID(ctx context.Context) string {
	id, _ := ctx.Value(requestIDKey{}).(string)
	return id
}

// WithRequestID hands a handler the request_id of its message.
func WithRequestID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, requestIDKey{}, id)
}

const (
	handlerAttempts = 3
	retryBackoff    = time.Second
)

// Consumer reads one topic and routes each message to the handler for its
// event type. It never stops on a bad message: the lanes are shared.
type Consumer struct {
	reader   *kgo.Reader
	topic    string
	handlers map[string]Handler
	failures map[string]Failure
	contract *Contract
	blobs    Blobs
	attempts int
	backoff  time.Duration
	running  bool
}

func NewConsumer(cfg config.Kafka, group, topic string, handlers map[string]Handler, failures map[string]Failure, contract *Contract, blobs Blobs) (*Consumer, error) {
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
		topic: topic, handlers: handlers, failures: failures, contract: contract, blobs: blobs,
		attempts: handlerAttempts, backoff: retryBackoff,
	}, nil
}

func (c *Consumer) Running() bool { return c.running }

// Run blocks until ctx ends; nothing else stops it.
func (c *Consumer) Run(ctx context.Context) error {
	c.running = true
	defer func() { c.running = false; _ = c.reader.Close() }()
	for {
		msg, err := c.reader.FetchMessage(ctx)
		if err != nil {
			if ctx.Err() != nil {
				return nil
			}
			slog.Warn("fetch failed; retrying", "topic", c.topic, "error", err)
			if !sleep(ctx, c.backoff) {
				return nil
			}
			continue
		}
		if !c.process(ctx, msg.Offset, msg.Value) {
			return nil // ctx ended mid-work: leave the offset for redelivery
		}
		if err := c.reader.CommitMessages(ctx, msg); err != nil && ctx.Err() == nil {
			slog.Warn("commit failed; the message may be redelivered", "topic", c.topic, "offset", msg.Offset, "error", err)
		}
	}
}

// process handles one message and reports whether its offset may be
// committed; false only when ctx ended before the work finished.
func (c *Consumer) process(ctx context.Context, offset int64, raw []byte) bool {
	env, err := c.unwrap(raw)
	if errors.Is(err, errNotOurs) {
		return true // another product's event, or one this service doesn't handle
	}
	if err != nil {
		// Can never succeed; never log the payload (never-log list).
		slog.Error("dropping invalid message", "topic", c.topic, "offset", offset, "error", err)
		return true
	}
	ctx = WithRequestID(ctx, env.RequestID)
	var data json.RawMessage
	for attempt := 1; ; attempt++ {
		data, err = c.load(ctx, env)
		if errors.Is(err, ErrContract) {
			slog.Error("dropping invalid message", "topic", c.topic, "event", env.Type, "offset", offset, "request_id", env.RequestID, "error", err)
			return true
		}
		if err == nil {
			if err = c.handlers[env.Type](ctx, data); err == nil {
				return true
			}
		}
		if ctx.Err() != nil {
			return false
		}
		if attempt >= c.attempts {
			break
		}
		slog.Warn("handler failed; retrying", "topic", c.topic, "event", env.Type, "offset", offset, "request_id", env.RequestID,
			"attempt", attempt, "error", err)
		if !sleep(ctx, c.backoff<<(attempt-1)) {
			return false
		}
	}
	slog.Error("handler kept failing; recorded and skipped", "topic", c.topic, "event", env.Type, "offset", offset,
		"request_id", env.RequestID, "attempts", c.attempts, "error", err)
	if fail := c.failures[env.Type]; fail != nil && data != nil {
		if ferr := fail(ctx, data, err); ferr != nil {
			slog.Error("recording the failure failed", "event", env.Type, "offset", offset, "request_id", env.RequestID, "error", ferr)
		}
	}
	return ctx.Err() == nil
}

func sleep(ctx context.Context, d time.Duration) bool {
	t := time.NewTimer(d)
	defer t.Stop()
	select {
	case <-ctx.Done():
		return false
	case <-t.C:
		return true
	}
}

// ErrContract marks a message that can never be sent or handled as it is
// (it fails its schema, or carries a major version this code doesn't
// speak). Any other error (storage, say) is worth retrying.
var ErrContract = errors.New("violates the contract")

// errNotOurs marks a message this consumer skips without a word: the lanes
// are shared, so most messages on them belong to someone else.
var errNotOurs = errors.New("not handled here")

func (c *Consumer) unwrap(raw []byte) (*Envelope, error) {
	// Read the type first: other products' envelopes are not ours to validate.
	var head struct {
		Type string `json:"type"`
	}
	if json.Unmarshal(raw, &head) != nil || !strings.HasPrefix(head.Type, Product) {
		return nil, errNotOurs
	}
	if _, ok := c.handlers[head.Type]; !ok || TopicFor[head.Type] != c.topic {
		return nil, errNotOurs
	}
	if err := c.contract.Validate("envelope", raw); err != nil {
		return nil, fmt.Errorf("%w: envelope: %v", ErrContract, err)
	}
	var env Envelope
	if err := json.Unmarshal(raw, &env); err != nil {
		return nil, fmt.Errorf("%w: envelope: %v", ErrContract, err)
	}
	if major, _, _ := strings.Cut(env.Version, "."); major != supportedMajor {
		return nil, fmt.Errorf("%w: unsupported envelope version %s", ErrContract, env.Version)
	}
	return &env, nil
}

// load resolves the payload (the claim-check) and validates it.
func (c *Consumer) load(ctx context.Context, env *Envelope) (json.RawMessage, error) {
	data := env.Data
	if env.DataRef != nil {
		var err error
		if data, err = c.blobs.Get(ctx, env.DataRef.Key); err != nil {
			return nil, err
		}
	}
	if err := c.contract.Validate(env.Type, data); err != nil {
		return nil, fmt.Errorf("%w: %s: %v", ErrContract, env.Type, err)
	}
	return data, nil
}
