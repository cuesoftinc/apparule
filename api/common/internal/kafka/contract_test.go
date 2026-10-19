package kafka

import (
	"encoding/json"
	"io/fs"
	"testing"

	"github.com/cuesoftinc/apparule/api/common/contract"
)

func TestExamplesMatchSchemas(t *testing.T) {
	c, err := LoadContract()
	if err != nil {
		t.Fatal(err)
	}
	names, _ := fs.Glob(contract.Schemas, "examples/*.json")
	if len(names) < len(TopicFor) {
		t.Fatalf("expected an example per event, found %d", len(names))
	}
	seen := map[string]bool{}
	for _, name := range names {
		raw, _ := contract.Schemas.ReadFile(name)
		if err := c.Validate("envelope", raw); err != nil {
			t.Errorf("%s envelope: %v", name, err)
		}
		var env Envelope
		if err := json.Unmarshal(raw, &env); err != nil {
			t.Fatal(err)
		}
		if err := c.Validate(env.Type, env.Data); err != nil {
			t.Errorf("%s data: %v", name, err)
		}
		seen[env.Type] = true
	}
	for event := range TopicFor {
		if !seen[event] {
			t.Errorf("no example for %s", event)
		}
	}
}

func TestRejectsUnknownFieldsAndBadEnums(t *testing.T) {
	c, err := LoadContract()
	if err != nil {
		t.Fatal(err)
	}
	base := `"session_id":"5c2a9d1e-3b4f-4a6c-8d7e-9f0a1b2c3d4e","attempt":1,"method":"mediapipe_2d_v2","thresholds_version":"v","poses":{}`
	cases := map[string]string{
		"unknown field":         `{` + base + `,"status":"failed","error_code":"image_missing","extra":1}`,
		"bad status":            `{` + base + `,"status":"done"}`,
		"failed_qc without qc":  `{` + base + `,"status":"failed_qc"}`,
		"measured without data": `{` + base + `,"status":"measured"}`,
	}
	for name, body := range cases {
		if err := c.Validate(EventCaptureMeasured, []byte(body)); err == nil {
			t.Errorf("%s: expected a validation error", name)
		}
	}
}

func TestEveryEventRidesASharedLane(t *testing.T) {
	lanes := map[string]bool{TopicUploads: true, TopicRequests: true, TopicResults: true}
	for event, topic := range TopicFor {
		if !lanes[topic] || event[:len(Product)] != Product {
			t.Errorf("%s on %s", event, topic)
		}
	}
}
